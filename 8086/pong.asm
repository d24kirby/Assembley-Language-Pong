Assume cs:code, ds:data, ss:stack

data segment 
; All variables defined within the data segment
; menu variables
menu1 db "*******************************************************************************$"
menu2 db "                               Welcome$"
menu3 db "                                 to$"
menu4 db "                 ________  ________  ________   ________ $"
menu5 db "                |\   __  \|\   __  \|\   ___  \|\   ____\$"
menu6 db "                \ \  \|\  \ \  \|\  \ \  \\ \  \ \  \___|$"
menu7 db "                 \ \   ____\ \  \\\  \ \  \\ \  \ \  \  ___$"
menu8 db "                  \ \  \___|\ \  \\\  \ \  \\ \  \ \  \|\  \$"
menu9 db "                   \ \__\    \ \_______\ \__\\ \__\ \_______\$"
menu10 db "                    \|__|     \|_______|\|__| \|__|\|_______|$"
menu11 db "	        Press the correct key to select your option$"
menu12 db "                               p - Play Game$"
menu13 db "                               e - Exit Game$"
menu14 db "*******************************************************************************$"

player1_ready db "Player 1 press enter when ready!$"
player2_ready db "Player 2 press enter when ready!$"
players_ready db "Players are ready, game is starting!$"
player1_score db 0
player2_score db 0
player2 db "Player 2 is the winner!!!$"
player1 db "Player 1 is the winner!!!$"

player1_cursor_pos db 11
player2_cursor_pos db 11
ball_y_pos db 11
ball_x_pos db 39
ball_direction db 0
data ends

stack segment
;Stack size and the top of the stack defined in the stack segment
dw 100 dup(?)
stacktop:
stack ends

code segment
begin:
mov ax,data
mov ds,ax
mov ax,stack
mov ss,ax
mov sp, offset stacktop

; Code Begin

call setup_ports
call main_menu

; ################################# Exit Program ################################################## 
exit_program:
call clear_screen
mov dh, 00
mov dl, 00
mov ah, 2h
int 10h
mov ah, 4ch
int 21h

; ################################ Main Menu Controller #############################################
main_menu:

controller:
mov dx, 0
call clear_screen
call display_main_menu
input_loop:
call main_menu_input
cmp dx,0
je input_loop
cmp dx, 1
je start_game
jmp return_main_menu

start_game:
call players_are_ready
call game
jmp controller

return_main_menu:
ret

; ################################# Main Game Loop ##################################################
game:
push ax
push bx
push cx
push dx 
game_start:
call reset_game
call super_sleep
gameplay:
call move_ball
cmp dx, 1
je player1_scored
cmp dx, 2
je player2_scored

call player1_input
call player2_input

call sleep
jmp gameplay

player1_scored:
mov si, offset player1_score
mov al, [si]
add al, 1
mov [si],al
call player1_leds
jmp score

player2_scored:
mov si, offset player2_score
mov al, [si]
add al, 1
mov [si],al
; led things
jmp score

score:
mov si, offset player1_score
mov bl , [si]
cmp bl, 8
je player1_winner
mov si, offset player2_score
mov bl , [si]
cmp bl, 8
je player2_winner
jmp game_start

player1_winner:
call clear_screen
mov si, offset player1
call display_win_msg
call p1_flash_leds
jmp return_to_main_menu

player2_winner:
call clear_screen
mov si, offset player2
call display_win_msg
;call p2_flash_leds
jmp return_to_main_menu

return_to_main_menu:
mov dx, 140h
mov al, 0ffh
out dx, al
mov dx, 142h
mov al, 0ffh
out dx, al
mov si, offset player1_score
mov al, 0
mov [si], al
mov si, offset player2_score
mov al, 0
mov [si], al
call player1_leds
;call player2_leds
pop dx
pop cx
pop bx
pop ax

ret

; ################################ Random Number Generator #####################################################
RANDGEN4:         ; generate a rand no using the system time

push ax
push bx

   MOV AH, 00h  ; interrupts to get system time        
   INT 1AH      ; CX:DX now hold number of clock ticks since midnight      

   mov  ax, dx
   xor  dx, dx   
   mov cx, 4
   div  cx       ; here dx contains the remainder of the division - from 0 to 3
   
pop bx 
pop ax
   
RET

; ################################ Random Number Generator #####################################################
RANDGEN24:         ; generate a rand no using the system time

push ax
push bx
push cx

   MOV AH, 00h  ; interrupts to get system time        
   INT 1AH      ; CX:DX now hold number of clock ticks since midnight      

   mov  ax, dx
   xor  dx, dx   
   mov cx, 24
   div  cx       ; here dx contains the remainder of the division - from 0 to 23
   
pop cx
pop bx 
pop ax
   
RET

; ################################ player 1 leds #####################################################
player1_leds:
push ax
push bx
push cx
push dx

mov dx, 140h
mov al, 00h
mov cx, 6h
led_loop_1:
not al
out dx, al
call led_sleep
loop led_loop_1

mov al , 0ffh
out dx, al

mov si, offset player1_score
mov bl, [si]
cmp bl, 0h
je player1_leds_exit

score_loop_1a:
mov al, 00000000b
mov cl, 00000001b
score_loop_1b:
or al, cl
shl cl,1
dec bl
cmp bl, 0h
jne score_loop_1b
not al
out dx, al
jmp player1_leds_exit

player1_leds_exit:
pop dx
pop cx
pop bx
pop ax

ret

; ################################ Display Win Message #####################################################
display_win_msg:
push ax
push bx
push cx
push dx

mov dh, 11
mov dl, 23
mov ah, 2h
int 10h
call print

pop dx
pop cx
pop bx
pop ax

ret

; ################################ Player 1 Flash LEDs #####################################################
p1_flash_leds:
push ax
push bx
push cx
push dx

mov dx, 140h
mov al, 00h
mov cx, 8h
led_loop_1_flash:
not al
out dx, al
call led_sleep
loop led_loop_1_flash

pop dx
pop cx
pop bx
pop ax

ret

; ################################ Set-up Ports #####################################################
setup_ports:
push ax
push bx
push cx
push dx

;Set direction mode
MOV DX,143H  
MOV AL,2
OUT DX,AL

MOV DX,141H  ;Set all port B lines to input
MOV AL,00H
OUT DX,AL

MOV DX,140H  ;Set all port B lines to input
MOV AL,0ffH
OUT DX,AL

MOV DX,142H  ;Set all port B lines to input
MOV AL,0ffH
OUT DX,AL

;Set Operation mode
MOV DX,143H  
MOV AL,3
OUT DX,AL

pop dx
pop cx
pop bx
pop ax

ret

; ################################ Players Ready  ###################################################
players_are_ready:
push ax
push bx
push cx
push dx

call clear_screen
mov dh, 00
mov dl, 00
mov ah, 2h
int 10h

mov si, offset player1_ready
call print
ready1:
mov ah, 08h
int 21h
cmp al, 0dh
jne ready1

mov si, offset player2_ready
call print
ready2:
mov ah, 08h
int 21h
cmp al, 0dh
jne ready2

mov si, offset players_ready
call print

call super_sleep

pop dx
pop cx
pop bx 
pop ax
ret

; ################################# Main Menu Input ################################################## 
main_menu_input:
push ax
push bx
push cx

mov dx, 0
mov ah,01h
int 16h
jz input_end

input_get:
mov ah,00h
int 16h
cmp al,"p"
je input1
cmp al,"e"
je input2
jmp input_end

input1:
mov dx,1
jmp input_end

input2:
mov dx, 2
jmp input_end

input_end:
pop cx
pop bx
pop ax

ret

; ################################# Player 1 Input ################################################## 
player1_input:
push ax
push bx
push cx

player1_input_get:
mov dx, 141h
in al, dx
and al, 3H
cmp al, 2H
je player1_move_up
cmp al, 1H
je player1_move_down
jmp player1_input_end

player1_move_up:
call clear_player1_cursor
mov si, offset player1_cursor_pos
mov al,[si]
cmp al, 01h
je player1_input_end
sub al, 1
mov [si],al
call set_player1_cursor
jmp player1_input_end

player1_move_down:
call clear_player1_cursor
mov si, offset player1_cursor_pos
mov al,[si]
cmp al, 22h
je player1_input_end
add al, 1
mov [si],al
call set_player1_cursor
jmp player1_input_end
exit_program_sub_1:
mov dx, 1

player1_input_end:
pop cx
pop bx
pop ax

ret

; ################################# Player 2 Input ################################################## 
player2_input:
push ax
push bx
push cx

player2_input_get:
mov dx, 141h
in al, dx
and al, 00001100b
cmp al, 00001000b
je player2_move_up
cmp al, 00000100b
je player2_move_down
jmp player2_input_end

player2_move_up:
call clear_player2_cursor
mov si, offset player2_cursor_pos
mov al,[si]
cmp al, 01h
je player2_input_end
sub al, 1
mov [si],al
call set_player2_cursor
jmp player2_input_end

player2_move_down:
call clear_player2_cursor
mov si, offset player2_cursor_pos
mov al,[si]
cmp al, 22h
je player2_input_end
add al, 1
mov [si],al
call set_player2_cursor
jmp player2_input_end

exit_program_sub_2:
mov dx, 1

player2_input_end:
pop cx
pop bx
pop ax

ret

; ################################# Clear Screen ################################################## 
clear_screen:
push ax
push bx
push cx
push dx

mov ah,06h
mov al,00h
mov bh,07h
mov cx,0000h
mov dl,79h
mov dh,24h
int 10h

pop dx
pop cx
pop bx
pop ax

ret

; ################################# Reset Game ################################################## 
reset_game:
push ax
push bx
push cx
push dx

mov si, offset player1_cursor_pos
mov al , [si]
mov al, 11
mov [si],al

mov si, offset player2_cursor_pos
mov al , [si]
mov al, 11
mov [si],al

call RANDGEN24
mov si, offset ball_y_pos
mov [si],dl

mov si, offset ball_x_pos
mov al , [si]
mov al, 39
mov [si],al

call RANDGEN4
mov si, offset ball_direction
mov [si],dl

call clear_screen
call set_ball
call set_player1_cursor
call set_player2_cursor

pop dx
pop cx
pop bx
pop ax

ret

; ################################# Set Ball Position ################################################## 
set_ball:
push ax
push bx
push cx
push dx
mov si, offset ball_y_pos
mov dh, [si]
mov si, offset ball_x_pos
mov dl, [si]
mov ah, 2h
int 10h

mov dl, 2ah
mov ah,2h
int 21h

pop dx
pop cx
pop bx
pop ax

ret

; ################################# Clear Ball Position ################################################## 
clear_ball:
push ax
push bx
push cx
push dx
mov si, offset ball_y_pos
mov dh, [si]
mov si, offset ball_x_pos
mov dl, [si]
mov ah, 2h
int 10h

mov dl, " "
mov ah,2h
int 21h

pop dx
pop cx
pop bx
pop ax

ret

; ################################# Set Player 1 Cursor ################################################## 
set_player1_cursor:
push ax
push bx
push cx
push dx

mov si, offset player1_cursor_pos
mov al,[si]
sub al, 1
mov dh, al
mov dl, 00
mov ah, 2h
int 10h

mov dl, 0b3h
int 21h

mov al,[si]
mov dh, al
mov dl, 00
int 10h

mov dl, 0b3h
int 21h

mov al,[si]
add al,1
mov dh, al
mov dl, 00
int 10h

mov dl, 0b3h
int 21h

pop dx
pop cx
pop bx
pop ax

ret

; ############################### Clear Player 1 Cursor ##################################################
clear_player1_cursor:
push ax
push bx
push cx
push dx

mov si, offset player1_cursor_pos
mov al,[si]
sub al, 1
mov dh, al
mov dl, 00
mov ah, 2h
int 10h

mov dl, " "
int 21h

mov al,[si]
mov dh, al
mov dl, 00
int 10h

mov dl, " "
int 21h

mov al,[si]
add al,1
mov dh, al
mov dl, 00
int 10h

mov dl, " "
int 21h

pop dx
pop cx
pop bx
pop ax

ret

; ################################# Set Player 2 Cursor ################################################## 
set_player2_cursor:
push ax
push bx
push cx
push dx

mov si, offset player2_cursor_pos
mov al,[si]
sub al, 1
mov dh, al
mov dl, 79
mov ah, 2h
int 10h

mov dl, 0b3h
int 21h

mov al,[si]
mov dh, al
mov dl, 79
int 10h

mov dl, 0b3h
int 21h

mov al,[si]
add al,1
mov dh, al
mov dl, 79
int 10h

mov dl, 0b3h
int 21h

pop dx
pop cx
pop bx
pop ax

ret

; ############################## Clear Player 2 Cursor ################################################## 
clear_player2_cursor:
push ax
push bx
push cx
push dx

mov si, offset player2_cursor_pos
mov al,[si]
sub al, 1
mov dh, al
mov dl, 79
mov ah, 2h
int 10h

mov dl, " "
int 21h

mov al,[si]
mov dh, al
mov dl, 79
int 10h

mov dl, " "
int 21h

mov al,[si]
add al,1
mov dh, al
mov dl, 79
int 10h

mov dl, " "
int 21h

pop dx
pop cx
pop bx
pop ax

ret

; ################################# Move Ball ################################################## 
move_ball:
push ax
push bx
push cx

; ball direction is stored in al
; ball position is stored in bx (x in bh, y in bl)
; cursor positions are in cx (player 1 in ch, player 2 in cl)

call clear_ball

mov dx, 0

;Get ball position information
mov si, offset ball_y_pos
mov bl, [si]
mov si, offset ball_x_pos
mov bh, [si]

;Get cursor positions
mov si, offset player2_cursor_pos
mov cl, [si]
mov si, offset player1_cursor_pos
mov ch, [si]

;Get ball direction
mov si, offset ball_direction
mov al , [si]

now:
cmp al, 0
jne sow
call north_west
jmp return_move_ball
sow: 
cmp al, 1
jne noe
call south_west
jmp return_move_ball
noe: 
cmp al, 2
jne soe
call north_east
jmp return_move_ball
soe: 
cmp al, 3
jne return_move_ball_exit
call south_east
jmp return_move_ball

return_move_ball:
cmp dx, 0
jne return_move_ball_exit
;update all ball and direction variables
;set ball position information
mov si, offset ball_y_pos
mov [si],bl
mov si, offset ball_x_pos
mov [si],bh
;Get ball direction
mov si, offset ball_direction
mov [si],al
call set_ball
return_move_ball_exit:
pop cx
pop bx
pop ax

ret

; ################################# North West Ball Movement ###############################
north_west:
cmp bh, 0
jne nw_y

; paddle check
add ch, 1
cmp bl, ch
je nw_paddle_bounce
sub ch,1
cmp bl,ch
je nw_paddle_bounce
sub ch,1
cmp bl,ch
je nw_paddle_bounce
; score for player 2
mov dx, 2
jmp nw_return

nw_y:
cmp bl, 0
jne nw_move
mov al, 1
add bl,1
sub bh,1
jmp nw_return

nw_move:
sub bl, 1 
sub bh, 1
jmp nw_return

nw_paddle_bounce:
cmp bl,0
jne nw_normal_bounce
; corner bounce 
mov al , 3
add bl , 1
add bh , 1
jmp nw_return
nw_normal_bounce:
mov al, 2
sub bl,1
add bh,1
jmp nw_return

nw_return:
ret

; ################################# South West Ball Movement ###############################
south_west:
cmp bh, 0
jne sw_y

; paddle check
add ch, 1
cmp bl, ch
je sw_paddle_bounce
sub ch,1
cmp bl,ch
je sw_paddle_bounce
sub ch,1
cmp bl,ch
je sw_paddle_bounce
; score for player 2
mov dx, 2
jmp sw_return

sw_y:
cmp bl, 23 
jne sw_move
mov al, 0
sub bl,1
sub bh,1
jmp sw_return

sw_move:
add bl, 1 
sub bh, 1
jmp sw_return

sw_paddle_bounce:
cmp bl,23
jne sw_normal_bounce
; corner bounce 
mov al , 2
sub bl , 1
add bh , 1
jmp sw_return
sw_normal_bounce:
mov al, 3
add bl,1
add bh,1
jmp sw_return

sw_return:
ret

; ################################# North East Ball Movement ###############################
north_east:
cmp bh, 79
jne ne_y

; paddle check
add cl, 1
cmp bl, cl
je ne_paddle_bounce
sub cl,1
cmp bl,cl
je ne_paddle_bounce
sub cl,1
cmp bl,cl
je ne_paddle_bounce
; score for player 1
mov dx, 1
jmp ne_return

ne_y:
cmp bl, 0
jne ne_move
mov al, 3
add bl,1
add bh,1
jmp ne_return

ne_move:
sub bl, 1 
add bh, 1
jmp ne_return

ne_paddle_bounce:
cmp bl,0
jne ne_normal_bounce
; corner bounce 
mov al , 1
add bl , 1
sub bh , 1
jmp ne_return
ne_normal_bounce:
mov al, 0
sub bl,1
sub bh,1
jmp ne_return

ne_return:
ret

; ################################# South East Ball Movement ###############################
south_east:
cmp bh, 79
jne se_y

; paddle check
add cl, 1
cmp bl, cl
je se_paddle_bounce
sub cl,1
cmp bl,cl
je se_paddle_bounce
sub cl,1
cmp bl,cl
je se_paddle_bounce
; score for player 1
mov dx, 1
jmp se_return

se_y:
cmp bl, 23
jne se_move
mov al, 2
sub bl,1
add bh,1
jmp se_return

se_move:
add bl, 1 
add bh, 1
jmp se_return

se_paddle_bounce:
cmp bl,23
jne se_normal_bounce
; corner bounce 
mov al , 0
sub bl , 1
sub bh , 1
jmp se_return
se_normal_bounce:
mov al, 1
add bl,1
sub bh,1
jmp se_return

se_return:
ret

; ################################# Sleep ################################################## 
sleep:
push ax
push bx
push cx
push dx

mov cx, 0ffffh
sleep_loop:
nop
nop
nop
nop
nop
loop sleep_loop

pop dx
pop cx
pop bx
pop ax

ret

; ################################# Super Sleep ############################################ 
super_sleep:
push ax
push bx
push cx
push dx

mov bx, 020h
super_sleep_outer_loop:
mov cx, 0ffffh
super_sleep_loop:
nop
nop
nop
nop
nop
loop super_sleep_loop
dec bx
cmp bx,0h
jne super_sleep_outer_loop

pop dx
pop cx
pop bx
pop ax

ret

; ################################# Super Sleep ############################################ 
led_sleep:
push ax
push bx
push cx
push dx

mov bx, 5h
led_sleep_outer_loop:
mov cx, 0ffffh
led_sleep_loop:
nop
nop
nop
nop
nop
loop led_sleep_loop
dec bx
cmp bx,0h
jne led_sleep_outer_loop

pop dx
pop cx
pop bx
pop ax

ret

; ################################# Main Menu Display #############################################
display_main_menu:
push ax
push bx
push cx
push dx
mov ah, 2

mov si, offset menu1
call print
call cr 
call cr 
mov si, offset menu2
call print
mov si, offset menu3
call print
call cr 
call cr 
mov si, offset menu4
call print
mov si, offset menu5
call print
mov si, offset menu6
call print
mov si, offset menu7
call print
mov si, offset menu8
call print
mov si, offset menu9
call print
mov si, offset menu10
call print
call cr 
call cr 
call cr 
mov si, offset menu11
call print
call cr 
mov si, offset menu12
call print
call cr  
mov si, offset menu13
call print
call cr 
mov si, offset menu14
call print

exit_display_main_menu:
pop dx
pop cx
pop bx
pop ax
ret

; ################################# Print ################################################## 
print:
push ax 
push dx 
mov ah,2 

;this block adds new line and places 
;cursor at the new line 
call cr

abc1: 
mov dl,[si] 
cmp dl,"$" 
je here1 
int 21h 
inc si 
jmp abc1 

here1: 
pop dx
pop ax 
ret 

; ################################# CR ################################################## 
cr:
push ax 
push dx 
mov ah,2 

;this block adds new line and places 
;cursor at the new line 
mov dl,0dh 
int 21h 
mov dl,0Ah 
int 21h 

pop dx
pop ax 
ret 


; Code End
code ends
end begin