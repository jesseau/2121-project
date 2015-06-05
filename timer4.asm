TIM4OVF:
	pushall
	lds temp1, tim4counter
	cpi temp1, 30 ; 250ms counter for keypad press
	breq stop_keypad_beep
	cpi temp1, 122 ; 1 second counter for beeper
	brne TIM4CONT ; it's not a second yet, so count up and do nothing
	cpi beepcount, 4 ; if we're here at the 4th iteration, then stop the beeping, i.e. only 3 iterations are completed
	brlt ignore_beeper
turn_beeper_off:
	clr beepcount
	stop_beeper
	jmp TIM4CONT
stop_keypad_beep:
	cpi iskeypad, 1
	brne TIM4CONT
	clr iskeypad
;	cpi temp1, 31 ; if we have a counter higher than 30, then that shouldn't break the existing finished beep
;	brge TIM4CONT
	stop_beeper
	jmp TIM4END
ignore_beeper:
	inc beepcount
	clr temp1 ; reset the 1 second counter
	sts tim4counter, temp1
	lds temp2, OCR4CL
	cpi temp2, 0
	breq beeper_off
	cpi temp2, 255
	breq beeper_on
beeper_on:
	clr temp2
	sts OCR4CL, temp2
	jmp TIM4END
beeper_off:
	ser temp2
	sts OCR4CL, temp2
	jmp TIM4END
TIM4CONT:
	inc temp1
	sts tim4counter, temp1
TIM4END:
	popall
	reti
