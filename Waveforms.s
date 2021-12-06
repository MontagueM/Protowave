#include <xc.inc>
	
global	Do_Sawtooth, Do_Square, Sawtooth_Setup, Square_Setup, Square_duty_cycle
extrn	ADC_Read, ADC_Setup, ADC_Close
psect	udata_acs   ; named variables in access ram
Square_counter: ds 1
Square_high:	ds 1
Square_low:	ds 1
Square_duty_cycle: ds 1

psect data
    
psect	wave_code, class=CODE

Do_Sawtooth:
	incf	LATJ, F, A
	return
	
Sawtooth_Setup:
	clrf	LATJ, A
	return
	
Do_Square:
	;call	ADC_Setup
	call	ADC_Read
	;call	ADC_Close
    
	incf	Square_counter, F, A
	movf	Square_duty_cycle, 0
	cpfslt	Square_counter, A
	movff	Square_high, LATJ
	movlw	0x1
	cpfsgt	Square_counter, A
	movff	Square_low, LATJ
	return

Square_Setup:
	movlw	128
	movwf	Square_duty_cycle, A
	movlw	0xFF
	movwf	Square_high, A
	movlw	0x0
	movwf	Square_low, A
	movff	Square_low, LATJ
	return
	
	end


