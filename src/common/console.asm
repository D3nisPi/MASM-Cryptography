include .\include\lib\kernel32.inc

.code
; Prints a string to the console
;
; Parameters:
;   RCX: byte* - c-style string
;
; No return value
option prologue:PrologueDef
option epilogue:EpilogueDef
Print proc
    local text_length: dword
    text_ptr equ [rbp + 16]
    STD_OUT equ -11
    ; Prologue 
    mov text_ptr, rcx
    sub rsp, 40

    ; Get length
    call lstrlenA
    mov text_length, eax

    ; Writing to console
    mov  rcx, STD_OUT
    call GetStdHandle

    mov rcx, rax
    mov rdx, text_ptr
    mov r8d, text_length
    mov r9, 0
    mov qword ptr [rsp + 32], 0
    call WriteFile

    ; Epilogue
    add rsp, 40
    ret
Print endp

; Waits for user input
;
; No parameters
;
; No return value
option prologue:PrologueDef
option epilogue:EpilogueDef
WaitForInput proc
    local buffer: byte
    STD_INPUT equ -10
    ; Prologue
    sub rsp, 40

    ; Waiting for input
    mov rcx, STD_INPUT
    call GetStdHandle

    mov rcx, rax
    lea rdx, buffer
    mov r8d, 1
    mov r9d, 0
    call ReadFile

    ; Epologue
    add rsp, 40
    ret
WaitForInput endp
end