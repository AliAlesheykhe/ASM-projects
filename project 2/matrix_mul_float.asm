section .bss
    input resb 256
    align 16
    dimensions resq 6         ; Reserve space for 3 double values (3 * 8 = 24 bytes)
    token resq 1
    matrix1 resq 1
    matrix2 resq 1
    matrix3 resq 1

section .data
    newLine db 0xA
    space db " ", 0
    simple_double_format db "%lf", 10, 0    ; Corrected format specifier for double
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
    call tokenize

    ;putting this printf call here because for some reason, not having this results in 2.0 to not be printed
    mov rdi, 0
    movapd xmm0, [dimensions]         ; Load double from memory to xmm0
    call printf

    mov rdi, simple_double_format
    movapd xmm0, [dimensions]         ; Load double from memory to xmm0
    call printf

    mov rdi, simple_double_format
    movapd xmm0, [dimensions + 16]   ; Load double from memory to xmm0
    call printf

    mov rdi, simple_double_format
    movapd xmm0, [dimensions + 32]   ; Load double from memory to xmm0
    call printf

    jmp done

tokenize:
    ; inputs: string to tokenize in r12, address to save in r13
    sub rsp, 8
    mov rdi, r12
    mov rsi, space
    mov r15, 0

    call strtok
    mov [token], rax

    tokenize_loop:
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
        jmp tokenize_loop

read_input:
    sub rsp, 8

    mov rdi, input
    mov rsi, 256
    mov rdx, [stdin]
    call fgets

    jmp end_method

end_method:
    add rsp, 8
    ret
done:
    mov rax, 60
    xor rdi, rdi
    syscall
