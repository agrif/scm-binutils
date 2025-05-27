    ;; **********************************************************************
    ;; **  Console support (input and output)        by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module handles console input and output. The console is normally
    ;; a serial terminal or terminal emulation program.
    ;;
    ;; Public functions provided
    ;;   ConInitialise         Initialise console module
    ;;   InputInsert           Insert character to character waiting buffer
    ;;   InputMore             Ask if user wants to output more
    ;;   InputPreview          Await one character but leave it to be input
    ;;   InputChar             Input character from console input device
    ;;   InputBufConvUpper     Convert contents of input buffer to upper case
    ;;   InputLineEdit         Input line where existing line is replaced
    ;;   InputLine             Input line to system line buffer
    ;;   InputLineTo           Input line to specified line buffer
    ;;   InputStatus           Check if input character is available
    ;;   OutputChar            Output character to console output device
    ;;   OutputNewLine         Output new line character(s)
    ;;   OutputZString         Output a zero (null) terminated string


    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    ;; Console: Initialise console module
    ;;   On entry: No parameters required
    ;;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
ConInitialise:
    xor  a
    ld   (iConInChar), a
    ret


    ;; **********************************************************************
    ;; **  Input form console / input device, typically a terminal         **
    ;; **********************************************************************


    ;; Console input: Insert character into character waiting buffer
    ;;   On entry: A = ASCII character
    ;;   On exit:  A BC DE HL IX IY I AF' BC' DE' HL' preserved
InputInsert:
    ld   (iConInChar), a ; Store as character waiting
    ret


    ;; Console input: Ask if user wants to output more
    ;;   On entry: No parameters required
    ;;   On exit:  A = ASCII character
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; No prompt is given, it just waits until character is available.
    ;; If the character is the request for 'more' character (eg. Return) the
    ;; routine exits with the character in A and the Z flag set.
    ;; If the character is Escape then the routine exits with A = 0 and
    ;; NZ flagged.
    ;; Otherwise the character is stored in iConInChar and will be picked up
    ;; on next call to InputGetWaiting.
InputMore:
    call JpIdle         ; Process idle events
    call JpConIn        ; Wait for input character
    jr   z, InputMore   ; Repeat until we get a character
    cp   kLinefeed      ; More (linefeed) ?
    jr   z, InputMore   ; Ignore line feed
    ;;ret  Z            ; Yes, so return with Z flagged
    cp   kReturn        ; More (carriage return) ?
    ret  z              ; Yes, so return with Z flagged
    cp   kEscape        ; Escape character ?
    jr   z, .InputMoreEscape ; Yes, so skip
    ld   (iConInChar), a ; Store as character waiting
    ret                 ;  and return with NZ flagged
.InputMoreEscape:
    xor  a              ; Clear A
    cp   1              ; Flag NZ as not a request for more
    ret


    ;; Console input: Await one character but leave it waiting to be input
    ;;   On entry: No parameters required
    ;;   On exit:  A = ASCII character
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
InputPreview:
    ld   a, (iConInChar) ; Read from character waiting buffer
    or   a              ; Is there a character waiting?
    ret  nz             ; If character is waiting then return it
.InputPreviewWait:
    call JpConIn        ; Wait for input character
    jr   nz, .InputPreviewGotOne ; Skip if we get a character
    call JpIdle         ; Process idle events
    jr   .InputPreviewWait ; Repeat until we get a character
.InputPreviewGotOne:
    ld   (iConInChar), a ; Store as character waiting
    ret


    ;; Console input: Input character from console input device
    ;;   On entry: No parameters required
    ;;   On exit:  A = ASCII character
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Waits until character is available
InputChar:
    ld   a, (iConInChar) ; Read from character waiting buffer
    or   a              ; Is there a character waiting?
    jr   z, .InputCharInput ; No, so go get new character..
    ;; Return character which is waiting to be read
    push af             ; Preserve character
    xor  a              ; Flush waiting buffer by
    ld   (iConInChar), a ;  storing zero in to
    pop  af             ; Restore character
    ret
    ;; Get new character from console input device
.InputCharInput:
    call JpConIn        ; Look for input character
    ret  nz             ; Exit if we have a character
    call JpIdle         ; Process idle events
    jr   .InputCharInput ; No character so keep looking


    ;; Console input: Check if input character is available
    ;;   On entry: No parameters required
    ;;   On exit:  NZ flagged if character is available
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Does not wait for a character to become available
InputStatus:
    ld   a, (iConInChar) ; Read from character waiting buffer
    or   a              ; Is there a character waiting?
    ret  nz             ; If character is waiting return
    call JpConIn        ; Look for input character
    ret  z              ; No character to exit
    ld   (iConInChar), a ; Store character to read later
    ret


    ;; Console input: Convert contents of input buffer to upper case
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; One exception is the character following an apostrophe
InputBufConvUpper:
    push af
    push hl
    ld   hl, (iConInBuf) ; Get start of current input buffer
.InputBufConvUpperLoop:
    ld   a, (hl)        ; Get character from input buffer
    or   a              ; Null string?
    jr   z, .InputBufConvUpperDone ; Yes, so we're done here
    ;; Do not convert character immediately following an apostrophe
    cp   kApostroph     ; Apostrophe?
    jr   nz, .InputBufConvUpperNotApos ; No, so skip
    inc  hl             ; Skip apostrophe
    ld   a, (hl)        ; Get character from input buffer
    or   a              ; Null string?
    jr   z, .InputBufConvUpperDone ; Yes, so we're done here
    jr   .InputBufConvUpperNext ; Go to next character
.InputBufConvUpperNotApos:
    ;; Convert this character to upper case
    call ConvertCharToUCase
    ld   (hl), a        ; Write upper case char to string
.InputBufConvUpperNext:
    inc  hl             ; Point ot next character in string
    jr   .InputBufConvUpperLoop ; Loop until end of string
.InputBufConvUpperDone:
    pop  hl
    pop  af
    ret


    ;; Console input: Input line to system line buffer
    ;;   On entry: No parameters required
    ;;   On exit:  DE = Start location of buffer
    ;;             A = Number of characters in buffer
    ;;             Z flagged if no characters in bufffer
    ;;             BC HL IX IY I AF' BC' DE' HL' preserved
    ;;             Interrupts enabled during this call ???
    ;; The number of characters returned does not include the null terminator.
InputLine:
    ld   de, kInputBuff ; Start of system line buffer
    xor  a
    ld   (de), a        ; Clear input buffer
    ld   a, kInputSize-1 ; Length of system line buffer
    jp   InputLineNow   ; Input line
    ;;call InputLineNow ; Input line
    ;;ret


    ;; Console input: Edit line in default string buffer
    ;;   On entry: No parameters required
    ;;   On exit:  DE = Start location of buffer
    ;;             A = Number of characters in buffer
    ;;             Z flagged if no characters in bufffer
    ;;             BC HL IX IY I AF' BC' DE' HL' preserved
    ;;             Interrupts enabled during this call ???
    ;; The number of characters returned does not include the null terminator.
    ;; DE points to a null terminated string to be edited
InputLineEdit:
    ld   de, kInputBuff ; Start of system line buffer
    call StrCopyToZ     ; Copy current string to input buffer
    ld   a, kInputSize-1 ; Length of system line buffer
    jp   InputLineNow   ; Input line
    ;;call InputLineNow ; Input line
    ;;ret


    ;; Console input: Input line to user defined buffer
    ;;   On entry: DE = Start of buffer
    ;;             A = Size of input buffer in bytes
    ;;   On exit:  A = Number of characters in input buffer
    ;;             Z flagged if no characters in bufffer ???
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;;             Interrupts enabled during this call ???
    ;; Maximum buffer length 255 bytes.
    ;; The buffer length includes the string termination character (null).
    ;; The number of characters returned does not include the null terminator.
InputLineTo:
    push af
    xor  a
    ld   (de), a        ; Clear input buffer
    pop  af
    ;;jp   InputLineNow ; Input line


    ;; Console input: Input or edit line at specified location
    ;;   On entry: DE = Start of buffer
    ;;             A = Size of input buffer in bytes
    ;;   On exit:  A = Number of characters in input buffer
    ;;             Z flagged if no characters in bufffer ???
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;;             Interrupts enabled during this call ???
    ;; Maximum buffer length 255 bytes.
    ;; The buffer length includes the string termination character (null).
    ;; The number of characters returned does not include the null terminator.
InputLineNow:
    push de
    push hl
    ld   (iConInBuf), de ; Store start of buffer
    ld   l, a           ; Store end address of buffer lo byte
    dec  l              ; Allow space for return character
    ld   h, e           ; Store start address of buffer lo byte
    ;;xor  a
    ;;ld   (de), a      ; Clear input buffer
    ;; Check if we are overtyping an existing string
    ld   a, (de)        ; Get first character in buffer
    or   a              ; Null (zero)?
    jr   z, .InputLineNowInput ; Yes, so skip
    ;; Output current string in buffer
.InputLineNowLoop1:
    call OutputChar     ; Output character
    inc  de             ; Point to next character
    ld   a, (de)        ; Get character from buffer
    or   a              ; Null (zero)?
    jr   nz, .InputLineNowLoop1 ; No, so go output it
    ;; Backspace to start of string
.InputLineNowLoop2:
    ld   a, kBackspace  ; ASCII backspace
    call OutputChar     ; Output backspace
    dec  de             ; Back one character
    ld   a, e           ; Get start address of buffer lo byte
    cp   h              ; Start of buffer?
    jr   nz, .InputLineNowLoop2 ; No, so go backspace again
    ;; Input line to buffer
.InputLineNowInput:
    call InputChar      ; Wait for input character
    bit  7, a           ; Reject if bit 7 set
    jr   nz, .InputLineNowInput
    cp   kEscape        ; Test if Escape character
    jr   z, .InputLineNowEscape
    cp   kBackspace     ; Test if Delete character
    jr   z, .InputLineNowBackspace
    cp   kReturn        ; Test if carriage return
    jr   z, .InputLineNowReturn
    cp   kSpace         ; Reject if control char
    jr   c, .InputLineNowInput
    ;; Normal character (ASCII 32 to 126), consider edit mode
    ;; If start of line and in edit mode, erase the line
    push af
    ld   a, e           ; Get start address of buffer lo byte
    cp   h              ; Start of buffer?
    jr   nz, .InputLineNowEndErase ; No, so skip
    ld   a, (de)        ; Get first character in line
    or   a              ; Anything to edit?
    jr   z, .InputLineNowEndErase ; No, so skip
    ;; Erase string being edited
.InputLineNowLoop3:
    ld   a, kSpace      ; ASCII space
    call OutputChar     ; Erase character from terminal
    xor  a
    ld   (de), a        ; Erase character from buffer
    inc  de             ; Point to next character
    ld   a, (de)        ; Get character from buffer
    or   a              ; Null (zero)?
    jr   nz, .InputLineNowLoop3 ; No, so go output it
.InputLineNowLoop4:
    ld   a, kBackspace  ; ASCII backspace
    call OutputChar     ; Output backspace
    dec  de             ; Back one character
    ld   a, e           ; Get start address of buffer lo byte
    cp   h              ; Start of buffer?
    jr   nz, .InputLineNowLoop4 ; No, so go backspace again
.InputLineNowEndErase:
    pop  af
    ;; Normal character (ASCII 32 to 126), write to buffer
    ld   (de), a        ; Store character in buffer
    ld   a, e           ; Get current address lo byte
    cp   l              ; Buffer full?
    jr   z, .InputLineNowInput ; Yes, so don't increment pointer
    ld   a, (de)        ; No, so..
    call OutputChar     ;  echo character just input
    inc  de             ;  and increment buffer pointer
    jr   .InputLineNowInput
    ;; Escape character
.InputLineNowEscape:
    call OutputNewLine  ; Output new line character(s)
    ld   a, kEscape
    cp   a              ; Set zero flag but with A = kEscape
    jr   .InputLineNowExit
    ;; Delete character
.InputLineNowBackspace:
    ld   a, e           ; Get start address of buffer lo byte
    cp   h              ; Start of buffer?
    jr   z, .InputLineNowInput ; Yes, so nothing to delete
    ld   a, kBackspace  ; ASCII backspace
    call OutputChar     ; Output backspace
    ld   a, kSpace      ; ASCII space
    call OutputChar     ; Output space
    ld   a, kBackspace  ; ASCII backspace
    call OutputChar     ; Output backspace
    dec  de             ; Decrement buffer pointer
    xor  a
    ld   (de), a        ; Mark end of string with null
    jr   .InputLineNowInput
    ;; Carriage return
.InputLineNowReturn:
    xor  a              ; Clear A to a null character (zero)
    ld   (de), a        ; Store null to terminate string in buffer
    call OutputNewLine  ; Output new line character(s)
    ld   a, e           ; Calculate number of characters
    sub  h              ;  in input buffer
.InputLineNowExit:
    pop  hl
    pop  de
    ret


    ;; **********************************************************************
    ;; **  Output to console / output device, typically a terminal         **
    ;; **********************************************************************


    ;; Console output: Output character to console output device
    ;;   On entry: A = Character to output
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; This is the only place the actual new line codes (eg. CR/LF) are used
OutputChar:
    push af
    cp   kNewLine       ; New line character?
    jr   nz, .OutputCharNotNL ; No, so skip
    ld   a, kReturn     ; Yes, so output physical new line
.OutputCharWait1:
    call JpConOut       ;  to console..
    jr   z, .OutputCharWait1
    ld   a, kLinefeed
.OutputCharNotNL:
.OutputCharWait2:
    call JpConOut       ; Output character to console
    jr   z, .OutputCharWait2
.OutputCharExit:
    pop  af
    ret


    ;; Console output: Output new line character(s)
    ;;   On entry: No parameters
    ;;   On exit:  A BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; This is the only place the actual new line codes (eg. CR/LF) are used
OutputNewLine:
    push af
    ld   a, kNewLine    ; Get new line character
    call OutputChar     ; Output carriage return character
    pop  af
    ret


    ;; Console output: Output a zero (null) terminated string
    ;;   On entry: DE= Start address of string
    ;;   On exit:  DE= Address after null
    ;;             AF BC HL IX IY I AF' BC' DE' HL' preserved
    ;;             Interrupts enabled during this call
    ;; Supports \n for new line
OutputZString:
    push af
.OutputZStringNext:
    ld   a, (de)        ; Get character from string
    inc  de             ; Point to next character
    or   a              ; Null terminator?
    jr   z, .OutputZStringFinished ; Yes, so we've finished
    call OutputChar     ; Output character
    jr   .OutputZStringNext ; Go process next character
.OutputZStringFinished:
    pop  af
    ret


    ;; **********************************************************************
    ;; **  Private functions                                                **
    ;; **********************************************************************


    #ifndef IncludeUtilities
    ;; This function is normal provided by the Utilities module, but if this
    ;; build does not include Utilities then assemble the function here.
    ;; Utility: Convert character to upper case
    ;;   On entry: A = Character in either case
    ;;   On exit:  A = Character in upper case
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
ConvertCharToUCase:
    cp   'a'            ; Character less than 'a'?
    ret  c              ; Yes, so finished
    cp   'z'+1          ; Character greater than 'z'?
    ret  nc             ; Yes, so finished
    sub  'a'-'A'        ; Convert case
    ret
    #endif


    ;; **********************************************************************
    ;; **  Private workspace (in RAM)                                      **
    ;; **********************************************************************

    .bss

iConInChar:
    .db  0              ; Console input character waiting
iConInBuf:
    .dw  0              ; Console input buffer start


    ;; **********************************************************************
    ;; **  End of Console support module                                   **
    ;; **********************************************************************
