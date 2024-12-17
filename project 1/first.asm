global main
extern printf
extern scanf
section .text

main:
    sub rsp, 8                          ;stack pointer realignment

    mov rdi, scanf_format1                     
    call scanf                          ;scanf will automatically save the user input in rsi
    mov rbx, rsi                        ;saving the original input for the number 20 - 23 bits as we are going to remove these bits in rsi 
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
    ret
    
section .data
scanf_format1: db "%d", 0
printf_format: db "%d", 10, 0