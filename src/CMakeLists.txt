# core
list(APPEND SCM_SOURCES alpha.S console.S idle.S ports.s)

# exports
list(APPEND SCM_SOURCES api.S fdos.S)

# support
list(APPEND SCM_SOURCES strings.S utilities.S)

# monitor
list(APPEND SCM_SOURCES monitor.S assembler.S breakpoint.S commands.S)

# optionally
# monitor: monitor.S assembler.S breakpoint.S commands.S disassembler.S hexloader.S script.S
# extensions: trace.S romfs.S

# hardware !Manager.s (see !Main.asm)
# rom filing system

add_executable(scmonitor-r1 ${SCM_SOURCES})
target_compile_definitions(scmonitor-r1 PRIVATE BUILD_R1)
target_include_directories(scmonitor-r1 PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
z80_add_linker_script(scmonitor-r1 PRIVATE link.x)
z80_globalize_symbols(scmonitor-r1)
z80_executable(scmonitor-r1)
