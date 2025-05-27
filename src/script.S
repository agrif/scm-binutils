    ;; **********************************************************************
    ;; **  Script language                           by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; Currently just a proof of concept

    ;; The script language is a tokenised interpreter.
    ;;   S = Small
    ;;   C = Computer
    ;;   R = Reduced        or Rapid
    ;;   I = Instruction
    ;;   P = Program        or Programming
    ;;   T = Text
    ;;
    ;; Line numbers are used to identify locations for editing, nothing more.
    ;; Lines are automatically renumbered each time the code is listed.
    ;; Flow control uses labels rather than line numbers.
    ;;
    ;; The program is stored in lines with this format:
    ;;   Byte   Line length (including this byte), Zero = End of program
    ;;   Word   Line number (displayed in hex)
    ;;   Byte   Line type token: Comment, Label, Statement
    ;;   Bytes  Comment/Label/Statement
    ;;
    ;; Comment lines contain the Comment token followed by a zero
    ;; terminated text string.
    ;;
    ;; Label lines contain the Label token followed by a zero
    ;; terminated text string.
    ;;
    ;; Statement lines contain the statement token followed by a tokenised
    ;; statement.
    ;;
    ;; The script language supports 26 global variables named "A" to "Z",
    ;; each holding an unsigned 16-bit value.
    ;;
    ;; String variables and arrays are not supported. Although PEEK and
    ;; POKE could enable some manipulation of such data.
    ;;
    ;; Script commands are RUN, SCRIPT?? (=LIST), NEW, OLD
    ;;
    ;; Script keywords are:
    ;;   IN, OUT, PEEK, POKE
    ;;   SYS, CALL
    ;;   IF .. THEN .. ELSE .. ENDIF
    ;;   FOR .. NEXT .. EXIT FOR
    ;;   LET
    ;;   GOTO, GOSUB
    ;;   PRINT, INPUT
    ;;   END
    ;;   DELAY
    ;;
    ;; Script operators are:
    ;;   +, -, *, /
    ;;   =, >, <, >=, <=, !=
    ;;   AND, OR
    ;;
    ;; Assignments and comparisons are limited to the most simple of
    ;; statements, such as:
    ;;   LET A = B + 1
    ;;   IF A = 4 THEN
    ;; More complex versions, such as use of parentheses, are not supported
    ;; such as:
    ;;   LET A = (B + 1) * (C + 2)
    ;;   IF  (A + 1) = (B + 2) THEN

    #ifdef IncludeScripting

    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    ;; Initialise script module
    ;;   On entry: No parameters required
    ;;   On exit:  HL = iScrLine = Address of start of program
    ;;             BC DE IX IY I AF' BC' DE' HL' preserved
ScrInitialise:
    ld   hl, 0x4000
    ld   (iScrStart), hl
    jp   ScrNew


    ;; Script: Command: New
    ;;   On entry: No parameters required
    ;;   On exit:  IX IY I AF' BC' DE' HL' preserved
ScrNew:
    ld   hl, (iScrStart) ; Point to first line of program
    ld   a, (hl)        ; Get length of first line
    or   a              ; Length > zero? (program exists)
    ret  z              ; No, so abort
    ld   (iScrOldLen), a ; Yes, so store old length of line
    xor  a              ;  and clear current program
    ld   (hl), a
    ret


    ;; Script: Command: Old
    ;;   On entry: No parameters required
    ;;   On exit:  IX IY I AF' BC' DE' HL' preserved
ScrOld:
    ld   hl, (iScrStart) ; Point to first line of program
    ld   a, (hl)        ; Get length of first line
    or   a              ; Length = zero? (no program)
    ret  nz             ; No, abort and don't overwrite
    ld   a, (iScrOldLen) ; Yes, so get old length of line
    ld   (hl), a        ;  and restore program
    ret


    ;; Script: Command: Script (list)
    ;;   On entry: No parameters required
    ;;   On exit:  IX IY I AF' BC' DE' HL' preserved
ScrList:
    call ScrSetStart
.ScrListLine:
    ld   a, (hl)
    or   a
    ret  z
    ;; Output current line
    ;;push hl
    ld   b, a           ; Store line length
    call StrInitDefault
    inc  hl
    ld   e, (hl)        ; Get lo byte of line number
    inc  hl
    ld   d, (hl)        ; Get hi byte of line number
    call StrWrHexWord
    call StrWrSpace
    inc  hl
    ld   a, (hl)
    bit  7, a
    jr   z, .ScrListText
    ;; Output token
    res  7, a
    call ScrFindString
    ld   a, (hl)
    and  0x7f
.ScrListToken:
    call StrWrChar
    inc  hl
    ld   a, (hl)
    bit  7, a
    jr   nz, .ScrListEndOfLine
    jr   .ScrListToken
    ;; Not a token
.ScrListText:
    cp   kSemicolon
    jr   z, .ScrListComment
    cp   kColon
    jr   nz, .ScrListEndOfLine
    ;; Output comment or label
.ScrListComment:
    call StrWrChar
    inc  hl
    ld   a, (hl)
    or   a
    jr   nz, .ScrListComment


    ;;pop  hl

.ScrListEndOfLine:
    call StrWrNewLine
    call StrPrint
    call ScrNextLine
    jr   .ScrListLine


    ;; Script: Edit line
    ;;   On entry: DE = Start of line in input buffer (after line number)
    ;;             HL = Line number
    ;;   On exit:  Script program memory updated
    ;;             IX IY I AF' BC' DE' HL' preserved
ScrEdit:
    ld   b, h
    ld   c, l
    call ScrSetStart
    call CLISkipDelim
    ld   a, (de)
    or   a              ; Blank line entered?
    jr   z, .ScrEditDelete ; Yes, so go delete line

    ;; Find end of program
.ScrEditNext:
    ld   a, (hl)
    or   a
    jr   z, .ScrEditAppend
    call ScrNextLine
    jr   .ScrEditNext
    ;; Append line
.ScrEditAppend:
    push de
    push hl
    call ScrTokenise
    pop  hl
    pop  de
    push hl
    ;;ld   (hl), 3
    inc  hl
    ld   (hl), c
    inc  hl
    ld   (hl), b
    inc  hl
    ld   b, 3           ; Initial line length
.ScrEditCopy:
    ld   a, (de)
    ld   (hl), a
    inc  de
    inc  hl
    inc  b
    or   a
    jr   nz, .ScrEditCopy
    ;; Line written to program
.ScrEditDone:
    ld   (hl), a        ; Terminate program
    pop  hl
    ld   (hl), b        ; Write length to line
    ret
    ;; Delete line
.ScrEditDelete:
    call ScrFindLine
    ret


    ;; **********************************************************************
    ;; **  Private functions                                               **
    ;; **********************************************************************


    ;; Set current line to start of program
    ;;   On entry: No parameters required
    ;;   On exit:  HL = iScrLine = Address of start of first line
    ;;             BC DE IX IY I AF' BC' DE' HL' preserved
ScrSetStart:
    ld   hl, (iScrStart)
    ld   (iScrLine), hl
    ret


    ;; Calculate start address of next line
    ;;   On entry: No parameters required
    ;;   On exit:  HL = iScrLine = Address of start of line
    ;;             BC DE IX IY I AF' BC' DE' HL' preserved
ScrNextLine:
    ld   hl, (iScrLine) ; Get start of current line
    ld   a, (hl)        ; Get length of line
    add  a, l           ; Add to start of line...
    ld   l, a
    jr   nc, .ScrNextLineDone
    inc  h
.ScrNextLineDone:
    ld   (iScrLine), hl ; Store start of 'next' line
    ret


    ;; Find address of line BC
    ;;   On entry: BC = Line number to be deleted
    ;;             DE = Start of line in input buffer (after line number)
    ;;             HL = Start of program
    ;;   On exit:  NZ flagged if found
    ;;             HL = iScrLine = Address of start of line
ScrFindLine:
.ScrFindLineNext:
    ld   a, (hl)        ; Get length of line
    or   a              ; End of program?
    ret  z              ; Yes, so return as line not found
    inc  hl             ; Point to line number lo byte
    ld   a, (hl)        ; Get line number lo byte
    cp   c              ; Compare with lo byte of target line
    jr   nz, .ScrFindLineFind ; Not the same so go try next line
    inc  hl             ; Point to line number hi byte
    ld   a, (hl)        ; Get line number hi byte
    cp   b              ; Compare with hi byte of target line
    jr   z, .ScrFindLineFound ; Same so we've found the line
.ScrFindLineFind:
    call ScrNextLine    ; Find start of next line
    jr   .ScrFindLineNext ; Loop until done
.ScrFindLineFound:
    ld   hl, (iScrLine) ; Get start address of this line
    ld   a, 0xff        ; Found so return NZ
    or   a
    ret


    ;; Tokenise line
    ;;   On entry: DE = Start of line in input buffer (after line number)
ScrTokenise:
    ld   hl, (iScrStart) ; Point to length of first line
    ld   a, (hl)        ; Get length of first line
    ld   (iScrOldLen), a ; Store, so flagging program exists
    call CLISkipDelim
    ld   h, d
    ld   l, e
    ld   a, (de)
    cp   kSemicolon     ; Comment?
    ret  z              ; Yes, so we're done
    cp   kColon         ; Label?
    ret  z              ; Yes, so we're done
    push de
    push hl
    ld   hl, ScrNameList
    call SearchStringListNA
    pop  hl
    pop  de
    jr   z, .ScrTokeniseError
    set  7, a           ; Turn string number into token
    ld   (hl), a        ; Store token in program memory
    inc  hl
    ld   (hl), 0        ; Mark end of tokenised string
    ret
.ScrTokeniseError:
    ret



    ;; TODO This is virtually identical to DisFindString so share code
    ;; Script: Find start of string A
    ;;   On entry: A = String number
    ;;   On exit:  HL = Start of string
    ;;             AF BC DE IX IY I AF' BC' DE' HL' preserved
    ;; Find string A in bit 7 delimited disassembler string list
ScrFindString:
    push af
    push bc
    ld   hl, ScrNameList-1 ; Start of string table - 1
    ld   b, a           ; Get string number
.ScrFindStringNext:
    inc  hl             ; Point to next character
    bit  7, (hl)        ; Start of new string?
    jr   z, .ScrFindStringNext ; No, so go get next character
    djnz .ScrFindStringNext ; Loop back if not the right string
    pop  bc
    pop  af
    ret


    ;; **********************************************************************
    ;; **  Constant data                                                   **
    ;; **********************************************************************

    .section .rodata

    ;; Key word names list
ScrNameList:
    .db  128+'T', "1"
    .db  128+'P', "EEK" ; PEEK
    .db  128+'T', "2"
    .db  128            ; List terminator


    ;; **********************************************************************
    ;; **  Private workspace (in RAM)                                      **
    ;; **********************************************************************

    .bss

iScrStart:
    .dw  0              ; Start of script program
iScrLine:
    .dw  0              ; Start of current line
iScrOldLen:
    .db  0              ; Length to restore program with NEW


    ;; **********************************************************************
    ;; **  End of Script module                                            **
    ;; **********************************************************************

    #endif // IncludeScripting
