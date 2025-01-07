section .bss
    input resb 256
    dimensions resq 2
    token resq 1
    matrix1 resq 1
    matrix2 resq 1
    matrix3 resq 1
    transpose_matrix resq 1

section .data
    newLine db 0xA
    space db " ", 0
    simple_int_printf db "%lld", 10, 0
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


%macro print 2 
    mov rax, 1 ; syscall number for write 
    mov rdi, 1 ; file descriptor (stdout) 
    mov rsi, %1 ; pointer to the message 
    mov rdx, %2 ; length of the message 
    syscall 
%endmacro

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
    mov r14, [dimensions]               ;passing the number of rows
    mov r12, [dimensions + 8]           ;passing the number of columns
    call read_matrix

    mov rdi, [matrix1]                      ;the matrix to be transposed
    mov rsi, [transpose_matrix]             ;where to save the transposed matrix
    mov rdx, [dimensions]                   ;rows of the matrix to be transposed
    mov rcx, [dimensions + 8]               ;columns of the matrix to be transposed
    call transpose

    ;multiply the transpose matrix by matrix2, save the result to matrix3
    mov rdi, [transpose_matrix]             ;the left matrix
    mov rsi, [matrix2]                      ;the right matrix
    mov rcx, [matrix3]                      ;the result matrix
    mov r10, [dimensions + 8]               ;rows of left matrix and result
    mov r11, [dimensions]                   ;columns of left matrix and rows of right matrix
    mov r12, r10                            ;columns of right matrix and result
    call multiply_matrices

    ;calculate the trace of matrix3 for the final result
    mov rdi, [matrix3]
    mov rsi, [dimensions + 8]
    mov rdx, rsi
    call calculate_trace                    ;result will be saved to rax

    ;print the final result
    mov rdi, simple_int_printf
    mov rsi, rax
    call printf

    jmp done
tokenize:
    ;inputs: string to tokenize and address to save in r12 and r13 respectively
    sub rsp, 8
    mov rdi, r12
    mov rsi, space
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
        mov rsi, space
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
    mov rsi, 8                     ; size of each element (64-bits or 8 bytes)
    call calloc
    test rax, rax
    jz memory_allocation_failed
    mov [matrix1], rax

    ; Reserving memory for the second matrix
    mov rdi, [dimensions]           ; rows of matrix2
    imul rdi, [dimensions + 8]      ; multiply by columns of matrix2
    mov rsi, 8                      ; size of each element (64-bits or 8 bytes)
    call calloc
    test rax, rax
    jz memory_allocation_failed
    mov [matrix2], rax

    ; Reserving memory for the third matrix (result of the multiplication)
    mov rdi, [dimensions + 8]           ; rows of matrix3
    imul rdi, [dimensions + 8]          ; multiply by columns of matrix3
    mov rsi, 8                          ; size of each element (64-bits or 8 bytes)
    call calloc
    test rax, rax
    jz memory_allocation_failed
    mov [matrix3], rax

    ;reserving memory for the transpose matrix
    mov rdi, [dimensions + 8]           ; rows of the transpose
    imul rdi, [dimensions]              ; multiply by columns of transpose
    mov rsi, 8                          ; size of each element (64-bits or 8 bytes)
    call calloc
    test rax, rax
    jz memory_allocation_failed
    mov [transpose_matrix], rax

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
    ;inputs address of the matrix, number of rows, number of columns in r13, r14 and r12 respectively
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
    ;inputs: number of rows (r12), number of columns(r13), address of the matrix (r14)
    sub rsp, 8
    
    imul r12, r13                           ;total size of the matrix
    xor r15, r15                            ;setting r15 to 0 to use as an iteration in the loop
    print_matrix_loop:
        cmp r15, r12                        
        je end_method                       ;exits if all numbers have been printed

        ; Format the number as a string 
        mov rdi, simple_int_printf 
        mov rsi, [r14] 
        call printf
        ;print space, 1

        add r14, 8                          ;go to the next number in the matrix
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

memory_allocation_failed:
    mov rdi, error_msg
    call printf
    jmp done

multiply_matrices:
    ;inputs: addresses of the first, second and destination matrices in rdi, rsi and rcx respectively
    ;and rows of the first matrix(r10), columns of the first matrix(r11) and and columns of the second matrix(r12)
    sub rsp, 8               
    mov r8, r10                             ;load rows of matrix3 to r8                   
    imul r8, r12                            ;multiply rows of matrix3 by its columns to get the total size of matrix3
    mov r9, 0
    multiply_loop:
        mov rax, r9
        xor rdx, rdx
        div r12                             ;divide rax r9 by the number of elements in each row of rax
        push r8
        push r9
        mov r8, rax                         ;put the current of matrix1 to be multiplied in r8 (input for dot_product)
        mov r9, rdx                         ;put the current column of matrix2 to be multiplied in r9 (as input for dot_product)
        call dot_product
        mov [rcx], r15                      ;store the result of the dot product to matrix3
        add rcx, 8
        pop r9
        pop r8
        inc r9
        cmp r9, r8
        jl multiply_loop
    jmp end_method

dot_product:
    ;inputs: row of the first matrix (r8), column of the second matrix (r9)
    sub rsp, 8

    mov rax, rdi                        ;load matrix1 ddress into rax
    mov rbx, rsi                        ;load matrix2 address into rbx
    mov r13, r8                         ;load current row to r13
    imul r13, r11                       ;multiply r13 by the number of columns in the first matrix
    imul r13, 8                         ;save the size of the row in bytes (each number is 8 bytes)
    add rax, r13                        ;load the current matrix1 row address into rax

    imul r9, 8
    add rbx, r9                         ;address of the first element of the r9th column in matrix2
    mov r14, r12                        ;load the length of rows in the second matrix
    imul r14, 8                         ;get the size of the rows of matrix2

    mov r15, 0                          ;setting the initial value of r15 to 0 in order to use it to calculate the result    
    mov r13, 0                          ;use to check if loop is finished (it will be compared with r11, number of rows in matrix2)
    calculate_number_loop:
        mov r8, [rax]                   ;load the current number of matrix1's current column into r14
        imul r8, [rbx]                  ;multiply by the corresponding number in matrix2
        add r15, r8                     ;add to the accumilator
        add rbx, r14                    ;go to the next number of matrix2 in the same column but different row
        add rax, 8                      ;go to the next number in the current row
        inc r13
        cmp r13, r11
        jl calculate_number_loop
    jmp end_method
transpose:
    ;inputs: address of matrix1 (rdi), address of where to store the transpose(rsi), row of the matrix to be transposed (rdx), and its columns (rcx)
    sub rsp, 8

    mov r8, rdx
    imul r8, rcx                        ;saving the size of the resulting transpose matrix into r8
    xor r9, r9                          ;setting r9 to 0 to use as loop iterator

    mov r10, rcx
    imul r10, 8                         ;saving the size of each row of matrix1 into r10

    transpose_loop:
        mov rax, [rdi]
        mov [rsi], rax                  ;saving the value in the current number in matrix1 to the transpose
        inc r9                          ;incrementing r9 to keep track of the numbers saved to transpose
        add rsi, 8                      ;moving on to the location of the next number to be saved in transpose
        mov rax, [rdi + r10]
        mov [rsi], rax         
        inc r9
        add rsi, 8
        add rdi, 8                      ;moving on to the first number of the next column in matrix1

        cmp r9, r8                      ;comparing iterator to the total number of elements that need to be placed in transpose
        jl transpose_loop               ;going back to the loop if the number of elements that have already been placed is less than those that need to be placed.
    jmp end_method
calculate_trace:
    ;inputs: address of matrix to calculate the trace of (rdi), rows (rsi), columns (rdx)
    ;saves the result to rax
    sub rsp, 8

    xor rbx, rbx                        ;setting rbx to 0 to use as loop iterator (the current row)
    xor rax, rax                        ;setting rax to 0 to save the result

    mov r8, rdx
    imul r8, 8                          ;saving the size of each row into r8

    calculate_trace_loop:
        mov r9, rbx
        imul r9, 8                      ;this is the index to be added to the current row address in order to get access to the number in the current row that is on the main diagonal
        add rax, [rdi + r9]             ;adding the number on the diagonal to the result
        add rdi, r8                     ;moving on to the next row of the matrix
        inc rbx                         ;incrementing rbx to get the index of the next diagonal number (which is on the next row), rbx = number of the next row

        cmp rbx, rsi
        jl calculate_trace_loop         ;continueing the loop if the number of rows considered is less than the total number of rows
    jmp end_method

done:
    mov rax, 60
    xor rdi, rdi
    syscall


