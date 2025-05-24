# this is in a seperate file so we can expand $<TARGET_OBJECTS:..>
foreach(OBJECT IN LISTS OBJECTS)
  execute_process(COMMAND "${CMAKE_OBJCOPY}" -w --globalize-symbol !.* --globalize-symbol * "${OBJECT}")
endforeach()
