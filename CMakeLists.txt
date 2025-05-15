cmake_minimum_required(VERSION 3.16)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/z80-unknown-elf.cmake)

project(scc LANGUAGES ASM)

add_subdirectory(apps)
