/* drumsynth.h - the DrumSynth 2.0 engine, rewritten in C17 (64-bit Windows).
 *
 * The goal of this engine is to give exactly the same output as the original
 * engine, bin/ds2wav.dll from DrumSynth 2.0 (Paul Kellett, 2000), sample for
 * sample and byte for byte, under the reference conditions described in
 * docs/findings.md ("What the rewrite has to do"):
 *   - the DLL at the Windows default x87 precision (53 bits),
 *   - every preset rendered as the first sound after the program starts,
 *   - with the stack cleared, so its uninitialized variables read as 0.
 * How it does that is in docs/rewrite-plan.md and docs/disasm/README.md.
 *
 * The engine keeps no global state: every render starts from the same
 * state, and renders can run in parallel. */
#ifndef DRUMSYNTH_H
#define DRUMSYNTH_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Result codes, the same as the original ds2wav(). */
enum {
    DS_OK = 0,
    DS_ERR_VERSION = 1,   /* [General] Version is "DrumSynth" but not v1.x or v2.x */
    DS_ERR_INPUT = 2,     /* not a DrumSynth file (or the file cannot be read) */
    DS_ERR_OUTPUT = 3     /* the WAV cannot be written, or out of memory */
};

/* ---- Reading presets ------------------------------------------------------
 * The original reads .ds files with the Windows functions
 * GetPrivateProfileStringA and GetPrivateProfileIntA. A ds_source supplies
 * those two functions to the engine. Two sources are provided:
 *   - ds_ini: the file's text in memory, parsed the way Windows parses it
 *     (checked against Windows, see tools/probes/);
 *   - the Windows functions themselves, reading a file (ds_source_winapi).
 */
typedef struct ds_source {
    /* As GetPrivateProfileStringA: copies the value (or def) into out,
     * at most size - 1 characters, and returns the number copied. */
    unsigned (*get_string)(void* ctx, const char* section, const char* key,
                           const char* def, char* out, unsigned size);
    /* As GetPrivateProfileIntA. */
    unsigned (*get_int)(void* ctx, const char* section, const char* key, int def);
    void* ctx;
} ds_source;

typedef struct ds_ini ds_ini;

/* Parse .ds text (any bytes; the original reads files in the ANSI code
 * page). Returns NULL only when out of memory. */
ds_ini* ds_ini_parse(const char* text, size_t length);
/* Read and parse a file. Returns NULL if the file cannot be read. */
ds_ini* ds_ini_load(const char* path);
void ds_ini_free(ds_ini* ini);
/* A ds_source reading from ini (valid while ini is). */
ds_source ds_ini_source(const ds_ini* ini);
unsigned ds_ini_get_string(const ds_ini* ini, const char* section, const char* key,
                           const char* def, char* out, unsigned size);
unsigned ds_ini_get_int(const ds_ini* ini, const char* section, const char* key, int def);

/* A ds_source calling the Windows functions on a file. path must be
 * absolute (the Windows functions look in the Windows folder otherwise) and
 * must stay valid while the source is used. */
ds_source ds_source_winapi(const char* path);

/* ---- Rendering ------------------------------------------------------------ */

/* The level, tuning and time factors of the original ds2mem() (the
 * in-memory render the original exported but its GUI never used).
 * ds2wav() uses t = o = n = b = time = 1 and tune = 0. */
typedef struct ds_factors {
    float t, o, n, b;   /* tone, overtones, noise, noise band levels */
    float tune;         /* added to [General] Tuning, in semitones */
    float time;         /* multiplies [General] Stretch */
} ds_factors;

/* A rendered sound: 44.1 kHz, 16-bit, mono. */
typedef struct ds_sound {
    int16_t* samples;
    long length;              /* number of samples, a multiple of 1200 */
    char comment[256];        /* [General] Comment as the WAV's INFO chunk stores it */
    int comment_length;       /* bytes of comment written to the WAV (even) */
    unsigned notes;           /* DS_NOTE_* flags, see Diagnostics below */
} ds_sound;

/* Render a preset. factors may be NULL for ds2wav()'s values.
 * Returns DS_OK and fills *out, or an error code. */
int ds_render(const ds_source* source, const ds_factors* factors, ds_sound* out);
void ds_sound_free(ds_sound* sound);

/* Write a rendered sound as a WAV file, byte for byte as the original
 * ds2wav() writes it (header, data, then a LIST/INFO chunk with the
 * software name and the comment). Returns DS_OK or DS_ERR_OUTPUT. */
int ds_write_wav(const char* path, const ds_sound* sound);
/* The same bytes in memory. Returns the size, or 0 when out of memory;
 * free the buffer with free(). */
size_t ds_wav_bytes(const ds_sound* sound, unsigned char** bytes);

/* ds2wav(): read a .ds file with the in-memory parser, render it and write
 * the WAV. Returns the original's result codes. */
int ds_render_file(const char* ds_path, const char* wav_path);

/* ---- Diagnostics ----------------------------------------------------------
 * Things the original does that the rewrite cannot reproduce exactly
 * (docs/findings.md, "Where the rewrite cannot follow the original"). A
 * render reports them in ds_sound.notes; none of them happens with the
 * presets. */
enum {
    DS_NOTE_TOKEN_START = 1 << 0,  /* an envelope value read before any digit: the
                                       original reads its uninitialized buffer */
    DS_NOTE_MEMORY_BEYOND = 1 << 1,/* an envelope read or written past the DLL's
                                       global variables (runtime library data) */
    DS_NOTE_HANG = 1 << 2,         /* the original would hang or crash here
                                       (triangle phase NaN/infinite, distortion
                                       Rate below 0, noise band step 0) */
    DS_NOTE_POW_SPECIAL = 1 << 3   /* pow() with a non-finite argument or a result
                                       outside the double range, where _CIpow goes
                                       through its error handler; the rewrite gives
                                       the IEEE result (it matched the DLL in every
                                       case tested) */
};
#ifdef __cplusplus
}
#endif

#endif
