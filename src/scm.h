// **********************************************************************
// **  Small Computer Monitor (SCMonitor)        by Stephen C Cousins  **
// **                                                                  **
// **  Developed with Small Computer Workshop (IDE)     www.scc.me.uk  **
// **********************************************************************
// converted to GNU binutils by agrif

// Source code version number: Major.Minor.Revision (.Touch)
// This is the version number of the core code and does not include
// the hardware drivers.
// This version number is only changed when the source code no longer
// produces the same binary code for all existing builds.
// Cosmetic changes to the source and changes only affecting new
// hardware do not require the version number to change, only the
// 'Touch' date (which is an invisible part of the version number).
// Hardware drivers have their own configuration code and revision
// numbers: kConfMajor, kConfMinor and kConfRevis
#define kVersMajor 1
#define kVersMinor 0
#define kVersRevis 0
//#define kVersTouch 20181027 // Last date core code touched

// **********************************************************************
// **  Include configuration file                                      **
// **********************************************************************

#include "config.h"

// set kHardID based on hardware defined in config.h

#if defined(Custom)
#define kHardID 0
#elif defined(Simulated_Z80)
#define kHardID 1
#elif defined(SCDevKit01_Z80)
#define kHardID 2
#elif defined(RC2014_Z80)
#define kHardID 3
#elif defined(SC101_Z80)
#define kHardID 4
#elif defined(LiNC80_Z80)
#define kHardID 5
#elif defined(TomsSBC_Z80)
#define kHardID 6
#elif defined(Z280RC_Z280)
#define kHardID 7
#elif defined(SC114_Z80)
#define kHardID 8
#elif defined(Z80SBCRC_Z80)
#define kHardID 9
#else
#error "no hardware define found, kHardID left undefined"
#endif

//     **************************************************************
//     **                     Copyright notice                     **
//     **                                                          **
//     **  This software is very nearly 100% my own work so I am   **
//     **  entitled to  claim copyright and to grant licences to   **
//     **  others.                                                 **
//     **                                                          **
//     **  You are free to use this software for non-commercial    **
//     **  purposes provided it retains this copyright notice and  **
//     **  is clearly credited to me where appropriate.            **
//     **                                                          **
//     **  You are free to modify this software as you see fit     **
//     **  for your own use. You may also distribute derived       **
//     **  works provided they remain free of charge, are          **
//     **  appropriately credited and grant the same freedoms.     **
//     **                                                          **
//     **                    Stephen C Cousins                     **
//     **************************************************************
//
// Thanks to all those who have contributed to this software,
// particularly:
//
// Jon Langseth for all the input, testing and encouragement during
// the conversion and extension for the LiNC80 SBC1.
//
// Bill Shen for porting to his Z280RC system.
//
