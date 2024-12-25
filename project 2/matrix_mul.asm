section .bss
    input resb 256
    dimensions resq 3
    token resq 1
    matrix1 resq 1
    matrix2 resq 1
    matrix3 resq 1

section .data
    delimiter db " ", 0
    simple_int_printf db "%d", 10, 0
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

    ; Read the first matrix
    mov r13, [matrix1]
    mov r14, [dimensions]
    mov r12, [dimensions + 8]
    call read_matrix

    ; Read the second matrix
    mov r13, [matrix2]
    mov r14, [dimensions + 8]
    mov r12, [dimensions + 16]
    call read_matrix

    ; Print matrix1
    mov r12, [dimensions]
    mov r14, [matrix1]
    call print_matrix

    ; Print matrix2
    mov r12, [dimensions + 8]
    mov r14, [matrix2]
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
    mov rax, [dimensions]
    imul rax, [dimensions + 8]
    imul rax, 8
    call malloc
    test rax, rax
    jz memory_allocation_failed
    mov [matrix1], rax

    ; Reserving memory for the second matrix
    mov rax, [dimensions + 8]
    imul rax, [dimensions + 16]
    imul rax, 8
    call malloc
    test rax, rax
    jz memory_allocation_failed
    mov [matrix2], rax

    ; Reserving memory for the third matrix (the result of the multiplication)
    mov rax, [dimensions]
    imul rax, [dimensions + 16]
    imul rax, 8
    call malloc
    test rax, rax
    jz memory_allocation_failed
    mov [matrix3], rax

    jmp end_method

read_input:
    sub rsp, 8

    mov rdi, input
    mov rsi, 256
    mov rdx, [stdin]
    call fgets

    jmp end_method

read_matrix:
    sub rsp, 8

    imul r12, 8
    mov r15, 0
    read_matrix_loop:
        cmp r15, r14
        je end_method

        call read_input

        ; Tokenize and store the numbers given in the matrix
        mov rax, r15
        imul rax, r12
        push r12
        mov r12, input
        add r13, rax
        push r15
        call tokenize
        pop r15
        pop r12

        inc r15
        jmp read_matrix_loop
    je end_method

print_matrix:
    sub rsp, 8
    imul r12, [dimensions + 8]
    mov r13, 0
    print_matrix_loop:
        cmp r13, r12
        je end_method
        mov rdi, simple_int_printf
        mov rax, r13
        imul rax, 8
        add rax, r14
        mov rsi, [rax]
        call printf
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
    mov rdi, [matrix1]
    call free
    mov rdi, [matrix2]
    call free
    mov rdi, [matrix3]
    call free
    mov rax, 60
    xor rdi, rdi
    syscall

