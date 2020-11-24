;
; CS1022 Introduction to Computing II 2018/2019
; Magic Square
;

	AREA	RESET, CODE, READONLY
	ENTRY

	; initialize system stack pointer (SP)
	LDR	SP, =0x40010000

	LDR	R0, =arr3	;loads test array parameters
	LDR	R4, =size3
	LDR	R1, [R4]

	BL isMagicSquare
	PUSH  {R0} 		;stores result 
	
	

	LDR	R0, =arr2	;loads test array parameters
	LDR	R4, =size2
	LDR	R1, [R4]
	
	BL isMagicSquare
	PUSH {R0}  		;stores result 
		
	
			
	LDR	R0, =arr1	;loads test array parameters
	LDR	R4, =size1
	LDR	R1, [R4]
	
	BL isMagicSquare
	PUSH  {R0}  		;stores result 
	
	
	
	LDR	R0, =arr0	;loads test array parameters
	LDR	R4, =size0
	LDR	R1, [R4]
	
	BL isMagicSquare
	PUSH  {R0}  		;stores result 
		
		
	
	LDR	R0, =arr4	;loads test array parameters
	LDR	R4, =size4
	LDR	R1, [R4]
	
	BL isMagicSquare
	MOV R4, R0		; moves result to corresponding number register
	
	
	POP {R0-R3}		;gets stored results and puts them in corresponding numbered registers

stop	B	stop

;isMagicSquare
;	determines whether an nxn square array is a Magic square
;	by checking to see that all the rows, columns, and diagonals
;	have the same sum
; parameters:
;	RO: array
;	R1: size
; return
;	R0: boolean
isMagicSquare
	PUSH {R4-R6, lr}

	CMP R1, #1			;checks to see whether the matrix is a 1x1
	BNE notOneByOne		;and branches to end and returns true if it is
	MOV R0, #1
	B endMagic
	
notOneByOne
	
	MOV R4, R0			;saves size and address in other registers to save the values
	MOV R5, R1
	
	BL isDiagonalEqual	; calls to check diagonals
	CMP R0, #0			; branches to end if false
	BEQ endMagic
	
	MOV R6, R1			; saves value of matchingSum
	
	MOV R0, R4			;resets the values of address and size to call next subroutine
	MOV R1, R5
	
	
	BL isHorizontalEqual
	CMP R0, #0			; branches to end if rows are not equal
	BEQ endMagic
	
	CMP R6, R1			;compares the matching sums and branches to end and returns false
	BNE noMagic			;if they don't match
	
	MOV R0, R4			;resets the address and size to be able to call next subroutine
	MOV R1, R5
	
	
	BL isColumnEqual
	CMP R0, #0			;branches to end if cols are not equal
	BEQ endMagic
	
	CMP R6, R1			; returns false if matching sum for rows doesn't match otger matching sum
	BNE noMagic
	
	B endMagic
	
noMagic
	MOV R0, #0

endMagic
	
	POP {R4-R6, pc}
	


;isHorizontalEqual
;	Checks the sums of each row to see whether they 
;	are all equal
; parameters:
;	RO: array
;	R1: size
; return
;	R0: boolean
;	R1: matchingSum(or -1 if false)
	
isHorizontalEqual
	PUSH {R4-R8, lr}
	MOV R7, #0			;track current col
	
nextRow	

	ADD R7, R7, #1		;increment col
	MOV R5, #0

	SUB R4, R1, #2
	LDMIA R0!, {R5-R6}	;add first two in row and add to currentTotal
	ADD R5, R5, R6
	
forSummingRow
	CMP R4, #0			;if finished with row checks results
	BLS checkRow
	
	LDMIA R0!, {R6}		;continues to increment address and add value to 
	ADD R5, R5, R6		;the currentTotal
	
	SUB R4, R4, #1		; decrement col
	
	B forSummingRow

checkRow
	
	CMP R7, #1			;if it is the first row stores sum in register 
	BNE compareRow		;and continues to next row
	MOV R8, R5
	B nextRow
	
compareRow
	CMP R5, R8			;compares the first row's sum with the currentSum
	BNE horizontalUnequal;will either branch out if false or continue if there
						;are rows left to check
	CMP R7, R1
	BEQ horizontalEqual
	
	B nextRow
	
horizontalUnequal		; returns false
	MOV R0, #0
	MOV R1, #-1
	B endHorizontal

horizontalEqual			;returns true and the matchingSum
	MOV R0, #1
	MOV R1, R8
	
endHorizontal	
	POP {R4-R8, pc}



;isColumnEqual
;	determines whether all of the columns in a 
;	square matrix have equal sums
; parameters:
;	RO: array address
;	R1: size
; return
;	R0: boolean	(true or false)
;	R1: matchingSum(or -1 if false)	
isColumnEqual
	PUSH {R4-R8, lr}
	
	MOV R4, #0				;set current col
nextCol

	MOV R5, #0				;set current row
	MOV R7, #0				;reset currentTotal
	
sumCurrentCol
	MUL R6, R5, R1			;	row = row * rowSize
	ADD R6, R6, R4			;	col = col * colSize
	LDR R6, [R0, R6, LSL #2]; element = [row][col]	
	
	ADD R7, R7, R6			; increment row
	
	ADD R5, R5, #1			; add element to currentTotal
	CMP R5, R1
	BLO sumCurrentCol		; check if done
	
	ADD R4, R4, #1			; increment col
	
	CMP R4, #1				; check if done
	BNE compareColSums
	
	MOV R8, R7				; set sum in register to be able to compare
	B nextCol
	
compareColSums
	CMP R7, R8				;compare sums
	BNE unequalCol
	
	CMP R4, R1				;if not done go back to loop
	BLO nextCol
	
	MOV R0, #1				; set true if finished and move sum
	MOV R1, R8
	B endCol
	
unequalCol					; set false if two columns didn't match
	MOV R0, #0
	MOV R1, #-1

endCol

	POP {R4-R8, pc}
	
	
;isDiagonalEqual
	;determines whether the diagonals of a square 
	;matrix have the same sum
; parameters:
;	RO: array address
;	R1: size of arrray (size is n in an n by n)
; return
;	R0: boolean (true or false)
;	R1: matchingSum (if r0 is true store the sum found)	
isDiagonalEqual
	PUSH {R4-R10, lr}
	
	MOV R9, #0		; hold firstDiagonal Sum
	MOV R10, #0		; hold secondDiagonal Sum
	
	MOV R5, #0		; hold index of row/column of right to left diagonal
	MOV R6, R1		; hold index of column of right to left diagonal
	
	
nextIndex	
	SUB R6, R6, #1			;	adjust to current row
	MUL R8, R5, R1			;	row = row * rowSize
	
	ADD R7, R8, R5			;	col = col * colSize
	LDR R7, [R0, R7, LSL #2]; element = [row][col]
	ADD R9, R9, R7			; adds to first Diagonal sum
	
	ADD R8, R8, R6			;	col = col * colSize
	LDR R8, [R0, R8, LSL #2]; element = [row][col]
	ADD R10, R10, R8		; adds to second Diagonal sum
	
	ADD R5, R5, #1			; move to next row
	CMP R5, R1				; check bounds 
	BLO nextIndex
	
	CMP R9, R10
	BNE unequalDiagonal
	
	MOV R0, #1				;if sums are equal return true and 
	MOV R1, R10				;store sum 
	
	B endDiagonal
	
unequalDiagonal
	MOV R0, #0				;unequal sums set result to false
	MOV R1, #-1
	
endDiagonal
	POP {R4-R10, pc}	
	
	

size0	DCD	3			; a 3x3 array(magic)
arr0	DCD	2,7,6		; the array
		DCD	9,5,1
		DCD	4,3,8
			
size1	DCD	4			; a 4x4 array(magic)
arr1	DCD	1,1,1,1		; the array
		DCD	1,1,1,1
		DCD	1,1,1,1
		DCD 1,1,1,1
		
			
size2	DCD	1		; a 1x1 array
arr2	DCD	9		; the array

			
size3	DCD	2		; a 2x2 array(no Magic)
arr3	DCD	4,4		; the array
		DCD	5,5
		
		
size4	DCD	3		; a 3x3 array(no Magic)
arr4	DCD	2,7,6	; the array
		DCD	10,5,1
		DCD	4,3,8


	END
