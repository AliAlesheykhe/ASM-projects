section .bss
    input resb 256
    dimensions resq 3         ; Reserve space for 3 int values (3 * 8 = 24 bytes)
    token resq 1
    matrix1 resq 1
    matrix2 resq 1
    matrix3 resq 1

section .data
    newLine db 0xA
    space db " ", 0
    simple_double_format db "%lf", 10, 0    ; Corrected format specifier for double
    simple_int_format db "%lld", 10, 0    ; Corrected format specifier for double
    error_msg db "Memory allocation failed!", 10, 0
    buffer db 32 dup(0) ; Buffer to hold the formatted string

section .text
global main
extern printf
extern fgets
extern strtok
extern atoi
extern stdin
extern malloc
extern free
extern calloc
extern sprintf
extern fputs
extern stdout
extern strtod


%macro print 2 
    mov rax, 1 ; syscall number for write 
    mov rdi, 1 ; file descriptor (stdout) 
    mov rsi, %1 ; pointer to the message 
    mov rdx, %2 ; length of the message 
    syscall 
%endmacro

main:
    sub rsp, 8

    call read_input             ; Read the dimensions of the matrices

    ; Get the dimensions of the matrices as numbers
    mov r12, input
    mov r13, dimensions
    call tokenize_int_inputs

    call reserve_memory_for_matrices

    ;Read the first matrix
    mov r13, [matrix1]                  ;passing the matrix address
    mov r14, [dimensions]               ;passing the number of rows of the matrix
    mov r12, [dimensions + 8]           ;passing the number of columns of the matrix
    call read_matrix

    ; Read the second matrix
    mov r13, [matrix2]                  ;passing the address
    mov r14, [dimensions + 8]           ;passing the number of rows
    mov r12, [dimensions + 16]          ;passing the number of columns
    call read_matrix

    mov r12, [dimensions]               ;number of rows
    mov r13, [dimensions + 8]           ;number of elements in each row (columns)
    mov r14, [matrix1]                  ;passing the address
    call print_matrix

    mov r12, [dimensions + 8]           ;number of rows
    mov r13, [dimensions + 16]          ;number of elements in each row (columns)
    mov r14, [matrix2]                  ;passing the address
    call print_matrix
   
    jmp done

tokenize_double_inputs:
    ; inputs: string to tokenize in r12, address to save in r13
    sub rsp, 8
    mov rdi, r12
    mov rsi, space

    call strtok
    mov [token], rax

    double_tokenize_loop:
        cmp qword [token], 0
        je end_method

        mov rdi, [token]       ; Address of the token string
        lea rsi, [rsp]         ; Address to store the end pointer (temporary)
        call strtod            ; Convert string to double


        movapd [r13], xmm0     ; Store double to memory

        mov rdi, 0             ; Set strtok first parameter to NULL for subsequent calls
        mov rsi, space
        call strtok
        mov [token], rax

        add r13, 16             ; Move to the next double (8 bytes for double)
        jmp double_tokenize_loop
    jmp end_method

tokenize_int_inputs:
    ;inputs: string to tokenize and address to save in r12 and r13 respectively
    sub rsp, 8
    mov rdi, r12
    mov rsi, space

    call strtok
    mov [token], rax

    int_tokenize_loop:
        cmp qword [token], 0
        je end_method

        mov rdi, [token]
        call atoi
        mov [r13], rax

        mov rdi, 0
        mov rsi, space
        call strtok
        mov [token], rax

        add r13, 8
        jmp int_tokenize_loop

    jmp end_method
read_input:
    sub rsp, 8

    mov rdi, input
    mov rsi, 256
    mov rdx, [stdin]
    call fgets

    jmp end_method

reserve_memory_for_matrices:
    sub rsp, 8
    ; Reserving memory for the first matrix
    mov rdi, [dimensions]          ; rows of matrix1
    imul rdi, [dimensions + 8]     ; multiply by columns of matrix1
    mov rsi, 16                    ; size of each element (64-bit). we use 16 instead of eight because the size of the xmm registers is 16 bytes
    call calloc
    test rax, rax
    jz memory_allocation_failed
    mov [matrix1], rax

    ; Reserving memory for the second matrix
    mov rdi, [dimensions + 8]      ; rows of matrix2
    imul rdi, [dimensions + 16]    ; multiply by columns of matrix2
    mov rsi, 16                    ; size of each element (64-bit). we use 16 instead of eight because the size of the xmm registers is 16 bytes
    call calloc
    test rax, rax
    jz memory_allocation_failed
    mov [matrix2], rax

    ; Reserving memory for the third matrix (result of the multiplication)
    mov rdi, [dimensions]          ; rows of matrix3
    imul rdi, [dimensions + 16]    ; multiply by columns of matrix3
    mov rsi, 16                    ; size of each element (64-bit). we use 16 instead of eight because the size of the xmm registers is 16 bytes
    call calloc
    test rax, rax
    jz memory_allocation_failed
    mov [matrix3], rax

    jmp end_method
    memory_allocation_failed:
        mov rdi, error_msg
        call printf
        jmp done


read_matrix:
    ;inputs: address of the matrix, number of rows, number of columns in r13, r14 and r12 respectively
    sub rsp, 8
    imul r12, 16                     ;size of each row
    mov r15, 0
    read_matrix_loop:
        cmp r15, r14                ;comparing r15 with the number of rows
        je end_method

        call read_input

        ; Tokenize and store the numbers given in the matrix
        push r12
        mov r12, input
        call tokenize_double_inputs
        pop r12

        inc r15
        jmp read_matrix_loop
    jmp end_method

print_matrix:
    ;inputs: number of rows (r12), number of columns(r13), address of the matrix (r14)
    sub rsp, 8
    
    imul r12, r13                           ;total size of the matrix
    xor r15, r15                            ;setting r15 to 0 to use as an iteration in the loop
    print_matrix_loop:
        cmp r15, r12                        
        je end_method                       ;exits if all numbers have been printed

        ;calling an additional print because it will only print 0.000000 for some reason
        mov rdi, 0
        movapd xmm0, [r14] 
        call printf

        ; print the number
        mov rdi, simple_double_format
        movapd xmm0, [r14] 
        call printf
        ;print space, 1

        add r14, 16                          ;go to the next number in the matrix
        inc r15                             ;increment to keep track of the numbers printed
        ;check if next line should be printed
        mov rax, r15                            
        xor rdx, rdx
        div r13                             ;dividing r15 (index in matrix to be printed) by the number of elements in each row of the matrix (r13)
        test rdx, rdx                       ;checking the remainder of the previous division
        jz print_newLine                    ;print newLine if the remainder was zero (if the next number is in the next row of the matrix)
        jmp print_matrix_loop
        print_newLine:
            print newLine, 1
            jmp print_matrix_loop
    jmp end_method
    

end_method:
    add rsp, 8
    ret
done:
    mov rax, 60
    xor rdi, rdi
    syscall
