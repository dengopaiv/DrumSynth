# The DrumSynth 2.0 engine rewritten in C17, 64-bit Windows (MSVC + ml64).
#
#   cmake -S engine -B build/engine -A x64
#   cmake --build build/engine --config Release
#
# Used as a subdirectory by tools/renderers (c17_render) and tools/probes.
cmake_minimum_required(VERSION 3.20)
project(DrumSynthEngine LANGUAGES C ASM_MASM)

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "The DrumSynth engine is 64-bit only (x87 routines are ml64 assembly).")
endif()

add_library(drumsynth_engine STATIC
    src/ds_engine.c
    src/ds_ini.c
    src/ds_source_win.c
    src/ds_vc6.c
    src/ds_vc6_fltin.c
    src/ds_wav.c
    x87/ds_x87.asm)
target_include_directories(drumsynth_engine PUBLIC include PRIVATE src)
set_property(TARGET drumsynth_engine PROPERTY C_STANDARD 17)
set_property(TARGET drumsynth_engine PROPERTY C_STANDARD_REQUIRED ON)
target_compile_definitions(drumsynth_engine PRIVATE _CRT_SECURE_NO_WARNINGS)
# /fp:precise is MSVC's default and keeps every double operation as written:
# no contraction into fused multiply-adds, no reassociation. The engine
# depends on that, so it is stated explicitly.
target_compile_options(drumsynth_engine PRIVATE
    $<$<COMPILE_LANGUAGE:C>:/fp:precise /W4 /wd4244 /wd4305>)
target_link_libraries(drumsynth_engine PUBLIC kernel32)

# Diagnostic variant: the C library instead of the x87 sequences and VC6's
# pow, fmod and text-to-float conversion (see ds_x87.h, DS_ABLATE_LIBM).
add_library(drumsynth_engine_libm STATIC
    src/ds_engine.c src/ds_ini.c src/ds_source_win.c src/ds_vc6.c src/ds_vc6_fltin.c src/ds_wav.c
    x87/ds_x87.asm)
target_include_directories(drumsynth_engine_libm PUBLIC include PRIVATE src)
set_property(TARGET drumsynth_engine_libm PROPERTY C_STANDARD 17)
target_compile_definitions(drumsynth_engine_libm PRIVATE _CRT_SECURE_NO_WARNINGS DS_ABLATE_LIBM)
target_compile_options(drumsynth_engine_libm PRIVATE $<$<COMPILE_LANGUAGE:C>:/fp:precise /wd4244 /wd4305>)
