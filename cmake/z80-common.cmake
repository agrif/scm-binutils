# based on stm32-cmake by Konstantin Oblaukhov
# https://github.com/ObKo/stm32-cmake/

if(CMAKE_VERSION VERSION_LESS "3.27")
  message(FATAL_ERROR "This file requires CMake 3.27 or later.")
endif()

function(z80_add_linker_script TARGET VISIBILITY SCRIPT)
  get_filename_component(SCRIPT "${SCRIPT}" ABSOLUTE)
  target_link_options(${TARGET} ${VISIBILITY} -T "${SCRIPT}")

  get_target_property(TARGET_TYPE ${TARGET} TYPE)
  if(TARGET_TYPE STREQUAL "INTERFACE_LIBRARY")
    set(INTERFACE_PREFIX "INTERFACE_")
  endif()

  get_target_property(LINK_DEPENDS ${TARGET} ${INTERFACE_PREFIX}LINK_DEPENDS)
  if(LINK_DEPENDS)
    list(APPEND LINK_DEPENDS "${SCRIPT}")
  else()
    set(LINK_DEPENDS "${SCRIPT}")
  endif()

  set_target_properties(${TARGET} PROPERTIES ${INTERFACE_PREFIX}LINK_DEPENDS "${LINK_DEPENDS}")
endfunction()

function(z80_print_size TARGET)
  add_custom_command(
    TARGET ${TARGET}
    POST_BUILD
    COMMAND ${CMAKE_SIZE} "$<TARGET_FILE:${TARGET}>"
    COMMENT "Target ${TARGET} size: "
  )
endfunction()

function(_z80_generate_objcopy TARGET OUTPUT_EXTENSION OBJCOPY_BFD_OUTPUT)
  get_target_property(TARGET_OUTPUT_NAME ${TARGET} OUTPUT_NAME)
  if(TARGET_OUTPUT_NAME)
    set(OUTPUT_FILE_NAME "${TARGET_OUTPUT_NAME}.${OUTPUT_EXTENSION}")
  else()
    set(OUTPUT_FILE_NAME "${TARGET}.${OUTPUT_EXTENSION}")
  endif()

  get_target_property(RUNTIME_OUTPUT_DIRECTORY ${TARGET} RUNTIME_OUTPUT_DIRECTORY)
  if(RUNTIME_OUTPUT_DIRECTORY)
    set(OUTPUT_FILE_PATH "${RUNTIME_OUTPUT_DIRECTORY}/${OUTPUT_FILE_NAME}")
  else()
    set(OUTPUT_FILE_PATH "${OUTPUT_FILE_NAME}")
  endif()

  add_custom_command(
    TARGET ${TARGET}
    POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O ${OBJCOPY_BFD_OUTPUT} "$<TARGET_FILE:${TARGET}>" ${OUTPUT_FILE_PATH}
    BYPRODUCTS ${OUTPUT_FILE_PATH}
    COMMENT "Generating ${OUTPUT_FILE_NAME}"
  )
endfunction()

function(z80_generate_binary TARGET)
  _z80_generate_objcopy(${TARGET} "bin" "binary")
endfunction()

function(z80_generate_hex TARGET)
  _z80_generate_objcopy(${TARGET} "hex" "ihex")
endfunction()

# https://stackoverflow.com/a/66896673
function(_z80_add_preprocessor_command TARGET SOURCE OUTPUT SOURCENAME)
  if(NOT CMAKE_C_COMPILER_LOADED)
    message(FATAL_ERROR "Preprocessing sources requires C language enabled.")
  endif()

  string(TOUPPER "${CMAKE_BUILD_TYPE}" BUILD_TYPE)
  string(REPLACE " " ";" C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_${BUILD_TYPE}}")

  add_custom_command(
    COMMAND ${CMAKE_C_COMPILER}
    "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>,PREPEND,-D>"
    "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>,PREPEND,-I>"
    ${C_FLAGS}
    $<TARGET_PROPERTY:${TARGET},COMPILE_OPTIONS>
    -E ${SOURCE} -o ${OUTPUT}

    COMMAND_EXPAND_LISTS
    VERBATIM
    IMPLICIT_DEPENDS C ${SOURCE}
    DEPENDS ${SOURCE}
    OUTPUT ${OUTPUT}
    COMMENT "Preprocessing ${SOURCENAME}"
  )
endfunction()

function(z80_preprocess_sources TARGET)
  get_property(SOURCES TARGET ${TARGET} PROPERTY SOURCES)

  list(LENGTH SOURCES SOURCES_LENGTH)
  math(EXPR SOURCES_LENGTH "${SOURCES_LENGTH} - 1")
  foreach(I RANGE ${SOURCES_LENGTH})
    list(GET SOURCES ${I} SOURCE)
    get_filename_component(EXT "${SOURCE}" LAST_EXT)
    if(NOT "${EXT}" STREQUAL ".S")
      continue()
    endif()

    get_filename_component(BASE "${SOURCE}" NAME_WLE)
    set(PREPROCESSED "${CMAKE_CURRENT_BINARY_DIR}/${BASE}.s")
    set(SOURCEFULL "${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE}")

    _z80_add_preprocessor_command(${TARGET} "${SOURCEFULL}" "${PREPROCESSED}" "${SOURCE}")

    list(REMOVE_AT SOURCES ${I})
    list(INSERT SOURCES ${I} "${PREPROCESSED}")
  endforeach()

  set_property(TARGET ${TARGET} PROPERTY SOURCES "${SOURCES}")
endfunction()
