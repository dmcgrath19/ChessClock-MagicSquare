;
; CS1022 Introduction to Computing II 2018/2019
; Chess Clock
;

T0IR		EQU	0xE0004000
T0TCR		EQU	0xE0004004
T0TC		EQU	0xE0004008	;holds current time
T0MR0		EQU	0xE0004018
T0MCR		EQU	0xE0004014

PINSEL4		EQU	0xE002C010

FIO2DIR1	EQU	0x3FFFC041
FIO2PIN1	EQU	0x3FFFC055

EXTINT		EQU	0xE01FC140
EXTMODE		EQU	0xE01FC148
EXTPOLAR	EQU	0xE01FC14C

VICIntSelect	EQU	0xFFFFF00C
VICIntEnable	EQU	0xFFFFF010
VICVectAddr0	EQU	0xFFFFF100
VICVectPri0	EQU	0xFFFFF200
VICVectAddr	EQU	0xFFFFFF00

VICVectT0	EQU	4
VICVectEINT0	EQU	14

Irq_Stack_Size	EQU	0x80

Mode_USR        EQU     0x10
Mode_IRQ        EQU     0x12
I_Bit           EQU     0x80            ; when I bit is set, IRQ is disabled
F_Bit           EQU     0x40            ; when F bit is set, FIQ is disabled
	
clockOne		EQU		0x40000004		; address for last bit of clock one
clockTwo		EQU		0x4000000C		; address for last bit of clock two
currentTimer	EQU		0x40000012		; address for tracking current clock


	AREA	RESET, CODE, READONLY
	ENTRY

	; Exception Vectors

	B	Reset_Handler	; 0x00000000
	B	Undef_Handler	; 0x00000004
	B	SWI_Handler	; 0x00000008
	B	PAbt_Handler	; 0x0000000C
	B	DAbt_Handler	; 0x00000010
	NOP			; 0x00000014
	B	IRQ_Handler	; 0x00000018
	B	FIQ_Handler	; 0x0000001C

;
; Reset Exception Handler
;
Reset_Handler

	;
	; Initialize Stack Pointers (SP) for each mode we are using
	;

	; Stack Top
	LDR	R0, =0x40010000

	; Enter irq mode and set initial SP
	MSR     CPSR_c, #Mode_IRQ:OR:I_Bit:OR:F_Bit
	MOV     SP, R0
	SUB     R0, R0, #Irq_Stack_Size

	; Enter user mode and set initial SP
	MSR     CPSR_c, #Mode_USR
	MOV	SP, R0

	
	;load registers with ascii values 
	MOV R7, #0x32	; '2'
	MOV R6, #0x30	; '0'
	MOV R8, #0x3A	; ':'
	
	
	;set Clock One in memory -- bit by bit 
	;from right to left
	LDR	R4, =clockOne
	STRB R6, [R4], #-1
	STRB R6, [R4], #-1
	STRB R8, [R4], #-1
	STRB R6, [R4], #-1
	STRB R7, [R4]
	
	;set Clock Two in memory -- bit by bit 
	;from right to left 
	LDR	R4, =clockTwo
	STRB R6, [R4], #-1
	STRB R6, [R4], #-1
	STRB R8, [R4], #-1
	STRB R6, [R4], #-1
	STRB R7, [R4]
	
	;set the currentTimer to clock two so when the 
	;button is first pressed it will start on clock two
	;clock two is 0x00, while clock one is 0x01
	MOV R7, #0x00
	LDR R5, =currentTimer
	STRB R7, [R5]
	
	;Configure Timer0 // slightly modified from timer-int example
	
	; Stop and reset TIMER0 using Timer Control Register
	; Set bit 0 of TCR to 0 to stop TIMER
	; Set bit 1 of TCR to 1 to reset TIMER
	LDR	R5, =T0TCR
	LDR	R6, =0x2
	STRB	R6, [R5]

	; Clear any previous TIMER0 interrupt by writing 0xFF to the TIMER0
	; Interrupt Register (T0IR)
	LDR	R5, =T0IR
	LDR	R6, =0xFF
	STRB	R6, [R5]

	; Set match register for 1 sec using Match Register
	; Assuming a 1Mhz clock input to TIMER0, set MR
	; MR0 (0xE0004018) to 1,000,000
	LDR	R4, =T0MR0
	LDR	R5, =1000000
	STR	R5, [R4]

	; IRQ on match using Match Control Register
	; Set bit 0 of MCR to 1 to turn on interrupts
	; Set bit 1 of MCR to 1 to reset counter to 0 after every match
	; Set bit 2 of MCR to 0 to leave the counter enabled after match
	LDR	R4, =T0MCR
	LDR	R5, =0x03
	STRH	R5, [R4]

	;
	; Configure VIC for TIMER0 interrupts // from timer-int example
	;

	; Useful VIC vector numbers and masks for following code
	LDR	R3, =VICVectT0		 ; vector 4
	LDR	R4, =(1 << VICVectT0); bit mask for vector 4

	; VICIntSelect - Clear bit 4 of VICIntSelect register to cause
	; channel 4 (TIMER0) to raise IRQs (not FIQs)
	LDR	R5, =VICIntSelect	; addr = VICVectSelect;
	LDR	R6, [R5]			; tmp = Memory.Word(addr);
	BIC	R6, R6, R4			; Clear bit for Vector 0x04
	STR	R6, [R5]			; Memory.Word(addr) = tmp;

	; Set Priority for VIC channel 4 (TIMER0) to lowest (15) by setting
	; VICVectPri4 to 15. Note: VICVectPri4 is the element at index 4 of an
	; array of 4-byte values that starts at VICVectPri0.
	; i.e. VICVectPri4=VICVectPri0+(4*4)
	LDR	R5, =VICVectPri0	; addr = VICVectPri0;
	MOV	R6, #15				; pri = 15;
	STR	R6, [R5, R3, LSL #2]; Memory.Word(addr + vector * 4) = pri;

	; Set Handler routine address for VIC channel 4 (TIMER0) to address of
	; our handler routine (TimerHandler). Note: VICVectAddr4 is the element
	; at index 4 of an array of 4-byte values that starts at VICVectAddr0.
	; i.e. VICVectAddr4=VICVectAddr0+(4*4)
	LDR	R5, =VICVectAddr0	; addr = VICVectAddr0;
	LDR	R6, =Timer_Handler	; handler = address of TimerHandler;
	STR	R6, [R5, R3, LSL #2]; Memory.Word(addr + vector * 4) = handler

	; Enable VIC channel 4 (TIMER0) by writing a 1 to bit 4 of VICIntEnable
	LDR	R5, =VICIntEnable	; addr = VICIntEnable;
	STR	R4, [R5]			; enable interrupts for vector 0x4




	;
	; Configure P2.10 for EINT0 // from button-int example
	;

	; Enable P2.10 for GPIO
	LDR	R4, =PINSEL4
	LDR	R5, [R4]			; read current value
	BIC	R5, #(0x03 << 20)	; clear bits 21:20
	ORR	R5, #(0x01 << 20)	; set bits 21:20 to 01
	STR	R5, [R4]			; write new value

	; Set edge-sensitive mode for EINT0
	LDR	R4, =EXTMODE
	LDR	R5, [R4]			; read
	ORR	R5, #1				; modify
	STRB	R5, [R4]		; write

	; Set rising-edge mode for EINT0
	LDR	R4, =EXTPOLAR
	LDR	R5, [R4]			; read
	BIC	R5, #1				; modify
	STRB	R5, [R4]		; write

	; Reset EINT0
	LDR	R4, =EXTINT
	MOV	R5, #1
	STRB	R5, [R4]

	;
	; Configure VIC for EINT0 interrupts // from button-int example
	;

	; Useful VIC vector numbers and masks for following code
	LDR	R4, =VICVectEINT0		; vector 4
	LDR	R5, =(1 << VICVectEINT0); bit mask for vector 14

	; VICIntSelect - Clear bit 4 of VICIntSelect register to cause
	; channel 14 (EINT0) to raise IRQs (not FIQs)
	LDR	R6, =VICIntSelect		; addr = VICVectSelect;
	LDR	R7, [R6]				; tmp = Memory.Word(addr);
	BIC	R7, R7, R5				; Clear bit for Vector 14
	STR	R7, [R6]				; Memory.Word(addr) = tmp;

	; Set Priority for VIC channel 14 (EINT0) to lowest (15) by setting
	; VICVectPri4 to 15. Note: VICVectPri4 is the element at index 14 of an
	; array of 4-byte values that starts at VICVectPri0.
	; i.e. VICVectPri4=VICVectPri0+(4*4)
	LDR	R6, =VICVectPri0		; addr = VICVectPri0;
	MOV	R7, #15					; pri = 15;
	STR	R7, [R6, R4, LSL #2]	; Memory.Word(addr + vector * 4) = pri;

	; Set Handler routine address for VIC channel 4 (TIMER0) to address of
	; our handler routine (TimerHandler). Note: VICVectAddr4 is the element
	; at index 4 of an array of 4-byte values that starts at VICVectAddr0.
	; i.e. VICVectAddr4=VICVectAddr0+(4*4)
	LDR	R6, =VICVectAddr0		; addr = VICVectAddr0;
	LDR	R7, =Button_Handler		; handler = address of TimerHandler;
	MOV R8, R7
	STR	R7, [R6, R4, LSL #2]	; Memory.Word(addr + vector * 4) = handler
	
	; Enable VIC channel 14 (EINT0) by writing a 1 to bit 4 of VICIntEnable
	LDR	R6, =VICIntEnable		; addr = VICIntEnable;
	STR	R5, [R6]				; enable interrupts for vector 14

stop	B	stop


;
; TOP LEVEL EXCEPTION HANDLERS
;

;
; Software Interrupt Exception Handler
;
Undef_Handler
	B	Undef_Handler

;
; Software Interrupt Exception Handler
;
SWI_Handler
	B	SWI_Handler

;
; Prefetch Abort Exception Handler
;
PAbt_Handler
	B	PAbt_Handler

;
; Data Abort Exception Handler
;
DAbt_Handler
	B	DAbt_Handler

;
; Interrupt ReQuest (IRQ) Exception Handler (top level - all devices)
;
IRQ_Handler
	SUB	lr, lr, #4	; for IRQs, LR is always 4 more than the
				; real return address
	STMFD	sp!, {r0-r3,lr}	; save r0-r3 and lr

	LDR	r0, =VICVectAddr; address of VIC Vector Address memory-
				; mapped register

	MOV	lr, pc		; can’t use BL here because we are branching
	LDR	pc, [r0]	; to a different subroutine dependant on device
				; raising the IRQ - this is a manual BL !!

	LDMFD	sp!, {r0-r3, pc}^ ; restore r0-r3, lr and CPSR

;
; Fast Interrupt reQuest Exception Handler
;
FIQ_Handler
	B	FIQ_Handler


;
; write your interrupt handlers here
;
Timer_Handler

	STMFD	sp!, {r4-r5, lr}

	; Reset TIMER0 interrupt by writing 0xFF to T0IR
	LDR	R4, =T0IR
	MOV	R5, #0xFF
	STRB	R5, [R4]
	
	; Stop and reset TIMER0 using Timer Control Register
	; Set bit 0 of TCR to 0 to stop TIMER
	; Set bit 1 of TCR to 1 to reset TIMER
	LDR	R5, =T0TCR
	LDR	R6, =0x2
	STRB	R6, [R5]

	; create a register that keeps track of current bit number
	MOV R10, #0
	
	; load the value from address of currentTimer and use that 
	; value to load in the correct address to r4, which will
	; hold the current address value 
	LDR R5, =currentTimer
	LDRB R5, [R5]
	CMP R5, #1
	BNE otherTimer
	
	LDR R4, =clockOne
	B compareCurrentDigit

otherTimer
	LDR R4, =clockTwo
	
compareCurrentDigit
	
	;adjust to current bit number and check to make sure
	;it is still in the clock's bit range
	ADD R10, R10, #1
	CMP R10, #5
	BHI doneWithTimer
	
	
	
	LDRB R5, [R4]		;load in current digit from the current bit number
	CMP R5, #0x3A		;check to make sure it's a number not the colon
	BEQ nextDigit
	CMP R5, #0x30		;if the current digit is not zero branch 
	BNE subtractSecond
	
	CMP R10, #5
	BHI doneWithTimer	;if it's zero at the very left the timer has run out so end loop
	
	MOV R7, R4			; stores a second location for current address to be able to manipulate
	MOV R8, R10			; second location for bit to be able to manipulate
isEnoughTime			; checks to see if there is time left to count down from
	ADD R8, R8, #1		
	CMP R8, #5			; if it goes beyond bounds of timer, there is no time
	BHI doneWithTimer
	
	LDRB R6, [R7, #-1]!	; updates the current address of preceding bit
	
	CMP R8, #3			; skips the colon
	BEQ isEnoughTime
	
	CMP R6, #0x30		; if it reaches a number not 0 it exits the loop
	BEQ isEnoughTime

	CMP R10, #2
	BNE changeMinute
	MOV R5, #0x35		;make sure the tens place goes to 5 (59 seconds not 99)
	B adjustDigit
	
changeMinute	
	MOV R5, #0x39		;for digits 1 and 3 (left to right) set to 9 
	
adjustDigit
	STRB R5, [R4]		;store value back in current bit address

nextDigit
	SUB R4, R4, #1		;adjust bit address to get next bit
	
	B compareCurrentDigit
	

subtractSecond
	SUB R5, R5, #1		; for value 1-9 just subtract one from current value and 
	STRB R5, [R4]		; store them in current address
	
doneWithTimer


	; Clear source of interrupt by writing 0 to VICVectAddr
	LDR	R4, =VICVectAddr
	MOV	R5, #0
	STR	R5, [R4]
	
	;start the timer
	LDR	R4, =T0TCR
	LDR	R5, =0x01
	STRB	R5, [R4]

	LDMFD	sp!, {r4-r5, pc}
	
	
Button_Handler

	STMFD	sp!, {r4-r7, lr}
	
	; Reset EINT0 interrupt by writing 1 to EXTINT register
	LDR	R4, =EXTINT
	MOV	R5, #1
	STRB	R5, [R4]
	
	; Stop and reset TIMER0 using Timer Control Register
	; Set bit 0 of TCR to 0 to stop TIMER
	; Set bit 1 of TCR to 1 to reset TIMER
	LDR	R5, =T0TCR
	LDR	R6, =0x2
	STRB	R6, [R5]
	
	LDR R5, =currentTimer	;load value in of current clock
	LDRB R6, [R5]
	EOR R6, R6, #0x01		;switches clock to other clock
	
	STRB R6, [R5]			;stores other clock in currentTimer
	
	
	
	;start the timer
	LDR	R4, =T0TCR
	LDR	R5, =0x01
	STRB	R5, [R4]

	;
	; Clear source of interrupt
	;
	LDR	R4, =VICVectAddr	; addr = VICVectAddr
	MOV	R5, #0			; tmp = 0;
	STR	R5, [R4]		; Memory.Word(addr) = tmp;

	LDMFD	sp!, {r4-r7, pc}


	END
