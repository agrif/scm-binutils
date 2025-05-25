// =====================================================================
// Modified to be compatible with Small Computer Monitor 0.6.0 and
// SCWorkshop. Minor tweaks to Grant's version to fix syntax
// compatibility with SCWorkshop.
// The tweaks did not alter the binary output. Yes, I compared the outputs!
// Relocated code to 0x2000 & 0x8000, required changes to: WRKSPC and .ORG
// Ajusted monitor warm start address at MONITR:
// Replaced memory test limit of 0xFFFF with 0xFBFF.
// Made above easily configurable with conditional assembly, see next few
// lines.
// All changes labelled <SCC>
// converted to GNU binutils by agrif

// =====================================================================
// The updates to the original BASIC within this file are copyright
// Grant Searle
//
// You have permission to use this for NON COMMERCIAL USE ONLY
// If you wish to use it elsewhere, please include an acknowledgement to
// myself.
//
// http://searle.hostei.com/grant/index.html
//
// eMail: home.micros01@btinternet.com
//
// If the above don't work, please perform an Internet search to see if
// I have updated the web page hosting service.
//
// =====================================================================

// NASCOM ROM BASIC Ver 4.7, (C) 1978 Microsoft
// Scanned from source published in 80-BUS NEWS from Vol 2, Issue 3
// (May-June 1983) to Vol 3, Issue 3 (May-June 1984)
// Adapted for the freeware Zilog Macro Assembler 2.10 to produce
// the original ROM code (checksum 0xA934). PA

// GENERAL EQUATES

#define CTRLC       0x03        // Control "C"
#define CTRLG       0x07        // Control "G"
#define BKSP        0x08        // Back space
#define LF          0x0A        // Line feed
#define CS          0x0C        // Clear screen
#define CR          0x0D        // Carriage return
#define CTRLO       0x0F        // Control "O"
#define CTRLQ       0x11        // Control "Q"
#define CTRLR       0x12        // Control "R"
#define CTRLS       0x13        // Control "S"
#define CTRLU       0x15        // Control "U"
#define ESC         0x1B        // Escape
#define QUOTE       0x22        // Quotation mark '"'"
#define DEL         0x7F        // Delete

// BASIC ERROR CODE VALUES

#define NF          0x00        // NEXT without FOR
#define SN          0x02        // Syntax error
#define RG          0x04        // RETURN without GOSUB
#define OD          0x06        // Out of DATA
#define FC          0x08        // Function call error
#define OV          0x0A        // Overflow
#define OM          0x0C        // Out of memory
#define UL          0x0E        // Undefined line number
#define BS          0x10        // Bad subscript
#define DD          0x12        // Re-DIMensioned array
#define DZ          0x14        // Division by zero (/0)
#define ID          0x16        // Illegal direct
#define TM          0x18        // Type miss-match
#define OS          0x1A        // Out of string space
#define LS          0x1C        // String too long
#define ST          0x1E        // String formula too complex
#define CN          0x20        // Can't CONTinue
#define UF          0x22        // UnDEFined FN function
#define MO          0x24        // Missing operand
#define HX          0x26        // HEX error
#define BN          0x28        // BIN error

// RESERVED WORD TOKEN VALUES

#define ZEND        0x80        // END
#define ZFOR        0x81        // FOR
#define ZDATA       0x83        // DATA
#define ZGOTO       0x88        // GOTO
#define ZGOSUB      0x8C        // GOSUB
#define ZREM        0x8E        // REM
#define ZPRINT      0x9E        // PRINT
#define ZNEW        0xA4        // NEW

#define ZTAB        0xA5        // TAB
#define ZTO         0xA6        // TO
#define ZFN         0xA7        // FN
#define ZSPC        0xA8        // SPC
#define ZTHEN       0xA9        // THEN
#define ZNOT        0xAA        // NOT
#define ZSTEP       0xAB        // STEP

#define ZPLUS       0xAC        // +
#define ZMINUS      0xAD        // -
#define ZTIMES      0xAE        // *
#define ZDIV        0xAF        // /
#define ZOR         0xB2        // OR
#define ZGTR        0xB3        // >
#define ZEQUAL      0xB4        // M
#define ZLTH        0xB5        // <
#define ZSGN        0xB6        // SGN
#define ZPOINT      0xC7        // POINT
#define ZLEFT       +(0xCD+2)   // LEFT$
