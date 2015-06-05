finish_mode:

fmode_checkbuttons:
	cpi result, BUT1PRESSED
	brne fmode_nextcheck
	do_lcd_command 0b00000001
	stop_beeper
	ldl mode, ENTRYMODE
fmode_nextcheck:
	cpi result, '#'
	brne fmode_finish
	do_lcd_command 0b00000001
	stop_beeper
	ldl mode, ENTRYMODE

fmode_finish:
	ldl pmode, FINISHMODE
	ret

