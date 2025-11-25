cmake_minimum_required(VERSION 3.20)
project(DrumSynthCore VERSION 3.0.0 LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Build as shared library (DLL on Windows)
add_library(ds2wav SHARED
    drumsynth.c
    drumsynth.h
)

# Export symbols on Windows
if(WIN32)
    target_compile_definitions(ds2wav PRIVATE DS_EXPORTS)
    set_target_properties(ds2wav PROPERTIES
        PREFIX ""
        WINDOWS_EXPORT_ALL_SYMBOLS OFF
    )
endif()

# Math library on Unix
if(UNIX)
    target_link_libraries(ds2wav PRIVATE m)
endif()

# Install rules
install(TARGETS ds2wav
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
)
install(FILES drumsynth.h DESTINATION include)
