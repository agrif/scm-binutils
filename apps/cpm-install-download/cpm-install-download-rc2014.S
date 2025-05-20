    ;; **********************************************************************
    ;; **  RC2014 Download.com installer             by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    ;; The program aids installation of Download.com on to a RC2014 CP/M
    ;; system.

    .global Main
Main:
    ;; Page ROM out of memory
    ld   a, 1
    out  (0x38), a

    ;; Move downlaod.com program code to 0x0100
    ld   hl, Program
    ld   de, 0x0100
    ld   bc, ProgramEnd-Program
    ldir

    ;; Page ROM back into memory
    ld   a, 0
    out  (0x38), a

    ;; Display instructions
    ld   de, Message
    ld   c, 6           ; API 0x06
    rst  0x30           ;  = Output string

    ret

Message:
    .ascii "Download.com is ready to be saved.\r\n"
    .asciz "Start CP/M and enter SAVE 2 DOWNLOAD.COM\r\n"

Program:
    .incbin DOWNLOAD_BIN
ProgramEnd:
