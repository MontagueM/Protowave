#include <xc.inc>

extrn	DAC_Setup, DAC_Int_Hi
extrn	LCD_Setup, LCD_Write_Message, LCD_Send_Byte_I
extrn	KB_Setup

psect	code, abs
rst:	org	0x0000	; reset vector
	
	goto	start

int_hi:	org	0x0008	; high vector, no low vector
	goto	DAC_Int_Hi
	
start:	;call	DAC_Setup
	call	KB_Setup
	;goto	$	; Sit in infinite loop
	goto	start
	end	rst