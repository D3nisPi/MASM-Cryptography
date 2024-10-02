include .\include\common\byte_sequence.inc
include .\include\common\padding.inc
include .\include\common\random.inc

BLOCK_SIZE equ 8

.const
    ; Some tables differ from original
    ; They were changed because of bit indexing in original tables (from most significant)
    ip_table \
    byte 57, 49, 41, 33, 25, 17,  9,  1, 59, 51, 43, 35, 27, 19, 11,  3
    byte 61, 53, 45, 37, 29, 21, 13,  5, 63, 55, 47, 39, 31, 23, 15,  7
    byte 56, 48, 40, 32, 24, 16,  8,  0, 58, 50, 42, 34, 26, 18, 10,  2
    byte 60, 52, 44, 36, 28, 20, 12,  4, 62, 54, 46, 38, 30, 22, 14,  6

    inv_ip_table \
    byte 39,  7, 47, 15, 55, 23, 63, 31, 38,  6, 46, 14, 54, 22, 62, 30
    byte 37,  5, 45, 13, 53, 21, 61, 29, 36,  4, 44, 12, 52, 20, 60, 28
    byte 35,  3, 43, 11, 51, 19, 59, 27, 34,  2, 42, 10, 50, 18, 58, 26
    byte 33,  1, 41,  9, 49, 17, 57, 25, 32,  0, 40,  8, 48, 16, 56, 24

    e_table \
    byte 31,  0,  1,  2,  3,  4
    byte  3,  4,  5,  6,  7,  8
    byte  7,  8,  9, 10, 11, 12
    byte 11, 12, 13, 14, 15, 16
    byte 15, 16, 17, 18, 19, 20
    byte 19, 20, 21, 22, 23, 24
    byte 23, 24, 25, 26, 27, 28
    byte 27, 28, 29, 30, 31,  0

    p_table \
    byte  7, 28, 21, 10, 26,  2, 19, 13
    byte 23, 29,  5,  0, 18,  8, 24, 30
    byte 22,  1, 14, 27,  6,  9, 17, 31
    byte 15,  4, 20,  3, 11, 12, 25, 16

    sbox1 \
    byte 14,  4, 13,  1,  2, 15, 11,  8,  3, 10,  6, 12,  5,  9,  0,  7
    byte  0, 15,  7,  4, 14,  2, 13,  1, 10,  6, 12, 11,  9,  5,  3,  8
    byte  4,  1, 14,  8, 13,  6,  2, 11, 15, 12,  9,  7,  3, 10,  5,  0
    byte 15, 12,  8,  2,  4,  9,  1,  7,  5, 11,  3, 14, 10,  0,  6, 13

    sbox2 \
    byte 15,  1,  8, 14,  6, 11,  3,  4,  9,  7,  2, 13, 12,  0,  5, 10
    byte  3, 13,  4,  7, 15,  2,  8, 14, 12,  0,  1, 10,  6,  9, 11,  5
    byte  0, 14,  7, 11, 10,  4, 13,  1,  5,  8, 12,  6,  9,  3,  2, 15
    byte 13,  8, 10,  1,  3, 15,  4,  2, 11,  6,  7, 12,  0,  5, 14,  9

    sbox3 \
    byte 10,  0,  9, 14,  6,  3, 15,  5,  1, 13, 12,  7, 11,  4,  2,  8
    byte 13,  7,  0,  9,  3,  4,  6, 10,  2,  8,  5, 14, 12, 11, 15,  1
    byte 13,  6,  4,  9,  8, 15,  3,  0, 11,  1,  2, 12,  5, 10, 14,  7
    byte  1, 10, 13,  0,  6,  9,  8,  7,  4, 15, 14,  3, 11,  5,  2, 12

    sbox4 \
    byte  7, 13, 14,  3,  0,  6,  9, 10,  1,  2,  8,  5, 11, 12,  4, 15
    byte 13,  8, 11,  5,  6, 15,  0,  3,  4,  7,  2, 12,  1, 10, 14,  9
    byte 10,  6,  9,  0, 12, 11,  7, 13, 15,  1,  3, 14,  5,  2,  8,  4
    byte  3, 15,  0,  6, 10,  1, 13,  8,  9,  4,  5, 11, 12,  7,  2, 14

    sbox5 \
    byte  2, 12,  4,  1,  7, 10, 11,  6,  8,  5,  3, 15, 13,  0, 14,  9
    byte 14, 11,  2, 12,  4,  7, 13,  1,  5,  0, 15, 10,  3,  9,  8,  6
    byte  4,  2,  1, 11, 10, 13,  7,  8, 15,  9, 12,  5,  6,  3,  0, 14
    byte 11,  8, 12,  7,  1, 14,  2, 13,  6, 15,  0,  9, 10,  4,  5,  3

    sbox6 \
    byte 12,  1, 10, 15,  9,  2,  6,  8,  0, 13,  3,  4, 14,  7,  5, 11
    byte 10, 15,  4,  2,  7, 12,  9,  5,  6,  1, 13, 14,  0, 11,  3,  8
    byte  9, 14, 15,  5,  2,  8, 12,  3,  7,  0,  4, 10,  1, 13, 11,  6
    byte  4,  3,  2, 12,  9,  5, 15, 10, 11, 14,  1,  7,  6,  0,  8, 13

    sbox7 \
    byte  4, 11,  2, 14, 15,  0,  8, 13,  3, 12,  9,  7,  5, 10,  6,  1
    byte 13,  0, 11,  7,  4,  9,  1, 10, 14,  3,  5, 12,  2, 15,  8,  6
    byte  1,  4, 11, 13, 12,  3,  7, 14, 10, 15,  6,  8,  0,  5,  9,  2
    byte  6, 11, 13,  8,  1,  4, 10,  7,  9,  5,  0, 15, 14,  2,  3, 12

    sbox8 \
    byte 13,  2,  8,  4,  6, 15, 11,  1, 10,  9,  3, 14,  5,  0, 12,  7
    byte  1, 15, 13,  8, 10,  3,  7,  4, 12,  5,  6, 11,  0, 14,  9,  2
    byte  7, 11,  4,  1,  9, 12, 14,  2,  0,  6, 10, 13, 15,  3,  5,  8
    byte  2,  1, 14,  7,  4, 10,  8, 13, 15, 12,  9,  0,  3,  5,  6, 11

    sbox \
    qword offset sbox1
    qword offset sbox2
    qword offset sbox3
    qword offset sbox4
    qword offset sbox5
    qword offset sbox6
    qword offset sbox7
    qword offset sbox8

    key_ip_table \
    byte 60, 52, 44, 36, 59, 51, 43, 35, 27, 19, 11,  3, 58, 50
    byte 42, 34, 26, 18, 10,  2, 57, 49, 41, 33, 25, 17,  9,  1
    byte 28, 20, 12,  4, 61, 53, 45, 37, 29, 21, 13,  5, 62, 54
    byte 46, 38, 30, 22, 14,  6, 63, 55, 47, 39, 31, 23, 15,  7

    key_round_shifts \
    byte 1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1

    key_round_table \
    byte 24, 27, 20,  6, 14, 10,  3, 22,  0, 17,  7, 12,  8, 23, 11,  5
    byte 16, 26,  1,  9, 19, 25,  4, 15, 54, 43, 36, 29, 49, 40, 48, 30
    byte 52, 44, 37, 33, 46, 35, 50, 41, 28, 53, 51, 55, 32, 45, 39, 42

.data
    keys qword 16 dup(0)
.code
; Des encryption
;
; Parameters:
;   RCX: ByteSequence* - encrypted text (uninitialized)
;   RDX: ByteSequence* - plaintext
;   R8: qword - key
;
; Return value:
;   RAX: ByteSequence* - encrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
DesEncrypt proc
    local buffer: ByteSequence
    encrypted_text equ [rbp + 16]
    key equ [rbp + 32]
    ; Prologue
    mov encrypted_text, rcx
    mov key, r8
    sub rsp, 32

    ; Add padding
    lea rcx, buffer
    mov r8b, BLOCK_SIZE
    call AddPadding

    ; Encryption
    mov rcx, encrypted_text
    mov rdx, rax
    mov r8, key
    call DesEncryptWithoutPadding

    ; Free buffer
    lea rcx, buffer
    call FreeBS

    mov rax, encrypted_text

    ; Epilogue
    add rsp, 32
    ret
DesEncrypt endp

; Des encryption without padding (used for TripleDes)
;
; Parameters:
;   RCX: ByteSequence* - encrypted text (uninitialized)
;   RDX: ByteSequence* - plaintext
;   R8: qword - key
;
; Return value:
;   RAX: ByteSequence* - encrypted text (caller must free)
DesEncryptWithoutPadding proc
    encrypted_text equ [rbp + 16]
    text equ [rbp + 24]
    key equ [rbp + 32]
    ; Prologue
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    mov encrypted_text, rcx
    mov text, rdx
    sub rsp, 32

    ; Get round keys
    mov rcx, r8
    call GetRoundKeys

    ; Init encrypted_text fields
    mov rcx, encrypted_text
    mov rdx, text
    mov rdx, [rdx + ByteSequence.data_size]
    call CreateBS
    
    ; Encryption
    ; r12 - offset
    ; r13 - text data
    ; r14 - encrypted text data
    ; r15 - length
    mov r12, 0
    mov r13, text
    mov r13, [r13 + ByteSequence.data]
    mov r14, [rax + ByteSequence.data]
    mov r15, [rax + ByteSequence.data_size]
cycle:
    mov rcx, [r13 + r12]

    call DesEncryptBlock

    mov [r14 + r12], rax

    add r12, BLOCK_SIZE
condition:
    cmp r12, r15
    jb cycle
   
    mov rax, encrypted_text

    ; Epilogue
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    mov rsp, rbp
    pop rbp
    ret
DesEncryptWithoutPadding endp

; Encrypts one block of plaintext
;
; Parameters:
;   RCX: qword - block
;
; Return value:
;   RAX: qword - encrypted block
DesEncryptBlock proc
    ; Prologue
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40

    call InitialPermutation

    ; Encryption rounds
    ; r12d - L_i
    ; r13d - R_i
    ; r14d - temp
    ; r15b - counter
    lea rbx, keys
    mov r12, rax
    shr r12, 32
    mov r13d, eax
    mov r15, 0
cycle:
    mov r14d, r12d
    ; Update L
    mov r12d, r13d 
    
    ; Feistel function
    mov ecx, r13d
    mov rdx, [rbx + r15 * 8]
    call DesRoundFunction

    ; Update R
    mov r13d, eax
    xor r13d, r14d

    inc r15b
condition:
    cmp r15b, 16
    jb cycle

    ; Concatenate
    mov ecx, r12d
    shl r13, 32
    or rcx, r13

    call InverseInitialPermutation

    ; Epilogue
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret
DesEncryptBlock endp

; Des decryption
;
; Parameters:
;   RCX: ByteSequence* - decrypted text (uninitialized)
;   RDX: ByteSequence* - encrypted text
;   R8: qword - key
;
; Return value:
;   RAX: ByteSequence* - decrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
DesDecrypt proc
    local buffer: ByteSequence
    decrypted_text equ [rbp + 16]
    text equ [rbp + 24]
    key equ [rbp + 32]
    ; Prologue
    mov decrypted_text, rcx
    mov text, rdx
    mov key, r8
    sub rsp, 32

    lea rcx, buffer
    call DesDecryptWithoutPadding
   
    ; Remove padding
    mov rcx, decrypted_text
    mov rdx, rax
    call RemovePadding

    ; Free buffer
    lea rcx, buffer
    call FreeBS

    mov rax, decrypted_text

    ; Epilogue
    add rsp, 32
    ret
DesDecrypt endp

; Des decryption without removing padding (used for TripleDes)
;
; Parameters:
;   RCX: ByteSequence* - decrypted text (uninitialized)
;   RDX: ByteSequence* - encrypted text
;   R8: qword - key
;
; Return value:
;   RAX: ByteSequence* - decrypted text (caller must free)
DesDecryptWithoutPadding proc
    decrypted_text equ [rbp + 16]
    text equ [rbp + 24]
    key equ [rbp + 32]
    ; Prologue
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    mov decrypted_text, rcx
    mov text, rdx
    sub rsp, 32

    ; Get round keys
    mov rcx, r8
    call GetRoundKeys

    ; Init decrypted_text fields
    mov rcx, decrypted_text
    mov rdx, text
    mov rdx, [rdx + ByteSequence.data_size]
    call CreateBS
    
    ; Decryption rounds
    ; r12 - offset
    ; r13 - text data
    ; r14 - decrypted text data
    ; r15 - length
    mov r12, 0
    mov r13, text
    mov r13, [r13 + ByteSequence.data]
    mov r14, [rax + ByteSequence.data]
    mov r15, [rax + ByteSequence.data_size]
cycle:
    mov rcx, [r13 + r12]

    call DesDecryptBlock

    mov [r14 + r12], rax

    add r12, BLOCK_SIZE
condition:
    cmp r12, r15
    jb cycle

    mov rax, decrypted_text

    ; Epilogue
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    mov rsp, rbp
    pop rbp
    ret
DesDecryptWithoutPadding endp

; Decrypts one block of ciphertext
;
; Parameters:
;   RCX: qword - block
;
; Return value:
;   RAX: qword - decrypted block
DesDecryptBlock proc
    ; Prologue
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40

    call InitialPermutation

    ; r12d - L_i
    ; r13d - R_i
    ; r14d - temp
    ; r15b - counter
    lea rbx, keys
    mov r12, rax
    shr r12, 32
    mov r13d, eax
    
    mov r15, 15
cycle:
    mov r14d, r12d
    ; Update L
    mov r12d, r13d 
    
    ; Feistel function
    mov ecx, r13d
    mov rdx, [rbx + r15 * 8]
    call DesRoundFunction

    ; Update R
    mov r13d, eax
    xor r13d, r14d

    dec r15b
condition:
    cmp r15b, 0
    jge cycle

    ; Concatenate
    mov ecx, r12d
    shl r13, 32
    or rcx, r13

    call InverseInitialPermutation

    ; Epilogue
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret
DesDecryptBlock endp

; Generates key for des cipher
;
; No parameters
;
; Return value:
;   RAX: qword - key
DesGenKey proc
    ; Prologue
    push r12
    push r13
    sub rsp, 40

    mov r12, 0
    mov r13, 0
cycle:
    shl r13, 8

    ; Generate random 7 bits
    call GenRandom8
    shr al, 1
    mov r13b, al

    ; Count bits
    movzx ax, al
    popcnt dx, ax

    ; New bit
    not dx
    and dx, 1

    ; Set new bit
    shl dl, 7
    or r13b, dl

    inc r12
condtion:
    cmp r12, 8
    jb cycle

    mov rax, r13

    ; Epilogue
    add rsp, 40
    pop r13
    pop r12
    ret
DesGenKey endp

; Calculate round keys
;
; Parameters:
;   RCX: qword - initial key
;
; No return value
GetRoundKeys proc
    ; Prologue
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32

    call InitialKeyPermutation

    mov r12, 0  
    mov r13, rax
    lea r14, key_round_shifts
    lea r15, keys
cycle:
    mov rcx, r13
    mov dl, [r14 + r12]
    call KeyRotateLeft
    mov r13, rax

    mov rcx, rax
    call RoundKeyPermutation
    mov [r15 + r12 * 8], rax

    inc r12
condition:
    cmp r12, 16
    jb cycle

    ; Epilogue
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    mov rsp, rbp
    pop rbp
    ret
GetRoundKeys endp

; Rotates key (CD) to the left (separately C and D)
; C - 0..27 bit
; D - 28..55 bit
;
; Parameters:
;   RCX: qword - 56 bit key
;   DL: byte - shift size
;
; Return value:
;   RAX: qword - rotated key
option prologue:PrologueDef
option epilogue:EpilogueDef
KeyRotateLeft proc
    local first_part: dword
    key equ [rbp + 16]
    shift_size equ [rbp + 24]
    mask28 equ 0FFFFFFFh
    ; Prologue
    mov key, rcx
    mov shift_size, dl
    sub rsp, 40

    ; Rotate C
    and ecx, mask28
    call RotateLeft28
    mov first_part, eax

    ; Rotate D
    mov rcx, key
    shr rcx, 28
    and ecx, mask28
    mov dl, shift_size
    call RotateLeft28
    
    ; Merge CD
    shl rax, 28
    mov edx, first_part
    or rax, rdx

    add rsp, 40
    ret
KeyRotateLeft endp

; Rotates 28 first bits of value to the left
;
; Parameters:
;   ECX: dword - 28 bit number
;   DL: byte - shift size
;
; Return value;
;   EAX: dword - rotated value
RotateLeft28 proc
    mask28 equ 0FFFFFFFh
    mov r8d, ecx
    and r8d, mask28

    mov eax, r8d
    mov cl, dl
    shl eax, cl

    neg dl
    add dl, 28
    mov cl, dl
    mov edx, r8d
    shr edx, cl

    or eax, edx
    and eax, mask28
    ret
RotateLeft28 endp

; Feistel function
; 
; Parameters:
;   ECX: dword - R_(i-1)
;   RDX: qword - 48 bit key
;
; Return value:
;   EAX: dword - Feistel function result
DesRoundFunction proc
    key equ [rbp + 24]
    ; Prologue
    push rbp
    mov rbp, rsp
    mov key, rdx
    sub rsp, 32
    
    ; 1. E extension
    call FeistelExtension

    ; 2. XOR with key
    xor rax, key

    ; 3. SBox
    mov rcx, rax
    call SBoxTransformation

    ; 4. P permutation
    mov ecx, eax
    call FeistelPermutation

    ; Epilogue
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret
DesRoundFunction endp

; Performs transformation using S blocks
;
; Parameters:
;   RCX: qword - 48 bit vector (B1 B2 B3 B4 B5 B6 B7 B8), Bi is a 6-bit block
;
; Return value:
;   EAX: dword - 32 bit vector (B'1 B'2 B'3 B'4 B'5 B'6 B'7 B'8), Bi is a 4-bit block
SBoxTransformation proc
    ; cl - buffer for shift values
    ; r8 - source
    ; r9d - result
    mov rdx, 0
    mov r8, rcx
    mov r9d, 0
cycle:
    mov cl, 42
    mov al, dl
    mov r10b, 6
    mul r10b
    sub cl, al

    ; Get 6 bits
    mov rax, 111111b
    shl rax, cl
    and rax, r8
    shr rax, cl

    ; Row: 5th and 0th bits
    mov r10b, 100000b
    and r10b, al
    shr r10b, 4
    mov r11b, 000001b
    and r11b, al
    or r10b, r11b

    ; Column: 4th - 1st bits
    mov r11b, 011110b
    and r11b, al
    shr r11b, 1

    ; Get an index
    mov al, r10b
    shl al, 4
    add al, r11b
    
    lea r10, sbox
    mov rcx, [r10 + rdx * 8]
    movzx eax, byte ptr [rcx + rax]

    ; Compute index for writing
    mov cl, 28
    mov r10b, dl
    shl r10b, 2
    sub cl, r10b

    ; Write result
    shl eax, cl
    or r9d, eax

    inc rdx
condition:
    cmp rdx, 8
    jb cycle

    mov eax, r9d

    ret
SBoxTransformation endp

; Initial permutation
;
; Parameters:
;   RCX: qword - block
;
; Return value:
;   RAX: qword - permutated block
InitialPermutation proc
    sub rsp, 40
    lea rdx, ip_table
    mov r8b, 64
    call BitPermutation

    add rsp, 40
    ret
InitialPermutation endp

; Inverse initial permutation
;
; Parameters:
;   RCX: qword - block
;
; Return value:
;   RAX: qword - permutated block
InverseInitialPermutation proc
    sub rsp, 40
    lea rdx, inv_ip_table
    mov r8b, 64
    call BitPermutation

    add rsp, 40
    ret
InverseInitialPermutation endp

; Extension 32 -> 48 bit in Feistel function
;
; Parameters:
;   ECX: dword - 32 bit block R
;
; Return value:
;   RAX: qword - 48 bit block R
FeistelExtension proc
    sub rsp, 40
    lea rdx, e_table
    mov r8b, 48
    call BitPermutation

    add rsp, 40
    ret
FeistelExtension endp

; Permutation in Feistel function
;
; Parameters:
;   ECX: qword - block
;
; Return value:
;   EAX: qword - permutated block
FeistelPermutation proc
    sub rsp, 40
    lea rdx, p_table
    mov r8b, 32
    call BitPermutation

    add rsp, 40
    ret
FeistelPermutation endp

; Permutation initial key
;
; Parameters:
;   RCX: qword - initial key
;
; Return value:
;   RAX: qword - permutated initial key
InitialKeyPermutation proc
    sub rsp, 40
    lea rdx, key_ip_table
    mov r8b, 56
    call BitPermutation

    add rsp, 40
    ret
InitialKeyPermutation endp

; Permutation round key
;
; Parameters:
;   RCX: qword - round key
;
; Return value:
;   RAX: qword - permutated round key
RoundKeyPermutation proc
    sub rsp, 40
    lea rdx, key_round_table
    mov r8b, 48
    call BitPermutation

    add rsp, 40
    ret
RoundKeyPermutation endp

; Permuatates bits
;
; Parameters:
;   RCX: qword - data
;   RDX: byte* - permutation table
;   R8b: byte - length
BitPermutation proc
    ; cl - shift value
    ; dl - counter
    ; r8b - length
    ; r9 - table
    ; r10 - source
    ; r11 - result
    mov r9, rdx
    mov r10, rcx
    mov r11, 0
    mov rdx, 0
    jmp condition
cycle:
    mov cl, [r9 + rdx]

    mov rax, 1
    shl rax, cl
    and rax, r10
    shr rax, cl

    mov cl, dl
    shl rax, cl
    or r11, rax
    shr rax, cl

    inc dl
condition:
    cmp dl, r8b
    jb cycle

    mov rax, r11

    ret
BitPermutation endp
end