include .\include\common\byte_sequence.inc
include .\include\common\padding.inc
include .\include\common\random.inc

.code
; Vigenere cipher encryption
;
; Parameters:
;	RCX: ByteSequence* - encrypted text (uninitialized)
;	RDX: ByteSequence* - plaintext
;	R8: ByteSequence* - shift table (length must be 2^n, n in [1, 7])
;
; Return value:
;	RAX: ByteSequence* - encrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
VigenereEncrypt proc
	local buffer: ByteSequence
	encrypted_text equ [rbp + 16]
	text equ [rbp + 24]
	table equ [rbp + 32]
	; Prologue
	push rsi
	push rdi
	mov encrypted_text, rcx
	mov text, rdx
	mov table, r8
	sub rsp, 32

	; Add padding
	lea rcx, buffer
	mov r8b, byte ptr [r8 + ByteSequence.data_size]
	call AddPadding

	; Init ByteSequence structure for encrypted message
	mov rcx, encrypted_text
	mov rdx, [rax + ByteSequence.data_size]
	call CreateBS

    ; Encryption
	; rcx - counter
	; r8 - mask
	; r9 - length
	; r10 - table data
	; rsi - buffer data
	; rdi - encrypted text data
    mov rax, table
    lea rdx, buffer
	mov rcx, 0
	mov r8, [rax + ByteSequence.data_size]
	dec r8
	mov r9, [rdx + ByteSequence.data_size]
    mov r10, [rax + ByteSequence.data]
    mov rsi, [rdx + ByteSequence.data]
	mov rdi, encrypted_text
    mov rdi, [rdi + ByteSequence.data]
	jmp condition 
cycle:
	mov al, [rsi + rcx]
	mov rdx, rcx
	and rdx, r8
	mov dl, [r10 + rdx]
	add al, dl
	mov [rdi + rcx], al
	inc rcx
condition:
	cmp rcx, r9
	jb cycle
	
    ; Free buffer
	lea rcx, buffer
	call FreeBS

	mov rax, encrypted_text

	; Epilogue
	add rsp, 32
	pop rdi
	pop rsi
	ret
VigenereEncrypt endp

; Vigenere cipher decryption
;
; Parameters:
;	RCX: ByteSequence* - decrypted text (uninitialized)
;	RDX: ByteSequence* - encrypted text
;	R8: ByteSequence* - shift table (length must be 2^n, n in [1, 7])
;
; Return value:
;	RAX: ByteSequence* - decrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
VigenereDecrypt proc
	local buffer: ByteSequence
	decrypted_text equ [rbp + 16]
	text equ [rbp + 24]
	table equ [rbp + 32]
	; Prologue
	push rsi
	push rdi
	mov decrypted_text, rcx
	mov text, rdx
	mov table, r8
	sub rsp, 32

	; Init ByteSequence structure for decrypted message
	lea rcx, buffer
	mov rdx, [rdx + ByteSequence.data_size]
	call CreateBS

    ; Decryption
	; rcx - counter
	; r8 - mask
	; r9 - length
	; r10 - table data
	; rsi - text data
	; rdi - buffer data
	mov rax, table
    mov rdx, text
	mov rcx, 0
	mov r8, [rax + ByteSequence.data_size]
	dec r8
	mov r9, [rdx + ByteSequence.data_size]
    mov r10, [rax + ByteSequence.data]
    mov rsi, [rdx + ByteSequence.data]
	lea rdi, buffer
    mov rdi, [rdi + ByteSequence.data]
	jmp condition 
cycle:
	mov al, [rsi + rcx]
	mov rdx, rcx
	and rdx, r8
	mov dl, [r10 + rdx]
	sub al, dl
	mov [rdi + rcx], al
	inc rcx
condition:
	cmp rcx, r9
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
	add rsp, 32
	pop rdi
	pop rsi
	ret
VigenereDecrypt endp

; Generates shift table
;
; Parameters:
;	RCX: ByteSequence* - shift table (uninitialized)
;	DL: byte - block size (must be 2^n, n in [1, 7])
;
; Return value:
;	RAX: ByteSequence* - shift table (caller must free)
VigenereGenKey proc
	table equ [rbp + 16]
	block_size equ [rbp + 24]
	; Prologue
	push rbp
	mov rbp, rsp
	push r12
    push r13
	mov table, rcx
	mov block_size, dl
	sub rsp, 32

	movzx rdx, dl
	call CreateBS

    movzx r12, byte ptr block_size
	dec r12
	mov r13, [rax + ByteSequence.data]
cycle:
	call GenRandom8
	mov [r13 + r12], al
	dec r12
condition:
	cmp r12, 0
	jge cycle
	
	mov rax, r13
	
	; Epilogue
	add rsp, 32
    pop r13
	pop r12
	mov rsp, rbp
	pop rbp
	ret
VigenereGenKey endp
end