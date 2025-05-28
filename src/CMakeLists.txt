# common
list(APPEND SCM_SOURCES
  # core
  alpha.S console.S idle.S ports.s
  # exports
  api.S fdos.S
  # support
  strings.S utilities.S
  # monitor
  monitor.S assembler.S breakpoint.S commands.S
  disassembler.S disassembler-data.S hexloader.S script.S
  # extensions
  romfs.S
)

# RC2014
list(APPEND RC2014_SOURCES
  hardware/rc2014/serial-6850.S
  hardware/rc2014/serial-sio2.S
  hardware/rc2014/manager.S
)

function(scm_target TARGET BUILD_DEF)
  add_executable(${TARGET} ${SCM_SOURCES} ${ARGN})
  target_compile_definitions(${TARGET} PRIVATE ${BUILD_DEF})
  target_include_directories(${TARGET} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
  z80_add_linker_script(${TARGET} PRIVATE link.x)
  z80_globalize_symbols(${TARGET})
  z80_executable(${TARGET})
endfunction()

# R1: RC2014 08K ROM 32K RAM standard
scm_target(scmonitor-r1 BUILD_R1 ${RC2014_SOURCES}
  hardware/rc2014/rom-info-r1-bank1.S)

# R2: RC2014 16K ROM 48K RAM standard
z80_embed_binary(scmonitor-r2 hardware/rc2014/rom-info-r2-bank1.S
  MSBASIC_2000_4000_BIN msbasic-2000-4000)
scm_target(scmonitor-r2 BUILD_R2 ${RC2014_SOURCES}
  hardware/rc2014/rom-info-r2-bank1.S)

# R3: RC2014 32K ROM 32/64K RAM paged
z80_embed_binary(scmonitor-r3 hardware/rc2014/rom-info-r3-bank1.S
  MSBASIC_2000_8000_BIN msbasic-2000-8000)
z80_embed_binary(scmonitor-r3 hardware/rc2014/rom-info-r3-bank1.S
  CPM_LOADER_BIN cpm-loader)
scm_target(scmonitor-r3 BUILD_R3 ${RC2014_SOURCES}
  hardware/rc2014/rom-info-r3-bank1.S)
