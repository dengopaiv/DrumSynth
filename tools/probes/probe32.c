/* probe32 - call the original ds2wav.dll's internal routines directly.
 *
 * The DLL exports only ds2wav, ds2mem and ds2buf, but its other functions
 * sit at fixed offsets inside it (docs/disasm/README.md). This 32-bit
 * program loads the DLL and calls them by address, to get reference values
 * for any input, bit for bit:
 *
 *   probe32 DLL scanf FILE   sscanf(line, "%f", &f) for every line of FILE
 *                            -> "<result> <float bits, hex>"; f starts as
 *                               7FC00001, so an unchanged f shows
 *   probe32 DLL pow FILE     _CIpow for lines "<x bits> <y bits>" (double,
 *                            hex) -> the 80-bit result, hex (20 digits)
 *   probe32 DLL wave FILE    waveform(ph, form) for lines "<ph bits> <form>"
 *                            (float bits, hex) -> the 80-bit result, hex
 *   probe32 DLL rand N       srand(1), then N values of rand()
 *
 * The x87 control word is 0x027F (53-bit precision, round to nearest: the
 * Windows default and the reference condition) for every call. */
#include <float.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

/* Offsets from the DLL's base address (image base 0x10000000). */
#define RVA_WAVEFORM 0x1350
#define RVA_SSCANF   0x3087
#define RVA_SRAND    0x32AA
#define RVA_RAND     0x32B7
#define RVA_POW      0x3590

static unsigned char* base;

static void hex80(const unsigned char* b)
{
    for (int i = 9; i >= 0; i--) printf("%02X", b[i]);
    printf("\n");
}

static void set_cw53(void)
{
    unsigned int cw;
    __control87_2(_PC_53 | _RC_NEAR, _MCW_PC | _MCW_RC, &cw, NULL);
}

static int read_line(FILE* f, char* buf, int size)
{
    if (!fgets(buf, size, f)) return 0;
    size_t n = strlen(buf);
    while (n && (buf[n - 1] == '\n' || buf[n - 1] == '\r')) buf[--n] = 0;
    return 1;
}

int main(int argc, char** argv)
{
    if (argc < 4) {
        fprintf(stderr, "usage: probe32 DLL scanf|pow|wave FILE | rand N\n");
        return 2;
    }
    HMODULE h = LoadLibraryA(argv[1]);
    if (!h) { fprintf(stderr, "cannot load %s\n", argv[1]); return 2; }
    base = (unsigned char*)h;
    set_cw53();

    if (strcmp(argv[2], "rand") == 0) {
        void (__cdecl *srand_fn)(unsigned) = (void (__cdecl*)(unsigned))(base + RVA_SRAND);
        int (__cdecl *rand_fn)(void) = (int (__cdecl*)(void))(base + RVA_RAND);
        int n = atoi(argv[3]);
        srand_fn(1);
        for (int i = 0; i < n; i++) printf("%d\n", rand_fn());
        return 0;
    }

    FILE* f = fopen(argv[3], "rb");
    if (!f) { fprintf(stderr, "cannot open %s\n", argv[3]); return 2; }
    static char line[4096];

    if (strcmp(argv[2], "scanf") == 0) {
        int (__cdecl *sscanf_fn)(const char*, const char*, ...) =
            (int (__cdecl*)(const char*, const char*, ...))(base + RVA_SSCANF);
        while (read_line(f, line, sizeof(line))) {
            unsigned int bits = 0x7FC00001u;
            float v;
            memcpy(&v, &bits, 4);
            int r = sscanf_fn(line, "%f", &v);
            memcpy(&bits, &v, 4);
            printf("%d %08X\n", r, bits);
        }
    } else if (strcmp(argv[2], "pow") == 0) {
        void* fn = base + RVA_POW;
        while (read_line(f, line, sizeof(line))) {
            unsigned long long xb, yb;
            double x, y;
            unsigned char res[10];
            if (sscanf(line, "%llx %llx", &xb, &yb) != 2) continue;
            memcpy(&x, &xb, 8);
            memcpy(&y, &yb, 8);
            /* The DLL's callers load the base, then the exponent:
             * st(0) = y, st(1) = x (for example at 1000181E). */
            __asm {
                fld qword ptr x
                fld qword ptr y
                call fn
                fstp tbyte ptr res
            }
            set_cw53();
            hex80(res);
        }
    } else if (strcmp(argv[2], "wave") == 0) {
        void* fn = base + RVA_WAVEFORM;
        while (read_line(f, line, sizeof(line))) {
            unsigned int phb;
            int form;
            unsigned char res[10];
            if (sscanf(line, "%x %d", &phb, &form) != 2) continue;
            __asm {
                push form
                push phb
                call fn
                add esp, 8
                fstp tbyte ptr res
            }
            hex80(res);
        }
    } else {
        fprintf(stderr, "unknown command %s\n", argv[2]);
        return 2;
    }
    fclose(f);
    return 0;
}
