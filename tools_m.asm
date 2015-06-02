.macro pushall
push r0
push r1
push r2
push r3
push r4
push r5
push r6
push r7
push r8
push r8
push r10
push r11
push r12
push r13
push r14
push r15
push r16
push r17
push r18
push r19
push r20
push r21
push r22
push r23
push r24
push r25
push r26
push r27
push r28
push r29
push r30
push r31
in r16, SREG
push r16
.endmacro

.macro popall
pop r16
out SREG, r16
pop r31
pop r30
pop r29
pop r28
pop r27
pop r26
pop r25
pop r24
pop r23
pop r22
pop r21
pop r20
pop r19
pop r18
pop r17
pop r16
pop r15
pop r14
pop r13
pop r12
pop r11
pop r10
pop r8
pop r8
pop r7
pop r6
pop r5
pop r4
pop r3
pop r2
pop r1
pop r0
.endmacro

.macro divide
	clr @2
tools_loop:
	cp @0, @1
	brlo tools_result
	sub @0, @1
	inc @2
	rjmp loop
tools_result:
	mov @1, @0
	mov @0, @2
.endmacro

; load immediate to low registers, i.e. r0-r15 so that they're actually usable
.macro ldl
	push temp1
	ldi temp1, @1
	mov @0, temp1
	pop temp1
.endmacro

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead
