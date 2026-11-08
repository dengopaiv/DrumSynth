/* Reference renderer: the original 32-bit ds2wav.dll from DrumSynth 2.0
 * (bin/ds2wav.dll), loaded at run time and called the way the VB6 GUI
 * calls it. Must be built as 32-bit. */
#include <stdio.h>
#include <windows.h>
#include "renderer.h"

typedef int (WINAPI* ds2wav_fn)(char* dsfile, char* wavfile, HWND hWnd);

const char* RENDERER_NAME = "ref_render";
static ds2wav_fn ds2wav_ptr;

int renderer_init(const char* dll)
{
    HMODULE module;
    if (!dll) {
        fprintf(stderr, "ref_render: --dll PATH to the original ds2wav.dll is required\n");
        return 1;
    }
    module = LoadLibraryA(dll);
    if (!module) {
        fprintf(stderr, "ref_render: cannot load %s (error %lu)\n", dll, GetLastError());
        return 1;
    }
    ds2wav_ptr = (ds2wav_fn)GetProcAddress(module, "ds2wav");
    if (!ds2wav_ptr) {
        fprintf(stderr, "ref_render: %s has no ds2wav export\n", dll);
        return 1;
    }
    return 0;
}

int render_one(const char* dsfile, const char* wavfile)
{
    return ds2wav_ptr((char*)dsfile, (char*)wavfile, NULL);
}
