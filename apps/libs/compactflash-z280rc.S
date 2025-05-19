    ;; **********************************************************************
    ;; **  Compact Flash support                     by Stephen C Cousins  **
    ;; **  Modifications for Z280RC by Bill Shen <hcs>                     **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif
    ;;
    ;; **  Written as a module to be included in Small Computer Monitor Apps
    ;; **  Version 0.4 SCC 2018-05-20
    ;; **  www.scc.me.uk
    ;;
    ;; **********************************************************************
    ;;
    ;; This module provides support for Compact Flash cards
    ;;
    ;; Originally based on code by Grant Searle but not recognisable now
    ;;
    ;; **********************************************************************
    ;;
    ;; These are the function names provided by this module:
    ;; cfDiagnose                    Read card diagnostic info
    ;; cfFormat                      Format logical drive for use by CP/M
    ;; cfInfo                        Read card identification info
    ;; cfRead                        Read one or more sectors
    ;; cfSize                        Convert number of sectors to size info
    ;; cfVerify                      Verify one or more sectors
    ;; cfVerifyF                     Verify format of drive for use by CP/M
    ;; cfWrite                       Write one or more sectors

    #include "scm-api.h"
    #include "compactflash.h"


    ;; **********************************************************************
    ;; **  Customisation
    ;; **********************************************************************

    ;; Compact Flash: Select compact flash for access
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; This is called at the start of all compact flash accesses
    .pushsection .text.cfSelect
    .global cfSelect
cfSelect:
    ;; init page i/o reg to point to CF
    push bc             ; hcs save register
    push hl             ; hcs
    ld   c, 08h         ; hcs reg c points to I/O page register
    ld   l, 0           ; hcs set I/O page register to 0
    db   0edh, 6eh      ; hcs this is the op code for LDCTL (C),HL
    ;; hcs        ldctl (c), hl       ; write to I/O page register
    pop  hl             ; hcs restore reg
    pop  bc             ; hcs
    ret                 ; hcs
    .popsection

    ;; Compact Flash: Deselect compact flash for access
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; This is called at the end of all compact flash accesses
    .pushsection .text.cfDeselect
    .global cfDeselect
cfDeselect:
    ;; init page i/o reg to point to UART
    push bc             ; hcs save register
    push hl             ; hcs
    ld   c, 08h         ; hcs reg c points to I/O page register
    ld   l, 0feh        ; hcs set I/O page register to 0xFE
    db   0edh, 6eh      ; hcs this is the op code for LDCTL (C),HL
    ;;           ldctl (c), hl       ; write to I/O page register
    pop  hl             ; hcs restore reg
    pop  bc             ; hcs
    ret                 ; hcs
    .popsection


    ;; **********************************************************************
    ;; **  Public functions (and error messages)
    ;; **********************************************************************


    ;; **********************************************************************
    ;; Compact Flash: Error messages
    .pushsection .text.cfErrMsgs
    .global cfErrMsgs
cfErrMsgs:
    .asciz "No error"
    .asciz "Compact flash card not present"
    .asciz "Time-out error"
    .asciz "Compact flash card reported an error"
    .asciz "Verify error detected comparing data read back"
    .asciz "Compact flash card reports a correctable error"
    .asciz "Compact flash card reports a write fault"
    .db  0
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Initialise functions
    ;;   On entry: No parameters required
    ;;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.cfInit
    .global cfInit
cfInit:
    xor  a
    ld   (iErrorNum), a ; Clear error number
    ret
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Get error number
    ;;   On entry: No parameters required
    ;;   On exit:  A = Error number or zero if no error
    ;;             Z flagged if no error
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.cfGetError
    .global cfGetError
cfGetError:
    ld   a, (iErrorNum) ; Get error number
    or   a              ; Z flagged if no error
    ret
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: test if card is present
    ;;   On entry: No parameters required
    ;;   On exit:  A = Error number (0 if successful)
    ;;             Z flagged if no error
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.cfTstPres
    .global cfTstPres
cfTstPres:
    call cfPrep         ; Prepare compact flash card
    jr   nz, cfTstPres.NotPres ; Abort if error
    ;; xor  a
    ;; ld   (iErrorNum), a ; Clear error number
    ld   a, 5           ; Test value for sector count register
    out  (CF_SEC_CNT), a ; Write sector count register
    in   a, (CF_SEC_CNT) ; Read sector count register
    cp   5              ; Correct value read back?
    jr   z, cfTstPres.Present ; Yes, compact flash is present
cfTstPres.NotPres:
    ld   a, CF_NotPres
    ld   (iErrorNum), a ; Overwrite any existing error number
    call cfSetErr       ; Error = card not present
cfTstPres.Present:
    jp   cfGetErr       ; Return current error number
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Read card diagnostic info
    ;;   On entry: No parameter required
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.cfDiagnose
    .global cfDiagnose
cfDiagnose:
    call cfPrep         ; Prepare compact flash card
    jp   nz, cfGetErr   ; Abort if error
    ld   a, 0E0H
    out  (CF_LBA3), a
    ld   a, CF_DIAGNOSE
    out  (CF_COMMAND), a ; Perform diagnostic tests
    call cfWaitRdy      ; Wait for compact flash to be ready
    jp   nz, cfGetErr   ; Error, so abort
    in   a, (CF_ERROR)  ; Read error details
    cp   1              ; Error?
    jp   nz, cfSetErr   ; Yes, so set error
    jp   cfGetErr       ; No, so exit
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Read card identification info
    ;;   On entry: HL = Destination address
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             HL = Destination for next read
    ;;             BC DE IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.cfInfo
    .global cfInfo
cfInfo:
    call cfPrep         ; Prepare compact flash card
    jp   nz, cfGetErr   ; Abort if error
    ld   bc, 1          ; Set to read one sector
    ld   de, 0          ;  starting at sector 0x000000 *note
    ld   a, CF_IDENTIFY ; Get read identification command
    ;; jp   cfRdSec       ; Read from compact flash
    call cfRdSec        ; Read from compact flash
    ;; Byte swap needed for Z280RC
    push af
    push hl             ; hcs save the pointer to sector data
    push bc             ; hcs save reg
    ld   bc, 200h       ; hcs subtract 0x200 from hl
    sbc  hl, bc         ; hcs
    pop  bc             ; hcs restore bc reg
    call cfByteSwap     ; hcs swap the byte order
    pop  hl             ; hcs restore the pointer to sector data
    pop  af
    ret
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Read sectors
    ;;   On entry: C = Number of sectors to read
    ;;             DEB = First sector number to read
    ;;             HL = Destination address
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             HL = Destination for next read
    ;;             BC DE IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.cfRead
    .global cfRead
cfRead:
    call cfPrep         ; Prepare compact flash card
    jp   nz, cfGetErr   ; Abort if error
    ld   a, CF_RD_SEC   ; Get read sectors command
    jp   cfRdSec        ; Read from compact flash
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Write sectors
    ;;   On entry: C = Number of sectors to write
    ;;             DEB = First sector number to write
    ;;             HL = Source address for write sector data
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             HL = Source address for next sector write
    ;;             BC DE IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.cfWrite
    .global cfWrite
cfWrite:
    call cfPrep         ; Prepare compact flash card
    jp   nz, cfGetErr   ; Abort if error
    jp   cfWrSec        ; Write to compact flash
    .popsection



    ;; **********************************************************************
    ;; Compact Flash: Verify one or more sectors
    ;;   On entry: C = Number of sectors to verify
    ;;             DEB = First sector number to verify
    ;;             HL = Source address for verify sector data
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             HL = Source address for next sector verify
    ;;             BC DE IX IY I AF' BC' DE' HL' preserved
    ;; Each sector is 512 bytes long
    .pushsection .text.cfVerify
    .global cfVerify
cfVerify:
    call cfPrep         ; Prepare compact flash card
    jp   nz, cfGetErr   ; Abort if error
    jp   cfVerSec       ; Verify one or more sectors
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Format logical drive for use by CP/M
    ;;   On entry: B = Logical drive number to format (0 to N)
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; The directory contains:
    ;;   512 file entries per logical drive
    ;;    32 bytes per file entry
    ;;    16 file entries per sector (512 byte sectors)
    ;;    32 sectors per logical drive's directory
    .pushsection .text.cfFormat
    .global cfFormat
cfFormat:
    call cfPrep         ; Prepare compact flash card
    jp   nz, cfGetErr   ; Abort if error
    jp   cfForDrv       ; Format drive
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Verify format of logical drive after format for CP/M
    ;;   On entry: B = Logical drive number to format (0 to N)
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; The directory contains:
    ;;   512 file entries per logical drive
    ;;    32 bytes per file entry
    ;;    16 file entries per sector (512 byte sectors)
    ;;    32 sectors per logical drive's directory
    .pushsection .text.cfVerifyF
    .global cfVerifyF
cfVerifyF:
    call cfPrep         ; Prepare compact flash card
    jp   nz, cfGetErr   ; Abort if error
    jp   cfVerDrv       ; Verify drive
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Convert number of sectors to size info
    ;;   On entry: DEHL = Number of 512 byte sectors
    ;;   On exit:  DE = Size in decimal
    ;;             A = Units character 'M', 'G' or 'T'
    ;;             BC HL IX IY I AF' BC' DE' HL' preserved
    ;; Shift 32-bit number of sectors to the left until overflow in to bit 32
    ;; The number of shifts required provides offset into table of size info
    .pushsection .text.cfSize
    .global cfSize
cfSize:
    push bc
    push hl
    ld   c, 0xff        ; Shift count starts as -1
cfSize.Shift:
    inc  c              ; Increment count
    rl   l              ; Shift left DEHL...
    rl   h
    rl   e
    rl   d
    jr   nc, cfSize.Shift ; Repeat until overflow
    ld   b, 0
    ld   hl, cfSize.TabSize ; Locate size in decimal...
    add  hl, bc
    add  hl, bc
    ld   e, (hl)        ; DE = Size in decimal...
    inc  hl
    ld   d, (hl)
    ld   hl, cfSize.TabUnit ; Locate unit character...
    add  hl, bc
    ld   a, (hl)        ; A = Units character
    pop  hl
    pop  bc
    ret

cfSize.TabSize:
    .dw  2, 1, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1
cfSize.TabUnit:
    .db  "TTGGGGGGGGGGMMMMMMMMMM"
    .popsection


    ;; **********************************************************************
    ;; **  Private functions (not called directly by Apps)
    ;; **********************************************************************


    ;; **********************************************************************
    ;; Compact Flash: Prepare Compact Flash
    ;;   On entry: No parameters required
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Set compact flash for 8-bit IDE and no cache
    ;; Ignore errors until compact flash is prepared
    .pushsection .text.cfPrep
    .global cfPrep
cfPrep:
    call cfSelect       ; Select compact flash access
    call cfWaitRdy1     ; Wait for compact flash to be ready
    ;; jr   nz, cfGetErr  ; Abort if we get an error
    xor  a
    ld   (iErrorNum), a ; Clear error number
    ld   (iErrorVer), a ; Clear verify error flag
    ld   a, 0E0H
    out  (CF_LBA3), a
    ;; hcs            ld   a,CF_8BIT
    ;; hcs            out  (CF_FEATURE), a ; Store feature code
    ;; hcs            ld   a, CF_SET_FEAT ; Get set features command
    ;; hcs            out  (CF_COMMAND), a ; Perform set features
    ;; hcs            call cfWaitRdy      ; Wait for compact flash to be ready
    ;; hcs            jr   nz, cfGetErr   ; Abort if we get an error
    ;; ld   a, CF_NOCACHE ; Set no write cache
    ;; out  (CF_FEATURE), a ; Store feature code
    ;; ld   a, CF_SET_FEAT ; Get set features command
    ;; out  (CF_COMMAND), a ; Perform set features
    ;; call cfWaitRdy     ; Wait for compact flash to be ready
    ;; jr   nz, cfGetErr  ; Abort if time out
    ;; xor  a
    ;; ld   (iErrorNum), a ; Clear error number
    ;; ld   (iErrorVer), a ; Clear verify error flag
    ret
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Set error number
    ;;   On entry: A = Error number or zero if no error
    ;;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Any existing error number is not overwritten
    .pushsection .text.cfSetErr
    .global cfSetErr
cfSetErr:
    push af
    ld   a, (iErrorNum) ; Get error number
    or   a              ; Any error so far
    jr   nz, cfSetErr.Abort ; Do not overwrite existing error
    pop  af
    ld   (iErrorNum), a ; Store new error number
    jr   cfSetErr.Done
cfSetErr.Abort:
    pop  af
cfSetErr.Done:
    jp   cfGetErr       ; Return current error number
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Get error number
    ;;   On entry: No parameters required
    ;;   On exit:  A = Error number or zero if no error
    ;;             Z flagged if no error
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.cfGetErr
    .global cfGetErr
cfGetErr:
    call cfDeselect     ; Deselect compact flash access
    ld   a, (iErrorNum) ; Get error number
    or   a              ; Z flagged if no error
    ret
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Wait for compact flash to be ready
    ;;   On entry: No parameters required
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.cfWaitRdy
    .global cfWaitRdy
    ;; hcs diagnostic
cfWaitRdy:
    in   a, (CF_STATUS) ; hcs diagnostic
    and  80h            ; hcs diagnostic chk busy
    jp   nz, cfWaitRdy  ; hcs diagnostic
    in   a, (CF_STATUS) ; hcs diagnostic
    bit  6, a           ; hcs diagnostic test ready flag
    jp   z, cfWaitRdy
    xor  a              ; hcs diagnostic
    ret                 ; hcs diagnostic
cfWaitRdy1:
    push de
    ld   de, 0          ; Time out counter
cfWaitRdy1.Test:
    dec  de             ; Decrement timer
    ld   a, e           ; Time out?
    or   d
    jr   z, cfWaitRdy1.Timeout ; Yes, so error
    jr   cfWaitRdy1.Delay1 ; Delay to extend time-out
cfWaitRdy1.Delay1:
    jr   cfWaitRdy1.Delay2 ; Delay to extend time-out
cfWaitRdy1.Delay2:
    jr   cfWaitRdy1.Delay3 ; Delay to extend time-out
cfWaitRdy1.Delay3:
    in   a, (CF_STATUS) ; Read status register
    bit  7, a           ; Test Busy flag
    jr   nz, cfWaitRdy1.Test ; High so busy
    in   a, (CF_STATUS) ; Read status register
    bit  6, a           ; Test Ready flag
    jr   z, cfWaitRdy1.Test ; Low so not ready
    pop  de
    jp   cfTstErr       ; Go test for errors
cfWaitRdy1.Timeout:
    pop  de
    ld   a, CF_Timeout  ; Return time out error
    jp   cfSetErr       ; Store any error
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Wait for compact flash DRQ flag
    ;;   On entry: No parameters required
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.cfWaitDRQ
    .global cfWaitDRQ
    ;; hcs diagnostic
cfWaitDRQ:
    in   a, (CF_STATUS) ; hcs diagnostic
    and  8              ; hcs diagnostic
    jp   z, cfWaitDRQ   ; hcs diagnostic
    xor  a              ; hcs diagnostic
    ret                 ; hcs diagnostic
    ;; hcs cfWaitDRQ:  PUSH DE
    ld   de, 0          ; Time out counter
cfWaitDRQ.Test:
    dec  de             ; Decrement timer
    ld   a, e           ; Time out?
    or   d
    jr   z, cfWaitDRQ.Timeout ; Yes, so error
    jr   cfWaitDRQ.Delay1 ; Delay to extend time-out
cfWaitDRQ.Delay1:
    jr   cfWaitDRQ.Delay2 ; Delay to extend time-out
cfWaitDRQ.Delay2:
    jr   cfWaitDRQ.Delay3 ; Delay to extend time-out
cfWaitDRQ.Delay3:
    in   a, (CF_STATUS) ; Read status register
    bit  3, a           ; Test DRQ flag
    jr   z, cfWaitDRQ.Test ; Low so not ready
    pop  de
    jp   cfTstErr       ; Go test for errors
cfWaitDRQ.Timeout:
    pop  de
    ld   a, CF_Timeout  ; Return time out error
    jp   cfSetErr       ; Store any error
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Test for compact flash error
    ;;   On entry: No parameters required
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.cfTstErr
    .global cfTstErr
cfTstErr:
    in   a, (CF_STATUS) ; Read status register
    and  0b00100101     ; General error or write error or correctable
    jr   z, cfTstErr.Success ; No, so successful
    bit  2, a           ; Correctable error?
    jr   nz, cfTstErr.ErCorrect ; Yes, so report it
    bit  5, a           ; Write fault?
    jr   nz, cfTstErr.ErWrite ; Yes, so report it
    in   a, (CF_ERROR)  ; Read error details
    ld   (iErrorReg), a ; Store error details
    ld   a, CF_ErrFlag  ; Return error number
    jp   cfSetErr       ; Store any error
cfTstErr.Success:
    ld   a, (iErrorVer) ; Get verify error flag
    or   a              ; Any verify errors?
    jr   nz, cfTstErr.ErVerify ; Yes, so report it
    jp   cfGetErr       ; Return error status
cfTstErr.ErCorrect:
    ld   a, CF_Correct  ; Compact flash reports correctable error
    jp   cfSetErr       ; Store error
cfTstErr.ErWrite:
    ld   a, CF_Write    ; Compact flash reports a write fault
    jp   cfSetErr       ; Store error
cfTstErr.ErVerify:
    ld   a, CF_Verify   ; Verify error detected when comparing
    jp   cfSetErr       ; Store error
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Set command
    ;;   On entry: A = Command (ie. CF_xxx)
    ;;             C = Number of sectors to access
    ;;             DEB = First sector number to read
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             BC DE IX IY I AF' BC' DE' HL' preserved
    ;; Each sector is 512 bytes long
    .pushsection .text.cfSetCmd
    .global cfSetCmd
cfSetCmd:
    push af
    ld   a, b           ; Set up LBA parameters...
    out  (CF_LBA0), a
    ld   a, e
    out  (CF_LBA1), a
    ld   a, d
    out  (CF_LBA2), a
    ld   a, 0E0H
    out  (CF_LBA3), a
    ld   a, c           ; Get number of sectors to access
    out  (CF_SEC_CNT), a ; Set sector count
    pop  af
    out  (CF_COMMAND), a ; Set command
    jp   cfWaitRdy      ; Wait for compact flash to be ready
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Read one or more sectors
    ;;   On entry: A = Command ie. CF_RD_SEC or CF_IDENTIFY
    ;;             C = Number of sectors to read
    ;;             DEB = First sector number to read
    ;;             HL = Destination address for read sector data
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             HL = Destination address for next sector read
    ;;             BC DE IX IY I AF' BC' DE' HL' preserved
    ;; Each sector is 512 bytes long
    .pushsection .text.cfRdSec
    .global cfRdSec
cfRdSec:
    push bc
    push de
    call cfSetCmd       ; Set command: A=Cmd, C=Sectors, DEB=LBAsect
    jr   nz, cfRdSec.Abort ; Abort if time out
    ld   b, c           ; Number of sectors to read
    ;; Wait for compact flash before reading data
cfRdSec.Sector:
    call cfWaitDRQ      ; Wait for compact flash DRQ flag
    jr   nz, cfRdSec.Abort ; Abort if time out
    ;; hcs            push bc
    ;; hcs            ld   c, 4           ; One sector = 4 x 128 byte blocks
    ;; hcscfRdSec.Block: ld   b, 128         ; One block = 128 bytes
    ;; hcscfRdSec.Byte:  in   a, (CF_DATA)   ; Read data byte from compact flash
    ;; hcs            nop
    ;; hcs            nop
    ;; hcs            ld   (hl), a        ; Store data byte read
    ;; hcs            inc  hl             ; Point ot next byte
    ;; hcs            djnz cfRdSec.Byte   ; Repeat for all 128 bytes in block
    ;; hcs            dec  c
    ;; hcs            jr   NZ,cfRdSec.Block ; Repeat for all 4 blocks
    ;; hcs            pop  bc
    ;; hcs            djnz cfRdSec.Sector ; Repeat for all required sectors
    ;; hcs discard         push hl           ; hcs save the hl reg before sector read
    ld   c, CF_DATA     ; hcs reg C points to CF data reg
    ld   b, 0h          ; hcs sector has 256 16-bit data
    db   0edh, 92h      ; hcs op code for inirw input word and increment

    ;; hcs        inirw
    ;; hcs discard         ex (sp), hl       ; hcs swap before & after values of HL
    ;; hcs discard         call byteswap     ; hcs swap byte
    ;; hcs discard         pop hl            ; hcs restore the after value of HL
    ;; Read complete, now check for errors
    call cfWaitRdy      ; Wait for compact flash to be ready

cfRdSec.Abort:
    pop  de
    pop  bc
    jp   cfGetErr       ; Return error number
    .popsection

    ;; Alternative faster transfer method (read version shown)
    ;; cfRdSec.Sector: call cfWaitDRQ     ; Wait for compact flash DRQ flag
    ;;           jr   nz, cfRdSec.Abort   ; Abort if time out
    ;;           push bc             ; Preserve sector number and count
    ;;           ld   e, 4           ; 1 sector = 4 x 128 byte blocks
    ;;           ld   c, CF_DATA     ; Compact flash data register
    ;; cfRdSec.Block: ld   b, 128    ; Block size
    ;;           inir                ; (HL)=(C), HL=HL+1, B=B-1, repeat
    ;;           dec  e              ; Decrement block counter
    ;;           jr   nz, cfRdSec.Block ; Repeat until all blocks read
    ;;           pop  bc             ; Preserve sector number and count
    ;;           djnz cfRdSec.Sector ; Repeat for all required sectors
    ;; hcs do byte swap
    .pushsection .text.cfByteSwap
    .global cfByteSwap
    ;; hcs
cfByteSwap:
    push ix             ; hcs save reg
    push bc             ; hcs save reg
    push de             ; hcs save reg
    push hl             ; hcs copy HL to IX
    pop  ix             ; hcs
    ld   b, 0h          ; hcs counter
    ;; hcs
cfByteSwap.byteswap1:
    ld   d, (IX+0)      ; hcs swap the MSB and LSB byte
    ld   e, (IX+1)      ; hcs this is awkward, better algorithm needed
    ld   (IX+0), e      ; hcs
    inc  ix             ; hcs
    ld   (IX+0), d      ; hcs
    inc  ix             ; hcs
    djnz cfByteSwap.byteswap1 ; hcs do this 256 times
    pop  de             ; hcs restore reg
    pop  bc             ; hcs restore reg
    pop  ix             ; hcs restore reg
    ret                 ; hcs
    .popsection

    ;; **********************************************************************
    ;; Compact Flash: Write one or more sectors
    ;;   On entry: C = Number of sectors to write
    ;;             DEB = First sector number to write
    ;;             HL = Source address for write sector data
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             HL = Source address for next sector write
    ;;             BC DE IX IY I AF' BC' DE' HL' preserved
    ;; Each sector is 512 bytes long
    .pushsection .text.cfWrSec
    .global cfWrSec
cfWrSec:
    push bc
    push hl
    ld   a, CF_WR_SEC
    call cfSetCmd       ; Set command: A=Cmd, C=Sectors, DEB=LBAsect
    jr   nz, cfWrSec.Abort ; Abort if time out
    ld   b, c           ; Number of sectors to read
    ;; Wait for compact flash before writing data
cfWrSec.Sector:
    call cfWaitDRQ      ; Wait for compact flash DRQ flag
    jr   nz, cfWrSec.Abort ; Abort if time out
    ;; hcs            push bc
    ;; hcs            ld   c, 4           ; One sector = 4 x 128 byte blocks
    ;; hcscrWrSec.Block: ld   b, 128      ; One block = 128 bytes
    ;; hcscrWrSec.Byte: ld   a, (hl)      ; Get data byte to be written
    ;; hcs            nop
    ;; hcs            nop
    ;; hcs            out  (CF_DATA), a   ; Write data byte to compact flash
    ;; hcs            inc  hl             ; Point ot next byte
    ;; hcs            djnz crWrSec.Byte   ; Repeat for all 128 bytes in block
    ;; hcs            dec  c
    ;; hcs            jr   nz, crWrSec.Block ; Repeat for all 4 blocks
    ;; hcs            pop  bc
    ;; hcs            djnz cfWrSec.Sector ; Repeat for all required sectors
    ld   b, 0h          ; hcs sector has 256 16-bit data
    ld   c, CF_DATA     ; hcs reg C points to CF data reg
    db   0edh, 93h      ; hcs op code for otirw output word and increment
    ;; hcs        otirw

    ;; Write complete, now check for errors
    call cfWaitRdy      ; Wait for compact flash to be ready
cfWrSec.Abort:
    pop  hl
    pop  bc
    jp   cfGetErr       ; Return error number
    .popsection

    ;; Alternative faster transfer method (read version shown)
    ;;           push bc             ; Preserve sector number and count
    ;;           ld   e, 4           ; 1 sector = 4 x 128 byte blocks
    ;;           ld   c, CF_DATA     ; Compact flash data register
    ;; crWrSec.Block: ld   b, 128    ; Block size
    ;;           inir                ; (HL)=(C), HL=HL+1, B=B-1, repeat
    ;;           dec  e              ; Decrement block counter
    ;;           jr   nz, crWrSec.Block ; Repeat until all blocks read
    ;;           pop  bc             ; Preserve sector number and count
    ;;           djnz cfWrSec.Sector ; Repeat for all required sectors


    ;; **********************************************************************
    ;; Compact Flash: Verify one or more sectors
    ;;   On entry: C = Number of sectors to verify
    ;;             DEB = First sector number to verify
    ;;             HL = Source address for verify sector data
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;             HL = Source address for next sector verify
    ;;             BC DE IX IY I AF' BC' DE' HL' preserved
    ;; Each sector is 512 bytes long
    .pushsection .text.cfVerSec
    .global cfVerSec
cfVerSec:
    push bc
    push de
    xor  a
    ld   (iErrorVer), a ; Clear verify error flag
    ld   a, CF_RD_SEC
    call cfSetCmd       ; Set command: A=Cmd, C=Sectors, DEB=LBAsect
    jr   nz, cfVerSec.Abort ; Abort if time out
    ld   b, c           ; Number of sectors to verify
    ;; Wait for compact flash before reading data
cfVerSec.Sector:
    call cfWaitDRQ      ; Wait for compact flash DRQ flag
    jr   nz, cfVerSec.Abort ; Abort if time out
    push bc
    ld   c, 4           ; One sector = 4 x 128 byte blocks
cfVerSec.Block:
    ld   b, 128         ; One block = 128 bytes
cfVerSec.Byte:
    in   a, (CF_DATA)   ; Get byte from compact flash
    cp   (hl)           ; Compare with source byte
    call nz, cfVerSec.ErrorV ; If compare failed then flag error
    inc  hl             ; Point ot next byte
    djnz cfVerSec.Byte  ; Repeat for all 128 bytes in block
    dec  c
    jr   nz, cfVerSec.Block ; Repeat for all 4 blocks
    pop  bc
    djnz cfVerSec.Sector ; Repeat for all required sectors
    ;; Verify complete, now check for errors
    call cfWaitRdy      ; Wait for compact flash to be ready
cfVerSec.Abort:
    pop  de
    pop  bc
    jp   cfGetErr       ; Return error number
    ;; Store verify error flag
cfVerSec.ErrorV:
    ld   a, 0xff
    ld   (iErrorVer), a
    ret
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Format logical drive for use by CP/M
    ;;   On entry: B = Logical drive number to format (0 to N)
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; The directory contains:
    ;;   512 file entries per logical drive
    ;;    32 bytes per file entry
    ;;    16 file entries per sector (512 byte sectors)
    ;;    32 sectors per logical drive's directory
    .pushsection .text.cfForDrv
    .global cfForDrv
cfForDrv:
    push bc
    push de
    push hl
    ld   hl, 0          ; Start sector = HLA
    ld   a, b           ; Get drive number 0 to N
    or   a              ; Drive 0?
    ld   a, 32          ; Drive 0 has reserved track so
    jr   z, cfForDrv.Format ;  directory starts at sector 32
    ld   de, $0040      ; HL increment
cfForDrv.Calc:
    add  hl, de         ; Calculate start sector...
    djnz cfForDrv.Calc
    xor  a              ; Start sector = HLA
    ;; Start sector is now HLA (LBA2=H, LBA1=L, LBA0=A)
cfForDrv.Format:
    ld   b, a           ; Sector number least significant byte
    ex   de, hl         ; Sector number most significant bytes
    ld   c, 32          ; Prepare to write 32 sectors
    ld   a, CF_WR_SEC
    call cfSetCmd       ; Set command: A=Cmd, C=Sectors, DEB=LBAsect
    jr   nz, cfForDrv.Abort ; Abort if error
    ld   e, 32          ; Prepare to write 32 sectors
cfForDrv.Sector:
    call cfWaitDRQ      ; Wait for compact flash DRQ flag
    jr   nz, cfForDrv.Abort ; Abort if error
    ld   c, 16          ; One sector = 16 x 32 byte file entries
cfForDrv.File:
    ld   hl, cfDirData  ; Point to directory data for a file
    ld   b, 32          ; One file entry = 32 bytes
cfForDrv.WrByte:
    ld   a, (hl)        ; Get byte of directory data
    nop
    nop
    out  (CF_DATA), a   ; Write byte to compact flash
    inc  hl             ; Point to next byte
    djnz cfForDrv.WrByte ; Repeat for all bytes in block
    dec  c
    jr   nz, cfForDrv.File ; Repeat for all file entries in sector
    dec  e
    jr   nz, cfForDrv.Sector ; Repeat for all sectors
    call cfWaitRdy      ; Wait for compact flash to be ready
cfForDrv.Abort:
    pop  hl
    pop  de
    pop  bc
    jp   cfGetErr       ; Return error number
    .popsection


    ;; **********************************************************************
    ;; Compact Flash: Verify format of logical drive after format for CP/M
    ;;   On entry: B = Logical drive number to format (0 to N)
    ;;   On exit:  A = Error number (0 if no error)
    ;;             Z flagged if no error
    ;;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; The directory contains:
    ;;   512 file entries per logical drive
    ;;    32 bytes per file entry
    ;;    16 file entries per sector (512 byte sectors)
    ;;    32 sectors per logical drive's directory
    .pushsection .text.cfVerDrv
    .global cfVerDrv
cfVerDrv:
    push bc
    push de
    push hl
    xor  a
    ld   (iErrorVer), a ; Clear verify error flag
    ld   hl, 0          ; Start sector = HLA
    ld   a, b           ; Get drive number 0 to N
    or   a              ; Drive 0?
    ld   a, 32          ; Drive 0 has reserved track so
    jr   z, cfVerDrv.Verify ;  directory starts at sector 32
    ld   de, $0040      ; HL increment
cfVerDrv.Calc:
    add  hl, de         ; Calculate start sector...
    djnz cfVerDrv.Calc
    xor  a              ; Start sector = HLA
    ;; Start sector is now HLA (LBA2=H, LBA1=L, LBA0=A)
cfVerDrv.Verify:
    ld   b, a           ; Sector number least significant byte
    ex   de, hl         ; Sector number most significant bytes
    ld   c, 32          ; Prepare to write 32 sectors
    ld   a, CF_RD_SEC
    call cfSetCmd       ; Set command: A=Cmd, C=Sectors, DEB=LBAsect
    jr   nz, cfVerDrv.Abort ; Abort if error
    ld   e, 32          ; Prepare to write 32 sectors
cfVerDrv.Sector:
    call cfWaitDRQ      ; Wait for compact flash DRQ flag
    jr   nz, cfVerDrv.Abort ; Abort if error
    ld   c, 16          ; One sector = 16 x 32 byte file entries
cfVerDrv.File:
    ld   hl, cfDirData  ; Point to directory data for a file
    ld   b, 32          ; One file entry = 32 bytes
cfVerDrv.Byte:
    in   a, (CF_DATA)   ; Get byte from compact flash
    cp   (hl)           ; Compare with source directory data
    call nz, cfVerDrv.ErrorV ; If compare failed then flag error
    inc  hl             ; Point to next byte
    djnz cfVerDrv.Byte  ; Repeat for all bytes in block
    dec  c
    jr   nz, cfVerDrv.File ; Repeat for all file entries in sector
    dec  e
    jr   nz, cfVerDrv.Sector ; Repeat for all sectors
    call cfWaitRdy      ; Wait for compact flash to be ready
cfVerDrv.Abort:
    pop  hl
    pop  de
    pop  bc
    jp   cfGetErr       ; Return error number
    ;; Store verify error flag
cfVerDrv.ErrorV:
    ld   a, 0xff
    ld   (iErrorVer), a
    ret
    .popsection


    ;; Directory data for each file
    .pushsection .text.cfDirData
    .global cfDirData
cfDirData:
    .db  $E5, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $00, $00, $00, $00
    .db  $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .popsection


    ;; **********************************************************************
    ;; **  Variables
    ;; **********************************************************************

    ;; a hack - dynbass is before bss, so this is before app bss
    .section .dynbss, "w", @nobits

iErrorNum:
    .db  0              ; Error number
iErrorReg:
    .db  0              ; Error register
iErrorVer:
    .db  0              ; Verify error flag
