add_library(alphanumeric-lcd STATIC alphanumeric-lcd.S)
target_include_directories(alphanumeric-lcd PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(alphanumeric-lcd PRIVATE scm-api)
z80_library(alphanumeric-lcd)

add_library(compactflash STATIC compactflash.S compactflash.h)
target_include_directories(compactflash PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(compactflash PRIVATE scm-api)
z80_library(compactflash)

add_library(compactflash-z280rc STATIC compactflash-z280rc.S compactflash.h)
target_include_directories(compactflash-z280rc PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_compile_definitions(compactflash-z280rc PUBLIC COMPACTFLASH_Z280RC)
target_link_libraries(compactflash-z280rc PRIVATE scm-api)
z80_library(compactflash-z280rc)

add_library(scm-api STATIC scm-api.S scm-api.h)
target_include_directories(scm-api PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
z80_library(scm-api)

add_library(utilities STATIC utilities.S)
target_link_libraries(utilities PRIVATE scm-api)
z80_library(utilities)
