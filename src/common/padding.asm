include .\include\common\byte_sequence.inc

.code
; Adds padding to text
;
; Parameters:
;   RCX: ByteSequence* - padded text (to be padded)
;   RDX: ByteSequence* - text
;   R8B: byte - block size (2^n, n in [0, 7])
;
; Return value:
;   RAX: ByteSequence* - padded text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
AddPadding proc
	local new_size: qword
	local padding_size: byte
	padded_text equ [rbp + 16]
	text equ [rbp + 24]
	block_size equ [rbp + 32]
	; Prologue
	push rsi
	push rdi
	mov padded_text, rcx
	mov text, rdx
	mov block_size, r8b
	sub rsp, 32

	; Check if data_size is 0xF...F (max value)
	mov rax, [rdx + ByteSequence.data_size]
	cmp rax, 0FFFFFFFFFFFFFFFFh
	je no_padding

	; Computing amount of bytes to add
	; padding_size = block_size - (text.data_size % block_size)
	movzx r8, r8b
	mov rdx, r8
	dec rdx
	and rdx, rax
	sub r8, rdx
	mov padding_size, r8b

	; Computing new size
	; new_size = text.data_size + padding_size
	add rax, r8
	mov new_size, rax

	; Init ByteSequence fields
	mov rcx, padded_text
	mov rdx, rax
	call CreateBS
	
	; Copy data
	mov rcx, text
	mov rdx, rax
	call CopyBSData

	; Padding
	; rcx - index
	; dl - padding size
	; r8 - padded_text data
	; r9 - new size
	mov rcx, text
	mov rcx, [rcx + ByteSequence.data_size]
	mov dl, padding_size
	mov r8, padded_text
	mov r8, [r8 + ByteSequence.data]
	mov r9, new_size
cycle:
	mov [r8 + rcx], dl
	inc rcx
condition:
	cmp rcx, r9
	jb cycle

	mov rax, padded_text
	; Epilogue
	add rsp, 32
	pop rdi
	pop rsi
	ret
no_padding:
	; Init ByteSequence fields
	mov rcx, padded_text
	mov rdx, rax
	call CreateBS
	
	; Copy data
	mov rcx, text
	mov rdx, rax
	call CopyBSData

	mov rax, padded_text
	; Epilogue
	add rsp, 32
	pop rdi
	pop rsi
	ret
AddPadding endp

; Removes padding from the text
;
; Parameters:
; 	RCX: ByteSequence* - text with removed padding (uninitialized)
; 	RDX: ByteSequence* - padded text
;
; Return value:
; 	RAX: ByteSequence* - text with removed padding
RemovePadding proc
	text equ [rbp + 16]
	padded_text equ [rbp + 24]
	; Prologue
	push rbp
	mov rbp, rsp
	mov text, rcx
	mov padded_text, rdx
	sub rsp, 40

	; Check if data_size is 0xF...F (max value)
	mov rax, [rdx + ByteSequence.data_size]
	cmp rax, 0FFFFFFFFFFFFFFFFh
	je no_padding

	mov rdx, [rdx + ByteSequence.data]
	movzx rdx, byte ptr [rdx + rax - 1] ; last value
	sub rax, rdx

	; Check if result is < 0 (invalid decryption)
	cmp rax, 0
	jge no_padding
	mov rax, 0
no_padding:
	; Init ByteSequence fields
	mov rcx, text
	mov rdx, rax
	call CreateBS

	; Copy data
	mov rcx, padded_text
	mov rdx, rax
	call CopyBSData

	mov rax, text
	; Epilogue
	add rsp, 40
	mov rsp, rbp
	pop rbp
	ret
RemovePadding endp
end