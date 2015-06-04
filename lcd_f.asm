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

display_turnt:
	pushall
	do_lcd_command 0b10011011
	cpl ttpos, 0
	brne display_next1
	do_lcd_data_im '|'
	jmp display_turnt_end
display_next1:
	cpl ttpos, 1
	brne display_next2
	do_lcd_data_im '/'
	jmp display_turnt_end
display_next2:
	cpl ttpos, 2
	brne display_next3
	do_lcd_data_im '-'
	jmp display_turnt_end
display_next3:
	do_lcd_data_im 0
		
display_turnt_end:
	popall
	ret

display_open:
	pushall
	do_lcd_command 0b11000011
	cpl open, 1
	brne display_closed
	do_lcd_data_im 'O'
	jmp display_open_end
display_closed:
	do_lcd_data_im 'C'

display_open_end:
	popall
	ret
