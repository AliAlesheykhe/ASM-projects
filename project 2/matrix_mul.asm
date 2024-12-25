section .bss
    input resb 256
    dimensions resq 3
    token resq 1
    matrix1 resq 1
    matrix2 resq 1
    matrix3 resq 1

section .data
    delimiter db " ", 0
    simple_int_printf db "%lld", 10, 0
    printf_int_space db "%lld ", 0
    error_msg db "Memory allocation failed!", 10, 0

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

main:
    sub rsp, 8
    ; Getting the initial dimensions for the matrices
    mov rdi, simple_int_printf
    call read_input

    ; Get the dimensions of the matrices as numbers
    mov r12, input
    mov r13, dimensions
    call tokenize

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

    ;Print matrix1
    mov r12, [dimensions]               ;calculating the amount of numbers to print by multiplying the number of rows by columns
    imul r12, [dimensions + 8]
    mov r14, [matrix1]                  ;passing the address
    call print_matrix

    ; Print matrix2
    mov r12, [dimensions + 8]           ;calculating the amount of numbers to print by multiplying the number of rows by columns
    imul r12, [dimensions + 16]
    mov r14, [matrix2]                  ;passing the address
    call print_matrix

    jmp done
tokenize:
    sub rsp, 8
    mov rdi, r12
    mov rsi, delimiter
    mov r15, 0

    call strtok
    mov [token], rax

    tokenize_loop:
        cmp qword [token], 0
        je end_method

        mov rdi, [token]
        call atoi
        mov [r13 + r15], rax

        mov rdi, 0
        mov rsi, delimiter
        call strtok
        mov [token], rax

        add r15, 8
        jmp tokenize_loop

        jmp end_method
reserve_memory_for_matrices:
    sub rsp, 8
    ; Reserving memory for the first matrix
    mov rdi, [dimensions]          ; rows of matrix1
    imul rdi, [dimensions + 8]     ; multiply by columns of matrix1
    mov rsi, 8                     ; size of each element (64-bit)
    call calloc
    test rax, rax
    jz memory_allocation_failed
    mov [matrix1], rax

    ; Reserving memory for the second matrix
    mov rdi, [dimensions + 8]      ; rows of matrix2
    imul rdi, [dimensions + 16]    ; multiply by columns of matrix2
    mov rsi, 8                     ; size of each element (64-bit)
    call calloc
    test rax, rax
    jz memory_allocation_failed
    mov [matrix2], rax

    ; Reserving memory for the third matrix (result of the multiplication)
    mov rdi, [dimensions]          ; rows of matrix3
    imul rdi, [dimensions + 16]    ; multiply by columns of matrix3
    mov rsi, 8                     ; size of each element (64-bit)
    call calloc
    test rax, rax
    jz memory_allocation_failed
    mov [matrix3], rax

    add rsp, 8
    ret


read_input:
    sub rsp, 8

    mov rdi, input
    mov rsi, 256
    mov rdx, [stdin]
    call fgets

    jmp end_method

read_matrix:
    sub rsp, 8

    imul r12, 8                     ;size of each row
    mov r15, 0
    read_matrix_loop:
        cmp r15, r14                ;comparing r15 with the number of rows
        je end_method

        call read_input

        ; Tokenize and store the numbers given in the matrix
        push r12
        mov r12, input
        push r15
        call tokenize
        pop r15
        pop r12
        add r13, r12

        inc r15
        jmp read_matrix_loop
    je end_method

print_matrix:
    sub rsp, 8
    mov r13, 0
    print_matrix_loop:
        cmp r13, r12
        je end_method
        mov rdi, simple_int_printf
        mov rsi, [r14]
        call printf
        add r14, 8
        inc r13
        jmp print_matrix_loop
    jmp end_method
    
end_method:
    add rsp, 8
    ret

memory_allocation_failed:
    mov rdi, error_msg
    call printf
    jmp done
done:
    mov rax, 60
    xor rdi, rdi
    syscall

