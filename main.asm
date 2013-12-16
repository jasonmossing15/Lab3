;-------------------------------------------------------------------------------
;   Template code given as a starting point for ECE382 Lab 3.
;   NOTE: This code uses UCB0!
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file

                     .data
LCDDATA:                                                            ; holder of four bits to send LCD
              .space  1
LCDSEND:                                                            ; holder of eight bits to send LCD
                     .space  1
LCDCON:                                                             ; LCD control bits upper byte: E=0x80, RS=0x40, WR=0x20
                     .space  1
RESULTS:		.space		50
;-------------------------------------------------------------------------------
            	.text                           ; Assemble into program memory
LineCount:		.equ	0x02
DELAY1:			.equ	0xa
DELAY2:			.equ	0x232
bounceDelay:	.equ	0xdfec
hashtag:		.equ	0x23
Key1:			.equ	0xcd
Key2:			.equ	0xef
Key3:			.equ	0xab
Counter:		.equ	0x00
NewLineCount:	.equ	0x08
ONE:			.equ	0x31		;1 in ASCII
TWO:			.equ	0x32		;2 in ASCII
THREE:			.equ	0x33		;3 in ASCII
Countdown:		.equ	0x13	;32 is 50 in deciaml
Message1:		.byte	0xff,0xc3,0xc2,0xd8,0x8b,0xc2,0xd8,0x8b,0xc6,0xce,0xd8,0xd8,0xca,0xcc,0xce,0x8b,0x9a,0x8a,0x88
Message2:		.byte	0x99,0xa5,0xa4,0xbe,0xed,0xa4,0xbe,0xed,0xa0,0xa8,0xbe,0xbe,0xac,0xaa,0xa8,0xed,0xff,0xec,0xee
Message3:		.byte	0xbb,0x87,0x86,0x9c,0xcf,0x86,0x9c,0xcf,0x82,0x8a,0x9c,0x9c,0x8e,0x88,0x8a,0xcf,0xdc,0xce,0xcc
MessageSCRN1:	.string		"Message?#"
NewLine:		.string		"................................#"
MessageSCRN2:	.string		"PRESS123#"
KeySCRN:		.string		"Key?    #"
ResultSCRN:		.string		"Msg: #"
MESSAGENEWLINE:	.string		"  ................................#"
KeyResult:		.string		"Key: #"
            	.retain                         ; Override ELF conditional linking
                                            ; and retain current section
            	.retainrefs                     ; Additionally retain any sections
                                            ; that have references to current
                                            ; section
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer

;-------------------------------------------------------------------------------
                                            ; Main loop here
;-------------------------------------------------------------------------------

main:
    	   	  	clr.b	&BCSCTL1								; clears the registers controlling the clock
       		  	clr.b	&DCOCTL
       		    mov.b	&CALBC1_1MHZ,&BCSCTL1					; calibrates the clk registers to 1 MHz
       	    	mov.b	&CALDCO_1MHZ,&DCOCTL
				mov.b   #BIT4, &P1DIR                            ; show SMCLK on P1.4
   	    	    mov.b   #BIT4, &P1SEL


                  ; call your SPI initialization subroutine - you must implement this!
                call    #INITSPI

                  ; LCD Initialization - you'll know it works when your LCD goes blank
                  ; relies on you implementing SET_SS_HI, SET_SS_LO, LCDDELAY1, LCDDELAY2
                call    #LCDINIT

                call    #LCDCLR

				call	#BTNINIT

				mov		#MessageSCRN1, r6		;Line1 for Message screen
				call	#MessageScreen
				mov		#NewLine, r6			;Sets a new line
				call	#MessageScreen
				mov		#MessageSCRN2, r6		;Line2 for Message Screen
				call	#MessageScreen

				call	#MessageBTN				;checks message button

				call	#ButtonDelay			; delay to get rid of bouncing

                call    #LCDCLR					;clears screen for key

				mov		#KeySCRN, r6			; sets first line for key screen
				call	#MessageScreen
				mov		#NewLine, r6			;sets a new line
				call	#MessageScreen
				mov		#MessageSCRN2, r6		;sets the second line for key screen
				call	#MessageScreen

				call	#KeyBTN					;checks key buttons

               call    #LCDCLR					;clears screen for results

				mov		#RESULTS, r4
				call	#decryptMessage			;decrypts the message

				call	#output					; outputs the results screen

forever:
                  jmp     forever

; Initializes the SPI subsytem.
;
INITSPI:

        bis.b #UCSWRST, &UCB0CTL1

        bis.b #UCCKPL|UCMSB|UCMST|UCSYNC, &UCB0CTL0     ; don't forget UCSYNC!

        bis.b #UCSSEL1, &UCB0CTL1                       ; select a clock to use!

        bis.b #UCLISTEN, UCB0STAT                      ; enables internal loopback

        bis.b #BIT5, &P1SEL                             ; make UCB0CLK available on P1.5
        bis.b #BIT5, &P1SEL2

        bis.b #BIT7, &P1SEL                             ; make UCB0SSIMO available on P1.7
        bis.b #BIT7, &P1SEL2

        bis.b #BIT6, &P1SEL                             ; make UCB0SSOMI available on P1.6
        bis.b #BIT6, &P1SEL2

        bis.b #BIT1, &P2DIR								;sets my GPIO for SS

        bic.b #UCSWRST, &UCB0CTL1                       ; enable subsystem


                  ret

; Sets your slave select to high (disabled)
;
SET_SS_HI:

                 bis.b #BIT1, &P2OUT ; your set SS high code goes here

                  ret

; Sets your slave select to low (enabled)
;
SET_SS_LO:

                 bic.b #BIT1, &P2OUT ; your set SS low code goes here

                  ret


; Implements a 40.5 microsecond delay
;
LCDDELAY1:

                     push   r5
                     mov.w  #DELAY1, r5
delaylp1:            dec           r5
                     jnz           delaylp1
                     pop           r5
                     ret


; Implements a 1.65 millisecond delay
;
LCDDELAY2:

                     push   r5
                     mov.w  #DELAY2, r5
delaylp2:            dec           r5
                     jnz           delaylp2
                     pop           r5
                     ret

ButtonDelay:

                     push   r5
                     mov.w  #bounceDelay, r5
delaylp3:            dec           r5
                     jnz           delaylp3
                     pop           r5
                     ret

;---------------------------------------------------
; Subroutine Name: LCDCLR
; Author: Capt Todd Branchflower, USAF
; Function: Clears LCD, sets cursor to home
; Inputs: none
; Outputs: none
; Registers destroyed: none
; Subroutines used: LCDWRT8, LCDDELAY1, LCDDELAY2
;---------------------------------------------------
LCDCLR:
                  mov.b   #0, &LCDCON                                             ; clear RS
                  mov.b   #1, &LCDSEND                                            ; send clear
                  call    #LCDWRT8
                  call    #LCDDELAY1
                  mov.b   #0x40, &LCDCON                                          ; set RS
                  call    #LCDDELAY2

                  ret

;---------------------------------------------------
; Subroutine Name: LCDINIT
; Author: Capt Todd Branchflower, USAF
; Function: Initializes the LCD on the Geek Box
; Inputs: none
; Outputs: none
; Registers destroyed: none
; Subroutines used: LCDWRT4, LCDWRT8, LCDDELAY1, LCDDELAY2
;---------------------------------------------------
LCDINIT:
                  call    #SET_SS_HI

                  mov.b   #0, &LCDCON                                             ; initialize control bits

                  mov.b   #0x03, &LCDDATA                                         ; function set
                  call    #LCDWRT4
                  call    #LCDDELAY2

                  mov.b   #0x03, &LCDDATA                                         ; function set
                  call    #LCDWRT4
                  call    #LCDDELAY1

                  mov.b   #0x03, &LCDDATA                                         ; function set
                  call    #LCDWRT4
                  call    #LCDDELAY1

                  mov.b   #0x02, &LCDDATA                                         ; set 4-bit interface
                  call    #LCDWRT4
                  call    #LCDDELAY1

                  mov.b   #0x28, &LCDSEND                                         ; 2 lines, 5x7
                  call    #LCDWRT8
                  call    #LCDDELAY2

                  mov.b   #0x0C, &LCDSEND                                         ; display on, cursor, blink off
                  call    #LCDWRT8
                  call    #LCDDELAY2

                  mov.b   #0x01, &LCDSEND                                         ; clear, cursor home
                  call    #LCDWRT8
                  call    #LCDDELAY1

                  mov.b   #0x06, &LCDSEND                                         ; cursor increment, shift off
                  call    #LCDWRT8
                  call    #LCDDELAY2

                  mov.b   #0x01, &LCDSEND                                         ; clear, cursor home
                  call    #LCDWRT8
                  call    #LCDDELAY2

                  mov.b   #0x02, &LCDSEND                                         ; cursor home
                  call    #LCDWRT8
                  call    #LCDDELAY2

                  mov.b   #0, r5                                                  ; clear register
                  call    #SPISEND
                  call    #LCDDELAY1

                  ret

;---------------------------------------------------
; Subroutine Name: LCDWRT8
; Author: Capt Todd Branchflower, USAF
; Function: Send full byte to LCD
; Inputs: LCDSEND
; Outputs: none
; Registers destroyed: none
; Subroutines used: LCDWRT4
;---------------------------------------------------
LCDWRT8:
                  push.w  r5

                  mov.b   &LCDSEND, r5                                            ; load full byte
                  and.b   #0xf0, r5                                               ; shift in four zeros on the left
                  rrc.b   r5
                  rrc.b   r5
                  rrc.b   r5
                  rrc.b   r5
                  mov.b   r5, &LCDDATA                                            ; store send data
                  call    #LCDWRT4                                                ; write upper nibble
                  mov.b   &LCDSEND, r5                                            ; load full byte
                  and.b   #0x0f, r5                                               ; clear upper nibble
                  mov.b   r5, &LCDDATA
                  call    #LCDWRT4                                                ; write lower nibble

                  pop.w   r5
                  ret

;---------------------------------------------------
; Subroutine Name: LCDWRT4
; Author: Capt Todd Branchflower, USAF
; Function: Send 4 bits of data to LCD via SPI.
; sets upper four bits to match LCDCON.
; Inputs: LCDCON, LCDDATA
; Outputs: none
; Registers destroyed: none
; Subroutines used: LCDDELAY1
;---------------------------------------------------
LCDWRT4:
                  push.w  r5

                  mov.b   &LCDDATA, r5                                            ; load data to send
                  and.b   #0x0f, r5                                               ; ensure upper half of byte is clear
                  bis.b   &LCDCON, r5                                             ; set LCD control nibble
                  and.b   #0x7f, r5                                               ; set E low
                  call    #SPISEND
                  call    #LCDDELAY1
                  bis.b   #0x80, r5                                               ; set E high
                  call    #SPISEND
                  call    #LCDDELAY1
                  and.b   #0x7f, r5                                               ; set E low
                  call    #SPISEND
                  call    #LCDDELAY1

                  pop.w   r5
                  ret

;---------------------------------------------------
; Subroutine Name: SPISEND
; Author: Capt Todd Branchflower, USAF
; Function: Sends contents of r5 to SPI.
; Waits for Rx flag, clears by reading.
; Sets slave select accordingly.
; Outputs: none
; Registers destroyed: none
; Subroutines used: LCDWRT8, LCDDELAY1, LCDDELAY2
;---------------------------------------------------
; Subroutine: SPISEND
;
; takes byte to send in r5
SPISEND:
                  push    r4
                  call    #SET_SS_LO
                  mov.b   r5, &UCB0TXBUF                                          ; transfer byte
wait:
                  bit.b   #UCB0RXIFG, &IFG2                                       ; wait for transfer completion
                  jz      wait
                  mov.b   &UCB0RXBUF, r4                                          ; read value to clear flag
                  call    #SET_SS_HI
                  pop     r4
                  ret


;-----------------------------------------------------
; Subroutine Name: MessageScreen
; Author: C2C Jason Mossing, USAF
; Function: Sends a string to the LCD
; Inputs: string (r6)
; Outputs: none
; Registers destroyed: none
; Subroutines used: LCDWRT8, LCDDELAY1
;-----------------------------------------------------
MessageScreen:
				push	r6
again			mov.b	@r6, &LCDSEND
				cmp.b	#hashtag, 0(r6)
				jeq		end
				call	#LCDWRT8
				call	#LCDDELAY1
				inc		r6
				jmp		again
end				pop		r6
				ret

;--------------------------------------------------------
; Subroutine Name: BTNINIT
; Author: C2C Jason Mossing, USAF
; Function: Initialize Buttons
; Inputs: none
; Outputs: none
; Registers destroyed: none
; Subroutines used: none
;---------------------------------------------------------
BTNINIT:
				bic.b	#BIT3, &P2DIR				;Button 1
				bis.b	#BIT3, &P2REN
				bis.b	#BIT3, &P2OUT

				bic.b	#BIT4, &P2DIR				;Button 2
				bis.b	#BIT4, &P2REN
				bis.b	#BIT4, &P2OUT

				bic.b	#BIT5, &P2DIR				;Button 3
				bis.b	#BIT5, &P2REN
				bis.b	#BIT5, &P2OUT

				ret
;--------------------------------------------------------
; Subroutine Name: MessageBTN
; Author: C2C Jason Mossing, USAF
; Function: polls for button press then determines
; which message was selected
; Inputs: none
; Outputs: r9 (Message selected), r13 (message number in ASCII)
; Registers destroyed: none
; Subroutines used: none
;---------------------------------------------------------
MessageBTN:
poll_button:
                    bit.b   #BIT3, &P2IN
                    jz		btn1
                    bit.b   #BIT4, &P2IN
                    jz		btn2
                    bit.b   #BIT5, &P2IN
                    jz		btn3
                    jnz     poll_button            ; buttons are active-low

btn1:				mov		#Message1, r9
					mov.b	#ONE,	r13
					ret

btn2:				mov		#Message2, r9
					mov.b	#TWO,	r13
					ret

btn3:				mov		#Message3, r9
					mov.b	#THREE,	r13
					ret

;--------------------------------------------------------
; Subroutine Name: KeyBTN
; Author: C2C Jason Mossing, USAF
; Function: polls for button press then determines
; which key was selected
; Inputs: none
; Outputs: r10 (Key selected), r14 (key number in ASCII)
; Registers destroyed: none
; Subroutines used: none
;---------------------------------------------------------
KeyBTN:
poll_button1:
                    bit.b   #BIT3, &P2IN
                    jz		kbtn1
                    bit.b   #BIT4, &P2IN
                    jz		kbtn2
                    bit.b   #BIT5, &P2IN
                    jz		kbtn3
                    jnz     poll_button1            ; buttons are active-low

kbtn1:				mov.b	#Key1, r10
					mov.b	#ONE,	r14
					ret

kbtn2:				mov.b	#Key2, r10
					mov.b	#TWO,	r14
					ret

kbtn3:				mov.b	#Key3, r10
					mov.b	#THREE,	r14
					ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	decryptMessage subroutine			;
;	inputs:								;
;	r9: reference to encrypted message	;
;	r10:key constant					;
;	output:								;
;	r4: reference to decrypted message	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
decryptMessage:
		mov		#Countdown, r11

begin	mov.b	@r9, r7
		mov.b	r10, r8
		call	#decryptByte
		mov.b	r8, 0(r4)
		dec		r11
		jeq		done
		inc		r4
		inc		r9
		jmp		begin

done	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	decryptByte subroutine				;
;	inputs:								;
;	r7: encrypted Byte					;
;	r8:	key constant					;
;	output:								;
;	r8: decrypted Byte					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
decryptByte:
		xor			r7, r8
		ret


;----------------------------------------------------
; Subroutine Name: output
; Author: C2C Jason Mossing, USAF
; Function: output the correct results screen
; the first commented section is for the required
; functionality and the uncommented does the
; scrolling message
; which key was selected
; Inputs: r13 & r14 for required, none for A function
; Outputs: none
; Registers destroyed: none
; Subroutines used: LCDCLR, MessageScreen, ButtonDelay
;-----------------------------------------------------
output:
;			mov		#ResultSCRN, r6		;Line1 for Results screen
;			call	#MessageScreen
;
;			mov.b	r13, &LCDSEND
;			call	#LCDWRT8
;			call	#LCDDELAY1
;
;			mov		#MESSAGENEWLINE, r6			;Sets a new line
;			call	#MessageScreen
;
;			mov		#KeyResult, r6		;Line2 for Results Screen
;			call	#MessageScreen
;
;			mov.b	r14, &LCDSEND
;			call	#LCDWRT8
;			call	#LCDDELAY1
;
startover	mov		#Counter,	r12
			mov		#Countdown, r11
			mov		#RESULTS, r6
			call	#LCDCLR

cont		call	#MessageScreen
			dec		r11
			tst		r11
			jz		startover			;if every character has been at the beginning of the screen then restart the message
			inc		r6
			call	#ButtonDelay		;do a button delay after every messgae send to slow down the scrolling
			call	#LCDCLR				; clear the LCD everytime to avoid extra characters on the screen
			jmp		cont


			ret
;-------------------------------------------------------------------------------
;           Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect    .stack

;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
