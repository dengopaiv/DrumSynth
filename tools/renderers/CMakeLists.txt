# Renderers for comparing DrumSynth engines. Windows only.
#
#   cmake -S tools/renderers -B build/renderers-x86 -A Win32
#   cmake --build build/renderers-x86 --config Release   -> ref_render, src_render, new_render
#   cmake -S tools/renderers -B build/renderers-x64 -A x64
#   cmake --build build/renderers-x64 --config Release   -> new_render
cmake_minimum_required(VERSION 3.20)
project(DrumSynthRenderers LANGUAGES C)

set(REPO_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../..)
add_compile_definitions(_CRT_SECURE_NO_WARNINGS)

if(CMAKE_SIZEOF_VOID_P EQUAL 4)
    # The original 32-bit DLL can only be loaded by a 32-bit process.
    add_executable(ref_render renderer_main.c ref_render.c)

    # The original source, unmodified.
    add_executable(src_render renderer_main.c src_render.c ${REPO_ROOT}/drumsynth.c)
    target_include_directories(src_render PRIVATE ${REPO_ROOT})
    # getEnv() in the original writes one byte past its buffer (en[256]=0 in
    # char en[256]). The /GS stack check would abort on that, so it is off
    # here rather than changing the original code.
    target_compile_options(src_render PRIVATE /GS-)
endif()

add_executable(new_render renderer_main.c new_render.c
    ${REPO_ROOT}/src/DrumSynth.Core/drumsynth.c)
target_include_directories(new_render PRIVATE ${REPO_ROOT}/src/DrumSynth.Core)
# Link the engine statically; DS_EXPORTS only makes DS_API a dllexport.
target_compile_definitions(new_render PRIVATE DS_EXPORTS)
