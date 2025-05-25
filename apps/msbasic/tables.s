    ;; see msbasic.h for more info

    .section .init.rodata

    ;; FUNCTION ADDRESS TABLE

FNCTAB:
    .dw  SGN
    .dw  INT
    .dw  ABS
    .dw  USR
    .dw  FRE
    .dw  INP
    .dw  POS
    .dw  SQR
    .dw  RND
    .dw  LOG
    .dw  EXP
    .dw  COS
    .dw  SIN
    .dw  TAN
    .dw  ATN
    .dw  PEEK
    .dw  DEEK
    .dw  POINT
    .dw  LEN
    .dw  STR
    .dw  VAL
    .dw  ASC
    .dw  CHR
    .dw  HEX
    .dw  BIN
    .dw  LEFT
    .dw  RIGHT
    .dw  MID

    ;; RESERVED WORD LIST

WORDS:
    .db  'E'+0x80, "ND"
    .db  'F'+0x80, "OR"
    .db  'N'+0x80, "EXT"
    .db  'D'+0x80, "ATA"
    .db  'I'+0x80, "NPUT"
    .db  'D'+0x80, "IM"
    .db  'R'+0x80, "EAD"
    .db  'L'+0x80, "ET"
    .db  'G'+0x80, "OTO"
    .db  'R'+0x80, "UN"
    .db  'I'+0x80, "F"
    .db  'R'+0x80, "ESTORE"
    .db  'G'+0x80, "OSUB"
    .db  'R'+0x80, "ETURN"
    .db  'R'+0x80, "EM"
    .db  'S'+0x80, "TOP"
    .db  'O'+0x80, "UT"
    .db  'O'+0x80, "N"
    .db  'N'+0x80, "ULL"
    .db  'W'+0x80, "AIT"
    .db  'D'+0x80, "EF"
    .db  'P'+0x80, "OKE"
    .db  'D'+0x80, "OKE"
    .db  'S'+0x80, "CREEN"
    .db  'L'+0x80, "INES"
    .db  'C'+0x80, "LS"
    .db  'W'+0x80, "IDTH"
    .db  'M'+0x80, "ONITOR"
    .db  'S'+0x80, "ET"
    .db  'R'+0x80, "ESET"
    .db  'P'+0x80, "RINT"
    .db  'C'+0x80, "ONT"
    .db  'L'+0x80, "IST"
    .db  'C'+0x80, "LEAR"
    .db  'C'+0x80, "LOAD"
    .db  'C'+0x80, "SAVE"
    .db  'N'+0x80, "EW"

    .db  'T'+0x80, "AB("
    .db  'T'+0x80, "O"
    .db  'F'+0x80, "N"
    .db  'S'+0x80, "PC("
    .db  'T'+0x80, "HEN"
    .db  'N'+0x80, "OT"
    .db  'S'+0x80, "TEP"

    .db  '+'+0x80
    .db  '-'+0x80
    .db  '*'+0x80
    .db  '/'+0x80
    .db  '^'+0x80
    .db  'A'+0x80, "ND"
    .db  'O'+0x80, "R"
    .db  '>'+0x80
    .db  '='+0x80
    .db  '<'+0x80

    .db  'S'+0x80, "GN"
    .db  'I'+0x80, "NT"
    .db  'A'+0x80, "BS"
    .db  'U'+0x80, "SR"
    .db  'F'+0x80, "RE"
    .db  'I'+0x80, "NP"
    .db  'P'+0x80, "OS"
    .db  'S'+0x80, "QR"
    .db  'R'+0x80, "ND"
    .db  'L'+0x80, "OG"
    .db  'E'+0x80, "XP"
    .db  'C'+0x80, "OS"
    .db  'S'+0x80, "IN"
    .db  'T'+0x80, "AN"
    .db  'A'+0x80, "TN"
    .db  'P'+0x80, "EEK"
    .db  'D'+0x80, "EEK"
    .db  'P'+0x80, "OINT"
    .db  'L'+0x80, "EN"
    .db  'S'+0x80, "TR$"
    .db  'V'+0x80, "AL"
    .db  'A'+0x80, "SC"
    .db  'C'+0x80, "HR$"
    .db  'H'+0x80, "EX$"
    .db  'B'+0x80, "IN$"
    .db  'L'+0x80, "EFT$"
    .db  'R'+0x80, "IGHT$"
    .db  'M'+0x80, "ID$"
    .db  0x80           ; End of list marker

    ;; KEYWORD ADDRESS TABLE

WORDTB:
    .dw  PEND
    .dw  FOR
    .dw  NEXT
    .dw  DATA
    .dw  INPUT
    .dw  DIM
    .dw  READ
    .dw  LET
    .dw  GOTO
    .dw  RUN
    .dw  IF
    .dw  RESTOR
    .dw  GOSUB
    .dw  RETURN
    .dw  REM
    .dw  STOP
    .dw  POUT
    .dw  ON
    .dw  NULL
    .dw  WAIT
    .dw  DEF
    .dw  POKE
    .dw  DOKE
    .dw  REM
    .dw  LINES
    .dw  CLS
    .dw  WIDTH
    .dw  MONITR
    .dw  PSET
    .dw  RESET
    .dw  PRINT
    .dw  CONT
    .dw  LIST
    .dw  CLEAR
    .dw  REM
    .dw  REM
    .dw  NEW

    ;; ARITHMETIC PRECEDENCE TABLE

PRITAB:
    .db  0x79           ; Precedence value
    .dw  PADD           ; FPREG = <last> + FPREG

    .db  0x79           ; Precedence value
    .dw  PSUB           ; FPREG = <last> - FPREG

    .db  0x7c           ; Precedence value
    .dw  MULT           ; PPREG = <last> * FPREG

    .db  0x7c           ; Precedence value
    .dw  DIV            ; FPREG = <last> / FPREG

    .db  0x7f           ; Precedence value
    .dw  POWER          ; FPREG = <last> ^ FPREG

    .db  0x50           ; Precedence value
    .dw  PAND           ; FPREG = <last> AND FPREG

    .db  0x46           ; Precedence value
    .dw  POR            ; FPREG = <last> OR FPREG

    ;; BASIC ERROR CODE LIST

ERRORS:
    .ascii "NF"         ; NEXT without FOR
    .ascii "SN"         ; Syntax error
    .ascii "RG"         ; RETURN without GOSUB
    .ascii "OD"         ; Out of DATA
    .ascii "FC"         ; Illegal function call
    .ascii "OV"         ; Overflow error
    .ascii "OM"         ; Out of memory
    .ascii "UL"         ; Undefined line
    .ascii "BS"         ; Bad subscript
    .ascii "DD"         ; Re-DIMensioned array
    .ascii "/0"         ; Division by zero
    .ascii "ID"         ; Illegal direct
    .ascii "TM"         ; Type mis-match
    .ascii "OS"         ; Out of string space
    .ascii "LS"         ; String too long
    .ascii "ST"         ; String formula too complex
    .ascii "CN"         ; Can't CONTinue
    .ascii "UF"         ; Undefined FN function
    .ascii "MO"         ; Missing operand
    .ascii "HX"         ; HEX error
    .ascii "BN"         ; BIN error
