include .\include\common\byte_sequence.inc
include .\include\common\padding.inc
include .\include\common\random.inc

BLOCK_SIZE equ 16

.const
    sbox \
    byte 063h, 07ch, 077h, 07bh, 0f2h, 06bh, 06fh, 0c5h, 030h, 001h, 067h, 02bh, 0feh, 0d7h, 0abh, 076h
    byte 0cah, 082h, 0c9h, 07dh, 0fah, 059h, 047h, 0f0h, 0adh, 0d4h, 0a2h, 0afh, 09ch, 0a4h, 072h, 0c0h
    byte 0b7h, 0fdh, 093h, 026h, 036h, 03fh, 0f7h, 0cch, 034h, 0a5h, 0e5h, 0f1h, 071h, 0d8h, 031h, 015h
    byte 004h, 0c7h, 023h, 0c3h, 018h, 096h, 005h, 09ah, 007h, 012h, 080h, 0e2h, 0ebh, 027h, 0b2h, 075h
    byte 009h, 083h, 02ch, 01ah, 01bh, 06eh, 05ah, 0a0h, 052h, 03bh, 0d6h, 0b3h, 029h, 0e3h, 02fh, 084h
    byte 053h, 0d1h, 000h, 0edh, 020h, 0fch, 0b1h, 05bh, 06ah, 0cbh, 0beh, 039h, 04ah, 04ch, 058h, 0cfh
    byte 0d0h, 0efh, 0aah, 0fbh, 043h, 04dh, 033h, 085h, 045h, 0f9h, 002h, 07fh, 050h, 03ch, 09fh, 0a8h
    byte 051h, 0a3h, 040h, 08fh, 092h, 09dh, 038h, 0f5h, 0bch, 0b6h, 0dah, 021h, 010h, 0ffh, 0f3h, 0d2h
    byte 0cdh, 00ch, 013h, 0ech, 05fh, 097h, 044h, 017h, 0c4h, 0a7h, 07eh, 03dh, 064h, 05dh, 019h, 073h
    byte 060h, 081h, 04fh, 0dch, 022h, 02ah, 090h, 088h, 046h, 0eeh, 0b8h, 014h, 0deh, 05eh, 00bh, 0dbh
    byte 0e0h, 032h, 03ah, 00ah, 049h, 006h, 024h, 05ch, 0c2h, 0d3h, 0ach, 062h, 091h, 095h, 0e4h, 079h
    byte 0e7h, 0c8h, 037h, 06dh, 08dh, 0d5h, 04eh, 0a9h, 06ch, 056h, 0f4h, 0eah, 065h, 07ah, 0aeh, 008h
    byte 0bah, 078h, 025h, 02eh, 01ch, 0a6h, 0b4h, 0c6h, 0e8h, 0ddh, 074h, 01fh, 04bh, 0bdh, 08bh, 08ah
    byte 070h, 03eh, 0b5h, 066h, 048h, 003h, 0f6h, 00eh, 061h, 035h, 057h, 0b9h, 086h, 0c1h, 01dh, 09eh
    byte 0e1h, 0f8h, 098h, 011h, 069h, 0d9h, 08eh, 094h, 09bh, 01eh, 087h, 0e9h, 0ceh, 055h, 028h, 0dfh
    byte 08ch, 0a1h, 089h, 00dh, 0bfh, 0e6h, 042h, 068h, 041h, 099h, 02dh, 00fh, 0b0h, 054h, 0bbh, 016h

    inv_sbox \
    byte 052h, 009h, 06ah, 0d5h, 030h, 036h, 0a5h, 038h, 0bfh, 040h, 0a3h, 09eh, 081h, 0f3h, 0d7h, 0fbh
    byte 07ch, 0e3h, 039h, 082h, 09bh, 02fh, 0ffh, 087h, 034h, 08eh, 043h, 044h, 0c4h, 0deh, 0e9h, 0cbh
    byte 054h, 07bh, 094h, 032h, 0a6h, 0c2h, 023h, 03dh, 0eeh, 04ch, 095h, 00bh, 042h, 0fah, 0c3h, 04eh
    byte 008h, 02eh, 0a1h, 066h, 028h, 0d9h, 024h, 0b2h, 076h, 05bh, 0a2h, 049h, 06dh, 08bh, 0d1h, 025h
    byte 072h, 0f8h, 0f6h, 064h, 086h, 068h, 098h, 016h, 0d4h, 0a4h, 05ch, 0cch, 05dh, 065h, 0b6h, 092h
    byte 06ch, 070h, 048h, 050h, 0fdh, 0edh, 0b9h, 0dah, 05eh, 015h, 046h, 057h, 0a7h, 08dh, 09dh, 084h
    byte 090h, 0d8h, 0abh, 000h, 08ch, 0bch, 0d3h, 00ah, 0f7h, 0e4h, 058h, 005h, 0b8h, 0b3h, 045h, 006h
    byte 0d0h, 02ch, 01eh, 08fh, 0cah, 03fh, 00fh, 002h, 0c1h, 0afh, 0bdh, 003h, 001h, 013h, 08ah, 06bh
    byte 03ah, 091h, 011h, 041h, 04fh, 067h, 0dch, 0eah, 097h, 0f2h, 0cfh, 0ceh, 0f0h, 0b4h, 0e6h, 073h
    byte 096h, 0ach, 074h, 022h, 0e7h, 0adh, 035h, 085h, 0e2h, 0f9h, 037h, 0e8h, 01ch, 075h, 0dfh, 06eh
    byte 047h, 0f1h, 01ah, 071h, 01dh, 029h, 0c5h, 089h, 06fh, 0b7h, 062h, 00eh, 0aah, 018h, 0beh, 01bh
    byte 0fch, 056h, 03eh, 04bh, 0c6h, 0d2h, 079h, 020h, 09ah, 0dbh, 0c0h, 0feh, 078h, 0cdh, 05ah, 0f4h
    byte 01fh, 0ddh, 0a8h, 033h, 088h, 007h, 0c7h, 031h, 0b1h, 012h, 010h, 059h, 027h, 080h, 0ech, 05fh
    byte 060h, 051h, 07fh, 0a9h, 019h, 0b5h, 04ah, 00dh, 02dh, 0e5h, 07ah, 09fh, 093h, 0c9h, 09ch, 0efh
    byte 0a0h, 0e0h, 03bh, 04dh, 0aeh, 02ah, 0f5h, 0b0h, 0c8h, 0ebh, 0bbh, 03ch, 083h, 053h, 099h, 061h
    byte 017h, 02bh, 004h, 07eh, 0bah, 077h, 0d6h, 026h, 0e1h, 069h, 014h, 063h, 055h, 021h, 00ch, 07dh

    rcon \
    dword 01000000h
    dword 02000000h
    dword 04000000h
    dword 08000000h
    dword 10000000h
    dword 20000000h
    dword 40000000h
    dword 80000000h
    dword 1b000000h
    dword 36000000h

align 16
    block_permutation_table \
    byte  0,  4,  8, 12
    byte  1,  5,  9, 13
    byte  2,  6, 10, 14
    byte  3,  7, 11, 15
.data
align 16
    keys oword 15 dup(0)
.code
; AES encryption
;
; Parameters:
; 	RCX: ByteSequence* - encrypted text (unitialized)
; 	RDX: ByteSequence* - plaintext
;	R8: ByteSequence* - key (length must be 128, 196 or 256)
;
; Return value:
; 	RAX: ByteSequence* - encrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
AesEncrypt proc
    local buffer: ByteSequence
    local block: oword
    encrypted_text equ [rbp + 16]
    text equ [rbp + 24]
    key equ [rbp + 32]
    ; Prologue
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    sub rsp, 16
    movdqa [rsp], xmm6
    mov encrypted_text, rcx
    mov text, rdx
    mov key, r8
    sub rsp, 32

    ; Get round keys
    mov rcx, r8
    call AesGetRoundKeys

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
    ; xmm6 - block permutation table
    ; rbx - ptr to block
    ; rsi - buffer data
    ; rdi - encrypted text data
    ; r12 - offset
    ; r13 - length
    ; r14b - rounds
    movdqa xmm6, oword ptr block_permutation_table
    mov rax, encrypted_text
    lea rbx, block
    lea rsi, buffer
    mov rsi, [rsi + ByteSequence.data]
    mov rdi, [rax + ByteSequence.data]
    mov r12, 0	
    mov r13, [rax + ByteSequence.data_size]
    mov r14, key
    mov r14, [r14 + ByteSequence.data_size]
    shr r14, 5
    add r14, 6
    jmp condition
cycle:
    movdqa xmm0, [rsi + r12]
    pshufb xmm0, xmm6
    movdqa block, xmm0

    mov rcx, rbx
    mov dl, r14b
    call AesEncryptBlock

    movdqa xmm0, block
    pshufb xmm0, xmm6
    movdqa [rdi + r12], xmm0

    add r12, BLOCK_SIZE
condition:
    cmp r12, r13
    jb cycle

    ; Free buffer
    lea rcx, buffer
    call FreeBS

    mov rax, encrypted_text

    ; Epilogue
    add rsp, 32
    movdqa xmm6, [rsp]
    add rsp, 16
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
AesEncrypt endp

; Encrypts 128-bit block with aes cipher
;
; Parameters:
; 	RCX: oword* - block
; 	DL: byte - number of rounds
;
; Return value:
; 	RAX: oword* - block
AesEncryptBlock proc
    ; Prologue
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40

    ; Encryption
    ; r12 - offset in bytes
    ; r13 - 16 * rounds
    ; r14 - block ptr
    ; r15 - keys
    mov r12, 16
    movzx r13, dl
    shl r13, 4
    mov r14, rcx
    lea r15, keys

    movdqa xmm0, [r14]
    xorpd xmm0, [r15]
    movdqa [r14], xmm0

    jmp condition
cycle:
    mov rcx, r14
    call SubBytes

    mov rcx, r14
    call ShiftRows

    mov rcx, r14
    call MixColumns

    movdqa xmm0, [r14]
    xorpd xmm0, [r15 + r12]
    movdqa [r14], xmm0

    add r12, BLOCK_SIZE
condition:
    cmp r12, r13
    jb cycle
    
    mov rcx, r14
    call SubBytes
    
    mov rcx, r14
    call ShiftRows

    movdqa xmm0, [r14]
    xorpd xmm0, [r15 + r12]
    movdqa [r14], xmm0

    mov rax, r14

    ; Epilogue
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    ret
AesEncryptBlock endp

; AES decryption
;
; Parameters:
; 	RCX: ByteSequence* - decrypted text (unitialized)
; 	RDX: ByteSequence* - encrypted text
;	R8: ByteSequence* - key (length must be 128, 196 or 256)
;
; Return value:
; 	RAX: ByteSequence* - decrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
AesDecrypt proc
    local buffer: ByteSequence
    local block: oword
    decrypted_text equ [rbp + 16]
    text equ [rbp + 24]
    key equ [rbp + 32]
    ; Prologue
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    sub rsp, 16
    movdqa [rsp], xmm6
    mov encrypted_text, rcx
    mov text, rdx
    mov key, r8
    sub rsp, 32

    ; Get round keys
    mov rcx, r8
    call AesGetRoundKeys

    ; Init buffer
    lea rcx, buffer
    mov rdx, text
    mov rdx, [rdx + ByteSequence.data_size]
    call CreateBS
    
    ; Decryption
    ; xmm6 - block permutation table
    ; rbx - ptr to block
    ; rsi - text data
    ; rdi - buffer data
    ; r12 - offset
    ; r13 - length
    ; r14b - rounds
    movdqa xmm6, oword ptr block_permutation_table
    lea rbx, block
    mov rsi, text
    mov rsi, [rsi + ByteSequence.data]
    mov rdi, [rax + ByteSequence.data]
    mov r12, 0	
    mov r13, [rax + ByteSequence.data_size]
    mov r14, key
    mov r14, [r14 + ByteSequence.data_size]
    shr r14, 5
    add r14, 6
    jmp condition
cycle:
    movdqa xmm0, [rsi + r12]
    pshufb xmm0, xmm6
    movdqa block, xmm0

    mov rcx, rbx
    mov dl, r14b
    call AesDecryptBlock

    movdqa xmm0, block
    pshufb xmm0, xmm6
    movdqa [rdi + r12], xmm0

    add r12, BLOCK_SIZE
condition:
    cmp r12, r13
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
    movdqa xmm6, [rsp]
    add rsp, 16
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
AesDecrypt endp

; Decrypts 128-bit block with aes cipher
;
; Parameters:
; 	RCX: oword* - block
; 	DL: byte - number of rounds
;
; Return value:
; 	RAX: oword* - block
AesDecryptBlock proc
    ; Prologue
    push r12
    push r13
    push r14
    sub rsp, 32

    ; Decryption
    ; r12 - offset in bytes = 16 * rounds - 16
    ; r13 - block ptr
    ; r14 - keys
    movzx r12, dl
    shl r12, 4
    mov r13, rcx
    lea r14, keys

    movdqa xmm0, [r13]
    xorpd xmm0, [r14 + r12]
    movdqa [r13], xmm0

    sub r12, BLOCK_SIZE

    jmp condition
cycle:
    mov rcx, r13
    call InvShiftRows

    mov rcx, r13
    call InvSubBytes

    movdqa xmm0, [r13]
    xorpd xmm0, [r14 + r12]
    movdqa [r13], xmm0

    mov rcx, r13
    call InvMixColumns

    sub r12, BLOCK_SIZE
condition:
    cmp r12, BLOCK_SIZE
    jge cycle
    
    mov rcx, r13
    call InvShiftRows

    mov rcx, r13
    call InvSubBytes

    movdqa xmm0, [r13]
    xorpd xmm0, [r14]
    movdqa [r13], xmm0

    mov rax, r13

    ; Epilogue
    add rsp, 32
    pop r14
    pop r13
    pop r12
    ret
AesDecryptBlock endp

; Performs substitution of 16 bytes in a block
;
; Parameters:
;	RCX: oword* - block
; 
; Return value:
; 	RAX: oword* - block
SubBytes proc
    ; rcx - ptr to data
    ; rdx - counter
    ; r8 - sbox
    mov rax, 0
    mov rdx, 0
    lea r8, sbox
    jmp condition
cycle:
    mov al, [rcx + rdx]
    mov al, [r8 + rax]
    mov [rcx + rdx], al

    inc rdx
condition:
    cmp rdx, 16
    jb cycle

    mov rax, rcx

    ret
SubBytes endp

; Performs inverse substitution of 16 bytes in a block
;
; Parameters:
;	RCX: oword* - block
; 
; Return value:
; 	RAX: oword* - block
InvSubBytes proc
    ; rcx - ptr to data
    ; rdx - counter
    ; r8 - inverse sbox
    mov rax, 0
    mov rdx, 0
    lea r8, inv_sbox
    jmp condition
cycle:
    mov al, [rcx + rdx]
    mov al, [r8 + rax]
    mov [rcx + rdx], al

    inc rdx
condition:
    cmp rdx, 16
    jb cycle

    mov rax, rcx

    ret
InvSubBytes endp

; Shifts rows in a block
;
; Parameters:
;	RCX: oword* - block
; 
; Return value:
; 	RAX: oword* - block
ShiftRows proc
    mov eax, [rcx + 4]
    ror eax, 8
    mov [rcx + 4], eax

    mov eax, [rcx + 8]
    ror eax, 16
    mov [rcx + 8], eax

    mov eax, [rcx + 12]
    ror eax, 24
    mov [rcx + 12], eax

    mov rax, rcx

    ret
ShiftRows endp

; Shifts rows in a block in the opposite direction
;
; Parameters:
;	RCX: oword* - block
; 
; Return value:
; 	RAX: oword* - block
InvShiftRows proc
    mov eax, [rcx + 4]
    rol eax, 8
    mov [rcx + 4], eax

    mov eax, [rcx + 8]
    rol eax, 16
    mov [rcx + 8], eax

    mov eax, [rcx + 12]
    rol eax, 24
    mov [rcx + 12], eax

    mov rax, rcx

    ret
InvShiftRows endp

; Each column is multiplied by the matrix M in Galois field
; M = [2, 3, 1, 1]
;     [1, 2, 3, 1]
;     [1, 1, 2, 3]
;     [3, 1, 1, 2]
;
; Parameters:
;	RCX: oword* - block
; 
; Return value:
; 	RAX: oword* - block
option prologue:PrologueDef
option epilogue:EpilogueDef
MixColumns proc
    local block_copy: oword
    ; Prologue
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32

    ; Copy block
    movdqa xmm0, [rcx]
    movdqa block_copy, xmm0

    ; r12 - column index
    ; r13b - temp
    ; r14 - block copy
    ; r15 - original block  
    mov r12, 0
    lea r14, block_copy
    mov r15, rcx
    jmp condition
cycle:
    ; A
    mov cl, [r14 + r12]
    mov dl, 2
    call GFMultiply
    mov r13b, al

    mov cl, [r14 + r12 + 4]
    mov dl, 3
    call GFMultiply
    xor r13b, al

    xor r13b, [r14 + r12 + 8]
    xor r13b, [r14 + r12 + 12]
    mov [r15 + r12], r13b

    ; B
    mov r13b, [r14 + r12]

    mov cl, [r14 + r12 + 4]
    mov dl, 2
    call GFMultiply
    xor r13b, al

    mov cl, [r14 + r12 + 8]
    mov dl, 3
    call GFMultiply
    xor r13b, al

    xor r13b, [r14 + r12 + 12]
    mov [r15 + r12 + 4], r13b

    ; C
    mov r13b, [r14 + r12]
    xor r13b, [r14 + r12 + 4]

    mov cl, [r14 + r12 + 8]
    mov dl, 2
    call GFMultiply
    xor r13b, al

    mov cl, [r14 + r12 + 12]
    mov dl, 3
    call GFMultiply
    xor r13b, al

    mov [r15 + r12 + 8], r13b

    ; D
    mov cl, [r14 + r12]
    mov dl, 3
    call GFMultiply
    mov r13b, al

    xor r13b, [r14 + r12 + 4]
    xor r13b, [r14 + r12 + 8]

    mov cl, [r14 + r12 + 12]
    mov dl, 2
    call GFMultiply
    xor r13b, al

    mov [r15 + r12 + 12], r13b

    inc r12
condition:
    cmp r12, 4
    jb cycle

    mov rax, r15

    ; Epilogue
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    ret
MixColumns endp

; Each column is multiplied by the invertible matrix IM in Galois field
; IM = [14, 11, 13,  9]
;      [ 9, 14, 11, 13]
;      [13,  9, 14, 11]
;      [11, 13,  9, 14]
;
; Parameters:
;	RCX: oword* - block
; 
; Return value:
; 	RAX: oword* - block
option prologue:PrologueDef
option epilogue:EpilogueDef
InvMixColumns proc
    local block_copy: oword
    ; Prologue
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32

    ; Copy block
    movdqa xmm0, [rcx]
    movdqa block_copy, xmm0

    ; r12 - column index
    ; r13b - temp
    ; r14 - block copy
    ; r15 - original block
    mov r12, 0
    lea r14, block_copy
    mov r15, rcx
    jmp condition
cycle:
    ; A
    mov cl, [r14 + r12]
    mov dl, 14
    call GFMultiply
    mov r13b, al

    mov cl, [r14 + r12 + 4]
    mov dl, 11
    call GFMultiply
    xor r13b, al

    mov cl, [r14 + r12 + 8]
    mov dl, 13
    call GFMultiply
    xor r13b, al

    mov cl, [r14 + r12 + 12]
    mov dl, 9
    call GFMultiply
    xor r13b, al

    mov [r15 + r12], r13b

    ; B
    mov cl, [r14 + r12]
    mov dl, 9
    call GFMultiply
    mov r13b, al

    mov cl, [r14 + r12 + 4]
    mov dl, 14
    call GFMultiply
    xor r13b, al

    mov cl, [r14 + r12 + 8]
    mov dl, 11
    call GFMultiply
    xor r13b, al

    mov cl, [r14 + r12 + 12]
    mov dl, 13
    call GFMultiply
    xor r13b, al

    mov [r15 + r12 + 4], r13b

    ; C
    mov cl, [r14 + r12]
    mov dl, 13
    call GFMultiply
    mov r13b, al

    mov cl, [r14 + r12 + 4]
    mov dl, 9
    call GFMultiply
    xor r13b, al

    mov cl, [r14 + r12 + 8]
    mov dl, 14
    call GFMultiply
    xor r13b, al

    mov cl, [r14 + r12 + 12]
    mov dl, 11
    call GFMultiply
    xor r13b, al

    mov [r15 + r12 + 8], r13b

    ; D
    mov cl, [r14 + r12]
    mov dl, 11
    call GFMultiply
    mov r13b, al

    mov cl, [r14 + r12 + 4]
    mov dl, 13
    call GFMultiply
    xor r13b, al

    mov cl, [r14 + r12 + 8]
    mov dl, 9
    call GFMultiply
    xor r13b, al

    mov cl, [r14 + r12 + 12]
    mov dl, 14
    call GFMultiply
    xor r13b, al

    mov [r15 + r12 + 12], r13b

    inc r12
condition:
    cmp r12, 4
    jb cycle

    mov rax, r15

    ; Epilogue
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    ret
InvMixColumns endp


; Performs multiplication in GF(2^8)
;
; Parameters:
;	CL: byte - 1st operand
; 	DL: byte - 2nd operand
;
; Return value:
; 	AL: byte - result of multiplication
GFMultiply proc
    ; cl - 1st operand
    ; dl - 2nd operand
    ; r8b - result
    mov r8b, 0
    jmp condition
cycle:
    mov al, dl
    and al, 1
    cmp al, 0
    je next_bit
    xor r8b, cl
next_bit:
    shl cl, 1
    jc reduction
    shr dl, 1
    jmp condition
reduction:
    xor cl, 1Bh
    shr dl, 1
condition:
    cmp dl, 0
    jne cycle

    mov al, r8b

    ret
GFMultiply endp

; Generates keys for 
; ecnryption / decryption
; using initial key
;
; Parameters:
; 	RCX: ByteSequence* - initial key
;
; No return value
AesGetRoundKeys proc
    ; Prologue
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32

    ; rcx - counter
    ; rdx - key size
    ; r8 - key data
    ; r9 - keys
    lea r9, keys
    mov r8, [rcx + ByteSequence.data]
    mov rdx, [rcx + ByteSequence.data_size]
    mov rcx, 0
    jmp copy_condition
copy_cycle:
    mov al, [r8 + rcx]
    mov [r9 + rcx], al
    inc rcx
copy_condition:
    cmp rcx, rdx
    jb copy_cycle
    
    ; Nk = key size / 32
    ; rounds = Nk + 6
    ;
    ; rbx - rcon
    ; r12 - i = Nk
    ; r13 - Nk
    ; rdi - keys
    ; esi - temp
    ; r14 - 4 * (rounds + 1)
    ; r15b - buffer for result of i / Nk
    lea rbx, rcon
    mov rdi, r9
    mov r12, rcx
    shr r12, 5
    mov r13, r12
    mov r14, r12
    add r14, 7
    shl r14, 2
    mov r15, 0
    jmp condition
cycle:
    ; temp = keys32[i - 1]
    mov esi, [rdi + r12 * 4 - 4] 

    mov ax, r12w
    div r13b
    mov r15b, al

    cmp ah, 0
    jne elseif_statement
if_statement:
    ; temp = SubWord(RotWord(temp)) xor Rcon[i / Nk]
    ror esi, 8

    mov ecx, esi
    call SubDWord

    xor eax, [rbx + r15 * 4]
    mov esi, eax

    jmp endif_statement
elseif_statement:
    cmp r13, 8
    jne endif_statement
    cmp ah, 4
    jne endif_statement

    ; temp = SubWord(temp)
    mov ecx, esi
    call SubDWord
    mov esi, eax
endif_statement:
    ; temp = temp XOR keys[i - Nk]
    mov rdx, r12
    sub rdx, r13
    xor esi, [rdi + rdx * 4]

    mov [rdi + r12 * 4], esi

    inc r12
condition:
    cmp r12, r14
    jb cycle

    ; Permutate 128bit keys for XOR with permutated block
    ; XOR requires block in normal form (not 4x4 matrix),
    ; so we permutate key instead for compatibility with block in matrix form
    ; xmm6 - permutation table
    ; rcx - offset
    ; r14 - keys size
    ; rdi - keys
    movdqa xmm1, oword ptr block_permutation_table
    mov rcx, 0
    shl r14, 2
    jmp permutation_condition
permutation_cycle:
    movdqa xmm0, [rdi + rcx]
    pshufb xmm0, xmm1
    movdqa [rdi + rcx], xmm0

    add rcx, BLOCK_SIZE
permutation_condition:
    cmp rcx, r14
    jb permutation_cycle

    ; Epilogue
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
AesGetRoundKeys endp

; Performs substitution of 4 bytes in block
;
; Parameters:
;	RCX: dword - block
; 
; Return value:
; 	RAX: dword - substitutioned block
SubDWord proc
    ; rcx - data
    ; rdx - counter
    ; r8 - sbox
    ; r9 - result
    mov rax, 0
    mov rdx, 0
    lea r8, sbox
    mov r9, 0
    jmp condition
cycle:
    mov al, cl
    mov al, [r8 + rax]
    mov r9b, al

    shr ecx, 8
    ror r9d, 8

    inc rdx
condition:
    cmp rdx, 4
    jb cycle

    mov rax, r9

    ret
SubDWord endp

; Generates initial key for aes encryption / decryption
;
; Parameters:
; 	RCX: ByteSequence* - key (uninitialized)
; 	DX: word - key length (128, 196 or 256)
;
; Return value:
; 	RAX: ByteSequence* - key (caller must free)
AesGenKey proc
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
    movzx rdx, dx
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
AesGenKey endp
end