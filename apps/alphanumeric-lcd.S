    ;; **********************************************************************
    ;; **  Alphanumeric LCD example                  by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif
    ;;
    ;; **  Written as a Small Computer Monitor App
    ;; **  Version 0.3 SCC 2018-06-28
    ;; **  www.scc.me.uk
    ;;
    ;; **********************************************************************
    ;;
    ;; This program is an example of one of the methods of interfacing an
    ;; alphanumeric LCD module.
    ;;
    ;; In this example the display is connected to the Z80 PIO parallel
    ;; port A. This is port A of a Z80 PIO, although a simple 8-bit latch
    ;; style output port is all that is actually needed.
    ;;
    ;; This interfacing method uses 4-bit data mode and uses time delays
    ;; rather than polling the display's ready status. As a result the
    ;; interface only requires 6 simple output lines:
    ;;   Output bit 0 = not used
    ;;   Output bit 1 = not used
    ;;   Output bit 2 = RS         High = data, Low = instruction
    ;;   Output bit 3 = E          Active high
    ;;   Output bit 4 = DB4
    ;;   Output bit 5 = DB5
    ;;   Output bit 6 = DB6
    ;;   Output bit 7 = DB7
    ;; Display's R/W is connected to 0v so it is always in write mode
    ;;
    ;; For further details see the LCD support code
    ;;
    ;; LiNC80 PIO address 0x18 to 0x1B (included on LiNC80 SBC1)
    ;;   0x18 = Port A data
    ;;   0x19 = Port B data
    ;;   0x1A = Port A control
    ;;   0x1B = Port B control
    ;;
    ;; RC2014 PIO address 0x68 to 0x6B (using module SC103 Z80 PIO)
    ;;   0x68 = Port A data
    ;;   0x69 = Port B data
    ;;   0x6A = Port A control
    ;;   0x6B = Port B control
    ;;
    ;; Z280RC PIO address 0x68 to 0x6B (using module SC103 Z80 PIO)
    ;;   0x68 = Port A data
    ;;   0x69 = Port B data
    ;;   0x6A = Port A control
    ;;   0x6B = Port B control
    ;;
    ;; To set up PIO port A in mode 3 (control) using LiNC80 as example
    ;;   I/O address 0x1A = 0b11001111 (0xCF)   Select mode 3 (control)
    ;;   I/O address 0x1A = 0b00000000 (0x00)   All pins are output
    ;;
    ;; To write a data byte to the output port using LiNC80 as example
    ;;   I/O address 0x18 = <data byte>
    ;;
    ;; **********************************************************************

    #include "scm-api.h"
    #include "alphanumeric-lcd.h"


    ;; **********************************************************************
    ;; **  Constants
    ;; **********************************************************************

    ;; Constants used by this code module
    #ifdef LINC80
    ;; PIO port A data register
    #define kDataReg     0x18
    ;; PIO port A control register
    #define kContReg     0x1A
    #endif

    #ifdef RC2014
    #define kDataReg     0x68
    #define kContReg     0x6A
    #endif

    #ifdef Z280RC
    #define kDataReg     0x68
    #define kContReg     0x6A
    #endif


    ;; LCD constants required by LCD support module
    ;; this must be a symbol, not a define
    .global kLCDPrt
    .equ kLCDPrt, kDataReg ; LCD port is the PIO port A data reg


    ;; **********************************************************************
    ;; **  Main program code
    ;; **********************************************************************

    .global Main
Main:
    ;; Z280RC requires I/O page selection to access external I/O
    ;; Based on code by Bill Shen
    #ifdef Z280RC
    ld   c, 08h         ; Reg c points to I/O page register
    ld   l, 0h          ; Set I/O page register to 0x00
    db   0edh, 6eh      ; This is the op code for LDCTL (C),HL
    #endif

    ;; Initalise PIO port A for control mode with all bits set as outputs
    ld   a, 0b11001111
    out  (kContReg), a  ; Port A = PIO 'control' mode
    ld   a, 0b00000000
    out  (kContReg), a  ; Port A = all lines are outputs

    ;; Initialise alphanumeric LCD module
    call fLCD_Init      ; Initialise LCD module

    ;; Display text on first line
    ld   a, kLCD_Line1
    call fLCD_Pos       ; Position cursor to location in A
    ld   de, MsgHello
    call fLCD_Str       ; Display string pointed to by DE

    ;; Display text on second line
    ld   a, kLCD_Line2
    call fLCD_Pos       ; Position cursor to location in A
    ld   de, MsgLiNC80
    call fLCD_Str       ; Display string pointed to by DE

    ;; Define custom character(s)
    ld   a, 0           ; First character to define (0 to 7)
    ld   de, BitMaps    ; Pointer to start of bitmap data
    ld   b, 2           ; Number of characters to define
Main.DefLoop:
    call fLCD_Def       ; Define custom character
    djnz Main.DefLoop   ; Repeat for each character

    ;; Display custom character 0
    ld   a, kLCD_Line1+14
    call fLCD_Pos       ; Position cursor to location in A
    ld   a, 0
    call fLCD_Data      ; Write character in A at cursor

    ;; (agrif) for some reason, precompiled LINC80 version includes this
    #ifdef LINC80
    ;; Display custom character 1
    ld   a, kLCD_Line2+14
    call fLCD_Pos       ; Position cursor to location in A
    ld   a, 1
    call fLCD_Data      ; Write character in A at cursor
    #endif

    ;; Some other things to do
    ;;ld   a, kLCD_Clear  ; Display clear
    ;;ld   a, kLCD_Blink  ; Display on with blinking block cursor
    ;;ld   a, kLCD_Under  ; Display on with underscore cursor
    ;;ld   a, kLCD_On     ; Display on with no cursor
    ;;ld   a, kLCD_Off    ; Display off

    ;; (agrif) LINC80 also differs here
    #ifdef LINC80
    ld   a, kLCD_Blink
    #else
    ld   a, kLCD_On
    #endif

    call fLCD_Inst      ; Send instruction to display

    ;; Z280RC requires I/O page selection to be restored
    ;; Code by Bill Shen
    #ifdef Z280RC
    ld   c, 08h         ; hcs reg c points to I/O page register
    ld   l, 0feh        ; hcs set I/O page register to 0xFE
    db   0edh, 6eh      ; hcs this is the op code for LDCTL (C),HL
    #endif

    ret


    ;; Test strings
MsgHello:
    .asciz "Hello World!"
    #ifdef LINC80
MsgLiNC80:
    .asciz "I'm a LiNC80"
    #endif
    #ifdef RC2014
MsgLiNC80:
    .asciz "I'm an RC2014"
    #endif
    #ifdef Z280RC
MsgLiNC80:
    .asciz "I'm a Z280RC"
    #endif

    ;; Custom characters 5 pixels wide by 8 pixels high
    ;; Up to 8 custom characters can be defined
BitMaps:
    ;; Character 0x00 = Battery icon
    .db  0b01110
    .db  0b11011
    .db  0b10001
    .db  0b10001
    .db  0b11111
    .db  0b11111
    .db  0b11111
    .db  0b11111
    ;; Character 0x01 = Bluetooth icon
    .db  0b01100
    .db  0b01010
    .db  0b11100
    .db  0b01000
    .db  0b11100
    .db  0b01010
    .db  0b01100
    .db  0b00000
