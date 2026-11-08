/* ds_wav.c - the WAV file exactly as the original ds2wav() writes it
 * (DLL 10002293..10002397 and 10002F90..10002FD5):
 *
 *   44 bytes  RIFF header: "RIFF", 36 + 2*Length + 44 + commentLen, "WAVE",
 *             "fmt ", 16, PCM (1), 1 channel, 44100 Hz, 88200 bytes/s,
 *             block align 2, 16 bits, "data", 2*Length
 *   2*Length  the samples, 16-bit little endian
 *   44 bytes  "LIST", 36 + commentLen, "INFO", "ISFT", 16,
 *             "DrumSynth v2.0 " and a zero byte, "ICMT", commentLen
 *   commentLen bytes of the comment (with its zero byte, padded to even)
 *
 * The RIFF length counts the LIST chunk; the data chunk is followed by the
 * LIST chunk, which is valid RIFF. */
#include "drumsynth.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned char* put32(unsigned char* p, uint32_t v)
{
    p[0] = (unsigned char)v; p[1] = (unsigned char)(v >> 8);
    p[2] = (unsigned char)(v >> 16); p[3] = (unsigned char)(v >> 24);
    return p + 4;
}

static unsigned char* put16(unsigned char* p, uint16_t v)
{
    p[0] = (unsigned char)v; p[1] = (unsigned char)(v >> 8);
    return p + 2;
}

static unsigned char* put4cc(unsigned char* p, const char* s)
{
    memcpy(p, s, 4);
    return p + 4;
}

size_t ds_wav_bytes(const ds_sound* sound, unsigned char** bytes)
{
    uint32_t length = (uint32_t)sound->length;
    uint32_t clen = (uint32_t)sound->comment_length;
    size_t total = 44 + 2 * (size_t)length + 44 + clen;
    unsigned char* b = malloc(total);
    *bytes = b;
    if (!b) return 0;
    unsigned char* p = b;
    p = put4cc(p, "RIFF");
    p = put32(p, 36 + 2 * length + 44 + clen);
    p = put4cc(p, "WAVE");
    p = put4cc(p, "fmt ");
    p = put32(p, 16);
    p = put16(p, 1);       /* WAVE_FORMAT_PCM */
    p = put16(p, 1);       /* mono */
    p = put32(p, 44100);
    p = put32(p, 2 * 44100);
    p = put16(p, 2);
    p = put16(p, 16);
    p = put4cc(p, "data");
    p = put32(p, 2 * length);
    for (uint32_t i = 0; i < length; i++) p = put16(p, (uint16_t)sound->samples[i]);
    p = put4cc(p, "LIST");
    p = put32(p, 36 + clen);
    p = put4cc(p, "INFO");
    p = put4cc(p, "ISFT");
    p = put32(p, 16);
    memcpy(p, "DrumSynth v2.0 ", 16); /* 15 characters and the zero byte */
    p += 16;
    p = put4cc(p, "ICMT");
    p = put32(p, clen);
    memcpy(p, sound->comment, clen);
    p += clen;
    return (size_t)(p - b);
}

int ds_write_wav(const char* path, const ds_sound* sound)
{
    unsigned char* bytes;
    size_t n = ds_wav_bytes(sound, &bytes);
    if (!n) return DS_ERR_OUTPUT;
    FILE* f = fopen(path, "wb");
    if (!f) { free(bytes); return DS_ERR_OUTPUT; }
    size_t w = fwrite(bytes, 1, n, f);
    int closed = fclose(f);
    free(bytes);
    return (w == n && closed == 0) ? DS_OK : DS_ERR_OUTPUT;
}

int ds_render_file(const char* ds_path, const char* wav_path)
{
    /* A file that cannot be read reads as empty, as with the Windows
     * functions: no Version, so result 2. */
    ds_ini* ini = ds_ini_load(ds_path);
    if (!ini) ini = ds_ini_parse("", 0);
    if (!ini) return DS_ERR_OUTPUT;
    ds_source src = ds_ini_source(ini);
    ds_sound sound;
    int r = ds_render(&src, NULL, &sound);
    ds_ini_free(ini);
    if (r != DS_OK) return r;
    r = ds_write_wav(wav_path, &sound);
    ds_sound_free(&sound);
    return r;
}
