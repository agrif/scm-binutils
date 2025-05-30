cmake_minimum_required(VERSION 3.27)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/z80-unknown-elf.cmake)

project(scc LANGUAGES ASM C)

# always want debug symbols
set(CMAKE_ASM_FLAGS -g)

add_subdirectory(apps)
add_subdirectory(cpm-apps)
add_subdirectory(src)
