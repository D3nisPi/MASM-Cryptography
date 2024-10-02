include .\include\common\console.inc
include .\include\common\string.inc
include .\include\common\byte_sequence.inc
include .\include\test.inc

.code
main proc
    sub rsp, 40

    call TestCaesar
    call TestSubstitution
    call TestPermutation
    call TestOtp
    call TestVigenere
    call TestDes
    call TestTripleDes
    call TestBlowfish
    call TestRC4
    call TestRC5
    call TestRC6
    call TestAes
    call TestTea

    mov rax, 0
    
    add rsp, 40
    ret
main endp
end