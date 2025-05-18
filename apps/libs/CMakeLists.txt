add_library(scm-api STATIC scm-api.S scm-api.h)
target_include_directories(scm-api PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
z80_preprocess_sources(scm-api)

add_library(utilities STATIC utilities.S)
target_link_libraries(utilities PRIVATE scm-api)
z80_preprocess_sources(utilities)

add_library(compactflash-generic STATIC compactflash-generic.S compactflash.h)
target_include_directories(compactflash-generic PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(compactflash-generic PRIVATE scm-api)
z80_preprocess_sources(compactflash-generic)
