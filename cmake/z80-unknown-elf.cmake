# based on stm32-cmake by Konstantin Oblaukhov
# https://github.com/ObKo/stm32-cmake/

if(CMAKE_VERSION VERSION_LESS "3.27")
  message(FATAL_ERROR "This file requires CMake 3.27 or later.")
endif()

get_filename_component(Z80_CMAKE_DIR ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)
list(APPEND CMAKE_MODULE_PATH ${Z80_CMAKE_DIR})
include(z80-common)

# system info
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR z80)

# GNU-flavored assembler
include(Platform/gas)

# use static libraries, not executables
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# use .elf executables
set(CMAKE_EXECUTABLE_SUFFIX .elf)
set(CMAKE_EXECUTABLE_SUFFIX_C .elf)
set(CMAKE_EXECUTABLE_SUFFIX_CXX .elf)
set(CMAKE_EXECUTABLE_SUFFIX_ASM .elf)

# only use our root
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# we don't care about mixed permission segments
add_link_options(--no-warn-rwx-segments)

# set a target triple
if(NOT Z80_TARGET_TRIPLET)
  if(DEFINED ENV{Z80_TARGET_TRIPLET})
    message(STATUS "Detected target triplet Z80_TARGET_TRIPLET in environment: $ENV{Z80_TARGET_TRIPLET}")
    set(Z80_TARGET_TRIPLET $ENV{Z80_TARGET_TRIPLET})
  else()
    set(Z80_TARGET_TRIPLET "z80-unknown-elf")
    message(STATUS "Target triplet Z80_TARGET_TRIPLET defaulting to ${Z80_TARGET_TRIPLET}")
  endif()
endif()

# discover the toolchain path
if(NOT Z80_TOOLCHAIN_PATH)
  if(DEFINED ENV{Z80_TOOLCHAIN_PATH})
    message(STATUS "Detected toolchain path Z80_TOOLCHAIN_PATH in environment: $ENV{Z80_TOOLCHAIN_PATH}")
    set(Z80_TOOLCHAIN_PATH $ENV{Z80_TOOLCHAIN_PATH})
  else()
    if(NOT CMAKE_ASM_COMPILER)
      # no toolchain path is set, we must look on $PATH
      # and this *must work*, it's the only option left
      find_program(CMAKE_ASM_COMPILER NAMES ${Z80_TARGET_TRIPLET}-as REQUIRED)
    endif()
    # if assembler is /something/bin/as, we want /something
    get_filename_component(Z80_TOOLCHAIN_PATH ${CMAKE_ASM_COMPILER} DIRECTORY)
    get_filename_component(Z80_TOOLCHAIN_PATH ${Z80_TOOLCHAIN_PATH} DIRECTORY)
    message(STATUS "Discovered toolchain path Z80_TOOLCHAIN_PATH from CMAKE_ASM_COMPILER: ${Z80_TOOLCHAIN_PATH}")
  endif()
  file(TO_CMAKE_PATH "${Z80_TOOLCHAIN_PATH}" Z80_TOOLCHAIN_PATH)
endif()

# handy path aliases
set(TOOLCHAIN_SYSROOT "${Z80_TOOLCHAIN_PATH}/${Z80_TARGET_TRIPLET}")
set(TOOLCHAIN_BIN_PATH "${Z80_TOOLCHAIN_PATH}/bin")
set(TOOLCHAIN_INC_PATH "${Z80_TOOLCHAIN_PATH}/${Z80_TARGET_TRIPLET}/include")
set(TOOLCHAIN_LIB_PATH "${Z80_TOOLCHAIN_PATH}/${Z80_TARGET_TRIPLET}/lib")

# find all the programs we want
find_program(CMAKE_AR
  NAMES ${Z80_TARGET_TRIPLET}-ar
  HINTS ${TOOLCHAIN_BIN_PATH}
  REQUIRED
)
find_program(CMAKE_ASM_COMPILER
  NAMES ${Z80_TARGET_TRIPLET}-as
  HINTS ${TOOLCHAIN_BIN_PATH}
  REQUIRED
)
find_program(CMAKE_LINKER
  NAMES ${Z80_TARGET_TRIPLET}-ld
  HINTS ${TOOLCHAIN_BIN_PATH}
  REQUIRED
)
find_program(CMAKE_OBJCOPY
  NAMES ${Z80_TARGET_TRIPLET}-objcopy
  HINTS ${TOOLCHAIN_BIN_PATH}
  REQUIRED
)
find_program(CMAKE_OBJDUMP
  NAMES ${Z80_TARGET_TRIPLET}-objdump
  HINTS ${TOOLCHAIN_BIN_PATH}
  REQUIRED
)
find_program(CMAKE_RANLIB
  NAMES ${Z80_TARGET_TRIPLET}-ranlib
  HINTS ${TOOLCHAIN_BIN_PATH}
  REQUIRED
)
find_program(CMAKE_SIZE
  NAMES ${Z80_TARGET_TRIPLET}-size
  HINTS ${TOOLCHAIN_BIN_PATH}
  REQUIRED
)
