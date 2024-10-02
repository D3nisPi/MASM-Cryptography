include .\include\lib\kernel32.inc
include .\include\common\byte_sequence.inc
include .\include\common\random.inc

.code
; Substitution cipher encryption & decryption
;
; Encryption:
; c[i] = t[p[i]], where
; c - ciphertest (encrypted text),
; p - plaintext (text),
; t - substitution table
;
; Decryption:
; p[i] = it[c[i]], where
; p - plaintext (decrypted text),
; c - ciphertext,
; it - inverse substitution table
;
; Parameters:
;	RCX: ByteSequence* - encrypted text / decrypted text (uninitilized)
;	RDX: ByteSequence* - plaintext / encrypted text
;	R8: ByteSequence* - substitution table / inverse substitution table (length must be 256 bytes, all values unique)
; 
; Return value:
;	RAX : ByteSequence* - encrypted text  / decrypted text (caller must free)
Substitution proc
    result_text equ [rbp + 16]
    text equ [rbp + 24]
    table equ [rbp + 32]
    ; Prologue
    push rbp
    mov rbp, rsp
    mov result_text, rcx
    mov text, rdx
    mov table, r8
    sub rsp, 32
    
    ; Init ByteSequence structure for encrypted / decrypted message
    mov rdx, [rdx + ByteSequence.data_size]
    call CreateBS

    ; Encryption / Decryption
    ; rcx - counter
    ; rdx - table data
    ; r8 - result text
    ; r9 - length
    ; r10 - text data
    ; r11 - result text data
    mov rax, 0
    mov rcx, 0
    mov rdx, table
    mov rdx, [rdx + ByteSequence.data]
    mov r8, result_text
    mov r9, [r8 + ByteSequence.data_size]
    mov r10, text
    mov r10, [r10 + ByteSequence.data]
    mov r11, [r8 + ByteSequence.data]
    jmp condition
cycle:
    mov al, [r10 + rcx]
    mov al, [rdx + rax]
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
Substitution endp

; Generates key for substitution cipher
;
; Parameters:
; 	RCX: ByteSequence* - substitution table (uninitialized)
;	RDX: ByteSequence* - inverse substitution table (uninitialized)
;
; Return value:
;	RAX: ByteSequence* - substitution table (caller must free)
;	RDX: ByteSequence* - inverse substitution table (caller must free)
SubstitutionGenKey proc
    table equ [rbp + 16]
    inv_table equ [rbp + 24]
    ; Prologue
    push rbp
    mov rbp, rsp
    push r12
    push r13
    mov table, rcx
    mov inv_table, rdx
    sub rsp, 32

    ; Init substitution table
    mov rdx, 256
    call CreateBS

    ; Fill substitution table with t[i] = i
    ; rcx - counter
    ; rdx - table data
    mov rcx, 0
    mov rdx, [rax + ByteSequence.data]
    jmp pt_condition
pt_cycle:
    mov [rdx + rcx], cl
    inc rcx
pt_condition:
    cmp rcx, 256
    jb pt_cycle

    ; Shuffle substitution table
    ; r12 - counter
    ; r13 - table data
    mov r12, 255
    mov r13, rdx
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

    ; Init inverse substitution table
    mov rcx, inv_table
    mov rdx, 256
    call CreateBS

    ; Fill inverse substitution table
    ; rcx - counter
    ; rdx - inverse table data
    ; r13 - table data
    mov rcx, 0
    mov rdx, [rax + ByteSequence.data]
    mov rax, 0
    jmp ipt_condition
ipt_cycle:
    mov al, [r13 + rcx]
    mov [rdx + rax], cl
    inc rcx
ipt_condition:
    cmp rcx, 256
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
SubstitutionGenKey endp
end