/* Original source renderer: the unmodified DrumSynth 2.0 drumsynth.c from
 * the repository root, compiled with today's compiler. Comparing it with
 * ref_render shows what the compiler alone changes (VC6 x87 vs. SSE2). */
#include "drumsynth.h"
#include "renderer.h"

const char* RENDERER_NAME = "src_render";

int renderer_init(const char* option)
{
    (void)option;
    return 0;
}

int render_one(const char* dsfile, const char* wavfile)
{
    return ds2wav((char*)dsfile, (char*)wavfile, NULL);
}
