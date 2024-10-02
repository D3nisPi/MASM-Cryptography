include .\include\lib\kernel32.inc

.code
; Сonverts a 32bit unsigned integer to a string (caller must free)
;
; Parameters:
;	ECX: dword - number
;
; Return value:
;	RAX: byte* - c-style string
option prologue:PrologueDef
option epilogue:EpilogueDef
DWordToStr proc
	local string_length: byte
    number equ [rbp + 16]
	; Prologue
	push rsi
	push rdi
    mov number, ecx
	sub rsp, 40
	
	; Zero case
	cmp rcx, 0
	je zero_case

	; Length calculation
    ; Using 64-bit registers to avoid overflow
    ; rax - number
    ; cl - number length
    ; r8d - divisor
	mov eax, ecx
	mov cl, 0
    mov r8d, 10
	jmp length_condition
length_cycle:
	mov rdx, rax
	shr rdx, 32
	div r8d
	inc cl
length_condition:
	cmp rax, 0
	ja length_cycle

	mov string_length, cl

	; Memory allocation
    call GetProcessHeap
    mov rcx, rax
    mov edx, 0
	movzx r8, string_length
	inc r8
    call HeapAlloc
	mov r9, rax

	; Getting reversed string
    ; rax - number
    ; r8d - divisor
    ; rcx - index
    mov eax, number
	mov r8d, 10
	mov rcx, 0
	jmp condition
cycle:
	mov rdx, rax
	shr rdx, 32
	div r8d

    ; Adding 48 to get a string representation
	or dl, 30h
	mov [r9 + rcx], dl
	inc cl
condition:
	cmp rax, 0
	ja cycle
	
	; Reverse string and add zero byte at the end
	mov rsi, 0
	movzx rdi, string_length
	mov byte ptr [r9 + rdi], 0
	dec rdi
	jmp reverse_condition
reverse_cycle:
	mov al, [r9 + rsi]
	mov dl, [r9 + rdi]
	mov [r9 + rsi], dl
	mov [r9 + rdi], al
	inc rsi
	dec rdi
reverse_condition:
	cmp rsi, rdi
	jb reverse_cycle

	mov rax, r9
	; Epilogue
	add rsp, 40
	pop rdi
	pop rsi
	ret
zero_case:
	; Memory allocation
    call GetProcessHeap
    mov rcx, rax
    mov edx, 0
	mov r8, 2
    call HeapAlloc
	mov byte ptr [rax], 48
	mov byte ptr [rax + 1], 0

	; Epilogue
	add rsp, 40
	pop rdi
	pop rsi
	ret
DWordToStr endp
end