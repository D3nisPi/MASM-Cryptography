include .\include\lib\bcrypt.inc

.const
    rng word 52h, 4eh, 47h, 0h
.data
    buf byte 8 dup(0)
.code
; Fills bytes of buffer with random values
; If number of bytes to fill is greater than the size of the buffer the behaviour is undefined
;
; Parameters:
;   RCX: void* - ptr to buffer
;   RDX: qword - number of bytes to fill
;
; Return value:
;   RAX: void* - ptr to buffer
option prologue:PrologueDef
option epilogue:EpilogueDef
GenRandomBytes proc
    local handle: qword
    buffer equ [rbp + 16]
    buffer_size equ [rbp + 24]
    ; Prologue
    mov buffer, rcx
    mov buffer_size, rdx
    sub rsp, 40

    lea rcx, handle
    lea rdx, rng
    mov r8, 0
    mov r9, 0
    call BCryptOpenAlgorithmProvider

    mov rcx, handle 
    mov rdx, buffer
    mov r8, buffer_size
    mov r9, 0
    call BCryptGenRandom

    mov rcx, handle
    mov rdx, 0
    call BCryptCloseAlgorithmProvider

    mov rax, buffer
    ; Epilogue
    add rsp, 40
    ret
GenRandomBytes endp

; Generates random byte number
;
; No parameters
;
; Return value:
;   AL: byte - random value
GenRandom8 proc
    sub rsp, 40

    lea rcx, buf
    mov rdx, 1
    call GenRandomBytes

    mov al, [rax]

    add rsp, 40
    ret
GenRandom8 endp

; Generates random byte number
; in range [cl, dl)
;
; Parameters:
;   CL: byte - min value
;   DL: byte - max value (not included)
;
; Return value:
;   AL: byte - random value in range [cl, dl)
GenRandomRange8 proc
    min equ [rbp + 16]
    max equ [rbp + 24]
    ; Prologue
    push rbp
    mov rbp, rsp
    mov min, cl
    mov max, dl
    sub rsp, 32

    lea rcx, buf
    mov rdx, 1
    call GenRandomBytes

    movzx ax, byte ptr [rax]
    mov cl, max
    sub cl, min
    div cl

    mov al, ah
    add al, min

    ; Epologue
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret
GenRandomRange8 endp

; Generates random dword number
;
; No parameters
;
; Return value:
;   EAX: dword - random value
GenRandom32 proc
    sub rsp, 40

    lea rcx, buf
    mov rdx, 4
    call GenRandomBytes

    mov eax, [rax]

    add rsp, 40
    ret
GenRandom32 endp

; Generates random byte number
; in range [ecx, edx)
;
; Parameters:
;   ECX: dword - min value
;   EDX: dword - max value (not included)
;
; Return value:
;   EAX: dword - random value in range [ecx, edx)
GenRandomRange32 proc
    min equ [rbp + 16]
    max equ [rbp + 24]
    ; Prologue
    push rbp
    mov rbp, rsp
    mov min, ecx
    mov max, edx
    sub rsp, 32

    lea rcx, buf
    mov rdx, 1
    call GenRandomBytes
    
    mov eax, [rax]
    mov edx, 0
    mov ecx, max
    sub ecx, min
    div ecx

    mov eax, edx
    add eax, min

    ; Epilogue
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret
GenRandomRange32 endp
end