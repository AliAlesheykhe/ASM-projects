global main
extern printf
extern fgets
extern atoi
extern stdin
extern strtok
;Ali Alesheykhe 402105687
;run this using:
;nasm -f elf64 -g -F dwarf -o first.o first.asm
;gcc -no-pie -o first first.o -lc

section .bss
    input resb 256
    token resq 1
    r_num resq 1
    n_num resq 1
    valid resb 1
section .data
    printf_format db "%d", 10, 0
    deliminater db " ", 0
section .text
main:
    sub rsp, 8

    mov byte[valid], 0
    mov rdi, input
    mov rsi, 256
    mov rdx, [stdin]
    call fgets

    mov rdi, input
    mov rsi, deliminater
    call strtok
    mov [token], rax

    mov rdi, [token]
    call atoi
    mov [n_num], rax

    mov rdi, 0
    mov rsi, deliminater
    call strtok
    mov [token], rax

    mov rdi, [token]
    call atoi
    mov [r_num], rax

    ; mov rsi, [n_num]
    ; call print_num

    ; mov rsi, [r_num]
    ; call print_num
    mov rax, [n_num]
    mov rbx, [r_num]
    call n_choose_r

    mov rsi, rcx
    call print_num

    add rsp, 8
    ret
print_num:
    sub rsp, 8

    mov rdi, printf_format
    call printf

    add rsp, 8
    ret
n_choose_r:
    push rbx        ; Save rbx
    push rdi        ; Save rdi
    push r8         ; Save r8

    cmp rax, rbx
    je n_equals_r
    jl n_less_than_r 

    cmp rbx, 0
    jl r_less_than_zero
    je r_equals_zero

    sub rax, 1
    mov rdi, rbx    ; Save current rbx
    call n_choose_r
    mov r8, rcx     ; Store result in r8
    
    mov rbx, rdi    ; Restore rbx
    sub rbx, 1
    mov rdi, rax    ; Save current rax
    call n_choose_r
    add rcx, r8     ; Add results
    
    add rax, 1      ; Restore rax

    pop r8          ; Restore r8
    pop rdi         ; Restore rdi
    pop rbx         ; Restore rbx

    ret

    r_equals_zero:
        mov rcx, 1
        pop r8          ; Clean up the stack
        pop rdi
        pop rbx
        ret
    r_less_than_zero:
        mov rcx, 0
        pop r8          ; Clean up the stack
        pop rdi
        pop rbx
        ret
    n_equals_r:
        mov rcx, 1
        pop r8          ; Clean up the stack
        pop rdi
        pop rbx
        ret
    n_less_than_r:
        mov rcx, 0
        pop r8          ; Clean up the stack
        pop rdi
        pop rbx
        ret



    

    


