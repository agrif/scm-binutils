// **********************************************************************
// **  Config: R* = RC2014                       by Stephen C Cousins  **
// **********************************************************************
// see scm.h for more info

// Target hardware
#define RC2014_Z80             // Determines hardware support included

// Build variations:

// Standard build: 8k ROM
// All official RC2014 systems can run this
// Paged ROM board set for 8k page size
// 64k RAM board set to start at 8k (not page enabled)
#if BUILD_R1
#define kConfMinor '1'         // Config: 1 to 9 = official, 0 = user
#define kCode      0x0000      // Typically 0x0000 or 0xE000
#define kData      0xFC00      // Typically 0xFC00 (to 0xFFFF)
#define kROMBanks  1           // Number of software selectable ROM banks
#define kROMTop    0x1F        // Top of banked ROM (hi byte only)
#endif

// Standard build: 16k ROM
// Paged ROM board set for 16k page size
// 64k RAM board set to start at 16k (not page enabled)
#if BUILD_R2
#define kConfMinor '2'         // Config: 1 to 9 = official, 0 = user
#define kCode      0x0000      // Typically 0x0000 or 0xE000
#define kData      0xFC00      // Typically 0xFC00 (to 0xFFFF)
#define kROMBanks  1           // Number of software selectable ROM banks
#define kROMTop    0x3F        // Top of banked ROM (hi byte only)
#endif

// Standard build: 32k ROM
// Paged ROM board set for 32k page size
// 64k RAM board set to page enabled
#if BUILD_R3
#define kConfMinor '3'         // Config: 1 to 9 = official, 0 = user
#define kCode      0x0000      // Typically 0x0000 or 0xE000
#define kData      0xFC00      // Typically 0xFC00 (to 0xFFFF)
#define kROMBanks  1           // Number of software selectable ROM banks
#define kROMTop    0x7F        // Top of banked ROM (hi byte only)
#endif

// Distribution build: 16k ROM (with BASIC and CP/M loader)
// Paged ROM board set for 32k page size
// 64k RAM board set to page enabled
#if BUILD_R4
#define kConfMinor '4'         // Config: 1 to 9 = official, 0 = user
#define kCode      0x0000      // Typically 0x0000 or 0xE000
#define kData      0xFC00      // Typically 0xFC00 (to 0xFFFF)
#define kROMBanks  1           // Number of software selectable ROM banks
#define kROMTop    0x3F        // Top of banked ROM (hi byte only)
#endif

// Common to all builds for this hardware:

// Configuration identifiers
#define kConfMajor 'R'         // Config: Letter = official, number = user
//#define kConfMinor '1'       // Config: 1 to 9 = official, 0 = user

// Code assembled here (ROM or RAM)
// Address assumed to be on a 256 byte boundary
// Space required currently less than 0x1E00 bytes
//#define kCode     0x0000     // Typically 0x0000 or 0xE000

// Data space here (must be in RAM)
// Address assumed to be on a 256 byte boundary
// Space required currently less 0x0400 bytes
//#define kData     0xFC00     // Typically 0xFC00 (to 0xFFFF)

// Default values written to fixed locations in ROM for easy modification
#define kConDef    1           // Console device 1 is SIOA or 68B50
#define kBaud1Def  0x96        // Console device 1 default baud rate
#define kBaud2Def  0x96        // Console device 2 default baud rate

// ROM Filing System
//#define kROMBanks 2          // Number of software selectable ROM banks
//#define kROMTop   0x3F       // Top of banked ROM (hi byte only)

// Timing
#define kDelayCnt  306         // Loop count for 1 ms delay at 7.3728 MHz

// Optional ROM filing system information
#define ROMFS_Monitor_EXE      // Monitor.EXE

// Optional features (comment out or rename unwanted features)
// Excluding any of these may result in bugs as I don't test every option

// Exporting functions:
#define IncludeAPI             // Application Programming Interface (API)
#define IncludeFDOS            // Very limited CP/M style FDOS support

// Support functions:
#define IncludeStrings         // String support (needs utilities)
#define IncludeUtilities       // Utility functions (needs strings)

// Monitor functions:
#define IncludeMonitor         // Monitor essentials
#define IncludeAssembler       // Assembler (needs disassembler)
//#define IncludeBaud          // Baud rate setting
#define IncludeBreakpoint      // Breakpoint and single stepping
#define IncludeCommands        // Command Line Interprester (CLI)
#define IncludeDisassemble     // Disassembler
#define IncludeHelp            // Extended help text
#define IncludeHexLoader       // Intel hex loader
#define IncludeMiniTerm        // Mini terminal support
//#define IncludeTrace         // Trace execution

// Extensions:
#define IncludeRomFS           // ROM filing system
//#define IncludeScripting     // Simple scripting (needs monitor)
#define IncludeSelftest        // Self test at reset

// defines for any hardware options would go here

#define kSIO2      0x80        // Base address of SIO/2 chip
#define kACIA1     0x80        // Base address of serial ACIA #1
#define kACIA2     0x40        // Base address of serial ACIA #2
#define kPrtIn     0x00        // General input port
#define kPrtOut    0x00        // General output port

// **********************************************************************
// **  End of configuration details                                    **
// **********************************************************************
