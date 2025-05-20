    ;; =====================================================================
    ;; Contents of this file are copyright Grant Searle
    ;; HEX routine from Joel Owens.
    ;; converted to GNU binutils by agrif
    ;;
    ;; You have permission to use this for NON COMMERCIAL USE ONLY
    ;; If you wish to use it elsewhere, please include an acknowledgement
    ;; to myself.
    ;;
    ;; http://searle.hostei.com/grant/index.html
    ;;
    ;; eMail: home.micros01@btinternet.com
    ;;
    ;; If the above don't work, please perform an Internet search to see
    ;; if I have updated the web page hosting service.
    ;;
    ;; =====================================================================

    ;; CPM page 0 addresses
    .equ REBOOT, 0x0
    .equ BDOS, 0x5
    .equ FCB, 05CH
    .equ BUFF, 080H

    ;; CPM BDOS calls
    #define CONIO 6
    #define CONINP 1
    #define CONOUT 2
    #define PSTRING 9
    #define MAKEF 22
    #define CLOSEF 16
    #define WRITES 21
    #define DELF 19
    #define SETUSR 32

    #define CR 0x0d
    #define LF 0x0a

    .global _start
_start:
    ld   a, 0
    ld   (buffPos), a
    ld   (checkSum), a
    ld   (byteCount), a
    ld   (printCount), a
    ld   hl, BUFF
    ld   (buffPtr), hl


WAITLT:
    call GETCHR
    cp   'U'
    jp   z, SETUSER
    cp   ':'
    jr   nz, WAITLT


    ld   c, DELF
    ld   de, FCB
    call BDOS

    ld   c, MAKEF
    ld   de, FCB
    call BDOS

GETHEX:
    call GETCHR
    cp   '>'
    jr   z, CLOSE
    ld   b, a
    push bc
    call GETCHR
    pop  bc
    ld   c, a

    call BCTOA

    ld   b, a
    ld   a, (checkSum)
    add  a, b
    ld   (checkSum), a
    ld   a, (byteCount)
    inc  a
    ld   (byteCount), a

    ld   a, b

    ld   hl, (buffPtr)

    ld   (hl), a
    inc  hl
    ld   (buffPtr), hl

    ld   a, (buffPos)
    inc  a
    ld   (buffPos), a
    cp   80H

    jr   nz, NOWRITE

    ld   c, WRITES
    ld   de, FCB
    call BDOS
    ld   a, '.'
    call PUTCHR

    ;; New line every 8K (64 dots)
    ld   a, (printCount)
    inc  a
    cp   64
    jr   nz, noCRLF
    ld   (printCount), a
    ld   a, CR
    call PUTCHR
    ld   a, LF
    call PUTCHR
    ld   a, 0
noCRLF:
    ld   (printCount), a

    ld   hl, BUFF
    ld   (buffPtr), hl

    ld   a, 0
    ld   (buffPos), a
NOWRITE:
    jr   GETHEX


CLOSE:

    ld   a, (buffPos)
    cp   0
    jr   z, NOWRITE2

    ld   c, WRITES
    ld   de, FCB
    call BDOS
    ld   a, '.'
    call PUTCHR

NOWRITE2:
    ld   c, CLOSEF
    ld   de, FCB
    call BDOS

    ;; Byte count (lower 8 bits)
    call GETCHR
    ld   b, a
    push bc
    call GETCHR
    pop  bc
    ld   c, a

    call BCTOA
    ld   b, a
    ld   a, (byteCount)
    sub  b
    cp   0
    jr   z, byteCountOK

    ld   a, CR
    call PUTCHR
    ld   a, LF
    call PUTCHR

    ld   de, countErrMess
    ld   c, PSTRING
    call BDOS

    ;; Sink remaining 2 bytes
    call GETCHR
    call GETCHR

    jr   FINISH

byteCountOK:

    ;; Checksum
    call GETCHR
    ld   b, a
    push bc
    call GETCHR
    pop  bc
    ld   c, a

    call BCTOA
    ld   b, a
    ld   a, (checkSum)
    sub  b
    cp   0
    jr   z, checksumOK

    ld   a, CR
    call PUTCHR
    ld   a, LF
    call PUTCHR

    ld   de, chkErrMess
    ld   c, PSTRING
    call BDOS
    jr   FINISH

checksumOK:
    ld   a, CR
    call PUTCHR
    ld   a, LF
    call PUTCHR

    ld   de, OKMess
    ld   c, PSTRING
    call BDOS



FINISH:
    ld   c, SETUSR
    ld   e, 0
    call BDOS

    jp   REBOOT


SETUSER:
    call GETCHR
    call HEX2VAL
    ld   e, a
    ld   c, SETUSR
    call BDOS
    jp   WAITLT


    ;; Get a char into A
    ;;GETCHR:
    ;;    ld   C, CONINP
    ;;    call BDOS
    ;;    ret

    ;; Wait for a char into A (no echo)
GETCHR:
    ld   e, $FF
    ld   c, CONIO
    call BDOS
    cp   0
    jr   z, GETCHR
    ret

    ;; Write A to output
PUTCHR:
    ld   c, CONOUT
    ld   e, a
    call BDOS
    ret


    ;; ---------------------------------------------------------------------
    ;; Convert ASCII characters in B C registers to a byte value in A
    ;; ---------------------------------------------------------------------
BCTOA:
    ld   a, b           ; Move the hi order byte to A
    sub  $30            ; Take it down from Ascii
    cp   $0A            ; Are we in the 0-9 range here?
    jr   c, BCTOA1      ; If so, get the next nybble
    sub  $07            ; But if A-F, take it down some more
BCTOA1:
    rlca                ; Rotate the nybble from low to high
    rlca                ; One bit at a time
    rlca                ; Until we
    rlca                ; Get there with it
    ld   b, a           ; Save the converted high nybble
    ld   a, c           ; Now get the low order byte
    sub  $30            ; Convert it down from Ascii
    cp   $0A            ; 0-9 at this point?
    jr   c, BCTOA2      ; Good enough then, but
    sub  $07            ; Take off 7 more if it's A-F
BCTOA2:
    add  a, b           ; Add in the high order nybble
    ret

    ;; Change Hex in A to actual value in A
HEX2VAL:
    sub  $30
    cp   $0A
    ret  c
    sub  $07
    ret

    .data
buffPos:
    .db  0x0
buffPtr:
    .dw  0x0000
printCount:
    .db  0x0
checkSum:
    .db  0x0
byteCount:
    .db  0x0
OKMess:
    .ascii "OK$"
chkErrMess:
    .ascii "======Checksum Error======$"
countErrMess:
    .ascii "======File Length Error======$"
