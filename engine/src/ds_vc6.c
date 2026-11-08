/* ds_vc6.c - Visual C++ 6 runtime behaviour the original ds2wav.dll depends
 * on. See ds_vc6.h and docs/disasm/README.md. */
#include "ds_vc6.h"

#include <ctype.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "ds_x87.h"

int32_t vc6_ftol(double x)
{
    /* fistp qword with the rounding control set to truncate. Values outside
     * [-2^63, 2^63), and NaN, give the integer indefinite
     * 0x8000000000000000, whose low half is 0. */
    if (!(x >= -0x1p63 && x < 0x1p63)) return 0;
    int64_t v = (int64_t)x; /* C conversion truncates toward zero */
    return (int32_t)(uint32_t)(uint64_t)v;
}

/* ---- sscanf("%f") ----------------------------------------------------------
 * VC6's input.c reads, for %f: white space; an optional sign; digits; an
 * optional '.' and digits; and, only if at least one digit was read, an
 * 'e' or 'E' with an optional sign and digits. If no digit was read the
 * conversion fails: sscanf returns 0 if the failure was at a character, or
 * EOF (-1) if it was at the end of the string (also for an empty or
 * all-white-space string). The collected text is converted by _fltin
 * (__strgtold12, then rounding to float).
 *
 * The text-to-float conversion is VC6's own, transcribed in ds_vc6_fltin.c;
 * tools/probes compares it with the DLL's sscanf (docs/reference/probes.md). */
static int vc6_isspace(int c)
{
    /* isspace() in the "C" locale, which the DLL never changes. */
    return c == ' ' || c == '\t' || c == '\n' || c == '\v' || c == '\f' || c == '\r';
}

int vc6_scan_float(const char* s, float* f)
{
    const unsigned char* p = (const unsigned char*)s;
    char buf[400];
    size_t n = 0;
    int started = 0;

    while (vc6_isspace(*p)) p++;
    if (*p == 0) return -1;

    if (*p == '-') { buf[n++] = '-'; p++; }
    else if (*p == '+') { p++; }
    while (isdigit(*p) && n < sizeof(buf) - 8) { started = 1; buf[n++] = (char)*p++; }
    if (*p == '.') {
        buf[n++] = '.';
        p++;
        while (isdigit(*p) && n < sizeof(buf) - 8) { started = 1; buf[n++] = (char)*p++; }
    }
    if (started && (*p == 'e' || *p == 'E')) {
        buf[n++] = 'e';
        p++;
        if (*p == '-') { buf[n++] = '-'; p++; }
        else if (*p == '+') { p++; }
        while (isdigit(*p) && n < sizeof(buf) - 2) { buf[n++] = (char)*p++; }
    }
    if (!started) return *p == 0 ? -1 : 0;

    buf[n] = 0;
#ifdef DS_ABLATE_LIBM
    *f = strtof(buf, NULL);
#else
    *f = vc6_atoflt(buf);
#endif
    return 1;
}

/* ---- pow ------------------------------------------------------------------
 * VC6's _CIpow (DLL 100035B2). For the arguments DrumSynth uses (x > 0 and
 * finite) it is ds87_pow_core. The other cases, as the DLL handles them:
 *   x == +-0:   y == 0 -> 1; y denormal -> 0; y < 0 -> +inf (-inf for -0
 *               and odd integer y); y > 0 -> +0 (-0 for -0 and odd y)
 *   x < 0:      y not an integer -> NaN (domain error); otherwise
 *               pow(-x, y), negated for odd y
 *   non-finite: not reproduced (C pow).
 * The integer test is VC6's: frndint(y) == y, then frndint(y/2) == y/2. */
static int int_class(double y)
{
    if (nearbyint(y) != y) return 0;            /* not an integer */
    return nearbyint(y * 0.5) != y * 0.5 ? 1 : 2; /* 1 = odd, 2 = even */
}

double vc6_pow(double x, double y)
{
#ifdef DS_ABLATE_LIBM
    return pow(x, y);
#endif
    if (!isfinite(x) || !isfinite(y)) return pow(x, y);
    if (x == 0.0) {
        if (y == 0.0) return 1.0;
        if (fpclassify(y) == FP_SUBNORMAL) return 0.0;
        int odd_neg = signbit(x) && int_class(y) == 1;
        if (y < 0.0) return odd_neg ? -INFINITY : INFINITY;
        return odd_neg ? -0.0 : 0.0;
    }
    if (x < 0.0) {
        int k = int_class(y);
        if (k == 0) return -NAN; /* the x87 "indefinite" QNaN, sign set */
        double r = ds87_pow_core(-x, y);
        return k == 1 ? -r : r;
    }
    return ds87_pow_core(x, y);
}

/* ---- fmod -----------------------------------------------------------------
 * VC6's _CIfmod (DLL 100030CA, 10004930): it classifies both arguments with
 * fxam (10004C07) and dispatches through a table (1000F1E0):
 *   both finite and non-zero: fprem until complete (100030D4), which gives
 *                             the exact remainder, like C fmod;
 *   x zero (either sign):     +0 (10004CA4), where C fmod keeps the sign;
 *   any NaN:                  a NaN;
 *   x infinite, y zero or y infinite: the "indefinite" NaN.
 * (fprem runs with the control word 0x133F, 64-bit precision; it is exact
 * at any precision.) */
double vc6_fmod(double x, double y)
{
#ifdef DS_ABLATE_LIBM
    return fmod(x, y);
#endif
    if (isnan(x) || isnan(y)) return NAN;
    if (isinf(x) || y == 0.0 || isinf(y)) return -NAN;
    if (x == 0.0) return 0.0;
    return fmod(x, y);
}
