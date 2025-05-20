    ;; **********************************************************************
    ;; **  Compact Flash CP/M Boot Loader            by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    ;; Based on code by Grant Searle.
    ;; http://searle.hostei.com/grant/index.html

    #include "compactflash.h"


    ;; Number of 512 sectors to be loaded
    #define NumSectors 24
    ;; Length to load in bytes
    #define LoadBytes +(NumSectors * 512)


    ;; Memory map
    .bss

    ;; Temporary stack
TempStack:
    .skip 0x800
    ;; CP/M load address
LoadAddr:
    .skip LoadBytes
LoadNext:
    .equ LoadTop, LoadNext-1 ; Top of loaded bytes
    .equ CPMTop, 0xffff ; Top location used by CP/M

    .text

    .global Main
Main:
    ;; Test if compact flash present
    ld   a, 5           ; Tets value for sector count register
    out  (CF_SEC_CNT), a ; Write sector count register
    in   a, (CF_SEC_CNT) ; Read sector count register
    cp   5              ; Correct value read back?
    jr   z, Main.Present ; Yes, compact flash is present
    ld   de, MsgNotFound ; Pointer to error message
    ld   c, 6           ; API 0x06
    rst  0x30           ;  = Output string
    jp   0x0014         ; Warm start monitor
Main.Present:
    ;; Load CP/M
    call Wait           ; Wait for compact flash to be ready
    ld   a, CF_8BIT     ; Set IDE to be 8bit
    out  (CF_FEATURE), a ; Store feature code
    ld   a, CF_SET_FEAT ; Get set features command
    out  (CF_COMMAND), a ; Perform set features
    call Wait           ; Wait for compact flash to be ready
    ld   a, CF_NOCACHE  ; Set no write cache
    out  (CF_FEATURE), a ; Store feature code
    ld   a, CF_SET_FEAT ; Get set features command
    out  (CF_COMMAND), a ; Perform set features
    call Wait           ; Wait for compact flash to be ready
    ld   b, NumSectors  ; Number of physical sectors
    ld   c, 0           ; First sector number
    ld   hl, LoadAddr   ; Code from compact flash loads here
    ;; Read sectors where one sector is 4 x 128 byte blocks = 512 bytes
ReadSects:
    ld   a, c           ; Get sector number
    out  (CF_LBA0), a   ; Set sector number
    xor  a              ; Set up LBA parameters...
    out  (CF_LBA1), a
    out  (CF_LBA2), a
    ld   a, 0E0H
    out  (CF_LBA3), a
    ld   a, 1           ; Get number if sectors to read
    out  (CF_SEC_CNT), a ; Store sector count
    ld   a, CF_RD_SEC   ; Get read sectors command
    out  (CF_COMMAND), a ; Perform sector(s) read
    call Wait           ; Wait for compact flash to be ready
ReadSects.TstReady:
    in   a, (CF_STATUS) ; Read status register
    bit  3, a           ; Test DRQ flag
    jr   z, ReadSects.TstReady ; Low so not ready
    ld   e, 4           ; 1 sector = 4 x 128 byte blocks
    push bc             ; Preserve sector number and count
    ld   c, CF_DATA     ; Compact flash data register
ReadBlock:
    ld   b, 128         ; Block size
    inir                ; (HL)=(C), HL=HL+1, B=B-1, repeat
    dec  e              ; Decrement block counter
    jr   nz, ReadBlock  ; Repeat until all blocks read
    pop  bc             ; Preserve sector number and count
    inc  c              ; Increment sector number
    djnz ReadSects      ; Repeat for all required sectors
    ;; CP/M now loaded into temporary buffer in RAM
    ;; Determine current console device
    ld   c, 0x27        ; API 0x27 = Get current console
    rst  0x30           ;  = I/O devices (1 to 6) in DE
    ;; SCMonitor functions must no longer be used
    di                  ; Disable interrupts
    ld   SP, TempStack  ; Temporary stack
    ;; Page out the ROM so we now have full 64k bytes of RAM available
    ;; Writing to usual shadow copy is useless as CP/M overwrites it
    ld   a, $01         ; Value to page out ROM
    ;;           LD   (0xFFF0),A     ;Store shadow copy of paging register
    out  ($38), a       ; Write to page register
    ;; Write jump instruction at mode 1 interrupt address to fix an issue
    ;; with RC2014 cbios for 68B50, where the BIOS assumes this intruction is
    ;; already in RAM. If it is not, the BIOS dispays "A>" then hangs.
    ld   a, 0xc3        ; Instruction op-code = "JP nn"
    ld   (0x0038), a    ; Write to interrupt mode 1 address
    ;; Set up CP/M iobyte as RC2014 BIOS fails to do this due to paging issue
    ;; whereby ROM is paged back in at the time it attempts to write to iobyte
    ;; Currently D = 1 for port A, 2 for port B
    ;; CP/M iobyte must be 0 = port B, 1 = port A
    ld   a, d           ; Get console device (1 = port A, 2 = port B)
    cp   1              ; Port A?
    jr   z, ReadBlock.iobyte ; Yes, so skip
    xor  a              ; A = 0 for port B
ReadBlock.iobyte:
    ld   (0x0003), a    ; Store iobyte (1 = port A, 0 = port B)
    ;; Push SIO port number (0 = port A, 1 = port B) so that any CBIOS
    ;; that correctly sets iobyte still works
    ld   a, d           ; Get console device (1 = port A, 2 = port B)
    dec  a              ; Adjust to 0 = port A, 1 = port B
    push af             ; Store console device number on stack
    ;; Move CP/M to top of memory, overwriting SCMonitor workspace
    ld   hl, LoadTop    ; Top of bytes loaded
    ld   de, CPMTop     ; Top of CP/M's memory
    ld   bc, LoadBytes  ; Number of bytes loaded
    lddr                ; Move loaded bytes
    ;; Start CP/M using entry at top of BIOS
    ld   hl, ($FFFE)    ; Get start up address
    jp   (hl)           ; Run code downloaded from compact flash


    ;; Wait until compact flash is ready
Wait:
Wait.TstBusy:
    in   a, (CF_STATUS) ; Read status register
    bit  7, a           ; Test Busy flag
    jr   nz, Wait.TstBusy ; High so busy
Wait.TstReady:
    in   a, (CF_STATUS) ; Read status register
    bit  6, a           ; Test Ready flag
    ;;jr   z, Wait.TstReady ; Low so not ready
    jr   z, Wait.TstBusy ; Low so not ready
    ret

    ;; Error message
MsgNotFound:
    .asciz "Compact flash not present\r\n"
