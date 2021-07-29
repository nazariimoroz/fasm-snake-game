format PE64 Console
entry start
include 'C:\Users\tk\Desktop\FASM\INCLUDE\win64a.inc'


section '.data' data readable writeable executable
    ; Constants
    height = 20
    width  = 32
    
    ; enum Direction
    dir.Left    = 0
    dir.Right   = 1
    dir.Up      = 2
    dir.Down    = 3
    
    ; Structs
    struc SPoint x,y{
        .x dd x
        .y dd y
    }

    ; Strings
    str1 db "Hello World %i",0xA,0x0
    str2 db "TEST",0xA,0x0
    apples_out db 0xA,"Apples: %i", 0x0,0xA
    
    
    loose_word db "You loose!!!",0xA,0x0
    
    ; Registered varibles
    map  rb height * width
    snake rb width * height * 2 
    snake.size rd 1 
    snake.dir rb 1
    
    ; vars
    apple SPoint 1,1
    apples_count dd 0
    
   
    

section '.code' code readable writeable executable


    start:
        call init_snake
        call init_rand
                
        .infinity_loop:
            invoke sleep,110                                
            call set_cur_position
            call key_check_snake
            
            call move_snake
            call check_wall
            call check_apple
            call tail_check_snake
            
            call init_map 
            call put_apple
            call put_snake
            
            
            invoke printf, map; map out
            invoke printf, apples_out, [apples_count]
        
        call check_exit
        jmp .infinity_loop               
        
        
        call [getch]
        invoke exit_process, 0
    ret


    ;===========================================================================


    ; map array initialization
    init_map:
        
        ; fill first and last lines in map
        push rax                        
        
            i = 0
            while i < width
                mov rax, map
                add rax, i
                mov [rax], byte '#'
                mov rax, height - 1
                imul rax, width
                add rax, map
                add rax, i
                mov [rax], byte '#' 
            i = i + 1
            end while
            mov rax, map
            add rax, width - 1
            mov [rax], byte 0xA
        
            mov rax, width
            imul rax, height
            dec rax
            add rax, map
            mov [rax], byte 0x0
        
        pop rax
         
        ; fill other lines in map
        i = 1  
        while i < height - 1
            
            mov rax, width
            imul rax, i
            j = 0
            while j < width
                mov rbx, map
                add rbx, rax
                add rbx, j    
                if j = 0 | j = width - 2
                    mov [rbx], byte '#'
                else 
                    mov [rbx], byte ' '
                end if
            j = j + 1
            end while    
            add rax, map
            add rax, width - 1
            mov [rax], byte 0xA      
                
        i = i + 1 
        end while
        
    ret    
    
    
    ;===========================================================================
    
    
    set_cur_position:
        invoke get_std_handle, STD_OUTPUT_HANDLE    
        invoke set_console_cursor_position, rax, 0,0
    ret
    
    
    ;===========================================================================
    
    
    init_snake:
        mov [snake.dir], dir.Down
        mov [snake.size], dword 2
        
        mov [snake],   4
        mov [snake+1], 2
        
        mov [snake+2], 4
        mov [snake+3], 1
    ret
    
    
    ;===========================================================================
    
    
    put_snake:
        mov rcx, 0
        mov ecx, dword[snake.size]
        .wh:
            
            mov rax, rcx
            dec rax
            imul rax, 2
            xor rbx, rbx ; x
            mov bl, byte [snake + rax]      
            xor rdx, rdx ; y
            mov dl, byte [snake + rax + 1]   
            imul rdx, width       
            mov [map + rdx + rbx], byte '@' 
            
        loop .wh
    ret
    
    
    ;===========================================================================
    
    
    key_check_snake:                  
        mov r8, 'A'
        invoke get_key_state, r8
        cmp rax, 1
            jg .A
            
        mov r8, 'S'
        invoke get_key_state, r8
        cmp rax, 1
            jg .S
        
        mov r8, 'D'            
        invoke get_key_state, r8
        cmp rax, 1
            jg .D
        
        mov r8, 'W'             
        invoke get_key_state, r8  
        cmp rax, 1
            jg .W
        jmp .exit
                    
         .A:
            mov [snake.dir], dir.Left
         
         jmp .exit
         .S:
            mov [snake.dir], dir.Down
            
         jmp .exit
         .D:
            mov [snake.dir], dir.Right
            
         jmp .exit
         .W:
            mov [snake.dir], dir.Up
            
    .exit:
    ret
    
    
    ;===========================================================================
    
    
    move_snake:
        xor rcx, rcx
        mov ecx, dword [snake.size]
        dec rcx
        .wh:
            mov rax, rcx
            imul rax, 2          
                
            xor rbx, rbx ; x next
            mov bl, [snake + rax - 2]
            xor rdx, rdx ; y next
            mov dl, [snake + rax - 1]
            mov [snake + rax], bl
            mov [snake + rax + 1], dl
                
        loop .wh
        
            ; move snake head
        cmp [snake.dir], dir.Left
            je .LEFT
        cmp [snake.dir], dir.Right
            je .RIGHT
        cmp [snake.dir], dir.Up
            je .UP
        cmp [snake.dir], dir.Down
            je .DOWN
        
        .LEFT:
            xor rcx, rcx
            mov cl,[snake]
            dec rcx
            mov [snake], cl
            
        jmp .exit 
        .RIGHT:
            xor rcx, rcx
            mov cl,[snake]
            inc rcx
            mov [snake], cl
        jmp .exit 
        .UP:                      
            xor rcx, rcx
            mov cl,[snake + 1]
            dec rcx
            mov [snake + 1], cl
        jmp .exit 
        .DOWN:                    
            xor rcx, rcx
            mov cl,[snake + 1]
            inc rcx
            mov [snake + 1], cl
         
    .exit:               
    ret
    
    
    ;===========================================================================
    
    
    check_wall:
        ; check on walls
        xor rbx, rbx ; x
        mov bl, byte [snake]      
        xor rdx, rdx ; y
        mov dl, byte [snake + 1]
    
        ; ----------------------X----------------------
        cmp rbx, 0
            je .from_zero_to_max_point_X
        cmp rbx, width - 2
            je .from_max_point_to_one_X
        ; ----------------------X----------------------
        ; ----------------------Y----------------------
        cmp rdx, 0
            je .from_zero_to_max_point_Y
        cmp rdx, height - 1
            je .from_max_point_to_one_Y
        ; ----------------------Y----------------------            
        jmp .check_on_standart_wall
        
        .from_zero_to_max_point_X:
            mov [snake], width - 3
        jmp .check_on_standart_wall
        .from_max_point_to_one_X:
            mov [snake], 1
        jmp .check_on_standart_wall
        
        .from_zero_to_max_point_Y:
            mov [snake + 1], height - 2
        jmp .check_on_standart_wall
        .from_max_point_to_one_Y:
            mov [snake + 1], 1
        jmp .check_on_standart_wall
    
        ; check on standart wall
        .check_on_standart_wall:
        xor rbx, rbx ; x
        mov bl, byte [snake]      
        xor rdx, rdx ; y
        mov dl, byte [snake + 1]  
        imul rdx, width
        mov r8, map
        add r8, rdx
        add r8, rbx
        cmp [r8], byte '#'
            je .p_exit   
        
        jmp .exit
        .p_exit:
            invoke printf, loose_word  
            invoke sleep, 5000
            invoke exit_process, 0
          
    .exit:
    ret
    
    
    ;===========================================================================
    
    
    ; snake head and snake tail check
    tail_check_snake:
        mov rcx, 0
        mov ecx, dword[snake.size]
        dec rcx
        .wh:
            
            mov rax, rcx
            imul rax, 2
            xor rbx, rbx ; x
            mov bl, byte [snake + rax]      
            xor rdx, rdx ; y
            mov dl, byte [snake + rax + 1]          
            cmp bl, [snake]
                jne .next_iter    
            cmp dl, [snake + 1]
                je .p_exit
            .next_iter:
                
        loop .wh
        jmp .exit
        .p_exit:
            invoke printf, loose_word  
            invoke sleep, 5000
            invoke exit_process, 0
    .exit:
    ret
    
    
    ;===========================================================================
    
    
    put_apple:
        xor rax, rax
        mov eax, [apple.y]
        imul eax, width
        add eax, [apple.x]
        add eax, map
        mov [eax], byte '+'
    ret
    
    
    ;===========================================================================
    
    
    check_apple: 
        xor rbx, rbx ; x
        mov bl, byte [snake]      
        xor rdx, rdx ; y
        mov dl, byte [snake + 1]
        
        cmp ebx, [apple.x]
            jne .exit
        cmp edx, [apple.y]
            je .ok
            jmp .exit
        .ok:
            invoke rand
            mov rbx, width - 3
            div rbx
            mov r8, rdx ; x
            
            push r8
            invoke rand
            mov rbx, height - 2
            div rbx
            mov rbx, rdx ; y
            pop r8
            mov rax, r8
            
            inc rax
            mov [apple.x], eax
            
            inc rbx
            mov [apple.y], ebx
            inc [snake.size]
            inc [apples_count]
    .exit:
    ret
    
    
    ;===========================================================================    
    
    
    
    
    
    
    
    
    
section '.my_func' code readable writeable executable
    ; in:
    ; r8 - string(pointer)
    putc_:
        invoke printf, r8
    ret
    
    check_exit:
        invoke get_key_state, VK_ESCAPE
        cmp rax, 1
            jg .tr
            jmp .exit
        
        .tr:
        invoke exit_process, 0
        
    .exit:
    ret
    
    init_rand:
        mov rax, 0
        invoke time, rax 
        invoke srand, rax
    ret
    
                  
section 'idata' data import readable writeable executable
    library \
        karnel,         'kernel32.dll',\
        user,           'user32.dll',\
        msvcrt,         'msvcrt.dll'
    
    
    import user, \
        get_key_state,  'GetKeyState'
    
    import karnel,\
        exit_process,       'ExitProcess',\
        sleep,              'Sleep',\
set_console_cursor_position,'SetConsoleCursorPosition',\
        get_std_handle,     'GetStdHandle'
    
    
    import msvcrt,\
  		printf,         'printf',\
  		sprintf,        'sprintf',\
        getch,          '_getch',\
        system,         'system',\
        rand,           'rand',\
        srand,          'srand',\
        time,           'time'
        
