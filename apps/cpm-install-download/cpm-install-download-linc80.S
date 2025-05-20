    ;; **********************************************************************
    ;; **  LiNC80-friendly Wrapper for DOWNLOAD2.HEX      by Jon Langseth  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif
    ;;
    ;; Grant Searle's DOWNLOAD2.HEX contains the useful DOWNLOAD.COM transient
    ;; for CP/M, designed to be loaded with his "relocator" placed at FFE8.
    ;; Unfortunately, that loader does not work well in the LiNC80 with SCMon,
    ;; and to retain compatibility with Grant Searle's Loader, I have no wish
    ;; to patch it to work with SCMon. Because of that, I made this replacement.
    ;;
    ;; This code is designed to be built using SCWorkshop (see http://scc.me.uk)
    ;; It loads DOWNLOAD2.HEX automagically to $4100-> and provides a simple
    ;; memory relocator on $8000->
    ;;
    ;; To use, boot into SCMon and paste in the compiled HEX file
    ;; Then execute the relocator using the "G8000" command. When you are
    ;; returned to the monitor, boot to CP/M using the CPM command, and
    ;; save the binary data using "SAVE 2 DOWNLOAD.COM"

    .equ TPA, 0x0100

    ;; (agrif) FIXME these are memory locations that *should* be taken
    ;; from a built SCM
    .equ iConfigCpy, 0xfff0
    .equ iConfigPre, 0xfff1

    #define kConfigReg 0x38


    ;; Source the original DOWNLOAD2.HEX
    .data
SrcAdr:
    .incbin DOWNLOAD_BIN
    ;; (agrif) original includes these extra 8 bytes. bug in SCWorkshop?
    .fill 8, 1, 0xff
SrcEnd:
    ;; (agrif) align SrcLen to 0x1000
    #define SrcLen +((SrcEnd - SrcAdr + 0xfff) & ~0xfff)


    ;; The "FFE8-replacement":
    .text
    .globl Main
Main:
    ;; Output a startup message
    ld   de, MsgStarting
    ld   c, 6           ; Use SCMon API 0x06
    call 0x30           ;  = Output string

    ;; AFAIK, we decided to not include a ConfReg API handler
    ;; So, at least for now, use hard coded behaviour to disable ROM:
    ld   a, (iConfigCpy) ; Get current config byte
    ld   (iConfigPre), a ; Store as 'previous' config byte

    ld   a, $01
    ld   (iConfigCpy), a ; Store new value to shadow copy
    out  (kConfigReg), a ; Set the config register

    ;; Do the copy. It's a simple LDIR of SrcLen bytes from SrcAdr to TPA
    ld   hl, SrcAdr
    ld   de, TPA
    ld   bc, SrcLen
    ldir

    ;; Load the original config register content from the shadow register
    ld   a, (iConfigPre) ; Get previous config byte
    ld   (iConfigCpy), a ; Store as current config byte
    out  (kConfigReg), a ; Set the config register

    ;; Signoff message, we're done.
    ld   de, MsgDone
    ld   c, 6
    call 0x30

    ret

MsgStarting:
    .asciz "Disabling ROM and copying data to RAM\r\n"
MsgDone:
    .ascii "Done copying data from $4100 to $0100. ROM restored.\r\n"
    .asciz "Boot to CPM and run SAVE 2 DOWNLOAD.COM\r\n"
