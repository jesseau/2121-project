.include "m2560def.inc"

.set tnp = 64 ; tnp stands for total number of patterns
.def temp = r16
.def pat = r18
.def nump = r19
.def scnt = r20
.def i = r2
.def npat = r22
.def but0 = r23
.def but1 = r24
.def mask = r25
.def but0st = r26
.def but1st = r27
.def npats = r17
.def btime = r3

.macro debounce
ldi mask, @2
and mask, temp
cpi mask, 0
brne else
subi @0, 1 
rjmp cont
else:
subi @0, -1

cont:
cpi @0, 1
brge off
ldi @0, 40
ldi @1, 1
rjmp mend

off:
cpi @0, 80
brlt mend
ldi @0, 40
ldi @1, 0

mend:
.endmacro

.dseg
tcnt: .byte 2
rate: .byte 2
patterns: .byte tnp

.cseg
.org 0x0000
jmp RESET
jmp DEFAULT
jmp DEFAULT

.org OVF0addr
jmp Timer0OVF

DEFAULT: reti

RESET:
ldi temp, HIGH(RAMEND)
out SPH, temp
ldi temp, LOW(RAMEND)
out SPL, temp

clr temp
out DDRB, temp
ser temp
out PORTB, temp

out DDRC, temp
clr temp
out PORTC, temp
rjmp main

Timer0OVF:
in temp, SREG
push temp
;set the speed with which the patterns are displayed
cpi nump, 5
brlt normspeed
ldi temp, LOW(500)
sts rate, temp
ldi temp, HIGH(500)
sts rate+1, temp
rjmp polling

normspeed:
ldi temp, LOW(1000)
sts rate, temp
ldi temp, HIGH(1000)
sts rate+1, temp

polling:
in temp, PINB
debounce but0, but0st, 1
debounce but1, but1st, 2

inc btime
ldi temp, 80
cp btime, temp
brne timer
clr btime

cpi but0st, 1
brne but1only
cpi but1st, 1
brne but0only
clr npat
clr nump
clr pat
clr scnt
clr npats
clr btime
sts patterns, npat
ldi temp, 0b11000011
out PORTC, temp

but0only:
lsl npat
inc npats
;out PORTC, npat
rjmp addnpat

but1only:
cpi but1st, 1
brne addnpat
lsl npat
ldi temp, 1
add npat, temp
;out PORTC, npat
inc npats

addnpat:
cpi npats, 8
brne timer
ldi YL, LOW(patterns)
ldi YH, HIGH(patterns)
clr temp
add YL, nump
adc YH, temp
st Y, npat
cpi nump, tnp
breq skipinc
inc nump
skipinc:
clr npat
clr npats

;display the pattern/change to a new pattern
timer:
lds r30, tcnt
lds r31, tcnt+1
adiw r31:r30, 1
lds temp, rate
cp r30, temp
lds temp, rate+1
cpc r31, temp
brlt epilogue 

clr r30
clr r31

bst scnt, 0
inc scnt
brbc 6, empty
out PORTC, pat
rjmp newpattern
empty:
clr temp
out PORTC, nump

newpattern:
cpi scnt, 7
brne epilogue
clr scnt
ldi YH, HIGH(patterns)
ldi YL, LOW(patterns)
ld pat, Y

clr i
loop:
cp i, nump
breq preepilogue
ldd temp, Y+1
st Y+, temp
inc i
rjmp loop

preepilogue:
clr temp
cp nump, temp
breq nopatterns
dec nump
rjmp epilogue
nopatterns:
ldi scnt, 6

epilogue:
sts tcnt, r30
sts tcnt+1, r31
pop temp
out SREG, temp
reti

main:
;initialise the variables for polling
ldi but0, 40
ldi but1, 40
clr but0st
clr but1st
clr nump
clr scnt
clr npats
clr npat
ldi pat, 0b10101010
sts patterns, npat


clock:
;initialise the clock
ldi temp, 0b00000000
out TCCR0A, temp 
ldi temp, 0b00000011
out TCCR0B, temp
ldi temp, 1<<TOIE0
sts TIMSK0, temp
sei

mloop: rjmp mloop

