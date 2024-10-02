include .\include\common\byte_sequence.inc
include .\include\common\random.inc

.data
    s byte 256 dup(0)
.code
; RC4 encryption / decryption
;
; Parameters:
;   RCX: ByteSequence* - encrypted text / decrypted text (uninitialized)
;   RDX: ByteSequence* - plaintext / encrypted text
;   R8: ByteSequence* - key (length must be 5 - 256 bytes)
;
; Return value:
;   RAX: ByteSequence* - encrypted text / decrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
RC4 proc
    local key_sequence: ByteSequence
    result_text equ [rbp + 16]
    text equ [rbp + 24]
    key equ [rbp + 32]
    ; Prologue
    mov result_text, rcx
    mov text, rdx
    mov key, r8
    sub rsp, 32

    ; Init result text fields
    mov rdx, [rdx + ByteSequence.data_size]
    call CreateBS

    ; Init S array
    mov rcx, key
    call InitS

    ; Generate key sequence
    lea rcx, key_sequence
    mov rdx, text
    mov rdx, [rdx + ByteSequence.data_size]
    call GenerateKey

    ; Encryption
    ; rcx - counter
    ; rdx - length
    ; r8 - key sequence data
    ; r9 - text data
    ; r10 - result text data
    mov rcx, 0
    mov rdx, [rax + ByteSequence.data_size]
    mov r8, [rax + ByteSequence.data]
    mov r9, text
    mov r9, [r9 + ByteSequence.data]
    mov r10, result_text
    mov r10, [r10 + ByteSequence.data]
cycle:
    mov al, [r8 + rcx]
    xor al, [r9 + rcx]
    mov [r10 + rcx], al

    inc rcx
condition:
    cmp rcx, rdx
    jb cycle

    ; Free generated key data
    lea rcx, key_sequence
    call FreeBS

    mov rax, result_text

    ; Epilogue
    add rsp, 32
    ret
RC4 endp

; Initializes S array
;
; Parameters:
;   RCX: ByteSequence* - key
;
; No return value
InitS proc
    mov r11, rcx

    ; Fill s[i] with i
    mov rcx, 0
    lea rdx, s
    jmp fill_condition
fill_cycle:
    mov [rdx + rcx], cl
    inc rcx
fill_condition:
    cmp rcx, 256
    jb fill_cycle

    ; rcx - i
    ; r8 - j
    ; r9 - s array
    ; r10 - key data
    ; r11 - key size
    mov rcx, 0
    mov r8, 0
    lea r9, s
    mov r10, [r11 + ByteSequence.data]
    mov r11, [r11 + ByteSequence.data_size]
    jmp condition
cycle:
    ; j = (j + s[i]) mod 256
    add r8b, [r9 + rcx]

    ; j = (j + key[i % key.size]) mod 256
    mov dx, 0
    mov ax, cx
    div r11w
    movzx rdx, dx
    add r8b, [r10 + rdx]

    ; Swap s[i], s[j]
    mov al, [r9 + rcx]
    mov dl, [r9 + r8]
    mov [r9 + rcx], dl
    mov [r9 + r8], al

    inc rcx
condition:
    cmp rcx, 256
    jb cycle

    ret
InitS endp

; Generates key sequence for encryption / decryption
; from initial key
;
; Parameters:
;   RCX: ByteSequence* - key sequence (uninitialized)
;   RDX: ByteSequence* - bytes to generate
;
; Return value:
;   RAX: ByteSequence* - key sequence (caller must free)
GenerateKey proc
    key equ [rbp + 16]
    key_size equ [rbp + 24]
    ; Prologue
    push rbp
    mov rbp, rsp
    push rbx
    mov key, rcx
    sub rsp, 40

    call CreateBS

    ; Generate key sequence
    ; rcx - i
    ; rdx - j
    ; r8 - s
    ; r9 - cycle counter
    ; r10 - key data
    ; r11 - key size
    mov rcx, 0
    mov rdx, 0
    lea r8, s
    mov r9, 0
    mov r10, [rax + ByteSequence.data]
    mov r11, [rax + ByteSequence.data_size]
cycle:
    ; i = (i + 1) mod 256
    ; j = (j + s[i]) mod 256
    inc cl
    add dl, [r8 + rcx]
    
    ; Swap s[i], s[j]
    mov al, [r8 + rcx]
    mov bl, [r8 + rdx]
    mov [r8 + rcx], bl
    mov [r8 + rdx], al

    ; t = (s[i] + s[j]) mod 256
    mov al, [r8 + rcx]
    add al, [r8 + rdx]

    ; key.data[r9] = s[t]
    movzx rax, al
    mov al, [r8 + rax]
    mov [r10 + r9], al

    inc r9
condtion:
    cmp r9, r11
    jb cycle

    mov rax, key

    add rsp, 40
    pop rbx
    mov rsp, rbp
    pop rbp
    ret
GenerateKey endp

; Generates key for RC4 cipher
;
; Parameters:
;   RCX: ByteSequence* - key (uninitialized)
;   DX: word - key length (5 - 256 bytes)
;
; Return value:
;   RAX: ByteSequence* - key (caller must free)
RC4GenKey proc
    ; Prologue
    push rbx
    push r12
    push r13
    sub rsp, 32

    movzx rdx, dx
    call CreateBS
    mov rbx, rax

    mov r12, [rax + ByteSequence.data_size]
    dec r12
    mov r13, [rax + ByteSequence.data]
cycle:
    call GenRandom8
    mov [r13 + r12], al
    dec r12
condition:
    cmp r12, 0
    jge cycle

    mov rax, rbx

    ; Epilogue
    add rsp, 32
    pop r13
    pop r12
    pop rbx
    ret
RC4GenKey endp
end