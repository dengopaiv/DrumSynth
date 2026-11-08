/* ini_probe - compare the engine's .ds parser (engine/src/ds_ini.c) with the
 * Windows profile functions that the original engine uses.
 *
 *   ini_probe QUERIES FILES
 *
 * QUERIES: one query per line, fields separated by tabs:
 *   S <section> <key> <default> <size>   GetPrivateProfileStringA
 *   I <section> <key> <default>          GetPrivateProfileIntA
 * FILES: one .ds file path per line.
 *
 * Every query is run on every file both ways. Prints each difference as
 *   DIFF <file> <query> | windows: <result> | engine: <result>
 * and at the end "compared N, different M". Exit code 0 if no difference. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

#include "drumsynth.h"

typedef struct query {
    char kind;
    char section[256], key[256], def[256];
    int size;
} query;

static int split(char* line, char** fields, int max)
{
    int n = 0;
    fields[n++] = line;
    for (char* p = line; *p && n < max; p++)
        if (*p == '\t') { *p = 0; fields[n++] = p + 1; }
    return n;
}

static void chomp(char* s)
{
    size_t n = strlen(s);
    while (n && (s[n - 1] == '\n' || s[n - 1] == '\r')) s[--n] = 0;
}

int main(int argc, char** argv)
{
    if (argc != 3) { fprintf(stderr, "usage: ini_probe QUERIES FILES\n"); return 2; }
    FILE* qf = fopen(argv[1], "rb");
    FILE* ff = fopen(argv[2], "rb");
    if (!qf || !ff) { fprintf(stderr, "cannot open input\n"); return 2; }

    query* qs = NULL;
    int nq = 0, cap = 0;
    char line[4096];
    while (fgets(line, sizeof(line), qf)) {
        chomp(line);
        char* f[6];
        int n = split(line, f, 6);
        if (n < 4) continue;
        if (nq == cap) { cap = cap ? cap * 2 : 64; qs = realloc(qs, cap * sizeof(query)); }
        query* q = &qs[nq++];
        q->kind = f[0][0];
        strcpy(q->section, f[1]);
        strcpy(q->key, f[2]);
        strcpy(q->def, f[3]);
        q->size = n > 4 ? atoi(f[4]) : 0;
    }

    long compared = 0, different = 0;
    char path[MAX_PATH];
    while (fgets(path, sizeof(path), ff)) {
        chomp(path);
        if (!path[0]) continue;
        char full[MAX_PATH];
        GetFullPathNameA(path, MAX_PATH, full, NULL);
        ds_ini* ini = ds_ini_load(full);
        /* A file that cannot be read reads as empty, as with Windows. */
        if (!ini) ini = ds_ini_parse("", 0);
        for (int i = 0; i < nq; i++) {
            query* q = &qs[i];
            compared++;
            if (q->kind == 'S') {
                char a[1024], b[1024];
                memset(a, 0x55, sizeof(a));
                memset(b, 0x55, sizeof(b));
                DWORD ra = GetPrivateProfileStringA(q->section, q->key, q->def, a, q->size, full);
                unsigned rb = ds_ini_get_string(ini, q->section, q->key, q->def, b, q->size);
                if (ra != rb || strcmp(a, b) != 0) {
                    different++;
                    printf("DIFF %s S[%s][%s] def=\"%s\" size=%d | windows: %lu \"%s\" | engine: %u \"%s\"\n",
                           full, q->section, q->key, q->def, q->size, ra, a, rb, b);
                }
            } else {
                int def = atoi(q->def);
                UINT ra = GetPrivateProfileIntA(q->section, q->key, def, full);
                unsigned rb = ds_ini_get_int(ini, q->section, q->key, def);
                if (ra != rb) {
                    different++;
                    printf("DIFF %s I[%s][%s] def=%d | windows: %u | engine: %u\n",
                           full, q->section, q->key, def, ra, rb);
                }
            }
        }
        ds_ini_free(ini);
    }
    printf("compared %ld, different %ld\n", compared, different);
    return different ? 1 : 0;
}
