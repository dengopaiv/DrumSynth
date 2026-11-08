# Probe programs comparing the original DLL's internal routines with the
# C17 engine's (see README.md in this folder).
#
#   cmake -S tools/probes -B build/probes-x86 -A Win32   -> probe32, ini_probe32
#   cmake -S tools/probes -B build/probes-x64 -A x64     -> probe64, ini_probe
cmake_minimum_required(VERSION 3.20)
project(DrumSynthProbes LANGUAGES C)
set(REPO_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../..)
add_compile_definitions(_CRT_SECURE_NO_WARNINGS)

if(CMAKE_SIZEOF_VOID_P EQUAL 4)
    add_executable(probe32 probe32.c)
    # The parser is plain C: build it 32-bit too, to compare it with the
    # 32-bit Windows profile functions the original DLL calls (WOW64).
    add_executable(ini_probe32 ini_probe.c ${REPO_ROOT}/engine/src/ds_ini.c)
    target_include_directories(ini_probe32 PRIVATE ${REPO_ROOT}/engine/include)
else()
    enable_language(ASM_MASM)
    add_subdirectory(${REPO_ROOT}/engine ${CMAKE_BINARY_DIR}/engine)
    add_executable(probe64 probe64.c)
    target_link_libraries(probe64 PRIVATE drumsynth_engine)
    target_include_directories(probe64 PRIVATE ${REPO_ROOT}/engine/src)
    add_executable(ini_probe ini_probe.c)
    target_link_libraries(ini_probe PRIVATE drumsynth_engine)
endif()
