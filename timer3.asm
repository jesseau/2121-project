TIM3OVF:
	pushall
tim3_loop:
	lds temp1, OCR3CL
	cpl fadedir, INCREASING
	breq fade_increasing
	cpl fadedir, DECREASING
	breq fade_decreasing
fade_decreasing:
	cpi temp1, 0
	breq TIM3CONT
	subi temp1, 2
	sts OCR3CL, temp1
	jmp TIM3CONT
fade_increasing:
	cpi temp1, 254
	breq TIM3CONT
	subi temp1, -2
	sts OCR3CL, temp1

TIM3CONT:
	cpl mode, RUNNINGMODE
	breq running_ignore

	lds dataL, tim3counter
	lds dataH, tim3counter+1
	adiw dataH:dataL, 1
	cpi dataL, low(2460) ; use 2460 for 10 seconds later
	ldi temp1, high(2460)
	cpc dataH, temp1
	brne TIM3END

	ldl fadedir, DECREASING

running_ignore:
	clr temp1
	mov dataL, temp1
	mov dataH, temp1

TIM3END:
	sts tim3counter, dataL
	sts tim3counter+1, dataH
	popall
	reti

