#include <xc.inc>

global  ADC_Setup, ADC_Read, ADC_Close
extrn	Square_duty_cycle
psect	adc_code, class=CODE
    
ADC_Setup:
	bsf	TRISA, PORTA_RA0_POSN, A  ; pin RA0==AN0 input
	movlb	0x0f
	bsf	ANSEL0	    ; set AN0 to analog
	movlb	0x00
	movlw   0x01	    ; select AN0 for measurement
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x30	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0x76	    ; Left justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	

	return

ADC_Close:
	movlw   0x00	    ; select AN0 for measurement
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x0	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0x0	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	return
	
ADC_Read:
	btfsc   GO	    ; check to see if finished
	return
	;read new values of address
	    	
	;swapf	ADRESL, 1
	;movlw	0x0F
	;andwf	ADRESL, 1
	;swapf	ADRESH, 1
	movf	ADRESH, 0
	;addwf	ADRESL, 0
	movwf	Square_duty_cycle, A
	bsf	GO
	return

end