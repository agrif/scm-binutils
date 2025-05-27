    ;; **********************************************************************
    ;; **  Hex file loader                           by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module loads an Intel Hex file from the current input device.
    ;;
    ;; An Intel Hex file is a text file where each line is a record.
    ;;
    ;; A record starts with a colon (':') and ends with CR and/or LF.
    ;;
    ;; The next two characters form a hex byte which is the number of data
    ;; bytes in the record.
    ;;
    ;; The next four characters form a hex word which is the start address
    ;; for the record's data bytes. High byte first.
    ;;
    ;; The next two characters form a hex byte which describes the type of
    ;; record. 0x00 is a normal data record. 0x01 is an end of file marker.
    ;;
    ;; Then follows the specified number of data bytes, each written as two
    ;; character hex number.
    ;;
    ;; Finally there is a checksum byte in the form of a two character hex
    ;; number.
    ;;
    ;; To test the checksum simply add up all bytes in the record, including
    ;; the checksum (but not the colon), and test to see if it is zero.
    ;;
    ;; The checksum is calculated by adding together all bytes in the record
    ;; except the checksum byte and the colon character, ANDing with 0xFF
    ;; and then subtracting from 0x100.
    ;;
    ;; Example record:
    ;;   :0300300002337A1E
    ;; Record Length: 03 (3 bytes of data)
    ;; Address: 0030 (the 3 bytes will be stored at 0030, 0031, and 0032)
    ;; Record Type: 00 (normal data)
    ;; Data: 02, 33, 7A
    ;; Checksum: 1E (03 + 00 + 30 + 00 + 02 + 33 + 7A = E2, 100 - E2 = 1E)
    ;;
    ;; The last line of the file is an end marker with 00 data bytes and
    ;; record type 01, and so is:
    ;;   :00000001FF
    ;;
    ;; Test file: (loads data 0x03 0x02 0x01 to address 0x4000)
    ;;   :03400000030201B7
    ;;   :00000001FF
    ;;
    ;; Public functions provided
    ;;   HexLoad               Load hex file from the current console input

    #ifdef IncludeHexLoader

    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    ;; HexLoader: Load an intel hex file from the current console input
    ;;   On entry: No parameters required
    ;;   On exit:  IX IY I AF' BC' DE' HL' preserved
HexLoad:
    ld   c, 0           ; Clear checksum of this whole file
.HexLoadLine:
    call InputChar      ; Get first character in record/line
    cp   kSpace         ; Control character?
    jr   c, .HexLoadLine ; Yes, so discard it
    cp   kColon         ; Colon?
    ret  nz             ; No, so return with this character
    ;;ld   c, 0         ; Clear checksum for this line only
    ;; Get number of data bytes in this record
    call HexGetByte     ; Get number of data bytes
    ld   b, a           ; Store number of data bytes in record
    add  a, c           ; Add to checksum
    ld   c, a
    ;; Get start address for this record
    call HexGetByte     ; Get address hi byte
    ld   d, a           ; Store address hi byte
    add  a, c           ; Add to checksum
    ld   c, a
    call HexGetByte     ; Get address lo byte
    ld   e, a           ; Store address lo byte
    add  a, c           ; Add to checksum
    ld   c, a
    ;; Get record type
    call HexGetByte     ; Get record type
    ld   h, a           ; Store record type
    add  a, c           ; Add to checksum
    ld   c, a
    ;; Input any data bytes in this record
    ld   a, b           ; Get number of bytes in record
    or   a              ; Zero?
    jr   z, .HexLoadCheck ; Yes, so skip..
.HexLoadData:
    call HexGetByte     ; Get data byte
    ld   (de), a        ; Store data byte in memory
    inc  de             ; Point to next memory location
    add  a, c           ; Add to checksum
    ld   c, a
    djnz .HexLoadData
    ;; Get checksum byte for this record
.HexLoadCheck:
    call HexGetByte     ; Get checksum byte
    add  a, c           ; Add to checksum
    ld   c, a
    ;; Should now test checksum for this line, but instead keep a checksum
    ;; for the whole file and test only at the end. This avoids having to
    ;; store a failure flag (no registers left) whilst still allowing this
    ;; function to flush all lines of the file.
    ;; Test for end of file
    ld   a, h           ; Get record type
    cp   1              ; End of file?
    jr   nz, .HexLoadLine ; No, so repeat for next record
    ;; End of file so test checksum
    ld   a, c           ; Get checksum
    or   a              ; It should be zero?
    ld   a, kMsgReady   ; Prepare for checksum ok message
    jr   z, .HexLoadResult ; Skip if checksum ok
    ld   a, kMsgFileEr  ; File error message number
.HexLoadResult:
    call MonOutputMsg   ; Output message #A
    xor  a              ; Return null character
    ld   a, kNewLine
    ld   a, kReturn
    ret


    ;; **********************************************************************
    ;; **  Private functions                                               **
    ;; **********************************************************************

    ;; HexLoader: Get byte from two hex characters from current console input
    ;;   On entry: No parameters required
    ;;   On exit:  A = Bytes received
    ;;             BC DE H IX IY I AF' BC' DE' HL' preserved
HexGetByte:
    call InputChar      ; Get character from input device
    call ConvertCharToNumber
    rlca
    rlca
    rlca
    rlca
    ld   l, a           ; Store result hi nibble
    call InputChar      ; Get character from input device
    call ConvertCharToNumber
    or   l              ; Get result byte
    ret


    ;; **********************************************************************
    ;; **  End of Hex file loader module                                   **
    ;; **********************************************************************

    #endif // IncludeHexLoader
