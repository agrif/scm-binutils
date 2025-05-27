    ;; **********************************************************************
    ;; **  Alpha module                              by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module provides the following:
    ;;   Defines the memory map (except kCode and kData)
    ;;   Reset code / Cold start command line interpreter
    ;;   Warm start command line interpreter
    ;;
    ;; Public functions provided:
    ;;   ColdStart             Cold start monitor
    ;;   WarmStart             Warm start monitor
    ;;   InitJumps             Initialise jump table with vector list
    ;;   ClaimJump             Claim jump table entry
    ;;   ReadJump              Read jump table entry
    ;;   MemAPI                Call API with parameters in RAM
    ;;   SelConDev             Select console in/out device
    ;;   SelConDevI            Select console input device
    ;;   SelConDevO            Select console output device
    ;;   DevInput              Input from specified console device
    ;;   DevOutput             Output to specified console device
    ;;   Delay                 Delay by sepecified number of millseconds
    ;;   GetConDev             Get current console device numbers
    ;;   GetMemTop             Get top of free memory
    ;;   SetMemTop             Set top of free memory
    ;;   GetVersion            Get version and configuration details
    ;;   OutputMessage         Output specified embedded message
    ;;   SetBaud               Set baud rate for console devices
    ;;   SysReset              System reset


    ;; **********************************************************************
    ;; **  Constants                                                       **
    ;; **********************************************************************

    ;; Memory map (ROM or RAM)
    .equ Reset, 0x0000  ; Z80 reset location

    ;; Memory map (RAM) (assuming kData = 0xFC00)
    ;; 0xFC00 to 0xFCBF  User stack
    ;; 0xFCC0 to 0xFCFF  System stack
    ;; 0xFD00 to 0xFD7F  Line input buffer
    ;; 0xFD80 to 0xFDFF  String buffer
    ;; 0xFE00 to 0xFE5F  Jump table
    ;; 0xFE60 to 0xFEFF  Workspace (currently using to about 0xFEAF)
    ;; 0xFF00 to 0xFFFF  Pass info between apps and memory banks:
    ;; 0xFF00 to 0xFF7F    Transient data area
    ;; 0xFF80 to 0xFFEF    Transient code area
    ;; 0xFFD0 to 0xFFDF    ROMFS file info block 2
    ;; 0xFFE0 to 0xFFEF    ROMFS file info block 1
    ;; 0xFFF0 to 0xFFFF    System variables

    .bss

    .skip 0xc0          ; Top of stack for user program
kSPUsr:
    .skip 0x40          ; Top of stack for system
kSPSys:
kInputBuff:
    .skip kInputSize    ; Line input buffer start    (to +0x017F)
kStrBuffer:
    .skip kStrSize      ; String buffer              (to +0x01FF)

kJumpTab:
JpNMI:
    .skip 3             ; Fn 0x00: Jump to non-maskable interrupt
JpRST08:
    .skip 3             ; Fn 0x01: Jump to restart 08 handler
JpRST10:
    .skip 3             ; Fn 0x02: Jump to restart 10 handler
JpRST18:
    .skip 3             ; Fn 0x03: Jump to restart 18 handler
JpRST20:
    .skip 3             ; Fn 0x04: Jump to restart 20 handler
JpBP:
    .skip 3             ; Fn 0x05: Jump to restart 28 breakpoint
JpAPI:
    .skip 3             ; Fn 0x06: Jump to restart 30 API handler
JpINT:
    .skip 3             ; Fn 0x07: Jump to restart 38 interrupt handler
JpConIn:
    .skip 3             ; Fn 0x08: Jump to console input character
JpConOut:
    .skip 3             ; Fn 0x09: Jump to console output character
    .skip 3             ; Fn 0x0A: Jump to console get input status
    .skip 3             ; Fn 0x0B: Jump to console get output status
JpIdle:
    .skip 3             ; Fn 0x0C: Jump to idle handler
JpTimer1:
    .skip 3             ; Fn 0x0D: Jump to timer 1 handler
JpTimer2:
    .skip 3             ; Fn 0x0E: Jump to timer 2 handler
JpTimer3:
    .skip 3             ; Fn 0x0F: Jump to timer 3 handler
    ;; Fn 0x10: Start of console device jumps
    .skip 3             ; Jump to device 1 input character
    .skip 3             ; Jump to device 1 output character
    .skip 3             ; Jump to device 2 input character
    .skip 3             ; Jump to device 2 output character
    .skip 3             ; Jump to device 3 input character
    .skip 3             ; Jump to device 3 output character
    .skip 3             ; Jump to device 4 input character
    .skip 3             ; Jump to device 4 output character
    .skip 3             ; Jump to device 5 input character
    .skip 3             ; Jump to device 5 output character
    .skip 3             ; Jump to device 6 input character
    .skip 3             ; Jump to device 6 output character

    ;; 4 unused entries
    .skip 3
    .skip 3
    .skip 3
    .skip 3

kWorkspace:
    ;; additional .bss variables placed here
    ;;.skip 0xa0        ; Space for data & variables (to +0x02FF)


    ;; Pass information between apps and memory banks 0xFF00 to 0xFFFF
    .equ kPassData, 0xff00 ; 0xFF00 to 0xFF7F Transient data area
    .equ kPassCode, 0xff80 ; 0xFF80 to 0xFFEF Transient code area
    .equ kPassInfo, 0xfff0 ; 0xFFF0 to 0xFFFF Variable passing area
    .equ kPassCtrl, kPassInfo+0x00 ; Pass control / paging information
    .equ kPassAF, kPassInfo+0x02 ; Pass AF to/from API
    .equ kPassBC, kPassInfo+0x04 ; Pass BC to/from API
    .equ kPassDE, kPassInfo+0x06 ; Pass DE to/from API
    .equ kPassHL, kPassInfo+0x08 ; Pass HL --/from API
    .equ kPassDevI, kPassInfo+0x0A ; Pass current input device
    .equ kPassDevO, kPassInfo+0x0B ; Pass current output device


    ;; Page zero use
    ;; SCMonitor: page zero can be in RAM or ROM
    ;; CP/M: page zero must be in RAM
    ;; <Address>   <Z80 function>   <Monitor>   <CP/M 2>
    ;; 0000-0002   RST 00 / Reset   Cold start  Warm boot
    ;; 0003-0004                    Warm start  IOBYTE / drive & user
    ;; 0005-0007                    As CP/M     FDOS entry point
    ;; 0008-000B   RST 08           Char out    Not used
    ;; 000C-000F                    CstartOld   Not used
    ;; 0010-0013   RST 10           Char in     Not used
    ;; 0014-0017                    WstartOld   Not used
    ;; 0018-001F   RST 18           In status   Not used
    ;; 0020-0027   RST 20           Not used    Not used
    ;; 0028-002F   RST 28           Breakpoint  Debugging
    ;; 0030-0037   RST 30           API entry   Not used
    ;; 0038-003F   RST 38 / INT     Interrupt   Interrupt mode 1 handler
    ;; 0040-005B                    Options     Not used
    ;; 005C-007F                    As CP/M     Default FCB
    ;; 0066-0068   NMI              or Non-maskable interrupt (NMI) handler
    ;; 0080-00FF                    As CP/M     Default DMA


    ;; **********************************************************************
    ;; **  Initialise memory sections                                      **
    ;; **********************************************************************

    ;; avoid a really bad error or infinite cycle
    #if  !defined(kCode) || !defined(kData)
    #error "kCode or kData not defined"
    #endif

    ;; promote kData and kCode from defines to symbols for the linker
    .equ "kCode", kCode
    .equ "kData", kData


    ;; **********************************************************************
    ;; **  Page zero default vectors etc, copied to RAM if appropriate     **
    ;; **********************************************************************

    .text

    ;; Reset / power up here
Page0Strt:
ColdStart:
    jp   ColdStrt       ; 0x0000  CP/M 2 Warm boot
WarmStart:
    jr   WStrt          ; 0x0003  CP/M 2 IOBYTE / drive & user
    jp   FDOS           ; 0x0005  CP/M 2 FDOS entry point
    jp   JpRST08        ; 0x0008  RST 08 Console character out
    .skip 1             ; 0x000B
    jp   ColdStrt       ; 0x000C  Cold start (unofficial entry)
    .skip 1             ; 0x000F
    jp   JpRST10        ; 0x0010  RST 10 Console character in
    .skip 1             ; 0x0013
WStrt:
    jp   WarmStrt       ; 0x0014  Warm start (unofficial entry)
    .skip 1             ; 0x0017
    jp   JpRST18        ; 0x0018  RST 18 Console input status
    .skip 5             ; 0x001B
    jp   JpRST20        ; 0x0020  RST 20 Not used
    .skip 5             ; 0x0023
    jp   JpBP           ; 0x0028  RST 28 Our debugging breakpoint
    .skip 5             ; 0x002B         and CP/M debugging tools
    jp   JpAPI          ; 0x0030  RST 30 API entry point
    .skip 1             ; 0x0033         parameters in registers
    jp   MemAPI         ; 0x0034  API call with
    .skip 1             ; 0x0037         parameters in memory
    jp   JpINT          ; 0x0038  RST 38 Interrupt mode 1 handler
    .skip 5             ; 0x003B
kaConDev:
    .db  kConDef        ; 0x0040  Default console device (1 to 6)
kaBaud1Def:
    .db  kBaud1Def      ; 0x0041  Default device 1 baud rate
kaBaud2Def:
    .db  kBaud2Def      ; 0x0042  Default device 2 baud rate
    .skip 1             ; 0x0043  Not used
    .skip 4             ; 0x0044  Not used
    .skip 8             ; 0x0048  Not used
    .skip 8             ; 0x0050  Not used
    .skip 4             ; 0x0058  Not used
    .skip 4             ; 0x005C  CP/M 2 Default FCB
    .skip 6             ; 0x0060         from 0x005C to 0x007F
    jp   JpNMI          ; 0x0066  Non-maskable interrupt handler
Page0End:


    ;; **********************************************************************
    ;; **  Jump table defaults to be copied to RAM                         **
    ;; **********************************************************************

JumpStrt:
    jp   TrapNMI        ; Fn 0x00: non-maskable interrupt
    jp   OutputChar     ; Fn 0x01: restart 08 output character
    jp   InputChar      ; Fn 0x02: restart 10 input character
    jp   InputStatus    ; Fn 0x03: restart 18 get input status
    jp   TrapCALL       ; Fn 0x04: restart 20 handler
    jp   BPHandler      ; Fn 0x05: restart 28 breakpoint handler
    jp   APIHandler     ; Fn 0x06: restart 30 API handler
    jp   TrapINT        ; Fn 0x07: restart 38 interrupt handler
    jp   TrapCALL       ; Fn 0x08: console input character
    jp   TrapCALL       ; Fn 0x09: console output character
    jp   TrapCALL       ; Fn 0x0A: console get input status
    jp   TrapCALL       ; Fn 0x0B: console get output status
    jp   TrapCALL       ; Fn 0x0C: Jump to idle handler
    jp   TrapCALL       ; Fn 0x0D: Jump to timer 1 handler
    jp   TrapCALL       ; Fn 0x0E: Jump to timer 2 handler
    jp   TrapCALL       ; Fn 0x0F: Jump to timer 3 handler
    jp   DevNoIn        ; Fn 0x10: Device 1 input character
    jp   DevNoOut       ; Fn 0x11: Device 1 output character
    jp   DevNoIn        ; Fn 0x10: Device 2 input character
    jp   DevNoOut       ; Fn 0x11: Device 2 output character
    jp   DevNoIn        ; Fn 0x10: Device 3 input character
    jp   DevNoOut       ; Fn 0x11: Device 3 output character
    jp   DevNoIn        ; Fn 0x10: Device 4 input character
    jp   DevNoOut       ; Fn 0x11: Device 4 output character
    jp   DevNoIn        ; Fn 0x10: Device 5 input character
    jp   DevNoOut       ; Fn 0x11: Device 5 output character
    jp   DevNoIn        ; Fn 0x10: Device 6 input character
    jp   DevNoOut       ; Fn 0x11: Device 6 output character
JumpEnd:


    ;; **********************************************************************
    ;; **  Reset code                                                      **
    ;; **********************************************************************

    ;; Cold start Command Line Interpreter
ColdStrt:
    di                  ; Disable interrupts
    ld   SP, kSPSys     ; Initialise system stack pointer
    ;; Self test included?
    #ifdef IncludeSelftest
    ;; This indicates status on the default output port (LEDs)
    ;; At the end of a sucessful self test the default output port is cleared
    ;; to zero, otherwise the default output port indicates the failure
    #if  BUILD_S2
    #include "hardware/sc114/selftest.s"
    #define CUSTOM_SELFTEST
    #endif
    #ifndef CUSTOM_SELFTEST
    ;; Include self test functions
    #include "selftest.s"
    #endif
    #endif
    ;; Copy vectors etc to page zero in case code is elsewhere
    ld   de, 0x0000     ; Copy vectors etc to here
    ld   hl, Page0Strt  ; Copy vectors etc from here
    ld   bc, Page0End-Page0Strt ; Number of bytes to copy
    ldir                ; Copy bytes
    ;; Initialise jump table, other than console devices
    ld   de, kJumpTab   ; Copy jump table to here
    ld   hl, JumpStrt   ; Copy jump table from here
    ld   bc, JumpEnd-JumpStrt ; Number of bytes to copy
    ldir                ; Copy bytes
    ;; Initialise top of memory value
    ld   hl, kData-1    ; Top of free memory
    ld   (iMemTop), hl  ; Set top of free memory
    ;; Initialise ports module for default I/O ports
    ;; This will turn off all outputs at the default output port (LEDs)
    ld   a, kPrtOut     ; Default output port address
    call PrtOInit       ; Initialise output port
    ld   a, kPrtIn      ; Default input port address
    call PrtIInit       ; Initialise input port
    ;; Initialise hardware and set up required jump table entries
    ;; This may indicate an error at the default output port (LEDs)
    call Hardware_Initialise
    ;; Initialise default console device to first physical device
    ld   a, (kaConDev)  ; Default device number
    call SelConDev      ; Select console device
    ;; Initialise rest of system
    call ConInitialise  ; Initialise the console
    #ifdef IncludeScripting
    call ScrInitialise  ; Initialise script language
    #endif
    #ifdef IncludeRomFS
    call RomInitialise  ; Initialise ROM filing system
    #endif
    ;; Output sign-on message
    call OutputNewLine  ; Output new line
    call OutputNewLine  ; Output new line
    ld   a, kMsgProdID  ; ="Small Computer Monitor"
    call OutputMessage  ; Output message
    ld   a, '-'         ; ="-"
    call OutputChar     ; Output character
    ld   a, kSpace      ; =" "
    call OutputChar     ; Output character
    ld   de, szStartup  ; ="<hardware>"
    call OutputZString  ; Output message at DE
    call OutputNewLine  ; Output new line
    #ifndef IncludeCommands
    call OutputNewLine  ; Output new line
    ld   a, kMsgAbout   ; ="Small Computer Monitor ..."
    call OutputMessage  ; Output message A
    call OutputNewLine  ; Output new line
    ld   a, kMsgDevice  ; ="Devices:"
    call OutputMessage  ; Output message A
    ld   a, kMsgDevLst  ; ="<device list>"
    call OutputMessage  ; Output message A
    #endif

    ;; Warm start Command Line Interpreter
WarmStrt:
    ld   SP, kSPSys     ; Initialise system stack pointer
    #ifdef IncludeBreakpoint
    call BPInitialise   ; Initialise breakpoint module
    #endif
    #ifdef IncludeCommands
    jp   CLILoop        ; Command Line Interpreter main loop
    #else
.WarmStrtHalt:
    jr   .WarmStrtHalt  ; Halt here if no CLI
    #endif

    ;; Trap unused entry points
    #ifndef IncludeAPI
API:
    #endif
    #ifndef IncludeFDOS
FDOS:
    #endif
    #ifndef IncludeBreakpoint
BPHandler:
    #endif
TrapCALL:
    ret                 ; Return from entry point

    ;; Trap unused mode 1 interrupt
TrapINT:
    reti                ; Return from interrupt

    ;; Trap unused non-maskabler interrupt
TrapNMI:
    retn                ; Return from interrupt

    ;; Default console device routines
DevNoIn:
DevNoOut:
    xor  a              ; Z flagged as no input or output
    ret                 ; Return have done nothing


    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************


    ;; System: Initialise jump table entries
    ;;   On entry: A = First jump table entry to initialise
    ;;             B = Number of entries to be initialised
    ;;             HL = Pointer to list of vectors
    ;;   On exit:  C IX IY I AF' BC' DE' HL' preserved
InitJumps:
    ld   e, (hl)        ; Get lo byte of vector
    inc  hl             ; Point to hi byte of vector
    ld   d, (hl)        ; Get lo byte of vector
    inc  hl             ; Point to next vector
    call ClaimJump      ; Claim jump table entry
    inc  a              ; Increment entry number
    djnz InitJumps      ; Repeat until done
    ret


    ;; System: Claim system jump table entry
    ;;   On entry: A = Entry number (0 to n)
    ;;             DE = Address of function
    ;;   On exit:  No parameters returned
    ;;             AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Some system functions, such as console in and console out, are
    ;; redirected through a jump table. By claiming a jump table entry the
    ;; function can be handled by any required code. This might allow
    ;; swapping output to a different device, such as a printer.
ClaimJump:
    push af
    push bc
    push hl
    ld   hl, kJumpTab   ; Start of jump table
    ld   b, 0           ; Calculate offset and store in BC..
    ld   c, a           ; C = 3 times A..
    add  a, a           ; x2
    add  a, c           ; x3
    ld   c, a
    add  hl, bc         ; Find location in table...
    ;; Write jump table entry to memory
    ld   (hl), 0xc3     ; Store jump instruction
    inc  hl
    ld   (hl), e        ; Store routine address lo byte
    inc  hl
    ld   (hl), d        ; Store routine address hi byte
    pop  hl
    pop  bc
    pop  af
    ret


    ;; System: API call with parameters passed via memory
    ;;   On entry: Memory locations kPassXX contain register values
    ;;   On exit:  Memory locations kPassXX contain register values
MemAPI:
    ld   hl, (kPassAF)  ; Get AF parameter from RAM
    push hl             ; Pass AF parameter via stack
    pop  af             ; Get AF parameter from stack
    ld   bc, (kPassBC)  ; Get BC parameter from RAM
    ld   de, (kPassDE)  ; Get DE parameter from RAM
    ld   hl, (kPassHL)  ; Get HL parameter from RAM
    rst  0x30           ; Call API
    push af             ; Pass AF result via stack
    pop  hl             ; Get AF result from stack
    ld   (kPassAF), hl  ; Store AF result in RAM
    ld   (kPassHL), hl  ; Store HL result in RAM
    ld   (kPassDE), de  ; Store DE result in RAM
    ld   (kPassBC), bc  ; Store BC result in RAM
    ret


    ;; System: Read system jump table entry
    ;;   On entry: A = Entry number (0 to n)
    ;;   On exit:  DE = Address of function
    ;;             AF BC HL IX IY I AF' BC' DE' HL' preserved
    ;; Some system functions, such as console in and console out, are
    ;; redirected through a jump table. By claiming a jump table entry the
    ;; function can be handled by any required code. This might allow
    ;; swapping output to a different device, such as a printer.
ReadJump:
    push af
    push bc
    push hl
    ld   hl, kJumpTab+1 ; Start of jump table + 1
    ld   b, 0           ; Calculate offset and store in BC..
    ld   c, a           ; C = 3 times A..
    add  a, a           ; x2
    add  a, c           ; x3
    ld   c, a
    add  hl, bc         ; Find location in table...
    ;; Write jump table entry to memory
    ld   e, (hl)        ; Store routine address lo byte
    inc  hl
    ld   d, (hl)        ; Store routine address hi byte
    pop  hl
    pop  bc
    pop  af
    ret


    ;; System: Select console device
    ;;   On entry: A = New console device number (1 to n)
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; The console device list starts at jump table entry kFnDevN.
    ;; Each device has two entries: input and output
    ;; SelConDev  = Select both input and output device
    ;; SelConDevO = Select output device only
    ;; SelConDevI = Select input device only
SelConDev:
    call SelConDevI     ; Select console input device
    ;;jp   SelConDevO   ; Select console output device
    ;; Select output device
SelConDevO:
    push af
    push de
    ld   (kPassDevO), a ; Store output device number
    add  a, a           ; Double as two entries each
    add  a, kFnDev1Out-2 ; Function number for device zero
    call ReadJump       ; Read source entry
    ld   a, kFnConOut   ; Destination device entry number
    call ClaimJump      ; Write destination entry
    pop  de
    pop  af
    ret
    ;; Select input device
SelConDevI:
    push af
    push de
    ld   (kPassDevI), a ; Store input device number
    add  a, a           ; Double as two entries each
    add  a, kFnDev1In-2 ; Function number for device zero
    call ReadJump       ; Read source entry
    ld   a, kFnConIn    ; Destination device entry number
    call ClaimJump      ; Write destination entry
    pop  de
    pop  af
    ret


    ;; System: Input from specified console device
    ;;   On entry: E = Console device number (1 to n)
    ;;   On exit:  A = Character input 9if there is one ready)
    ;;             NZ flagged if character has been input
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
DevInput:
    ld   a, e           ; Get console device number
    add  a, a           ; Double as two entries each
    add  a, kFnDev1In-2 ; Function number for device zero
    call ReadJump       ; Read table entry
    ex   de, hl         ; Get routine address in HL
    jp   (hl)           ; Jump to input routine


    ;; System: Output to specified console device
    ;;   On entry: A = Character to be output
    ;;             E = Console device number (1 to n)
    ;;   On exit:  IX IY I AF' BC' DE' HL' preserved
DevOutput:
    push af             ; Store character to be output
    ld   a, e           ; Get console device number
    add  a, a           ; Double as two entries each
    add  a, kFnDev1Out-2 ; Function number for device zero
    call ReadJump       ; Read table entry
    ex   de, hl         ; Get routine address in HL
    pop  af             ; Restore character to be output
    jp   (hl)           ; Jump to output routine


    ;; System: Delay by specified number of millseconds
    ;;   On entry: DE = Delay time in milliseconds
    ;;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Clock =  1.0000 MHz,  1 ms =  1,000 TCy =  40 * 24 - 36
    ;; Clock =  4.0000 MHz,  1 ms =  4,000 TCy = 165 * 24 - 36
    ;; Clock =  7.3728 MHz,  1 ms =  7,373 TCy = 306 * 24 - 36
    ;; Clock = 12.0000 MHz,  1 ms = 12,000 TCy = 498 * 24 - 36
    ;; Clock = 20.0000 MHz,  1 ms = 20,000 TCy = 831 * 24 - 36
Delay:
    push bc
    push de
    ;; 1 ms loop, DE times... (overhead = 36 TCy)
.DelayLoopDE:
    ld   bc, kDelayCnt  ; [10]  Loop counter
    ;; 26 TCy loop, BC times...
.DelayLoopBC:
    dec  bc             ; [6]
    ld   a, c           ; [4]
    or   b              ; [4]
    jp   nz, .DelayLoopBC ; [10]
    dec  de             ; [6]
    ld   a, e           ; [4]
    or   d              ; [4]
    jr   nz, .DelayLoopDE ; [12/7]
    pop  de
    pop  bc
    ret


    ;; System: Get current console device numbers
    ;;   On entry: No parameters required
    ;;   On exit:  D = Current console output device number
    ;;             E = Current console input device number
    ;;   On exit:  AF BC HL IX IY I AF' BC' DE' HL' preserved
GetConDev:
    ld   de, (kPassDevI) ; Get console device numbers
    ret


    ;; System: Get top of free memory
    ;;   On entry: No parameters required
    ;;   On exit:  DE = Top of free memory
    ;;   On exit:  AF BC HL IX IY I AF' BC' DE' HL' preserved
GetMemTop:
    ld   de, (iMemTop)  ; Get top of free memory
    ret


    ;; System: Set top of free memory
    ;;   On entry: DE = Top of free memory
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
SetMemTop:
    ld   (iMemTop), de  ; Set top of free memory
    ret


    ;; System: Get version details
    ;;   On entry: No parameters required
    ;;   On exit:  D,E and A = Monitor code version
    ;;               D = kVersMajor
    ;;               E = kVersMinor
    ;;               A = kVersRevis(ion)
    ;;             B,C = Configuration ID
    ;;               B = kConfMajor ('R'=RC2014, 'L'=LiNC80, etc)
    ;;               C = kConfMinor (sub-type '1', '2', etc)
    ;;             H,L = Target hardware ID
    ;;               H = kHardID (1=Simulator, 2=,SCDevKt, 3=RC2014, etc)
    ;;               L = Hardware option flags (hardware specific)
    ;;             IX IY I AF' BC' DE' HL' preserved
GetVersion:
    ld   h, kHardID     ; H = Hardware ID
    ld   a, (iHwFlags)  ; Get hardware option flags
    ld   l, a           ; L = Hardware option flags
    ld   b, kConfMajor  ; B = Major configuration
    ld   c, kConfMinor  ; C = Minor configuration
    ld   d, kVersMajor  ; D = Major version number
    ld   e, kVersMinor  ; E = Minor version number
    ld   a, kVersRevis  ; A = Revision number
    ret


    ;; System: Output message
    ;;  On entry:  A = Message number (0 to n)
    ;;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
OutputMessage:
    or   a              ; Null message?
    ret  z              ; Yes, so abort
    push de             ; Preserve DE
    push hl             ; Preserve HL
    ;; Monitor message?
    #ifdef IncludeMonitor
    call MonOutputMsg   ; Offer message number to monitor
    or   a              ; Message still needs handling?
    jr   z, .OutputMessageExit ; No, so exit
    #endif
    ;; Add any other message generating modules here
    ;; ...........
    ;; System message?
    cp   kMsgLstSys+1   ; Valid system message number?
    jr   nc, .OutputMessageExit ; No, so abort
    ;; About message?
    cp   kMsgAbout      ; About message?
    jr   nz, .OutputMessageNotAbout ; No, so skip
    ld   de, szProduct  ; ="Small Computer Monitor"
    call OutputZString  ; Output message at DE
    ld   de, szAbout    ; ="<about this configuration>"
    call OutputZString  ; Output message at DE
    call Hardware_Signon ; Hardware signon message
    jr   .OutputMessageExit
.OutputMessageNotAbout:
    ;; Device list message?
    cp   kMsgDevLst     ; Device list message?
    jr   nz, .OutputMessageNotDevLst ; No, so skip
    ;;ld   de, szDevices ; ="Devices:"
    ;;call OutputZString ; Output message at DE
    call Hardware_Devices ; Output device list
    jr   .OutputMessageExit
.OutputMessageNotDevLst:
    ;; Other system message?
    ld   e, a           ; Get message number
    ld   d, 0
    ld   hl, MsgTabSys  ; Get start of message table
    add  hl, de         ; Calculate location in table
    add  hl, de
    ld   a, (hl)        ; Get address from table...
    inc  hl
    ld   d, (hl)
    ld   e, a
    call OutputZString  ; Output message as DE
.OutputMessageExit:
    pop  hl             ; Restore HL
    pop  de             ; Restore DE
    ret


    ;; System: Set baud rate
    ;;  On entry:  A = Device identifier (0x01 to 0x06, or 0x0A to 0x0B)
    ;;             E = Baud rate code
    ;;   On exit:  IF successful: (ie. valid device and baud code)
    ;;               A != 0 and NZ flagged
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
SetBaud:
    cp   0x0a           ; Identifier is a hex letter?
    jr   c, .SetBaudGotNum ; No, so skip
    sub  0x09           ; Convert 0x0A/B to 0x01/2
.SetBaudGotNum:
    ld   c, a           ; Get device identifier (0x01 to 0x06)
    ld   a, e           ; Get baud rate code
    ;; Set baud rate for device C (1 to 6) to baud code A
    jp   Hardware_BaudSet ; Failure: A=0 and Z flagged


    ;; System: System reset
    ;;  On entry:  A = Reset type:
    ;;               0 = Cold start monitor
    ;;               1 = Warm start monitor
    ;;   On exit:  System resets
SysReset:
    cp   0x01           ; Warm start monitor
    jp   z, WarmStart   ; Yes, so warm start monitor
    rst  0              ; Cold start monitor


    ;; **********************************************************************
    ;; **  Constant data                                                   **
    ;; **********************************************************************

    .section .rodata

    ;; Message strings (zero terminated)
szNull:
    .db  kNull
szProduct:
    .db  "Small Computer Monitor ", kNull
szDevices:
    .db  "Devices detected:", kNewLine, kNull
szAbout:
    .db  "by Stephen C Cousins (www.scc.me.uk)", kNewLine
    .db  "Version "
    .db  '0'+kVersMajor, '.'
    .db  '0'+kVersMinor, '.'
    .db  '0'+kVersRevis
    .db  " configuration ", kConfMajor, kConfMinor
    #ifdef SHOW_CONFIG_REVISION
    .db  '.', kConfRevis
    #endif
    .db  " for ", kNull
    .db  kNull

    ;; Message table
MsgTabSys:
    .dw  szNull
    .dw  szProduct
    .dw  szDevices
    ;;.dw  szAbout      ; Handled in code
    ;;.dw  szDevList    ; Handled in code


    ;; **********************************************************************
    ;; **  Private workspace (in RAM)                                      **
    ;; **********************************************************************

    .bss

iMemTop:
    .dw  0              ; Top of free memory address

    ;; **********************************************************************
    ;; **  End of Alpha module                                             **
    ;; **********************************************************************

    ;; (agrif) FIXME no good very bad shims for undefined symbols
    ;; from alpha.S
    .equ FDOS, 0x0564
    .equ BPHandler, 0x0e12
    .equ Hardware_Initialise, 0x1d30
    .equ RomInitialise, 0x1ae3
    .equ szStartup, 0x1d29
    .equ BPInitialise, 0x0dff
    .equ CLILoop, 0x0f72
    .equ iHwFlags, 0xfeaf
    .equ MonOutputMsg, 0x0869
    .equ Hardware_Signon, 0x1dae
    .equ Hardware_Devices, 0x1dce
    .equ Hardware_BaudSet, 0x1d9d

    ;; from console.S
    .equ ConvertCharToUCase, 0x06de
    .equ StrCopyToZ, 0x05c8

    ;; from idle.S
    .equ Hardware_PollTimer, 0x1d9f

    ;; from api.S
    .equ CLIExecute, 0x0fa2
    .equ RomGetPtr, 0x1b81
    .equ CLISkipDelim, 0x0ff4
    .equ CLISkipNonDeli, 0x0feb
    .equ CLIGetHexParam, 0x0ffd
