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
	// Increment square counter to keep track of where we are in generation
	incf	Square_counter, F, A

	// Check if we need to swap to high if we're low
	movf	Square_duty_cycle, W
	cpfslt	Square_counter, A
	movff	Square_high, LATJ
	movf	Square_duty_cycle, W
	cpfslt	Square_counter, A
	
	// Check if we need to swap to low if we're high
	movlw	0x1
	cpfsgt	Square_counter, A
	movff	Square_low, LATJ
	

	return

Square_Setup:
	// Default duty cycle as 50%
	movlw	128
	movwf	Square_duty_cycle, A
	// Max volume
	movlw	0xFF
	movwf	Square_high, A
	// Zero minimum
	movlw	0x00
	movwf	Square_low, A
	// Begin low
	movff	Square_low, LATJ
	return
	
	end


