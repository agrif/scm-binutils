    ;; see msbasic.h for more info

    #include "msbasic.h"

.ARET:
    ret                 ; A RETurn instruction

GETINP:
    rst  0x10           ; input a character
    ret

CLS:
    ld   a, CS          ; ASCII Clear screen
    jp   MONOUT         ; Output character

WIDTH:
    call GETINT         ; Get integer 0-255
    ld   a, e           ; Width to A
    ld   (LWIDTH), a    ; Set width
    ret

LINES:
    call GETNUM         ; Get a number
    call DEINT          ; Get integer -32768 to 32767
    ld   (LINESC), de   ; Set lines counter
    ld   (LINESN), de   ; Set lines number
    ret

DEEK:
    call DEINT          ; Get integer -32768 to 32767
    push de             ; Save number
    pop  hl             ; Number to HL
    ld   b, (hl)        ; Get LSB of contents
    inc  hl
    ld   a, (hl)        ; Get MSB of contents
    jp   ABPASS         ; Return integer AB

DOKE:
    call GETNUM         ; Get a number
    call DEINT          ; Get integer -32768 to 32767
    push de             ; Save address
    call CHKSYN         ; Make sure ',' follows
    .db  ','
    call GETNUM         ; Get a number
    call DEINT          ; Get integer -32768 to 32767
    ex   (sp), hl       ; Save value,get address
    ld   (hl), e        ; Save LSB of value
    inc  hl
    ld   (hl), d        ; Save MSB of value
    pop  hl             ; Restore code string address
    ret


    ;; HEX$(nn) Convert 16 bit number to Hexadecimal string

HEX:
    call TSTNUM         ; Verify it's a number
    call DEINT          ; Get integer -32768 to 32767
    push bc             ; Save contents of BC
    ld   hl, PBUFF
    ld   a, d           ; Get high order into A
    cp   0
    jr   z, .HEX2       ; Skip output if both high digits are zero
    call .BYT2ASC       ; Convert D to ASCII
    ld   a, b
    cp   '0'
    jr   z, .HEX1       ; Don't store high digit if zero
    ld   (hl), b        ; Store it to PBUFF
    inc  hl             ; Next location
.HEX1:
    ld   (hl), c        ; Store C to PBUFF+1
    inc  hl             ; Next location
.HEX2:
    ld   a, e           ; Get lower byte
    call .BYT2ASC       ; Convert E to ASCII
    ld   a, d
    cp   0
    jr   nz, .HEX3      ; If upper byte was not zero then always print lower byte
    ld   a, b
    cp   '0'            ; If high digit of lower byte is zero then don't print
    jr   z, .HEX4
.HEX3:
    ld   (hl), b        ; to PBUFF+2
    inc  hl             ; Next location
.HEX4:
    ld   (hl), c        ; to PBUFF+3
    inc  hl             ; PBUFF+4 to zero
    xor  a              ; Terminating character
    ld   (hl), a        ; Store zero to terminate
    inc  hl             ; Make sure PBUFF is terminated
    ld   (hl), a        ; Store the double zero there
    pop  bc             ; Get BC back
    ld   hl, PBUFF      ; Reset to start of PBUFF
    jp   STR1           ; Convert the PBUFF to a string and return it

.BYT2ASC:
    ld   b, a           ; Save original value
    and  0x0f           ; Strip off upper nybble
    cp   0x0a           ; 0-9?
    jr   c, .ADD30      ; If A-F, add 7 more
    add  a, 0x07        ; Bring value up to ASCII A-F
.ADD30:
    add  a, 0x30        ; And make ASCII
    ld   c, a           ; Save converted char to C
    ld   a, b           ; Retrieve original value
    rrca                ; and Rotate it right
    rrca
    rrca
    rrca
    and  0x0f           ; Mask off upper nybble
    cp   0x0a           ; 0-9? < A hex?
    jr   c, .ADD301     ; Skip Add 7
    add  a, 0x07        ; Bring it up to ASCII A-F
.ADD301:
    add  a, 0x30        ; And make it full ASCII
    ld   b, a           ; Store high order byte
    ret

    ;; Convert "&Hnnnn" to FPREG
    ;; Gets a character from (HL) checks for Hexadecimal ASCII numbers "&Hnnnn"
    ;; Char is in A, NC if char is ;<=>?@ A-z, CY is set if 0-9
HEXTFP:
    ex   de, hl         ; Move code string pointer to DE
    ld   hl, 0          ; Zero out the value
    call .GETHEX        ; Check the number for valid hex
    jp   c, .HXERR      ; First value wasn't hex, HX error
    jr   .HEXLP1        ; Convert first character
.HEXLP:
    call .GETHEX        ; Get second and addtional characters
    jr   c, .HEXIT      ; Exit if not a hex character
.HEXLP1:
    add  hl, hl         ; Rotate 4 bits to the left
    add  hl, hl
    add  hl, hl
    add  hl, hl
    or   l              ; Add in D0-D3 into L
    ld   l, a           ; Save new value
    jr   .HEXLP         ; And continue until all hex characters are in

.GETHEX:
    inc  de             ; Next location
    ld   a, (de)        ; Load character at pointer
    cp   ' '
    jp   z, .GETHEX     ; Skip spaces
    sub  0x30           ; Get absolute value
    ret  c              ; < "0", error
    cp   0x0a
    jr   c, .NOSUB7     ; Is already in the range 0-9
    sub  0x07           ; Reduce to A-F
    cp   0x0a           ; Value should be 0x0A-0x0F at this point
    ret  c              ; CY set if was :            ; < = > ? @
.NOSUB7:
    cp   0x10           ; > Greater than "F"?
    ccf
    ret                 ; CY set if it wasn't valid hex

.HEXIT:
    ex   de, hl         ; Value into DE, Code string into HL
    ld   a, d           ; Load DE into AC
    ld   c, e           ; For prep to
    push hl
    call ACPASS         ; ACPASS to set AC as integer into FPREG
    pop  hl
    ret

.HXERR:
    ld   e, HX          ; ?HEX Error
    jp   ERROR

    ;; BIN$(NN) Convert integer to a 1-16 char binary string
BIN:
    call TSTNUM         ; Verify it's a number
    call DEINT          ; Get integer -32768 to 32767
.BIN2:
    push bc             ; Save contents of BC
    ld   hl, PBUFF
    ld   b, 17          ; One higher than max char count
    ;; Suppress leading zeros
.ZEROSUP:
    dec  b              ; Max 16 chars
    ld   a, b
    cp   0x01
    jr   z, .BITOUT     ; Always output at least one character
    rl   e
    rl   d
    jr   nc, .ZEROSUP
    jr   .BITOUT2
.BITOUT:
    rl   e
    rl   d              ; Top bit now in carry
.BITOUT2:
    ld   a, '0'         ; Char for '0'
    adc  a, 0           ; If carry set then '0' --> '1'
    ld   (hl), a
    inc  hl
    dec  b
    jr   nz, .BITOUT
    xor  a              ; Terminating character
    ld   (hl), a        ; Store zero to terminate
    inc  hl             ; Make sure PBUFF is terminated
    ld   (hl), a        ; Store the double zero there
    pop  bc
    ld   hl, PBUFF
    jp   STR1

    ;; Convert "&Bnnnn" to FPREG
    ;; Gets a character from (HL) checks for Binary ASCII numbers "&Bnnnn"
BINTFP:
    ex   de, hl         ; Move code string pointer to DE
    ld   hl, 0          ; Zero out the value
    call .CHKBIN        ; Check the number for valid bin
    jp   c, .BINERR     ; First value wasn't bin, HX error
.BINIT:
    sub  '0'
    add  hl, hl         ; Rotate HL left
    or   l
    ld   l, a
    call .CHKBIN        ; Get second and addtional characters
    jr   nc, .BINIT     ; Process if a bin character
    ex   de, hl         ; Value into DE, Code string into HL
    ld   a, d           ; Load DE into AC
    ld   c, e           ; For prep to
    push hl
    call ACPASS         ; ACPASS to set AC as integer into FPREG
    pop  hl
    ret

    ;; Char is in A, NC if char is 0 or 1
.CHKBIN:
    inc  de
    ld   a, (de)
    cp   ' '
    jp   z, .CHKBIN     ; Skip spaces
    cp   '0'            ; Set C if < '0'
    ret  c
    cp   '2'
    ccf                 ; Set C if > '1'
    ret

.BINERR:
    ld   e, BN          ; ?BIN Error
    jp   ERROR


.JJUMP1:
    ld   ix, 0xffff     ; Flag cold start   <SCC> was -1
    jp   CSTART         ; Go and initialise

MONOUT:
    jp   0x0008         ; output a char

MONITR:
    #ifdef BUILD_GRANTS_ORIGINAL
    jp   0x0000         ; Monitor warm start
    #else
    ;; (agrif) FIXME this *should* be taken from a built SCM
    jp   0x0014         ; SCMonitor warm start
    #endif

INITST:
    ld   a, 0           ; Clear break flag
    ld   (BRKFLG), a
    jp   INIT

.ARETN:
    retn                ; Return from NMI

.TSTBIT:
    push af             ; Save bit mask
    and  b              ; Get common bits
    pop  bc             ; Restore bit mask
    cp   b              ; Same bit set?
    ld   a, 0           ; Return 0 in A
    ret

OUTNCR:
    call OUTC           ; Output character in A
    jp   PRNTCRLF       ; Output CRLF
