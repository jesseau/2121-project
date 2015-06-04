.macro do_lcd_command
	push r16
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
	pop r16
.endmacro
.macro do_lcd_data
	push r16
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
	pop r16
.endmacro

.macro do_lcd_data_im
	push r16
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
	pop r16
.endmacro

.macro make_backslash
	do_lcd_command 0b01000000
	do_lcd_data_im 0b00000000
	do_lcd_data_im 0b00010000
	do_lcd_data_im 0b00001000
	do_lcd_data_im 0b00000100
	do_lcd_data_im 0b00000010
	do_lcd_data_im 0b00000001
	do_lcd_data_im 0b00000000
	do_lcd_data_im 0b00000000
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
	push temp2
	clr temp2
	brbc 7, no_iflag
	ldi temp2, 1
no_iflag:
	cli
	do_lcd_command 0b00000001
	convert_num minutes
	do_lcd_data_im ':'
	convert_num seconds
	rcall display_turnt
	rcall display_open

	cpi temp2, 1
	brne no_sei
	sei
no_sei:
	pop temp2
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
