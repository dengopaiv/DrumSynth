/* Shared command line for the renderers.
 *
 *   <renderer> [--dll PATH] IN.ds OUT.wav
 *   <renderer> [--dll PATH] LISTFILE      (one "IN.ds<TAB>OUT.wav" per line)
 *
 * Options: --dll PATH (ref_render), --fpu 24|53|64 (32-bit only),
 * --no-clear-stack (see clear_stack below).
 *
 * Prints "<result code><TAB><input>" for every file. Exit code 0 when every
 * file rendered, 1 when any failed, 2 on a usage or setup error.
 * Paths are made absolute first: the original engine reads presets with
 * GetPrivateProfileString, which looks in the Windows folder for bare names. */
#include <float.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>
#include "renderer.h"

/* Zero the stack the renderer is about to use.
 *
 * The original engine reads at least one local variable before it is ever
 * written: Ot, the overtone output, is added to every sample but only set
 * when the overtones section is on. With overtones off it is whatever the
 * stack held, which depends on the host program, on the path strings passed
 * to Windows, and on the previous render (after a render with overtones on,
 * the slot holds that render's last overtone value, usually 0). Zeroing the
 * stack first makes every render start from the same state: the
 * uninitialized values read as 0. --no-clear-stack turns this off, to see
 * the raw behaviour. See docs/findings.md. */
static int clear_stack_enabled = 1;

static __declspec(noinline) void clear_stack(void)
{
    volatile unsigned char buffer[256 * 1024];
    SecureZeroMemory((void*)buffer, sizeof(buffer));
}

static int render_path(const char* in, const char* out)
{
    char full_in[MAX_PATH], full_out[MAX_PATH];
    if (!GetFullPathNameA(in, MAX_PATH, full_in, NULL)) return -1;
    if (!GetFullPathNameA(out, MAX_PATH, full_out, NULL)) return -1;
    if (clear_stack_enabled) clear_stack();
    return render_one(full_in, full_out);
}

int main(int argc, char** argv)
{
    const char* option = NULL;
    int first = 1;
    int fpu_bits = 0;

    for (;;) {
        if (argc - first > 1 && strcmp(argv[first], "--dll") == 0) {
            option = argv[first + 1];
            first += 2;
        } else if (argc - first > 1 && strcmp(argv[first], "--fpu") == 0) {
            fpu_bits = atoi(argv[first + 1]);
            if (fpu_bits != 24 && fpu_bits != 53 && fpu_bits != 64) {
                fprintf(stderr, "%s: --fpu must be 24, 53 or 64\n", RENDERER_NAME);
                return 2;
            }
            first += 2;
        } else if (argc - first > 0 && strcmp(argv[first], "--no-clear-stack") == 0) {
            clear_stack_enabled = 0;
            first += 1;
        } else {
            break;
        }
    }
    if (argc - first != 1 && argc - first != 2) {
        fprintf(stderr, "usage: %s [--dll PATH] [--fpu 24|53|64] [--no-clear-stack] "
                "IN.ds OUT.wav | LISTFILE\n", RENDERER_NAME);
        return 2;
    }
    if (renderer_init(option) != 0) return 2;

    /* --fpu sets the x87 precision control (24, 53 or 64 bits of mantissa).
     * It only affects code that computes on the x87 unit, such as the
     * original VC6 DLL. It is applied after renderer_init() because loading
     * the DLL runs its C runtime start-up, which may reset the x87 settings.
     * The precision in effect is reported on stderr. */
    if (fpu_bits) {
#ifdef _M_IX86
        unsigned int pc = fpu_bits == 24 ? _PC_24 : fpu_bits == 53 ? _PC_53 : _PC_64; /* _PC_64 is 0 */
        unsigned int x87, sse;
        __control87_2(pc, _MCW_PC, &x87, &sse);
#else
        fprintf(stderr, "%s: --fpu is only available in 32-bit builds\n", RENDERER_NAME);
        return 2;
#endif
    }
#ifdef _M_IX86
    {
        unsigned int x87, sse;
        __control87_2(0, 0, &x87, &sse);
        fprintf(stderr, "%s: x87 precision %s\n", RENDERER_NAME,
                (x87 & _MCW_PC) == _PC_24 ? "24 bits" : (x87 & _MCW_PC) == _PC_53 ? "53 bits" : "64 bits");
    }
#endif

    if (argc - first == 2) {
        int r = render_path(argv[first], argv[first + 1]);
        printf("%d\t%s\n", r, argv[first]);
        return r == 0 ? 0 : 1;
    }

    {
        FILE* list = fopen(argv[first], "r");
        char line[2 * MAX_PATH + 16];
        int failed = 0;
        if (!list) {
            fprintf(stderr, "%s: cannot open %s\n", RENDERER_NAME, argv[first]);
            return 2;
        }
        while (fgets(line, sizeof(line), list)) {
            char* tab;
            int r;
            line[strcspn(line, "\r\n")] = 0;
            if (line[0] == 0) continue;
            tab = strchr(line, '\t');
            if (!tab) {
                fprintf(stderr, "%s: bad list line: %s\n", RENDERER_NAME, line);
                failed++;
                continue;
            }
            *tab = 0;
            r = render_path(line, tab + 1);
            printf("%d\t%s\n", r, line);
            if (r != 0) failed++;
        }
        fclose(list);
        return failed == 0 ? 0 : 1;
    }
}
