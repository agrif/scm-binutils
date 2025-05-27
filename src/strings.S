    ;; **********************************************************************
    ;; **  String support                            by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module provides a group of functions to handle strings. Strings
    ;; are build in buffers using various functions, such as StrWrChar,
    ;; which writes the specified character to the end of the currently
    ;; selected string. The string can then be 'printed' to the current
    ;; output device with the StrPrint function.
    ;;
    ;; Ensure StrInitialise or StrInitDefault is called before any other
    ;; string function as these finctions select and initialise a string
    ;; buffer.
    ;;
    ;; Strings are stored in buffers where the first byte of the buffer
    ;; contains the string length. A value of zero therefore indicates
    ;; an empty (or null) string.
    ;;
    ;; Public functions provided
    ;;   StrAppend             Append specified string to current buffer
    ;;   StrAppendZ            Append specified zero terminated string
    ;;   StrClear              Clear the current string buffer
    ;;   StrConvUpper          Convert string to upper case
    ;;   StrCopyToZ            Copy to zero (null) terminated string
    ;;   StrGetLength          Get length of string in current string buffer
    ;;   StrInitDefault        Initialise and select the default buffer
    ;;   StrInitialise         Initialise default or supplied string buffer
    ;;   StrPrint              Print string in current string buffer
    ;;   StrPrintDE            Print string in string buffer at DE
    ;;   StrWrAddress          Write address, colon, space to buffer
    ;;   StrWrAsciiChar        Write ascii character to string buffer
    ;;   StrWrBackspace        Write backspace to string buffer
    ;;   StrWrBinaryByte       Write binary byte to string buffer
    ;;   StrWrBinaryWord       TODO write binary byte
    ;;   StrWrChar             Write character to string buffer
    ;;   StrWrDecByte          TODO write decimal byte
    ;;   StrWrDecWord          TODO write decimal word
    ;;   StrWrHexByte          Write byte to buffer as 2 hex characters
    ;;   StrWrHexNibble        Write nibble to buffer as 1 hex character
    ;;   StrWrHexWord          Write word to buffer as 4 hex characters
    ;;   StrWrNewLine          Write new line to string buffer
    ;;   StrWrPadding          Write padding (spaces) to specified length
    ;;   StrWrSpace            Write space character to string buffer
    ;;   StrWrSpaces           Write specified spaces to string buffer
    ;; Unless otherwise stated these functions have no return values and
    ;; preserved the registers: AF BC DE HL IX IY I AF' BC' DE' HL'

    #ifdef IncludeStrings

    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    ;; String: Append specified string to current string buffer
    ;;   On entry: DE = Start of string to be appended
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrAppend:
    push af
    push bc
    push de
    ld   a, (de)        ; Get length of specified string
    or   a              ; Null string?
    jr   z, .StrAppendDone ; Yes, so we're done
    ld   b, a           ; Store length of string
.StrAppendNext:
    inc  de             ; Point to next character to append
    ld   a, (de)        ; Get character from specified string
    call StrWrChar      ; Write character to current string
    djnz .StrAppendNext ; Loop back if more character
.StrAppendDone:
    pop  de
    pop  bc
    pop  af
    ret


    ;; String: Append specified zero (null) terminated string
    ;;   On entry: DE = Start of string to be appended
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Appends specified zero (null) terminated string to current string
    ;; buffer. The string does not have the usual length prefix but
    ;; instead is terminated with a zero (null).
StrAppendZ:
    push af
    push de
.StrAppendZNext:
    ld   a, (de)        ; Get length of specified string
    or   a              ; Null string?
    jr   z, .StrAppendZDone ; Yes, so we're done
    call StrWrChar      ; Write character to current string
    inc  de             ; Point to next character
    jr   .StrAppendZNext ; Loop back if more character
.StrAppendZDone:
    pop  de
    pop  af
    ret


    ;; String: Clear string in current string buffer
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrClear:
    push hl
    ld   hl, (iStrStart) ; Get start of current string buffer
    ld   (hl), 0        ; Initialise string with length zero
    pop  hl
    ret


    ;; String: Convert string to upper case
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrConvUpper:
    push af
    push hl
    ld   hl, (iStrStart) ; Get start of current string buffer
    ld   a, (hl)        ; Get length of string
    or   a              ; Null string?
    jr   z, .StrConvUpperDone ; Yes, so we're done here
    push bc
    ld   b, a           ; Store length of string
.StrConvUpperLoop:
    inc  hl             ; Point to next character in string
    ld   a, (hl)        ; Get character from string
    call ConvertCharToUCase
    ld   (hl), a        ; Write upper case char to string
    djnz .StrConvUpperLoop ; Loop until end of string
    pop  bc
.StrConvUpperDone:
    pop  hl
    pop  af
    ret


    ;; String: Copy to zero (null) terminated string
    ;;   On entry: DE = Location to store Z string
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrCopyToZ:
    push af
    push de
    push hl
    ld   hl, (iStrStart) ; Get start of current string buffer
    ld   a, (hl)        ; Get length of string
    or   a              ; Null string?
    jr   z, .StrCopyToZDone ; Yes, so we're done here
    inc  hl             ; Point to first character in string
    push bc
    ld   c, a           ; Store length of string
    ld   b, 0
    ldir                ; Copy string from HL to DE
    pop  bc
.StrCopyToZDone:
    xor  a
    ld   (de), a        ; Terminate string with null
    pop  hl
    pop  de
    pop  af
    ret


    ;; String: Get length of string in current string buffer
    ;;   On entry: No parameters required
    ;;   On exit:  A = Length in characters
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
StrGetLength:
    push hl
    ld   hl, (iStrStart) ; Get start of current string buffer
    ld   a, (hl)        ; Get length of string in buffer
    pop  hl
    ret


    ;; String: Initialise and select default string buffer
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrInitDefault:
    push af
    xor  a              ; Select default string buffer (0)
    call StrInitialise  ; Select and initialise buffer
    pop  af
    ret


    ;; String: Initialise default or supplied string buffer
    ;;   On entry: A = Size of buffer or zero to restore defaults
    ;;             DE = Start address of string buffer
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Size includes the string's length byte so needs to be one byte
    ;; longer than the largest string it can hold.
StrInitialise:
    push af
    push de
    or   a              ; Buffer length zero?
    jr   nz, .StrInitialiseInit ; No, so go use supplied values
    ld   de, kStrBuffer ; Get start of default buffer
    ld   a, kStrSize    ; Get size of default buffer
.StrInitialiseInit:
    ld   (iStrStart), de ; Store start of string buffer
    ld   (iStrSize), a  ; Store size of string buffer
    xor  a              ; Prepare for length zero
    ld   (de), a        ; Initialise string with length zero
    pop  de
    pop  af
    ret


    ;; String: Print string in current string buffer
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; The string is printed to the current output device
    ;; Supports \n for new line
StrPrint:
    push de
    ld   de, (iStrStart) ; Get start of current string buffer
    call StrPrintDE     ; Print string at DE
.StrPrintDone:
    pop  de
    ret


    ;; String: Print string in current string buffer
    ;;   On entry: DE = Address of string
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; The string is printed to the current output device
StrPrintDE:
    push af
    push bc
    push de
    ld   a, (de)        ; Get length of specified string
    or   a              ; Null string?
    jr   z, .StrPrintDEDone ; Yes, so we're done
    ld   b, a           ; Store length of string
.StrPrintDENext:
    inc  de             ; Point to next character to append
    ld   a, (de)        ; Get character from specified string
    call OutputChar     ; Output character to output device
    djnz .StrPrintDENext ; Loop back if more character
.StrPrintDEDone:
    pop  de
    pop  bc
    pop  af
    ret


    ;; String: Write address, colon, space to string buffer
    ;;   On entry: DE = Address
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Example output: "1234: "
StrWrAddress:
    push af
    call StrWrHexWord   ; Write start address of this line
    ld   a, ':'
    call StrWrChar      ; Write colon
    call StrWrSpace     ; Write space
    pop  af
    ret


    ;; String: Write ascii character to string buffer
    ;;   On entry: A = ASCII character
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; If the character is not printable then a dot is written instead
StrWrAsciiChar:
    push af
    call ConvertByteToAscii
    call StrWrChar      ; Write character or a dot
    pop  af
    ret


    #ifdef kIncludeUnusedCode
    ;; String: Write backspace to string buffer
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Writeing backspace deletes the last character in the buffer
StrWrBackspace:
    push af
    push hl
    ld   hl, (iStrStart) ; Pointer to start of string buffer
    ld   a, (hl)        ; Get length of string in buffer
    or   a              ; Null terminator?
    jr   z, .StrWrBackspaceSkip ; Yes, so skip as null string
    dec  hl             ; Decrement string length
.StrWrBackspaceSkip:
    pop  hl
    pop  af
    ret
    #endif


    #ifdef kIncludeUnusedCode
    ;; String: Write binary byte
    ;;   On entry: A = Binary byte
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrBinaryByte:
    push af
    push bc
    ld   b, 8           ; Set for 8-bits
    ld   c, a           ; Store binary byte
.StrWrBinaryByteNextBit:
    ld   a, '1'         ; Default to '1'
    rl   c              ; Rotate data byte
    jr   c, .StrWrBinaryByteOne ; result in Carry
    ld   a, '0'         ; Select '0'
.StrWrBinaryByteOne:
    call StrWrChar      ; Output '1' or '0'
    djnz .StrWrBinaryByteNextBit ; Loop until done
    pop  bc
    pop  af
    ret
    #endif


    ;; String: Write character
    ;;   On entry: A = Character to write to string buffer
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; The specified character is writted to the string buffer and a null
    ;; terminator added.
StrWrChar:
    push af
    push de
    push hl
    ld   e, a           ; Store character to write
    ld   hl, (iStrStart) ; Start of current string buffer
    ld   a, (hl)        ; Get length of string in buffer
    ;; TODO >>>>> Trap strings too long for the buffer
    inc  (hl)           ; Increment string length
    inc  a              ; Inc to skip length byte
    add  a, l           ; Add A to start of buffer...
    ld   l, a           ;  to get address for next character
    jr   nc, .StrWrCharStore
    inc  h
.StrWrCharStore:
    ld   (hl), e        ; Store character in buffer
    pop  hl
    pop  de
    pop  af
    ret


    ;; TODO >>>>> WriteDecimalByte


    ;; TODO >>>>> WriteDecimalByteWithZero


    ;; String: Write hex byte to string buffer
    ;;   On entry: A = Hex byte
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrHexByte:
    push af
    push de
    call ConvertByteToNibbles
    ld   a, d
    call StrWrHexNibble
    ld   a, e
    call StrWrHexNibble
    pop  de
    pop  af
    ret


    ;; String: Write hex nibble to string buffer
    ;;   On entry: A = Hex nibble
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrHexNibble:
    push af
    and  0x0f           ; Mask off nibble
    cp   0x0a           ; Nibble > 10 ?
    jr   c, .StrWrHexNibbleSkip ; No, so skip
    add  a, 7           ; Yes, so add 7
.StrWrHexNibbleSkip:
    add  a, 0x30        ; Add ASCII '0'
    call StrWrChar      ; Write character
    pop  af
    ret


    ;; String: Write hex word to string buffer
    ;;   On entry: DE = Hex word
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrHexWord:
    push af
    ld   a, d           ; Get hi byte
    call StrWrHexByte   ; Write as two hex digits
    ld   a, e           ; Get lo byte
    call StrWrHexByte   ; Write as two hex digits
    pop  af
    ret


    ;; String: Write new line to string buffer
    ;;   On entry: No parameters
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrNewLine:
    push af
    ld   a, kNewLine    ; Get new line character
    call StrWrChar      ; Write character to string
    pop  af
    ret


    ;; String:  Write padding (spaces) to specified length
    ;;   On entry: A = Required length of string
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrPadding:
    push af
    push bc
    push hl
    ld   b, a
    ld   hl, (iStrStart) ; Get start of current string buffer
    sub  (hl)           ; Compare required length to current
    jr   c, .StrWrPaddingEnd ; End now if already too long
    jr   z, .StrWrPaddingEnd ; End now if already required length
    call StrWrSpaces    ; Write required number of spaces
.StrWrPaddingEnd:
    pop  hl
    pop  bc
    pop  af
    ret


    ;; String: Write space character to string buffer
    ;;   On entry: No parameters
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrSpace:
    push af
    ld   a, kSpace      ; Space character
    call StrWrChar      ; Write space character
    pop  af
    ret


    ;; String: Write spaces to string buffer
    ;;   On entry: A = Number of spaces to write
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrSpaces:
    push af
.StrWrSpacesLoop:
    call StrWrSpace     ; Print one space character
    dec  a              ; Written all required spaces?
    jr   nz, .StrWrSpacesLoop ; No, so go write another
    pop  af
    ret


    ;; **********************************************************************
    ;; **  Private workspace (in RAM)                                      **
    ;; **********************************************************************

    .bss

iStrStart:
    .dw  0              ; Start of current string buffer
iStrSize:
    .db  0              ; Size of current string buffer (0 to Len-1)


    ;; **********************************************************************
    ;; **  End of String support module                                    **
    ;; **********************************************************************

    #endif // IncludeStrings
