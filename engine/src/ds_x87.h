/* ds_x87.h - x87 instruction sequences from the original ds2wav.dll,
 * implemented in engine/x87/ds_x87.asm (ml64). See that file for why they
 * are in assembly and which DLL addresses each one reproduces. */
#ifndef DS_X87_H
#define DS_X87_H

double ds87_sin(double x);                 /* round53(fsin(x)) */
double ds87_sin_mul(double x, double m);   /* round53(fsin(x) * m) */
double ds87_cos_mul(double x, double m);   /* round53(fcos(x) * m) */
double ds87_pow_core(double x, double y);  /* _CIpow main path, x > 0 */
/* round53(round53(exp(round53(t * rate)) * ddf) + f2), the droop phase step */
double ds87_droop_phi(double t, double rate, double ddf, double f2);
/* f1 + (f2 - f1) / (1 - exp(emax * rate)), the droop set-up */
double ds87_droop_f2(double f1, double f2, double emax, double rate);

/* Test helpers: the full 80-bit result, 10 bytes, little endian. */
void ds87_test_sin80(double x, void* out);
void ds87_test_cos80(double x, void* out);
void ds87_test_pow80(double x, double y, void* out);
void ds87_test_exp80(double x, void* out);

#endif

#ifdef DS_ABLATE_LIBM
/* Diagnostic build (drumsynth_engine_libm, renderer c17-libm): today's C
 * library instead of the x87 sequences, to measure what they are worth
 * (docs/reports/ref-vs-c17-libm.md). Not for use. */
#include <math.h>
#define ds87_sin(x) sin(x)
#define ds87_sin_mul(x, m) (sin(x) * (m))
#define ds87_cos_mul(x, m) (cos(x) * (m))
#define ds87_droop_phi(t, rate, ddf, f2) (exp((t) * (rate)) * (ddf) + (f2))
#define ds87_droop_f2(f1, f2, emax, rate) ((f1) + ((f2) - (f1)) / (1.0 - exp((emax) * (rate))))
#endif
