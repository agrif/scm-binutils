    ;; **********************************************************************
    ;; **  Limited CP/M style FDOS support           by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    #ifdef IncludeFDOS

    ;; Last FDOS function number
    #define kFDOSLast +((.FDOSTableEnd-.FDOSTable)/2 - 1)

    ;; Currently this is just a proff of concept!

    ;; FDOS: Main entry point
    ;;   On entry: C = Function number
    ;;             DE = Parameter (as specified by function)
    ;;   On exit:  A = Single byte value (as specified by function)
    ;;             HL = Double byte value (as specified by function)
    ;;             IX IY I AF' BC' DE' HL' preserved
    ;; For compatibility functions return with A=L and B=H.
    ;; Unsupported or out of range functions return A,B,H and L = zero.
FDOS:
    ld   hl, .FDOSTable ; Start of function address table
    ;;ld   b, a         ; Preserve A
    ld   a, c           ; Get function number
    cp   kFDOSLast+1    ; Supported function?
    jr   nc, FDOSExit   ; No, so go..
    ;;ld   a, b         ; Restore A
    ld   b, 0
    add  hl, bc         ; Calculate table pointer..
    add  hl, bc
    ld   b, (hl)        ; Read function address from table..
    inc  hl
    ld   h, (hl)
    ld   l, b
    jp   (hl)           ; Jump to function address
    ;; Exit for unsupported or out of range functions
FDOSExit:
    xor  a              ; A=0
    ld   b, a           ; B=0
    ld   h, a           ; H=0
    ld   l, a           ; L=0
    ret


    ;; FDOS: Function 1: Console input
    ;;   On entry: No parameters required
    ;;   On exit:  A = ASCII character from input
    ;;             IX IY I AF' BC' DE' HL' preserved
    ;; WARNING: Only partially implemented
FDOSConIn:
    jp   InputChar


    ;; FDOS: Function 2: Console output
    ;;   On entry: E = ASCII character to be output
    ;;   On exit:  IX IY I AF' BC' DE' HL' preserved
    ;; WARNING: Only partially implemented
FDOSConOut:
    ld   a, e
    jp   OutputChar

    .section .rodata

    ;; FDOS: Function address table
    ;; This table contains a list of addresses, one for each FDOS function.
    ;; Each is the address of the subroutine for the relevant function.
.FDOSTable:
    .dw  Reset          ;  0 = System reset
    .dw  FDOSConIn      ;  1 = Console input
    .dw  FDOSConOut     ;  2 = Console output
    ;;.dw  FDOSExit     ;  3 = Reader input
    ;;.dw  FDOSExit     ;  4 = Punch output
    ;;.dw  FDOSExit     ;  5 = List output
    ;;.dw  FDOSExit     ;  6 = Direct console I/O
    ;;.dw  FDOSExit     ;  7 = Get I/O byte
    ;;.dw  FDOSExit     ;  8 = Set I/O byte
    ;;.dw  FDOSExit     ;  9 = Read string
    ;;.dw  FDOSExit     ; 10 = Read console buffer
    ;;.dw  FDOSExit     ; 11 = Get console status
    ;;.dw  FDOSExit     ; 12 = Return version number
    ;;.dw  FDOSExit     ; 13 = Reset disk system
    ;;.dw  FDOSExit     ; 14 = Select disk
    ;;.dw  FDOSExit     ; 15 = Open file
    ;;.dw  FDOSExit     ; 16 = Close file
    ;;.dw  FDOSExit     ; 17 = Search for first
    ;;.dw  FDOSExit     ; 18 = Search for next
    ;;.dw  FDOSExit     ; 19 = Delete file
    ;;.dw  FDOSExit     ; 20 = Read sequential
    ;;.dw  FDOSExit     ; 21 = Write sequential
    ;;.dw  FDOSExit     ; 22 = Make file
    ;;.dw  FDOSExit     ; 23 = Rename file
    ;;.dw  FDOSExit     ; 24 = Return login vector
    ;;.dw  FDOSExit     ; 25 = Return current disk
    ;;.dw  FDOSExit     ; 26 = Set DMA address
    ;;.dw  FDOSExit     ; 27 = Get addr (alloc)
    ;;.dw  FDOSExit     ; 28 = Write protect disk
    ;;.dw  FDOSExit     ; 29 = Get R/O vector
    ;;.dw  FDOSExit     ; 30 = Set file attributes
    ;;.dw  FDOSExit     ; 31 = Get addr (disk params)
    ;;.dw  FDOSExit     ; 32 = Set/get user code
    ;;.dw  FDOSExit     ; 33 = Read random
    ;;.dw  FDOSExit     ; 34 = Write random
    ;;.dw  FDOSExit     ; 35 = Compute file size
    ;;.dw  FDOSExit     ; 36 = Set random record
    ;;.dw  FDOSExit     ; 37 = Reset drive
    ;;.dw  FDOSExit     ; 38 = Unspecified
    ;;.dw  FDOSExit     ; 39 = Unspecified
    ;;.dw  FDOSExit     ; 40 = Write random with zero fill
.FDOSTableEnd:


    ;; **********************************************************************
    ;; **  End of CP/M style FDOS support module                           **
    ;; **********************************************************************

    #endif // IncludeFDOS
