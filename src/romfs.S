    ;; **********************************************************************
    ;; **  ROM Filing System module                  by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module provides a simple read only filing system designed to
    ;; allow code and data to be stored in ROM, including banked ROM.

    ;; For a system with multiple ROM banks, each 16k bytes long and
    ;; starting at address 0x0000, the first reference is 0x3FF0, the second
    ;; at 0x3FE0, and so on.
    ;;
    ;; WARNING: Supports a maximum of 15 files in each ROM bank
    ;;
    ;; Each file reference contains the following bytes:
    ;; Offset    Description
    ;; +0x00     Reference identifier byte 0x55
    ;; +0x01     Reference identifier byte 0xAA
    ;; +0x02     File name, 8 characters, padded with trailing spaces
    ;; +0x0A     File type and flags (see below)
    ;; +0x0B     File destination (see below)
    ;; +0x0C     File start address, 16-bit, low byte first
    ;; +0x0E     File length, 16-bit, low byte first
    ;;
    ;; The file name contains eight ASCII characters. File names shorter than
    ;; eight characters long have the unused trailing bytes filled with ASCII
    ;; spaces (0x20). The file name can contain characters A to Z, a to z, 0
    ;; to 9, underscore, but no spaces other than the trailing bytes.
    ;; File names must be at least two characters long so they do not
    ;; conflict with single letter monitor commands.
    ;;
    ;; File types and flags:
    ;;  +-------+-------+-------+-------+-------------------------------+
    ;;  | Auto  | Move  | 0     | 0     | File type (0 to 15)           |
    ;;  +-------+-------+-------+-------+-------+-------+-------+-------+
    ;;  | Bit 7 | Bit 6 | Bit 5 | Bit 4 | Bit 3 | Bit 2 | Bit 1 | Bit 0 |
    ;;  +-------+-------+-------+-------+-------+-------+-------+-------+
    ;;  File flags:                       File types:
    ;;  Bit 7 = Auto run                  0 = .DAT  Unspecified
    ;;  Bit 6 = Move* to RAM and run      1 = .COM  Monitor command
    ;;  Bit 5 = Reserved (zero)           2 = .EXE  Executable
    ;;  Bit 4 = Reserved (zero)           3 = .HLP  Help
    ;;  * = see 'destination'             4 = .TXT  Text
    ;;
    ;; Type 0 files: (Unspecified)
    ;; The contents of these files is ignored by the Monitor.
    ;;
    ;; Type 1 files: (Monitor commands)
    ;; These are commands that can be issued from the Monitor and require
    ;; the Monitor in order to function.
    ;; These files can not be executed from other ROM banks.
    ;;
    ;; Type 2 files: (Executable)
    ;; These are commands that can be issued by the Monitor but do no
    ;; require the Monitor to function.
    ;; These files can not be executed from other ROM banks.
    ;; Type 2 files can also be bootable ROMs which make no use of the
    ;; Monitor.
    ;;
    ;; Type 3 files: (Help)
    ;; These are simple text files, which are output at the end of the
    ;; Monitor own help text.
    ;; Typically these are used to describe executable code (type 1 or 2)
    ;; which can be run from the Monitor's command line.
    ;; Help text should be kept short, being made up of one or more lines
    ;; each terminated with CR (0x0D) and LF (0x0A). The end of the help
    ;; text is terminated with a Null (0x00).
    ;;
    ;; Type 4 files: (Text)
    ;; Not currently used by the Monitor
    ;;
    ;; The destination byte, if required, is the hi byte of the address
    ;; to which the file is copied. If the 'move' flag is not set then this
    ;; byte should be 0x00.
    ;;
    ;; The start word is the address is the absolute address in the CPU's
    ;; memory map when the host ROM bank is paged in.
    ;; To allow easy testing the Monitor removes 'bank select' bits from
    ;; the address. For example, an address from start of 32K ROM of 0x7000
    ;; is treated as 0x3000, as this is the address it will be once paged
    ;; into the CPU's memory map.
    ;;
    ;; The file length is only currently used for files that need to be
    ;; copied to RAM. However, all files should include this to support
    ;; future uses which may rely on knowing the length of any file.
    ;;
    ;; Example file reference:
    ;;           .dw  0xAA55         ; Identifier
    ;;           .db  "TEST    "     ; File name ("TEST.COM")
    ;;           .db  0x41           ; File type 2 = Command, moved to RAM
    ;;           .db  0xF0           ; Move code to 0xF000 to run it
    ;;           .dw  CmdTest        ; Start address
    ;;           .dw  CmdTestEnd-CmdTest ; Length

    #ifdef IncludeRomFS

    ;; **********************************************************************
    ;; **  Constants                                                       **
    ;; **********************************************************************

    ;; Fixed address to allow external code to use this data
    ;; (agrif) this is inside kPassCode, defined in alpha.S
    .equ kTrFileRe2, 0xffd0 ; Transient file reference
    .equ kTrFileRef, 0xffe0 ; Transient file reference


    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    ;; Initialise the ROM filing system
    ;;   On entry: No parameters required
    ;;   On exit:  IX IY I AF' BC' DE' HL' preserved
RomInitialise:
    call RomPageInit    ; Initialise ROM paging
    xor  a
    ld   (iRomMap), a   ; Clear echoed bank flags
    call RomEcho        ; Mask out ROM banks which are echos
    ;; Auto run any suitably flagged files
    call RomSearchInit
.RomInitialiseLoop:
    call RomSearchNext
    ret  nz
    ld   a, (kTrFileRef+0x0A)
    bit  7, a           ; Autorun?
    call nz, RomRun     ; Execute this file
    jr   .RomInitialiseLoop


    ;; Determine which ROM banks are real and which are echos
    ;;   On entry: No parameters required
    ;;   On exit:  IX IY I AF' BC' DE' HL' preserved
    ;; This table shows the possible ROM banks and any echoed copies
    ;;  +--------------------+-----------+-----------+-----------+-----------+
    ;;  | Configuration reg  | 64k EPROM | 32k EPROM | 32k EEPRM | 16k EPROM |
    ;;  | ROM Bank selection | A15=ROS1  | A15=n/a   | A15=n/a   | A15=n/a   |
    ;;  |          ROS1 ROS0 | A14=ROS0  | A14=ROS0  | A14=ROS1  | A14=n/a   |
    ;;  +--------------------+-----------+-----------+-----------+-----------+
    ;;  | Bank 0     0    0  |  Bank 0   |  Bank 0   |  Bank 0   |  Bank 0   |
    ;;  | Bank 1     0    1  |  Bank 1   |  Bank 1   |  Echo 0 - |  Echo 0 - |
    ;;  | Bank 2     1    0  |  Bank 2   |  Echo 0 - |  Bank 1   |  Echo 0 - |
    ;;  | Bank 3     1    1  |  Bank 3   |  Echo 1 - |  Echo 1 - |  Echo 0 - |
    ;;  +--------------------+-----------+-----------+-----------+-----------+
    ;; To eliminate bank echos:
    ;; If bank 0 = bank 1 then bank 1 is echo and bank 3 is echo
    ;; If bank 0 = bank 2 then bank 2 is echo and bank 3 is echo
RomEcho:
    ld   a, 0           ; Bank zero
    ld   l, 0xf0        ; First reference in bank
    call RomGetRef      ; Read reference to RAM
    ld   hl, kTrFileRef ; Copy file reference to
    ld   de, kTrFileRe2 ;  second reference buffer
    ld   bc, 16         ; Length of file reference
    ldir                ; Copy (HL) to (DE) and repeat x BC
    ld   a, 1           ; Bank one
    ld   l, 0xf0        ; First reference in bank
    call RomGetRef      ; Read reference to RAM
    call .RomEchoRomComp ; Compare banks
    jr   nz, .RomEchoTest2 ; Not the same so skip
    ld   a, 0b00001010  ; Banks 1 and 3 are echos
    ld   (iRomMap), a   ; Store echoed bank flags
.RomEchoTest2:
    ld   a, 2           ; Bank two
    ld   l, 0xf0        ; First reference in bank
    call RomGetRef      ; Read reference to RAM
    call .RomEchoRomComp ; Compare banks
    ret  nz             ; Not the same so finished
    ld   a, (iRomMap)   ; Get echoed flag bits so far
    or   0b00001100     ; Banks 2 and 3 are echos
    ld   (iRomMap), a   ; Store echoed bank flags
    ret
    ;; Compare file reference from two banks to check for ROM echo
.RomEchoRomComp:
    ld   b, 16          ; Compare 16 bytes
    ld   hl, kTrFileRef ; First file reference
    ld   de, kTrFileRe2 ; Second file reference
.RomEchoLoop:
    ld   a, (de)        ; Compare byte from each...
    cp   (hl)
    ret  nz             ; Not the same so return NZ flagged
    inc  hl
    inc  de
    djnz .RomEchoLoop   ; Repeat for all 16 bytes
    ret                 ; Same so return Z flagged


    ;; Initialise file reference search
    ;;   On entry: No parameters required
    ;;   On exit:  iRomBank and iRomRefLo are the 'previous' reference
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; First call RomSearchInit to initialise a file reference search
    ;; Then repeatedly call RomSearchNext to read file references
RomSearchInit:
    xor  a
    ld   (iRomBank), a  ; Start with bank zero
    ld   (iRomRefLo), a ; Start with first reference
    ret


    ;; Get next file reference from ROM
    ;;   On entry: iRomBank and iRomRefLo are the previous reference
    ;;   On exit:  iRomBank and iRomRefLo are the current reference
    ;;             If a valid reference found Z is flagged
    ;;             DE IX IY I AF' BC' DE' HL' preserved
    ;; First call RomSearchInit to initialise a file reference search
    ;; Then repeatedly call RomSearchNext to read file references
RomSearchNext:
    ld   hl, iRomRefLo  ; Point to lo byte of ref address
    ld   a, (hl)        ; Get current reference address lo
    sub  16             ; Move down to next reference
    ld   (hl), a        ; Update current reference address lo
    ;; Get current file reference
    ld   l, a           ; Store current reference lo byte
    ld   a, (iRomBank)  ; Get current ROM bank
    push de
    call RomGetRef      ; Get the file reference
    pop  de
    ld   hl, (kTrFileRef) ; Get reference identifier
    ld   a, l           ; For valid ref L = 0x55
    xor  h              ; For valid ref H = 0xAA
    inc  a              ; Valid file?
    ret  z              ; Yes, so return with Z flagged
    ;; Select next ROM bank
.RomSearchNextNextBank:
    ld   a, (iRomBank)  ; Get current ROM bank
    inc  a              ; Point to next ROM bank
    ld   b, a           ; Remember ROM bank for later
    ld   (iRomBank), a  ; Store new ROM bank
    and  kROMBanks      ; Finished all ROM banks?
    ret  nz             ; Yes, so end with NZ flagged
    ld   c, 0x01        ; Prepare bit mask for this bank
.RomSearchNextRotate:
    rlc  c              ; Rotate bit mask 'B' times
    djnz .RomSearchNextRotate ;  Bit 1 set for bank 1 etc
    ld   a, (iRomMap)   ; Bit maps of ROM bank echos
    and  c              ; Test if current bank is an echo
    jr   nz, .RomSearchNextNextBank ; Skip this bank if it is an echo
    xor  a              ; First reference in ROM
    ld   (iRomRefLo), a ; Store new reference address
    jr   RomSearchNext  ; Go consider next file reference


    ;; Get pointer to current position in command line string
    ;;   On entry: No parameters required
    ;;   On exit:  DE = Address of string typically in command line
    ;;             AF BC HL IX IY I AF' BC' DE' HL' preserved
    ;; This function is called by the API
    ;; Used by monitor command files to read command parameters
RomGetPtr:
    ld   de, (iRomTemp) ; Get pointer to command line
    ret


    ;; Execute file in ROM matching named pointed to be DE
    ;;   On entry: DE = Address of string typically in command line
    ;;   On exit:  If command executed A = 0x00 and Z flagged
    ;;             IX IY I AF' BC' DE' HL' preserved
RomExFile:
    ld   (iRomTemp), de ; Store start of command string
    call RomSearchInit
.RomExFileNextFile:
    call RomSearchNext  ; Find next file reference
    ret  nz             ; End of ROM files so exit
    ld   a, (kTrFileRef+0x0A) ; Get type
    and  0x0f           ; Remove flag bits
    cp   1              ; Monitor command?
    jr   z, .RomExFileGotFile ; Yes, so go check name
    cp   2              ; Executable code?
    jr   nz, .RomExFileNextFile ; No, so go look for next file
    ;; Found executable file so see if the file name is a match
.RomExFileGotFile:
    ld   de, (iRomTemp) ; Get start of command string
    ld   hl, kTrFileRef+2 ; Get pointer to file name
    ld   b, 8           ; Maximum length
.RomExFileCompare:
    ld   a, (hl)        ; Character from ROM
    cp   kSpace         ; Space?
    jr   z, .RomExFileCheck ; Yes, so possible match
    call ConvertCharToUCase
    ld   c, a           ; Store char from ROM in UCase
    ld   a, (de)        ; Get char from command name
    cp   kSpace+1       ; <= Space?
    jr   c, .RomExFileNextFile ; Yes, so too short
    call ConvertCharToUCase
    cp   c              ; Matching character?
    jr   nz, .RomExFileNextFile ; No, so no match
    inc  hl             ; Point ot next char in ROM
    inc  de             ; Point ot next char in command
    djnz .RomExFileCompare ; Loop until max characters
    jr   RomRun         ; Match, so run the file
    ;; Check we are also at end of command name
.RomExFileCheck:
    ld   a, (de)        ; Get char from command name
    cp   kSpace+1       ; <= Space?
    jr   nc, .RomExFileNextFile ; Yes, so too long
    ld   (iRomTemp), de ; Update sommand line pointer
    ;;jr   RomRun       ; Match, so run the file

    ;; Found file so execute it
    ;; WARNING: Call here RomInitialise for autorun function
RomRun:
    ld   a, (kTrFileRef+0x0A) ; Get file type
    bit  6, a           ; Move code first
    jr   nz, .RomRunMove ; No, so go move code
    ;; Execute direct from ROM
    ld   a, (iRomBank)  ; Get code's ROM bank
    ld   de, (kTrFileRef+0x0C) ; Get start address
    call RomExec        ; Run the executable
.RomRunReturn:
    xor  a              ; Executed file, so return
    ret                 ;  A=0 and Z flagged
    ;; Move code to RAM before running it
.RomRunMove:
    ld   hl, (kTrFileRef+0x0C) ; Get start address
    ld   bc, (kTrFileRef+0x0E) ; Get length address
    ld   a, (kTrFileRef+0x0B) ; Get destination MSB
    ld   d, a           ; Set destination MSB
    ld   e, 0           ; Set destination LSB to zero
    ld   a, (iRomBank)  ; get code's ROM bank
    call RomCopy        ; Move code to RAM
    ld   a, (kTrFileRef+0x0B) ; Get destination MSB
    ld   h, a           ; Set destination MSB
    ld   l, 0           ; Set destination LSB to zero
    ld   bc, .RomRunReturn ; Get return address
    push bc             ; Push return address onto stack
    jp   (hl)           ; Execute at start address


    ;; Get help from current file reference
    ;;   On entry: File reference must be in RAM
    ;;   On exit:  DE = Pointer to start of Help string
    ;;             IX IY I AF' BC' DE' HL' preserved
RomGetHlp:
    ld   hl, (kTrFileRef+0x0C) ; Get start address
    ld   bc, (kTrFileRef+0x0E) ; Get length address
    ld   de, kStrBuffer ; Copy help to string buffer
    ld   a, (iRomBank)  ; get code's ROM bank
    call RomCopy        ; Move code to RAM
    ld   de, kStrBuffer ; Copy help to string buffer
    ret


    ;; Get pointer to file name
    ;;   On entry: File reference must be in RAM
    ;;   On exit:  DE = Pointer to start of Help string
    ;;             BC HL IX IY I AF' BC' DE' HL' preserved
    ;; Returns a string with length as first byte and no Null terminator
RomGetName:
    ld   a, 8           ; Length of file name
    ld   de, kTrFileRef+1 ; Location in file reference
    ld   (de), a        ; Store length as start of name
    ret


    ;; Get file type
    ;;   On entry: File reference must be in RAM
    ;;   On exit:  A = File type and flags for current file reference
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
RomGetType:
    ld   a, (kTrFileRef+10)
    ret


    ;; Get file info
    ;;   On entry: File reference must be in RAM
    ;;   On exit:  DE = File's start address in the ROM
    ;;             BC = File's length
    ;;             AF HL IX IY I AF' BC' DE' HL' preserved
RomGetInfo:
    ld   de, (kTrFileRef+0x0C) ; Start address
    ld   bc, (kTrFileRef+0x0E) ; File length
    ret


    ;; Get file reference from ROM
    ;;   On entry: A = ROM bank number (0 to 3)
    ;;             L = Lo byte of file reference address
    ;;   On exit:  IX IY I AF' BC' DE' HL' preserved
    ;; A file reference is copied from ROM to a fixed location in RAM
RomGetRef:
    ld   h, kROMTop     ; Hi byte of reference address
    ld   de, kTrFileRef ; Transient storage for reference
    ld   bc, 16         ; Length of file reference
    call RomCopy        ; Go copy ref from ROM to RAM
    ;; Ensure start address is the absolute address in the memory map
    ld   a, (kTrFileRef+0x0D) ; Get start address hi byte
    and  kROMTop        ; Mask with top of ROM
    ld   (kTrFileRef+0x0D), a ; Store start address hi byte
    ret


    ;; **********************************************************************
    ;; **  Private workspace (in RAM)                                      **
    ;; **********************************************************************

    .bss

iRomBank:
    .db  0
iRomRefLo:
    .db  0
iRomMap:
    .db  0              ; One bit for each bank, 1=Echo
iRomTemp:
    .dw  0

    ;; **********************************************************************
    ;; **  End of ROM Filing System module                                 **
    ;; **********************************************************************

    #endif // IncludeRomFS
