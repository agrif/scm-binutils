add_library(scm-api STATIC scm-api.S scm-api.h)
target_include_directories(scm-api PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
z80_preprocess_sources(scm-api)
