    ;; **********************************************************************
    ;; **  Compact Flash Information                 by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif
    ;;
    ;; **  Written as a Small Computer Monitor App
    ;; **  Version 0.4.1 SCC 2018-06-02
    ;; **  www.scc.me.uk
    ;;
    ;; **********************************************************************
    ;;
    ;; This App reads compact flash card identification information and
    ;; displays some of it.
    ;;
    ;; **********************************************************************

    #include "scm-api.h"
    #include "compactflash.h"

    ;; **********************************************************************
    ;; **  Memory map
    ;; **********************************************************************

    .equ Buffer, 0x9100


    ;; **********************************************************************
    ;; **  Main program code
    ;; **********************************************************************

    .global Main
Main:
    ;; Initialise
    call cfInit         ; Initialise Compact Flash functions

    ;; Output program details
    ld   de, About      ; Text: "Compact flash card info..."
    call aOutputText
    call aOutputNewLine ; Output new line

    call aOutputNewLine ; Output new line

    ;; Test if compact flash card is present
    call cfTstPres      ; Test if compact flash card is present
    jp   nz, ReportErr  ; Report error and exit program

    ;; Get Compact flash identification info
    ld   hl, Buffer     ; Destination address for data read
    call cfInfo         ; Read CF identification info
    jp   nz, ReportErr  ; Report error and exit program

    ;; Display results -> Number of sectors on card
    ld   de, NumSectors ; Test: "Number of sectors on card: "
    call aOutputText
    call uOutputHexPref ; Output '$' (or whatever)
    ld   de, (Buffer+14)
    call uOutputHexWord ; Output most significant word
    ld   de, (Buffer+16)
    call uOutputHexWord ; Output least significant word
    call aOutputNewLine ; Output new line

    ;; Display results -> Card size
    ld   de, CardSize   ; Text: "Card size: "
    call aOutputText
    ld   de, (Buffer+14) ; Number of sectors hi word
    ld   hl, (Buffer+16) ; Number of sectors lo word
    call cfSize         ; Get size in DE, units in A
    call uOutputDecWord ; Output decimal word DE
    call aOutputChar
    ld   a, 'B'         ; Get Bytes character
    call aOutputChar
    call aOutputNewLine ; Output new line

    call aOutputNewLine ; Output new line

    ;; Display results -> Model details
    ld   de, Model      ; Text: "Card model: "
    call aOutputText
    ld   a, 20          ; Number of character pairs
    ld   de, Buffer+54  ; Start of text
    call TextSwap       ; Output model text
    call aOutputNewLine ; Output new line

    ;; Display results -> Serial number
    ld   de, Serial     ; Text: "Serial number: "
    call aOutputText
    ld   a, 20          ; Number of characters
    ld   de, Buffer+20  ; Start of text
    call Text           ; Output model text
    call aOutputNewLine ; Output new line

    ;; Display results -> Firmware version
    ld   de, Version    ; Text: "Firmware version: "
    call aOutputText
    ld   a, 4           ; Number of character pairs
    ld   de, Buffer+46  ; Start of text
    call TextSwap       ; Output model text
    call aOutputNewLine ; Output new line

    call aOutputNewLine ; Output new line

    ;; Display results -> Default number of cylinders
    ld   de, Cylinders  ; Text: "... cylinders: "
    ld   hl, Buffer+2   ; Location of data word
    call Parameter      ; Output parameter

    ;; Display results -> Default number of heads
    ld   de, Heads      ; Text: "... headss: "
    ld   hl, Buffer+6   ; Location of data word
    call Parameter      ; Output parameter

    ;; Display results -> Default number of sectors per track
    ld   de, Sectors    ; Text: "... sectors: "
    ld   hl, Buffer+12  ; Location of data word
    call Parameter      ; Output parameter

    #ifdef NOCHANCE
    ;; Display results -> Number of unformated bytes per sector
    ;; Code excluded as this value is now considered obsolete
    ;; and does not always return sensible numbers
    ld   de, Bytes      ; Location of message
    ld   hl, Buffer+10  ; Location of data word
    call Parameter      ; Output parameter
    #endif

    call aOutputNewLine ; Output new line

    ;; Display results -> Compact Flash diagnostic test result
    ld   de, Diagnose
    call aOutputText    ; Output "Diagnostic... "
    call cfDiagnose     ; Run diagnostics and return error code
    jr   nz, Main.Failed ; Did diagnostic pass?
    ld   de, Passed     ; Passed ...
    call aOutputText    ; Output "Passed... "
    jr   Main.EndDiag
Main.Failed:
    ld   de, Failed     ; Failed ...
    call aOutputText    ; Output "Failed... "
    call uOutputHexPref ; Output hex prefix
    call uOutputHexByte ; Output result as hex byte
Main.EndDiag:
    call aOutputNewLine ; Output new line

    ret

ReportErr:
    call aOutputNewLine
    call cfGetError     ; Get error number
    ld   de, cfErrMsgs  ; Point to list of error messages
    call uFindString    ; Find error message string
    call aOutputText    ; Output message at DE
    call aOutputNewLine ; Output new line
    ret


    ;; **********************************************************************
    ;; **  Messages
    ;; **********************************************************************

About:
    .asciz "Compact flash card information v0.4 by Stephen C Cousins"
NumSectors:
    .asciz "Number of sectors on card: "
CardSize:
    .asciz "Card size: "
Model:
    .asciz "Card model:       "
Serial:
    .asciz "Serial number:    "
Version:
    .asciz "Firmware version: "
Cylinders:
    .asciz "Default number of cylinders:  "
Heads:
    .asciz "Default number of heads:      "
Sectors:
    .asciz "Default sectors per track:    "
Diagnose:
    .asciz "Card's self diagnostic test "
Passed:
    .asciz "passed"
Failed:
    .asciz "failed: code "


    ;; **********************************************************************
    ;; **  Support functions
    ;; **********************************************************************

    ;; Output parameter (string plus hex word)
Parameter:
    push hl
    call aOutputText
    call uOutputHexPref ; Output '$' (or whatever)
    pop  hl
    ld   e, (hl)        ; Get parameter address...
    inc  hl
    ld   d, (hl)
    call uOutputHexWord ; Output hex parameter value
    call aOutputNewLine ; Output new line
    ret


    ;; Output text (at DE) length (A)
Text:
    push af
    push bc
    push de
    ld   b, a           ; Number of characters
    ld   a, kQuote      ; Quotation mark
    call aOutputChar
Text.Loop:
    ld   a, (DE)        ; Get character from text
    call aOutputChar
    inc  de             ; Point to next character
    djnz Text.Loop
    ld   a, kQuote      ; Quotation mark
    call aOutputChar
    pop  de
    pop  bc
    pop  af
    ret


    ;; Output text (at DE) number of character pairs (A)
    ;; Character order swapped in each word
TextSwap:
    push af
    push bc
    push de
    ld   b, a           ; Number of characters
    ld   a, kQuote      ; Quotation mark
    call aOutputChar
TextSwap.Loop:
    inc  de
    ld   a, (DE)        ; Get first CharOut of pair
    dec  de
    call aOutputChar
    ld   a, (DE)        ; Get second character of pair
    call aOutputChar
    inc  de             ; Point to next character pair
    inc  de
    djnz TextSwap.Loop
    ld   a, kQuote      ; Quotation mark
    call aOutputChar
    pop  de
    pop  bc
    pop  af
    ret
