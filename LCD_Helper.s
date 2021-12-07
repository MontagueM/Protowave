#include <xc.inc>
	
psect	udata_acs   ; named variables in access ram

psect data
 
 WaveformString:
    db	    'W','F',':'
    align   2
    
 SquareString:
    db	    'S','Q','U'
    align   2
 
 SawString:
    db	    'S','A','W'
    align   2
  
ScaleString:
    db	    'S','C',':'
    align   2
    
MinString:
    db	    'M','I','N'
    align   2
    
MajString:
    db	    'M','A','J'
    align   2
    
    
psect	lcd_help_code, class=CODE
LCD_main:
	
	return
	
	end





