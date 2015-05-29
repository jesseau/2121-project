.macro do_lcd_command
	push r16
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
	pop r16
.endmacro
.macro do_lcd_data
	push r16
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
	pop r16
.endmacro

.macro make_backslash
;backslash symbol
.endmacro

.macro print_num
	pop @0
	ldi @1, 48
	add @0, @1
	do_lcd_data temp1
endprintnum:
.endmacro

;use as convert_num mynumber
.macro convert_num
	push temp1 
	push temp2

	mov temp1, @0

	ldi temp2, 10
	divide temp1, temp2, temp3
	push temp2

	ldi temp2, 10
	divide temp1, temp2, temp3
	push temp2

	print_num temp1, temp2
	print_num temp1, temp2

	pop temp2
	pop temp1
.endmacro

.macro print_time
	push temp1
	set_cursor 0
	convert_num minutes
	ldi temp1, 58 ; colon
	do_lcd_data temp1
	convert_num seconds
	pop temp1
.endmacro

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro

;
; Send a command to the LCD (r16)
;

lcd_command:
	out PORTF, r16
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	ret

lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW
lcd_wait_loop:
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret
