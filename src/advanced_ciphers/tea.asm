include .\include\common\byte_sequence.inc
include .\include\common\padding.inc
include .\include\common\random.inc

DELTA equ 9E3779B9h
DECRYPT_SUM equ 0C6EF3720h
BLOCK_SIZE equ 8

.code
; TEA encryption
;
; Parameters:
;   RCX: ByteSequence* - encrypted text (uninitialized)
;   RDX: ByteSequence* - plaintext
;   R8: ByteSequence* - key (length must be 16 bytes)
;
; Return value:
;   RAX: ByteSequence* - encrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
TeaEncrypt proc
    local buffer: ByteSequence
    encrypted_text equ [rbp + 16]
    text equ [rbp + 24]
	key equ [rbp + 32]
	; Prologue
	push rbx
	push r12
	push r13
	push r14
    push r15
	mov encrypted_text, rcx
    mov text, rdx
    mov key, r8
	sub rsp, 40

	; Add padding
	lea rcx, buffer
	mov r8b, BLOCK_SIZE
	call AddPadding

	; Init encrypted_text fields
	mov rcx, encrypted_text
	mov rdx, [rax + ByteSequence.data_size]
    call CreateBS
    
    ; Encryption
    ; rbx - key
    ; r12 - offset
    ; r13 - buffer data
    ; r14 - encrypted text data
    ; r15 - length
	mov rbx, key
    mov r12, 0
    lea r13, buffer
    mov r13, [r13 + ByteSequence.data]
    mov r14, [rax + ByteSequence.data]
    mov r15, [rax + ByteSequence.data_size]
    jmp condition
cycle:
    mov rcx, [r13 + r12]
    mov rdx, rbx

    call TeaEncryptBlock

    mov [r14 + r12], rax

    add r12, BLOCK_SIZE
condition:
    cmp r12, r15
    jb cycle

    ; Free buffer
    lea rcx, buffer
    call FreeBS

    mov rax, encrypted_text

    ; Epilogue
    add rsp, 40
    pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
    ret
TeaEncrypt endp

; Encrypts 64-bit block of text with tea cipher
;
; Parameters:
;   RCX: qword - block
;   RDX: ByteSequence* - key (length must be 16 bytes)
;
; Return value:
;   RAX: qword - encrypted block
TeaEncryptBlock proc
    ; rcx - counter
    ; r8d - 1st part of block
    ; r9d - 2nd part of block
    ; r10d - sum
    ; r11 - key data
    mov r8, rcx
    shr r8, 32
    mov r9d, ecx
    mov r10d, 0
    mov r11, [rdx + ByteSequence.data]
    mov rcx, 0
    jmp condition
cycle:
    add r10d, DELTA

    ; (v1 << 4) + key[0]
    mov eax, r9d
    shl eax, 4
    add eax, [r11]

    ; ((v1 << 4) + key[0]) ^ (v1 + sum)
    mov edx, r9d
    add edx, r10d
    xor eax, edx

    ; v0 += ((v1 << 4) + key[0]) ^ (v1 + sum) ^ ((v1 >> 5) + key[1])
    mov edx, r9d
    shr edx, 5
    add edx, [r11 + 4]
    xor eax, edx
    add r8d, eax

    ; (v0 << 4) + key[2]
    mov eax, r8d
    shl eax, 4
    add eax, [r11 + 8]

    ; ((v0 << 4) + key[2]) ^ (v0 + sum)
    mov edx, r8d
    add edx, r10d
    xor eax, edx

    ; v1 += ((v0 << 4) + key[2]) ^ (v0 + sum) ^ ((v0 >> 5) + key[3])
    mov edx, r8d
    shr edx, 5
    add edx, [r11 + 12]
    xor eax, edx
    add r9d, eax

    inc rcx
condition:
    cmp rcx, 32
    jb cycle

    mov eax, r9d
    shl r8, 32
    or rax, r8

    ret
TeaEncryptBlock endp

; TEA decryption
;
; Parameters:
;   RCX: ByteSequence* - decrypted text (uninitialized)
;   RDX: ByteSequence* - encrypted text
;   R8: ByteSequence* - key (length must be 16 bytes)
;
; Return value:
;   RAX: ByteSequence* - decrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
TeaDecrypt proc
    local buffer: ByteSequence
    decrypted_text equ [rbp + 16]
    text equ [rbp + 24]
	key equ [rbp + 32]
	; Prologue
	push rbx
	push r12
	push r13
	push r14
    push r15
	mov decrypted_text, rcx
    mov text, rdx
    mov key, r8
	sub rsp, 40

	; Init buffer
	lea rcx, buffer
	mov rdx, [rdx + ByteSequence.data_size]
    call CreateBS
    
    ; Decryption
    ; rbx - key
    ; r12 - offset
    ; r13 - text data
    ; r14 - buffer data
    ; r15 - length
	mov rbx, key
    mov r12, 0
    mov r13, text
    mov r13, [r13 + ByteSequence.data]
    mov r14, [rax + ByteSequence.data]
    mov r15, [rax + ByteSequence.data_size]
    jmp condition
cycle:
    mov rcx, [r13 + r12]
    mov rdx, rbx

    call TeaDecryptBlock

    mov [r14 + r12], rax

    add r12, BLOCK_SIZE
condition:
    cmp r12, r15
    jb cycle

    ; Remove padding
    mov rcx, decrypted_text
    lea rdx, buffer
    call RemovePadding

    ; Free buffer
    lea rcx, buffer
    call FreeBS

    mov rax, decrypted_text

    ; Epilogue
    add rsp, 40
    pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
    ret
TeaDecrypt endp

; Decrypts 64-bit block of text with tea cipher
;
; Parameters:
;   RCX: qword - block
;   RDX: ByteSequence* - key (length must be 16 bytes)
;
; Return value:
;   RAX: qword - decrypted block
TeaDecryptBlock proc
    ; rcx - counter
    ; r8d - 1st part of block
    ; r9d- 2nd part of block
    ; r10d - sum
    ; r11 - key data
    mov r8, rcx
    shr r8, 32
    mov r9d, ecx
    mov r10d, DECRYPT_SUM
    mov r11, [rdx + ByteSequence.data]
    mov rcx, 0
    jmp condition
cycle:
    ; (v0 << 4) + key[2]
    mov eax, r8d
    shl eax, 4
    add eax, [r11 + 8]

    ; ((v0 << 4) + key[2]) ^ (v0 + sum)
    mov edx, r8d
    add edx, r10d
    xor eax, edx

    ; v1 -= ((v0 << 4) + key[2]) ^ (v0 + sum) ^ ((v0 >> 5) + key[3])
    mov edx, r8d
    shr edx, 5
    add edx, [r11 + 12]
    xor eax, edx
    sub r9d, eax

    ; (v1 << 4) + key[0]
    mov eax, r9d
    shl eax, 4
    add eax, [r11]

    ; ((v1 << 4) + key[0]) ^ (v1 + sum)
    mov edx, r9d
    add edx, r10d
    xor eax, edx

    ; v0 -= ((v1 << 4) + key[0]) ^ (v1 + sum) ^ ((v1 >> 5) + key[1])
    mov edx, r9d
    shr edx, 5
    add edx, [r11 + 4]
    xor eax, edx
    sub r8d, eax

    sub r10d, DELTA

    inc rcx
condition:
    cmp rcx, 32
    jb cycle

    mov eax, r9d
    shl r8, 32
    or rax, r8

    ret
TeaDecryptBlock endp

; Generates 16-byte key for tea cipher
;
; Parameters:
;   RCX: ByteSequence* - key (uninitialized)
;
; Return value:
;   RAX: ByteSequence* - key (caller must free)
TeaGenKey proc
    ; Prologue
	push r12
	push r13
    push r14
	mov r14, rcx
	sub rsp, 32

    ; Init key
	mov rdx, 16
	call CreateBS

    ; Fill key with random values
	; r12 - index
	; r13 - key data
	mov r12, 15
	mov r13, [rax + ByteSequence.data]
    jmp condition
cycle:
	call GenRandom8
    mov [r13 + r12], al
	dec r12
condition:
	cmp r12, 0
	jge cycle

	mov rax, r14

    ; Epilogue
	add rsp, 32
    pop r14
	pop r13
	pop r12
	ret
TeaGenKey endp
end