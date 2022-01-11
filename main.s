#include <xc.inc>

extrn	DAC_Setup, DAC_Interrupt_High
extrn	LCD_Setup, LCD_Main
extrn	KB_Setup, KB_Main
extrn	ADC_Setup
    
psect	code, abs
rst:	org	0x0000		    ; reset vector
	
	goto	Init

int_hi:	org	0x0008		    ; high vector, no low vector
	goto	DAC_Interrupt_High

Init:
    	call	DAC_Setup
	call	ADC_Setup
	call	LCD_Setup
	call	KB_Setup

Start:	
	call	KB_Main
	call	LCD_Main
	goto	Start
	end	rst