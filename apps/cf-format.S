    ;; **********************************************************************
    ;; **  Compact Flash Format                      by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif
    ;;
    ;; **  Written as a Small Computer Monitor App
    ;; **  Verions 0.4.1 SCC 2018-06-02
    ;; **  www.scc.me.uk
    ;;
    ;; **********************************************************************
    ;;
    ;; Formats a compact flash card for use with CP/M.
    ;;
    ;; **********************************************************************

    #include "scm-api.h"
    #include "compactflash.h"


    ;; **********************************************************************
    ;; Memory map
    ;; **********************************************************************

    .equ Buffer, 0x9100 ; Data load address


    ;; **********************************************************************
    ;; **  Main program code
    ;; **********************************************************************

    .global Main
Main:
    ;; Initialise
    call cfInit         ; Initialise Compact Flash functions

    ;; Output program details
    ld   de, About      ; Pointer to error message
    call aOutputText    ; Output "Compact flash card..."
    call aOutputNewLine ; Output new line

    call aOutputNewLine ; Output new line

    ;; Test if compact flash present
    call cfTstPres      ; Test if compact flash card is present
    jp   nz, ReportErr  ; Report error and exit program

    ;; Get Compact flash identification info
    ld   hl, Buffer     ; Destination address for data read
    call cfInfo         ; Read CF identification info
    jp   nz, ReportErr  ; Report error and exit program

    ;; Output card size in MB
    ld   de, CardSize
    call aOutputText    ; Output "Card size: "
    ld   de, (Buffer+14) ; Number of sectors hi word
    ld   hl, (Buffer+16) ; Number of sectors lo word
    call cfSize         ; Get size in DE, units in A
    push af             ; Preserve units character
    call uOutputDecWord ; Output decimal word DE
    call aOutputChar    ; Output units character eg. "M"
    ld   a, 'B'         ; Get Bytes character
    call aOutputChar    ; Output Bytes character "B"
    call aOutputNewLine ; Output new line
    pop  af             ; Restore units character

    call aOutputNewLine ; Output new line

    ;; Output number of drives to format
    cp   'M'            ; Card size in Megabytes?
    jr   nz, Main.SetMax ; No, so set max useful size of 128MB
    ld   a, d           ; Get hi byte of size in MB
    or   a              ; Zero? (ie. < 256MB)
    jr   z, Main.SetSize ; Yes, so set size to DE megabytes
Main.SetMax:
    ld   e, 128         ; Set max useful size of 128MB
Main.SetSize:
    srl  e              ; Convert size in MB (8 to 128)
    srl  e              ;  to number of 8 MB 'drives'
    srl  e
    ld   a, e           ; Get number of logical drives
    ld   (iDrives), a   ; Store number of logical drives
    push de
    ld   de, NumDrives  ; Pointer to message
    call aOutputText    ; Output "Number of drives..."
    pop  de
    call uOutputDecWord ; Ouput number of logical drives
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

    ld   de, Formatting ; Point to message
    call aOutputText    ; Output "Formatting: "
    ld   b, 0           ; Current drive (0 to N-1)
Main.Format:
    ld   a, b           ; Get drive number (0 to N-1)
    add  a, 'A'         ; Determine drive letter
    call aOutputChar    ; Output drive letter
    call cfFormat       ; Format logical drive E (1 to N-1)
    jp   nz, ReportErr  ; Report error and exit program
    inc  b              ; Increment drive number
    ld   a, (iDrives)   ; Get number of logical drive
    cp   b              ; Finished?
    jr   nz, Main.Format ; NO, so go format this drive
    call aOutputNewLine ; Output new line

    ld   de, Verifying  ; Point to message
    call aOutputText    ; Output "Verifying: "
    ld   b, 0           ; Current drive (0 to N-1)
Main.Verify:
    ld   a, b           ; Get drive number (0 to N-1)
    add  a, 'A'         ; Determine drive letter
    call aOutputChar    ; Output drive letter
    call cfVerifyF      ; Verify logical drive E (1 to N-1)
    jp   nz, ReportErr  ; Report error and exit program
    inc  b              ; Increment drive number
    ld   a, (iDrives)   ; Get number of logical drive
    cp   b              ; Finished?
    jr   nz, Main.Verify ; NO, so go verify this drive
    call aOutputNewLine ; Output new line

    call aOutputNewLine ; Output new line

    ld   de, Complete   ; Point to message
    call aOutputText    ; Output "Formatting complete"
    call aOutputNewLine ; Output new line

    ret


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
    .asciz "Compact Flash card format v0.4 by Stephen C Cousins"
CardSize:
    .asciz "Card size: "
NumDrives:
    .asciz "Number of logical drives to format: "
Warning:
    .asciz "WARNING: Format will erase all data from the card"
Confirm:
    .asciz "Do you wish to continue? (Y/N)"
Formatting:
    .asciz "Formatting drives: "
Verifying:
    .asciz "Verifying drives:  "
Complete:
    .asciz "Formatting complete"


    ;; **********************************************************************
    ;; **  Variables
    ;; **********************************************************************

    .bss                ; Data section

iDrives:
    .db  0              ; Number of logical drives to format
