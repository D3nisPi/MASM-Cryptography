include .\include\common\byte_sequence.inc
include .\include\advanced_ciphers\des.inc
include .\include\advanced_ciphers\3des.inc

.code
; Triple Des encryption (DES-EDE3)
;
; Parameters:
;   RCX: ByteSequence* - encrypted text (uninitialized)
;   RDX: ByteSequence* - plaintext
;   R8: TripleDesKey* - key
;
; Return value:
;   RAX: ByteSequence* - encrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
TripleDesEncrypt proc
    local buffer1: ByteSequence
    local buffer2: ByteSequence
    encrypted_text equ [rbp + 16]
    text equ [rbp + 24]
    key equ [rbp + 32]
    ; Prologue
    mov encrypted_text, rcx
    mov text, rdx
    mov key, r8
    sub rsp, 32

    lea rcx, buffer1
    mov rdx, rdx
    mov r8, key
    mov r8, [r8 + TripleDesKey.key1]
    call DesEncrypt

    lea rcx, buffer2
    mov rdx, rax
    mov r8, key
    mov r8, [r8 + TripleDesKey.key2]
    call DesDecryptWithoutPadding

    mov rcx, encrypted_text
    mov rdx, rax
    mov r8, key
    mov r8, [r8 + TripleDesKey.key3]
    call DesEncryptWithoutPadding

    lea rcx, buffer1
    call FreeBS
    lea rcx, buffer2
    call FreeBS

    mov rax, encrypted_text

    ; Epilogue
    add rsp, 32
    ret
TripleDesEncrypt endp

; Triple Des decryption (DES-EDE3)
;
; Parameters:
;   RCX: ByteSequence* - decrypted text (uninitialized)
;   RDX: ByteSequence* - encrypted text
;   R8: TripleDesKey* - key
;
; Return value:
;   RAX: ByteSequence* - decrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
TripleDesDecrypt proc
    local buffer1: ByteSequence
    local buffer2: ByteSequence
    decrypted_text equ [rbp + 16]
    text equ [rbp + 24]
    key equ [rbp + 32]
    ; Prologue
    mov decrypted_text, rcx
    mov text, rdx
    mov key, r8
    sub rsp, 32

    lea rcx, buffer1
    mov rdx, rdx
    mov r8, key
    mov r8, [r8 + TripleDesKey.key3]
    call DesDecryptWithoutPadding

    lea rcx, buffer2
    mov rdx, rax
    mov r8, key
    mov r8, [r8 + TripleDesKey.key2]
    call DesEncryptWithoutPadding

    mov rcx, encrypted_text
    mov rdx, rax
    mov r8, key
    mov r8, [r8 + TripleDesKey.key1]
    call DesDecrypt

    lea rcx, buffer1
    call FreeBS
    lea rcx, buffer2
    call FreeBS

    mov rax, decrypted_text

    ; Epilogue
    add rsp, 32
    ret
TripleDesDecrypt endp

; Triple Des key generation
;
; Parameters:
;   RCX: TripleDesKey* - key
;
; Return value:
;   RAX:  TripleDesKey* - key
TripleDesGenKey proc
    ; Prologue
    push rbx
    mov rbx, rcx
    sub rsp, 32

    call DesGenKey
    mov [rbx + TripleDesKey.key1], rax

    call DesGenKey
    mov [rbx + TripleDesKey.key2], rax

    call DesGenKey
    mov [rbx + TripleDesKey.key3], rax

    mov rax, rbx

    ; Epilogue
    add rsp, 32
    pop rbx
    ret
TripleDesGenKey endp
end