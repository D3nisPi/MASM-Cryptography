include .\include\lib\kernel32.inc
include .\include\common\console.inc
include .\include\common\string.inc
include .\include\common\random.inc
include .\include\common\byte_sequence.inc

include .\include\basic_ciphers\caesar.inc
include .\include\basic_ciphers\substitution.inc
include .\include\basic_ciphers\permutation.inc
include .\include\basic_ciphers\otp.inc
include .\include\basic_ciphers\vigenere.inc
include .\include\advanced_ciphers\des.inc
include .\include\advanced_ciphers\3des.inc
include .\include\advanced_ciphers\blowfish.inc
include .\include\advanced_ciphers\rc4.inc
include .\include\advanced_ciphers\rc5.inc
include .\include\advanced_ciphers\rc6.inc
include .\include\advanced_ciphers\aes.inc
include .\include\advanced_ciphers\tea.inc

.const
	text1 byte "Lorem ipsum dolor sit amet, consectetur cras amet."
	text2 byte "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer a urna et ligula blandit efficitur."
	text3 byte "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur interdum in diam nec efficitur. Sed eu gravida risus. Nulla porttitor rutrum volutpat."
	byte "In cursus massa non sapien facilisis, eget tristique ex condimentum. Pellentesque venenatis leo."
	
	text4  byte "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc ac magna et elit fermentum volutpat vel sit amet magna."
	byte "Morbi est lorem, vestibulum in vehicula et, ultricies sit amet mi. Vestibulum viverra sagittis rhoncus. Morbi nisl nunc, ornare a imperdiet quis,"
	byte "pellentesque tempor nibh. Phasellus egestas dapibus leo ac bibendum. In vestibulum gravida nibh a vestibulum. Nullam et lobortis libero. "
	byte "Sed ante quam, aliquet nec elit in, vestibulum fermentum orci. Nullam libero justo, ullamcorper ut."
	
	text5  byte "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam suscipit tempus lacus eget sollicitudin. Sed sed fermentum ante, et gravida erat."
	byte "Curabitur semper, ante sed rutrum suscipit, neque turpis tempor lacus, at bibendum neque magna condimentum massa."
	byte "Duis finibus ex ac dolor eleifend venenatis. Pellentesque nulla diam, consequat eu commodo tempus, pharetra vitae dolor."
	byte "Curabitur lorem sem, laoreet at ultricies sit amet, ultricies vel dolor. Pellentesque a quam nulla. Praesent lacinia tellus mauris, sit amet ornare"
	byte "ante tempor et. Duis semper magna lacus, quis elementum ligula posuere sed. Maecenas fringilla venenatis mauris eu lacinia."
	byte "Proin nunc ante, lobortis fermentum tincidunt et, mollis vitae risus. Mauris at ornare nunc. Cras ultricies eu enim sed bibendum. Duis gravida leo"
	byte "eros, id viverra est interdum et. Nam rhoncus tempor fermentum. Morbi posuere lobortis nisl, sed ornare nunc tincidunt a."
	byte "Vestibulum eget lectus condimentum enim suscipit rutrum a a eros. Quisque turpis."

align 16
	bs1 ByteSequence {50, offset text1}
	bs2 ByteSequence {100, offset text2}
	bs3 ByteSequence {250, offset text3}
	bs4 ByteSequence {500, offset text4}
	bs5 ByteSequence {1000, offset text5}

align 8
	texts qword offset bs1,
				offset bs2,
				offset bs3,
				offset bs4,
				offset bs5

	texts_number equ ($ - texts) / 8

	test_number_text byte 9, "Test #", 0
	passed_text byte " passed", 0Ah, 0
	failed_text byte " failed", 0Ah, 0

	caesar_text byte "Caesar cipher", 0Ah, 0
	substitution_text byte "Substitution cipher", 0Ah, 0
	permutation_text byte "Permutation cipher", 0Ah, 0
	otp_text byte "One-time pad cipher", 0Ah, 0
	vigenere_text byte "Vigenere cipher", 0Ah, 0
	des_text byte "DES cipher", 0Ah, 0
	triple_des_text byte "3DES cipher", 0Ah, 0
	aes_text byte "AES cipher", 0Ah, 0
	blowfish_text byte "Blowfish cipher", 0Ah, 0
	twofish_text byte "Twofish cipher", 0Ah, 0
	rc4_text byte "RC4 cipher", 0Ah, 0
	rc5_text byte "RC5 cipher", 0Ah, 0
	tea_text byte "TEA cipher", 0Ah, 0
	rc6_text byte "RC6 cipher", 0Ah, 0
.data
	string_number qword 0
	heap_handle qword 0
align 16
	encrypted_text ByteSequence {0, 0}
	decrypted_text ByteSequence {0, 0}
.code
; Prints 'Test #[number]'
;
; Parameters:
;   ECX: dword - test number
;
; No return value
PrintTestNumber proc
    number equ [rbp + 16]
    ; Prologue
    push rbp
    mov rbp, rsp
    mov number, ecx
    sub rsp, 32

	lea rcx, test_number_text
	call Print

	mov ecx, number
	call DwordToStr

	mov string_number, rax
	mov rcx, rax
	call Print

    call GetProcessHeap
    mov rcx, rax
    mov edx, 0
    mov r8, string_number
    call HeapFree

    ; Epilogue
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret
PrintTestNumber endp

; Compares two texts and prints
; 'passed' if CompareBS(rcx, rdx) == 0
; 'failed' otherwise
;
; Parameters:
;	RCX: ByteSequence* - first text
;	RDX: ByteSequence* - second text
;
; No return value
PrintTestResult proc
	sub rsp, 40

	call CompareBS	
	cmp rax, 0
	jne failed

	lea rcx, passed_text
	jmp continue
failed:
	lea rcx, failed_text
continue:
	call Print

	add rsp, 40
	ret
PrintTestResult endp

; Tests caesar cipher
;
; No parameters
;
; No return value
TestCaesar proc
	; Prologue
	push rbx
    push rsi
    push rdi
	push r12
    push r13
    push r14
    sub rsp, 40

    ; Testing
	lea rcx, caesar_text
	call Print
    
	lea rbx, texts
    lea rsi, encrypted_text
    lea rdi, decrypted_text
    mov r12, 0
    mov r13, texts_number
	jmp condition
cycle:
    mov ecx, r12d
	call PrintTestNumber

	; Encrypting and decrypting text using random key
	call CaesarGenKey
	mov r14b, al
	
	mov rcx, rsi
	mov rdx, [rbx + r12 * 8]
	mov r8b, r14b
	call CaesarEncrypt

	mov rcx, rdi
	mov rdx, rax
	mov r8b, r14b
	call CaesarDecrypt

	mov rcx, [rbx + r12 * 8]
	mov rdx, rax
	call PrintTestResult

	mov rcx, rsi
	call FreeBS
	mov rcx, rdi
	call FreeBS

	inc r12
condition:
	cmp r12, r13
	jb cycle
	
	; Epilogue
	add rsp, 40
	pop r15
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	ret
TestCaesar endp

; Tests substitution cipher
;
; No parameters
;
; No return value
option prologue:PrologueDef
option epilogue:EpilogueDef
TestSubstitution proc
	local table: ByteSequence
	local inv_table: ByteSequence
	; Prologue
	push rbx
    push rsi
    push rdi
	push r12
    push r13
    push r14
    push r15
    sub rsp, 40

    ; Testing
	lea rcx, substitution_text
	call Print
    
	lea rbx, texts
    lea rsi, encrypted_text
    lea rdi, decrypted_text
    mov r12, 0
    mov r13, texts_number
	lea r14, table
	lea r15, inv_table
	jmp condition
cycle:
    mov ecx, r12d
	call PrintTestNumber

	; Encrypting and decrypting text using random key
	mov rcx, r14
	mov rdx, r15
	call SubstitutionGenKey
	
	mov rcx, rsi
	mov rdx, [rbx + r12 * 8]
	mov r8, r14
	call Substitution

	mov rcx, rdi
	mov rdx, rax
	mov r8, r15
	call Substitution

	mov rcx, [rbx + r12 * 8]
	mov rdx, rax
	call PrintTestResult

	mov rcx, rsi
	call FreeBS
	mov rcx, rdi
	call FreeBS
	mov rcx, r14
	call FreeBS
	mov rcx, r15
	call FreeBS

	inc r12
condition:
	cmp r12, r13
	jb cycle
	
	; Epilogue
	add rsp, 40
	pop r15
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbx
	ret
TestSubstitution endp

; Tests permutation cipher
;
; No parameters
;
; No return value
option prologue:PrologueDef
option epilogue:EpilogueDef
TestPermutation proc
	local table: ByteSequence
	local inv_table: ByteSequence
	; Prologue
	push rbx
    push rsi
    push rdi
	push r12
    push r13
    push r14
    push r15
    sub rsp, 40

    ; Testing
	lea rcx, permutation_text
	call Print
    
	lea rbx, texts
    lea rsi, encrypted_text
    lea rdi, decrypted_text
    mov r12, 0
    mov r13, texts_number
	lea r14, table
	lea r15, inv_table
	jmp condition
cycle:
    mov ecx, r12d
	call PrintTestNumber

	; Encrypting and decrypting text using random key
	mov rcx, r14
	mov rdx, r15
	mov r8b, 16
	call PermutationGenKey
	
	mov rcx, rsi
	mov rdx, [rbx + r12 * 8]
	mov r8, r14
	call PermutationEncrypt

	mov rcx, rdi
	mov rdx, rax
	mov r8, r15
	call PermutationDecrypt

	mov rcx, [rbx + r12 * 8]
	mov rdx, rax
	call PrintTestResult

	mov rcx, rsi
	call FreeBS
	mov rcx, rdi
	call FreeBS
	mov rcx, r14
	call FreeBS
	mov rcx, r15
	call FreeBS

	inc r12
condition:
	cmp r12, r13
	jb cycle
	
	; Epilogue
	add rsp, 40
	pop r15
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbx
	ret
TestPermutation endp

; Tests otp cipher
;
; No parameters
;
; No return value
option prologue:PrologueDef
option epilogue:EpilogueDef
TestOtp proc
	local key: ByteSequence
	; Prologue
	push rbx
    push rsi
    push rdi
	push r12
    push r13
    push r14
    sub rsp, 32

    ; Testing
	lea rcx, otp_text
	call Print
    
	lea rbx, texts
    lea rsi, encrypted_text
    lea rdi, decrypted_text
    mov r12, 0
    mov r13, texts_number
	lea r14, key
	jmp condition
cycle:
    mov ecx, r12d
	call PrintTestNumber

	; Encrypting and decrypting text using random key
	mov rcx, r14
	mov rdx, [rbx + r12 * 8]
	mov rdx, [rdx + ByteSequence.data_size]
	call OneTimePadGenKey
	
	mov rcx, rsi
	mov rdx, [rbx + r12 * 8]
	mov r8, r14
	call OneTimePad

	mov rcx, rdi
	mov rdx, rax
	mov r8, r14
	call OneTimePad

	mov rcx, [rbx + r12 * 8]
	mov rdx, rax
	call PrintTestResult

	mov rcx, rsi
	call FreeBS
	mov rcx, rdi
	call FreeBS
	mov rcx, r14
	call FreeBS

	inc r12
condition:
	cmp r12, r13
	jb cycle
	
	; Epilogue
	add rsp, 32
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbx
	ret
TestOtp endp

; Tests vigenere cipher
;
; No parameters
;
; No return value
option prologue:PrologueDef
option epilogue:EpilogueDef
TestVigenere proc
	local key: ByteSequence
	; Prologue
	push rbx
    push rsi
    push rdi
	push r12
    push r13
    push r14
    sub rsp, 32

    ; Testing
	lea rcx, vigenere_text
	call Print
    
	lea rbx, texts
    lea rsi, encrypted_text
    lea rdi, decrypted_text
    mov r12, 0
    mov r13, texts_number
	lea r14, key
	jmp condition
cycle:
    mov ecx, r12d
	call PrintTestNumber

	; Encrypting and decrypting text using random key
	mov rcx, r14
	mov dl, 16
	call VigenereGenKey
	
	mov rcx, rsi
	mov rdx, [rbx + r12 * 8]
	mov r8, r14
	call VigenereEncrypt

	mov rcx, rdi
	mov rdx, rax
	mov r8, r14
	call VigenereDecrypt

	mov rcx, [rbx + r12 * 8]
	mov rdx, rax
	call PrintTestResult

	mov rcx, rsi
	call FreeBS
	mov rcx, rdi
	call FreeBS
	mov rcx, r14
	call FreeBS

	inc r12
condition:
	cmp r12, r13
	jb cycle
	
	; Epilogue
	add rsp, 32
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbx
	ret
TestVigenere endp

; Tests des cipher
;
; No parameters
;
; No return value
TestDes proc
	; Prologue
	push rbx
    push rsi
    push rdi
	push r12
    push r13
    push r14
    sub rsp, 40

    ; Testing
	lea rcx, des_text
	call Print
    
	lea rbx, texts
    lea rsi, encrypted_text
    lea rdi, decrypted_text
    mov r12, 0
    mov r13, texts_number
	jmp condition
cycle:
    mov ecx, r12d
	call PrintTestNumber

	; Encrypting and decrypting text using random key
	call DesGenKey
	mov r14, rax
	
	mov rcx, rsi
	mov rdx, [rbx + r12 * 8]
	mov r8, r14
	call DesEncrypt

	mov rcx, rdi
	mov rdx, rax
	mov r8, r14
	call DesDecrypt

	mov rcx, [rbx + r12 * 8]
	mov rdx, rax
	call PrintTestResult

	mov rcx, rsi
	call FreeBS
	mov rcx, rdi
	call FreeBS

	inc r12
condition:
	cmp r12, r13
	jb cycle
	
	; Epilogue
	add rsp, 40
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbx
	ret
TestDes endp

; Tests triple des cipher
;
; No parameters
;
; No return value
option prologue:PrologueDef
option epilogue:EpilogueDef
TestTripleDes proc
	local key: TripleDesKey
	; Prologue
	push rbx
    push rsi
    push rdi
	push r12
    push r13
    push r14
    sub rsp, 40

    ; Testing
	lea rcx, triple_des_text
	call Print
    
	lea rbx, texts
    lea rsi, encrypted_text
    lea rdi, decrypted_text
    mov r12, 0
    mov r13, texts_number
	lea r14, key
	jmp condition
cycle:
    mov ecx, r12d
	call PrintTestNumber

	; Encrypting and decrypting text using random key
	mov rcx, r14
	call TripleDesGenKey
	
	mov rcx, rsi
	mov rdx, [rbx + r12 * 8]
	mov r8, r14
	call TripleDesEncrypt

	mov rcx, rdi
	mov rdx, rax
	mov r8, r14
	call TripleDesDecrypt

	mov rcx, [rbx + r12 * 8]
	mov rdx, rax
	call PrintTestResult

	mov rcx, rsi
	call FreeBS
	mov rcx, rdi
	call FreeBS

	inc r12
condition:
	cmp r12, r13
	jb cycle
	
	; Epilogue
	add rsp, 40
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbx
	ret
TestTripleDes endp

; Tests blowfish cipher
;
; No parameters
;
; No return value
option prologue:PrologueDef
option epilogue:EpilogueDef
TestBlowfish proc
	local key: ByteSequence
	; Prologue
	push rbx
    push rsi
    push rdi
	push r12
    push r13
    push r14
    sub rsp, 32

    ; Testing
	lea rcx, blowfish_text
	call Print
    
	lea rbx, texts
    lea rsi, encrypted_text
    lea rdi, decrypted_text
    mov r12, 0
    mov r13, texts_number
	lea r14, key
	jmp condition
cycle:
    mov ecx, r12d
	call PrintTestNumber

	; Encrypting and decrypting text using random key
	mov rcx, r14
	mov dl, 32
	call BlowfishGenKey
	
	mov rcx, rsi
	mov rdx, [rbx + r12 * 8]
	mov r8, r14
	call BlowfishEncrypt

	mov rcx, rdi
	mov rdx, rax
	mov r8, r14
	call BlowfishDecrypt

	mov rcx, [rbx + r12 * 8]
	mov rdx, rax
	call PrintTestResult

	mov rcx, rsi
	call FreeBS
	mov rcx, rdi
	call FreeBS
	mov rcx, r14
	call FreeBS

	inc r12
condition:
	cmp r12, r13
	jb cycle
	
	; Epilogue
	add rsp, 32
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbx
	ret
TestBlowfish endp

; Tests rc4 cipher
;
; No parameters
;
; No return value
option prologue:PrologueDef
option epilogue:EpilogueDef
TestRC4 proc
	local key: ByteSequence
	; Prologue
	push rbx
    push rsi
    push rdi
	push r12
    push r13
    push r14
    sub rsp, 32

    ; Testing
	lea rcx, rc4_text
	call Print
    
	lea rbx, texts
    lea rsi, encrypted_text
    lea rdi, decrypted_text
    mov r12, 0
    mov r13, texts_number
	lea r14, key
	jmp condition
cycle:
    mov ecx, r12d
	call PrintTestNumber

	; Encrypting and decrypting text using random key
	mov rcx, r14
	mov dx, 128
	call RC4GenKey
	
	mov rcx, rsi
	mov rdx, [rbx + r12 * 8]
	mov r8, r14
	call RC4

	mov rcx, rdi
	mov rdx, rax
	mov r8, r14
	call RC4

	mov rcx, [rbx + r12 * 8]
	mov rdx, rax
	call PrintTestResult

	mov rcx, rsi
	call FreeBS
	mov rcx, rdi
	call FreeBS
	mov rcx, r14
	call FreeBS

	inc r12
condition:
	cmp r12, r13
	jb cycle
	
	; Epilogue
	add rsp, 32
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbx
	ret
TestRC4 endp

; Tests rc5 cipher
;
; No parameters
;
; No return value
option prologue:PrologueDef
option epilogue:EpilogueDef
TestRC5 proc
	local key: ByteSequence
	; Prologue
	push rbx
    push rsi
    push rdi
	push r12
    push r13
    push r14
    sub rsp, 32

    ; Testing
	lea rcx, rc5_text
	call Print
    
	lea rbx, texts
    lea rsi, encrypted_text
    lea rdi, decrypted_text
    mov r12, 0
    mov r13, texts_number
	lea r14, key
	jmp condition
cycle:
    mov ecx, r12d
	call PrintTestNumber

	; Encrypting and decrypting text using random key
	mov rcx, r14
	mov dx, 128
	call RC5GenKey
	
	mov rcx, rsi
	mov rdx, [rbx + r12 * 8]
	mov r8, r14
	mov r9b, 15
	call RC5Encrypt

	mov rcx, rdi
	mov rdx, rax
	mov r8, r14
	mov r9b, 15
	call RC5Decrypt

	mov rcx, [rbx + r12 * 8]
	mov rdx, rax
	call PrintTestResult

	mov rcx, rsi
	call FreeBS
	mov rcx, rdi
	call FreeBS
	mov rcx, r14
	call FreeBS

	inc r12
condition:
	cmp r12, r13
	jb cycle
	
	; Epilogue
	add rsp, 32
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbx
	ret
TestRC5 endp

; Tests aes cipher
;
; No parameters
;
; No return value
option prologue:PrologueDef
option epilogue:EpilogueDef
TestAes proc
	local key: ByteSequence
	; Prologue
	push rbx
    push rsi
    push rdi
	push r12
    push r13
    push r14
    sub rsp, 32

    ; Testing
	lea rcx, aes_text
	call Print
    
	lea rbx, texts
    lea rsi, encrypted_text
    lea rdi, decrypted_text
    mov r12, 0
    mov r13, texts_number
	lea r14, key
	jmp condition
cycle:
    mov ecx, r12d
	call PrintTestNumber

	; Encrypting and decrypting text using random key
	mov rcx, r14
	mov dx, 128
	call AesGenKey
	
	mov rcx, rsi
	mov rdx, [rbx + r12 * 8]
	mov r8, r14
	call AesEncrypt

	mov rcx, rdi
	mov rdx, rax
	mov r8, r14
	call AesDecrypt

	mov rcx, [rbx + r12 * 8]
	mov rdx, rax
	call PrintTestResult

	mov rcx, rsi
	call FreeBS
	mov rcx, rdi
	call FreeBS
	mov rcx, r14
	call FreeBS

	inc r12
condition:
	cmp r12, r13
	jb cycle
	
	; Epilogue
	add rsp, 32
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbx
	ret
TestAes endp

; Tests aes cipher
;
; No parameters
;
; No return value
option prologue:PrologueDef
option epilogue:EpilogueDef
TestTea proc
	local key: ByteSequence
	; Prologue
	push rbx
    push rsi
    push rdi
	push r12
    push r13
    push r14
    sub rsp, 32

    ; Testing
	lea rcx, tea_text
	call Print
    
	lea rbx, texts
    lea rsi, encrypted_text
    lea rdi, decrypted_text
    mov r12, 0
    mov r13, texts_number
	lea r14, key
	jmp condition
cycle:
    mov ecx, r12d
	call PrintTestNumber

	; Encrypting and decrypting text using random key
	mov rcx, r14
	call TeaGenKey
	
	mov rcx, rsi
	mov rdx, [rbx + r12 * 8]
	mov r8, r14
	call TeaEncrypt

	mov rcx, rdi
	mov rdx, rax
	mov r8, r14
	call TeaDecrypt

	mov rcx, [rbx + r12 * 8]
	mov rdx, rax
	call PrintTestResult

	mov rcx, rsi
	call FreeBS
	mov rcx, rdi
	call FreeBS
	mov rcx, r14
	call FreeBS

	inc r12
condition:
	cmp r12, r13
	jb cycle
	
	; Epilogue
	add rsp, 32
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbx
	ret
TestTea endp

; Tests rc6 cipher
;
; No parameters
;
; No return value
option prologue:PrologueDef
option epilogue:EpilogueDef
TestRC6 proc
	local key: ByteSequence
	; Prologue
	push rbx
    push rsi
    push rdi
	push r12
    push r13
    push r14
    sub rsp, 32

    ; Testing
	lea rcx, rc6_text
	call Print
    
	lea rbx, texts
    lea rsi, encrypted_text
    lea rdi, decrypted_text
    mov r12, 0
    mov r13, texts_number
	lea r14, key
	jmp condition
cycle:
    mov ecx, r12d
	call PrintTestNumber

	; Encrypting and decrypting text using random key
	mov rcx, r14
	mov dx, 128
	call RC6GenKey
	
	mov rcx, rsi
	mov rdx, [rbx + r12 * 8]
	mov r8, r14
	mov r9b, 20
	call RC6Encrypt

	mov rcx, rdi
	mov rdx, rax
	mov r8, r14
	mov r9b, 20
	call RC6Decrypt

	mov rcx, [rbx + r12 * 8]
	mov rdx, rax
	call PrintTestResult

	mov rcx, rsi
	call FreeBS
	mov rcx, rdi
	call FreeBS
	mov rcx, r14
	call FreeBS

	inc r12
condition:
	cmp r12, r13
	jb cycle
	
	; Epilogue
	add rsp, 32
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbx
	ret
TestRC6 endp
end