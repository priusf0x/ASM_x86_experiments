.model tiny 
.code
org 100h

; ======================= DEFINES =========================

__exit__ macro 
		mov ah, 4ch
		int 21h
	 endm

EOL 	equ "$"

; uses dx ah
PRINT macro string  
	lea dx, [string]
	mov ah, 09h 
	int 21h 		
      endm


; uses dl ah al
GETCH macro  
	mov ah, 08h
	int 21h
      endm

; ========================= MAIN ==========================
 
_start: 
		call state_machine 
		__exit__ 

; ====================== FUNCTIONS ========================

state_machine:

.repeat: 
	GETCH 
	jz .leave			; LEAVE IF EMPTY
	sub al, 48 			; CONVERSATION TO NUMBER
	mov bl, [.msg_count]	
	cmp al, bl			; CHECK IF CORRECT
	jbe .err_skip			; LEAVE IF INCORRECT
	PRINT .err_msg
	jmp .repeat		
.err_skip:
	test al, al			; ZERO TEST
	jz .leave			; LEAVE BY DEFAULT

	xor bx, bx
	mov bl, al
	shl bl, 1	
	mov dx, [bx + offset .states]
	mov ah, 09h
	int 21h

	jmp .repeat 

	.leave:
		PRINT .exit_msg 
		ret 


	.data
	align 2
.states:
		dw .exit_msg 
		dw .svetloye
.msg_count 	db 1

.text:
.err_msg 	db "Неправильное значение!", 10, EOL
.exit_msg	db "Все пока!", 10, EOL
.svetloye	db "В целом сойдет", 10, EOL 
	.code 


		

end		_start