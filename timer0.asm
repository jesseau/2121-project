TIM0OVF:
	pushall
	lds dataL, displaycounter
	lds dataH, displaycounter+1
	adiw dataH:dataL, 1
	cpi dataL, LOW(1953)
	ldi temp1, HIGH(1953)
	cpc dataH, temp1
	brne timer_displaycont
	clr dataL
	clr dataH
	rcall display_turnt
	rcall display_open
	rcall display_power
timer_displaycont:
	sts displaycounter, dataL
	sts displaycounter+1, dataH

	cpl mode, RUNNINGMODE ;check if in running mode
	breq tim0continue
	cbi PORTE, 4 ; disable motor
	jmp tim0end

tim0continue:
;do the mag/turntable first
	lds dataL, turntcounter
	lds dataH, turntcounter+1
	adiw dataH:dataL, 1
	cpi dataL, LOW(1953)
	ldi temp1, HIGH(1953)
	cpc dataH, temp1
	breq mag_and_turn
	jmp mag_and_turn_end

mag_and_turn:
	clr dataL
	clr dataH
	lds temp1, magcounter
	cp temp1, power
	brlt motoron

;motor turns off
	cbi PORTE, 4
	jmp postmotor
motoron:
;motor turns on
	sbi PORTE, 4

postmotor:
	;do_lcd_command 0b11000000
	;do_lcd_data_im 'P'
	inc temp1
	cpi temp1, 4
	brlt update_mag
	clr temp1
update_mag:
	sts magcounter, temp1

turntable:
	lds temp3, turntable_counter
	inc temp3
	cpi temp3, 10
	brlt turntable_end
	clr temp3
	add ttpos, dir
	cpl ttpos, 0 ; check for underflow
	brge turntable_check_of
	ldl ttpos, 3
turntable_check_of:
	cpl ttpos, 4
	brlt turntable_end
	ldl ttpos, 0

turntable_end:
	sts turntable_counter, temp3
mag_and_turn_end:
	sts turntcounter, dataL
	sts turntcounter+1, dataH	

netxcomp: ;next comparison	
	lds dataL, tim0counter
	lds dataH, tim0counter+1	
	adiw dataH:dataL, 1
	cpi dataL, LOW(7812)
	ldi temp1, HIGH(7812)
	cpc dataH, temp1
	breq nextsecond ; using reverse branching to prevent rjmp screwups
	;tim0counter has not counted to 1 second yet
	jmp tim0end
		
nextsecond: ;1 second has passed, so update the clock
	clr dataL ;set counter back to 0
	clr dataH
	cpl seconds, 0
	brne adjust_seconds
	cpl minutes, 0
	brne adjust_minutes
	jmp display_time
adjust_minutes:
	dec minutes
	ldl seconds, 59
	jmp display_time
adjust_seconds:
	dec seconds	

display_time:
	print_time
	cpl seconds, 0
	breq comp_minutes
	jmp tim0end
comp_minutes:
	cpl minutes, 0
	breq change_finish_mode
	jmp tim0end

change_finish_mode:
	ldl mode, FINISHMODE
	rcall reset_fadetimer
	start_beeper
	do_lcd_command 0b10000000
	do_lcd_data_im 'D'
	do_lcd_data_im 'o'
	do_lcd_data_im 'n'
	do_lcd_data_im 'e'
	do_lcd_data_im ' '
	do_lcd_command 0b11000000 ; set cursor to second line
	do_lcd_data_im 'R'
	do_lcd_data_im 'e'
	do_lcd_data_im 'm'
	do_lcd_data_im 'o'
	do_lcd_data_im 'v'
	do_lcd_data_im 'e'
	do_lcd_data_im ' '
	do_lcd_data_im 'F'
	do_lcd_data_im 'o'
	do_lcd_data_im 'o'
	do_lcd_data_im 'd'

tim0end:
	sts tim0counter, dataL ;store counter from registers back into memory
	sts tim0counter+1, dataH
	popall
	reti
