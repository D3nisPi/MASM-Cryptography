include .\include\common\byte_sequence.inc
include .\include\common\random.inc

.code
; One-time pad encryption & decryption
;
; Parameters:
;	RCX: ByteSequence* - ecnrypted text / decrypted text (uninitialized)
;	RDX: ByteSequence* - plaintext / ecnrypted text
;	R8: ByteSequence* - key (must be the same size as the text)
;
; Return value:
;	RAX: ByteSequence* - ecnrypted text / decrypted text (caller must free)
OneTimePad proc
	result_text equ [rbp + 16]
	text equ [rbp + 24]
    key equ [rbp + 32]
    ; Prologue
    push rbp
    mov rbp, rsp
    mov result_text, rcx
    mov text, rdx
    mov key, r8
	sub rsp, 32

    ; Init ByteSequence structure for result text
    mov rdx, [rdx + ByteSequence.data_size]
    call CreateBS
    
    ; Encryption / Decryption
    ; rcx - counter
    ; rdx - key
    ; r8 - result text
    ; r9 - length
    ; r10 - text data
    ; r11 - result text data
	mov rcx, 0
	mov rdx, key
	mov rdx, [rdx + ByteSequence.data]
	mov r8, result_text
    mov r9, [r8 + ByteSequence.data_size]
    mov r10, text
    mov r10, [r10 + ByteSequence.data]
    mov r11, [r8 + ByteSequence.data]
    jmp condition
cycle:
    mov al, [r10 + rcx]
    xor al, [rdx + rcx]
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
OneTimePad endp

; One-time pad key generation
;
; Parameters:
;	RCX: ByteSequence* - key (uninitialized)
;	RDX: qword - key length
;
; Return value:
;	RAX: ByteSequence* - key (caller must free)
OneTimePadGenKey proc
	key equ [rbp + 16]
	key_size equ [rbp + 24]
	; Prologue
	push rbp
	mov rbp, rsp
	push rbx
	push r12
	push r13
	mov key, rcx
	mov key_size, rdx
	sub rsp, 40
	
	; Init ByteSequence (key)
    call CreateBS

	; Generating random byte sequence
	mov rbx, [rax + ByteSequence.data]
	mov r12, 0
	mov r13, key_size
	jmp condition
cycle:
	call GenRandom8
	mov [rbx + r12], al
	inc r12
condition:
	cmp r12, r13
	jb cycle

	mov rax, key

	; Epilogue
	add rsp, 40
	pop r13
	pop r12
	pop rbx
	mov rsp, rbp
	pop rbp
	ret
OneTimePadGenKey endp
end