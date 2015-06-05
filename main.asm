.include "m2560def.inc"
.include "tools_m.asm"
.include "lcd_m.asm"

.def enterpl = r2 ; boolean flag for power level insertion mode
.def numpressed = r3 ; for entry mode, how many digits have been pressed so far
.def ttpos = r4 ;turntable position
.def pmode = r5
.def power = r6
.def row = r7
.def col = r8
.def rmask = r9
.def cmask = r10
.def pressed = r11
.def open = r12
.def mode = r13
.def minutes = r14
.def seconds = r15
.def temp1 = r16
.def temp2 = r17
.def temp3 = r18
.def result = r19
.def dir = r20 ; stands for direction
.def fadedir = r21 ; fade direction for backlight (advanced feature)
.def beepcount = r22
.def iskeypad = r23

.def dataL = r24
.def dataH = r25

.equ BUT1 = 0 ; e.g. use "andi temp, (1<<BUT1)" to check PB1 pressed
.equ BUT0 = 1
.equ BUT1PRESSED = 0xF0
.equ BUT0PRESSED = 0x0F

.equ ENTRYMODE = 0
.equ RUNNINGMODE = 1
.equ PAUSEMODE = 2
.equ FINISHMODE = 3

.equ INCREASING = 1
.equ DECREASING = 0

.dseg
tim0counter: .byte 2
tim3counter: .byte 2
tim4counter: .byte 1
turntcounter: .byte 2 ;stands for turntable counter
turntpos: .byte 1 ;turntable position
magcounter: .byte 1
pausetype: .byte 1
displaycounter: .byte 2
turntable_counter: .byte 1

.cseg
.org 0x00
	jmp RESET
.org OVF1addr
	jmp DEFAULT
.org OVF0addr
	jmp TIM0OVF
.org OVF3addr
	jmp TIM3OVF
.org OVF4addr
	jmp TIM4OVF

DEFAULT:
	reti

.include "init.asm"
.include "timer0.asm"
.include "timer3.asm"
.include "timer4.asm"

main:
;main loop => check what mode we're in, call function for that mode
;mode function returns when it is no longer the mode
mainloop:
	rcall get_input
	cpl open, 1
	brne main_normal_input
	cpi result, BUT0PRESSED
	brne main_no_input
	ldl open, 0
	jmp main_mode_check
main_no_input:
	ldi result, BUT1PRESSED
	jmp main_mode_check
main_normal_input:
	;out portc, result
	cpi result, BUT1PRESSED
	brne main_mode_check
	ldl open, 1
	
main_mode_check:
	;out portc, result
	mov temp1, mode
	cpi temp1, 0	
	brne main_next1
	rcall entry_mode
	jmp mainloop
main_next1:
	cpi temp1, 1
	brne main_next2
	rcall running_mode
	jmp mainloop
main_next2:
	cpi temp1, 2
	brne main_next3
	rcall pause_mode
	jmp mainloop
main_next3:
	rcall finish_mode
	jmp mainloop

.include "entry.asm"
.include "running.asm"
.include "pause.asm"
.include "finish.asm"

.include "tools_f.asm"
.include "lcd_f.asm"
