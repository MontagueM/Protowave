#include <xc.inc>

extrn	DAC_Setup, DAC_Int_Hi
extrn	LCD_Setup, LCD_Write_Message, LCD_Send_Byte_I
extrn	KB_Setup, KB_main
extrn	ADC_Setup

psect	code, abs
rst:	org	0x0000	; reset vector
	
	goto	init

int_hi:	org	0x0008	; high vector, no low vector
	goto	DAC_Int_Hi

init:
    	call	DAC_Setup
	call	ADC_Setup
	call	KB_Setup
	;call	LCD_Setup
start:	
	call	KB_main
	;call	LCD_main
	;goto	$	; Sit in infinite loop
	goto	start
	end	rst