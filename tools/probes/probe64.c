/* probe64 - the C17 engine's versions of the routines that probe32 calls in
 * the original DLL, with the same commands and output format:
 *
 *   probe64 scanf FILE   vc6_scan_float      -> "<result> <float bits>"
 *   probe64 pow FILE     vc6_pow             -> its double result as an
 *                                               80-bit value (the DLL's
 *                                               result is always a double
 *                                               value: 53-bit, in range)
 *   probe64 wave FILE    the engine's waveform -> the 80-bit result
 *   probe64 rand N       vc6_rand after srand(1)
 */
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ds_vc6.h"
#include "ds_x87.h"

/* Test entry in ds_engine.c. */
void ds_test_waveform80(float ph, long form, unsigned char out[10]);
void ds_double_to_80(double d, unsigned char out[10]);

static void hex80(const unsigned char* b)
{
    for (int i = 9; i >= 0; i--) printf("%02X", b[i]);
    printf("\n");
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
    if (argc < 3) {
        fprintf(stderr, "usage: probe64 scanf|pow|wave FILE | rand N\n");
        return 2;
    }
    if (strcmp(argv[1], "rand") == 0) {
        vc6_rand_state r;
        vc6_srand(&r, 1);
        int n = atoi(argv[2]);
        for (int i = 0; i < n; i++) printf("%d\n", vc6_rand(&r));
        return 0;
    }
    FILE* f = fopen(argv[2], "rb");
    if (!f) { fprintf(stderr, "cannot open %s\n", argv[2]); return 2; }
    static char line[4096];
    if (strcmp(argv[1], "scanf") == 0) {
        while (read_line(f, line, sizeof(line))) {
            uint32_t bits = 0x7FC00001u;
            float v;
            memcpy(&v, &bits, 4);
            int r = vc6_scan_float(line, &v);
            memcpy(&bits, &v, 4);
            printf("%d %08X\n", r, bits);
        }
    } else if (strcmp(argv[1], "pow") == 0) {
        while (read_line(f, line, sizeof(line))) {
            unsigned long long xb, yb;
            double x, y;
            unsigned char res[10];
            if (sscanf(line, "%llx %llx", &xb, &yb) != 2) continue;
            memcpy(&x, &xb, 8);
            memcpy(&y, &yb, 8);
            ds_double_to_80(vc6_pow(x, y), res);
            hex80(res);
        }
    } else if (strcmp(argv[1], "wave") == 0) {
        while (read_line(f, line, sizeof(line))) {
            unsigned int phb;
            int form;
            float ph;
            unsigned char res[10];
            if (sscanf(line, "%x %d", &phb, &form) != 2) continue;
            memcpy(&ph, &phb, 4);
            ds_test_waveform80(ph, form, res);
            hex80(res);
        }
    } else {
        fprintf(stderr, "unknown command %s\n", argv[1]);
        return 2;
    }
    fclose(f);
    return 0;
}
