/* Modern engine renderer: src/DrumSynth.Core/drumsynth.c via ds_to_wav. */
#include "drumsynth.h"
#include "renderer.h"

const char* RENDERER_NAME = "new_render";

int renderer_init(const char* option)
{
    (void)option;
    return 0;
}

int render_one(const char* dsfile, const char* wavfile)
{
    return ds_to_wav(dsfile, wavfile);
}
