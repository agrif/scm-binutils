# based on stm32-cmake by Konstantin Oblaukhov
# https://github.com/ObKo/stm32-cmake/

if(CMAKE_VERSION VERSION_LESS "3.27")
  message(FATAL_ERROR "This file requires CMake 3.27 or later.")
endif()

get_filename_component(Z80_CMAKE_DIR ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)

function(z80_add_linker_script TARGET VISIBILITY SCRIPT)
  get_filename_component(SCRIPT "${SCRIPT}" ABSOLUTE)
  target_link_options(${TARGET} ${VISIBILITY} "SHELL:-T \"${SCRIPT}\"")

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
    VERBATIM
  )
endfunction()

# if this function doesn't agree with z80_get_alternate,
# change z80_get_alternate and not this
function(z80_get_alternate_gen RESULT TARGET OUTPUT_EXTENSION)
  set(${RESULT} "$<TARGET_FILE_DIR:${TARGET}>/$<TARGET_FILE_BASE_NAME:${TARGET}>${OUTPUT_EXTENSION}")
  return(PROPAGATE ${RESULT})
endfunction()

function(z80_get_alternate RESULT TARGET OUTPUT_EXTENSION)
  get_target_property(TARGET_OUTPUT_NAME ${TARGET} OUTPUT_NAME)
  if(TARGET_OUTPUT_NAME)
    set(OUTPUT_FILE_NAME "${TARGET_OUTPUT_NAME}${OUTPUT_EXTENSION}")
  else()
    set(OUTPUT_FILE_NAME "${TARGET}${OUTPUT_EXTENSION}")
  endif()

  get_target_property(RUNTIME_OUTPUT_DIRECTORY ${TARGET} RUNTIME_OUTPUT_DIRECTORY)
  if(RUNTIME_OUTPUT_DIRECTORY)
    set(${RESULT} "${RUNTIME_OUTPUT_DIRECTORY}/${OUTPUT_FILE_NAME}")
  else()
    set(${RESULT} "${OUTPUT_FILE_NAME}")
  endif()

  return(PROPAGATE ${RESULT})
endfunction()

function(z80_generate_objcopy TARGET OUTPUT_EXTENSION)
  z80_get_alternate(OUTPUT_FILE_PATH ${TARGET} "${OUTPUT_EXTENSION}")
  add_custom_command(
    TARGET ${TARGET}
    POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} ${ARGN} "$<TARGET_FILE:${TARGET}>" ${OUTPUT_FILE_PATH}
    BYPRODUCTS ${OUTPUT_FILE_PATH}
    VERBATIM
  )
endfunction()

function(z80_generate_binary TARGET)
  z80_generate_objcopy(${TARGET} ".bin" -O binary)
endfunction()

function(z80_generate_hex TARGET)
  z80_generate_objcopy(${TARGET} ".hex" -O ihex)
endfunction()

# https://stackoverflow.com/a/66896673
function(_z80_add_preprocessor_command TARGET SOURCE OUTPUT SOURCENAME)
  if(NOT CMAKE_C_COMPILER_LOADED)
    message(FATAL_ERROR "Preprocessing sources requires C language enabled.")
  endif()

  string(TOUPPER "${CMAKE_BUILD_TYPE}" BUILD_TYPE)
  string(REPLACE " " ";" C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_${BUILD_TYPE}}")

  get_source_file_property(SRC_COMPILE_DEFINITIONS "${SOURCE}" COMPILE_DEFINITIONS)
  if(SRC_COMPILE_DEFINITIONS STREQUAL "NOTFOUND")
    set(SRC_COMPILE_DEFINITIONS "")
  endif()
  list(TRANSFORM SRC_COMPILE_DEFINITIONS PREPEND -D)

  get_source_file_property(SRC_INCLUDE_DIRECTORIES "${SOURCE}" INCLUDE_DIRECTORIES)
  if(SRC_INCLUDE_DIRECTORIES STREQUAL "NOTFOUND")
    set(SRC_INCLUDE_DIRECTORIES "")
  endif()
  list(TRANSFORM SRC_INCLUDE_DIRECTORIES PREPEND -I)

  get_source_file_property(SRC_COMPILE_OPTIONS "${SOURCE}" COMPILE_OPTIONS)
  if(SRC_COMPILE_OPTIONS STREQUAL "NOTFOUND")
    set(SRC_COMPILE_OPTIONS "")
  endif()

  add_custom_command(
    COMMAND ${CMAKE_C_COMPILER}

    ${C_FLAGS}
    $<TARGET_PROPERTY:${TARGET},COMPILE_OPTIONS>
    ${SRC_COMPILE_OPTIONS}

    "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>,PREPEND,-D>"
    ${SRC_COMPILE_DEFINITIONS}

    "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>,PREPEND,-I>"
    ${SRC_INCLUDE_DIRECTORIES}

    -MMD -MF "${OUTPUT}.d" -MQ "${OUTPUT}"
    -E "${SOURCE}" -o "${OUTPUT}"

    COMMAND_EXPAND_LISTS
    VERBATIM
    DEPFILE "${OUTPUT}.d"
    DEPENDS "${SOURCE}"
    OUTPUT "${OUTPUT}"
    COMMENT "Preprocessing ${SOURCENAME}"
  )
endfunction()

function(z80_preprocessed_name RESULT TARGET SOURCE)
  get_filename_component(BASE "${SOURCE}" NAME_WLE)
  set(${RESULT} "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}-${BASE}.s")
  return(PROPAGATE ${RESULT})
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

    z80_preprocessed_name(PREPROCESSED ${TARGET} "${SOURCE}")
    set(SOURCEFULL "${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE}")

    _z80_add_preprocessor_command(${TARGET} "${SOURCEFULL}" "${PREPROCESSED}" "${SOURCE}")

    list(REMOVE_AT SOURCES ${I})
    list(INSERT SOURCES ${I} "${PREPROCESSED}")
  endforeach()

  set_property(TARGET ${TARGET} PROPERTY SOURCES "${SOURCES}")
endfunction()

function(z80_executable TARGET)
  z80_preprocess_sources(${TARGET})
  z80_print_size(${TARGET})
  z80_generate_binary(${TARGET})
  z80_generate_hex(${TARGET})
endfunction()

function(z80_library TARGET)
  z80_preprocess_sources(${TARGET})
endfunction()

function(z80_keep_symbols TARGET)
  foreach(SYMBOL IN LISTS ARGN)
    target_link_options(${TARGET} PRIVATE "SHELL:-u ${SYMBOL}")
  endforeach()
endfunction()

function(z80_globalize_symbols TARGET)
  # call out to a seperate file to expand $<TARGET_OBJECTS:..>
  add_custom_command(
    TARGET ${TARGET}
    PRE_LINK
    COMMAND ${CMAKE_COMMAND}
    "-DOBJECTS=$<TARGET_OBJECTS:${TARGET}>"
    "-DCMAKE_OBJCOPY=${CMAKE_OBJCOPY}"
    -P "${Z80_CMAKE_DIR}/z80-common-globalize-symbols.cmake"
    VERBATIM
  )
endfunction()

function(z80_embed_binary TARGET SOURCE DEFINE ALTTARGET)
  z80_embed_alternate(${TARGET} "${SOURCE}" "${DEFINE}" ${ALTTARGET} ".bin")
endfunction()

function(z80_embed_alternate TARGET SOURCE DEFINE ALTTARGET OUTPUT_EXTENSION)
  z80_get_alternate_gen(GENERATED ${ALTTARGET} "${OUTPUT_EXTENSION}")

  # a place in the build directory to store it, purposefully non-unique
  # so that multiple uses can share this rule (might be a bad idea)
  set(LOCAL "${CMAKE_CURRENT_BINARY_DIR}/${DEFINE}.bin")

  # jank: can't use generator expressions inside OBJECT_DEPENDS
  # so lets copy the file over to our build dir and depend on that
  add_custom_command(
    COMMAND ${CMAKE_COMMAND} -E copy "${GENERATED}" "${LOCAL}"
    VERBATIM
    DEPENDS ${ALTTARGET}
    OUTPUT "${LOCAL}"
  )

  # get the preprocessed name of our source
  z80_preprocessed_name(SOURCE_ASM ${TARGET} "${SOURCE}")

  get_source_file_property(OBJECT_DEPENDS "${SOURCE_ASM}" OBJECT_DEPENDS)
  get_source_file_property(COMPILE_DEFINITIONS "${SOURCE}" COMPILE_DEFINITIONS)

  # why do you do this cmake
  if(OBJECT_DEPENDS STREQUAL "NOTFOUND")
    set(OBJECT_DEPENDS "")
  endif()
  if(COMPILE_DEFINITIONS STREQUAL "NOTFOUND")
    set(COMPILE_DEFINITIONS "")
  endif()

  list(APPEND OBJECT_DEPENDS "${LOCAL}")
  list(APPEND COMPILE_DEFINITIONS "${DEFINE}=\"${LOCAL}\"")

  set_source_files_properties(${SOURCE_ASM} PROPERTIES
    OBJECT_DEPENDS "${OBJECT_DEPENDS}"
  )

  set_source_files_properties(${SOURCE} PROPERTIES
    COMPILE_DEFINITIONS "${COMPILE_DEFINITIONS}"
  )
endfunction()
