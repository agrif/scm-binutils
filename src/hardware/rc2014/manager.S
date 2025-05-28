    ;; **********************************************************************
    ;; **  Hardware Manager                          by Stephen C Cousins  **
    ;; **  Hardware: RC2014                                                **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module is responsible for:
    ;;   Any optional hardware detection
    ;;   Setting up drivers for all hardware
    ;;   Initialising hardware


    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    .section .rodata
    ;; Startup message
szStartup:
    .db  "RC2014", kNull


    ;; (agrif) use a subsection to force it to appear after above .rodata
    .section .text.Hardware_Initialise

    ;; Hardware initialise
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL not specified
    ;;             IX IY I AF' BC' DE' HL' preserved
    ;; Identify and initialise console devices:
    ;;   Console device 1 = Serial device at 0x80 (SIO port A or ACIA #1)
    ;;   Console device 2 = Serial device at 0x80 (SIO port B)
    ;;   Console device 3 = Serial device at 0x40 (ACIA #2)
    ;; Sets up hardware device flags:
    ;;   Bit 0 = Serial 6850 ACIA #1 detected
    ;;   Bit 1 = Serial Z80 SIO   #1 detected
    ;;   Bit 2 = Serial 6850 ACIA #2 detected
Hardware_Initialise:
    xor  a
    ld   (iHwFlags), a  ; Clear hardware flags
    ;; Look for SIO2 type 2 (official addressing scheme)
    call RC2014_SerialSIO2_Initialise_T2
    jr   nz, .Hardware_InitialiseNoSIO2T2 ; Skip if SIO2 not found
    ld   hl, iHwFlags   ; Get hardware flags
    set  1, (hl)        ; Set SIO2 present flag
    ld   hl, .Hardware_InitialisePtrSIO2T2 ; Pointer to vector list
    jr   .Hardware_InitialiseSerial4 ; Set up serial vectors
.Hardware_InitialiseNoSIO2T2:
    ;; Look for SIO2 type 1 (original addressing scheme)
    call RC2014_SerialSIO2_Initialise_T1
    jr   nz, .Hardware_InitialiseNoSIO2T1 ; Skip if SIO2 not found
    ld   hl, iHwFlags   ; Get hardware flags
    set  1, (hl)        ; Set SIO2 present flag
    ld   hl, .Hardware_InitialisePtrSIO2T1 ; Pointer to vector list
.Hardware_InitialiseSerial4:
    ld   b, 4           ; Number of jump vectors
    jr   .Hardware_InitialiseSerial ; Set up serial vectors
.Hardware_InitialiseNoSIO2T1:
    ;; Look for 6850 ACIA #1
    call RC2014_SerialACIA1_Initialise
    jr   nz, .Hardware_InitialiseNoACIA1 ; Skip if 6850 not found
    ld   hl, iHwFlags   ; Get hardware flags
    set  0, (hl)        ; Set 6850 present flag
    ld   hl, .Hardware_InitialisePtrACIA1 ; Pointer to vector list
    ld   b, 2           ; Number of jump vectors
    ;;jr   .Hardware_InitialiseSerial ; Set up serial vectors
    ;; Set up jump table for serial device #1 or #1+#2
.Hardware_InitialiseSerial:
    ld   a, kFnDev1In   ; First device jump entry
    call InitJumps      ; Set up serial vectors
.Hardware_InitialiseNoACIA1:
    ;; Look for 6850 ACIA #2
    call RC2014_SerialACIA2_Initialise
    jr   nz, .Hardware_InitialiseNoACIA2 ; Skip if 6850 not found
    ld   hl, iHwFlags   ; Get hardware flags
    set  2, (hl)        ; Set 6850 present flag
    ld   hl, .Hardware_InitialisePtrACIA2 ; Pointer to vector list
    ld   b, 2           ; Number of jump vectors
    ld   a, kFnDev3In   ; First device jump entry
    call InitJumps      ; Set up serial vectors
.Hardware_InitialiseNoACIA2:
    ;; Test if any console devices have been found
    ld   a, (iHwFlags)  ; Get device detected flags
    or   a              ; Any found?
    ret  nz             ; Yes, so return
    ;; Indicate failure by turning on Bit 0 LED at the default port
    xor  a              ; Output bit number zero (A=0)
    jp   PrtOSet        ; Turn on specified output bit

    .section .rodata.PtrSIO2T1
    ;; Jump table enties
    ;; Device #1 = Serial SIO/2 channel A
.Hardware_InitialisePtrSIO2T1:
    .dw  RC2014_SerialSIO2A_InputChar_T1
    .dw  RC2014_SerialSIO2A_OutputChar_T1
    ;; Device #2 = Serial SIO/2 channel B
    .dw  RC2014_SerialSIO2B_InputChar_T1
    .dw  RC2014_SerialSIO2B_OutputChar_T1
    ;; Device #1 = Serial SIO/2 channel A
.Hardware_InitialisePtrSIO2T2:
    .dw  RC2014_SerialSIO2A_InputChar_T2
    .dw  RC2014_SerialSIO2A_OutputChar_T2
    ;; Device #2 = Serial SIO/2 channel B
    .dw  RC2014_SerialSIO2B_InputChar_T2
    .dw  RC2014_SerialSIO2B_OutputChar_T2
    ;; Device #1 = Serial ACIA #1 module
.Hardware_InitialisePtrACIA1:
    .dw  RC2014_SerialACIA1_InputChar
    .dw  RC2014_SerialACIA1_OutputChar
    ;; Device #3 = Serial ACIA #2 module
.Hardware_InitialisePtrACIA2:
    .dw  RC2014_SerialACIA2_InputChar
    .dw  RC2014_SerialACIA2_OutputChar


    ;; (agrif) use a subsection to force it to appear after above .rodata
    .section .text.Hardware_BaudSet

    ;; Hardware: Set baud rate
    ;;   On entry: No parameters required
    ;;   On entry: A = Baud rate code
    ;;             C = Console device number (1 to 6)
    ;;   On exit:  IF successful: (ie. valid device and baud code)
    ;;               A != 0 and NZ flagged
    ;;             BC HL not specified
    ;;             DE? IX IY I AF' BC' DE' HL' preserved
Hardware_BaudSet:
    xor  a              ; Return failure (A=0 and Z flagged)
    ret                 ; Abort as invalid baud rate


    ;; Hardware: Poll timer
    ;;   On entry: No parameters required
    ;;   On exit:  If 1ms event to be processed NZ flagged and A != 0
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Poll software generated timer to see if a 1ms event has occurred.
    ;; We have to estimate the number of clock cycles used since the last
    ;; call to this routine. When the system is waiting for a console input
    ;; character this will be the time it takes to call here plus the time
    ;; to poll the serial input device. Lets call this the loop time.
    ;; The rest of the time we don't know so the timer events will probably
    ;; run slow.
    ;; We generate a 1000 Hz event (every 1,000 micro seconds) by
    ;; counting processor clock cycles.
    ;; With a 7.3728 Hz CPU clock, 1,000 micro seconds is 7,373 cycles
Hardware_PollTimer:
    ld   a, (iHwIdle)   ; Get loop counter
    add  a, 7           ; Add to loop counter
    ld   (iHwIdle), a   ; Store updated counter
    jr   c, .Hardware_PollTimerRollOver ; Skip if roll over (1ms event)
    xor  a              ; No event so Z flagged and A = 0
    ret
.Hardware_PollTimerRollOver:
    or   0xff           ; 1ms event so NZ flagged and A != 0
    ret


    ;; Hardware: Output signon info
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL not specified
    ;;             IX IY I AF' BC' DE' HL' preserved
Hardware_Signon:
    ld   de, .Hardware_SignonszHardware ; Pointer to start up message
    jp   OutputZString  ; Output start up message

    .section .rodata.szHardware
.Hardware_SignonszHardware:
    .db  "Z80 based RC2014 systems", kNewLine, kNull


    ;; (agrif) use a subsection to force it to appear after above .rodata
    .section .text.Hardware_Devices

    ;; Hardware: Output devices info
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL not specified
    ;;             IX IY I AF' BC' DE' HL' preserved
Hardware_Devices:
    ld   hl, iHwFlags   ; Get hardware present flags
    ld   de, .Hardware_DevicesszHw6850 ; Serial 6850 message
    bit  0, (hl)        ; Serial 6850 present?
    call nz, OutputZString ; Yes, so list it
    ld   de, .Hardware_DevicesszHwSIO2 ; Serial SIO/2 message
    bit  1, (hl)        ; Serial SIO/2 present?
    call nz, OutputZString ; Yes, so list it
    ld   de, .Hardware_DevicesszHw6850B ; Serial 6850 message
    bit  2, (hl)        ; Serial 6850 present?
    call nz, OutputZString ; Yes, so list it
    ret

    .section .rodata.szHw6850
.Hardware_DevicesszHw6850:
    .db  "1 = 6850 ACIA #1   (@80)", kNewLine, kNull
.Hardware_DevicesszHwSIO2:
    .db  "1 = Z80 SIO port A (@80)", kNewLine
    .db  "2 = Z80 SIO port B (@82)", kNewLine, kNull
.Hardware_DevicesszHw6850B:
    .db  "3 = 6850 ACIA #2   (@40)", kNewLine, kNull


    ;; (agrif) use a subsection to force it to appear after above .rodata
    .section .text.RomPageInit

    ;; Initialise ROM paging
    ;;   On entry: No parameters required
    ;;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
RomPageInit:
    ret

    ;; Fixed address to allow external code to use it
    .equ kTransCode, kPassCode ; Transient code area

    ;; Execute code in ROM bank
    ;;   On entry: A = ROM bank number (0 to 3)
    ;;             DE = Absolute address to execute
    ;;   On exit:  IX IY I AF' BC' DE' HL' preserved
    ;; WARNING: Not safe against interrupt changing config register
    ;; First copy required utility function to RAM and then run it
    ;; The ROM bank is selected and the code executed
RomExec:
    push de
    ld   hl, .RomExecTransExec ; Source: start of code to copy
    ld   de, kTransCode ; Destination: transient code area
    ld   bc, .RomExecTransExecEnd-.RomExecTransExec ; Length of copy
    ldir                ; Copy (HL) to (DE) and repeat x BC
    pop  de
    jp   kTransCode
    ;; Transient code copied to RAM before being executed
    ;;rlca              ; Shift requested ROM bank number
.RomExecTransExec:
    ;;rlca              ;   from  0b000000NN
    ;;rlca              ;   to    0b00NN0000
    ;;rlca
    ;;ld   b, a         ; Store new ROM bank bits
    ;;ld   a, (iConfigCpy) ; Get current config byte
    ;;ld   (iConfigPre), a ; Store as 'previous' config byte
    ;;and  0b11001111   ; Clear ROM bank bits
    ;;or   b            ; Include new ROM bank bits
    ;;ld   (iConfigCpy), a ; Write config byte to shadow copy
    ;;out  (kConfigReg), a ; Write config byte to register
    ld   bc, kTransCode+(.RomExecTransRet-.RomExecTransExec)
    push bc             ; Push return address onto stack
    push de             ; Jump to DE by pushing on
    ret                 ;  to stack and 'returning'
    ;;ld   a ,(iConfigPre) ; Get previous ROM page
.RomExecTransRet:
    ;;ld   (iConfigCpy), a ; Write config byte to shadow copy
    ;;out  (kConfigReg), a ; Write config byte to register
    ret
.RomExecTransExecEnd:


    ;; Copy from ROM bank to RAM
    ;;   On entry: A = ROM bank number (0 to 3)
    ;;             HL = Source start address (in ROM)
    ;;             DE = Destination start address (in RAM)
    ;;             BC = Number of bytes to copy
    ;;   On exit:  IX IY I AF' BC' DE' HL' preserved
    ;; WARNING: Not safe against interrupt changing config register
    ;; First copy required utility function to RAM and then run it
RomCopy:
    push bc
    push de
    push hl
    ld   hl, TransCopy  ; Source: start of code to copy
    ld   de, kTransCode ; Destination: transient code area
    ld   bc, TransCopyEnd-TransCopy ; Length of copy
    ldir                ; Copy (HL) to (DE) and repeat x BC
    pop  hl
    pop  de
    pop  bc
    jp   kTransCode
    ;; Transient code copied to RAM before being executed
    ;;push bc           ; Preserve number of bytes to copy
TransCopy:
    ;;rlca              ; Shift requested ROM bank number
    ;;rlca              ;   from  0b000000NN
    ;;rlca              ;   to    0b00NN0000
    ;;rlca
    ;;ld   b, a         ; Store new ROM bank bits
    ;;ld   a, (iConfigCpy) ; Get current config byte
    ;;ld   c, a         ; Store as 'previous' config byte
    ;;and  0b11001111   ; Clear ROM bank bits
    ;;or   b            ; Include new ROM bank bits
    ;;out  (kConfigReg), a ; Write new config byte to register
    ;;ld   a, c         ; Get 'previous' config byte
    ;;pop  bc           ; Restore number of bytes to copy
    ldir                ; Copy (HL) to (DE) and repeat x BC
    ;;out  (kConfigReg), a ; Restore 'previous' config byte
    ret
TransCopyEnd:


    ;; **********************************************************************
    ;; **  Public workspace (in RAM)                                       **
    ;; **********************************************************************

    .bss

    ;; Hardware flags
    ;; Bit 0 = Serial 6850 ACIA #1 detected
    ;; Bit 1 = Serial Z80 SIO   #1 detected
    ;; Bit 2 = Serial 6850 ACIA #2 detected
    ;; Bit 3 to 7 = Not defined, all cleared to zero
iHwFlags:
    .db  0              ; Hardware flags

iHwIdle:
    .db  0              ; Poll timer count

    ;; **********************************************************************
    ;; **  End of Hardware manager for RC2014                              **
    ;; **********************************************************************
