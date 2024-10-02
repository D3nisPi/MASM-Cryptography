include .\include\common\byte_sequence.inc
include .\include\common\padding.inc
include .\include\common\random.inc

BLOCK_SIZE = 16

.const
    P qword 0B7E151628AED2A6Bh
    Q qword 09E3779B97F4A7C15h
.data
    L qword 32 dup(0)
    S qword 512 dup(0)
    L_length qword 0
    S_length qword 0
.code
; RC5 encryption
;
; Parameters:
;   RCX: ByteSequence* - encrypted text (uninitialized)
;   RDX: ByteSequence* - plaintext
;   R8: ByteSequence* - key (length must be 0 - 255)
;   R9B: byte - number of rounds
;
; Return value:
;   RAX: ByteSequence* - encrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
RC5Encrypt proc
    local buffer: ByteSequence
    encrypted_text equ [rbp + 16]
    text equ [rbp + 24]
    key equ [rbp + 32]
    rounds equ [rbp + 40]
    ; Prologue
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov encrypted_text, rcx
    mov text, rdx
    mov key, r8
    mov rounds, r9b
	sub rsp, 40

    ; Initialize array L with key
    mov rcx, r8
    call RC5InitArrayL

    ; Initialize S table with constant values
    mov cl, rounds
    call RC5InitTableS

    ; RC5Shuffle L and S
    call RC5Shuffle

    ; Add padding
    lea rcx, buffer
    mov rdx, text
    mov r8b, BLOCK_SIZE
    call AddPadding

    ; Init encrypted_text fields
    mov rcx, encrypted_text
    mov rdx, [rax + ByteSequence.data_size]
    call CreateBS

    ; Encryption
    ; bl - number of rounds
    ; r12 - index
    ; r13 - buffer data
    ; r14 - ecnrypted text data
    ; r15 - length
    mov bl, rounds
    mov r12, 0
    lea r13, buffer
    mov r13, [r13 + ByteSequence.data]
    mov r14, [rax + ByteSequence.data]
    mov r15, [rax + ByteSequence.data_size]
    jmp condition
cycle:
    mov rcx, [r13 + r12]
    mov rdx, [r13 + r12 + 8]
    mov r8b, bl
    call RC5EncryptBlock
    mov [r14 + r12], rax
    mov [r14 + r12 + 8], rdx

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
RC5Encrypt endp

; Encrypts one 128-bit block with rc5 cipher
;
; Parameters:
;   RCX: qword - 1st part of 128-bit block (A)
;   RDX: qword - 2nd part of 128-bit block (B)
;   R8B: byte - number of rounds
;
; Return values:
;   RAX: qword - 1st part of encrypted 128-bit block
;   RDX: qword - 2nd part of encrypted 128-bit block
RC5EncryptBlock proc
    ; rdx - counter
    ; r8 - A
    ; r9 - B
    ; r10 - number of rounds
    ; r11 - S
    movzx r10, r8b
    mov r8, rcx
    mov r9, rdx
    lea r11, S
    mov rdx, 1

    add r8, [r11]
    add r9, [r11 + 8]

    jmp condition
cycle:
    shl rdx, 1

    ; A = ((A xor B) <<< B) + S[2*i]
    xor r8, r9
    mov rcx, r9
    and rcx, 63
    rol r8, cl
    add r8, [r11 + rdx * 8]

    ; B = ((A xor B) <<< A) + S[2*i + 1]
    xor r9, r8
    mov rcx, r8
    and rcx, 63
    rol r9, cl
    add r9, [r11 + rdx * 8 + 8]

    shr rdx, 1

    inc rdx
condition:
    cmp rdx, r10
    jbe cycle

    mov rax, r8
    mov rdx, r9

    ret
RC5EncryptBlock endp

; RC5 decryption
;
; Parameters:
;   RCX: ByteSequence* - decrypted text (uninitialized)
;   RDX: ByteSequence* - encrypted text
;   R8: ByteSequence* - key (length must be 0 - 255)
;   R9B: byte - number of rounds
;
; Return value:
;   RAX: ByteSequence* - decrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
RC5Decrypt proc
    local buffer: ByteSequence
    decrypted_text equ [rbp + 16]
	text equ [rbp + 24]
	key equ [rbp + 32]
    rounds equ [rbp + 40]
	; Prologue
    push rbx
    push r12
    push r13
    push r14
    push r15
	mov decrypted_text, rcx
	mov text, rdx
	mov key, r8
    mov rounds, r9b
	sub rsp, 40

    ; Initialize array L with key
    mov rcx, r8
    call RC5InitArrayL

    ; Initialize S table with constant values
    mov cl, rounds
    call RC5InitTableS

    ; RC5Shuffle L and S
    call RC5Shuffle

    ; Init buffer
    lea rcx, buffer
    mov rdx, text
    mov rdx, [rdx + ByteSequence.data_size]
    call CreateBS
    
    ; Decryption
    ; bl - number of rounds
    ; r12 - index
    ; r13 - text data
    ; r14 - buffer data
    ; r15 - length
    mov bl, rounds
    mov r12, 0
    mov r13, text
    mov r13, [r13 + ByteSequence.data]
    mov r14, [rax + ByteSequence.data]
    mov r15, [rax + ByteSequence.data_size]
    jmp condition
cycle:
    mov rcx, [r13 + r12]
    mov rdx, [r13 + r12 + 8]
    mov r8b, bl
    call RC5DecryptBlock
    mov [r14 + r12], rax
    mov [r14 + r12 + 8], rdx

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
RC5Decrypt endp

; Decrypts one 128-bit block with rc5 cipher
;
; Parameters:
;   RCX: qword - 1st part of 128-bit block (A)
;   RDX: qword - 2nd part of 128-bit block (B)
;   R8B: byte - number of rounds
;
; Return values:
;   RAX: qword - 1st part of decrypted 128-bit block
;   RDX: qword - 2nd part of decrypted 128-bit block
RC5DecryptBlock proc
    ; r8 - A
    ; r9 - B
    ; r10 - number of rounds
    ; r11 - S
    movzx r10, r8b
    mov r8, rcx
    mov r9, rdx
    lea r11, S
    jmp condition
cycle:
    shl r10, 1

    ; B = ((B - S[2*i + 1]) >>> A) xor A
    sub r9, [r11 + r10 * 8 + 8]
    mov rcx, r8
    and rcx, 63
    ror r9, cl
    xor r9, r8

    ; A = ((A - S[2*i]) >>> B) xor B
    sub r8, [r11 + r10 * 8]
    mov rcx, r9
    and rcx, 63
    ror r8, cl
    xor r8, r9

    shr r10, 1

    dec r10
condition:
    cmp r10, 1
    jae cycle

    sub r9, [r11 + 8]
    sub r8, [r11]

    mov rax, r8
    mov rdx, r9

    ret
RC5DecryptBlock endp

; Initialized L array with key
; 
; Parameters:
;   RCX: ByteSequence* - key
;
; No return value
RC5InitArrayL proc
    mov rdx, [rcx + ByteSequence.data_size]
    cmp rdx, 0
    je zero_length_key

    ; Copy key into L array
    ; rcx - counter
    ; rdx - key size
    ; r8 - key data
    ; r9 - L array
    mov r8, [rcx + ByteSequence.data]
    lea r9, L
    mov rcx, 0
    jmp copy_condition
copy_cycle:
    mov al, [r8 + rcx]
    mov [r9 + rcx], al
    inc rcx
copy_condition:
    cmp rcx, rdx
    jb copy_cycle

    ; Fill next bytes of L with 0 while rcx % 8 != 0
    jmp fill_condition
fill_cycle:
    mov byte ptr [r9 + rcx], 0
    inc rcx
fill_condition:
    test rcx, 7
    jnz fill_cycle

    shr rcx, 3
    mov L_length, rcx

    ret
zero_length_key:
    lea rax, L
    mov qword ptr [rax], 0

    mov L_length, 1

    ret
RC5InitArrayL endp

; Initialize S table with constant values
;
; Parameters:
;   CL: byte - number of rounds
;
; No return value
RC5InitTableS proc
    ; rcx - counter
    ; rdx - s table length (2 * (rounds + 1))
    ; r8 - s table
    ; r9 - value
    movzx rdx, cl
    inc rdx
    shl rdx, 1
    mov rcx, 1
    lea r8, S

    mov r9, P
    mov [r8], r9
    jmp condition
cycle:
    add r9, Q
    mov [r8 + rcx * 8], r9
    inc rcx
condition:
    cmp rcx, rdx
    jb cycle

    mov S_length, rdx

    ret
RC5InitTableS endp

; RC5Shuffle L array and S table
;
; No parameters
;
; No return value
RC5Shuffle proc
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; S length = 2 * (r + 1)
    mov r14, S_length

    ; c = b / 8
    mov r15, L_length

    ; N = 3 * max(S_lenght, L_length)
    cmp r14, r15
    jb less
    mov rax, r14
    jmp N
less:
    mov rax, r15
N:
    mov rbx, rax
    shl rbx, 1
    add rbx, rax

    ; rbx - N
    ; r8 - i = 0
    ; r9 - j = 0
    ; r10 - G = 0
    ; r11 - H = 0
    ; r12 - S table
    ; r13 - L array
    ; r14w - S length
    ; r15b - L length
    mov r8, 0
    mov r9, 0
    mov r10, 0
    mov r11, 0
    lea r12, S
    lea r13, L
    jmp condition
cycle:
    ; G = S[i] = (S[i] + G + H) <<< 3
    mov rax, [r12 + r8 * 8]
    add rax, r10
    add rax, r11
    rol rax, 3
    mov [r12 + r8 * 8], rax
    mov r10, rax

    ; H = L[j] = (L[j] + G + H) <<< (G + H)
    mov rcx, r10
    add rcx, r11
    mov rax, [r13 + r9 * 8]
    add rax, rcx
    and rcx, 63
    rol rax, cl
    mov [r13 + r9 * 8], rax
    mov r11, rax

    ; i = (i + 1) mod S_length
    ; 2 <= S_length <= 512
    inc r8
    mov dx, 0
    mov ax, r8w
    div r14w
    movzx r8, dx

    ; j = (j + 1) mod L_length
    ; 1 <= L_length <= 32
    inc r9
    mov ax, r9w
    div r15b
    mov al, ah
    movzx r9, al

    dec rbx
condition:
    cmp rbx, 0
    ja cycle

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
RC5Shuffle endp

; Generates key for rc5 cipher
;
; Parameters:
;   RCX: ByteSequence* - key (uninitialized)
;   DL: byte - key length
;
; Return value:
;   RAX: ByteSequence* - key (caller must free)
RC5GenKey proc
    key equ [rbp + 16]
	key_length equ [rbp + 24]
    ; Prologue
	push rbp
	mov rbp, rsp
	push r12
	push r13
	mov key, rcx
	sub rsp, 32

    ; Init key
	movzx rdx, dl
	call CreateBS

    ; Fill key with random values
	; r12 - index
	; r13 - key data
	mov r12, [rax + ByteSequence.data_size]
    dec r12
	mov r13, [rax + ByteSequence.data]
    jmp condition
cycle:
	call GenRandom8
    mov [r13 + r12], al
	dec r12
condition:
	cmp r12, 0
	jge cycle

	mov rax, key

    ; Epilogue
	add rsp, 32
	pop r13
	pop r12
	mov rsp, rbp
	pop rbp
	ret
RC5GenKey endp
end