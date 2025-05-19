    ;; **********************************************************************
    ;; **  Alphanumeric LCD support                  by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif
    ;;
    ;; **  Written as a Small Computer Monitor App
    ;; **  Version 0.1 SCC 2018-05-16
    ;; **  www.scc.me.uk
    ;;
    ;; **********************************************************************
    ;;
    ;; This module provides support for alphanumeric LCD modules using with
    ;; *  HD44780 (or compatible) controller
    ;; *  5 x 7 pixel fonts
    ;; *  Up to 80 characters in total (eg. 4 lines of 20 characters)
    ;; *  Interface via six digital outputs to the display (see below)
    ;;
    ;; LCD module pinout:
    ;;   1  Vss   0v supply
    ;;   2  Vdd   5v supply
    ;;   3  Vo    LCD input voltage (near zero volts via potentiometer)
    ;;   4  RS    High = data, Low = instruction
    ;;   5  R/W   High = Read, Low = Write
    ;;   6  E     Enable signal (active high)
    ;;   7  DB0   Data bit 0
    ;;   8  DB1   Data bit 1
    ;;   9  DB2   Data bit 2
    ;;  10  DB3   Data bit 3
    ;;  11  DB4   Data bit 4
    ;;  12  DB5   Data bit 5
    ;;  13  DB6   Data bit 6
    ;;  14  DB7   Data bit 7
    ;;  15  A     Backlight anode (+)
    ;;  16  K     Backlight cathode (-)
    ;;
    ;; This interfacing method uses 4-bit data mode and uses time delays
    ;; rather than polling the display's ready status. As a result the
    ;; interface only requires 6 simple output lines:
    ;;   LCD E   = Microcomputer output port bit <kLCDBitE>
    ;;   LCD RS  = Microcomputer output port bit <kLCDBitRS>
    ;;   LCD DB4 = Microcomputer output port bit 4
    ;;   LCD DB5 = Microcomputer output port bit 5
    ;;   LCD DB6 = Microcomputer output port bit 6
    ;;   LCD DB7 = Microcomputer output port bit 7
    ;; Display's R/W is connected to 0v so it is always in write mode
    ;; All 6 connections must be on the same port address <kLCDPrt>
    ;; This method also allows a decent length of cable from micro to LCD
    ;;
    ;; **********************************************************************

    #include "scm-api.h"
    #include "alphanumeric-lcd.h"


    ;; **********************************************************************
    ;; **  Constants
    ;; **********************************************************************

    ;; Constants that must be defined externally
    ;; .equ  kLCDPrt, 0x18           ;Port address used for LCD


    ;; **********************************************************************
    ;; **  LCD support functions
    ;; **********************************************************************

    ;; Initialise alphanumeric LCD module
    ;; LCD control register codes:
    ;;   DL   0 = 4-bit mode        1 = 8-bit mode
    ;;   N    0 = 1-line mode       1 = 2-line mode
    ;;   F    0 = Font 5 x 8        1 = Font 5 x 11
    ;;   D    0 = Display off       1 = Display on
    ;;   C    0 = Cursor off        1 = Cursor on
    ;;   B    0 = Blinking off      1 = Blinking on
    ;;   ID   0 = Decrement mode    1 = Increment mode
    ;;   SH   0 = Entire shift off  1 = Entire shift on
    .global fLCD_Init
fLCD_Init:
    ld   a, 40
    call LCDDelay       ; Delay 40ms after power up
    ;; For reliable reset set 8-bit mode - 3 times
    call WrFn8bit       ; Function = 8-bit mode
    call WrFn8bit       ; Function = 8-bit mode
    call WrFn8bit       ; Function = 8-bit mode
    ;; Set 4-bit mode
    call WrFn4bit       ; Function = 4-bit mode
    call LCDDelay1      ; Delay 37 us or more
    ;; Function set
    ld   a, 0b00101000  ; Control reg:  0  0  1  DL N  F  x  x
    call fLCD_Inst      ; 2 line, display on
    ;; Display On/Off control
    ld   a, 0b00001100  ; Control reg:  0  0  0  0  1  D  C  B
    call fLCD_Inst      ; Display on, cursor on, blink off
    ;; Display Clear
    ld   a, 0b00000001  ; Control reg:  0  0  0  0  0  0  0  1
    call fLCD_Inst      ; Clear display
    ;; Entry mode
    ld   a, 0b00000110  ; Control reg:  0  0  0  0  0  1  ID SH
    call fLCD_Inst      ; Increment mode, shift off
    ;; Display module now initialised
    ret


    ;; Write instruction to LCD
    ;;   On entry: A = Instruction byte to be written
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .global fLCD_Inst
fLCD_Inst:
    push af
    push af
    call fLCD_Inst.Wr4bits ; Write bits 4 to 7 of instruction
    pop  af
    rla                 ; Rotate bits 0-3 into bits 4-7...
    rla
    rla
    rla
    call fLCD_Inst.Wr4bits ; Write bits 0 to 3 of instruction
    ld   a, 2
    call LCDDelay       ; Delay 2 ms to complete
    pop  af
    ret
fLCD_Inst.Wr4bits:
    and  0xf0           ; Mask so we only have D4 to D7
    out  (kLCDPrt), a   ; Output with E=Low and RS=Low
    set  kLCDBitE, a
    out  (kLCDPrt), a   ; Output with E=High and RS=Low
    res  kLCDBitE, a
    out  (kLCDPrt), a   ; Output with E=Low and RS=Low
    ret


    ;; Write data to LCD
    ;;   On entry: A = Data byte to be written
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .global fLCD_Data
fLCD_Data:
    push af
    push af
    call fLCD_Data.Wr4bits ; Write bits 4 to 7 of data byte
    pop  af
    rla                 ; Rotate bits 0-3 into bits 4-7...
    rla
    rla
    rla
    call fLCD_Data.Wr4bits ; Write bits 0 to 3 of data byte
    ld   a, 150
fLCD_Data.Wait:
    dec  a              ; Wait a while to allow data
    jr   nz, fLCD_Data.Wait ;  write to complete
    pop  af
    ret
fLCD_Data.Wr4bits:
    and  0xf0           ; Mask so we only have D4 to D7
    set  kLCDBitRS, a
    out  (kLCDPrt), a   ; Output with E=Low and RS=High
    set  kLCDBitE, a
    out  (kLCDPrt), a   ; Output with E=High and RS=High
    res  kLCDBitE, a
    out  (kLCDPrt), a   ; Output with E=Low and RS=High
    res  kLCDBitRS, a
    out  (kLCDPrt), a   ; Output with E=Low and RS=Low
    ret


    ;; Position cursor to specified location
    ;;   On entry: A = Cursor position
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .global fLCD_Pos
fLCD_Pos:
    push af
    or   kLCD_Pos       ; Prepare position cursor instruction
    call fLCD_Inst      ; Write instruction to LCD
    pop  af
    ret


    ;; Output text string to LCD
    ;;   On entry: DE = Pointer to null terminated text string
    ;;   On exit:  BC HL IX IY I AF' BC' DE' HL' preserved
    .global fLCD_Str
fLCD_Str:
    ld   a, (DE)        ; Get character from string
    or   a              ; Null terminator?
    ret  z              ; Yes, so finished
    call fLCD_Data      ; Write character to display
    inc  de             ; Point to next character
    jr   fLCD_Str       ; Repeat


    ;; Define custom character
    ;;   On entry: A = Character number (0 to 7)
    ;;             DE = Pointer to character bitmap data
    ;;   On exit:  A = Next character number
    ;;             DE = Next location following bitmap
    ;;             BC HL IX IY I AF' BC' DE' HL' preserved
    ;; Character is
    .global fLCD_Def
fLCD_Def:
    push bc
    push af
    rlca                ; Calculate location
    rlca                ;  for bitmap data
    rlca                ;  = 8 x CharacterNumber
    or   kLCD_Def       ; Prepare define character instruction
    call fLCD_Inst      ; Write instruction to LCD
    ld   b, 0
fLCD_Def.Loop:
    ld   a, (DE)        ; Get byte from bitmap
    call fLCD_Data      ; Write byte to display
    inc  de             ; Point to next byte
    inc  b              ; Count bytes
    bit  3, b           ; Finish all 8 bytes?
    jr   z, fLCD_Def.Loop ; No, so repeat
    pop  af
    inc  a              ; Increment character number
    pop  bc
    ret


    ;; **********************************************************************
    ;; **  Private functions
    ;; **********************************************************************

    ;; Write function to LCD
    ;;   On entry: A = Function byte to be written
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
WrFn4bit:
    ld   a, 0b00100000  ; 4-bit mode
    jr   WrFunc
WrFn8bit:
    ld   a, 0b00110000  ; 8-bit mode
WrFunc:
    push af
    out  (kLCDPrt), a   ; Output with E=Low and RS=Low
    set  kLCDBitE, a
    out  (kLCDPrt), a   ; Output with E=High and RS=Low
    res  kLCDBitE, a
    out  (kLCDPrt), a   ; Output with E=Low and RS=Low
    ld   a, 5
    call LCDDelay       ; Delay 5 ms to complete
    pop  af
    ret


    ;; Delay in milliseconds
    ;;   On entry: A = Number of milliseconds delay
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
LCDDelay1:
    ld   a, 1           ; Delay by 1 ms
LCDDelay:
    push de
    ld   e, a           ; Delay by 'A' ms
    ld   d, 0
    call aDelayInMS
    pop  de
    ret
