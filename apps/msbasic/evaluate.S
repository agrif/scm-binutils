    ;; see msbasic.h for more info

    #include "msbasic.h"

LIST:
    call ATOH           ; ASCII number to DE
    ret  nz             ; Return if anything extra
    pop  bc             ; Rubbish - Not needed
    call SRCHLN         ; Search for line number in DE
    push bc             ; Save address of line
    call .SETLIN        ; Set up lines counter
.LISTLP:
    pop  hl             ; Restore address of line
    ld   c, (hl)        ; Get LSB of next line
    inc  hl
    ld   b, (hl)        ; Get MSB of next line
    inc  hl
    ld   a, b           ; BC = 0 (End of program)?
    or   c
    jp   z, PRNTOK      ; Yes - Go to command mode
    call .COUNT         ; Count lines
    call .TSTBRK        ; Test for break key
    push bc             ; Save address of next line
    call PRNTCRLF       ; Output CRLF
    ld   e, (hl)        ; Get LSB of line number
    inc  hl
    ld   d, (hl)        ; Get MSB of line number
    inc  hl
    push hl             ; Save address of line start
    ex   de, hl         ; Line number to HL
    call PRNTHL         ; Output line number in decimal
    ld   a, ' '         ; Space after line number
    pop  hl             ; Restore start of line address
.LSTLP2:
    call OUTC           ; Output character in A
.LSTLP3:
    ld   a, (hl)        ; Get next byte in line
    or   a              ; End of line?
    inc  hl             ; To next byte in line
    jp   z, .LISTLP     ; Yes - get next line
    jp   p, .LSTLP2     ; No token - output it
    sub  ZEND-1         ; Find and output word
    ld   c, a           ; Token offset+1 to C
    ld   de, WORDS      ; Reserved word list
.FNDTOK:
    ld   a, (de)        ; Get character in list
    inc  de             ; Move on to next
    or   a              ; Is it start of word?
    jp   p, .FNDTOK     ; No - Keep looking for word
    dec  c              ; Count words
    jp   nz, .FNDTOK    ; Not there - keep looking
.OUTWRD:
    and  01111111B      ; Strip bit 7
    call OUTC           ; Output first character
    ld   a, (de)        ; Get next character
    inc  de             ; Move on to next
    or   a              ; Is it end of word?
    jp   p, .OUTWRD     ; No - output the rest
    jp   .LSTLP3        ; Next byte in line

.SETLIN:
    push hl             ; Set up LINES counter
    ld   hl, (LINESN)   ; Get LINES number
    ld   (LINESC), hl   ; Save in LINES counter
    pop  hl
    ret

.COUNT:
    push hl             ; Save code string address
    push de
    ld   hl, (LINESC)   ; Get LINES counter
    ld   de, 0xffff     ;   <SCC> was -1
    adc  hl, de         ; Decrement
    ld   (LINESC), hl   ; Put it back
    pop  de
    pop  hl             ; Restore code string address
    ret  p              ; Return if more lines to go
    push hl             ; Save code string address
    ld   hl, (LINESN)   ; Get LINES number
    ld   (LINESC), hl   ; Reset LINES counter
    call GETINP         ; Get input character
    cp   CTRLC          ; Is it control "C"?
    jp   z, .RSLNBK     ; Yes - Reset LINES and break
    pop  hl             ; Restore code string address
    jp   .COUNT         ; Keep on counting

.RSLNBK:
    ld   hl, (LINESN)   ; Get LINES number
    ld   (LINESC), hl   ; Reset LINES counter
    jp   BRKRET         ; Go and output "Break"

FOR:
    ld   a, 0x64        ; Flag "FOR" assignment
    ld   (FORFLG), a    ; Save "FOR" flag
    call LET            ; Set up initial index
    pop  bc             ; Drop RETurn address
    push hl             ; Save code string address
    call DATA           ; Get next statement address
    ld   (LOOPST), hl   ; Save it for start of loop
    ld   hl, 2          ; Offset for "FOR" block
    add  hl, SP         ; Point to it
.FORSLP:
    call LOKFOR         ; Look for existing "FOR" block
    pop  de             ; Get code string address
    jp   nz, .FORFND    ; No nesting found
    add  hl, bc         ; Move into "FOR" block
    push de             ; Save code string address
    dec  hl
    ld   d, (hl)        ; Get MSB of loop statement
    dec  hl
    ld   e, (hl)        ; Get LSB of loop statement
    inc  hl
    inc  hl
    push hl             ; Save block address
    ld   hl, (LOOPST)   ; Get address of loop statement
    call CPDEHL         ; Compare the FOR loops
    pop  hl             ; Restore block address
    jp   nz, .FORSLP    ; Different FORs - Find another
    pop  de             ; Restore code string address
    ld   SP, hl         ; Remove all nested loops

.FORFND:
    ex   de, hl         ; Code string address to HL
    ld   c, 8
    call CHKSTK         ; Check for 8 levels of stack
    push hl             ; Save code string address
    ld   hl, (LOOPST)   ; Get first statement of loop
    ex   (sp), hl       ; Save and restore code string
    push hl             ; Re-save code string address
    ld   hl, (LINEAT)   ; Get current line number
    ex   (sp), hl       ; Save and restore code string
    call TSTNUM         ; Make sure it's a number
    call CHKSYN         ; Make sure "TO" is next
    .db  ZTO            ; "TO" token
    call GETNUM         ; Get "TO" expression value
    push hl             ; Save code string address
    call BCDEFP         ; Move "TO" value to BCDE
    pop  hl             ; Restore code string address
    push bc             ; Save "TO" value in block
    push de
    ld   bc, 0x8100     ; BCDE - 1 (default STEP)
    ld   d, c           ; C=0
    ld   e, d           ; D=0
    ld   a, (hl)        ; Get next byte in code string
    cp   ZSTEP          ; See if "STEP" is stated
    ld   a, 1           ; Sign of step = 1
    jp   nz, .SAVSTP    ; No STEP given - Default to 1
    call GETCHR         ; Jump over "STEP" token
    call GETNUM         ; Get step value
    push hl             ; Save code string address
    call BCDEFP         ; Move STEP to BCDE
    call TSTSGN         ; Test sign of FPREG
    pop  hl             ; Restore code string address
.SAVSTP:
    push bc             ; Save the STEP value in block
    push de
    push af             ; Save sign of STEP
    inc  SP             ; Don't save flags
    push hl             ; Save code string address
    ld   hl, (BRKLIN)   ; Get address of index variable
    ex   (sp), hl       ; Save and restore code string
.PUTFID:
    ld   b, ZFOR        ; "FOR" block marker
    push bc             ; Save it
    inc  SP             ; Don't save C

.RUNCNT:
    call .TSTBRK        ; Execution driver - Test break
    ld   (BRKLIN), hl   ; Save code address for break
    ld   a, (hl)        ; Get next byte in code string
    cp   ':'            ; Multi statement line?
    jp   z, EXCUTE      ; Yes - Execute it
    or   a              ; End of line?
    jp   nz, SNERR      ; No - Syntax error
    inc  hl             ; Point to address of next line
    ld   a, (hl)        ; Get LSB of line pointer
    inc  hl
    or   (hl)           ; Is it zero (End of prog)?
    jp   z, .ENDPRG     ; Yes - Terminate execution
    inc  hl             ; Point to line number
    ld   e, (hl)        ; Get LSB of line number
    inc  hl
    ld   d, (hl)        ; Get MSB of line number
    ex   de, hl         ; Line number to HL
    ld   (LINEAT), hl   ; Save as current line number
    ex   de, hl         ; Line number back to DE
EXCUTE:
    call GETCHR         ; Get key word
    ld   de, .RUNCNT    ; Where to RETurn to
    push de             ; Save for RETurn
.IFJMP:
    ret  z              ; Go to .RUNCNT if end of STMT
.ONJMP:
    sub  ZEND           ; Is it a token?
    jp   c, LET         ; No - try to assign it
    cp   ZNEW+1-ZEND    ; END to NEW ?
    jp   nc, SNERR      ; Not a key word - ?SN Error
    rlca                ; Double it
    ld   c, a           ; BC = Offset into table
    ld   b, 0
    ex   de, hl         ; Save code string address
    ld   hl, WORDTB     ; Keyword address table
    add  hl, bc         ; Point to routine address
    ld   c, (hl)        ; Get LSB of routine address
    inc  hl
    ld   b, (hl)        ; Get MSB of routine address
    push bc             ; Save routine address
    ex   de, hl         ; Restore code string address

GETCHR:
    inc  hl             ; Point to next character
    ld   a, (hl)        ; Get next code string byte
    cp   ':'            ; Z if ':'
    ret  nc             ; NC if > "9"
    cp   ' '
    jp   z, GETCHR      ; Skip over spaces
    cp   '0'
    ccf                 ; NC if < '0'
    inc  a              ; Test for zero - Leave carry
    dec  a              ; Z if Null
    ret

RESTOR:
    ex   de, hl         ; Save code string address
    ld   hl, (BASTXT)   ; Point to start of program
    jp   z, .RESTNL     ; Just RESTORE - reset pointer
    ex   de, hl         ; Restore code string address
    call ATOH           ; Get line number to DE
    push hl             ; Save code string address
    call SRCHLN         ; Search for line number in DE
    ld   h, b           ; HL = Address of line
    ld   l, c
    pop  de             ; Restore code string address
    jp   nc, ULERR      ; ?UL Error if not found
.RESTNL:
    dec  hl             ; Byte before DATA statement
.UPDATA:
    ld   (NXTDAT), hl   ; Update DATA pointer
    ex   de, hl         ; Restore code string address
    ret


.TSTBRK:
    rst  0x18           ; Check input status
    ret  z              ; No key, go back
    rst  0x10           ; Get the key into A
    cp   ESC            ; Escape key?
    jr   z, .BRK        ; Yes, break
    cp   CTRLC          ; <Ctrl-C>
    jr   z, .BRK        ; Yes, break
    cp   CTRLS          ; Stop scrolling?
    ret  nz             ; Other key, ignore


.STALL:
    rst  0x10           ; Wait for key
    cp   CTRLQ          ; Resume scrolling?
    ret  z              ; Release the chokehold
    cp   CTRLC          ; Second break?
    jr   z, STOP        ; Break during hold exits prog
    jr   .STALL         ; Loop until <Ctrl-Q> or <brk>

.BRK:
    ld   a, 0xff        ; Set BRKFLG
    ld   (BRKFLG), a    ; Store it


STOP:
    ret  nz             ; Exit if anything else
    .db  0xf6           ; Flag "STOP"
PEND:
    ret  nz             ; Exit if anything else
    ld   (BRKLIN), hl   ; Save point of break
    .db  0x21           ; Skip "OR 11111111B"
.INPBRK:
    or   11111111B      ; Flag "Break" wanted
    pop  bc             ; Return not needed and more
.ENDPRG:
    ld   hl, (LINEAT)   ; Get current line number
    push af             ; Save STOP / END status
    ld   a, l           ; Is it direct break?
    and  h
    inc  a              ; Line is -1 if direct break
    jp   z, .NOLIN      ; Yes - No line number
    ld   (ERRLIN), hl   ; Save line of break
    ld   hl, (BRKLIN)   ; Get point of break
    ld   (CONTAD), hl   ; Save point to CONTinue
.NOLIN:
    xor  a
    ld   (CTLOFG), a    ; Enable output
    call STTLIN         ; Start a new line
    pop  af             ; Restore STOP / END status
    ld   hl, BRKMSG     ; "Break" message
    jp   nz, ERRIN      ; "in line" wanted?
    jp   PRNTOK         ; Go to command mode

CONT:
    ld   hl, (CONTAD)   ; Get CONTinue address
    ld   a, h           ; Is it zero?
    or   l
    ld   e, CN          ; ?CN Error
    jp   z, ERROR       ; Yes - output "?CN Error"
    ex   de, hl         ; Save code string address
    ld   hl, (ERRLIN)   ; Get line of last break
    ld   (LINEAT), hl   ; Set up current line number
    ex   de, hl         ; Restore code string address
    ret                 ; CONTinue where left off

NULL:
    call GETINT         ; Get integer 0-255
    ret  nz             ; Return if bad value
    ld   (NULLS), a     ; Set nulls number
    ret


.ACCSUM:
    push hl             ; Save address in array
    ld   hl, (CHKSUM)   ; Get check sum
    ld   b, 0           ; BC - Value of byte
    ld   c, a
    add  hl, bc         ; Add byte to check sum
    ld   (CHKSUM), hl   ; Re-save check sum
    pop  hl             ; Restore address in array
    ret

.CHKLTR:
    ld   a, (hl)        ; Get byte
    cp   'A'            ; < 'a' ?
    ret  c              ; Carry set if not letter
    cp   'Z'+1          ; > 'z' ?
    ccf
    ret                 ; Carry set if not letter

.FPSINT:
    call GETCHR         ; Get next character
.POSINT:
    call GETNUM         ; Get integer 0 to 32767
DEPINT:
    call TSTSGN         ; Test sign of FPREG
    jp   m, FCERR       ; Negative - ?FC Error
DEINT:
    ld   a, (FPEXP)     ; Get integer value to DE
    cp   0x80+16        ; Exponent in range (16 bits)?
    jp   c, FPINT       ; Yes - convert it
    ld   bc, 0x9080     ; BCDE = -32768
    ld   de, 0x0000
    push hl             ; Save code string address
    call CMPNUM         ; Compare FPREG with BCDE
    pop  hl             ; Restore code string address
    ld   d, c           ; MSB to D
    ret  z              ; Return if in range
FCERR:
    ld   e, FC          ; ?FC Error
    jp   ERROR          ; Output error-

ATOH:
    dec  hl             ; ASCII number to DE binary
.GETLN:
    ld   de, 0          ; Get number to DE
.GTLNLP:
    call GETCHR         ; Get next character
    ret  nc             ; Exit if not a digit
    push hl             ; Save code string address
    push af             ; Save digit
    ld   hl, 6552       ; Largest number 65529   <SCC> was 65529/10
    call CPDEHL         ; Number in range?
    jp   c, SNERR       ; No - ?SN Error
    ld   h, d           ; HL = Number
    ld   l, e
    add  hl, de         ; Times 2
    add  hl, hl         ; Times 4
    add  hl, de         ; Times 5
    add  hl, hl         ; Times 10
    pop  af             ; Restore digit
    sub  '0'            ; Make it 0 to 9
    ld   e, a           ; DE = Value of digit
    ld   d, 0
    add  hl, de         ; Add to number
    ex   de, hl         ; Number to DE
    pop  hl             ; Restore code string address
    jp   .GTLNLP        ; Go to next character

CLEAR:
    jp   z, INTVAR      ; Just "CLEAR" Keep parameters
    call .POSINT        ; Get integer 0 to 32767 to DE
    dec  hl             ; Cancel increment
    call GETCHR         ; Get next character
    push hl             ; Save code string address
    ld   hl, (LSTRAM)   ; Get end of RAM
    jp   z, .STORED     ; No value given - Use stored
    pop  hl             ; Restore code string address
    call CHKSYN         ; Check for comma
    .db  ','
    push de             ; Save number
    call .POSINT        ; Get integer 0 to 32767
    dec  hl             ; Cancel increment
    call GETCHR         ; Get next character
    jp   nz, SNERR      ; ?SN Error if more on line
    ex   (sp), hl       ; Save code string address
    ex   de, hl         ; Number to DE
.STORED:
    ld   a, l           ; Get LSB of new RAM top
    sub  e              ; Subtract LSB of string space
    ld   e, a           ; Save LSB
    ld   a, h           ; Get MSB of new RAM top
    sbc  a, d           ; Subtract MSB of string space
    ld   d, a           ; Save MSB
    jp   c, OMERR       ; ?OM Error if not enough mem
    push hl             ; Save RAM top
    ld   hl, (PROGND)   ; Get program end
    ld   bc, 40         ; 40 Bytes minimum working RAM
    add  hl, bc         ; Get lowest address
    call CPDEHL         ; Enough memory?
    jp   nc, OMERR      ; No - ?OM Error
    ex   de, hl         ; RAM top to HL
    ld   (STRSPC), hl   ; Set new string space
    pop  hl             ; End of memory to use
    ld   (LSTRAM), hl   ; Set new top of RAM
    pop  hl             ; Restore code string address
    jp   INTVAR         ; Initialise variables

RUN:
    jp   z, RUNFST      ; RUN from start if just RUN
    call INTVAR         ; Initialise variables
    ld   bc, .RUNCNT    ; Execution driver loop
    jp   .RUNLIN        ; RUN from line number

GOSUB:
    ld   c, 3           ; 3 Levels of stack needed
    call CHKSTK         ; Check for 3 levels of stack
    pop  bc             ; Get return address
    push hl             ; Save code string for RETURN
    push hl             ; And for GOSUB routine
    ld   hl, (LINEAT)   ; Get current line
    ex   (sp), hl       ; Into stack - Code string out
    ld   a, ZGOSUB      ; "GOSUB" token
    push af             ; Save token
    inc  SP             ; Don't save flags

.RUNLIN:
    push bc             ; Save return address
GOTO:
    call ATOH           ; ASCII number to DE binary
    call REM            ; Get end of line
    push hl             ; Save end of line
    ld   hl, (LINEAT)   ; Get current line
    call CPDEHL         ; Line after current?
    pop  hl             ; Restore end of line
    inc  hl             ; Start of next line
    call c, SRCHLP      ; Line is after current line
    call nc, SRCHLN     ; Line is before current line
    ld   h, b           ; Set up code string address
    ld   l, c
    dec  hl             ; Incremented after
    ret  c              ; Line found
ULERR:
    ld   e, UL          ; ?UL Error
    jp   ERROR          ; Output error message

RETURN:
    ret  nz             ; Return if not just RETURN
    ld   d, -1          ; Flag "GOSUB" search
    call BAKSTK         ; Look "GOSUB" block
    ld   SP, hl         ; Kill all FORs in subroutine
    cp   ZGOSUB         ; Test for "GOSUB" token
    ld   e, RG          ; ?RG Error
    jp   nz, ERROR      ; Error if no "GOSUB" found
    pop  hl             ; Get RETURN line number
    ld   (LINEAT), hl   ; Save as current
    inc  hl             ; Was it from direct statement?
    ld   a, h
    or   l              ; Return to line
    jp   nz, .RETLIN    ; No - Return to line
    ld   a, (LSTBIN)    ; Any INPUT in subroutine?
    or   a              ; If so buffer is corrupted
    jp   nz, POPNOK     ; Yes - Go to command mode
.RETLIN:
    ld   hl, .RUNCNT    ; Execution driver loop
    ex   (sp), hl       ; Into stack - Code string out
    .db  0x3e           ; Skip "POP HL"
.NXTDTA:
    pop  hl             ; Restore code string address

DATA:
    .db  0x01, 0x3a     ; ':' End of statement
REM:
    ld   c, 0           ; 00  End of statement
    ld   b, 0
.NXTSTL:
    ld   a, c           ; Statement and byte
    ld   c, b
    ld   b, a           ; Statement end byte
.NXTSTT:
    ld   a, (hl)        ; Get byte
    or   a              ; End of line?
    ret  z              ; Yes - Exit
    cp   b              ; End of statement?
    ret  z              ; Yes - Exit
    inc  hl             ; Next byte
    cp   QUOTE          ; Literal string?
    jp   z, .NXTSTL     ; Yes - Look for another '"'
    jp   .NXTSTT        ; Keep looking

LET:
    call GETVAR         ; Get variable name
    call CHKSYN         ; Make sure "=" follows
    .db  ZEQUAL         ; "=" token
    push de             ; Save address of variable
    ld   a, (TYPE)      ; Get data type
    push af             ; Save type
    call EVAL           ; Evaluate expression
    pop  af             ; Restore type
    ex   (sp), hl       ; Save code - Get var addr
    ld   (BRKLIN), hl   ; Save address of variable
    rra                 ; Adjust type
    call CHKTYP         ; Check types are the same
    jp   z, .LETNUM     ; Numeric - Move value
.LETSTR:
    push hl             ; Save address of string var
    ld   hl, (FPREG)    ; Pointer to string entry
    push hl             ; Save it on stack
    inc  hl             ; Skip over length
    inc  hl
    ld   e, (hl)        ; LSB of string address
    inc  hl
    ld   d, (hl)        ; MSB of string address
    ld   hl, (BASTXT)   ; Point to start of program
    call CPDEHL         ; Is string before program?
    jp   nc, .CRESTR    ; Yes - Create string entry
    ld   hl, (STRSPC)   ; Point to string space
    call CPDEHL         ; Is string literal in program?
    pop  de             ; Restore address of string
    jp   nc, .MVSTPT    ; Yes - Set up pointer
    ld   hl, TMPSTR     ; Temporary string pool
    call CPDEHL         ; Is string in temporary pool?
    jp   nc, .MVSTPT    ; No - Set up pointer
    .db  0x3e           ; Skip "POP DE"
.CRESTR:
    pop  de             ; Restore address of string
    call BAKTMP         ; Back to last tmp-str entry
    ex   de, hl         ; Address of string entry
    call SAVSTR         ; Save string in string area
.MVSTPT:
    call BAKTMP         ; Back to last tmp-str entry
    pop  hl             ; Get string pointer
    call DETHL4         ; Move string pointer to var
    pop  hl             ; Restore code string address
    ret

.LETNUM:
    push hl             ; Save address of variable
    call FPTHL          ; Move value to variable
    pop  de             ; Restore address of variable
    pop  hl             ; Restore code string address
    ret

ON:
    call GETINT         ; Get integer 0-255
    ld   a, (hl)        ; Get "GOTO" or "GOSUB" token
    ld   b, a           ; Save in B
    cp   ZGOSUB         ; "GOSUB" token?
    jp   z, .ONGO       ; Yes - Find line number
    call CHKSYN         ; Make sure it's "GOTO"
    .db  ZGOTO          ; "GOTO" token
    dec  hl             ; Cancel increment
.ONGO:
    ld   c, e           ; Integer of branch value
.ONGOLP:
    dec  c              ; Count branches
    ld   a, b           ; Get "GOTO" or "GOSUB" token
    jp   z, .ONJMP      ; Go to that line if right one
    call .GETLN         ; Get line number to DE
    cp   ','            ; Another line number?
    ret  nz             ; No - Drop through
    jp   .ONGOLP        ; Yes - loop

IF: call EVAL           ; Evaluate expression
    ld   a, (hl)        ; Get token
    cp   ZGOTO          ; "GOTO" token?
    jp   z, .IFGO       ; Yes - Get line
    call CHKSYN         ; Make sure it's "THEN"
    .db  ZTHEN          ; "THEN" token
    dec  hl             ; Cancel increment
.IFGO:
    call TSTNUM         ; Make sure it's numeric
    call TSTSGN         ; Test state of expression
    jp   z, REM         ; False - Drop through
    call GETCHR         ; Get next character
    jp   c, GOTO        ; Number - GOTO that line
    jp   .IFJMP         ; Otherwise do statement

.MRPRNT:
    dec  hl             ; DEC 'cos GETCHR INCs
    call GETCHR         ; Get next character
PRINT:
    jp   z, PRNTCRLF    ; CRLF if just PRINT
.PRNTLP:
    ret  z              ; End of list - Exit
    cp   ZTAB           ; "TAB(" token?
    jp   z, .DOTAB      ; Yes - Do TAB routine
    cp   ZSPC           ; "SPC(" token?
    jp   z, .DOTAB      ; Yes - Do SPC routine
    push hl             ; Save code string address
    cp   ','            ; Comma?
    jp   z, .DOCOM      ; Yes - Move to next zone
    cp   59             ; ";"         ; Semi-colon?
    jp   z, .NEXITM     ; Do semi-colon routine
    pop  bc             ; Code string address to BC
    call EVAL           ; Evaluate expression
    push hl             ; Save code string address
    ld   a, (TYPE)      ; Get variable type
    or   a              ; Is it a string variable?
    jp   nz, .PRNTST    ; Yes - Output string contents
    call NUMASC         ; Convert number to text
    call CRTST          ; Create temporary string
    ld   (hl), ' '      ; Followed by a space
    ld   hl, (FPREG)    ; Get length of output
    inc  (hl)           ; Plus 1 for the space
    ld   hl, (FPREG)    ; < Not needed >
    ld   a, (LWIDTH)    ; Get width of line
    ld   b, a           ; To B
    inc  b              ; Width 255 (No limit)?
    jp   z, .PRNTNB     ; Yes - Output number string
    inc  b              ; Adjust it
    ld   a, (CURPOS)    ; Get cursor position
    add  a, (hl)        ; Add length of string
    dec  a              ; Adjust it
    cp   b              ; Will output fit on this line?
    call nc, PRNTCRLF   ; No - CRLF first
.PRNTNB:
    call PRS1           ; Output string at (HL)
    xor  a              ; Skip CALL by setting 'z' flag
.PRNTST:
    call nz, PRS1       ; Output string at (HL)
    pop  hl             ; Restore code string address
    jp   .MRPRNT        ; See if more to PRINT

STTLIN:
    ld   a, (CURPOS)    ; Make sure on new line
    or   a              ; Already at start?
    ret  z              ; Yes - Do nothing
    jp   PRNTCRLF       ; Start a new line

ENDINP:
    ld   (hl), 0        ; Mark end of buffer
    ld   hl, BUFFER-1   ; Point to buffer
PRNTCRLF:
    ld   a, CR          ; Load a CR
    call OUTC           ; Output character
    ld   a, LF          ; Load a LF
    call OUTC           ; Output character
DONULL:
    xor  a              ; Set to position 0
    ld   (CURPOS), a    ; Store it
    ld   a, (NULLS)     ; Get number of nulls
.NULLP:
    dec  a              ; Count them
    ret  z              ; Return if done
    push af             ; Save count
    xor  a              ; Load a null
    call OUTC           ; Output it
    pop  af             ; Restore count
    jp   .NULLP         ; Keep counting

.DOCOM:
    ld   a, (COMMAN)    ; Get comma width
    ld   b, a           ; Save in B
    ld   a, (CURPOS)    ; Get current position
    cp   b              ; Within the limit?
    call nc, PRNTCRLF   ; No - output CRLF
    jp   nc, .NEXITM    ; Get next item
.ZONELP:
    sub  14             ; Next zone of 14 characters
    jp   nc, .ZONELP    ; Repeat if more zones
    cpl                 ; Number of spaces to output
    jp   .ASPCS         ; Output them

.DOTAB:
    push af             ; Save token
    call FNDNUM         ; Evaluate expression
    call CHKSYN         ; Make sure ")" follows
    .db  ")"
    dec  hl             ; Back space on to ")"
    pop  af             ; Restore token
    sub  ZSPC           ; Was it "SPC(" ?
    push hl             ; Save code string address
    jp   z, .DOSPC      ; Yes - Do 'E' spaces
    ld   a, (CURPOS)    ; Get current position
.DOSPC:
    cpl                 ; Number of spaces to print to
    add  a, e           ; Total number to print
    jp   nc, .NEXITM    ; TAB < Current POS(X)
.ASPCS:
    inc  a              ; Output A spaces
    ld   b, a           ; Save number to print
    ld   a, ' '         ; Space
.SPCLP:
    call OUTC           ; Output character in A
    dec  b              ; Count them
    jp   nz, .SPCLP     ; Repeat if more
.NEXITM:
    pop  hl             ; Restore code string address
    call GETCHR         ; Get next character
    jp   .PRNTLP        ; More to print

    .section .rodata.redo

.REDO:
    .asciz "?Redo from start\r\n"

    ;; make sure this comes after the above .rodata
    .section .text.badinp

.BADINP:
    ld   a, (READFG)    ; READ or INPUT?
    or   a
    jp   nz, DATSNR     ; READ - ?SN Error
    pop  bc             ; Throw away code string addr
    ld   hl, .REDO      ; "Redo from start" message
    call PRS            ; Output string
    jp   DOAGN          ; Do last INPUT again

INPUT:
    call IDTEST         ; Test for illegal direct
    ld   a, (hl)        ; Get character after "INPUT"
    cp   QUOTE          ; Is there a prompt string?
    ld   a, 0           ; Clear A and leave flags
    ld   (CTLOFG), a    ; Enable output
    jp   nz, .NOPMPT    ; No prompt - get input
    call QTSTR          ; Get string terminated by '"'
    call CHKSYN         ; Check for ';' after prompt
    .db  0x3b           ; ';' <SCC>
    push hl             ; Save code string address
    call PRS1           ; Output prompt string
    .db  0x3e           ; Skip "PUSH HL"
.NOPMPT:
    push hl             ; Save code string address
    call PROMPT         ; Get input with "? " prompt
    pop  bc             ; Restore code string address
    jp   c, .INPBRK     ; Break pressed - Exit
    inc  hl             ; Next byte
    ld   a, (hl)        ; Get it
    or   a              ; End of line?
    dec  hl             ; Back again
    push bc             ; Re-save code string address
    jp   z, .NXTDTA     ; Yes - Find next DATA stmt
    ld   (hl), ','      ; Store comma as separator
    jp   .NXTITM        ; Get next item

READ:
    push hl             ; Save code string address
    ld   hl, (NXTDAT)   ; Next DATA statement
    .db  0xf6           ; Flag "READ"
.NXTITM:
    xor  a              ; Flag "INPUT"
    ld   (READFG), a    ; Save "READ"/"INPUT" flag
    ex   (sp), hl       ; Get code str' , Save pointer
    jp   .GTVLUS        ; Get values

.NEDMOR:
    call CHKSYN         ; Check for comma between items
    .db  ','
.GTVLUS:
    call GETVAR         ; Get variable name
    ex   (sp), hl       ; Save code str" , Get pointer
    push de             ; Save variable address
    ld   a, (hl)        ; Get next "INPUT"/"DATA" byte
    cp   ','            ; Comma?
    jp   z, .ANTVLU     ; Yes - Get another value
    ld   a, (READFG)    ; Is it READ?
    or   a
    jp   nz, .FDTLP     ; Yes - Find next DATA stmt
    ld   a, '?'         ; More INPUT needed
    call OUTC           ; Output character
    call PROMPT         ; Get INPUT with prompt
    pop  de             ; Variable address
    pop  bc             ; Code string address
    jp   c, .INPBRK     ; Break pressed
    inc  hl             ; Point to next DATA byte
    ld   a, (hl)        ; Get byte
    or   a              ; Is it zero (No input) ?
    dec  hl             ; Back space INPUT pointer
    push bc             ; Save code string address
    jp   z, .NXTDTA     ; Find end of buffer
    push de             ; Save variable address
.ANTVLU:
    ld   a, (TYPE)      ; Check data type
    or   a              ; Is it numeric?
    jp   z, .INPBIN     ; Yes - Convert to binary
    call GETCHR         ; Get next character
    ld   d, a           ; Save input character
    ld   b, a           ; Again
    cp   QUOTE          ; Start of literal sting?
    jp   z, .STRENT     ; Yes - Create string entry
    ld   a, (READFG)    ; "READ" or "INPUT" ?
    or   a
    ld   d, a           ; Save 00 if "INPUT"
    jp   z, .ITMSEP     ; "INPUT" - End with 00
    ld   d, ':'         ; "DATA" - End with 00 or ':'
.ITMSEP:
    ld   b, ','         ; Item separator
    dec  hl             ; Back space for DTSTR
.STRENT:
    call DTSTR          ; Get string terminated by D
    ex   de, hl         ; String address to DE
    ld   hl, .LTSTND    ; Where to go after .LETSTR
    ex   (sp), hl       ; Save HL , get input pointer
    push de             ; Save address of string
    jp   .LETSTR        ; Assign string to variable

.INPBIN:
    call GETCHR         ; Get next character
    call ASCTFP         ; Convert ASCII to FP number
    ex   (sp), hl       ; Save input ptr, Get var addr
    call FPTHL          ; Move FPREG to variable
    pop  hl             ; Restore input pointer
.LTSTND:
    dec  hl             ; DEC 'cos GETCHR INCs
    call GETCHR         ; Get next character
    jp   z, .MORDT      ; End of line - More needed?
    cp   ','            ; Another value?
    jp   nz, .BADINP    ; No - Bad input
.MORDT:
    ex   (sp), hl       ; Get code string address
    dec  hl             ; DEC 'cos GETCHR INCs
    call GETCHR         ; Get next character
    jp   nz, .NEDMOR    ; More needed - Get it
    pop  de             ; Restore DATA pointer
    ld   a, (READFG)    ; "READ" or "INPUT" ?
    or   a
    ex   de, hl         ; DATA pointer to HL
    jp   nz, .UPDATA    ; Update DATA pointer if "READ"
    push de             ; Save code string address
    or   (hl)           ; More input given?
    ld   hl, .EXTIG     ; "?Extra ignored" message
    call nz, PRS        ; Output string if extra given
    pop  hl             ; Restore code string address
    ret

    .section .rodata.extig

.EXTIG:
    .asciz "?Extra ignored\r\n"

    ;; make sure this comes after the above .rodata
    .section .text.fdtlp

.FDTLP:
    call DATA           ; Get next statement
    or   a              ; End of line?
    jp   nz, .FANDT     ; No - See if DATA statement
    inc  hl
    ld   a, (hl)        ; End of program?
    inc  hl
    or   (hl)           ; 00 00 Ends program
    ld   e, OD          ; ?OD Error
    jp   z, ERROR       ; Yes - Out of DATA
    inc  hl
    ld   e, (hl)        ; LSB of line number
    inc  hl
    ld   d, (hl)        ; MSB of line number
    ex   de, hl
    ld   (DATLIN), hl   ; Set line of current DATA item
    ex   de, hl
.FANDT:
    call GETCHR         ; Get next character
    cp   ZDATA          ; "DATA" token
    jp   nz, .FDTLP     ; No "DATA" - Keep looking
    jp   .ANTVLU        ; Found - Convert input

NEXT:
    ld   de, 0          ; In case no index given
.NEXT1:
    call nz, GETVAR     ; Get index address
    ld   (BRKLIN), hl   ; Save code string address
    call BAKSTK         ; Look for "FOR" block
    jp   nz, NFERR      ; No "FOR" - ?NF Error
    ld   SP, hl         ; Clear nested loops
    push de             ; Save index address
    ld   a, (hl)        ; Get sign of STEP
    inc  hl
    push af             ; Save sign of STEP
    push de             ; Save index address
    call PHLTFP         ; Move index value to FPREG
    ex   (sp), hl       ; Save address of TO value
    push hl             ; Save address of index
    call ADDPHL         ; Add STEP to index value
    pop  hl             ; Restore address of index
    call FPTHL          ; Move value to index variable
    pop  hl             ; Restore address of TO value
    call LOADFP         ; Move TO value to BCDE
    push hl             ; Save address of line of FOR
    call CMPNUM         ; Compare index with TO value
    pop  hl             ; Restore address of line num
    pop  bc             ; Address of sign of STEP
    sub  b              ; Compare with expected sign
    call LOADFP         ; BC = Loop stmt,DE = Line num
    jp   z, .KILFOR     ; Loop finished - Terminate it
    ex   de, hl         ; Loop statement line number
    ld   (LINEAT), hl   ; Set loop line number
    ld   l, c           ; Set code string to loop
    ld   h, b
    jp   .PUTFID        ; Put back "FOR" and continue

.KILFOR:
    ld   SP, hl         ; Remove "FOR" block
    ld   hl, (BRKLIN)   ; Code string after "NEXT"
    ld   a, (hl)        ; Get next byte in code string
    cp   ','            ; More NEXTs ?
    jp   nz, .RUNCNT    ; No - Do next statement
    call GETCHR         ; Position to index name
    call .NEXT1         ; Re-enter NEXT routine
    ;; < will not RETurn to here , Exit to .RUNCNT or Loop >

GETNUM:
    call EVAL           ; Get a numeric expression
TSTNUM:
    .db  0xf6           ; Clear carry (numeric)
TSTSTR:
    scf                 ; Set carry (string)
CHKTYP:
    ld   a, (TYPE)      ; Check types match
    adc  a, a           ; Expected + actual
    or   a              ; Clear carry , set parity
    ret  pe             ; Even parity - Types match
    jp   TMERR          ; Different types - Error

.OPNPAR:
    call CHKSYN         ; Make sure "(" follows
    .db  "("
EVAL:
    dec  hl             ; Evaluate expression & save
    ld   d, 0           ; Precedence value
.EVAL1:
    push de             ; Save precedence
    ld   c, 1
    call CHKSTK         ; Check for 1 level of stack
    call OPRND          ; Get next expression value
EVAL2:
    ld   (NXTOPR), hl   ; Save address of next operator
.EVAL3:
    ld   hl, (NXTOPR)   ; Restore address of next opr
    pop  bc             ; Precedence value and operator
    ld   a, b           ; Get precedence value
    cp   0x78           ; "AND" or "OR" ?
    call nc, TSTNUM     ; No - Make sure it's a number
    ld   a, (hl)        ; Get next operator / function
    ld   d, 0           ; Clear Last relation
.RLTLP:
    sub  ZGTR           ; ">" Token
    jp   c, .FOPRND     ; + - * / ^ AND OR - Test it
    cp   ZLTH+1-ZGTR    ; < = >
    jp   nc, .FOPRND    ; Function - Call it
    cp   ZEQUAL-ZGTR    ; "="
    rla                 ; <- Test for legal
    xor  d              ; <- combinations of < = >
    cp   d              ; <- by combining last token
    ld   d, a           ; <- with current one
    jp   c, SNERR       ; Error if "<<' '==" or ">>"
    ld   (CUROPR), hl   ; Save address of current token
    call GETCHR         ; Get next character
    jp   .RLTLP         ; Treat the two as one

.FOPRND:
    ld   a, d           ; < = > found ?
    or   a
    jp   nz, .TSTRED    ; Yes - Test for reduction
    ld   a, (hl)        ; Get operator token
    ld   (CUROPR), hl   ; Save operator address
    sub  ZPLUS          ; Operator or function?
    ret  c              ; Neither - Exit
    cp   ZOR+1-ZPLUS    ; Is it + - * / ^ AND OR ?
    ret  nc             ; No - Exit
    ld   e, a           ; Coded operator
    ld   a, (TYPE)      ; Get data type
    dec  a              ; FF = numeric , 00 = string
    or   e              ; Combine with coded operator
    ld   a, e           ; Get coded operator
    jp   z, CONCAT      ; String concatenation
    rlca                ; Times 2
    add  a, e           ; Times 3
    ld   e, a           ; To DE (D is 0)
    ld   hl, PRITAB     ; Precedence table
    add  hl, de         ; To the operator concerned
    ld   a, b           ; Last operator precedence
    ld   d, (hl)        ; Get evaluation precedence
    cp   d              ; Compare with eval precedence
    ret  nc             ; Exit if higher precedence
    inc  hl             ; Point to routine address
    call TSTNUM         ; Make sure it's a number

.STKTHS:
    push bc             ; Save last precedence & token
    ld   bc, .EVAL3     ; Where to go on prec' break
    push bc             ; Save on stack for return
    ld   b, e           ; Save operator
    ld   c, d           ; Save precedence
    call STAKFP         ; Move value to stack
    ld   e, b           ; Restore operator
    ld   d, c           ; Restore precedence
    ld   c, (hl)        ; Get LSB of routine address
    inc  hl
    ld   b, (hl)        ; Get MSB of routine address
    inc  hl
    push bc             ; Save routine address
    ld   hl, (CUROPR)   ; Address of current operator
    jp   .EVAL1         ; Loop until prec' break

OPRND:
    xor  a              ; Get operand routine
    ld   (TYPE), a      ; Set numeric expected
    call GETCHR         ; Get next character
    ld   e, MO          ; ?MO Error
    jp   z, ERROR       ; No operand - Error
    jp   c, ASCTFP      ; Number - Get value
    call .CHKLTR        ; See if a letter
    jp   nc, .CONVAR    ; Letter - Find variable
    cp   '&'            ; &H = HEX, &B = BINARY
    jr   nz, .NOTAMP
    call GETCHR         ; Get next character
    cp   'H'            ; Hex number indicated? [function added]
    jp   z, HEXTFP      ; Convert Hex to FPREG
    cp   'B'            ; Binary number indicated? [function added]
    jp   z, BINTFP      ; Convert Bin to FPREG
    ld   e, SN          ; If neither then a ?SN Error
    jp   z, ERROR       ;
.NOTAMP:
    cp   ZPLUS          ; '+' Token ?
    jp   z, OPRND       ; Yes - Look for operand
    cp   '.'            ; '.' ?
    jp   z, ASCTFP      ; Yes - Create FP number
    cp   ZMINUS         ; '-' Token ?
    jp   z, .MINUS      ; Yes - Do minus
    cp   QUOTE          ; Literal string ?
    jp   z, QTSTR       ; Get string terminated by '"'
    cp   ZNOT           ; "NOT" Token ?
    jp   z, .EVNOT      ; Yes - Eval NOT expression
    cp   ZFN            ; "FN" Token ?
    jp   z, .DOFN       ; Yes - Do FN routine
    sub  ZSGN           ; Is it a function?
    jp   nc, .FNOFST    ; Yes - Evaluate function
.EVLPAR:
    call .OPNPAR        ; Evaluate expression in "()"
    call CHKSYN         ; Make sure ")" follows
    .db  ")"
    ret

.MINUS:
    ld   d, 0x7d        ; '-' precedence
    call .EVAL1         ; Evaluate until prec' break
    ld   hl, (NXTOPR)   ; Get next operator address
    push hl             ; Save next operator address
    call INVSGN         ; Negate value
.RETNUM:
    call TSTNUM         ; Make sure it's a number
    pop  hl             ; Restore next operator address
    ret

.CONVAR:
    call GETVAR         ; Get variable address to DE
.FRMEVL:
    push hl             ; Save code string address
    ex   de, hl         ; Variable address to HL
    ld   (FPREG), hl    ; Save address of variable
    ld   a, (TYPE)      ; Get type
    or   a              ; Numeric?
    call z, PHLTFP      ; Yes - Move contents to FPREG
    pop  hl             ; Restore code string address
    ret

.FNOFST:
    ld   b, 0           ; Get address of function
    rlca                ; Double function offset
    ld   c, a           ; BC = Offset in function table
    push bc             ; Save adjusted token value
    call GETCHR         ; Get next character
    ld   a, c           ; Get adjusted token value
    cp   2*(ZLEFT-ZSGN)-1 ; Adj' LEFT$,RIGHT$ or MID$ ?
    jp   c, .FNVAL      ; No - Do function
    call .OPNPAR        ; Evaluate expression  (X,...
    call CHKSYN         ; Make sure ',' follows
    .db  ','
    call TSTSTR         ; Make sure it's a string
    ex   de, hl         ; Save code string address
    ld   hl, (FPREG)    ; Get address of string
    ex   (sp), hl       ; Save address of string
    push hl             ; Save adjusted token value
    ex   de, hl         ; Restore code string address
    call GETINT         ; Get integer 0-255
    ex   de, hl         ; Save code string address
    ex   (sp), hl       ; Save integer,HL = adj' token
    jp   .GOFUNC        ; Jump to string function

.FNVAL:
    call .EVLPAR        ; Evaluate expression
    ex   (sp), hl       ; HL = Adjusted token value
    ld   de, .RETNUM    ; Return number from function
    push de             ; Save on stack
.GOFUNC:
    ld   bc, FNCTAB     ; Function routine addresses
    add  hl, bc         ; Point to right address
    ld   c, (hl)        ; Get LSB of address
    inc  hl             ;
    ld   h, (hl)        ; Get MSB of address
    ld   l, c           ; Address to HL
    jp   (hl)           ; Jump to function

SGNEXP:
    dec  d              ; Dee to flag negative exponent
    cp   ZMINUS         ; '-' token ?
    ret  z              ; Yes - Return
    cp   '-'            ; '-' ASCII ?
    ret  z              ; Yes - Return
    inc  d              ; Inc to flag positive exponent
    cp   '+'            ; '+' ASCII ?
    ret  z              ; Yes - Return
    cp   ZPLUS          ; '+' token ?
    ret  z              ; Yes - Return
    dec  hl             ; DEC 'cos GETCHR INCs
    ret                 ; Return "NZ"

POR:
    .db  0xf6           ; Flag "OR"
PAND:
    xor  a              ; Flag "AND"
    push af             ; Save "AND" / "OR" flag
    call TSTNUM         ; Make sure it's a number
    call DEINT          ; Get integer -32768 to 32767
    pop  af             ; Restore "AND" / "OR" flag
    ex   de, hl         ; <- Get last
    pop  bc             ; <-  value
    ex   (sp), hl       ; <-  from
    ex   de, hl         ; <-  stack
    call FPBCDE         ; Move last value to FPREG
    push af             ; Save "AND" / "OR" flag
    call DEINT          ; Get integer -32768 to 32767
    pop  af             ; Restore "AND" / "OR" flag
    pop  bc             ; Get value
    ld   a, c           ; Get LSB
    ld   hl, ACPASS     ; Address of save AC as current
    jp   nz, .POR1      ; Jump if OR
    and  e              ; "AND" LSBs
    ld   c, a           ; Save LSB
    ld   a, b           ; Get MBS
    and  d              ; "AND" MSBs
    jp   (hl)           ; Save AC as current (ACPASS)

.POR1:
    or   e              ; "OR" LSBs
    ld   c, a           ; Save LSB
    ld   a, b           ; Get MSB
    or   d              ; "OR" MSBs
    jp   (hl)           ; Save AC as current (ACPASS)

.TSTRED:
    ld   hl, .CMPLOG    ; Logical compare routine
    ld   a, (TYPE)      ; Get data type
    rra                 ; Carry set = string
    ld   a, d           ; Get last precedence value
    rla                 ; Times 2 plus carry
    ld   e, a           ; To E
    ld   d, 0x64        ; Relational precedence
    ld   a, b           ; Get current precedence
    cp   d              ; Compare with last
    ret  nc             ; Eval if last was rel' or log'
    jp   .STKTHS        ; Stack this one and get next

    .section .rodata.cmplog

.CMPLOG:
    .dw  .CMPLG1        ; Compare two values / strings

    ;; make sure this comes after the above .rodata
    .section .text.cmplg1

.CMPLG1:
    ld   a, c           ; Get data type
    or   a
    rra
    pop  bc             ; Get last expression to BCDE
    pop  de
    push af             ; Save status
    call CHKTYP         ; Check that types match
    ld   hl, .CMPRES    ; Result to comparison
    push hl             ; Save for RETurn
    jp   z, CMPNUM      ; Compare values if numeric
    xor  a              ; Compare two strings
    ld   (TYPE), a      ; Set type to numeric
    push de             ; Save string name
    call GSTRCU         ; Get current string
    ld   a, (hl)        ; Get length of string
    inc  hl
    inc  hl
    ld   c, (hl)        ; Get LSB of address
    inc  hl
    ld   b, (hl)        ; Get MSB of address
    pop  de             ; Restore string name
    push bc             ; Save address of string
    push af             ; Save length of string
    call GSTRDE         ; Get second string
    call LOADFP         ; Get address of second string
    pop  af             ; Restore length of string 1
    ld   d, a           ; Length to D
    pop  hl             ; Restore address of string 1
.CMPSTR:
    ld   a, e           ; Bytes of string 2 to do
    or   d              ; Bytes of string 1 to do
    ret  z              ; Exit if all bytes compared
    ld   a, d           ; Get bytes of string 1 to do
    sub  1
    ret  c              ; Exit if end of string 1
    xor  a
    cp   e              ; Bytes of string 2 to do
    inc  a
    ret  nc             ; Exit if end of string 2
    dec  d              ; Count bytes in string 1
    dec  e              ; Count bytes in string 2
    ld   a, (bc)        ; Byte in string 2
    cp   (hl)           ; Compare to byte in string 1
    inc  hl             ; Move up string 1
    inc  bc             ; Move up string 2
    jp   z, .CMPSTR     ; Same - Try next bytes
    ccf                 ; Flag difference (">" or "<")
    jp   FLGDIF         ; "<" gives -1 , ">" gives +1

.CMPRES:
    inc  a              ; Increment current value
    adc  a, a           ; Double plus carry
    pop  bc             ; Get other value
    and  b              ; Combine them
    add  a, -1          ; Carry set if different
    sbc  a, a           ; 00 - Equal , FF - Different
    jp   FLGREL         ; Set current value & continue

.EVNOT:
    ld   d, 0x5a        ; Precedence value for "NOT"
    call .EVAL1         ; Eval until precedence break
    call TSTNUM         ; Make sure it's a number
    call DEINT          ; Get integer -32768 - 32767
    ld   a, e           ; Get LSB
    cpl                 ; Invert LSB
    ld   c, a           ; Save "NOT" of LSB
    ld   a, d           ; Get MSB
    cpl                 ; Invert MSB
    call ACPASS         ; Save AC as current
    pop  bc             ; Clean up stack
    jp   .EVAL3         ; Continue evaluation

.DIMRET:
    dec  hl             ; DEC 'cos GETCHR INCs
    call GETCHR         ; Get next character
    ret  z              ; End of DIM statement
    call CHKSYN         ; Make sure ',' follows
    .db  ','
DIM:
    ld   bc, .DIMRET    ; Return to "DIMRET"
    push bc             ; Save on stack
    .db  0xf6           ; Flag "Create" variable
GETVAR:
    xor  a              ; Find variable address,to DE
    ld   (LCRFLG), a    ; Set locate / create flag
    ld   b, (hl)        ; Get First byte of name
GTFNAM:
    call .CHKLTR        ; See if a letter
    jp   c, SNERR       ; ?SN Error if not a letter
    xor  a
    ld   c, a           ; Clear second byte of name
    ld   (TYPE), a      ; Set type to numeric
    call GETCHR         ; Get next character
    jp   c, .SVNAM2     ; Numeric - Save in name
    call .CHKLTR        ; See if a letter
    jp   c, .CHARTY     ; Not a letter - Check type
.SVNAM2:
    ld   c, a           ; Save second byte of name
.ENDNAM:
    call GETCHR         ; Get next character
    jp   c, .ENDNAM     ; Numeric - Get another
    call .CHKLTR        ; See if a letter
    jp   nc, .ENDNAM    ; Letter - Get another
.CHARTY:
    sub  '$'            ; String variable?
    jp   nz, .NOTSTR    ; No - Numeric variable
    inc  a              ; A = 1 (string type)
    ld   (TYPE), a      ; Set type to string
    rrca                ; A = 0x80 , Flag for string
    add  a, c           ; 2nd byte of name has bit 7 on
    ld   c, a           ; Resave second byte on name
    call GETCHR         ; Get next character
.NOTSTR:
    ld   a, (FORFLG)    ; Array name needed ?
    dec  a
    jp   z, .ARLDSV     ; Yes - Get array name
    jp   p, .NSCFOR     ; No array with "FOR" or "FN"
    ld   a, (hl)        ; Get byte again
    sub  '('            ; Subscripted variable?
    jp   z, .SBSCPT     ; Yes - Sort out subscript

.NSCFOR:
    xor  a              ; Simple variable
    ld   (FORFLG), a    ; Clear "FOR" flag
    push hl             ; Save code string address
    ld   d, b           ; DE = Variable name to find
    ld   e, c
    ld   hl, (FNRGNM)   ; FN argument name
    call CPDEHL         ; Is it the FN argument?
    ld   de, FNARG      ; Point to argument value
    jp   z, POPHRT      ; Yes - Return FN argument value
    ld   hl, (VAREND)   ; End of variables
    ex   de, hl         ; Address of end of search
    ld   hl, (PROGND)   ; Start of variables address
.FNDVAR:
    call CPDEHL         ; End of variable list table?
    jp   z, .CFEVAL     ; Yes - Called from EVAL?
    ld   a, c           ; Get second byte of name
    sub  (hl)           ; Compare with name in list
    inc  hl             ; Move on to first byte
    jp   nz, .FNTHR     ; Different - Find another
    ld   a, b           ; Get first byte of name
    sub  (hl)           ; Compare with name in list
.FNTHR:
    inc  hl             ; Move on to LSB of value
    jp   z, .RETADR     ; Found - Return address
    inc  hl             ; <- Skip
    inc  hl             ; <- over
    inc  hl             ; <- F.P.
    inc  hl             ; <- value
    jp   .FNDVAR        ; Keep looking

.CFEVAL:
    pop  hl             ; Restore code string address
    ex   (sp), hl       ; Get return address
    push de             ; Save address of variable
    ld   de, .FRMEVL    ; Return address in EVAL
    call CPDEHL         ; Called from EVAL ?
    pop  de             ; Restore address of variable
    jp   z, .RETNUL     ; Yes - Return null variable
    ex   (sp), hl       ; Put back return
    push hl             ; Save code string address
    push bc             ; Save variable name
    ld   bc, 6          ; 2 byte name plus 4 byte data
    ld   hl, (ARREND)   ; End of arrays
    push hl             ; Save end of arrays
    add  hl, bc         ; Move up 6 bytes
    pop  bc             ; Source address in BC
    push hl             ; Save new end address
    call MOVUP          ; Move arrays up
    pop  hl             ; Restore new end address
    ld   (ARREND), hl   ; Set new end address
    ld   h, b           ; End of variables to HL
    ld   l, c
    ld   (VAREND), hl   ; Set new end address

.ZEROLP:
    dec  hl             ; Back through to zero variable
    ld   (hl), 0        ; Zero byte in variable
    call CPDEHL         ; Done them all?
    jp   nz, .ZEROLP    ; No - Keep on going
    pop  de             ; Get variable name
    ld   (hl), e        ; Store second character
    inc  hl
    ld   (hl), d        ; Store first character
    inc  hl
.RETADR:
    ex   de, hl         ; Address of variable in DE
    pop  hl             ; Restore code string address
    ret

.RETNUL:
    ld   (FPEXP), a     ; Set result to zero
    ld   hl, ZERBYT     ; Also set a null string
    ld   (FPREG), hl    ; Save for EVAL
    pop  hl             ; Restore code string address
    ret

.SBSCPT:
    push hl             ; Save code string address
    ld   hl, (LCRFLG)   ; Locate/Create and Type
    ex   (sp), hl       ; Save and get code string
    ld   d, a           ; Zero number of dimensions
.SCPTLP:
    push de             ; Save number of dimensions
    push bc             ; Save array name
    call .FPSINT        ; Get subscript (0-32767)
    pop  bc             ; Restore array name
    pop  af             ; Get number of dimensions
    ex   de, hl
    ex   (sp), hl       ; Save subscript value
    push hl             ; Save LCRFLG and TYPE
    ex   de, hl
    inc  a              ; Count dimensions
    ld   d, a           ; Save in D
    ld   a, (hl)        ; Get next byte in code string
    cp   ','            ; Comma (more to come)?
    jp   z, .SCPTLP     ; Yes - More subscripts
    call CHKSYN         ; Make sure ")" follows
    .db  ")"
    ld   (NXTOPR), hl   ; Save code string address
    pop  hl             ; Get LCRFLG and TYPE
    ld   (LCRFLG), hl   ; Restore Locate/create & type
    ld   e, 0           ; Flag not CSAVE* or CLOAD*
    push de             ; Save number of dimensions (D)
    .db  0x11           ; Skip "PUSH HL" and "PUSH AF'

.ARLDSV:
    push hl             ; Save code string address
    push af             ; A = 00 , Flags set = Z,N
    ld   hl, (VAREND)   ; Start of arrays
    .db  0x3e           ; Skip "ADD HL,DE"
.FNDARY:
    add  hl, de         ; Move to next array start
    ex   de, hl
    ld   hl, (ARREND)   ; End of arrays
    ex   de, hl         ; Current array pointer
    call CPDEHL         ; End of arrays found?
    jp   z, .CREARY     ; Yes - Create array
    ld   a, (hl)        ; Get second byte of name
    cp   c              ; Compare with name given
    inc  hl             ; Move on
    jp   nz, .NXTARY    ; Different - Find next array
    ld   a, (hl)        ; Get first byte of name
    cp   b              ; Compare with name given
.NXTARY:
    inc  hl             ; Move on
    ld   e, (hl)        ; Get LSB of next array address
    inc  hl
    ld   d, (hl)        ; Get MSB of next array address
    inc  hl
    jp   nz, .FNDARY    ; Not found - Keep looking
    ld   a, (LCRFLG)    ; Found Locate or Create it?
    or   a
    jp   nz, DDERR      ; Create - ?DD Error
    pop  af             ; Locate - Get number of dim'ns
    ld   b, h           ; BC Points to array dim'ns
    ld   c, l
    jp   z, POPHRT      ; Jump if array load/save
    sub  (hl)           ; Same number of dimensions?
    jp   z, .FINDEL     ; Yes - Find element
BSERR:
    ld   e, BS          ; ?BS Error
    jp   ERROR          ; Output error

.CREARY:
    ld   de, 4          ; 4 Bytes per entry
    pop  af             ; Array to save or 0 dim'ns?
    jp   z, FCERR       ; Yes - ?FC Error
    ld   (hl), c        ; Save second byte of name
    inc  hl
    ld   (hl), b        ; Save first byte of name
    inc  hl
    ld   c, a           ; Number of dimensions to C
    call CHKSTK         ; Check if enough memory
    inc  hl             ; Point to number of dimensions
    inc  hl
    ld   (CUROPR), hl   ; Save address of pointer
    ld   (hl), c        ; Set number of dimensions
    inc  hl
    ld   a, (LCRFLG)    ; Locate of Create?
    rla                 ; Carry set = Create
    ld   a, c           ; Get number of dimensions
.CRARLP:
    ld   bc, 10+1       ; Default dimension size 10
    jp   nc, .DEFSIZ    ; Locate - Set default size
    pop  bc             ; Get specified dimension size
    inc  bc             ; Include zero element
.DEFSIZ:
    ld   (hl), c        ; Save LSB of dimension size
    inc  hl
    ld   (hl), b        ; Save MSB of dimension size
    inc  hl
    push af             ; Save num' of dim'ns an status
    push hl             ; Save address of dim'n size
    call MLDEBC         ; Multiply DE by BC to find
    ex   de, hl         ; amount of mem needed (to DE)
    pop  hl             ; Restore address of dimension
    pop  af             ; Restore number of dimensions
    dec  a              ; Count them
    jp   nz, .CRARLP    ; Do next dimension if more
    push af             ; Save locate/create flag
    ld   b, d           ; MSB of memory needed
    ld   c, e           ; LSB of memory needed
    ex   de, hl
    add  hl, de         ; Add bytes to array start
    jp   c, OMERR       ; Too big - Error
    call ENFMEM         ; See if enough memory
    ld   (ARREND), hl   ; Save new end of array

.ZERARY:
    dec  hl             ; Back through array data
    ld   (hl), 0        ; Set array element to zero
    call CPDEHL         ; All elements zeroed?
    jp   nz, .ZERARY    ; No - Keep on going
    inc  bc             ; Number of bytes + 1
    ld   d, a           ; A=0
    ld   hl, (CUROPR)   ; Get address of array
    ld   e, (hl)        ; Number of dimensions
    ex   de, hl         ; To HL
    add  hl, hl         ; Two bytes per dimension size
    add  hl, bc         ; Add number of bytes
    ex   de, hl         ; Bytes needed to DE
    dec  hl
    dec  hl
    ld   (hl), e        ; Save LSB of bytes needed
    inc  hl
    ld   (hl), d        ; Save MSB of bytes needed
    inc  hl
    pop  af             ; Locate / Create?
    jp   c, .ENDDIM     ; A is 0 , End if create
.FINDEL:
    ld   b, a           ; Find array element
    ld   c, a
    ld   a, (hl)        ; Number of dimensions
    inc  hl
    .db  0x16           ; Skip "POP HL"
.FNDELP:
    pop  hl             ; Address of next dim' size
    ld   e, (hl)        ; Get LSB of dim'n size
    inc  hl
    ld   d, (hl)        ; Get MSB of dim'n size
    inc  hl
    ex   (sp), hl       ; Save address - Get index
    push af             ; Save number of dim'ns
    call CPDEHL         ; Dimension too large?
    jp   nc, BSERR      ; Yes - ?BS Error
    push hl             ; Save index
    call MLDEBC         ; Multiply previous by size
    pop  de             ; Index supplied to DE
    add  hl, de         ; Add index to pointer
    pop  af             ; Number of dimensions
    dec  a              ; Count them
    ld   b, h           ; MSB of pointer
    ld   c, l           ; LSB of pointer
    jp   nz, .FNDELP    ; More - Keep going
    add  hl, hl         ; 4 Bytes per element
    add  hl, hl
    pop  bc             ; Start of array
    add  hl, bc         ; Point to element
    ex   de, hl         ; Address of element to DE
.ENDDIM:
    ld   hl, (NXTOPR)   ; Got code string address
    ret

FRE:
    ld   hl, (ARREND)   ; Start of free memory
    ex   de, hl         ; To DE
    ld   hl, 0          ; End of free memory
    add  hl, SP         ; Current stack value
    ld   a, (TYPE)      ; Dummy argument type
    or   a
    jp   z, .FRENUM     ; Numeric - Free variable space
    call GSTRCU         ; Current string to pool
    call GARBGE         ; Garbage collection
    ld   hl, (STRSPC)   ; Bottom of string space in use
    ex   de, hl         ; To DE
    ld   hl, (STRBOT)   ; Bottom of string space
.FRENUM:
    ld   a, l           ; Get LSB of end
    sub  e              ; Subtract LSB of beginning
    ld   c, a           ; Save difference if C
    ld   a, h           ; Get MSB of end
    sbc  a, d           ; Subtract MSB of beginning
ACPASS:
    ld   b, c           ; Return integer AC
ABPASS:
    ld   d, b           ; Return integer AB
    ld   e, 0
    ld   hl, TYPE       ; Point to type
    ld   (hl), e        ; Set type to numeric
    ld   b, 0x80+16     ; 16 bit integer
    jp   RETINT         ; Return the integr

POS:
    ld   a, (CURPOS)    ; Get cursor position
PASSA:
    ld   b, a           ; Put A into AB
    xor  a              ; Zero A
    jp   ABPASS         ; Return integer AB

DEF:
    call .CHEKFN        ; Get "FN" and name
    call IDTEST         ; Test for illegal direct
    ld   bc, DATA       ; To get next statement
    push bc             ; Save address for RETurn
    push de             ; Save address of function ptr
    call CHKSYN         ; Make sure "(" follows
    .db  "("
    call GETVAR         ; Get argument variable name
    push hl             ; Save code string address
    ex   de, hl         ; Argument address to HL
    dec  hl
    ld   d, (hl)        ; Get first byte of arg name
    dec  hl
    ld   e, (hl)        ; Get second byte of arg name
    pop  hl             ; Restore code string address
    call TSTNUM         ; Make sure numeric argument
    call CHKSYN         ; Make sure ")" follows
    .db  ")"
    call CHKSYN         ; Make sure "=" follows
    .db  ZEQUAL         ; "=" token
    ld   b, h           ; Code string address to BC
    ld   c, l
    ex   (sp), hl       ; Save code str , Get FN ptr
    ld   (hl), c        ; Save LSB of FN code string
    inc  hl
    ld   (hl), b        ; Save MSB of FN code string
    jp   SVSTAD         ; Save address and do function

.DOFN:
    call .CHEKFN        ; Make sure FN follows
    push de             ; Save function pointer address
    call .EVLPAR        ; Evaluate expression in "()"
    call TSTNUM         ; Make sure numeric result
    ex   (sp), hl       ; Save code str , Get FN ptr
    ld   e, (hl)        ; Get LSB of FN code string
    inc  hl
    ld   d, (hl)        ; Get MSB of FN code string
    inc  hl
    ld   a, d           ; And function DEFined?
    or   e
    jp   z, UFERR       ; No - ?UF Error
    ld   a, (hl)        ; Get LSB of argument address
    inc  hl
    ld   h, (hl)        ; Get MSB of argument address
    ld   l, a           ; HL = Arg variable address
    push hl             ; Save it
    ld   hl, (FNRGNM)   ; Get old argument name
    ex   (sp), hl       ;       ; Save old , Get new
    ld   (FNRGNM), hl   ; Set new argument name
    ld   hl, (FNARG+2)  ; Get LSB,NLSB of old arg value
    push hl             ; Save it
    ld   hl, (FNARG)    ; Get MSB,EXP of old arg value
    push hl             ; Save it
    ld   hl, FNARG      ; HL = Value of argument
    push de             ; Save FN code string address
    call FPTHL          ; Move FPREG to argument
    pop  hl             ; Get FN code string address
    call GETNUM         ; Get value from function
    dec  hl             ; DEC 'cos GETCHR INCs
    call GETCHR         ; Get next character
    jp   nz, SNERR      ; Bad character in FN - Error
    pop  hl             ; Get MSB,EXP of old arg
    ld   (FNARG), hl    ; Restore it
    pop  hl             ; Get LSB,NLSB of old arg
    ld   (FNARG+2), hl  ; Restore it
    pop  hl             ; Get name of old arg
    ld   (FNRGNM), hl   ; Restore it
    pop  hl             ; Restore code string address
    ret

IDTEST:
    push hl             ; Save code string address
    ld   hl, (LINEAT)   ; Get current line number
    inc  hl             ; -1 means direct statement
    ld   a, h
    or   l
    pop  hl             ; Restore code string address
    ret  nz             ; Return if in program
    ld   e, ID          ; ?ID Error
    jp   ERROR

.CHEKFN:
    call CHKSYN         ; Make sure FN follows
    .db  ZFN            ; "FN" token
    ld   a, 0x80
    ld   (FORFLG), a    ; Flag FN name to find
    or   (hl)           ; FN name has bit 7 set
    ld   b, a           ; in first byte of name
    call GTFNAM         ; Get FN name
    jp   TSTNUM         ; Make sure numeric function

STR:
    call TSTNUM         ; Make sure it's a number
    call NUMASC         ; Turn number into text
STR1:
    call CRTST          ; Create string entry for it
    call GSTRCU         ; Current string to pool
    ld   bc, .TOPOOL    ; Save in string pool
    push bc             ; Save address on stack

SAVSTR:
    ld   a, (hl)        ; Get string length
    inc  hl
    inc  hl
    push hl             ; Save pointer to string
    call .TESTR         ; See if enough string space
    pop  hl             ; Restore pointer to string
    ld   c, (hl)        ; Get LSB of address
    inc  hl
    ld   b, (hl)        ; Get MSB of address
    call .CRTMST        ; Create string entry
    push hl             ; Save pointer to MSB of addr
    ld   l, a           ; Length of string
    call .TOSTRA        ; Move to string area
    pop  de             ; Restore pointer to MSB
    ret

.MKTMST:
    call .TESTR         ; See if enough string space
.CRTMST:
    ld   hl, TMPSTR     ; Temporary string
    push hl             ; Save it
    ld   (hl), a        ; Save length of string
    inc  hl
SVSTAD:
    inc  hl
    ld   (hl), e        ; Save LSB of address
    inc  hl
    ld   (hl), d        ; Save MSB of address
    pop  hl             ; Restore pointer
    ret

CRTST:
    dec  hl             ; DEC - INCed after
QTSTR:
    ld   b, QUOTE       ; Terminating quote
    ld   d, b           ; Quote to D
DTSTR:
    push hl             ; Save start
    ld   c, -1          ; Set counter to -1
.QTSTLP:
    inc  hl             ; Move on
    ld   a, (hl)        ; Get byte
    inc  c              ; Count bytes
    or   a              ; End of line?
    jp   z, .CRTSTE     ; Yes - Create string entry
    cp   d              ; Terminator D found?
    jp   z, .CRTSTE     ; Yes - Create string entry
    cp   b              ; Terminator B found?
    jp   nz, .QTSTLP    ; No - Keep looking
.CRTSTE:
    cp   QUOTE          ; End with '"'?
    call z, GETCHR      ; Yes - Get next character
    ex   (sp), hl       ; Starting quote
    inc  hl             ; First byte of string
    ex   de, hl         ; To DE
    ld   a, c           ; Get length
    call .CRTMST        ; Create string entry
.TSTOPL:
    ld   de, TMPSTR     ; Temporary string
    ld   hl, (TMSTPT)   ; Temporary string pool pointer
    ld   (FPREG), hl    ; Save address of string ptr
    ld   a, 1
    ld   (TYPE), a      ; Set type to string
    call DETHL4         ; Move string to pool
    call CPDEHL         ; Out of string pool?
    ld   (TMSTPT), hl   ; Save new pointer
    pop  hl             ; Restore code string address
    ld   a, (hl)        ; Get next code byte
    ret  nz             ; Return if pool OK
    ld   e, ST          ; ?ST Error
    jp   ERROR          ; String pool overflow

PRNUMS:
    inc  hl             ; Skip leading space
PRS:
    call CRTST          ; Create string entry for it
PRS1:
    call GSTRCU         ; Current string to pool
    call LOADFP         ; Move string block to BCDE
    inc  e              ; Length + 1
.PRSLP:
    dec  e              ; Count characters
    ret  z              ; End of string
    ld   a, (bc)        ; Get byte to output
    call OUTC           ; Output character in A
    cp   CR             ; Return?
    call z, DONULL      ; Yes - Do nulls
    inc  bc             ; Next byte in string
    jp   .PRSLP         ; More characters to output

.TESTR:
    or   a              ; Test if enough room
    .db  0x0e           ; No garbage collection done
.GRBDON:
    pop  af             ; Garbage collection done
    push af             ; Save status
    ld   hl, (STRSPC)   ; Bottom of string space in use
    ex   de, hl         ; To DE
    ld   hl, (STRBOT)   ; Bottom of string area
    cpl                 ; Negate length (Top down)
    ld   c, a           ; -Length to BC
    ld   b, -1          ; BC = -ve length of string
    add  hl, bc         ; Add to bottom of space in use
    inc  hl             ; Plus one for 2's complement
    call CPDEHL         ; Below string RAM area?
    jp   c, .TESTOS     ; Tidy up if not done else err
    ld   (STRBOT), hl   ; Save new bottom of area
    inc  hl             ; Point to first byte of string
    ex   de, hl         ; Address to DE
POPAF:
    pop  af             ; Throw away status push
    ret

.TESTOS:
    pop  af             ; Garbage collect been done?
    ld   e, OS          ; ?OS Error
    jp   z, ERROR       ; Yes - Not enough string apace
    cp   a              ; Flag garbage collect done
    push af             ; Save status
    ld   bc, .GRBDON    ; Garbage collection done
    push bc             ; Save for RETurn
GARBGE:
    ld   hl, (LSTRAM)   ; Get end of RAM pointer
.GARBLP:
    ld   (STRBOT), hl   ; Reset string pointer
    ld   hl, 0
    push hl             ; Flag no string found
    ld   hl, (STRSPC)   ; Get bottom of string space
    push hl             ; Save bottom of string space
    ld   hl, TMSTPL     ; Temporary string pool
.GRBLP:
    ex   de, hl
    ld   hl, (TMSTPT)   ; Temporary string pool pointer
    ex   de, hl
    call CPDEHL         ; Temporary string pool done?
    ld   bc, .GRBLP     ; Loop until string pool done
    jp   nz, .STPOOL    ; No - See if in string area
    ld   hl, (PROGND)   ; Start of simple variables
.SMPVAR:
    ex   de, hl
    ld   hl, (VAREND)   ; End of simple variables
    ex   de, hl
    call CPDEHL         ; All simple strings done?
    jp   z, .ARRLP      ; Yes - Do string arrays
    ld   a, (hl)        ; Get type of variable
    inc  hl
    inc  hl
    or   a              ; "S" flag set if string
    call .STRADD        ; See if string in string area
    jp   .SMPVAR        ; Loop until simple ones done

.GNXARY:
    pop  bc             ; Scrap address of this array
.ARRLP:
    ex   de, hl
    ld   hl, (ARREND)   ; End of string arrays
    ex   de, hl
    call CPDEHL         ; All string arrays done?
    jp   z, .SCNEND     ; Yes - Move string if found
    call LOADFP         ; Get array name to BCDE
    ld   a, e           ; Get type of array
    push hl             ; Save address of num of dim'ns
    add  hl, bc         ; Start of next array
    or   a              ; Test type of array
    jp   p, .GNXARY     ; Numeric array - Ignore it
    ld   (CUROPR), hl   ; Save address of next array
    pop  hl             ; Get address of num of dim'ns
    ld   c, (hl)        ; BC = Number of dimensions
    ld   b, 0
    add  hl, bc         ; Two bytes per dimension size
    add  hl, bc
    inc  hl             ; Plus one for number of dim'ns
.GRBARY:
    ex   de, hl
    ld   hl, (CUROPR)   ; Get address of next array
    ex   de, hl
    call CPDEHL         ; Is this array finished?
    jp   z, .ARRLP      ; Yes - Get next one
    ld   bc, .GRBARY    ; Loop until array all done
.STPOOL:
    push bc             ; Save return address
    or   0x80           ; Flag string type
.STRADD:
    ld   a, (hl)        ; Get string length
    inc  hl
    inc  hl
    ld   e, (hl)        ; Get LSB of string address
    inc  hl
    ld   d, (hl)        ; Get MSB of string address
    inc  hl
    ret  p              ; Not a string - Return
    or   a              ; Set flags on string length
    ret  z              ; Null string - Return
    ld   b, h           ; Save variable pointer
    ld   c, l
    ld   hl, (STRBOT)   ; Bottom of new area
    call CPDEHL         ; String been done?
    ld   h, b           ; Restore variable pointer
    ld   l, c
    ret  c              ; String done - Ignore
    pop  hl             ; Return address
    ex   (sp), hl       ; Lowest available string area
    call CPDEHL         ; String within string area?
    ex   (sp), hl       ; Lowest available string area
    push hl             ; Re-save return address
    ld   h, b           ; Restore variable pointer
    ld   l, c
    ret  nc             ; Outside string area - Ignore
    pop  bc             ; Get return , Throw 2 away
    pop  af             ;
    pop  af             ;
    push hl             ; Save variable pointer
    push de             ; Save address of current
    push bc             ; Put back return address
    ret                 ; Go to it

.SCNEND:
    pop  de             ; Addresses of strings
    pop  hl             ;
    ld   a, l           ; HL = 0 if no more to do
    or   h
    ret  z              ; No more to do - Return
    dec  hl
    ld   b, (hl)        ; MSB of address of string
    dec  hl
    ld   c, (hl)        ; LSB of address of string
    push hl             ; Save variable address
    dec  hl
    dec  hl
    ld   l, (hl)        ; HL = Length of string
    ld   h, 0
    add  hl, bc         ; Address of end of string+1
    ld   d, b           ; String address to DE
    ld   e, c
    dec  hl             ; Last byte in string
    ld   b, h           ; Address to BC
    ld   c, l
    ld   hl, (STRBOT)   ; Current bottom of string area
    call MOVSTR         ; Move string to new address
    pop  hl             ; Restore variable address
    ld   (hl), c        ; Save new LSB of address
    inc  hl
    ld   (hl), b        ; Save new MSB of address
    ld   l, c           ; Next string area+1 to HL
    ld   h, b
    dec  hl             ; Next string area address
    jp   .GARBLP        ; Look for more strings

CONCAT:
    push bc             ; Save prec' opr & code string
    push hl             ;
    ld   hl, (FPREG)    ; Get first string
    ex   (sp), hl       ; Save first string
    call OPRND          ; Get second string
    ex   (sp), hl       ; Restore first string
    call TSTSTR         ; Make sure it's a string
    ld   a, (hl)        ; Get length of second string
    push hl             ; Save first string
    ld   hl, (FPREG)    ; Get second string
    push hl             ; Save second string
    add  a, (hl)        ; Add length of second string
    ld   e, LS          ; ?LS Error
    jp   c, ERROR       ; String too long - Error
    call .MKTMST        ; Make temporary string
    pop  de             ; Get second string to DE
    call GSTRDE         ; Move to string pool if needed
    ex   (sp), hl       ; Get first string
    call .GSTRHL        ; Move to string pool if needed
    push hl             ; Save first string
    ld   hl, (TMPSTR+2) ; Temporary string address
    ex   de, hl         ; To DE
    call .SSTSA         ; First string to string area
    call .SSTSA         ; Second string to string area
    ld   hl, EVAL2      ; Return to evaluation loop
    ex   (sp), hl       ; Save return,get code string
    push hl             ; Save code string address
    jp   .TSTOPL        ; To temporary string to pool

.SSTSA:
    pop  hl             ; Return address
    ex   (sp), hl       ; Get string block,save return
    ld   a, (hl)        ; Get length of string
    inc  hl
    inc  hl
    ld   c, (hl)        ; Get LSB of string address
    inc  hl
    ld   b, (hl)        ; Get MSB of string address
    ld   l, a           ; Length to L
.TOSTRA:
    inc  l              ; INC - DECed after
.TSALP:
    dec  l              ; Count bytes moved
    ret  z              ; End of string - Return
    ld   a, (bc)        ; Get source
    ld   (de), a        ; Save destination
    inc  bc             ; Next source
    inc  de             ; Next destination
    jp   .TSALP         ; Loop until string moved

.GETSTR:
    call TSTSTR         ; Make sure it's a string
GSTRCU:
    ld   hl, (FPREG)    ; Get current string
.GSTRHL:
    ex   de, hl         ; Save DE
GSTRDE:
    call BAKTMP         ; Was it last tmp-str?
    ex   de, hl         ; Restore DE
    ret  nz             ; No - Return
    push de             ; Save string
    ld   d, b           ; String block address to DE
    ld   e, c
    dec  de             ; Point to length
    ld   c, (hl)        ; Get string length
    ld   hl, (STRBOT)   ; Current bottom of string area
    call CPDEHL         ; Last one in string area?
    jp   nz, .POPHL     ; No - Return
    ld   b, a           ; Clear B (A=0)
    add  hl, bc         ; Remove string from str' area
    ld   (STRBOT), hl   ; Save new bottom of str' area
.POPHL:
    pop  hl             ; Restore string
    ret

BAKTMP:
    ld   hl, (TMSTPT)   ; Get temporary string pool top
    dec  hl             ; Back
    ld   b, (hl)        ; Get MSB of address
    dec  hl             ; Back
    ld   c, (hl)        ; Get LSB of address
    dec  hl             ; Back
    dec  hl             ; Back
    call CPDEHL         ; String last in string pool?
    ret  nz             ; Yes - Leave it
    ld   (TMSTPT), hl   ; Save new string pool top
    ret

LEN:
    ld   bc, PASSA      ; To return integer A
    push bc             ; Save address
.GETLEN:
    call .GETSTR        ; Get string and its length
    xor  a
    ld   d, a           ; Clear D
    ld   (TYPE), a      ; Set type to numeric
    ld   a, (hl)        ; Get length of string
    or   a              ; Set status flags
    ret

ASC:
    ld   bc, PASSA      ; To return integer A
    push bc             ; Save address
.GTFLNM:
    call .GETLEN        ; Get length of string
    jp   z, FCERR       ; Null string - Error
    inc  hl
    inc  hl
    ld   e, (hl)        ; Get LSB of address
    inc  hl
    ld   d, (hl)        ; Get MSB of address
    ld   a, (de)        ; Get first byte of string
    ret

CHR:
    ld   a, 1           ; One character string
    call .MKTMST        ; Make a temporary string
    call .MAKINT        ; Make it integer A
    ld   hl, (TMPSTR+2) ; Get address of string
    ld   (hl), e        ; Save character
.TOPOOL:
    pop  bc             ; Clean up stack
    jp   .TSTOPL        ; Temporary string to pool

LEFT:
    call .LFRGNM        ; Get number and ending ")"
    xor  a              ; Start at first byte in string
.RIGHT1:
    ex   (sp), hl       ; Save code string,Get string
    ld   c, a           ; Starting position in string
.MID1:
    push hl             ; Save string block address
    ld   a, (hl)        ; Get length of string
    cp   b              ; Compare with number given
    jp   c, .ALLFOL     ; All following bytes required
    ld   a, b           ; Get new length
    .db  0x11           ; Skip "LD C,0"
.ALLFOL:
    ld   c, 0           ; First byte of string
    push bc             ; Save position in string
    call .TESTR         ; See if enough string space
    pop  bc             ; Get position in string
    pop  hl             ; Restore string block address
    push hl             ; And re-save it
    inc  hl
    inc  hl
    ld   b, (hl)        ; Get LSB of address
    inc  hl
    ld   h, (hl)        ; Get MSB of address
    ld   l, b           ; HL = address of string
    ld   b, 0           ; BC = starting address
    add  hl, bc         ; Point to that byte
    ld   b, h           ; BC = source string
    ld   c, l
    call .CRTMST        ; Create a string entry
    ld   l, a           ; Length of new string
    call .TOSTRA        ; Move string to string area
    pop  de             ; Clear stack
    call GSTRDE         ; Move to string pool if needed
    jp   .TSTOPL        ; Temporary string to pool

RIGHT:
    call .LFRGNM        ; Get number and ending ")"
    pop  de             ; Get string length
    push de             ; And re-save
    ld   a, (de)        ; Get length
    sub  b              ; Move back N bytes
    jp   .RIGHT1        ; Go and get sub-string

MID:
    ex   de, hl         ; Get code string address
    ld   a, (hl)        ; Get next byte ',' or ")"
    call .MIDNUM        ; Get number supplied
    inc  b              ; Is it character zero?
    dec  b
    jp   z, FCERR       ; Yes - Error
    push bc             ; Save starting position
    ld   e, 255         ; All of string
    cp   ')'            ; Any length given?
    jp   z, .RSTSTR     ; No - Rest of string
    call CHKSYN         ; Make sure ',' follows
    .db  ','
    call GETINT         ; Get integer 0-255
.RSTSTR:
    call CHKSYN         ; Make sure ")" follows
    .db  ")"
    pop  af             ; Restore starting position
    ex   (sp), hl       ; Get string,8ave code string
    ld   bc, .MID1      ; Continuation of MID$ routine
    push bc             ; Save for return
    dec  a              ; Starting position-1
    cp   (hl)           ; Compare with length
    ld   b, 0           ; Zero bytes length
    ret  nc             ; Null string if start past end
    ld   c, a           ; Save starting position-1
    ld   a, (hl)        ; Get length of string
    sub  c              ; Subtract start
    cp   e              ; Enough string for it?
    ld   b, a           ; Save maximum length available
    ret  c              ; Truncate string if needed
    ld   b, e           ; Set specified length
    ret                 ; Go and create string

VAL:
    call .GETLEN        ; Get length of string
    jp   z, RESZER      ; Result zero
    ld   e, a           ; Save length
    inc  hl
    inc  hl
    ld   a, (hl)        ; Get LSB of address
    inc  hl
    ld   h, (hl)        ; Get MSB of address
    ld   l, a           ; HL = String address
    push hl             ; Save string address
    add  hl, de
    ld   b, (hl)        ; Get end of string+1 byte
    ld   (hl), d        ; Zero it to terminate
    ex   (sp), hl       ; Save string end,get start
    push bc             ; Save end+1 byte
    ld   a, (hl)        ; Get starting byte
    cp   '$'            ; Hex number indicated? [function added]
    jp   nz, .VAL1
    call HEXTFP         ; Convert Hex to FPREG
    jr   .VAL3
.VAL1:
    cp   '%'            ; Binary number indicated? [function added]
    jp   nz, .VAL2
    call BINTFP         ; Convert Bin to FPREG
    jr   .VAL3
.VAL2:
    call ASCTFP         ; Convert ASCII string to FP
.VAL3:
    pop  bc             ; Restore end+1 byte
    pop  hl             ; Restore end+1 address
    ld   (hl), b        ; Put back original byte
    ret

.LFRGNM:
    ex   de, hl         ; Code string address to HL
    call CHKSYN         ; Make sure ")" follows
    .db  ")"
.MIDNUM:
    pop  bc             ; Get return address
    pop  de             ; Get number supplied
    push bc             ; Re-save return address
    ld   b, e           ; Number to B
    ret

INP:
    call .MAKINT        ; Make it integer A
    ld   (INPORT), a    ; Set input port
    call INPSUB         ; Get input from port
    jp   PASSA          ; Return integer A

POUT:
    call .SETIO         ; Set up port number
    jp   OUTSUB         ; Output data and return

WAIT:
    call .SETIO         ; Set up port number
    push af             ; Save AND mask
    ld   e, 0           ; Assume zero if none given
    dec  hl             ; DEC 'cos GETCHR INCs
    call GETCHR         ; Get next character
    jp   z, .NOXOR      ; No XOR byte given
    call CHKSYN         ; Make sure ',' follows
    .db  ','
    call GETINT         ; Get integer 0-255 to XOR with
.NOXOR:
    pop  bc             ; Restore AND mask
.WAITLP:
    call INPSUB         ; Get input
    xor  e              ; Flip selected bits
    and  b              ; Result non-zero?
    jp   z, .WAITLP     ; No = keep waiting
    ret

.SETIO:
    call GETINT         ; Get integer 0-255
    ld   (INPORT), a    ; Set input port
    ld   (OTPORT), a    ; Set output port
    call CHKSYN         ; Make sure ',' follows
    .db  ','
    jp   GETINT         ; Get integer 0-255 and return

FNDNUM:
    call GETCHR         ; Get next character
GETINT:
    call GETNUM         ; Get a number from 0 to 255
.MAKINT:
    call DEPINT         ; Make sure value 0 - 255
    ld   a, d           ; Get MSB of number
    or   a              ; Zero?
    jp   nz, FCERR      ; No - Error
    dec  hl             ; DEC 'cos GETCHR INCs
    call GETCHR         ; Get next character
    ld   a, e           ; Get number to A
    ret

PEEK:
    call DEINT          ; Get memory address
    ld   a, (de)        ; Get byte in memory
    jp   PASSA          ; Return integer A

POKE:
    call GETNUM         ; Get memory address
    call DEINT          ; Get integer -32768 to 3276
    push de             ; Save memory address
    call CHKSYN         ; Make sure ',' follows
    .db  ','
    call GETINT         ; Get integer 0-255
    pop  de             ; Restore memory address
    ld   (de), a        ; Load it into memory
    ret
