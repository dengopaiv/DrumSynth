/* C17 rewrite renderer: engine/ (ds_render_file).
 *
 * --dll winapi makes it read presets with the Windows profile functions,
 * like the original, instead of the engine's own parser (engine/src/ds_ini.c);
 * the two must give identical renders. */
#include <stdio.h>
#include <string.h>
#include "drumsynth.h"
#include "renderer.h"

const char* RENDERER_NAME = "c17_render";
static int use_winapi = 0;

int renderer_init(const char* option)
{
    use_winapi = option && strcmp(option, "winapi") == 0;
    return 0;
}

/* Prints the engine's notes (DS_NOTE_*, drumsynth.h) on stderr: inputs where
 * the original would hang, crash or read garbage. */
int render_one(const char* dsfile, const char* wavfile)
{
    ds_ini* ini = NULL;
    ds_source src;
    if (use_winapi) {
        src = ds_source_winapi(dsfile);
    } else {
        ini = ds_ini_load(dsfile);
        if (!ini) ini = ds_ini_parse("", 0);
        if (!ini) return DS_ERR_OUTPUT;
        src = ds_ini_source(ini);
    }
    ds_sound sound;
    int r = ds_render(&src, NULL, &sound);
    ds_ini_free(ini);
    if (r != DS_OK) return r;
    if (sound.notes) fprintf(stderr, "notes %X\t%s\n", sound.notes, dsfile);
    r = ds_write_wav(wavfile, &sound);
    ds_sound_free(&sound);
    return r;
}
