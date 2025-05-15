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
