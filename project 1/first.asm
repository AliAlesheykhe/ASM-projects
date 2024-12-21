global main
extern printf
extern fgets
extern strstr
extern atoi
extern stdin

section .bss
    input resb 256        ; Allocate 256 bytes for input storage (user's string)
    number resq 1         ; Reserve space for the number (64-bit integer)
    flag resb 1

section .text
main:
    sub rsp, 8

    mov byte [flag], 0
    mov rdi, input
    mov rsi, 256
    mov rdx, [stdin]
    call fgets
    mov rdi, input
    call atoi
    mov r14, rax 
    call check_s
    cmp byte [flag], 1
    je s_found
    call s_not_found

    add rsp, 8
    ret

s_not_found:   
    sub rsp, 8                
    mov rsi, r14
    mov rbx, r14
    shr rsi, 14                         ;shifting 14 to the right to remove the first 0 - 14 bits of the number. the bits 14 to 17 will be the first 4 bits of the number after this.
    shl rsi, 60                         ;shifitng 60 bits to the left because we only need the first 4 bits and rsi has 64 of them
    shr rsi, 60                         ;removed all the bits by shifting to left and right except for the bits 14 - 17 (start counting from 0)
    mov r14, rsi                        ;saving rsi in r14 because call to printf changes rsi                                               
    mov rdi, printf_format
    call printf
    ;we do the same thing we did for bits 20-23 as we did for bits 14-17 in the previous section
    shr rbx, 20                         
    shl rbx, 60
    shr rbx, 60
    mov rdi, printf_format              
    mov rsi, rbx
    call printf                         ;print the number represented by the bits 20-23
    mov rdi, printf_format
    mov rsi, r14
    add rsi, rbx
    call printf                         ;print the sum of the two numbers
    add rsp, 8
    ret
s_found:
    mov rsi, r14
    mov rbx, r14
    shr rsi, 14
    shl rsi, 60
    shr rsi, 60
    mov r14, rsi
    shr rsi, 3
    cmp rsi, 1
    je less_than_zero_14_17
    print_first_num:
        mov rdi, printf_format
        mov rsi, r14
        call printf
    shr rbx, 20
    shl rbx, 60
    shr rbx, 60
    mov r15, rbx
    shr rbx, 3
    cmp rbx, 1
    je less_than_zero_20_23
    print_second_num:
        mov rdi, printf_format
        mov rsi, r15
        call printf
    ;print sum:
    mov rsi, r14
    add rsi, r15
    mov rdi, printf_format
    call printf
    call done
less_than_zero_14_17:
    add r14, 0xFFFFFFFFFFFFFFF0
    jmp print_first_num
less_than_zero_20_23:
    add r15, 0xFFFFFFFFFFFFFFF0
    jmp print_second_num
done:
    mov rax, 60
    xor rdi, rdi
    syscall

check_s:
    sub rsp, 8
    mov rdi, input
    mov rsi, s_substring
    call strstr
    test rax, rax
    jz no_s
    mov byte [flag], 1  
no_s:
    add rsp, 8
    ret
section .data
scanf_format: db "%s", 0                                 ;Format string for scanf (to read the entire input)
printf_format: db "%d", 10, 0                            ;Format string to print the number
s_substring: db "-s", 0                                  ;The "-s" flag string for comparison