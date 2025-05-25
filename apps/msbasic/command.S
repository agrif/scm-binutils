    ;; see msbasic.h for more info

    #include "msbasic.h"

    .section .rodata.errmsg

.ERRMSG:
    .asciz " Error"
INMSG:
    .asciz " in "
    .equ ZERBYT, $-1    ; A zero byte
.OKMSG:
    .asciz "Ok\r\n"
    .db  0
BRKMSG:
    .asciz "Break"

    ;; force a new section so that this is *after* the above
    .section .text.bakstk

BAKSTK:
    ld   hl, 4          ; Look for "FOR" block with
    add  hl, SP         ; same index as specified
LOKFOR:
    ld   a, (hl)        ; Get block ID
    inc  hl             ; Point to index address
    cp   ZFOR           ; Is it a "FOR" token
    ret  nz             ; No - exit
    ld   c, (hl)        ; BC = Address of "FOR" index
    inc  hl
    ld   b, (hl)
    inc  hl             ; Point to sign of STEP
    push hl             ; Save pointer to sign
    ld   l, c           ; HL = address of "FOR" index
    ld   h, b
    ld   a, d           ; See if an index was specified
    or   e              ; DE = 0 if no index specified
    ex   de, hl         ; Specified index into HL
    jp   z, .INDFND     ; Skip if no index given
    ex   de, hl         ; Index back into DE
    call CPDEHL         ; Compare index with one given
.INDFND:
    ld   bc, 16-3       ; Offset to next block
    pop  hl             ; Restore pointer to sign
    ret  z              ; Return if block found
    add  hl, bc         ; Point to next block
    jp   LOKFOR         ; Keep on looking

MOVUP:
    call ENFMEM         ; See if enough memory
MOVSTR:
    push bc             ; Save end of source
    ex   (sp), hl       ; Swap source and dest" end
    pop  bc             ; Get end of destination
.MOVLP:
    call CPDEHL         ; See if list moved
    ld   a, (hl)        ; Get byte
    ld   (bc), a        ; Move it
    ret  z              ; Exit if all done
    dec  bc             ; Next byte to move to
    dec  hl             ; Next byte to move
    jp   .MOVLP         ; Loop until all bytes moved

CHKSTK:
    push hl             ; Save code string address
    ld   hl, (ARREND)   ; Lowest free memory
    ld   b, 0           ; BC = Number of levels to test
    add  hl, bc         ; 2 Bytes for each level
    add  hl, bc
    .db  0x3e           ; Skip "PUSH HL"
ENFMEM:
    push hl             ; Save code string address
    ld   a, 0xd0        ; LOW -48 ; 48 Bytes minimum RAM
    sub  l
    ld   l, a
    ld   a, 0xff        ; HIGH (-48) ; 48 Bytes minimum RAM
    sbc  a, h
    jp   c, OMERR       ; Not enough - ?OM Error
    ld   h, a
    add  hl, SP         ; Test if stack is overflowed
    pop  hl             ; Restore code string address
    ret  c              ; Return if enough mmory
OMERR:
    ld   e, OM          ; ?OM Error
    jp   ERROR

DATSNR:
    ld   hl, (DATLIN)   ; Get line of current DATA item
    ld   (LINEAT), hl   ; Save as current line
SNERR:
    ld   e, SN          ; ?SN Error
    .db  0x01           ; Skip "LD E,DZ"
DZERR:
    ld   e, DZ          ; ?/0 Error
    .db  0x01           ; Skip "LD E,NF"
NFERR:
    ld   e, NF          ; ?NF Error
    .db  0x01           ; Skip "LD E,DD"
DDERR:
    ld   e, DD          ; ?DD Error
    .db  0x01           ; Skip "LD E,UF"
UFERR:
    ld   e, UF          ; ?UF Error
    .db  0x01           ; Skip "LD E,OV
OVERR:
    ld   e, OV          ; ?OV Error
    .db  0x01           ; Skip "LD E,TM"
TMERR:
    ld   e, TM          ; ?TM Error

ERROR:
    call CLREG          ; Clear registers and stack
    ld   (CTLOFG), a    ; Enable output (A is 0)
    call STTLIN         ; Start new line
    ld   hl, ERRORS     ; Point to error codes
    ld   d, a           ; D = 0 (A is 0)
    ld   a, '?'
    call OUTC           ; Output '?'
    add  hl, de         ; Offset to correct error code
    ld   a, (hl)        ; First character
    call OUTC           ; Output it
    call GETCHR         ; Get next character
    call OUTC           ; Output it
    ld   hl, .ERRMSG    ; "Error" message
ERRIN:
    call PRS            ; Output message
    ld   hl, (LINEAT)   ; Get line of error
    ld   de, 0xfffe     ; Cold start error if -2   <SCC> was -2
    call CPDEHL         ; See if cold start error
    jp   z, CSTART      ; Cold start error - Restart
    ld   a, h           ; Was it a direct error?
    and  l              ; Line = -1 if direct error
    inc  a
    call nz, LINEIN     ; No - output line of error
    .db  0x3e           ; Skip "POP BC"
POPNOK:
    pop  bc             ; Drop address in input buffer

PRNTOK:
    xor  a              ; Output "Ok" and get command
    ld   (CTLOFG), a    ; Enable output
    call STTLIN         ; Start new line
    ld   hl, .OKMSG     ; "Ok" message
    call PRS            ; Output "Ok"
.GETCMD:
    ld   hl, 0xffff     ; Flag direct mode   <SCC> was -1
    ld   (LINEAT), hl   ; Save as current line
    call .GETLIN        ; Get an input line
    jp   c, .GETCMD     ; Get line again if break
    call GETCHR         ; Get first character
    inc  a              ; Test if end of line
    dec  a              ; Without affecting Carry
    jp   z, .GETCMD     ; Nothing entered - Get another
    push af             ; Save Carry status
    call ATOH           ; Get line number into DE
    push de             ; Save line number
    call .CRUNCH        ; Tokenise rest of line
    ld   b, a           ; Length of tokenised line
    pop  de             ; Restore line number
    pop  af             ; Restore Carry
    jp   nc, EXCUTE     ; No line number - Direct mode
    push de             ; Save line number
    push bc             ; Save length of tokenised line
    xor  a
    ld   (LSTBIN), a    ; Clear last byte input
    call GETCHR         ; Get next character
    or   a              ; Set flags
    push af             ; And save them
    call SRCHLN         ; Search for line number in DE
    jp   c, .LINFND     ; Jump if line found
    pop  af             ; Get status
    push af             ; And re-save
    jp   z, ULERR       ; Nothing after number - Error
    or   a              ; Clear Carry
.LINFND:
    push bc             ; Save address of line in prog
    jp   nc, .INEWLN    ; Line not found - Insert new
    ex   de, hl         ; Next line address in DE
    ld   hl, (PROGND)   ; End of program
.SFTPRG:
    ld   a, (de)        ; Shift rest of program down
    ld   (bc), a
    inc  bc             ; Next destination
    inc  de             ; Next source
    call CPDEHL         ; All done?
    jp   nz, .SFTPRG    ; More to do
    ld   h, b           ; HL - New end of program
    ld   l, c
    ld   (PROGND), hl   ; Update end of program

.INEWLN:
    pop  de             ; Get address of line,
    pop  af             ; Get status
    jp   z, .SETPTR     ; No text - Set up pointers
    ld   hl, (PROGND)   ; Get end of program
    ex   (sp), hl       ; Get length of input line
    pop  bc             ; End of program to BC
    add  hl, bc         ; Find new end
    push hl             ; Save new end
    call MOVUP          ; Make space for line
    pop  hl             ; Restore new end
    ld   (PROGND), hl   ; Update end of program pointer
    ex   de, hl         ; Get line to move up in HL
    ld   (hl), h        ; Save MSB
    pop  de             ; Get new line number
    inc  hl             ; Skip pointer
    inc  hl
    ld   (hl), e        ; Save LSB of line number
    inc  hl
    ld   (hl), d        ; Save MSB of line number
    inc  hl             ; To first byte in line
    ld   de, BUFFER     ; Copy buffer to program
.MOVBUF:
    ld   a, (de)        ; Get source
    ld   (hl), a        ; Save destinations
    inc  hl             ; Next source
    inc  de             ; Next destination
    or   a              ; Done?
    jp   nz, .MOVBUF    ; No - Repeat
.SETPTR:
    call RUNFST         ; Set line pointers
    inc  hl             ; To LSB of pointer
    ex   de, hl         ; Address to DE
.PTRLP:
    ld   h, d           ; Address to HL
    ld   l, e
    ld   a, (hl)        ; Get LSB of pointer
    inc  hl             ; To MSB of pointer
    or   (hl)           ; Compare with MSB pointer
    jp   z, .GETCMD     ; Get command line if end
    inc  hl             ; To LSB of line number
    inc  hl             ; Skip line number
    inc  hl             ; Point to first byte in line
    xor  a              ; Looking for 00 byte
.FNDEND:
    cp   (hl)           ; Found end of line?
    inc  hl             ; Move to next byte
    jp   nz, .FNDEND    ; No - Keep looking
    ex   de, hl         ; Next line address to HL
    ld   (hl), e        ; Save LSB of pointer
    inc  hl
    ld   (hl), d        ; Save MSB of pointer
    jp   .PTRLP         ; Do next line

SRCHLN:
    ld   hl, (BASTXT)   ; Start of program text
SRCHLP:
    ld   b, h           ; BC = Address to look at
    ld   c, l
    ld   a, (hl)        ; Get address of next line
    inc  hl
    or   (hl)           ; End of program found?
    dec  hl
    ret  z              ; Yes - Line not found
    inc  hl
    inc  hl
    ld   a, (hl)        ; Get LSB of line number
    inc  hl
    ld   h, (hl)        ; Get MSB of line number
    ld   l, a
    call CPDEHL         ; Compare with line in DE
    ld   h, b           ; HL = Start of this line
    ld   l, c
    ld   a, (hl)        ; Get LSB of next line address
    inc  hl
    ld   h, (hl)        ; Get MSB of next line address
    ld   l, a           ; Next line to HL
    ccf
    ret  z              ; Lines found - Exit
    ccf
    ret  nc             ; Line not found,at line after
    jp   SRCHLP         ; Keep looking

NEW:
    ret  nz             ; Return if any more on line
CLRPTR:
    ld   hl, (BASTXT)   ; Point to start of program
    xor  a              ; Set program area to empty
    ld   (hl), a        ; Save LSB = 00
    inc  hl
    ld   (hl), a        ; Save MSB = 00
    inc  hl
    ld   (PROGND), hl   ; Set program end

RUNFST:
    ld   hl, (BASTXT)   ; Clear all variables
    dec  hl

INTVAR:
    ld   (BRKLIN), hl   ; Initialise RUN variables
    ld   hl, (LSTRAM)   ; Get end of RAM
    ld   (STRBOT), hl   ; Clear string space
    xor  a
    call RESTOR         ; Reset DATA pointers
    ld   hl, (PROGND)   ; Get end of program
    ld   (VAREND), hl   ; Clear variables
    ld   (ARREND), hl   ; Clear arrays

CLREG:
    pop  bc             ; Save return address
    ld   hl, (STRSPC)   ; Get end of working RAN
    ld   SP, hl         ; Set stack
    ld   hl, TMSTPL     ; Temporary string pool
    ld   (TMSTPT), hl   ; Reset temporary string ptr
    xor  a              ; A = 00
    ld   l, a           ; HL = 0000
    ld   h, a
    ld   (CONTAD), hl   ; No CONTinue
    ld   (FORFLG), a    ; Clear FOR flag
    ld   (FNRGNM), hl   ; Clear FN argument
    push hl             ; HL = 0000
    push bc             ; Put back return
DOAGN:
    ld   hl, (BRKLIN)   ; Get address of code to RUN
    ret                 ; Return to execution driver

PROMPT:
    ld   a, '?'         ; '?'
    call OUTC           ; Output character
    ld   a, ' '         ; Space
    call OUTC           ; Output character
    jp   RINPUT         ; Get input line

.CRUNCH:
    xor  a              ; Tokenise line @ HL to BUFFER
    ld   (DATFLG), a    ; Reset literal flag
    ld   c, 2+3         ; 2 byte number and 3 nulls
    ld   de, BUFFER     ; Start of input buffer
.CRNCLP:
    ld   a, (hl)        ; Get byte
    cp   ' '            ; Is it a space?
    jp   z, .MOVDIR     ; Yes - Copy direct
    ld   b, a           ; Save character
    cp   QUOTE          ; Is it a quote?
    jp   z, .CPYLIT     ; Yes - Copy literal string
    or   a              ; Is it end of buffer?
    jp   z, .ENDBUF     ; Yes - End buffer
    ld   a, (DATFLG)    ; Get data type
    or   a              ; Literal?
    ld   a, (hl)        ; Get byte to copy
    jp   nz, .MOVDIR    ; Literal - Copy direct
    cp   '?'            ; Is it '?' short for PRINT
    ld   a, ZPRINT      ; "PRINT" token
    jp   z, .MOVDIR     ; Yes - replace it
    ld   a, (hl)        ; Get byte again
    cp   '0'            ; Is it less than '0'
    jp   c, .FNDWRD     ; Yes - Look for reserved words
    cp   60             ; ";"+1           ; Is it "0123456789:;" ?
    jp   c, .MOVDIR     ; Yes - copy it direct
.FNDWRD:
    push de             ; Look for reserved words
    ld   de, WORDS-1    ; Point to table
    push bc             ; Save count
    ld   bc, .RETNAD    ; Where to return to
    push bc             ; Save return address
    ld   b, ZEND-1      ; First token value -1
    ld   a, (hl)        ; Get byte
    cp   'a'            ; Less than 'a' ?
    jp   c, .SEARCH     ; Yes - search for words
    cp   'z'+1          ; Greater than 'z' ?
    jp   nc, .SEARCH    ; Yes - search for words
    and  01011111B      ; Force upper case
    ld   (hl), a        ; Replace byte
.SEARCH:
    ld   c, (hl)        ; Search for a word
    ex   de, hl
.GETNXT:
    inc  hl             ; Get next reserved word
    or   (hl)           ; Start of word?
    jp   p, .GETNXT     ; No - move on
    inc  b              ; Increment token value
    ld   a, (hl)        ; Get byte from table
    and  01111111B      ; Strip bit 7
    ret  z              ; Return if end of list
    cp   c              ; Same character as in buffer?
    jp   nz, .GETNXT    ; No - get next word
    ex   de, hl
    push hl             ; Save start of word

.NXTBYT:
    inc  de             ; Look through rest of word
    ld   a, (de)        ; Get byte from table
    or   a              ; End of word ?
    jp   m, .MATCH      ; Yes - Match found
    ld   c, a           ; Save it
    ld   a, b           ; Get token value
    cp   ZGOTO          ; Is it "GOTO" token ?
    jp   nz, .NOSPC     ; No - Don't allow spaces
    call GETCHR         ; Get next character
    dec  hl             ; Cancel increment from GETCHR
.NOSPC:
    inc  hl             ; Next byte
    ld   a, (hl)        ; Get byte
    cp   'a'            ; Less than 'a' ?
    jp   c, .NOCHNG     ; Yes - don't change
    and  01011111B      ; Make upper case
.NOCHNG:
    cp   c              ; Same as in buffer ?
    jp   z, .NXTBYT     ; Yes - keep testing
    pop  hl             ; Get back start of word
    jp   .SEARCH        ; Look at next word

.MATCH:
    ld   c, b           ; Word found - Save token value
    pop  af             ; Throw away return
    ex   de, hl
    ret                 ; Return to ".RETNAD"
.RETNAD:
    ex   de, hl         ; Get address in string
    ld   a, c           ; Get token value
    pop  bc             ; Restore buffer length
    pop  de             ; Get destination address
.MOVDIR:
    inc  hl             ; Next source in buffer
    ld   (de), a        ; Put byte in buffer
    inc  de             ; Move up buffer
    inc  c              ; Increment length of buffer
    sub  ':'            ; End of statement?
    jp   z, .SETLIT     ; Jump if multi-statement line
    cp   ZDATA-0x3A     ; Is it DATA statement ?
    jp   nz, .TSTREM    ; No - see if REM
.SETLIT:
    ld   (DATFLG), a    ; Set literal flag
.TSTREM:
    sub  ZREM-0x3A      ; Is it REM?
    jp   nz, .CRNCLP    ; No - Leave flag
    ld   b, a           ; Copy rest of buffer
.NXTCHR:
    ld   a, (hl)        ; Get byte
    or   a              ; End of line ?
    jp   z, .ENDBUF     ; Yes - Terminate buffer
    cp   b              ; End of statement ?
    jp   z, .MOVDIR     ; Yes - Get next one
.CPYLIT:
    inc  hl             ; Move up source string
    ld   (de), a        ; Save in destination
    inc  c              ; Increment length
    inc  de             ; Move up destination
    jp   .NXTCHR        ; Repeat

.ENDBUF:
    ld   hl, BUFFER-1   ; Point to start of buffer
    ld   (de), a        ; Mark end of buffer (A = 00)
    inc  de
    ld   (de), a        ; A = 00
    inc  de
    ld   (de), a        ; A = 00
    ret

.DODEL:
    ld   a, (NULFLG)    ; Get null flag status
    or   a              ; Is it zero?
    ld   a, 0           ; Zero A - Leave flags
    ld   (NULFLG), a    ; Zero null flag
    jp   nz, .ECHDEL    ; Set - Echo it
    dec  b              ; Decrement length
    jp   z, .GETLIN     ; Get line again if empty
    call OUTC           ; Output null character
    .db  0x3e           ; Skip "DEC B"
.ECHDEL:
    dec  b              ; Count bytes in buffer
    dec  hl             ; Back space buffer
    jp   z, .OTKLN      ; No buffer - Try again
    ld   a, (hl)        ; Get deleted byte
    call OUTC           ; Echo it
    jp   .MORINP        ; Get more input

.DELCHR:
    dec  b              ; Count bytes in buffer
    dec  hl             ; Back space buffer
    call OUTC           ; Output character in A
    jp   nz, .MORINP    ; Not end - Get more
.OTKLN:
    call OUTC           ; Output character in A
.KILIN:
    call PRNTCRLF       ; Output CRLF
    jp   TTYLIN         ; Get line again

.GETLIN:
TTYLIN:
    ld   hl, BUFFER     ; Get a line by character
    ld   b, 1           ; Set buffer as empty
    xor  a
    ld   (NULFLG), a    ; Clear null flag
.MORINP:
    call .CLOTST        ; Get character and test ^O
    ld   c, a           ; Save character in C
    cp   DEL            ; Delete character?
    jp   z, .DODEL      ; Yes - Process it
    ld   a, (NULFLG)    ; Get null flag
    or   a              ; Test null flag status
    jp   z, .PROCES     ; Reset - Process character
    ld   a, 0           ; Set a null
    call OUTC           ; Output null
    xor  a              ; Clear A
    ld   (NULFLG), a    ; Reset null flag
.PROCES:
    ld   a, c           ; Get character
    cp   CTRLG          ; Bell?
    jp   z, .PUTCTL     ; Yes - Save it
    cp   CTRLC          ; Is it control "C"?
    call z, PRNTCRLF    ; Yes - Output CRLF
    scf                 ; Flag break
    ret  z              ; Return if control "C"
    cp   CR             ; Is it enter?
    jp   z, ENDINP      ; Yes - Terminate input
    cp   CTRLU          ; Is it control "U"?
    jp   z, .KILIN      ; Yes - Get another line
    cp   '@'            ; Is it "kill line"?
    jp   z, .OTKLN      ; Yes - Kill line
    cp   '_'            ; Is it delete?
    jp   z, .DELCHR     ; Yes - Delete character
    cp   BKSP           ; Is it backspace?
    jp   z, .DELCHR     ; Yes - Delete character
    cp   CTRLR          ; Is it control "R"?
    jp   nz, .PUTBUF    ; No - Put in buffer
    push bc             ; Save buffer length
    push de             ; Save DE
    push hl             ; Save buffer address
    ld   (hl), 0        ; Mark end of buffer
    call OUTNCR         ; Output and do CRLF
    ld   hl, BUFFER     ; Point to buffer start
    call PRS            ; Output buffer
    pop  hl             ; Restore buffer address
    pop  de             ; Restore DE
    pop  bc             ; Restore buffer length
    jp   .MORINP        ; Get another character

.PUTBUF:
    cp   ' '            ; Is it a control code?
    jp   c, .MORINP     ; Yes - Ignore
.PUTCTL:
    ld   a, b           ; Get number of bytes in buffer
    cp   72+1           ; Test for line overflow
    ld   a, CTRLG       ; Set a bell
    jp   nc, .OUTNBS    ; Ring bell if buffer full
    ld   a, c           ; Get character
    ld   (hl), c        ; Save in buffer
    ld   (LSTBIN), a    ; Save last input byte
    inc  hl             ; Move up buffer
    inc  b              ; Increment length
.OUTIT:
    call OUTC           ; Output the character entered
    jp   .MORINP        ; Get another character

.OUTNBS:
    call OUTC           ; Output bell and back over it
    ld   a, BKSP        ; Set back space
    jp   .OUTIT         ; Output it and get more

CPDEHL:
    ld   a, h           ; Get H
    sub  d              ; Compare with D
    ret  nz             ; Different - Exit
    ld   a, l           ; Get L
    sub  e              ; Compare with E
    ret                 ; Return status

CHKSYN:
    ld   a, (hl)        ; Check syntax of character
    ex   (sp), hl       ; Address of test byte
    cp   (hl)           ; Same as in code string?
    inc  hl             ; Return address
    ex   (sp), hl       ; Put it back
    jp   z, GETCHR      ; Yes - Get next character
    jp   SNERR          ; Different - ?SN Error

OUTC:
    push af             ; Save character
    ld   a, (CTLOFG)    ; Get control "O" flag
    or   a              ; Is it set?
    jp   nz, POPAF      ; Yes - don't output
    pop  af             ; Restore character
    push bc             ; Save buffer length
    push af             ; Save character
    cp   ' '            ; Is it a control code?
    jp   c, .DINPOS     ; Yes - Don't INC POS(X)
    ld   a, (LWIDTH)    ; Get line width
    ld   b, a           ; To B
    ld   a, (CURPOS)    ; Get cursor position
    inc  b              ; Width 255?
    jp   z, .INCLEN     ; Yes - No width limit
    dec  b              ; Restore width
    cp   b              ; At end of line?
    call z, PRNTCRLF    ; Yes - output CRLF
.INCLEN:
    inc  a              ; Move on one character
    ld   (CURPOS), a    ; Save new position
.DINPOS:
    pop  af             ; Restore character
    pop  bc             ; Restore buffer length
    call MONOUT         ; Send it
    ret

.CLOTST:
    call GETINP         ; Get input character
    and  01111111B      ; Strip bit 7
    cp   CTRLO          ; Is it control "O"?
    ret  nz             ; No don't flip flag
    ld   a, (CTLOFG)    ; Get flag
    cpl                 ; Flip it
    ld   (CTLOFG), a    ; Put it back
    xor  a              ; Null character
    ret
