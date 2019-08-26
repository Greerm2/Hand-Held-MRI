
;***************************************************************************
      nolist
      include  'ioequ.asm'
      include  'FPGA.asm'
      list
;***************************************************************************

                org     x:$0


PARAM_BASE      equ     *       ; Memory for pulse program parameters
RXG1            ds      1       ; 00 - Receiver gain block 1
RXG2            ds      1       ; 01 - Receiver gain block 2
DEC1            ds      1       ; 02 - Decimation for CIC1
DEC5            ds      1       ; 03 - Decimation for CIC5
DECFIR          ds      1       ; 04 - Decimation for FIR
ATT1            ds      1       ; 05 - Attenuation for CIC1
DELAYFIR        ds      1       ; 06 - Delay for CIC5
ATTFIR          ds      1       ; 07 - Attenuation for FIR
Ntaps           ds      1       ; 08 - Taps for FIR
TXF00           ds      1       ; 09 - Tx Frequency word 0
TXF01           ds      1       ; 10 - Tx Frequency word 1
                ds      1       ; 11 - not used
                ds      1       ; 12 - not used
RXF00           ds      1       ; 13 - Rx Frequency word 0
RXF01           ds      1       ; 14 - Rx Frequency word 1
GRADVERSION     ds      1       ; 15 - Gradient version number
                ds      1       ; 16 - not used
RXP0            ds      1       ; 17 - Rx Phase word 0
NRSCANS         ds      1       ; 18 - Number of scans to perform
EXPDELAY        ds      1       ; 19 - Delay between experiments
PGO             ds      1       ; 20 - Pulse gate overhead delay
GRADRESET       ds      1       ; 21 - 1 if gradients are to be reset
LFRXAMP         ds      1       ; 22 - 1 if low frequency Kea
SKIPPNTS        ds      1       ; 23 - Points to skip at start of acquisition
JITTER_CH1      ds      1       ; 24 - DDS channel 1 antiphase jitter parameter
JITTER_CH2      ds      1       ; 25 - DDS channel 2 antiphase jitter parameter
UseTrigger      ds      1       ; 26 - If = 1 then wait for trigger
                ds      1       ; 27 - Not used

; Pulse program info

NRxShim             ds      1       ; 28 - Number xShim
NRyShim             ds      1       ; 29 - Number yShim
NRzShim             ds      1       ; 30 - Number zShim
NRoShim             ds      1       ; 31 - Number oShim
TXA90            ds      1       ; 32 - Tx amplitude 90 word 0
TXP1            ds      1       ; 33 - Tx phase 1
DELAYRF90          ds      1       ; 34 - Delay RF90
NRGradZ             ds      1       ; 35 - Number GradZ
NRZGradAmplitude             ds      1       ; 36 - Number ZGradAmplitude
NRGradX             ds      1       ; 37 - Number GradX
NRXGradAmplitude             ds      1       ; 38 - Number XGradAmplitude
DELAYXGrad          ds      1       ; 39 - Delay XGrad
DELAYDeltaGrad          ds      1       ; 40 - Delay DeltaGrad
TXA180            ds      1       ; 41 - Tx amplitude 180 word 0
TXP2            ds      1       ; 42 - Tx phase 2
DELAYRF180          ds      1       ; 43 - Delay RF180
DELAYEncoding          ds      1       ; 44 - Delay Encoding
NREchoes             ds      1       ; 45 - Number Echoes
DELAY180_acq          ds      1       ; 46 - Delay 180_acq
NRPnts             ds      1       ; 47 - Number Pnts
DELAYAcq          ds      1       ; 48 - Delay Acq
NRDummy             ds      1       ; 49 - Number Dummy
DELAYDummy          ds      1       ; 50 - Delay Dummy




        DEFINE  NEWFPGA   '1'
;***************************************************************************
;
;       Space for filter coeffs, samples etc
;
        org    y:$0

CONSTANTS     equ     *     
TTL           ds      1                ; TTL state
;RF            ds      1                ; RF TTL state
DATA_ADRS     ds      1                ; Acquisition memory address for append mode
TX_AMP        ds      1                ; Current Tx amplitude
TX_PHASE      ds      1                ; Current Tx phase
TMP           ds      1                ; temporary variables

; **************************************************************************
; 
        org     p:$002000               ; start

        move    r0,x:(r6)+              ; Save registers
        move    r1,x:(r6)+
        move    r2,x:(r6)+
        move    r3,x:(r6)+
        move    r4,x:(r6)+
        move    r5,x:(r6)+
        move    r7,x:(r6)+
        move    x0,x:(r6)+
        move    x1,x:(r6)+
        move    y0,x:(r6)+
        move    y1,x:(r6)+
        move    b0,x:(r6)+
        move    b1,x:(r6)+
        move    b2,x:(r6)+


        movep   #$0F9FE1,x:A_BCR        ; Set up wait states, 4 for AA3

         

         

;Startup sequence
        move    #$000000,a1
        move    a1,x:FPGA_TTL
        move    #$000000,a1                     ; turn off reset pulse
        move    a1,x:FPGA_Sync
; AD9910
        move    #$000000,a1
        move    a1,x:FPGA_DDS_CR
; ADC LTC2207
        move    #$00d6d8,a1
        move    a1,x:FPGA_ADC_SW            ; startup time from shutdown
        move    #$000003,a1                 ; 3 for dithering 1 without
        move    a1,x:FPGA_ADC_CR            ; Start-up ADC
; Reset Sequence
; AD9910 and DDC
        move    #$000023,a1                     ; Reset AD9910 and CIC and DDC-DDS
        move    a1,x:FPGA_Sync
        move    #$000000,a1                     ; turn off reset pulse
        move    a1,x:FPGA_Sync
; Setup DDC
        move    #$000001,a1                 ; clear on set 0
        move    a1,x:FPGA_DRP1_CR
; Set DDC DDS Frequency
        move    x:RXF00,a1
        move    a1,x:FPGA_DRP1_PI          ; Update DRP DDS frequency
        move    x:RXF01,a1
        move    a1,x:FPGA_DRP1_PI
; Set DDC DDS Phase
        move    x:RXP0,a1
        move    a1,x:FPGA_DRP1_PO          ; Update DRP DDS phase
        move    #0,a1
        move    a1,x:FPGA_DRP1_PO
; Set CIC Fast Mode Specs
        move    #>1,a1
        move    a1,x:FPGA_DRP1_FASTMODE
        move    #>65,a1                     ; Minimum value for largest dwell times
        move    a1,x:FPGA_DRP1_MAXSpeedR
        move    x:SKIPPNTS,a1               ; Number of points to ignore from 
        move    a1,x:FPGA_DRP1_SD           ; Start if data collected
; Set CIC Decimation and scale value
        move    x:DEC1,a                    ; Update CIC Decimation
        move    a1,x:FPGA_DRP1_Dec
        move    x:ATT1,a                    ; Update Scale
        move    a1,x:FPGA_DRP1_Sca
        move    #$000001,a1                 ; turn off reset pulse
        move    a1,x:FPGA_Sync
; Set up filter coeffs
        move    #$000040,a1
        move    a1,x:FPGA_TTL
        move    #$10,r1                     ; Coefficients are stored from y:#$10
        move    #$000003,a1
        move    a1,x:FPGA_DRP1_FIRC
        move    #$000001,a1
        move    a1,x:FPGA_DRP1_FIRC
        do      x:Ntaps,fcl                  ; Do Ntaps coeffs
        move    y:(r1)+,a1
        move    a1,x:FPGA_DRP1_FIRData       ; Write bottom byte to data register 0 and inc pointer
fcl     nop
; Set FIR values
        move    x:DECFIR,a1                  ; Update CIC decimation set to 1
        move    a1,x:FPGA_DRP1_FIRC
        move    x:ATTFIR,a1
        move    a1,x:FPGA_DRP1_FIRScale
        move    #6000,a1
        move    a1,x:FPGA_DRP1_FIRRC
        move    x:DELAYFIR,a1
        move    #20,a1
        move    a1,x:FPGA_DRP1_FIRSD    ; Update filter delay count
        move    #$000040,a1
        move    a1,x:FPGA_TTL
; SETUP ADC
        move    #$000009,a1
        move    a1,x:FPGA_ADC_RW            ; delay from ADC capture to ND DDC
        move    #$000004,a1
        move    a1,x:FPGA_ADC_IR            ; Reset Overflow enable flag
        move    #$000000,a1
        move    a1,x:FPGA_ADC_IR            
        move    #$000001,a1                 ; Reset Overflow bit
        move    a1,x:FPGA_ADC_OV

; Reset FIFO
        move    #$000001,a1                 ; RESET FIFO
        move    a1,x:FPGA_FIFO_CR
; Set up the AD9910 DDS

        IF      NEWFPGA
; Reset Serial control (new dual DDS board)
        move    #$001000,a1                 ; Reset serial IO to AD9910
        move    a1,x:FPGA_DDS_CR
        move    #$000400,a1                 ;
        move    a1,x:FPGA_DDS_CR
; Setup DDS PLL clk frequency
        move    #$000538,a1                 ; CFR3 32-16     #$0438
        move    a1,x:FPGA_DDS1_CFR3
        move    #$004128,a1                 ; CFR3 15-0      #$4120      1 GHz clock
        move    a1,x:FPGA_DDS1_CFR3
        move    #2,r7
        bsr     wait
        move    #$000538,a1                 ; CFR3 32-16     #$0438
        move    a1,x:FPGA_DDS2_CFR3
        move    #$004128,a1                 ; CFR3 15-0      #$4140    1 GHz clock
        move    a1,x:FPGA_DDS2_CFR3
        move    #2,r7
        bsr     wait
        move    #$000010,a1                 ; 000010 I/O update
        move    a1,x:FPGA_Sync
        move    #2,r7
        bsr     wait
        move    #$000000,a1                 ; 000010 I/O update
        move    a1,x:FPGA_Sync
        move    #100,r7
        bsr     wait
        ELSE
; Reset Serial control (old single DDS board)
        move    #$001000,a1                 ; Reset serial IO to AD9910
        move    a1,x:FPGA_DDS2_CR
; Auto generate iou
        move    #$000400,a1                 ;#$000400
        move    a1,x:FPGA_DDS2_CR
        move    #2,r7
        bsr     wait
; Setup DDS PLL clk frequency
        move    #$000438,a1                 ; CFR3 32-16     #$0438    ---!!change for V2 !!
        move    a1,x:FPGA_DDS2_CFR3
        move    #$004140,a1                 ; CFR3 15-0      #$4140  ---!!change for V2 !!
        move    a1,x:FPGA_DDS2_CFR3
        move    #100,r7
        bsr     wait
        ENDIF

; Set Auxilary DAC value
        move    #$000000,a1                 ; Aux DAC 32-16
        move    a1,x:FPGA_DDS1_ADAC
        move    #$000085,a1                 ; Aux DAC 15-0
        move    a1,x:FPGA_DDS1_ADAC
        move    #2,r7
        bsr     wait
        move    #$000000,a1                 ; Aux DAC 32-16
        move    a1,x:FPGA_DDS2_ADAC
        move    #$000085,a1                 ; Aux DAC 15-0
        move    a1,x:FPGA_DDS2_ADAC
        move    #2,r7
        bsr     wait
; setup CFR1
        move    #$000049,a1                 ; CFR1 32-16
        move    a1,x:FPGA_DDS2_CFR1
        move    #$000000,a1                 ; CFR1 15-0
        move    a1,x:FPGA_DDS2_CFR1
        move    #2,r7
        bsr     wait
        move    #$000049,a1                 ; CFR1 32-16
        move    a1,x:FPGA_DDS1_CFR1
        move    #$000000,a1                 ; CFR1 15-0
        move    a1,x:FPGA_DDS1_CFR1
        move    #2,r7
        bsr     wait
; Switch off parallel update mode
        move    #$000000,a1        
        move    a1,x:FPGA_DDS1_PAR_MODE

;        clr     a                           ; ADDED
;        move    x:TXA1,a1
;        asl     #2,a,a
;        move    a1,x:FPGA_DDS2_PAR

; Setup CFR2
        move    #$000100,a1                 ; CFR2 32-16
        move    a1,x:FPGA_DDS1_CFR2
        move    #$000080,a1                 ; CFR2 15-0      parallel port mode off match latency on
        move    a1,x:FPGA_DDS1_CFR2
        move    #1,r7
        bsr     wait
        move    #$000100,a1                 ; CFR2 32-16
        move    a1,x:FPGA_DDS2_CFR2
        move    #$000080,a1                 ; CFR2 15-0      parallel port mode off match latency on
        move    a1,x:FPGA_DDS2_CFR2
        move    #1,r7
        bsr     wait
; Setup MultiChip sync
        move    #$002800,a1                 ; MSR 32-16 2c
        move    a1,x:FPGA_DDS1_MSR
        move    x:JITTER_CH1,a1
  ;      move    #$000058,a1                 ; MSR 15-0
        move    a1,x:FPGA_DDS1_MSR
        move    #1,r7
        bsr     wait
        move    #$002800,a1                 ; MSR 32-16
        move    a1,x:FPGA_DDS2_MSR
        move    x:JITTER_CH2,a1
  ;      move    #$000088,a1                 ; MSR 15-0
        move    a1,x:FPGA_DDS2_MSR
        move    #1,r7
        bsr     wait
; Auto generate iou
        move    #$000400,a1                 ;#$000400
        move    a1,x:FPGA_DDS_CR
        move    #2500,r7                   ; wait long time for loop
        bsr     wait

         

;### End startup if - this is run only during the first loop


; Set values for AD9910 channel 1 profile 0
        move    #$000000,a1                 ;Profile 0   #003fff
        move    a1,x:FPGA_DDS1_Pro0
        move    #$000000,a1
        move    a1,x:FPGA_DDS1_Pro0
        move    x:TXF00,a1                  ; Output W1 to 9910 (freq byte 1)
        move    a1,x:FPGA_DDS1_Pro0
        move    x:TXF01,a1                  ; Output W2 to 9910 (freq byte 0)
        move    a1,x:FPGA_DDS1_Pro0
        move    #2,r7
        bsr     wait
; Set values for AD9910 channel 2 profile 0
        move    #$000000,a1                 ;Profile 0   #003fff
        move    a1,x:FPGA_DDS2_Pro0
        move    #$000000,a1
        move    a1,x:FPGA_DDS2_Pro0
        move    x:TXF00,a1                  ; Output W1 to 9910 (freq byte 1)
        move    a1,x:FPGA_DDS2_Pro0
        move    x:TXF01,a1                  ; Output W2 to 9910 (freq byte 0)
        move    a1,x:FPGA_DDS2_Pro0
        move    #2,r7
        bsr     wait
; Set DDC DDS Frequency
        move    x:RXF00,a1
        move    a1,x:FPGA_DRP1_PI          ; Update DRP DDS frequency
        move    x:RXF01,a1
        move    a1,x:FPGA_DRP1_PI
; Clear Accumulator and setup CFR1
        move    #$000049,a1                 ; CFR1 32-16
        move    a1,x:FPGA_DDS1_CFR1
        move    #$002000,a1                 ; CFR1 15-0
        move    a1,x:FPGA_DDS1_CFR1
        move    #2,r7
        bsr     wait
        move    #$000049,a1                 ; CFR1 32-16
        move    a1,x:FPGA_DDS2_CFR1
        move    #$002000,a1                 ; CFR1 15-0
        move    a1,x:FPGA_DDS2_CFR1
        move    #2,r7
        bsr     wait
; Sync AD9910 and internal DDC
        move    #$000008,a1                 ; SYNC pulse
        move    a1,x:FPGA_Sync
        move    #$000002,a1                 ; Clear Sync port
        move    a1,x:FPGA_Sync
        move    #$000004,a1                 ; Start CE DDC-DDS
        move    a1,x:FPGA_Sync
        move    #$000010,a1                 ; I/O Update to clear registers
        move    a1,x:FPGA_Sync
        move    #$000000,a1                 ; Clear Sync port
        move    a1,x:FPGA_Sync
        move    #2,r7
        bsr     wait

        move    #$000049,a1  ; CFR1 32-16
        move    a1,x:FPGA_DDS1_CFR1
        move    #$000000,a1  ; CFR1 15-0
        move    a1,x:FPGA_DDS1_CFR1
        move    #100,r7
        bsr     wait
        move    #$000049,a1  ; CFR1 32-16
        move    a1,x:FPGA_DDS2_CFR1
        move    #$000000,a1  ; CFR1 15-0
        move    a1,x:FPGA_DDS2_CFR1
        move    #100,r7
        bsr     wait

;;-***---NEW-CODE-END--***--;;
        nop
        nop
        nop
        nop
;  Configure serial ports

        movep   #$2C,x:A_PCRD           ; Set up SSI 1 on Port D
        movep   #$100803,x:A_CRA1       ; SSI 1 ctrl reg A /3 clk, 16 bit word transferred
        movep   #$13C3C,x:A_CRB1        ; SSI 1 ctrl reg B enable SSI port with sc1/2 are outputs

; Check for HF or LF Rx amplifier
        move    x:LFRXAMP,a1
        brclr   #$00000,a1,SKIPHF

;  Set Receiver gain via serial port (1-100 MHz Rx amp)
        movep   #$2C,x:A_PCRC           ; Set up SSI 0
        movep   #$10080A,x:A_CRA0       ; /10 clk, 16 bit word transferred 
        movep   #$13C3C,x:A_CRB0        ; enable SSI port with sc1/2 are outputs

        move    x:RXG1,a1
        movep   #$0000,x:A_PDRE         ; select first gain block
        movep   a,x:A_TX00              ; Set up first gain block
        move    #10,r7
        bsr     wait
        move    x:RXG2,a1
        movep   #$0004,x:A_PDRE         ; select next gain block
        movep   a,x:A_TX00              ; Set up second gain block
        move    #10,r7
        bsr     wait
        bra     SKIPLF

SKIPHF  nop

;  Set Receiver gain via serial port (0-20 MHz Rx amp)

        movep   #$2C,x:A_PCRC           ; Set up SSI 0
        movep   #$18080A,x:A_CRA0       ; /10 clk, 16 bit word transferred 
        movep   #$13C3C,x:A_CRB0        ; enable SSI port with sc1/2 are outputs

        move    x:RXG1,a1
        move    #$00FFFF,x1
        and      x1,a1
        move    #$100000,x1             ; Select gain DAC
        or      x1,a1
        movep   #$0000,x:A_PDRE         ; Select Rx amp interface
        move    a1,x:A_TX00
        move    #10,r7                  ; Wait 10 us
        bsr     wait

;  Set Receiver offset via serial port (0-20 MHz Rx amp)
        move    x:RXG2,a1
        move    #$00FFFF,x1
        and      x1,a1
        move    #$110000,x1             ; Select offset DAC
        or      x1,a1
        movep   #$0000,x:A_PDRE         ; Select Rx amp interface
        move    a1,x:A_TX00
        move    #10,r7                  ; Wait 10 us
        bsr     wait

SKIPLF  nop

        movep   #$0007,x:A_PDRE         ; Select unused serial port
        movep   #$3c3c,x:A_CRB0         ; Disable SSI 0
        movep   #$24,x:A_PCRC

; Reset gradients to zero
        bsr     greset

; Intialise TTL value
        move    #$8000,a1   
        move    a1,y:TTL 
        move    a1,x:FPGA_TTL

; Initialise RF amplitude and phase
        move    #0,a1
        move    a1,y:TX_AMP  
        move    a1,y:TX_PHASE  

; Intialise Data address
        move    #$10000,a1
        move    a1,y:DATA_ADRS         
        move    a1,r5 

; Wait a bit   
        movep   #0,x:A_TLR2             ; Set up event timer
        move    #100,r3
        movep   r3,x:A_TCPR2            ; Set for first event
        movep   #$A01,x:A_TCSR2
  ;      jclr    #21,x:A_TCSR2,*
        movep   #$200A00,x:A_TCSR2      ; Turn off timer

; Set up repetition time
;        movep   #0,x:A_TLR0             ; Set up event timer
;        move    #$7FFFFF,r3
;        movep   r3,x:A_TCPR0            ; Set for first event
;        movep   #$000A01,x:A_TCSR0      ; Start timer
;        nop




;
;***************************************************************************
; Set Gradient level
        movep   #$2C,x:A_PCRD          ; Turn on SSI 1 on Port D
        move    #3,a1
        movep   a1,x:A_PDRE
        move    x:NRxShim,a1
        lsl     #8,a
        movep   a1,x:A_TX10            ; Set up gradient level
        move    #2,r7                  ; Wait 2us
        bsr     wait
        movep   #$24,x:A_PCRD          ; Turn off SSI 1 on Port D
;
;***************************************************************************
; Set Gradient level
        movep   #$2C,x:A_PCRD          ; Turn on SSI 1 on Port D
        move    #2,a1
        movep   a1,x:A_PDRE
        move    x:NRyShim,a1
        lsl     #8,a
        movep   a1,x:A_TX10            ; Set up gradient level
        move    #2,r7                  ; Wait 2us
        bsr     wait
        movep   #$24,x:A_PCRD          ; Turn off SSI 1 on Port D
;
;***************************************************************************
; Set Gradient level
        movep   #$2C,x:A_PCRD          ; Turn on SSI 1 on Port D
        move    #1,a1
        movep   a1,x:A_PDRE
        move    x:NRzShim,a1
        lsl     #8,a
        movep   a1,x:A_TX10            ; Set up gradient level
        move    #2,r7                  ; Wait 2us
        bsr     wait
        movep   #$24,x:A_PCRD          ; Turn off SSI 1 on Port D
;
;***************************************************************************
; Set Gradient level
        movep   #$2C,x:A_PCRD          ; Turn on SSI 1 on Port D
        move    #0,a1
        movep   a1,x:A_PDRE
        move    x:NRoShim,a1
        lsl     #8,a
        movep   a1,x:A_TX10            ; Set up gradient level
        move    #2,r7                  ; Wait 2us
        bsr     wait
        movep   #$24,x:A_PCRD          ; Turn off SSI 1 on Port D

;
;***************************************************************************
; Generate an RF pulse
;
        clr    a
        move   x:DELAYRF90,a1
; Check for invalid pulse length
        move   #1,b1                     ; Abort code
        cmp    #49999,a                  ; Pulse must be < 1 ms
        jgt    ABORT
        move   #2,b1                     ; Abort code
        cmp    #24,a                     ; Pulse must be >= 500 ns
        jlt    ABORT
; Unblank the RF amp
        move    y:TTL,a1                ; Load the current TTL level
        or      #$004000,a              ; Internal HPA
        move    a1,y:TTL                ; Save new TTL word
        move    a1,x:FPGA_TTL           ; Update TTL RF remains the same
; Start a timer to give pgo delay before RF comes on
        move    x:PGO,a1
        add     #3,a
        movep   a1,x:A_TCPR2
        nop
        movep   #$200A01,x:A_TCSR2
; Set channel amplitude
        move    x:TXA90,a1
        move    a1,y:TX_AMP
        move    a1,x:FPGA_DDS1_Pro0
; Set phase
        move    x:TXP1,a1
        move    a1,y:TX_PHASE
        move    a1,x:FPGA_DDS1_Pro0
        nop                             ; Eliminate pulse length jitter
        jclr    #21,x:A_TCSR2,*         ; Wait for parameters to update
; Start pulse
        move   x:DELAYRF90,r3
        movep   r3,x:A_TCPR2
       nop
        move    y:TTL,a1                ; Load the current TTL word
        or      #$000008,a             ; Channel 1/i/e RF on
        move    a1,y:TTL                ; Load the current TTL word
        move    a1,x:FPGA_TTL           ; Update TTL & RF
        movep   #$200A01,x:A_TCSR2      ; Start timer
        nop
        jclr    #21,x:A_TCSR2,*         ; Wait for pulse to end
; End pulse
        movep   #$200A00,x:A_TCSR2      ; Turn off timer
        and     #$FFBFF7,a               ; Switch off internal channel
        move    a1,y:TTL                 ; Update TTL word
        move    a1,x:FPGA_TTL           ; Update TTL & RF
        move    #$000000,a1
        move    a1,x:FPGA_DDS1_Pro0      ;Zero amplitude
;
;***************************************************************************
; Set Gradient level
        movep   #$2C,x:A_PCRD          ; Turn on SSI 1 on Port D
        move    x:NRGradZ,a1
        movep   a1,x:A_PDRE
        move    x:NRZGradAmplitude,a1
        lsl     #8,a
        movep   a1,x:A_TX10            ; Set up gradient level
        move    #2,r7                  ; Wait 2us
        bsr     wait
        movep   #$24,x:A_PCRD          ; Turn off SSI 1 on Port D
;
;***************************************************************************
; Set Gradient level
        movep   #$2C,x:A_PCRD          ; Turn on SSI 1 on Port D
        move    x:NRGradX,a1
        movep   a1,x:A_PDRE
        move    x:NRXGradAmplitude,a1
        lsl     #8,a
        movep   a1,x:A_TX10            ; Set up gradient level
        move    #2,r7                  ; Wait 2us
        bsr     wait
        movep   #$24,x:A_PCRD          ; Turn off SSI 1 on Port D
;
;***************************************************************************
; Delay
        move    x:DELAYXGrad,a1
        sub     #9,a
        move    a1,r3
        movep   r3,x:A_TCPR2
        movep   #$200A01,x:A_TCSR2
        nop
        jclr    #21,x:A_TCSR2,*         ; Wait for pulse to end
        movep   #$200A00,x:A_TCSR2      ; Turn off timer
;
;***************************************************************************
; Zero gradient
        movep   #$2C,x:A_PCRD          ; Turn on SSI 1 on Port D
        move    x:NRGradX,a1
        movep   a1,x:A_PDRE
        move    #$00,a1
        movep   a1,x:A_TX10            ; Zero the gradient
        move    #2,r7                  ; Wait 2us
        bsr     wait
        movep   #$24,x:A_PCRD          ; Turn off SSI 1 on Port D
;
;***************************************************************************
; Delay
        move    x:DELAYDeltaGrad,a1
        sub     #9,a
        move    a1,r3
        movep   r3,x:A_TCPR2
        movep   #$200A01,x:A_TCSR2
        nop
        jclr    #21,x:A_TCSR2,*         ; Wait for pulse to end
        movep   #$200A00,x:A_TCSR2      ; Turn off timer
;
;***************************************************************************
; Zero gradient
        movep   #$2C,x:A_PCRD          ; Turn on SSI 1 on Port D
        move    x:NRGradZ,a1
        movep   a1,x:A_PDRE
        move    #$00,a1
        movep   a1,x:A_TX10            ; Zero the gradient
        move    #2,r7                  ; Wait 2us
        bsr     wait
        movep   #$24,x:A_PCRD          ; Turn off SSI 1 on Port D

;
;***************************************************************************
; Generate an RF pulse
;
        clr    a
        move   x:DELAYRF180,a1
; Check for invalid pulse length
        move   #1,b1                     ; Abort code
        cmp    #49999,a                  ; Pulse must be < 1 ms
        jgt    ABORT
        move   #2,b1                     ; Abort code
        cmp    #24,a                     ; Pulse must be >= 500 ns
        jlt    ABORT
; Unblank the RF amp
        move    y:TTL,a1                ; Load the current TTL level
        or      #$004000,a              ; Internal HPA
        move    a1,y:TTL                ; Save new TTL word
        move    a1,x:FPGA_TTL           ; Update TTL RF remains the same
; Start a timer to give pgo delay before RF comes on
        move    x:PGO,a1
        add     #3,a
        movep   a1,x:A_TCPR2
        nop
        movep   #$200A01,x:A_TCSR2
; Set channel amplitude
        move    x:TXA180,a1
        move    a1,y:TX_AMP
        move    a1,x:FPGA_DDS1_Pro0
; Set phase
        move    x:TXP2,a1
        move    a1,y:TX_PHASE
        move    a1,x:FPGA_DDS1_Pro0
        nop                             ; Eliminate pulse length jitter
        jclr    #21,x:A_TCSR2,*         ; Wait for parameters to update
; Start pulse
        move   x:DELAYRF180,r3
        movep   r3,x:A_TCPR2
       nop
        move    y:TTL,a1                ; Load the current TTL word
        or      #$000008,a             ; Channel 1/i/e RF on
        move    a1,y:TTL                ; Load the current TTL word
        move    a1,x:FPGA_TTL           ; Update TTL & RF
        movep   #$200A01,x:A_TCSR2      ; Start timer
        nop
        jclr    #21,x:A_TCSR2,*         ; Wait for pulse to end
; End pulse
        movep   #$200A00,x:A_TCSR2      ; Turn off timer
        and     #$FFBFF7,a               ; Switch off internal channel
        move    a1,y:TTL                 ; Update TTL word
        move    a1,x:FPGA_TTL           ; Update TTL & RF
        move    #$000000,a1
        move    a1,x:FPGA_DDS1_Pro0      ;Zero amplitude
;
;***************************************************************************
; Delay
        move    x:DELAYEncoding,a1
        sub     #9,a
        move    a1,r3
        movep   r3,x:A_TCPR2
        movep   #$200A01,x:A_TCSR2
        nop
        jclr    #21,x:A_TCSR2,*         ; Wait for pulse to end
        movep   #$200A00,x:A_TCSR2      ; Turn off timer
;
;***************************************************************************
; Loop
        move    x:NREchoes,r1                 ; Load number repeats into r1
        do      r1,LOOP1                 ; Repeat code until Loop end

;
;***************************************************************************
; Generate an RF pulse
;
        clr    a
        move   x:DELAYRF180,a1
; Check for invalid pulse length
        move   #1,b1                     ; Abort code
        cmp    #49999,a                  ; Pulse must be < 1 ms
        jgt    ABORT
        move   #2,b1                     ; Abort code
        cmp    #24,a                     ; Pulse must be >= 500 ns
        jlt    ABORT
; Unblank the RF amp
        move    y:TTL,a1                ; Load the current TTL level
        or      #$004000,a              ; Internal HPA
        move    a1,y:TTL                ; Save new TTL word
        move    a1,x:FPGA_TTL           ; Update TTL RF remains the same
; Start a timer to give pgo delay before RF comes on
        move    x:PGO,a1
        add     #3,a
        movep   a1,x:A_TCPR2
        nop
        movep   #$200A01,x:A_TCSR2
; Set channel amplitude
        move    x:TXA180,a1
        move    a1,y:TX_AMP
        move    a1,x:FPGA_DDS1_Pro0
; Set phase
        move    x:TXP2,a1
        move    a1,y:TX_PHASE
        move    a1,x:FPGA_DDS1_Pro0
        nop                             ; Eliminate pulse length jitter
        jclr    #21,x:A_TCSR2,*         ; Wait for parameters to update
; Start pulse
        move   x:DELAYRF180,r3
        movep   r3,x:A_TCPR2
       nop
        move    y:TTL,a1                ; Load the current TTL word
        or      #$000008,a             ; Channel 1/i/e RF on
        move    a1,y:TTL                ; Load the current TTL word
        move    a1,x:FPGA_TTL           ; Update TTL & RF
        movep   #$200A01,x:A_TCSR2      ; Start timer
        nop
        jclr    #21,x:A_TCSR2,*         ; Wait for pulse to end
; End pulse
        movep   #$200A00,x:A_TCSR2      ; Turn off timer
        and     #$FFBFF7,a               ; Switch off internal channel
        move    a1,y:TTL                 ; Update TTL word
        move    a1,x:FPGA_TTL           ; Update TTL & RF
        move    #$000000,a1
        move    a1,x:FPGA_DDS1_Pro0      ;Zero amplitude
;
;***************************************************************************
; Delay
        move    x:DELAY180_acq,a1
        sub     #9,a
        move    a1,r3
        movep   r3,x:A_TCPR2
        movep   #$200A01,x:A_TCSR2
        nop
        jclr    #21,x:A_TCSR2,*         ; Wait for pulse to end
        movep   #$200A00,x:A_TCSR2      ; Turn off timer

;
;***************************************************************************
; Acquire (append with delay)
        move    x:NRPnts,a1
        move    a1,x:FPGA_DRP1_SampleNo  ; FPGA for the wrap-up algorithm to use ### make sure this is the same number as the loop count or major errors could occur
        move    y:TTL,a1                ; Load the current TTL state
        or      #$000010,a              ; Reset CIC
        move    a1,x:FPGA_TTL           ; Send to FPGA
        and     #$ffffef,a              ; Remove CIC flag
        or      #$000001,a              ; Start ADC capture
        move    a1,x:FPGA_TTL           ; Send to FPGA
        move    y:DATA_ADRS,r5           ; Specify the data address
        move    x:DELAYAcq,a1             ; Total acquisition time
        sub     #5,a
        move    a1,r3
        movep   r3,x:A_TCPR2
        movep   #$200A01,x:A_TCSR2      ; Set timer2
        movep   #0,x:A_TLR1             ; Set up ADC timer
        movep   #0,x:A_TCSR1            ; Disable timer
        movep   #$200361,x:A_TCSR1         ; Set up timer1 (T1) for input capture
        move    y:DATA_ADRS,r5           ; Specify the current data address
        move    x:NRPnts,r7
        do      r7,LBL1               ; Collect n samples
        jclr    #21,x:A_TCSR1,*         ; wait for timer1 flag
        movep   #$200361,x:A_TCSR1      ; clear timer1 flag
        move    x:FPGA_SampleA,a1       ; Load data from channel A
        move    a1,y:(r5)+              ; Save to memory
        move    x:FPGA_SampleB,a1       ; Load data from channel B
        move    a1,y:(r5)+              ; Save to memory
LBL1  nop
        move    y:TTL,a1                ; Stop ADC capture
        move    a1,x:FPGA_TTL           ; Send to FPGA
        move    r5,y:DATA_ADRS           ; Save data address
        jclr    #21,x:A_TCSR2,*         ; Wait for acqdelay to end
        movep   #$200A00,x:A_TCSR2
;
;***************************************************************************
; Loop
        move    x:NRDummy,r1                 ; Load number repeats into r1
        do      r1,LOOP2                 ; Repeat code until Loop end

;
;***************************************************************************
; Generate an RF pulse
;
        clr    a
        move   x:DELAYRF180,a1
; Check for invalid pulse length
        move   #1,b1                     ; Abort code
        cmp    #49999,a                  ; Pulse must be < 1 ms
        jgt    ABORT
        move   #2,b1                     ; Abort code
        cmp    #24,a                     ; Pulse must be >= 500 ns
        jlt    ABORT
; Unblank the RF amp
        move    y:TTL,a1                ; Load the current TTL level
        or      #$004000,a              ; Internal HPA
        move    a1,y:TTL                ; Save new TTL word
        move    a1,x:FPGA_TTL           ; Update TTL RF remains the same
; Start a timer to give pgo delay before RF comes on
        move    x:PGO,a1
        add     #3,a
        movep   a1,x:A_TCPR2
        nop
        movep   #$200A01,x:A_TCSR2
; Set channel amplitude
        move    x:TXA180,a1
        move    a1,y:TX_AMP
        move    a1,x:FPGA_DDS1_Pro0
; Set phase
        move    x:TXP2,a1
        move    a1,y:TX_PHASE
        move    a1,x:FPGA_DDS1_Pro0
        nop                             ; Eliminate pulse length jitter
        jclr    #21,x:A_TCSR2,*         ; Wait for parameters to update
; Start pulse
        move   x:DELAYRF180,r3
        movep   r3,x:A_TCPR2
       nop
        move    y:TTL,a1                ; Load the current TTL word
        or      #$000008,a             ; Channel 1/i/e RF on
        move    a1,y:TTL                ; Load the current TTL word
        move    a1,x:FPGA_TTL           ; Update TTL & RF
        movep   #$200A01,x:A_TCSR2      ; Start timer
        nop
        jclr    #21,x:A_TCSR2,*         ; Wait for pulse to end
; End pulse
        movep   #$200A00,x:A_TCSR2      ; Turn off timer
        and     #$FFBFF7,a               ; Switch off internal channel
        move    a1,y:TTL                 ; Update TTL word
        move    a1,x:FPGA_TTL           ; Update TTL & RF
        move    #$000000,a1
        move    a1,x:FPGA_DDS1_Pro0      ;Zero amplitude
;
;***************************************************************************
; Delay
        move    x:DELAYDummy,a1
        sub     #9,a
        move    a1,r3
        movep   r3,x:A_TCPR2
        movep   #$200A01,x:A_TCSR2
        nop
        jclr    #21,x:A_TCSR2,*         ; Wait for pulse to end
        movep   #$200A00,x:A_TCSR2      ; Turn off timer
;
;***************************************************************************
; Loop end
LOOP2  nop                ; Identifies end of loop
;
;***************************************************************************
; Loop end
LOOP1  nop                ; Identifies end of loop


;*************************************************************
;        End pulse program
;
        jmp     SKIP1 
ABORT   move    #$10000,r5             ; Write 100 into the first 1000 memory location
        move    b1,y:(r5)+
        move    #$99,r7
        do      r7,ABORTLP
        move   #100,a1
        move    a1,y:(r5)+
ABORTLP nop

SKIP1    move    #$000000,a1
        move    a1,x:FPGA_TTL
        
;Reset code
        move    #$000000,a1
        move    a1,x:FPGA_DRP1_CR
        move    a1,x:FPGA_ADC_CR
        move    #$000100,a1
        move    a1,x:FPGA_DDS_CR


; Reset gradients to zero
        bsr     greset

SKIP2   move    x:-(r6),b2              ; Restore registers
        move    x:-(r6),b1
        move    x:-(r6),b0
        move    x:-(r6),y1
        move    x:-(r6),y0
        move    x:-(r6),x1
        move    x:-(r6),x0
        move    x:-(r6),r7
        move    x:-(r6),r5
        move    x:-(r6),r4
        move    x:-(r6),r3
        move    x:-(r6),r2
        move    x:-(r6),r1
        move    x:-(r6),r0
        rts



; 
;*************************************************************
;        Wait n x 1us routine (100MHz clock)
;        On entry, r7 contains "n"
; 
wait    rep     #90
        nop
        move    (r7)-
        move    r7,b
        tst     b
        bne     wait
        rts
; 
;*************************************************************
;        short fixed wait 100ns routine (100MHz clock)
; 
swait   rep     #4
        nop
        rts

; 
;*************************************************************
;        Short variable wait of n x 100 ns routine (100MHz clock)
;        On entry, r7 contains "n"
; 
svwait  move    (r7)-
        move    r7,b
        tst     b
        nop
        nop
        nop
        bne     svwait
        rts

; 
;*************************************************************
;       Initialise gradients
; 
greset  move    x:GRADRESET,a1
        brclr   #$00000,a1,SKIPGRD

; Reset code for different gradient controller versions
        clr     a
        clr     b
        move    x:GRADVERSION,a1
        cmp     #04,a
        bne     G15
; 4 channel gradient controller reset code
G4      movep   #$2C,x:A_PCRD           ; Set up SSI 0
        movep   #$18080A,x:A_CRA0       ; /10 clk, 16 bit word transferred 
        movep   #$13C3C,x:A_CRB0        ; enable SSI port with sc1/2 are outputs
        move    #04,r7                  ; 4 gradients to reset
        move    #$00,b0                 ; Initial gradient = 0
        do      r7,G4LP                 ; Loop 4 times
        movep   b0,x:A_PDRE             ; Set the gradient channel
        move    #$00,a1
        movep   a1,x:A_TX10             ; Zero the gradeint
        rep     #180                    ; Wait 2 us
        nop                             ; for data to transfer
        inc     b                       ; Increment gradient channel
G4LP    nop
        bra     SKIPGRD 
; 15 channel gradient controller reset code
G15     cmp     #15,a
        bne     G16
        movep   #$2C,x:A_PCRD           ; Set up SSI 0
        movep   #$18080A,x:A_CRA0       ; /10 clk, 16 bit word transferred 
        movep   #$13C3C,x:A_CRB0        ; enable SSI port with sc1/2 are outputs
        move    #$00,a1
        movep   a1,x:A_PDRC		    ; Select second group of DACs     
        move    #$07,a1
        movep   a1,x:A_PDRE             ; Select reset line		
        move    #$00,a1
        movep   a1,x:A_TX10             ; Send zero to all gradients
        rep     #180                    ; Wait 2 us
        nop 
        bra     SKIPGRD 
; 16 channel gradient controller reset code
G16     cmp     #16,a
        bne     SKIPGRD
        movep   #$2C,x:A_PCRD           ; Turn on SSI 1 on Port D
        movep   #$180802,x:A_CRA1       ; /2 clk, 24 bit word transferred
        movep   #$13C3C,x:A_CRB1        ; Enable SSI port with sc1/2 are outputs
        move    #16,r7
        move    #$00,r5                 ; Gradient couner
        do      r7,G16LP
        clr     a
        clr     b
        move    r5,a1
        move    #$0001,b1               ; Assume first group
        cmp    #8,a                     ; See if channel is < 8
        jlt    G16SKIP
        sub    #8,a                     ; Subtract 8
        move    #$0000,b1               ; Second group
G16SKIP nop
        movep   b1,x:A_PDRC             ; Select group of 8 DACs
        move    a1,b0                   ; Save subgroup (4 channels)
        lsr     #2,a                    ; Shift 2 bits to right to determine subgroup (result 0/1)
        add     #4,a                    ; Add 4 to only access pins Y4 or Y5 on U7
        move    a1,x:A_PDRE             ; Select block of 4 DACs
        move    #$0,a1                  ; Get gradient amplitude
        move    #$00FFFF,x1
        and      x1,a1
        move    b0,b1                   ; Restore subgroup
        lsl     #16,b                   ; Move into correct format for DAC
        move    #$030000,x1
        and      x1,b
        move    #$100000,x1
        or       x1,b
        move     b1,x1
        or       x1,a                   ; Add amplitude word
        move    a1,x:A_TX10             ; Send channel info + grad. amplitude to DAC
        rep     #180                    ; Wait 2 us
        nop 
        clr     b
        move    r5,b1                   ; Next gradient
        add     #1,b
        move    b1,r5 
G16LP   nop


SKIPGRD nop
        movep   #$24,x:A_PCRD           ; Turn off SSI 1 on Port D (prevents serial noise)
        rts

; 
; *************************************************************
; 
;        TTL parameters
; 
ttl   dc      $00
; 
;*************************************************************


