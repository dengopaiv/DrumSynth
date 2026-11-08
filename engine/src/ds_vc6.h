/* ds_vc6.h - the parts of Visual C++ 6's runtime library that the original
 * ds2wav.dll links statically, reproduced so that the C17 engine gives the
 * same results. Each function names the DLL address it reproduces; the
 * analysis is in docs/disasm/README.md. */
#ifndef DS_VC6_H
#define DS_VC6_H

#include <stdint.h>

/* _ftol (DLL 10003060): sets the x87 rounding to truncate, stores the value
 * with fistp as a 64-bit integer and returns the low 32 bits (eax). Every
 * (int), (long) and (short) conversion of a floating-point value in the DLL
 * goes through it; (short) then takes the low 16 bits (ax).
 * Out of the 64-bit range, and for NaN, fistp stores the "integer
 * indefinite" 0x8000000000000000, whose low 32 bits are 0. */
int32_t vc6_ftol(double x);

static inline int16_t vc6_ftol_short(double x)
{
    return (int16_t)(uint16_t)(uint32_t)vc6_ftol(x);
}

/* rand() and srand() (DLL 100032B7, 100032AA): the Microsoft linear
 * congruential generator, seed = seed * 214013 + 2531011, result
 * (seed >> 16) & 0x7FFF. The seed lives in the DLL's per-thread data; the
 * DLL calls srand(1) at the start of every render, so a per-render seed
 * gives the same sequence. */
typedef struct { uint32_t seed; } vc6_rand_state;

static inline void vc6_srand(vc6_rand_state* r, uint32_t seed) { r->seed = seed; }

static inline int vc6_rand(vc6_rand_state* r)
{
    r->seed = r->seed * 214013u + 2531011u;
    return (int)((r->seed >> 16) & 0x7FFFu);
}

/* sscanf(s, "%f", &f) (DLL 10003087), as the DLL uses it.
 * Returns what sscanf returns: 1 when a number was converted (stored in *f),
 * 0 when the text does not start with a number (*f unchanged), and -1 (EOF)
 * when the string is empty or only white space (*f unchanged).
 * The text-to-float conversion is checked against the DLL's own sscanf with
 * tools/probes (docs/reference/). */
int vc6_scan_float(const char* s, float* f);

/* _atoflt (DLL 100099F7): VC6's conversion of the text sscanf collected
 * into a float (ds_vc6_fltin.c). */
float vc6_atoflt(const char* text);

/* pow() as VC6's _CIpow computes it (DLL 10003590, 100035B2, 10008710):
 * y * log2(x) with fyl2x, then 2^z with f2xm1 and fscale, at 53-bit
 * precision. Zero, negative and non-finite arguments are handled the way
 * _CIpow handles them (see ds_vc6.c). */
double vc6_pow(double x, double y);

/* fmod() as VC6's _CIfmod: like C fmod, except that a zero x gives +0
 * (see ds_vc6.c). */
double vc6_fmod(double x, double y);

#endif
