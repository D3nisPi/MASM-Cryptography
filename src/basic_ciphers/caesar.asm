include .\include\common\byte_sequence.inc
include .\include\common\random.inc

.code
; Caesar cipher encryption
;
; Parameters:
;   RCX: ByteSequence* - encrypted text (uninitialized)
;   RDX: ByteSequence* - plaintext
;   R8B: byte - key
;
; Return value:
;   RAX: ByteSequence* - encrypted text (caller must free)
CaesarEncrypt proc
    encrypted_text equ [rbp + 16]
    text equ [rbp + 24]
    key equ [rbp + 32]
    ; Prologue
    push rbp
    mov rbp, rsp
    mov encrypted_text, rcx
    mov text, rdx
    mov key, r8b
    sub rsp, 32

    ; Init ByteSequence structure for encrypted message
    mov rdx, [rdx + ByteSequence.data_size]
    call CreateBS

    ; Encryption
    ; rcx - counter
    ; dl - key
    ; r8 - encrypted text
    ; r9 - length
    ; r10 - text data
    ; r11 - encrypted text data
    mov rcx, 0
    mov dl, key
    mov r8, encrypted_text
    mov r9, [r8 + ByteSequence.data_size]
    mov r10, text
    mov r10, [r10 + ByteSequence.data]
    mov r11, [r8 + ByteSequence.data]
    jmp condition
cycle:
    mov al, [r10 + rcx]
    add al, dl
    mov [r11 + rcx], al
    inc rcx
condition:
    cmp rcx, r9
    jb cycle

    mov rax, r8
    
    ; Epilogue
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret
CaesarEncrypt endp

; Caesar cipher decryption
;
; Parameters:
;   RCX: ByteSequence* - decrypted text (uninitialized)
;   RDX: ByteSequence* - encrypted text
;   DL: byte - key
;
; Return value:
;   RAX: ByteSequence* - decrypted text (caller must free)
CaesarDecrypt proc
    decrypted_text equ [rbp + 16]
    text equ [rbp + 24]
    key equ [rbp + 32]
    ; Prologue
    push rbp
    mov rbp, rsp
    mov decrypted_text, rcx
    mov text, rdx
    mov key, r8b
    sub rsp, 32
    
    ; Init ByteSequence structure for decrypted message
    mov rdx, [rdx + ByteSequence.data_size]
    call CreateBS

    ; Encryption
    ; rcx - counter
    ; dl - key
    ; r8 - decrypted text
    ; r9 - length
    ; r10 - text data
    ; r11 - decrypted text data
    mov rcx, 0
    mov dl, key
    mov r8, encrypted_text
    mov r9, [r8 + ByteSequence.data_size]
    mov r10, text
    mov r10, [r10 + ByteSequence.data]
    mov r11, [r8 + ByteSequence.data]
    jmp condition
cycle:
    mov al, [r10 + rcx]
    sub al, dl
    mov [r11 + rcx], al
    inc rcx
condition:
    cmp rcx, r9
    jb cycle

    mov rax, r8

    ; Epilogue
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret
CaesarDecrypt endp

; Caesar cipher key generator
;
; No parameters
;
; Return value:
;   AL: byte - key
CaesarGenKey proc
    sub rsp, 40

    call GenRandom8

    add rsp, 40
    ret
CaesarGenKey endp
end