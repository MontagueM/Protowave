#include <xc.inc>
	
global		Do_Sawtooth, Do_Square, Sawtooth_Setup, Square_Setup, square_duty_cycle

psect		    udata_acs
square_counter:	    ds 1
square_high:	    ds 1
square_low:	    ds 1
square_duty_cycle:  ds 1

psect	wave_code, class=CODE

Do_Sawtooth:
	incf	LATJ, F, A
	return
	
Sawtooth_Setup:
	clrf	LATJ, A
	return
	
Do_Square:
	// Increment square counter to keep track of where we are in generation
	incf	square_counter, F, A

	// Check if we need to swap to high if we're low
	movf	square_duty_cycle, W
	cpfslt	square_counter, A
	movff	square_high, LATJ
	movf	square_duty_cycle, W
	cpfslt	square_counter, A
	
	// Check if we need to swap to low if we're high
	movlw	0x1
	cpfsgt	square_counter, A
	movff	square_low, LATJ
	

	return

Square_Setup:
	// Default duty cycle as 50%
	movlw	128
	movwf	square_duty_cycle, A
	// Max volume
	movlw	0xFF
	movwf	square_high, A
	// Zero minimum
	movlw	0x00
	movwf	square_low, A
	// Begin low
	movff	square_low, LATJ
	return
	
	end


