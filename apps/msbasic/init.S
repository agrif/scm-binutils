    ;; see msbasic.h for more info

    #include "msbasic.h"

    .section .init

COLD:
    jp   .STARTB        ; Jump for cold start
WARM:
    jp   WARMST         ; Jump for warm start
.STARTB:
    ld   ix, 0          ; Flag cold start
    jp   CSTART         ; Jump to initialise

    .dw  DEINT          ; Get integer -32768 to 32767
    .dw  ABPASS         ; Return integer in AB


CSTART:
    ld   hl, WRKSPC     ; Start of workspace RAM
    ld   SP, hl         ; Set up a temporary stack
    jp   INITST         ; Go to initialise

INIT:
    ld   de, INITAB     ; Initialise workspace
    ld   b, INITLE+3    ; Bytes to copy
    ld   hl, WRKSPC     ; Into workspace RAM
.COPY:
    ld   a, (de)        ; Get source
    ld   (hl), a        ; To destination
    inc  hl             ; Next destination
    inc  de             ; Next source
    dec  b              ; Count bytes
    jp   nz, .COPY      ; More to move
    ld   SP, hl         ; Temporary stack
    call CLREG          ; Clear registers and stack
    call PRNTCRLF       ; Output CRLF
    ld   (BUFFER+72+1), a ; Mark end of buffer
    ld   (PROGST), a    ; Initialise program area

.MSIZE:
    ld   hl, .MEMMSG    ; Point to message
    call PRS            ; Output "Memory size"
    call PROMPT         ; Get input with '?'
    call GETCHR         ; Get next character
    or   a              ; Set flags
    jp   nz, .TSTMEM    ; If number - Test if RAM there

    #ifdef BUILD_GRANTS_ORIGINAL
    ;; Original code to determine top of free memory <SCC>
    ld   hl, STLOOK     ; Point to start of RAM
.MLOOP:
    inc  hl             ; Next byte
    ld   a, h           ; Above address FFFF ?
    or   l
    jp   z, .SETTOP     ; Yes - 64K RAM
    ld   a, (hl)        ; Get contents
    ld   b, a           ; Save it
    cpl                 ; Flip all bits
    ld   (hl), a        ; Put it back
    cp   (hl)           ; RAM there if same
    ld   (hl), b        ; Restore old contents
    jp   z, .MLOOP      ; If RAM - test next byte
    jp   .SETTOP        ; Top of RAM found
    #else
    ;; SCMonitor compatible code to determine top of free memory <SCC>
    ld   c, 0x28        ; SCMonitor API 0x28
    rst  0x30           ;   Get top of free memory (to DE)
    ex   de, hl         ; Get top in HL
    inc  hl             ; For compatibility with original
    jr   .SETTOP        ; Top of RAM found
    #endif

.TSTMEM:
    call ATOH           ; Get high memory into DE
    or   a              ; Set flags on last byte
    jp   nz, SNERR      ; ?SN Error if bad character
    ex   de, hl         ; Address into HL
    dec  hl             ; Back one byte
    ld   a, 11011001B   ; Test byte
    ld   b, (hl)        ; Get old contents
    ld   (hl), a        ; Load test byte
    cp   (hl)           ; RAM there if same
    ld   (hl), b        ; Restore old contents
    jp   nz, .MSIZE     ; Ask again if no RAM

.SETTOP:
    dec  hl             ; Back one byte
    ld   de, STLOOK-1   ; See if enough RAM
    call CPDEHL         ; Compare DE with HL
    jp   c, .MSIZE      ; Ask again if not enough RAM
    ld   de, 0xffce     ; 50 Bytes string space   <SCC> was 0-50
    ld   (LSTRAM), hl   ; Save last available RAM
    add  hl, de         ; Allocate string space
    ld   (STRSPC), hl   ; Save string space
    call CLRPTR         ; Clear program area
    ld   hl, (STRSPC)   ; Get end of memory
    ld   de, 0xffef     ; Offset for free bytes   <SCC> was 0-17
    add  hl, de         ; Adjust HL
    ld   de, PROGST     ; Start of program text
    ld   a, l           ; Get LSB
    sub  e              ; Adjust it
    ld   l, a           ; Re-save
    ld   a, h           ; Get MSB
    sbc  a, d           ; Adjust it
    ld   h, a           ; Re-save
    push hl             ; Save bytes free
    ld   hl, .SIGNON    ; Sign-on message
    call PRS            ; Output string
    pop  hl             ; Get bytes free back
    call PRNTHL         ; Output amount of free memory
    ld   hl, .BFREE     ; " Bytes free" message
    call PRS            ; Output string

WARMST:
    ld   SP, STACK      ; Temporary stack
BRKRET:
    call CLREG          ; Clear registers and stack
    jp   PRNTOK         ; Go to get command line

    .section .init.rodata

.BFREE:
    .asciz " Bytes free\r\n"
    .db  0

.SIGNON:
    .ascii "Z80 BASIC Ver 4.7b\r\n"
    .ascii "Copyright (C)"
    .asciz " 1978 by Microsoft\r\n"
    .db  0

.MEMMSG:
    .asciz "Memory top"
