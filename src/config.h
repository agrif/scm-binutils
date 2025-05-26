// **********************************************************************
// **  Build options                                                   **
// **********************************************************************
// see scm.h for more info

// Only one build can be defined (set in CMakeLists.txt)
// 1st character (major identifier): letter=official, number=user/custom
// 2nd character (minor identifier): 1-9=official, 0=user/custom

// **********************************************************************
// **  Include configuration file                                      **
// **********************************************************************

//          BUILD_00            // Complete custom/user build

#if         BUILD_00
#include    "hardware/custom/config-00.h"
#endif

//          BUILD_L0            // LiNC80 SBC1 custom/user build
//          BUILD_L1            // LiNC80 SBC1 standard 32k ROM

#if         BUILD_L0
#include    "hardware/custom/config-l0.h"
#elif       BUILD_L1
#include    "hardware/linc80/config.h"
#endif

//          BUILD_R0            // RC2014 custom/user build
//          BUILD_R1            // RC2014 08K ROM 32K RAM standard
//          BUILD_R2            // RC2014 16K ROM 48K RAM standard
//          BUILD_R3            // RC2014 32K ROM 32/64K RAM paged
//          BUILD_R4            // RC2014 16K ROM 32/64K RAM paged

#if         BUILD_R0
#include    "hardware/custom/config-r0.h"
#elif       BUILD_R1 || BUILD_R2 || BUILD_R3 || BUILD_R4
#include    "hardware/rc2014/config.h"
#endif

//          BUILD_S0            // SCxxx  custom/user build
//          BUILD_S1            // SC101  standard ROM
//          BUILD_S2            // SC114  standard ROM

#if         BUILD_S0
#include    "hardware/custom/config-s0.h"
#elif       BUILD_S1
#include    "hardware/sc101/config.h"
#elif       BUILD_S2
#include    "hardware/sc114/config.h"
#endif

//          BUILD_T0            // TomsSBC custom/user build
//          BUILD_T1            // TomsSBC standard ROM

#if         BUILD_T0
#include    "hardware/custom/config-t0.h"
#elif       BUILD_T1
#include    "hardware/toms-sbc/config.h"
#endif

//          BUILD_W0            // SCWorkshop simulator - custom/user
//          BUILD_W1            // SCWorkshop simulator - standard

#if         BUILD_W0
#include    "hardware/custom/config-w0.h"
#elif       BUILD_W1
#include    "hardware/workshop/config.h"
#endif

//          BUILD_Z0            // Zxxx   custom/user build
//          BUILD_Z1            // Z280RC by Bill Shen
//          BUILD_Z2            // Z80SBCRC by Bill Shen

#if         BUILD_Z0
#include    "hardware/custom/config-z0.h"
#elif       BUILD_Z1
#include    "hardware/z280rc/config.h"
#elif       BUILD_Z2
#include    "hardware/z280sbcrc/config.h"
#endif

// **********************************************************************
// **  Configuration file requirements                                 **
// **********************************************************************

// The configuration file (included just above) must contain the
// following details:

// Target hardware
//#define LiNC80                 // Determines hardware support included

// Configuration identifiers
//#define kConfMajor 'W'         // Config: Letter = official, number = user
//#define kConfMinor '1'         // Config: 1 to 9 = official, 0 = user

// Code assembled here (ROM or RAM)
// Address assumed to be on a 256 byte boundary
// Space required currently less than 0x1E00 bytes
//#define kCode      0x0000      // Typically 0x0000 or 0xE000

// Data space here (must be in RAM)
// Address assumed to be on a 256 byte boundary
// Space required currently less 0x0400 bytes
//#define kData      0xFC00      // Typically 0xFC00 (to 0xFFFF)

// Default values written to fixed locations in ROM for easy modification
//#define kConDef    2           // Console device 1 is SIO port B
//#define kBaud1Def  0x96        // Console device 1 default baud rate
//#define kBaud2Def  0x96        // Console device 2 default baud rate

// ROM Filing System
//#define kROMBanks  1           // Number of software selectable ROM banks
//#define kROMTop    0x3F        // Top of banked ROM (hi byte only)

// Timing
//#define kDelayCnt  306         // Loop count for 1 ms delay at 7.3728 MHz

// Optional ROM filing system information
//#define ROMFS_Monitor_EXE      // Monitor.EXE

// Optional features (comment out or rename unwanted features)
// Excluding any of these may result in bugs as I don't test every option

// Exporting functions:
//#define IncludeAPI             // Application Programming Interface (API)
//#define IncludeFDOS            // Very limited CP/M style FDOS support

// Support functions:
//#define IncludeStrings         // String support (needs utilities)
//#define IncludeUtilities       // Utility functions (needs strings)

// Monitor functions:
//#define IncludeMonitor         // Monitor essentials
//#define IncludeAssembler       // Assembler (needs disassembler)
//#define IncludeBaud            // Baud rate setting
//#define IncludeBreakpoint      // Breakpoint and single stepping
//#define IncludeCommands        // Command Line Interprester (CLI)
//#define IncludeDisassemble     // Disassembler
//#define IncludeHelp            // Extended help text
//#define IncludeHexLoader       // Intel hex loader
//#define IncludeMiniTerm        // Mini terminal support
//#define IncludeTrace           // Trace execution

// Extensions:
//#define IncludeRomFS           // ROM filing system
//#define IncludeScripting       // Simple scripting (needs monitor)
//#define IncludeSelftest        // Self test at reset
