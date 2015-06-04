pause_mode:
	lds temp1, pausetype
	cpi pausetype, 1
	brne pause_button_press
	cpl open, 0	
	brne pause_mode_end
	ldl mode, RUNNINGMODE
	jmp pause_mode_end

pause_button_press:
	cpi result, '*'
	brne switch_to_entry
	ldl mode, RUNNINGMODE	 

switch_to_entry:
	cpi result, '#'
	brne pause_mode_end
	ldl mode, ENTRYMODE

pause_mode_end:
	ldl pmode, PAUSEMODE
	ret

