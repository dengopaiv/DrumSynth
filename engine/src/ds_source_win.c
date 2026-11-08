/* ds_source_win.c - a ds_source that calls the Windows profile functions,
 * exactly as the original ds2wav.dll does. Used as the reference for the
 * in-memory parser (ds_ini.c) and selectable in the c17 renderer. */
#include "drumsynth.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

static unsigned win_get_string(void* ctx, const char* s, const char* k, const char* d, char* o, unsigned n)
{
    return GetPrivateProfileStringA(s, k, d, o, n, (const char*)ctx);
}

static unsigned win_get_int(void* ctx, const char* s, const char* k, int d)
{
    return GetPrivateProfileIntA(s, k, d, (const char*)ctx);
}

ds_source ds_source_winapi(const char* path)
{
    ds_source src = { win_get_string, win_get_int, (void*)path };
    return src;
}
