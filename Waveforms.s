#include <xc.inc>
	
global	Do_Sawtooth, Do_Square, Sawtooth_Setup, Square_Setup
    
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
	incf	Square_counter, F, A
	movf	Square_duty_cycle, 0
	cpfslt	Square_counter, A
	movff	Square_high, LATJ
	movlw	0x1
	cpfsgt	Square_counter, A
	movff	Square_low, LATJ
	return

Square_Setup:
	movlw	200
	movwf	Square_duty_cycle, A
	movlw	0xFF
	movwf	Square_high, A
	movlw	0x0
	movwf	Square_low, A
	movff	Square_low, LATJ
	return
	
	end


