include .\include\lib\kernel32.inc
include .\include\common\byte_sequence.inc

BYTE_SEQUENCE_SIZE equ 16
 
.code
; Allocates length for ByteSequence structure and fills fields
;
; Parameters:
;   RCX: ByteSequence* - ByteSequence structure
;   RDX: qword - length of byte sequence
;
; Return value:
;   RAX: ByteSequence* - ByteSequence structure
CreateBS proc   
    byte_sequence equ [rbp + 16]
    sequence_size equ [rbp + 24]
    ; Prologue
    push rbp
    mov rbp, rsp
    mov byte_sequence, rcx
    mov sequence_size, rdx
    sub rsp, 32
    
    ; Alloc memory for data
    call GetProcessHeap
    mov rcx, rax
    mov edx, 0
	mov r8, sequence_size
    call HeapAlloc

    ; Initialize fields
    mov rcx, byte_sequence
    mov [rcx + ByteSequence.data], rax
    mov rax, sequence_size
    mov [rcx + ByteSequence.data_size], rax
    mov rax, byte_sequence

    ; Epilogue
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret
CreateBS endp


; Frees ByteSequence structure's data field
;
; Parameters:
;   RCX: ByteSequence* - ByteSequence structure
;
; No return value
FreeBS proc
    byte_sequence equ [rbp + 16]
    ; Prologue
    push rbp
    mov rbp, rsp
    mov byte_sequence, rcx
    sub rsp, 32
    
    ; Free byte_sequence.data
    call GetProcessHeap
    mov rcx, rax
    mov edx, 0
    mov r8, byte_sequence
    mov r8, [r8 + ByteSequence.data]
    call HeapFree

    ; Epilogue
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret
FreeBS endp


; Compares two ByteSequence structures
; Returns 0 if the data is the same
; Returns 1 if the byte sequence pointed to by RCX is greater than that pointed to by RDX
; Returns -1 if the byte sequence pointed to by RCX is less than that pointed to by RDX
;
; Parameters:
;   RCX: ByteSequence* - 1st structure
;   RDX: ByteSequence* - 2nd structure
;
; Return value:
;   RAX: qword - see description
CompareBS proc  
    byte_sequence1 equ [rsp + 8]
    byte_sequence2 equ [rsp + 16]
    ; Prologue
    mov byte_sequence1, rcx
    mov byte_sequence2, rdx

    ; Compare lengths
    mov r8, [rcx + ByteSequence.data_size]
    mov r9, [rdx + ByteSequence.data_size]
    cmp r8, r9
    jb less
    ja greater
    
    ; Compare bytes
    mov r8, [rcx + ByteSequence.data]
    mov r9, [rdx + ByteSequence.data]
    mov rcx, 0
cycle:
    mov al, [r8 + rcx]
    mov dl, [r9 + rcx]
    cmp al, dl
    jb less
    ja greater
    inc rcx
condition:
    mov rax, byte_sequence1
    mov rax, [rax + ByteSequence.data_size]
    cmp rcx, rax
    jb cycle

    mov rax, 0
    ret
less:
    mov rax, -1
    ret
greater:
    mov rax, 1
    ret
CompareBS endp



; Copies data from the 1st structure to the 2nd structure
; Bytes to copy = min(byte_sequence1.data_size, byte_sequence2.data_size)
;
; Parameters:
;   RCX: ByteSequence* - 1st structure
;   RCX: ByteSequence* - 2nd structure
;
; No return value
CopyBSData proc
    mov r8, [rcx + ByteSequence.data_size]
    mov r9, [rdx + ByteSequence.data_size]
    cmp r8, r9
    jb less
    jmp copy
less:
    mov r9, r8

copy:
    mov r8, 0
    mov rcx, [rcx + ByteSequence.data]
    mov rdx, [rdx + ByteSequence.data]
    jmp condition
cycle:
    mov al, [rcx + r8]
    mov [rdx + r8], al
    inc r8
condition:
    cmp r8, r9
    jb cycle

    ret
CopyBSData endp



; Reads 64 bits from the ByteSequence structure's data
; If the index is greater than rcx.data_size - 8 the behavior is undefined
;
; Parameters:
;   RCX: ByteSequence* - ByteSequence structure
;   RDX: qword - start index
;
; Return value:
;   RAX: qword - read data (64 bits)
ReadData64 proc
    mov r8, [rcx + ByteSequence.data]
    add r8, rdx
    mov rcx, 0
cycle:
    shl rax, 8
    mov al, [r8 + rcx]
    inc rcx
condition:
    cmp rcx, 8
    jb cycle

    ret
ReadData64 endp

; Writes 64 bits to the ByteSequence structure's data
; If the index is greater than rcx.data_size - 8 the behavior is undefined
;
; Parameters:
;   RCX: ByteSequence* - ByteSequence structure
;   RDX: qword - start index
;   R8: qword - data
;
; No return value
WriteData64 proc
    mov r9, [rcx + ByteSequence.data]
    add r9, rdx
    mov rcx, 7
cycle:
    mov [r9 + rcx], r8b
    shr r8, 8
    dec rcx
condition:
    cmp rcx, 0
    jge cycle

    ret
WriteData64 endp


; Reads 32 bits from the ByteSequence structure's data
; If the index is greater than rcx.data_size - 4 the behavior is undefined
;
; Parameters:
;   RCX: ByteSequence* - ByteSequence structure
;   RDX: qword - start index
;
; Return value:
;   EAX: dword - read data (32 bits)
ReadData32 proc
    mov r8, [rcx + ByteSequence.data]
    add r8, rdx
    mov rcx, 0
cycle:
    shl rax, 8
    mov al, [r8 + rcx]
    inc rcx
condition:
    cmp rcx, 4
    jb cycle

    ret
ReadData32 endp


; Writes 32 bits to the ByteSequence structure's data
; If the index is greater than rcx.data_size - 4 the behavior is undefined
;
; Parameters:
;   RCX: ByteSequence* - ByteSequence structure
;   RDX: qword - start index
;   R8D: dword - data
;
; No return value
WriteData32 proc
    mov r9, [rcx + ByteSequence.data]
    add r9, rdx
    mov rcx, 3
cycle:
    mov [r9 + rcx], r8b
    shr r8, 8
    dec rcx
condition:
    cmp rcx, 0
    jge cycle

    ret
WriteData32 endp
end