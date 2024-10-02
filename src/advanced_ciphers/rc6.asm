include .\include\common\byte_sequence.inc
include .\include\common\padding.inc
include .\include\common\random.inc

BLOCK_SIZE = 16

.const
    P dword 0B7E15163h
    Q dword 09E3779B9h
.data
    L dword 64 dup(0)
    S dword 514 dup(0)
    L_length qword 0
    S_length qword 0
.code
; RC6 encryption
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
RC6Encrypt proc
    local buffer: ByteSequence
    local text_block: oword
    encrypted_text equ [rbp + 16]
    text equ [rbp + 24]
    key equ [rbp + 32]
    rounds equ [rbp + 40]
    ; Prologue
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    mov encrypted_text, rcx
    mov text, rdx
    mov key, r8
    mov rounds, r9b
    sub rsp, 32

    ; Initialize array L with key
    mov rcx, r8
    call RC6InitArrayL

    ; Initialize S table with constant values
    mov cl, rounds
    call RC6InitTableS

    ; Shuffle L and S
    call RC6Shuffle

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
    ; rsi - buffer data
    ; rdi - ecnrypted text data
    ; r12 - offset
    ; r13b - number of rounds
    ; r14 - block ptr
    ; r15 - length
    lea rsi, buffer
    mov rsi, [rsi + ByteSequence.data]
    mov rdi, [rax + ByteSequence.data]
    mov r12, 0
    mov r13b, rounds
    lea r14, text_block
    mov r15, [rax + ByteSequence.data_size]
    jmp condition
cycle:
    movdqa xmm0, [rsi + r12]
    movdqa text_block, xmm0

    mov rcx, r14
    mov dl, r13b
    call RC6EncryptBlock

    movdqa xmm0, text_block
    movdqa [rdi + r12], xmm0

    add r12, BLOCK_SIZE
condition:
    cmp r12, r15
    jb cycle

    ; Free buffer
    lea rcx, buffer
    call FreeBS

    mov rax, encrypted_text

    ; Epilogue
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    ret
RC6Encrypt endp

; Encrypts one 128-bit block with rc6 cipher
;
; Parameters:
;   RCX: oword* - 128-bit block
;   DL: byte - number of rounds
;
; Return values:
;   RAX: oword* - encrypted 128-bit block
RC6EncryptBlock proc
    block equ [rbp + 16]
    ; Prologue
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov block, rcx

    ; rbx - S
    ; r8d - A
    ; r9d - B
    ; r10d - C
    ; r11d - D
    ; r12 - counter
    ; r13 - number of rounds
    ; r14 - t
    ; r15 - u
    lea rbx, S
    mov r8d, [rcx]
    mov r9d, [rcx + 4]
    mov r10d, [rcx + 8]
    mov r11d, [rcx + 12]
    mov r12, 1
    movzx r13, dl

    add r9d, [rbx]
    add r11d, [rbx + 4]

    jmp condition
cycle:
    ; t = (B(2B + 1)) <<< lg w
    mov eax, r9d
    mov edx, r9d
    shl edx, 1
    inc edx
    mul edx
    rol eax, 5
    mov r14d, eax

    ; u = (D(2D + 1)) <<< lg w
    mov eax, r11d
    mov edx, r11d
    shl edx, 1
    inc edx
    mul edx
    rol eax, 5
    mov r15d, eax

    ; A = ((A xor t) <<< u) + S[2i]
    xor r8d, r14d
    mov ecx, r15d
    and ecx, 31
    rol r8d, cl
    add r8d, [rbx + r12 * 8]

    ; C = ((C xor u) <<< t) + S[2i + 1]
    xor r10d, r15d
    mov ecx, r14d
    and ecx, 31
    rol r10d, cl
    add r10d, [rbx + r12 * 8 + 4]

    ; (A, B, C, D)  =  (B, C, D, A)
    mov ecx, r8d
    mov r8d, r9d
    mov r9d, r10d
    mov r10d, r11d
    mov r11d, ecx

    inc r12
condition:
    cmp r12, r13
    jbe cycle

    add r8d, [rbx + r12 * 8]
    add r10d, [rbx + r12 * 8 + 4]

    mov rax, block
    mov [rax], r8d
    mov [rax + 4], r9d
    mov [rax + 8], r10d
    mov [rax + 12], r11d

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret
RC6EncryptBlock endp

; RC6 decryption
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
RC6Decrypt proc
    local buffer: ByteSequence
    local text_block: oword
    decrypted_text equ [rbp + 16]
    text equ [rbp + 24]
    key equ [rbp + 32]
    rounds equ [rbp + 40]
    ; Prologue
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    mov decrypted_text, rcx
    mov text, rdx
    mov key, r8
    mov rounds, r9b
    sub rsp, 32

    ; Initialize array L with key
    mov rcx, r8
    call RC6InitArrayL

    ; Initialize S table with constant values
    mov cl, rounds
    call RC6InitTableS

    ; Shuffle L and S
    call RC6Shuffle

    ; Init buffer
    lea rcx, buffer
    mov rdx, text
    mov rdx, [rdx + ByteSequence.data_size]
    call CreateBS
    
    ; Decryption
    ; rsi - text data
    ; rdi - buffer data
    ; r12 - offset
    ; r13b - number of rounds
    ; r14 - block ptr
    ; r15 - length
    mov rsi, text
    mov rsi, [rsi + ByteSequence.data]
    mov rdi, [rax + ByteSequence.data]
    mov r12, 0
    mov r13b, rounds
    lea r14, text_block
    mov r15, [rax + ByteSequence.data_size]
    jmp condition
cycle:
    movdqa xmm0, [rsi + r12]
    movdqa text_block, xmm0

    mov rcx, r14
    mov dl, r13b
    call RC6DecryptBlock

    movdqa xmm0, text_block
    movdqa [rdi + r12], xmm0

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
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    ret
RC6Decrypt endp

; Decrypts one 128-bit block with rc6 cipher
;
; Parameters:
;   RCX: oword* - 128-bit block
;   DL: byte - number of rounds
;
; Return values:
;   RAX: oword* - decrypted 128-bit block
RC6DecryptBlock proc
    block equ [rbp + 16]
    ; Prologue
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    mov block, rcx

    ; r8d - A
    ; r9d - B
    ; r10d - C
    ; r11d - D
    ; r12 - counter
    ; r13 - S
    ; r14 - t
    ; r15 - u
    mov r8d, [rcx]
    mov r9d, [rcx + 4]
    mov r10d, [rcx + 8]
    mov r11d, [rcx + 12]
    movzx r12, dl
    lea r13, S

    sub r10d, [r13 + r12 * 8 + 12]
    sub r8d, [r13 + r12 * 8 + 8]

    jmp condition
cycle:
    ; (A, B, C, D) = (D, A, B, C)
    mov eax, r11d
    mov r11d, r10d
    mov r10d, r9d
    mov r9d, r8d
    mov r8d, eax

    ; u = (D(2D + 1)) <<< lg w
    mov eax, r11d
    mov edx, r11d
    shl edx, 1
    inc edx
    mul edx
    rol eax, 5
    mov r15d, eax

    ; t = (B(2B + 1)) <<< lg w
    mov eax, r9d
    mov edx, r9d
    shl edx, 1
    inc edx
    mul edx
    rol eax, 5
    mov r14d, eax

    ; C = ((C - S[2i + 1]) >>> t) xor u
    sub r10d, [r13 + r12 * 8 + 4]
    mov ecx, r14d
    and ecx, 31
    ror r10d, cl
    xor r10d, r15d

    ; A = ((A - S[2i]) >>> u) xor t
    sub r8d, [r13 + r12 * 8]
    mov ecx, r15d
    and ecx, 31
    ror r8d, cl
    xor r8d, r14d

    dec r12
condition:
    cmp r12, 1
    jge cycle

    sub r11d, [r13 + 4]
    sub r9d, [r13]

    mov rax, block
    mov [rax], r8d
    mov [rax + 4], r9d
    mov [rax + 8], r10d
    mov [rax + 12], r11d

    pop r15
    pop r14
    pop r13
    pop r12
    mov rsp, rbp
    pop rbp
    ret
RC6DecryptBlock endp

; Initialized L array with key
; 
; Parameters:
;   RCX: ByteSequence* - key
;
; No return value
RC6InitArrayL proc
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

    ; Fill next bytes of L with 0 while rcx % 4 != 0
    jmp fill_condition
fill_cycle:
    mov byte ptr [r9 + rcx], 0
    inc rcx
fill_condition:
    test rcx, 3
    jnz fill_cycle

    shr rcx, 2
    mov L_length, rcx

    ret
zero_length_key:
    lea rax, L
    mov dword ptr [rax], 0

    mov L_length, 1

    ret
RC6InitArrayL endp

; Initialize S table with constant values
;
; Parameters:
;   CL: byte - number of rounds
;
; No return value
RC6InitTableS proc
    ; rcx - counter
    ; rdx - s table length (2 * rounds + 4)
    ; r8 - s table
    ; r9d - value
    movzx rdx, cl
    shl rdx, 1
    add rdx, 4
    mov rcx, 1
    lea r8, S

    mov r9d, P
    mov [r8], r9d
    jmp condition
cycle:
    add r9d, Q
    mov [r8 + rcx * 4], r9d
    inc rcx
condition:
    cmp rcx, rdx
    jb cycle

    mov S_length, rdx

    ret
RC6InitTableS endp

; Shuffle L array and S table
;
; No parameters
;
; No return value
RC6Shuffle proc
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; S length = 2 * r + 4
    mov r14, S_length

    ; c = b / 4
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
    ; r10d - A = 0
    ; r11d - B = 0
    ; r12 - S table
    ; r13 - L array
    ; r14w - S length
    ; r15b - L length
    mov r8, 0
    mov r9, 0
    mov r10d, 0
    mov r11d, 0
    lea r12, S
    lea r13, L
    jmp condition
cycle:
    ; A = S[i] = (S[i] + A + B) <<< 3
    mov eax, [r12 + r8 * 4]
    add eax, r10d
    add eax, r11d
    rol eax, 3
    mov [r12 + r8 * 4], eax
    mov r10d, eax

    ; B = L[j] = (L[j] + A + B) <<< (A + B)
    mov ecx, r10d
    add ecx, r11d
    mov eax, [r13 + r9 * 4]
    add eax, ecx
    and ecx, 31
    rol eax, cl
    mov [r13 + r9 * 4], eax
    mov r11d, eax

    ; i = (i + 1) mod S_length
    ; 4 <= S_length <= 514
    inc r8
    mov dx, 0
    mov ax, r8w
    div r14w
    movzx r8, dx

    ; j = (j + 1) mod L_length
    ; 1 <= L_length <= 64
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
RC6Shuffle endp

; Generates key for rc6 cipher
;
; Parameters:
;   RCX: ByteSequence* - key (uninitialized)
;   DL: byte - key length
;
; Return value:
;   RAX: ByteSequence* - key (caller must free)
RC6GenKey proc
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
RC6GenKey endp
end