    ;; **********************************************************************
    ;; **  Breakpoint Support                        by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module provides breakpoint and single stepping support.
    ;;
    ;; Limitations of breakpoints and single step:
    ;;
    ;; You can't set breakpoints in read only memory. As a result you can't
    ;; single step through code in read only memory.
    ;;
    ;; Single stepping code in the monitor itself is problematic so it is
    ;; prevented. To achieve this any instruction trying to call or jump
    ;; into the monitor is not stepped, but instead the instruction after
    ;; is trapped. As a result calls into the monitor are stepped over.
    ;; To achieve this for the monitor's API etc we also step over calls
    ;; and jumps to the address range 0x0000 to 0x00FF.
    ;;
    ;; An instruction that jumps to itself will never run if you attempt to
    ;; single step it. For examples:
    ;;   Loop:  JP Loop
    ;;   Loop:  DJNZ Loop
    ;; Single step does not run the instruction as a breakproint is set there
    ;; each time you try to step. The only case this is likely to be an issue
    ;; is where DJNZ loops back to itself to create a short delay.
    ;;
    ;; Public functions provided:
    ;;   BPInitialise          Initialise the breakpoint module
    ;;   BPHandler             Code executed when breakpoint encountered
    ;;   BPReqSet              Clear set the requested breakpoint address
    ;;   BPReqClr              Clear the requested breakpoint address
    ;;   BPGo                  Breakpoint: Jump here for Go command
    ;;   BPStep                Breakpoint: Jump here for Step command
    ;;   BPIsInMonitor         Is address in monitor code?

    #ifdef IncludeBreakpoint

    ;; **********************************************************************
    ;; **  Constants                                                       **
    ;; **********************************************************************

    #define kBPOpcode  0xEF         // Breakpoint restart = RST 0x28
    #define kBPAddress 0x28         // Breakpoint reset address = 0x28


    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    ;; Breakpoint: Initialise this module
    ;;   On entry: No parameters required
    ;;   On exit:  BC IX IY I AF' BC' DE' HL' preserved
BPInitialise:
    call BPClear        ; Clear breakpoint from memory
    call BPReqClr       ; Clear requested breakpoint address
    ld   hl, kBPAddress ; Address of breakpoint restart
    ld   (hl), 0xc3     ; Write JP instruction at restart
    inc  hl             ; Increment address pointer
    ld   de, BPHandler  ; Write address of breakpoint handler
    ld   (hl), e        ;  at restart...
    inc  hl             ;  Should use LD (HL),BPHandler/256 etc
    ld   (hl), d        ;  but homebrew assembler fails at that
    ret                 ;  TODO fix the assembler!


    ;; Breakpoint: Breakpoint handler
    ;; Directed here when suitable breakpoint is encountered
BPHandler:
    ;; Store state of processor
    ld   (iBC), bc      ; Store BC
    ld   (iDE), de      ; Store DE
    ld   (iHL), hl      ; Store HL
    ld   (iIX), ix      ; Store IX
    ld   (iIY), iy      ; Store IY
    pop  hl             ; Get address of breakpoint + 1
    dec  hl             ; Adjust to address of breakpoint
    ld   (iPC), hl      ; Store address of breakpoint
    ld   (iSP), SP      ; Store stack pointer at breakpoint
    ex   (sp), hl
    ld   (iCSP), hl     ; Store contents of SP
    ex   (sp), hl
    push af             ; Copy AF to HL...
    pop  hl             ;  and store AF value
    ld   (iAF), hl      ; Store AF
    ld   a, I
    ld   (iIR+1), a     ; Store I register
    ld   a, R
    ld   (iIR), a       ; Store R register
    ;; Stack pointer now same value as it was before the breakpoint's restart
    ;; What caused this breakpoint?
    ld   hl, (iPC)      ; Did breakpoint restart occur at
    ld   a, l           ;  the current breakpoint?
    ld   d, h           ;  ie. PC=BP
    ld   hl, (iBPAddr)
    cp   l              ; LSBytes equal
    jr   nz, .BPHandlerTrap ; No, so TRAP
    ld   a, d
    cp   h              ; MSBytes equal
    jr   nz, .BPHandlerTrap ; No, so TRAP
    ;; A Restart 28 instruction was encountered at the breakpoint addr
    call BPClear
    ld   a, (iBPType)   ; Get breakpoint type
    or   a              ; Type 0 = Once?
    jr   nz, .BPHandlerReg ; No, so may be single stepping
    ld   de, szBreak    ; Point to message "Breakpoint"
    jr   .BPHandlerMsg
    ;; A Restart 28 instruction was encountered but not the breakpoint
.BPHandlerTrap:
    ld   de, szTrap     ; Point to message "Trap"
.BPHandlerMsg:
    call OutputZString  ; Output message
    ;; Output register values as they were at the breakpoint
.BPHandlerReg:
    call WrRegister1    ; Build primary register line
    call StrPrint       ; Output primary register line
    ;;call WrRegister2  ; Build secondary register line
    ;;call StrPrint     ; Output secondary register line
    #ifdef IncludeDisassemble
    ;; Disassemble this instruction and output it
    ;; Stack pointer now same value as it was before the breakpoint's restart
    ld   a, (iBPType)   ; Get breakpoint type
    or   a              ; Type 0 = Once?
    jp   z, WarmStart   ; Yes, so do not set another breakpoint
    ;; Single step mode, so wait for user key press
    call InputMore      ; Print more?
    jp   nz, WarmStart  ; No, so exit
    ;; Prepare to step next instruction
    ld   hl, (iPC)      ; Get current address
    call DisWrInstruction ; Disassemble instruction
    ld   d, h           ; Store address of next instruction
    ld   e, l           ;  (the one immediately after this)
    call StrWrNewLine   ; Write new line to string buffer
    call StrPrint       ; Print to output device
    call DisGetNextAddress ; Get PC after executing this inst
    ;; Catch jumps and calls into the monitor code and bottom 256 bytes
    ;; as we can't step reliably through code in the monitor itself
    ;; Also we trap the end of user program when it returns to monitor
    ;;ld   a, h         ; Get hi byte of address of next inst
    ;;or   a            ; Is next inst in bottom 256 bytes?
    ;;jr   z, .BPHandlerStepOver ; Yes, so step over this instruction
    call BPIsInMonitor  ; Next instruction within monitor code?
    jr   z, .BPHandlerStepOver ; Yes, so step over this instruction
    ;; Attempt to follow this instruction (ie. follow jumps etc)
    call BPSet          ; Attempt to set breakpoint here
    jr   z, .BPHandlerSetOK ; Set ok (ie in RAM) so skip
    ;; Attempt to step over this instruction (ie. don't follow jumps etc)
    ;; as we can't step through ROM code or reliably through monitor code
.BPHandlerStepOver:
    ld   h, d           ; Get address after this instruction
    ld   l, e           ;  as we can't step into ROM
    ld   de, szOver
    call OutputZString  ; Output "Stepping over..."
    call BPSet          ; Attempt to set breakpoint here
    ret  nz             ; Abort as failed so set (not in RAM)
    ;; Brakpoint set for next step ok
.BPHandlerSetOK:
    #else
    ;; No disassembler so just display address and hex bytes
    ;; Stack pointer now same value as it was before the breakpoint's restart
    call StrInitDefault ; Initialise default string buffer
    ld   de, (iPC)      ; Get current address
    call StrWrHexWord   ; Display breakpoint address
    ld   a, ':'
    call StrWrChar      ; Print ':'
    ld   a, 4           ; Get length of instruction
    ld   b, a
    ld   l, a
.BPHandlerLoop:
    call StrWrSpace
    ld   a, (de)        ; Read byte at PC
    call StrWrHexByte
    inc  de
    djnz .BPHandlerLoop
    ld   a, 5           ; TAB cursor..
    sub  l
    ld   l, a
    add  l
    add  l
    call StrWrSpaces    ; Display A spaces
    ld   a, '?'
    call StrWrChar      ; Print '?' (no disassembly)
    call StrWrNewLine
    call StrPrint       ; Print to output device
    ret
    #endif
    ;; Restore state of processor
    ;; Stack pointer now same value as it was before the breakpoint's restart
BPRestore:
    ld   a, (iIR+1)     ; Get value or I register
    ld   I, a           ; Retore I register
    ;;ld   a, (iIR)     ; Don't restore R as it is free
    ;;ld   r, a         ;    running refresh counter
    ld   hl, (iAF)      ; Get value of AF registers
    push hl
    pop  af             ; Restore AF
    ld   SP, (iSP)      ; Restore SP
    ld   hl, (iPC)      ; Get value of PC register
    push hl             ; Put continuation address on stack
    ld   iy, (iIY)      ; Restore IY
    ld   ix, (iIX)      ; Restore IX
    ld   hl, (iHL)      ; Restore HL
    ld   de, (iDE)      ; Restore DE
    ld   bc, (iBC)      ; Restore BC
    ret                 ; Return to continuation address


    ;; Clear or set the requested breakpoint address
    ;; This does not actually set or clear the breakpoint in memory
    ;; The actually breakpoint is manipulated at reset, Go or Step
    ;;   On entry: HL = Breakpoint address required
    ;;   On exit:  BC DE IX IY I AF' BC' DE' HL' preserved
BPReqClr:
    ld   hl, 0          ; Address zero indicates no BP request
    jr   BPWrAddr       ; Go clear the breakpoint request
    ;;   On entry: HL = Breakpoint address required
    ;;   On exit:  If successful NZ flagged
    ;;             It can fail (Z flagged) if address is in monitor code
    ;;             BC DE IX IY I AF' BC' DE' HL' preserved
BPReqSet:
    call BPIsInMonitor  ; Is address HL in monitor code are
    ret  z              ; Yes, so return with Z flagged
BPWrAddr:
    ld   (iBPReq), hl   ; Store as requested BP address
    ret                 ; Return NZ for successfully Set


    ;; Breakpoint: Jump here for Go command
BPGo:
    xor  a              ; Set for breakpoint mode
    ld   (iBPType), a   ;  not single step mode
    ld   hl, (iBPReq)   ; Get requested breakpoint address
    call BPSet          ; Set the requested breakpoint
    jp   BPRestore      ; Restore registers from variables


    ;; Breakpoint: Jump here for Step command
BPStep:
    ld   a, 1           ; Set for single step mode
    ld   (iBPType), a   ;  not breakpoint mode
    ld   hl, (iPC)      ; Get next instruction address
    call BPSet          ; Set the requested breakpoint
    jp   BPRestore      ; Restore registers from variables


    ;; **********************************************************************
    ;; **  Private functions                                               **
    ;; **********************************************************************


    ;; Breakpoint: Set breakpoint
    ;;   On entry: HL = Address of breakpoint
    ;;   On exit:  If successful A = 0 and Z flagged
    ;;               otherwise A != 0 and NZ flagged
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Failure can occur when trying to set breakpoint to address which is
    ;; not RAM.
BPSet:
    call BPClear        ; Ensure previous breakpoint removed
    ld   a, h           ; Check if requested address is 0x0000
    or   l              ;  and if so abort as nothing to do
    ret  z
    ld   a, (hl)        ; Get contents of breakpoint address
    ld   (iBPData), a   ; Store as breakpoint data
    ld   (hl), kBPOpcode ; Write breakpoint opcode to address
    ld   a, (hl)        ; Read back to see if in RAM
    cp   kBPOpcode      ; Is it the breakpoint opcode?
    jr   nz, .BPSetFailure ; No, so failed to set
    ld   (iBPAddr), hl  ; Store requested breakpoint address
    xor  a              ; Return success A = 0 and Z flagged
    ret
.BPSetFailure:
    ld   a, 0xff        ; Return failure A != 0 and NZ flagged
    or   a
    ret


    ;; Breakpoint: Clear breakpoint
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
BPClear:
    push af
    push hl
    ld   hl, (iBPAddr)  ; Get current breakpoint address
    ld   a, l           ; Test if breakpoint address is 0xFFFF
    and  h              ; If it is 0xFFFF then breakpoint is not set
    cp   0xff           ; Breakpoint set?
    jr   z, .BPClearClrData ; No, so skip breakpoint clear
    ld   a, (hl)        ; Test if breakpoint contains breakpoint opcode
    cp   kBPOpcode      ; If it is then breakpoint is not set
    jr   nz, .BPClearClrAddr ; No, so skip breakpoint clear
    ;; Breakpoint is currently set, so restore memory contents and clear BP
    ld   a, (iBPData)   ; Restore original contents of memory at current
    ld   (hl), a        ;  breakpoint address to remove breakpoint opcode
.BPClearClrAddr:
    ld   hl, 0xffff     ; Get value indicating break address is not set
    ld   (iBPAddr), hl  ; Store as breakpoint address to incicate not set
.BPClearClrData:
    ld   a, kBPOpcode   ; Get value indicating break data is not set
    ld   (iBPData), a   ; Store as breakpoint data to incicate not set
    pop  hl
    pop  af
    ret


    ;; Breakpoint: Is address in monitor code space?
    ;;   On entry: HL = Memory address to be tested
    ;;   On exit:  If address is in monitor code Z flagged
    ;;               otherwise NZ flagged
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Only test the most significant byte of the address. This is fine
    ;; for the start of the monitor code which is assumed to be on a 256
    ;; byte boundary. But the end of the monitor code will be treated as
    ;; entending to the end of the 256 byte boundry it is in.
BPIsInMonitor:
    ld   a, h           ; Get hi byte of address to be tested
    or   a              ; Is it 0x00? (address 0x0000 to 0x00FF
    ret  z              ; Yes, so return Z
    ;; H is not 0x00
    ld   a, EndOfMonitor >> 8
    cp   h              ; Compare with hi byte of address
    ;;           RET  Z              ;Return Z if H = monitor end
    ret  c              ; Return NZ if > monitor end
    ;; H is now known to be less than or equal to monitor end address
    ld   a, StartOfMonitor
    cp   h              ; Compare with hi byte of address
    ret  z              ; Return Z if H = monitor start
    ret  nc             ; Return NZ if H < monitor start
    ;; H is now known to be greater than monitor start (also H <= end)
    xor  a              ; Return Z as address in monitor code
    ret


    ;; **********************************************************************
    ;; **  Constant data                                                   **
    ;; **********************************************************************

    .section .rodata

szBreak:
    .db  "Breakpoint", kNewLine, kNull
szTrap:
    .db  "Trap", kNewLine, kNull
szOver:
    .db  "Stepping over code in ROM or in monitor", kNewLine, kNull


    ;; **********************************************************************
    ;; **  Private workspace (in RAM)                                      **
    ;; **********************************************************************

    .bss

iBPAddr:
    .dw  0              ; Breakpoint address
iBPData:
    .db  0              ; Breakpoint data (contents of BP address)
iBPType:
    .db  0              ; Breakpoint type: 0=Once, 1=Step
iBPReq:
    .dw  0              ; Breakpoint address request


    ;; To set a breakpoint or single step break, call xxx
    ;; This address is held in iBPReq.
    ;; When a program run or continue is required...


    ;; Instructions which can change flow of code (ie. alter PC)
    ;;   DJNZ d          10 nn      0001 0000
    ;;   JR   d          18 nn      0001 1000
    ;;   JR   c,  d      xx nn      001c c000
    ;;   JP   nn         C3 nn nn   1100 0011
    ;;   JP   cc, nn     xx nn nn   11cc c010
    ;;   JP   HL         E9         1110 1001
    ;;   JP   IX         DD E9      1110 1001
    ;;   JP   IY         FD E9      1110 1001
    ;;   CALL nn         CD nn nn   1100 1101
    ;;   CALL cc, nn     xx nn nn   11cc c100
    ;;   RET             C9         1100 1001
    ;;   RET  cc         xx         11cc c000
    ;;   RETI            ED 4D      0100 1101
    ;;   RETN            ED 45      0100 0101
    ;;   RST  aa         xx         11tt t111
    ;; Also an interrupt or reset signal changes PC


    ;; **********************************************************************
    ;; **  End of Breakpoint module                                        **
    ;; **********************************************************************

    #endif // IncludeBreakpoint
