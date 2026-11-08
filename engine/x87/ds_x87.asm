; ds_x87.asm - the x87 instruction sequences of the original ds2wav.dll,
; for the 64-bit C17 engine (assembled with ml64).
;
; Why this file exists (docs/rewrite-plan.md, docs/disasm/README.md):
; the original DLL was compiled by Visual C++ 6 for the x87 unit. Almost all
; of its arithmetic is plain +, -, *, / at 53-bit precision (the Windows
; default control word 0x027F), which gives exactly the same results as C
; `double` arithmetic on SSE2. The exceptions are the transcendental
; instructions fsin, fcos, fyl2x, f2xm1 and fscale and the constant fldl2e:
;   - their results have a 64-bit mantissa (precision control does not apply
;     to them), and the DLL often uses such a result directly in the next
;     multiplication, so the value is never rounded to 53 bits on its own;
;   - today's C library computes sin, cos, pow and exp differently.
; So each routine below executes the same instructions in the same order as
; the DLL, from the point where the transcendental instruction starts to the
; point where the DLL's value is back at 53-bit precision, and returns that
; value as a double. The DLL address of every sequence is given.
;
; Calling convention: Microsoft x64. double arguments arrive in xmm0..xmm3,
; the result is returned in xmm0. The x87 control word is callee-saved in
; the x64 ABI, so every routine saves it, sets 0x027F (53-bit precision,
; round to nearest, all exceptions masked, as in the DLL) and restores it.
; The x87 register stack is empty on entry and on exit, as the ABI requires.
; The routines use only the caller's 32-byte home space (rsp+8 .. rsp+39),
; so they need no prologue.
;
; Home space layout used by every routine:
;   [rsp+8]  saved control word (word)
;   [rsp+10] control word 0x027F (word)
;   [rsp+16] scratch qword (argument / result transfer)
;   [rsp+24] scratch qword
;   [rsp+32] scratch qword

        .code

CW53    MACRO
        fnstcw  word ptr [rsp+8]
        mov     word ptr [rsp+10], 027Fh
        fldcw   word ptr [rsp+10]
        ENDM

CWBACK  MACRO
        fldcw   word ptr [rsp+8]
        ENDM

; double ds87_sin(double x)
; round53(fsin(x)). Used where the DLL rounds the fsin result before any
; other use: waveform() form 1 (fadd st(0),st doubles it, then rounds;
; doubling is exact, so 2*round53(s) == round53(2*s)) and the sign test of
; the square wave. DLL: 1000138B, 10001430.
ds87_sin PROC
        CW53
        movsd   qword ptr [rsp+16], xmm0
        fld     qword ptr [rsp+16]
        fsin
        fstp    qword ptr [rsp+16]
        CWBACK
        movsd   xmm0, qword ptr [rsp+16]
        ret
ds87_sin ENDP

; double ds87_sin_mul(double x, double m)
; round53(fsin(x) * m): the 64-bit fsin result multiplied directly.
; DLL: tone 10002613 (fsin, fmul envData[1][ENV]); waveform() form 0 returns
; the raw fsin result (10001373) and every caller multiplies it first
; (10002A31, 10002A54, 10002A8A, 10002AAF, 10002B02, 10002B19).
ds87_sin_mul PROC
        CW53
        movsd   qword ptr [rsp+16], xmm0
        movsd   qword ptr [rsp+24], xmm1
        fld     qword ptr [rsp+16]
        fsin
        fmul    qword ptr [rsp+24]
        fstp    qword ptr [rsp+16]
        CWBACK
        movsd   xmm0, qword ptr [rsp+16]
        ret
ds87_sin_mul ENDP

; double ds87_cos_mul(double x, double m)
; round53(fcos(x) * m). DLL: noise band 1 10002742, noise band 2 1000285B.
ds87_cos_mul PROC
        CW53
        movsd   qword ptr [rsp+16], xmm0
        movsd   qword ptr [rsp+24], xmm1
        fld     qword ptr [rsp+16]
        fcos
        fmul    qword ptr [rsp+24]
        fstp    qword ptr [rsp+16]
        CWBACK
        movsd   xmm0, qword ptr [rsp+16]
        ret
ds87_cos_mul ENDP

; double ds87_pow_core(double x, double y)
; The main path of VC6's _CIpow (DLL 100035FF and 10008710) for a finite
; positive (or denormal) x and a finite y:
;   z = fyl2x: y * log2(x), 64-bit result
;   n = frndint(z)                      (round to nearest even)
;   f = round53(n - z), negated: z - n  (fsubr st(1),st then fchs)
;   r = round53(f2xm1(f) + 1)
;   result = fscale(r, n)               (exact)
; The caller (ds_vc6.c) handles zero, negative and non-finite arguments the
; way _CIpow does.
ds87_pow_core PROC
        CW53
        movsd   qword ptr [rsp+16], xmm0        ; x
        movsd   qword ptr [rsp+24], xmm1        ; y
        fld     qword ptr [rsp+24]              ; st0 = y
        fld     qword ptr [rsp+16]              ; st0 = x, st1 = y
        fyl2x                                   ; st0 = y * log2(x)
        fld     st(0)                           ; 10008710
        frndint
        fsubr   st(1), st
        fxch    st(1)
        fchs
        f2xm1
        fld1
        faddp   st(1), st
        fscale
        fstp    st(1)
        fstp    qword ptr [rsp+16]
        CWBACK
        movsd   xmm0, qword ptr [rsp+16]
        ret
ds87_pow_core ENDP

; The exp() that VC6 inlined (DLL 10001B3F and 10002536):
;   fldl2e; fmulp      z = round53(x * log2(e)), log2(e) at 64 bits
;   fld st0; frndint   n
;   fxch; fsub st,st1  f = round53(z - n)
;   f2xm1; fld1; faddp r = round53(f2xm1(f) + 1)
;   fscale; fstp st1   r * 2^n
; It is used in two places, each written out as a whole chain, because the
; result can lie outside the double exponent range (droop: exp(-1857)), where
; the x87 register still holds it exactly.
EXPSEQ  MACRO
        fldl2e
        fmulp   st(1), st
        fld     st(0)
        frndint
        fxch    st(1)
        fsub    st, st(1)
        f2xm1
        fld1
        faddp   st(1), st
        fscale
        fstp    st(1)
        ENDM

; double ds87_droop_phi(double t, double rate, double ddf, double f2)
; Tone with droop, DLL 10002526..1000255D:
;   phi[t] = F2 + ddF * exp(t * TDroopRate)
; compiled as round53(round53(exp(round53(t * rate)) * ddF) + F2).
ds87_droop_phi PROC
        CW53
        movsd   qword ptr [rsp+16], xmm0        ; t (exact integer)
        movsd   qword ptr [rsp+24], xmm1        ; TDroopRate (float value)
        movsd   qword ptr [rsp+32], xmm2        ; ddF (float value)
        fld     qword ptr [rsp+16]
        fmul    qword ptr [rsp+24]
        EXPSEQ
        fmul    qword ptr [rsp+32]
        movsd   qword ptr [rsp+16], xmm3        ; F2 (float value)
        fadd    qword ptr [rsp+16]
        fstp    qword ptr [rsp+16]
        CWBACK
        movsd   xmm0, qword ptr [rsp+16]
        ret
ds87_droop_phi ENDP

; double ds87_droop_f2(double f1, double f2, double emax, double rate)
; Droop set-up, DLL 10001B2D..10001B61:
;   F2 = F1 + ((F2 - F1) / (1 - exp(envData[1][MAX] * TDroopRate)))
; compiled as
;   d = round53(F2 - F1)
;   e = exp(round53(MAX * rate))       (inlined sequence)
;   result = round53(round53(d / round53(1 - e)) + F1)
ds87_droop_f2 PROC
        CW53
        movsd   qword ptr [rsp+16], xmm1        ; F2
        movsd   qword ptr [rsp+24], xmm0        ; F1
        fld     qword ptr [rsp+16]
        fsub    qword ptr [rsp+24]              ; st0 = F2 - F1
        movsd   qword ptr [rsp+16], xmm2        ; envData[1][MAX]
        movsd   qword ptr [rsp+32], xmm3        ; TDroopRate
        fld     qword ptr [rsp+16]
        fmul    qword ptr [rsp+32]              ; st0 = MAX * rate
        EXPSEQ                                  ; st0 = e, st1 = F2 - F1
        fld1
        fsubrp  st(1), st                       ; st0 = 1 - e  (fsubr 1.0f)
        fdivp   st(1), st                       ; st0 = (F2 - F1) / (1 - e)
        fadd    qword ptr [rsp+24]              ; + F1
        fstp    qword ptr [rsp+16]
        CWBACK
        movsd   xmm0, qword ptr [rsp+16]
        ret
ds87_droop_f2 ENDP

; ---------------------------------------------------------------------------
; Test helpers: the same sequences, returning the full 80-bit register value
; (10 bytes at *out) instead of a double, so that the test programs can
; compare them bit for bit with the DLL's own routines.

; void ds87_test_sin80(double x, void* out)   fsin(x), 80-bit
ds87_test_sin80 PROC
        CW53
        movsd   qword ptr [rsp+16], xmm0
        fld     qword ptr [rsp+16]
        fsin
        fstp    tbyte ptr [rdx]
        CWBACK
        ret
ds87_test_sin80 ENDP

; void ds87_test_cos80(double x, void* out)   fcos(x), 80-bit
ds87_test_cos80 PROC
        CW53
        movsd   qword ptr [rsp+16], xmm0
        fld     qword ptr [rsp+16]
        fcos
        fstp    tbyte ptr [rdx]
        CWBACK
        ret
ds87_test_cos80 ENDP

; void ds87_test_pow80(double x, double y, void* out)   _CIpow core, 80-bit
ds87_test_pow80 PROC
        CW53
        movsd   qword ptr [rsp+16], xmm0
        movsd   qword ptr [rsp+24], xmm1
        fld     qword ptr [rsp+24]
        fld     qword ptr [rsp+16]
        fyl2x
        fld     st(0)
        frndint
        fsubr   st(1), st
        fxch    st(1)
        fchs
        f2xm1
        fld1
        faddp   st(1), st
        fscale
        fstp    st(1)
        fstp    tbyte ptr [r8]
        CWBACK
        ret
ds87_test_pow80 ENDP

; void ds87_test_exp80(double x, void* out)   inlined exp sequence, 80-bit
ds87_test_exp80 PROC
        CW53
        movsd   qword ptr [rsp+16], xmm0
        fld     qword ptr [rsp+16]
        EXPSEQ
        fstp    tbyte ptr [rdx]
        CWBACK
        ret
ds87_test_exp80 ENDP

        END
