    ;; **********************************************************************
    ;; **  Common utility functions                  by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif
    ;;
    ;; **  Written as a module to be included in Small Computer Monitor Apps
    ;; **  Version 0.2 SCC 2018-05-15
    ;; **  www.scc.me.uk
    ;;
    ;; **********************************************************************
    ;;
    ;; This module provides some common utility functions
    ;;
    ;; **********************************************************************
    ;;
    ;; These are the function names provided by this module:
    ;; uOutputNewLine                ;Output new line (eg. CR+LF)
    ;; uOutputText                   ;Output null terminated string
    ;; uOutputHexPref                ;Output hexadecimal prefix (eg. '$')
    ;; uByteToNibbles                ;Convert byte (A) to two nibbles (DE)
    ;; uOutputHexNib                 ;Output hexadecimal nibble
    ;; uOutputHexByte                ;Output hexadecimal byte
    ;; uOutputHexWord                ;Output hexadecimal word
    ;; uOutputDecWord                ;Output decimal word no leading spaces
    ;; uFindString                   ;Fins null terminated string in list

    #include "scm-api.h"


    ;; **********************************************************************
    ;; **  Common support functions
    ;; **********************************************************************

    ;; Output new line
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.uOutputNewLine
    .global uOutputNewLine
uOutputNewLine:
    push af
    ld   a, kReturn     ; Prepare to output carriage return
    call aOutputChar
    ld   a, kLinefeed   ; Prepare to output line feed
    call aOutputChar
    pop  af
    ret
    .popsection


    ;; Output text string (null terminated)
    ;;   On entry: DE = Pointer to start of null terminated string
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.uOutputText
    .global uOutputText
uOutputText:
    push af
    push de
uOutputText.Loop:
    ld   a, (DE)        ; Get character from string
    or   a              ; End marker (null)?
    jr   z, uOutputText.Finished ; Yes, so finished
    call aOutputChar
    inc  de             ; Point to next character in string
    jr   uOutputDecWord.Loop ; Go consider next character
uOutputText.Finished:
    pop  de
    pop  af
    ret
    .popsection


    ;; Output hex prefix (eg. dollar)
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.uOutputHexPref
    .global uOutputHexPref
uOutputHexPref:
    push af
    ld   a, '$'         ; Prepare to output '$'
    call aOutputChar
    pop  af
    ret
    .popsection


    ;; Output hexadecimal word (0000 to FFFF)
    ;;   On entry: DE = Unsigned 16-bit number to be output in hexadecimal
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.uOutputHexWord
    .global uOutputHexWord
uOutputHexWord:
    push af
    ld   a, d
    call uOutputHexByte ; Output most significant byte
    ld   a, e
    call uOutputHexByte ; Output least significant byte
    pop  af
    ret
    .popsection


    ;; Output hexadecimal byte (00 to FF)
    ;;   On entry: A = Unsigned 8-bit number to be output in hexadecimal
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.uOutputHexByte
    .global uOutputHexByte
uOutputHexByte:
    push af
    push de
    call uByteToNibbles
    ld   a, d
    call uOutputHexNib  ; Output most significant nibble
    ld   a, e
    call uOutputHexNib  ; Output least significant nibble
    pop  de
    pop  af
    ret
    .popsection


    ;; Output hexadecimal nibble (0 to F)
    ;;   On entry: A = Unsigned 4-bit number to be output in hexadecimal
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.uOutputHexNib
    .global uOutputHexNib
uOutputHexNib:
    push af
    and  0x0f           ; Mask off nibble
    cp   0x0a           ; Nibble > 10 ?
    jr   c, uOutputHexNib.Skip ; No, so skip
    add  a, 7           ; Yes, so add 7
uOutputHexNib.Skip:
    add  a, 0x30        ; Add ASCII '0'
    call aOutputChar    ; Output hex nibble character
    pop  af
    ret
    .popsection


    ;; Convert byte (A) to nibbles (DE)
    ;;   On entry: A = Byte to be converted into nibbler
    ;;             D = Most significant nibble (0 to F)
    ;;             E = Least significant nibble (0 to F)
    ;;   On exit:  AF BC HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.uByteToNibbles
    .global uByteToNibbles
uByteToNibbles:
    push af
    ld   e, a           ; Get byte to convert
    rra                 ; Shift top nibble to
    rra                 ;  botom four bits..
    rra
    rra
    and  0x0f           ; Mask off unwanted bits
    ld   d, a           ; Store top nibble
    ld   a, e           ; Get byte to convert
    and  0x0f           ; Mask off unwanted bits
    ld   e, a           ; Store bottom nibble
    pop  af
    ret
    .popsection


    ;; Output decimal word (0 to 65535)
    ;;   On entry: DE = Unsigned 16-bit number to be output in decimal
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; No leading zero / spaces are output
    .pushsection .text.uOutputDecWord
    .global uOutputDecWord
uOutputDecWord:
    push af
    push bc
    push de
    push hl
    ex   de, hl         ; HL = number to output
    ld   b, 1           ; Set leading zero flag
    ld   de, 0xd8f0     ; -10000
    call uOutputDecWord.Digit
    ld   de, 0xfc18     ; -1000
    call uOutputDecWord.Digit
    ld   de, 0xff9c     ; -100
    call uOutputDecWord.Digit
    ld   e, 0xf6        ; -10
    call uOutputDecWord.Digit
    ld   e, 0xff        ; -1
    call uOutputDecWord.Digit
    djnz uOutputDecWord.Done ; Skip if a number has been output
    ld   a, '0'         ; Otherwise number must be zero
    call uOutputDecWord.Output ; Output '0'
uOutputDecWord.Done:
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    ;; Process one digit
uOutputDecWord.Digit:
    ld   a, '0'-1       ; A = Character '0' - 1
uOutputDecWord.Loop:
    inc  a              ; A = A + 1 (eg. Character '0')
    add  hl, de         ; Add supplied digit value
    jr   c, uOutputDecWord.Loop ; Repeat until counted this digit
    sbc  hl, de         ; Adjust remainder
    djnz uOutputDecWord.Output ; Output if not leading zero
    cp   '0'            ; Leading zero?
    jr   nz, uOutputDecWord.Output ; No, so output it
    inc  b              ; Set leading zero flag
    ret                 ; Abort output of leading zero
uOutputDecWord.Output:
    call aOutputChar    ; Output character
    ret
    .popsection


    ;; Locate string in list
    ;;   On entry: A = String number (0 to N)
    ;;             DE = Start of string list
    ;;   On exit:  DE = Address of start of null terminated string
    ;;             BC HL IX IY I AF' BC' DE' HL' preserved
    ;; If string not found the DE points to a null list terminator
    ;; Each string in the list is null terminated. eg:
    ;;           .TEXT "String 1",0
    ;;           .TEXT "String 2",0
    ;;           .DB 0               ;End marker
    .pushsection .text.uFindString
    .global uFindString
uFindString:
    or   a              ; Are we looking for string zero?
    ret  z              ; Yes, so exit
    push bc
    ld   b, a           ; Store string number
uFindString.Next:
    ld   a, (DE)        ; Get first character from string
    or   a              ; End of string list?
    jr   z, uFindString.Exit ; Yes, so abort
uFindString.Char:
    ld   a, (DE)        ; Get character from string
    inc  de             ; Point to next character in string
    or   a              ; Null terminator?
    jr   nz, uFindString.Char ; No, so go try next character
    djnz uFindString.Next ; Repeat if not the right string
uFindString.Exit:
    pop  bc
    ret
    .popsection
