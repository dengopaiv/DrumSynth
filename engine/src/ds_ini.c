/* ds_ini.c - reading .ds files the way the Windows functions
 * GetPrivateProfileStringA and GetPrivateProfileIntA read them.
 *
 * The original engine reads every value with those two functions, so their
 * rules decide what a preset means. The rules below were found and are
 * checked against Windows 11 with tools/probes (ini_probe.c on all presets
 * and on generated files, docs/reference/probes.md; the experiments are in
 * docs/reference/ini-rules.md):
 *
 *   - Lines end at '
' or '' (so LF, CRLF and CR files read the same).
 *   - White space is every character from 0x00 to 0x20; it is ignored at
 *     both ends of a line, of a name and of a value.
 *   - A line starting with ';' is a comment. ('#' is not special.)
 *   - A line starting with '[' starts a section. Its name is the text up to
 *     the first ']', or to the end of the line if there is none.
 *   - Any other line with a '=' is a key: the name is the text before the
 *     first '=', the value the text after it. Lines without '=' are
 *     ignored (a later "a=1" is found even after a line "a").
 *   - Keys before the first section cannot be read.
 *   - Section and key names are compared without regard to (ASCII) case.
 *     The names asked for are used without spaces (only ' ') at their ends.
 *   - The first section with the name is the only one searched, and the
 *     first key with the name in it wins.
 *   - A value of two or more characters enclosed in matching single or
 *     double quotes is returned without them.
 *   - At most size - 1 characters are copied. A missing key gives the
 *     default value, without trailing spaces.
 *   - GetPrivateProfileIntA reads the value as above with a 256-character
 *     buffer; an empty value gives the default. Otherwise it skips every
 *     character that is at most ' ' as a *signed* char (so also all bytes
 *     0x80-0xFF), reads an optional '+' or '-', an optional prefix 0x, 0o or
 *     0b (lower case only), then digits of that base (letters in either
 *     case) up to the first other character, wrapping modulo 2^32.
 *
 * Bytes are used as they are; the original reads files in the ANSI code
 * page, and Windows' conversion to Unicode and back changes nothing for
 * them. Not reproduced: files with NUL bytes, which Windows may take for
 * UTF-16 text, and files with a byte order mark. No preset has either. */
#include "drumsynth.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct ds_line {
    const char* name;      /* key name or section name */
    size_t name_len;
    const char* value;     /* NULL: no '=' on the line */
    size_t value_len;
    int is_section;
} ds_line;

struct ds_ini {
    char* text;
    ds_line* lines;
    size_t count;
};

static int ini_space(unsigned char c)
{
    /* White space in the file: every character up to ' '. */
    return c <= ' ';
}

static int lower(int c)
{
    return (c >= 'A' && c <= 'Z') ? c - 'A' + 'a' : c;
}

static int same_name(const char* a, size_t alen, const char* b)
{
    size_t blen = strlen(b);
    /* The requested name is used without spaces at its ends. */
    while (blen && b[0] == ' ') { b++; blen--; }
    while (blen && b[blen - 1] == ' ') blen--;
    if (alen != blen) return 0;
    for (size_t i = 0; i < alen; i++)
        if (lower((unsigned char)a[i]) != lower((unsigned char)b[i])) return 0;
    return 1;
}

ds_ini* ds_ini_parse(const char* text, size_t length)
{
    ds_ini* ini = calloc(1, sizeof(*ini));
    if (!ini) return NULL;
    ini->text = malloc(length + 1);
    size_t max_lines = 1;
    for (size_t i = 0; i < length; i++) if (text[i] == '\n' || text[i] == '\r') max_lines++;
    ini->lines = calloc(max_lines, sizeof(ds_line));
    if (!ini->text || !ini->lines) { ds_ini_free(ini); return NULL; }
    memcpy(ini->text, text, length);
    ini->text[length] = 0;

    const char* p = ini->text;
    const char* end = ini->text + length;
    while (p < end) {
        const char* line_end = p;
        while (line_end < end && *line_end != '\n' && *line_end != '\r') line_end++;
        const char* next = line_end < end ? line_end + 1 : end;
        const char* a = p;
        const char* b = line_end;
        while (a < b && ini_space((unsigned char)*a)) a++;
        while (b > a && ini_space((unsigned char)b[-1])) b--;
        p = next;
        if (a >= b) continue;

        if (*a == ';') continue; /* comment */
        ds_line* L = &ini->lines[ini->count];
        if (*a == '[') {
            const char* n = a + 1;
            const char* close = memchr(n, ']', (size_t)(b - n));
            const char* ne = close ? close : b;
            while (n < ne && ini_space((unsigned char)*n)) n++;
            while (ne > n && ini_space((unsigned char)ne[-1])) ne--;
            L->is_section = 1;
            L->name = n;
            L->name_len = (size_t)(ne - n);
            ini->count++;
            continue;
        }
        const char* eq = memchr(a, '=', (size_t)(b - a));
        if (!eq) continue; /* not a key */
        const char* ne = eq;
        while (ne > a && ini_space((unsigned char)ne[-1])) ne--;
        const char* vs = eq + 1;
        while (vs < b && ini_space((unsigned char)*vs)) vs++;
        L->name = a;
        L->name_len = (size_t)(ne - a);
        L->value = vs;
        L->value_len = (size_t)(b - vs);
        ini->count++;
    }
    return ini;
}

ds_ini* ds_ini_load(const char* path)
{
    FILE* f = fopen(path, "rb");
    if (!f) return NULL;
    char* buf = NULL;
    size_t len = 0, cap = 0;
    for (;;) {
        if (len == cap) {
            cap = cap ? cap * 2 : 4096;
            char* nb = realloc(buf, cap);
            if (!nb) { free(buf); fclose(f); return NULL; }
            buf = nb;
        }
        size_t got = fread(buf + len, 1, cap - len, f);
        len += got;
        if (got == 0) break;
    }
    fclose(f);
    ds_ini* ini = ds_ini_parse(buf ? buf : "", len);
    free(buf);
    return ini;
}

void ds_ini_free(ds_ini* ini)
{
    if (!ini) return;
    free(ini->text);
    free(ini->lines);
    free(ini);
}

/* The line of the key in the first section with the name, or NULL. */
static const ds_line* find_key(const ds_ini* ini, const char* section, const char* key)
{
    size_t i = 0;
    /* keys before the first section cannot be read */
    for (; i < ini->count; i++)
        if (ini->lines[i].is_section && same_name(ini->lines[i].name, ini->lines[i].name_len, section)) break;
    if (i == ini->count) return NULL;
    i++;
    for (; i < ini->count && !ini->lines[i].is_section; i++)
        if (same_name(ini->lines[i].name, ini->lines[i].name_len, key)) return &ini->lines[i];
    return NULL;
}

unsigned ds_ini_get_string(const ds_ini* ini, const char* section, const char* key,
                           const char* def, char* out, unsigned size)
{
    if (size == 0) return 0;
    const ds_line* L = ini ? find_key(ini, section, key) : NULL;
    const char* v;
    size_t vlen;
    if (L) {
        v = L->value ? L->value : "";
        vlen = L->value ? L->value_len : 0;
        if (vlen >= 2 && (v[0] == '"' || v[0] == '\'') && v[vlen - 1] == v[0]) {
            v++;
            vlen -= 2;
        }
    } else {
        v = def ? def : "";
        vlen = strlen(v);
        while (vlen && v[vlen - 1] == ' ') vlen--;
    }
    if (vlen > size - 1) vlen = size - 1;
    memcpy(out, v, vlen);
    out[vlen] = 0;
    return (unsigned)vlen;
}

unsigned ds_ini_get_int(const ds_ini* ini, const char* section, const char* key, int def)
{
    char buf[256];
    if (ds_ini_get_string(ini, section, key, "", buf, sizeof(buf)) == 0) return (unsigned)def;
    const unsigned char* p = (const unsigned char*)buf;
    while (*p && (signed char)*p <= ' ') p++;
    int minus = 0;
    if (*p == '+') p++;
    else if (*p == '-') { minus = 1; p++; }
    unsigned base = 10;
    if (p[0] == '0' && p[1] == 'x') { base = 16; p += 2; }
    else if (p[0] == '0' && p[1] == 'o') { base = 8; p += 2; }
    else if (p[0] == '0' && p[1] == 'b') { base = 2; p += 2; }
    uint32_t total = 0;
    for (;; p++) {
        unsigned d;
        if (*p >= '0' && *p <= '9') d = *p - '0';
        else if (*p >= 'A' && *p <= 'Z') d = *p - 'A' + 10;
        else if (*p >= 'a' && *p <= 'z') d = *p - 'a' + 10;
        else break;
        if (d >= base) break;
        total = total * base + d;
    }
    return minus ? 0u - total : total;
}

static unsigned ini_get_string(void* ctx, const char* s, const char* k, const char* d, char* o, unsigned n)
{
    return ds_ini_get_string((const ds_ini*)ctx, s, k, d, o, n);
}

static unsigned ini_get_int(void* ctx, const char* s, const char* k, int d)
{
    return ds_ini_get_int((const ds_ini*)ctx, s, k, d);
}

ds_source ds_ini_source(const ds_ini* ini)
{
    ds_source src = { ini_get_string, ini_get_int, (void*)ini };
    return src;
}
