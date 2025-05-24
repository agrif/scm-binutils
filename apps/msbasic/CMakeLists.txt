list(APPEND MSBASIC_SOURCES msbasic.S)

add_executable(msbasic-searle ${MSBASIC_SOURCES})
z80_add_linker_script(msbasic-searle PRIVATE link.x)
target_link_options(msbasic-searle PRIVATE --defsym=kORG=0x0150 --defsym=kWRKSPC=0x2045)
z80_executable(msbasic-searle)

add_executable(msbasic-2000-4000 ${MSBASIC_SOURCES})
z80_add_linker_script(msbasic-2000-4000 PRIVATE link.x)
target_link_options(msbasic-2000-4000 PRIVATE --defsym=kORG=0x2000 --defsym=kWRKSPC=0x4000)
z80_executable(msbasic-2000-4000)

add_executable(msbasic-2000-8000 ${MSBASIC_SOURCES})
z80_add_linker_script(msbasic-2000-8000 PRIVATE link.x)
target_link_options(msbasic-2000-8000 PRIVATE --defsym=kORG=0x2000 --defsym=kWRKSPC=0x8000)
z80_executable(msbasic-2000-8000)

add_executable(msbasic-8000-a000 ${MSBASIC_SOURCES})
z80_add_linker_script(msbasic-8000-a000 PRIVATE link.x)
target_link_options(msbasic-8000-a000 PRIVATE --defsym=kORG=0x8000 --defsym=kWRKSPC=0xa000)
z80_executable(msbasic-8000-a000)
