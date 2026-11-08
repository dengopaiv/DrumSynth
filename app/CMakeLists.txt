# DrumSynth: the accessible wxWidgets GUI on the C17 engine. Windows, 64-bit.
#
#   cmake -S app -B build/app -A x64 -DCMAKE_TOOLCHAIN_FILE=%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake
#   cmake --build build/app --config Release
#
# Needs wxWidgets 3.3 (vcpkg: wxwidgets:x64-windows). vcpkg copies its DLLs
# next to the program. See app/README.md.
cmake_minimum_required(VERSION 3.20)
project(DrumSynthApp VERSION 4.0.0 LANGUAGES C CXX ASM_MASM)

find_package(wxWidgets CONFIG REQUIRED)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../engine ${CMAKE_BINARY_DIR}/engine)

add_executable(DrumSynth WIN32
    src/app.cpp
    src/main_frame.cpp
    src/preset.cpp
    src/envelope_editor.cpp
    src/access.cpp
    src/vbtext.cpp
    src/app.rc)
set_property(TARGET DrumSynth PROPERTY CXX_STANDARD 17)
set_property(TARGET DrumSynth PROPERTY CXX_STANDARD_REQUIRED ON)
target_compile_definitions(DrumSynth PRIVATE _CRT_SECURE_NO_WARNINGS UNICODE _UNICODE
    DS_VERSION_STRING="${PROJECT_VERSION}"
    DS_VERSION_MAJOR=${PROJECT_VERSION_MAJOR} DS_VERSION_MINOR=${PROJECT_VERSION_MINOR}
    DS_VERSION_PATCH=${PROJECT_VERSION_PATCH})
target_compile_options(DrumSynth PRIVATE /W3 /utf-8)
target_link_libraries(DrumSynth PRIVATE drumsynth_engine wx::core wx::base winmm uiautomationcore)

# Test: load and re-save every preset as the GUI does (app/tests/README).
add_executable(preset_roundtrip tests/preset_roundtrip.cpp src/preset.cpp src/vbtext.cpp)
target_include_directories(preset_roundtrip PRIVATE src)
set_property(TARGET preset_roundtrip PROPERTY CXX_STANDARD 17)
target_compile_definitions(preset_roundtrip PRIVATE _CRT_SECURE_NO_WARNINGS)
target_link_libraries(preset_roundtrip PRIVATE drumsynth_engine)

# The help text goes next to the program.
add_custom_command(TARGET DrumSynth POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/../docs/gui-help.md $<TARGET_FILE_DIR:DrumSynth>/gui-help.md)

# Test: what MSAA reports for every control of the running GUI.
add_executable(msaa_dump tests/msaa_dump.cpp)
target_compile_definitions(msaa_dump PRIVATE UNICODE _UNICODE)
target_link_libraries(msaa_dump PRIVATE oleacc ole32 oleaut32)

# Optional: Tolk and NVDA's controller client next to the program, so
# announcements reach NVDA, JAWS and others directly (app/README.md).
set(TOLK_DIR "C:/GIT/environment/tolk" CACHE PATH "Folder with src/Tolk.dll and libs/x64")
if(EXISTS "${TOLK_DIR}/src/Tolk.dll")
    add_custom_command(TARGET DrumSynth POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${TOLK_DIR}/src/Tolk.dll" $<TARGET_FILE_DIR:DrumSynth>
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${TOLK_DIR}/libs/x64" $<TARGET_FILE_DIR:DrumSynth>)
endif()

# Test: what UI Automation (Narrator's interface) reports for the running GUI.
add_executable(uia_dump tests/uia_dump.cpp)
target_compile_definitions(uia_dump PRIVATE UNICODE _UNICODE)
target_link_libraries(uia_dump PRIVATE ole32 oleaut32 uiautomationcore)
