    ;; see msbasic.h for more info
    ;; BASIC WORK SPACE LOCATIONS

    .data

    ;; INITIALISATION TABLE --------------------------------------------------

    ;; BASIC Work space    <SCC> original 0x2045
WRKSPC:
    jp   WARMST         ; Warm start jump
USR:
    jp   FCERR          ; "USR (X)" jump (Set to Error)
OUTSUB:
    out  (0), a         ; "OUT p,n" skeleton
    .equ OTPORT, $ - 1  ; Port (p)
    ret
DIVSUP:
    sub  0              ; Division support routine
    .equ DIV1, $ - 1    ; <- Values
    ld   l, a
    ld   a, h
    sbc  a, 0
    .equ DIV2, $ - 1    ; <-   to
    ld   h, a
    ld   a, b
    sbc  a, 0
    .equ DIV3, $ - 1    ; <-   be
    ld   b, a
    ld   a, 0
    .equ DIV4, $ - 1    ; <-inserted
    ret
SEED:
    .db  0, 0, 0        ; Random number seed table used by RND
    .db  0x35, 0x4a, 0xca, 0x99 ; -2.65145E+07
    .db  0x39, 0x1c, 0x76, 0x98 ; 1.61291E+07
    .db  0x22, 0x95, 0xb3, 0x98 ; -1.17691E+07
    .db  0x0a, 0xdd, 0x47, 0x98 ; 1.30983E+07
    .db  0x53, 0xd1, 0x99, 0x99 ; -2-01612E+07
    .db  0x0a, 0x1a, 0x9f, 0x98 ; -1.04269E+07
    .db  0x65, 0xbc, 0xcd, 0x98 ; -1.34831E+07
    .db  0xd6, 0x77, 0x3e, 0x98 ; 1.24825E+07
LSTRND:
    .db  0x52, 0xc7, 0x4f, 0x80 ; Last random number
INPSUB:
    in   a, (0)         ; INP (x) skeleton
    .equ INPORT, $ - 1  ; PORT (x)
    ret
NULLS:
    .db  1              ; Number of nulls, POS (x) number (1)
LWIDTH:
    .db  255            ; Terminal width (255 = no auto CRLF)
COMMAN:
    .db  28             ; Width for commas (3 columns)
NULFLG:
    .db  0              ; Null after input byte flag: not set
CTLOFG:
    .db  0              ; Control "O" flag: Output enabled (^O off)
LINESC:
    .dw  20             ; Initial lines counter
LINESN:
    .dw  20             ; Initial lines number
CHKSUM:
    .dw  0              ; Array load/save check sum
NMIFLG:
    .db  0              ; Flag for NMI break routine: not set
BRKFLG:
    .db  0              ; Break flag
RINPUT:
    jp   TTYLIN         ; Input reflection (set to TTY)
POINT:
    jp   0              ; POINT reflection unused
PSET:
    jp   0              ; SET reflection
RESET:
    jp   0              ; RESET reflection
STRSPC:
    .dw  STLOOK         ; Bottom of string space
LINEAT:
    .dw  0xfffe         ; Current line number (cold)   <SCC> was -2
BASTXT:
    .dw  PROGST+1       ; Start of program text

    ;; END OF INITIALISATION TABLE -------------------------------------------

    .bss

    .skip 1
BUFFER:
    .skip 5             ; Input buffer
STACK:
    .skip 69            ; Initial stack
CURPOS:
    .skip 1             ; Character position on line
LCRFLG:
    .skip 1             ; Locate/Create flag
TYPE:
    .skip 1             ; Data type flag
DATFLG:
    .skip 1             ; Literal statement flag
LSTRAM:
    .skip 2             ; Last available RAM
TMSTPT:
    .skip 2             ; Temporary string pointer
TMSTPL:
    .skip 12            ; Temporary string pool
TMPSTR:
    .skip 4             ; Temporary string
STRBOT:
    .skip 2             ; Bottom of string space
CUROPR:
    .skip 2             ; Current operator in EVAL
LOOPST:
    .skip 2             ; First statement of loop
DATLIN:
    .skip 2             ; Line of current DATA item
FORFLG:
    .skip 1             ; "FOR" loop flag
LSTBIN:
    .skip 1             ; Last byte entered
READFG:
    .skip 1             ; Read/Input flag
BRKLIN:
    .skip 2             ; Line of break
NXTOPR:
    .skip 2             ; Next operator in EVAL
ERRLIN:
    .skip 2             ; Line of error
CONTAD:
    .skip 2             ; Where to CONTinue
PROGND:
    .skip 2             ; End of program
VAREND:
    .skip 2             ; End of variables
ARREND:
    .skip 2             ; End of arrays
NXTDAT:
    .skip 2             ; Next data item
FNRGNM:
    .skip 2             ; Name of FN argument
FNARG:
    .skip 4             ; FN argument value
FPREG:
    .skip 4             ; Floating point register
    .equ FPEXP, $ - 1   ; Floating point exponent
SGNRES:
    .skip 1             ; Sign of result
PBUFF:
    .skip 13            ; Number print buffer
MULVAL:
    .skip 3             ; Multiplier
PROGST:
    .skip 100           ; Start of program text area
STLOOK:
    ;; Start of memory test
