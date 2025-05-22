add_executable(msbasic-searle msbasic.S)
target_link_options(msbasic-searle PRIVATE -Ttext=0x0150 -Tdata=0x2045 -e COLD)
z80_executable(msbasic-searle)

add_executable(msbasic-2000-4000 msbasic.S)
target_link_options(msbasic-2000-4000 PRIVATE -Ttext=0x2000 -Tdata=0x4000 -e COLD)
z80_executable(msbasic-2000-4000)

add_executable(msbasic-2000-8000 msbasic.S)
target_link_options(msbasic-2000-8000 PRIVATE -Ttext=0x2000 -Tdata=0x8000 -e COLD)
z80_executable(msbasic-2000-8000)

add_executable(msbasic-8000-a000 msbasic.S)
target_link_options(msbasic-8000-a000 PRIVATE -Ttext=0x8000 -Tdata=0xa000 -e COLD)
z80_executable(msbasic-8000-a000)
