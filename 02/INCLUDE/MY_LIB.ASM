PRINT_STR macro string
	lea dx, [string + bx]
	mov ah, 09h
	int 21h
endm 