    ;; **********************************************************************
    ;; **  Compact Flash Test                        by Stephen C Cousins  **
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

    .equ Buffer, 0x9000


    ;; **********************************************************************
    ;; **  Main program code
    ;; **********************************************************************

    .global Main
Main:
    ;; Initialise
    call cfInit         ; Initialise Compact Flash functions

    ;; Output program details
    ld   de, About      ; Pointer to error message
    call aOutputText    ; Output "Compact flash card test..."
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
    ld   de, NumSectors
    call aOutputText    ; Output "Number of sectors on card: "
    call uOutputHexPref ; Output '$' prefix (or whatever)
    ld   de, (Buffer+14)
    ld   (iSize+2), de  ; Store as card size MSW
    call uOutputHexWord ; Output most significant word
    ld   de, (Buffer+16)
    ld   (iSize+0), de  ; Store as card size LSW
    call uOutputHexWord ; Output least significant word
    call aOutputNewLine

    ;; Adjust end sector number which needs to be 3 less than total as we
    ;; test in batches of 4 sectors
    xor  a              ; Clear carry flag
    ld   hl, (iSize+0)
    ld   de, 3
    sbc  hl, de         ; Subtract 3
    ld   (iSize+0), hl
    ld   hl, (iSize+2)
    ld   de, 0
    sbc  hl, de         ; Subtract carry flag
    ld   (iSize+2), hl

    ;; Display results -> Card size
    ld   de, CardSize
    call aOutputText    ; Output "Card size: "
    ld   de, (Buffer+14) ; Number of sectors hi word
    ld   hl, (Buffer+16) ; Number of sectors lo word
    call cfSize         ; Get size in DE, units in A
    call uOutputDecWord ; Output decimal word DE
    call aOutputChar    ; Output units character eg. "M"
    ld   a, 'B'         ; Get Bytes character
    call aOutputChar    ; Output Bytes character "B"
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
    call uOutputHexPref ; Output hext prefix
    call uOutputHexByte ; Output result as hex byte
Main.EndDiag:
    call aOutputNewLine ; Output new line

    call aOutputNewLine ; Output new line

    ;; Warning and confirm
    ld   de, Warning    ; Pointer to message
    call aOutputText    ; Output "WARNING:..."
    call aOutputNewLine
Main.Wait:
    ld   de, Confirm    ; Pointer to message
    call aOutputText    ; Output "Are you sure..."
    call aInputChar     ; Get key
    call aOutputNewLine ; Output new line
    and  0b01011111     ; Convert lower case to upper case
    cp   'N'
    ret  z              ; Abort if key = 'N'
    cp   'Y'
    jr   nz, Main.Wait  ; If not 'Y' ask again

    call aOutputNewLine ; Output new line


    ;; Test compact flash card
    ;; For each sector:
    ;; Fill sector+0 with 0x00
    ;; Fill sector+1 with 0xFF
    ;; Fill sector+2 with 0x55
    ;; Fill sector+3 with 0xAA
    ;; Verify all 4 sectors contain the correct data
    ;; Increment sector number
    ;; The sector address Sector+n only uses 8-bit addition so the
    ;; current sector test wraps around in blocks of 256 sectors
Test:
    xor  a              ; Start at sector zero
    ld   (iSector+0), a
    ld   (iSector+1), a
    ld   (iSector+2), a
    ld   (iSector+3), a
    ;; Test current sector
Test.Loop:
    xor  a
    ld   (iErrNum), a   ; Clear error number
    ld   (iFailCnt), a  ; Clear failure counter
    ;; Output current sector number
    ld   de, Sector
    call aOutputText    ; Output "Sector being tested: "
    call uOutputHexPref ; Output '$' (or whatever)
    ld   de, (iSector+2)
    call uOutputHexWord ; Output most significant word
    ld   de, (iSector+0)
    call uOutputHexWord ; Output least significant word
    ld   a, kSpace
    call aOutputChar    ; Output a space
    ;; Prepare start sector number (DEB) for writing
    ld   a, (iSector+0)
    ld   b, a
    ld   de, (iSector+1)
    ;; Fill sector+0 with 0x00
    ld   a, 0x00
    call Write          ; Write sector
    jr   nz, Test.Fail
    ;; Fill sector+1 with 0xFF
    inc  b
    ld   a, 0xff
    call Write          ; Write sector
    jr   nz, Test.Fail
    ;; Fill sector+2 with 0x55
    inc  b
    ld   a, 0x55
    call Write          ; Write sector
    jr   nz, Test.Fail
    ;; Fill sector+3 with 0xAA
    inc  b
    ld   a, 0xaa
    call Write          ; Write sector
    jr   nz, Test.Fail
    ;; Prepare start sector number (DEB) for verify
Test.VeriTest:
    ld   a, (iSector+0)
    ld   b, a
    ld   de, (iSector+1)
    ;; Verify sector+0
    ld   a, 0x00
    call Verify         ; Verify sector
    jr   nz, Test.Fail
    ;; Verify sector+1
    inc  b
    ld   a, 0xff
    call Verify         ; Verify sector
    jr   nz, Test.Fail
    ;; Verify sector+2
    inc  b
    ld   a, 0x55
    call Verify         ; Verify sector
    jr   nz, Test.Fail
    ;; Verify sector+3
    inc  b
    ld   a, 0xaa
    call Verify         ; Verify sector
    jr   nz, Test.Fail
    ;; Sector test passed
    ld   de, Passed     ; Passed ...
    call aOutputText    ; Output "Passed... "
    call aOutputNewLine ; Output new line
    ;; Test for character input
    call aInputStatus   ; Character input status?
    ret  nz             ; Abort if character available
    ;; Increment sector number
Test.Next:
    ld   hl, iSector    ; Point to current sector number
    inc  (hl)           ; Increment...
    jr   nz, Test.TstEnd
    inc  hl
    inc  (hl)
    jr   nz, Test.TstEnd
    inc  hl
    inc  (hl)
    jr   nz, Test.TstEnd
    inc  hl
    inc  (hl)
    ;; Test complete? (ie. reached end of card)
Test.TstEnd:
    ld   hl, iSector    ; Point to current sector number
    ld   de, iSize      ; Point to card size in sectors
    ld   b, 3           ; Number of bytes to compare
Test.Compare:
    ld   a, (DE)        ; Get byte from card size in sectors
    cp   (hl)           ; Compare to current sector number
    jp   nz, Test.Loop  ; Not zero, so go test next sector
    inc  hl             ; Increment to next byte
    inc  de             ; Increment to next byte
    djnz Test.Compare   ; Repeat until all bytes compared
    ;; Test completed
Test.Finished:
    ld   de, Complete   ; Test complete ...
    call aOutputText    ; Output "Test complete... "
    call aOutputNewLine ; Output new line
    ret
    ;; Failed a test
Test.Fail:
    ld   (iErrNum), a   ; Store error number
    ld   de, Failed     ; Pointer to message
    call aOutputText    ; Output "Failed... "
    call uOutputHexPref ; Output hex prefix
    call uOutputHexByte ; Output result as hex byte
    call ReportErr      ; Output descriptive error msg
    ld   hl, iFailCnt   ; Point to failure counter
    inc  (hl)           ; Increment failure counter
    ;; Check for verify error
    ;; ld   a, (hl)       ;Get error counter
    ;; cp   1             ;First error
    ;; jr   nz, Test.Wait     ;No, so do not retry
    call cfGetError     ; Get error number
    cp   CF_Verify      ; Verify error?
    jr   nz, Test.NotVeri ; Yes, so repeat the verify
    ;; Verify error
Test.AskV:
    ld   de, RetryV     ; Pointer to message
    call aOutputText    ; Output "Retry verify..."
    call aInputChar     ; Get key
    call aOutputNewLine ; Output new line
    and  0b01011111     ; Convert lower case to upper case
    cp   'N'
    jr   z, Test.Wait   ; Skip if key = 'N'
    cp   'Y'
    jr   nz, Test.AskV  ; If not 'Y' ask again
    call aOutputNewLine ; Output new line
    jp   Test.VeriTest
Test.NotVeri:
    ;; Wait for Continue Y/N
Test.Wait:
    ld   de, Confirm    ; Pointer to message
    call aOutputText    ; Output "Are you sure..."
    call aInputChar     ; Get key
    call aOutputNewLine ; Output new line
    and  0b01011111     ; Convert lower case to upper case
    cp   'N'
    ret  z              ; Abort if key = 'N'
    cp   'Y'
    jr   nz, Test.Wait  ; If not 'Y' ask again
    call aOutputNewLine ; Output new line
    jp   Test.Next


ReportErr:
    call aOutputNewLine ; Output new line
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
    .asciz "Compact flash card test v0.4 by Stephen C Cousins"
Warning:
    .asciz "WARNING: This will erase all data from the card"
Confirm:
    .asciz "Do you wish to continue? (Y/N)"
NumSectors:
    .asciz "Number of sectors on card: "
CardSize:
    .asciz "Card size: "
Diagnose:
    .asciz "Card's self diagnostic test "
Passed:
    .asciz "passed"
Failed:
    .asciz "failed: code "
Sector:
    .asciz "Sector: "
RetryV:
    .asciz "Do you wish to retry the verify? (Y/N)"
Complete:
    .asciz "Test complete"


    ;; **********************************************************************
    ;; **  Support functions
    ;; **********************************************************************


    ;; Write test sector
    ;;   On entry: A = Data byte to fill the sector buffer with
    ;;             DEB = Sector number to write
    ;;             HL = Source address for write sector data
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
Write:
    call PrepData       ; Prepare test data
    push hl
    ld   c, 1           ; Write one sector
    ld   hl, Buffer     ; Pointer to data
    call cfWrite        ; Write data to sector
    pop  hl
    ret


    ;; Verify test sector
    ;;   On entry: A = Data byte to fill the sector buffer with
    ;;             DEB = Sector number to verify
    ;;             HL = Source address for write sector data
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
Verify:
    call PrepData       ; Prepare test data
    push hl
    ld   c, 1           ; Verify one sector
    ld   hl, Buffer     ; Pointer to data
    call cfVerify       ; Verify sector
    pop  hl
    ret


    ;; Prepare test data
    ;;   On entry: A = Data byte to fill the sector buffer with
    ;;   On exit:  A BC DE HL IX IY I AF' BC' DE' HL' preserved
PrepData:
    push bc
    push hl
    ld   hl, Buffer
    ld   b, 0
PrepData.Loop:
    ld   (hl), a
    inc  hl
    ld   (hl), a
    inc  hl
    djnz PrepData.Loop
    pop  hl
    pop  bc
    ret


    ;; Output parameter (string plus hex word)
Parameter:
    push hl
    call aOutputText    ; Output message
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
    call aOutputChar    ; Output quote mark
Text.Loop:
    ld   a, (DE)        ; Get character from text
    call aOutputChar    ; Ouptut character
    inc  de             ; Point to next character
    djnz Text.Loop
    ld   a, kQuote      ; Quotation mark
    call aOutputChar    ; Output quote mark
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
    call aOutputChar    ; Output quote mark
TextSwap.Loop:
    inc  de
    ld   a, (DE)        ; Get first CharOut of pair
    dec  de
    call aOutputChar    ; Ouptut CharOutr
    ld   a, (DE)        ; Get second character of pair
    call aOutputChar    ; Ouptut CharOutr
    inc  de             ; Point to next character pair
    inc  de
    djnz TextSwap.Loop
    ld   a, kQuote      ; Quotation mark
    call aOutputChar    ; Output quote mark
    pop  de
    pop  bc
    pop  af
    ret


    ;; **********************************************************************
    ;; **  Variables
    ;; **********************************************************************

    .bss

iSector:
    .ds  4              ; Current sector number
iSize:
    .ds  4              ; Card size in sectors
iErrNum:
    .ds  1              ; Current error number
iFailCnt:
    .ds  1              ; Failure count at current sector
