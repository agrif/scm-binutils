    ;; **********************************************************************
    ;; **  Application Programming Interface (API)   by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module provides a means of external software accessing some of
    ;; the features of the Small Computer Monitor.
    ;;
    ;; API functions are accessed by:
    ;; Loading C register with the function number
    ;; Loading registers as required by the selected function
    ;; Calling address 0x0030 (either with CALL or RST instruction)
    ;;
    ;; Public functions provided:
    ;;   APIHandler            API main entry point

    #ifdef IncludeAPI

    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    ;; Last API function number
    #define kAPILast +((.APITableEnd-.APITable)/2 - 1)

    ;; API: Main entry point
    ;;   On entry: C = Function number
    ;;             A, DE = Parameters (as specified by function)
    ;;   On exit:  AF,BC,DE,HL = Return values (as specified by function)
    ;;             IX IY I AF' BC' DE' HL' preserved
    ;; This handler modifies: F, B, HL but preserves A, C, DE
    ;; Other registers depend on API function called
APIHandler:
    ld   hl, .APITable  ; Start of function address table
    ld   b, a           ; Preserve A
    ld   a, c           ; Get function number
    cp   kAPILast+1     ; Supported function?
    ret  nc             ; No, so abort
    ld   a, b           ; Restore A
    ld   b, 0
    add  hl, bc         ; Calculate table pointer..
    add  hl, bc
    ld   b, (hl)        ; Read function address from table..
    inc  hl
    ld   h, (hl)
    ld   l, b
    jp   (hl)           ; Jump to function address


    .section .rodata

    ;; API: Function address table
    ;; This table contains a list of addresses, one for each API function.
    ;; Each is the address of the subroutine for the relevant function.
.APITable:
    .dw  SysReset       ; 0x00 = System reset
    .dw  InputChar      ; 0x01 = Input character
    .dw  OutputChar     ; 0x02 = Output character
    .dw  InputStatus    ; 0x03 = Input status
    .dw  InputLineTo    ; 0x04 = Input line
    .dw  InputLine      ; 0x05 = Input line default
    .dw  OutputZString  ; 0x06 = Output line
    .dw  OutputNewLine  ; 0x07 = Output new line
    .dw  GetVersion     ; 0x08 = Get version details
    .dw  ClaimJump      ; 0x09 = Claim jump table entry
    .dw  Delay          ; 0x0A = Delay in milliseconds
    .dw  OutputMessage  ; 0x0B = Output system message
    .dw  ReadJump       ; 0x0C = Read jump table entry
    .dw  SelConDev      ; 0x0D = Select console in/out device
    .dw  SelConDevI     ; 0x0E = Select console input device
    .dw  SelConDevO     ; 0x0F = Select console output device
    .dw  DevInput       ; 0x10 = Input from specified device
    .dw  DevOutput      ; 0x11 = Output to specifiec device
    .dw  JpIdle         ; 0x12 = Poll idle events
    .dw  IdleConfig     ; 0x13 = Configure idle events
    .dw  IdleTimer1     ; 0x14 = Timer 1 control
    .dw  IdleTimer2     ; 0x15 = Timer 2 control
    .dw  IdleTimer3     ; 0x16 = Timer 3 control
    .dw  PrtOInit       ; 0x17 = Output port initialise
    .dw  PrtOWr         ; 0x18 = Write to output port
    .dw  PrtORd         ; 0x19 = Read from output port
    .dw  PrtOTst        ; 0x1A = Test output port bit
    .dw  PrtOSet        ; 0x1B = Set output port bit
    .dw  PrtOClr        ; 0x1C = Clear output port bit
    .dw  PrtOInv        ; 0x1D = Invert output port bit
    .dw  PrtIInit       ; 0x1E = Input port initialise
    .dw  PrtIRd         ; 0x1F = Read from input port
    .dw  PrtITst        ; 0x20 = Test input port bit
    .dw  SetBaud        ; 0x21 = Set baud rate
    .dw  CLIExecute     ; 0x22 = Execute command line
    .dw  RomGetPtr      ; 0x23 = Get pointer to command line
    .dw  CLISkipDelim   ; 0x24 = Skip delimiter
    .dw  CLISkipNonDeli ; 0x25 = Skip non-delimiter
    .dw  CLIGetHexParam ; 0x26 = Get hex parameter
    .dw  GetConDev      ; 0x27 = Get console in/out devices
    .dw  GetMemTop      ; 0x28 = Get top of free memory
    .dw  SetMemTop      ; 0x29 = Set top of free memory

    #ifdef RAM_BANK_SUPPORT
    .dw  RdBankedRAM    ; 0x2A = Read banked RAM
    .dw  WrBankedRAM    ; 0x2B = Write banked RAM
    #endif
.APITableEnd:

    ;; carefully use new subsection to make sure this comes *after* the above
    .section .text.DummyRomGetPtr

    ;; Dummy entry points for unsupported features
    #ifndef IncludeRomFS
RomGetPtr:
    #endif
    ret


    ;; **********************************************************************
    ;; **  End of Application Programming Interface (API) module           **
    ;; **********************************************************************

    #endif // IncludeAPI
