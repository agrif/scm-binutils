add_library(scm-api STATIC scm-api.S scm-api.h)
target_include_directories(scm-api PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
z80_preprocess_sources(scm-api)

add_library(utilities STATIC utilities.S)
target_link_libraries(utilities PRIVATE scm-api)
z80_preprocess_sources(utilities)

add_library(compactflash STATIC compactflash.S compactflash.h)
target_include_directories(compactflash PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(compactflash PRIVATE scm-api)
z80_preprocess_sources(compactflash)

add_library(compactflash-z280rc STATIC compactflash-z280rc.S compactflash.h)
target_include_directories(compactflash-z280rc PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_compile_definitions(compactflash-z280rc PUBLIC COMPACTFLASH_Z280RC)
target_link_libraries(compactflash-z280rc PRIVATE scm-api)
z80_preprocess_sources(compactflash-z280rc)
