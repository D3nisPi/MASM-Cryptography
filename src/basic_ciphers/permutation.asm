include .\include\lib\kernel32.inc
include .\include\common\byte_sequence.inc
include .\include\common\padding.inc
include .\include\common\random.inc

.code
; Permutation cipher encryption
; b[i] = b[t[i]], where 
; b - block of plaintext,
; t - permutation table
;
; Parameters:
;	RCX: ByteSequence* - encrypted text (uninitialized)
;	RDX: ByteSequence* - plaintext
;	R8: ByteSequence* - permutation table (length must be 2^n, n in [0, 7])
;
; Return value:
;	RAX: ByteSequence* - encrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
PermutationEncrypt proc
    local buffer: ByteSequence
    encrypted_text equ [rbp + 16]
    text equ [rbp + 24]
    table equ [rbp + 32]
    ; Prologue
    push rsi
    push rdi
    mov encrypted_text, rcx
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
    ; rcx - text counter
    ; rdx - block counter
    ; r8 - buffer
    ; r9 - permutation table data
    ; r10 - length
    ; r11 - block size
    ; rsi - buffer data
    ; rdi - encrypted text data
    mov rax, table
    mov rcx, 0
    mov rdx, 0
    lea r8, buffer
    mov r9, [rax + ByteSequence.data]	
    mov r10, [r8 + ByteSequence.data_size]
    mov r11, [rax + ByteSequence.data_size]
    mov rsi, [r8 + ByteSequence.data]
    mov rdi, encrypted_text
    mov rdi, [rdi + ByteSequence.data]
    jmp condition
cycle:
    movzx rax, byte ptr [r9 + rdx]
    sub rax, rdx
    add rax, rcx
    mov al, [rsi + rax]
    mov [rdi + rcx], al

    inc rcx
    inc rdx
reset:
    cmp rdx, r11
    jb condition
    mov rdx, 0
condition:
    cmp rcx, r10
    jb cycle
    
    mov rcx, r8
    call FreeBS
    
    mov rax, encrypted_text

    ; Epilogue
    add rsp, 32
    pop rdi
    pop rsi
    ret
PermutationEncrypt endp

; Permutation cipher decryption
; b[i] = b[it[i]], where 
; b - block of ciphertext, 
; it - inverse permutation table
;
; Parameters:
;	RCX: ByteSequence* - decrypted text (uninitialized)
;	RDX: ByteSequence* - encrypted text
;	R8: ByteSequence* - inverse permutation table (length must be 2^n, n in [0, 7])
;
; Return value:
;	RAX: ByteSequence* - decrypted text (caller must free)
option prologue:PrologueDef
option epilogue:EpilogueDef
PermutationDecrypt proc
    local buffer: ByteSequence
    decrypted_text equ [rbp + 16]
    text equ [rbp + 24]
    inv_table equ [rbp + 32]
    ; Prologue
    push rsi
    push rdi
    mov decrypted_text, rcx
    mov text, rdx
    mov inv_table, r8
    sub rsp, 32

    ; Create ByteSequence structure for decrypted message
    lea rcx, buffer
    mov rdx, [rdx + ByteSequence.data_size]
    call CreateBS
    
    ; Decryption
    ; rcx - text counter
    ; rdx - block counter
    ; r8 - buffer
    ; r9 - inverse permutation table data
    ; r10 - length
    ; r11 - block size
    ; rsi - encrypted text data
    ; rdi - buffer data
    mov rax, inv_table
    mov rcx, 0
    mov rdx, 0
    lea r8, buffer
    mov r9, [rax + ByteSequence.data]
    mov r10, [r8 + ByteSequence.data_size]
    mov r11, [rax + ByteSequence.data_size]
    mov rsi, text
    mov rsi, [rsi + ByteSequence.data]
    mov rdi, [r8 + ByteSequence.data]
    jmp condition
cycle:
    movzx rax, byte ptr [r9 + rdx]
    add rax, rcx
    sub rax, rdx
    mov al, [rsi + rax]
    mov [rdi + rcx], al

    inc rcx
    inc rdx
reset:
    cmp rdx, r11
    jb condition
    mov rdx, 0
condition:
    cmp rcx, r10
    jb cycle
    
    ; Remove padding
    mov rcx, decrypted_text
    mov rdx, r8
    call RemovePadding

    lea rcx, buffer
    call FreeBS

    mov rax, decrypted_text

    ; Epilogue
    add rsp, 32
    pop rdi
    pop rsi
    ret
PermutationDecrypt endp

; Generates permutation table and inverse permutation table
;
; Parameters:
;	RCX: ByteSequence* - permutation table (uninitialized)
;	RDX: ByteSequence* - inverse permutation table (uninitialized)
;	CL: byte - block size (must be 2^n, n in [0, 7])
;
; Return value:
;	RAX: ByteSequence* - permutation table (caller must free)
;	RDX: ByteSequence* - inverse permutation table (caller must free)
PermutationGenKey proc
    table equ [rbp + 16]
    inv_table equ [rbp + 24]
    block_size equ [rbp + 32]
    ; Prologue
    push rbp
    mov rbp, rsp
    push r12
    push r13
    mov table, rcx
    mov inv_table, rdx
    mov block_size, r8b
    sub rsp, 32

    ; Init permutation table
    movzx rdx, r8b
    call CreateBS

    ; Fill permutation table with t[i] = i
    ; rcx - counter
    ; rdx - length
    ; r8 - table data
    mov rcx, 0
    movzx rdx, byte ptr block_size
    mov r8, [rax + ByteSequence.data]
    jmp pt_condition
pt_cycle:
    mov [r8 + rcx], cl
    inc rcx
pt_condition:
    cmp rcx, rdx
    jb pt_cycle

    ; Shuffle permutation table
    ; r12 - counter
    ; r13 - table data
    mov r12, rdx
    dec r12
    mov r13, r8
    jmp shuffle_condition
shuffle_cycle:
    mov ecx, 0
    mov edx, r12d
    inc edx
    call GenRandomRange32
    mov r8b, [r13 + rax]
    mov r9b, [r13 + r12]
    mov [r13 + r12], r8b
    mov [r13 + rax], r9b
    dec r12
shuffle_condition:
    cmp r12, 0
    ja shuffle_cycle

    ; Init inverse permutation table
    mov rcx, inv_table
    movzx rdx, byte ptr block_size
    call CreateBS

    ; Fill inverse permutation table
    ; rcx - counter
    ; rdx - length
    ; r8 - inverse table data
    ; r13 - table data
    mov rcx, 0
    movzx rdx, byte ptr block_size
    mov r8, [rax + ByteSequence.data]
    mov rax, 0
    jmp ipt_condition
ipt_cycle:
    mov al, [r13 + rcx]
    mov [r8 + rax], cl
    inc rcx
ipt_condition:
    cmp rcx, rdx
    jb ipt_cycle
    
    mov rax, table
    mov rdx, inv_table
    
    ; Epilogue
    add rsp, 32
    pop r13
    pop r12
    mov rsp, rbp
    pop rbp
    ret
PermutationGenKey endp
end