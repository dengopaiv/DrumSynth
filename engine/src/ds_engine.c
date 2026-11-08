/* ds_engine.c - the DrumSynth 2.0 synthesis, transcribed from the machine
 * code of the original bin/ds2wav.dll (not only from drumsynth.c).
 *
 * Reading guide (details in docs/disasm/README.md):
 *   - float variables are the DLL's float variables in memory; every store
 *     to one rounds to float, exactly where the DLL stores.
 *   - double expressions are the DLL's x87 register values at 53-bit
 *     precision. C double arithmetic gives the same results as the x87 unit
 *     at that precision (both round every +, -, *, / and sqrt correctly to
 *     53 bits), so where the DLL keeps a value in a register, it is a
 *     double here, and where VC6 reordered an expression, the order here is
 *     VC6's, not the source's.
 *   - Constants are the DLL's own constants, bit for bit: VC6 replaced
 *     divisions by constants with multiplications by a float reciprocal
 *     and folded TwoPi / Fs, and those roundings are part of the sound.
 *   - The transcendental instructions (fsin, fcos, and the fyl2x/f2xm1/
 *     fscale sequences of pow and exp) run in ds_x87.asm.
 *   - The DLL's global variables from phi[] to timestretch lie in one
 *     memory block, and the engine keeps them in the same layout (struct
 *     ds_image), because the original reads and writes past the ends of
 *     its envelope tables, and what it finds there is part of its output.
 *   - DLL addresses are given as 1000xxxx.
 */
#include "drumsynth.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include "ds_vc6.h"
#include "ds_x87.h"

/* ---- Constants (DLL .rdata) ---------------------------------------------- */
#define TWOPI_F     0x1.921fb6p+2f    /* 6.2831853f (1000E148) */
#define TWOPI_D     ((double)TWOPI_F) /* (double)6.2831853f (1000E150) */
#define K_TWOPI_FS  0x1.2acb26p-13f   /* TwoPi / Fs, folded and rounded to float (1000E1E0) */
#define K_0_01      0x1.47ae14p-7f    /* 0.01f (1000E120, 1000E1E4) */
#define K_HOLD      0x1.afa4p+18f     /* 442000.0f (1000E124) */
#define K_INV_PI    0x1.45f302p-2f    /* 0.3183098f (1000E138) */
#define K_INV_TWOPI 0x1.45f306p-3f    /* 1 / TwoPi as float (1000E13C) */
#define K_TWO_PI_R  0x1.45f304p-1f    /* 0.6366197f (1000E144) */
#define K_0_999     0x1.ff7ceep-1f    /* 0.999f (1000E158) */
#define K_0_7824    0x1.9096bcp-1f    /* 0.7824f (1000E15C) */
#define K_1_001     0x1.00418ap+0f    /* 1.001f (1000E160) */
#define K_RANDMAX   0x1.0002p-15f     /* 1.f / RAND_MAX (1000E168) */
#define K_RANDMAX2  0x1.0002p-14f     /* 2.f * randmax (1000E16C) */
#define K_0_4F      0x1.99999ap-2f    /* 1 / 2.5f as float (1000E18C) */
#define K_0_4D      0x1.999999999999ap-2 /* 1 / 2.5 as double (1000E180) */
#define K_0_19      0x1.851eb8p-3f    /* 0.19f (1000E198) */
#define K_0_92      0x1.d70a3ep-1f    /* 0.92f (1000E19C) */
#define K_1_8       0x1.ccccccp+0f    /* 1.8f (1000E1A0) */
#define K_0_7       0x1.666666p-1f    /* 0.7f (1000E1A4) */
#define K_0_28      0x1.1eb852p-2f    /* 0.28f (1000E1A8) */
#define K_DEG       0x1.1df46ap-6f    /* 1 / 57.29578f as float (1000E1C0) */
#define K_1_30      0x1.111112p-5f    /* 1 / 30.0f as float (1000E1C8) */
#define K_0_001D    ((double)0x1.0624dep-10f) /* (double)0.001f (1000E1D8) */
#define K_0_02      0x1.47ae14p-6f    /* 1 / 50.f as float (1000E1E8) */
#define K_0_0005    0x1.0624dep-11f   /* 0.0005f (1000E1EC) */
#define K_1_105     0x1.381382p-7f    /* 1 / 105.f as float (1000E1F0) */
#define K_0_0101    0x1.4af4fp-7f     /* 0.0101f (1000E200) */
#define K_SEMITONE  ((double)0x1.0f38fap+0f) /* (double)1.0594631f (1000E208) */
#define K_0_2F      0x1.99999ap-3f    /* 0.2f (1000E21C) */
#define K_0_001F    0x1.0624dep-10f   /* 0.001f (immediate 3A83126F) */
#define K_BPHI0     0x1.921fb6p-1f    /* TwoPi / 8.f, folded (immediate 3F490FDB) */
#define K_999999    999999.0f         /* (immediate 497423F0) */

enum { MAX = 0, ENV = 1, PNT = 2, dENV = 3, NEXTT = 4 };

/* ---- The DLL's global variables, in the DLL's layout ---------------------
 * 100128A0 phi[1200], 10013B60 DF[1200], 10014E20 envpts[8][3][32],
 * 10015A20 wavewords, 10015A24 (unused), 10015A40 sliLev[8],
 * 10015A60 clippoint (short), 10015A64 (unused), 10015A80 envData[8][6],
 * 10015B40 timestretch. After it the DLL has runtime library data, which
 * the rewrite cannot reproduce; reads there give 0 and are reported. */
enum {
    IMG_PHI = 0,
    IMG_DF = 1200,
    IMG_ENVPTS = 2400,
    IMG_WAVEWORDS = 3168,
    IMG_SLILEV = 3176,
    IMG_CLIP = 3184,
    IMG_ENVDATA = 3192,
    IMG_TS = 3240,
    IMG_END = 3241,      /* first word after timestretch */
    IMG_WORDS = IMG_END + 1024
};

typedef union ds_image {
    float f[IMG_WORDS];
    int32_t i[IMG_WORDS];
    uint32_t u[IMG_WORDS];
} ds_image;

typedef struct engine {
    ds_image m;
    int32_t chkOn[8];            /* 10012880 */
    vc6_rand_state rnd;          /* per-thread seed of rand() */
    const ds_source* src;
    unsigned notes;
} engine;

#define envData(e, k)  (E->m.f[IMG_ENVDATA + (e) * 6 + (k)])
#define timestretch    (E->m.f[IMG_TS])
#define sliLev(n)      (E->m.i[IMG_SLILEV + (n)])
#define DF(j)          (E->m.f[IMG_DF + (j)])
#define phi(j)         (E->m.f[IMG_PHI + (j)])

static int16_t get_clip(const engine* E) { return (int16_t)(uint16_t)(E->m.u[IMG_CLIP] & 0xFFFFu); }
static void set_clip(engine* E, int16_t v)
{
    E->m.u[IMG_CLIP] = (E->m.u[IMG_CLIP] & 0xFFFF0000u) | (uint16_t)v;
}

/* envpts[e][k][p] as a word index into the image. p is not limited to 0..31:
 * the original indexes past the end of a row (envelopes with more than 32
 * points, and UpdateEnv after the last point). */
static long envpts_index(long e, long k, long p) { return IMG_ENVPTS + e * 96 + k * 32 + p; }

static float img_read(engine* E, long idx)
{
    if (idx >= 0 && idx < IMG_END) return E->m.f[idx];
    E->notes |= DS_NOTE_MEMORY_BEYOND;
    return (idx >= 0 && idx < IMG_WORDS) ? E->m.f[idx] : 0.f;
}

static float* img_ptr(engine* E, long idx)
{
    static float sink;
    if (idx >= 0 && idx < IMG_END) return &E->m.f[idx];
    E->notes |= DS_NOTE_MEMORY_BEYOND;
    if (idx >= 0 && idx < IMG_WORDS) return &E->m.f[idx];
    sink = 0.f;
    return &sink;
}

/* pow as the DLL's _CIpow, noting the cases the rewrite does not reproduce
 * exactly: non-finite arguments, and results outside the double range,
 * where _CIpow goes through its error handler (10008832). */
static double epow(engine* E, double x, double y)
{
    double r = vc6_pow(x, y);
    if (!isfinite(x) || !isfinite(y) || isinf(r) || (r != 0.0 && fabs(r) < 0x1p-1022))
        E->notes |= DS_NOTE_POW_SPECIAL;
    return r;
}

/* ---- Profile access ------------------------------------------------------ */
static void get_string(engine* E, const char* sec, const char* key, const char* def, char* out, unsigned size)
{
    E->src->get_string(E->src->ctx, sec, key, def, out, size);
}

static uint32_t get_int(engine* E, const char* sec, const char* key, int def)
{
    return E->src->get_int(E->src->ctx, sec, key, def);
}

/* GetPrivateProfileFloat (10001460): a 16-character buffer, then sscanf. */
static float get_float(engine* E, const char* sec, const char* key, float v)
{
    char tmp[16];
    float f = 0.f;
    get_string(E, sec, key, "", tmp, sizeof(tmp));
    vc6_scan_float(tmp, &f);
    if (tmp[0] == 0) f = v;
    return f;
}

/* getEnv (10001230). The token buffer s keeps its contents between tokens:
 * two separators in a row read the previous token again. In the DLL, s is
 * 8 bytes directly below en on the stack, so a longer token runs on into
 * the part of en that has already been read, and is still read whole; here
 * the buffer is simply long enough. Before the first character, s holds
 * whatever the stack held (DS_NOTE_TOKEN_START); here it is empty. */
static void scan_into(engine* E, const char* s, long idx)
{
    float* p = img_ptr(E, idx);
    float v = *p;
    int r = vc6_scan_float(s, &v);
    if (r == 0) v = 0.f;
    *p = v;
}

static void getEnv(engine* E, int env, const char* sec, const char* key)
{
    char en[257];
    char s[260];
    int i = 0, o = 0;
    long ep = 0;
    int have_token = 0;

    get_string(E, sec, key, "0,0 100,0", en, 256);
    en[256] = 0;
    s[0] = 0;

    while (en[i] != 0) {
        if (en[i] == ',') {
            if (!have_token) E->notes |= DS_NOTE_TOKEN_START;
            scan_into(E, s, envpts_index(env, 0, ep));
            o = 0;
        } else if (en[i] == ' ') {
            if (!have_token) E->notes |= DS_NOTE_TOKEN_START;
            scan_into(E, s, envpts_index(env, 1, ep));
            o = 0;
            ep++;
        } else {
            s[o] = en[i];
            o++;
            s[o] = 0;
            have_token = 1;
        }
        i++;
    }
    if (!have_token) E->notes |= DS_NOTE_TOKEN_START;
    scan_into(E, s, envpts_index(env, 1, ep));
    *img_ptr(E, envpts_index(env, 0, ep + 1)) = -1.f;
    envData(env, MAX) = img_read(E, envpts_index(env, 0, ep));
}

/* LongestEnv (10001010). The running maximum l stays in a register; it only
 * ever takes float values. l / 1200 was compiled as l * (-1/1200 as float),
 * truncated with _ftol and negated again. */
static int32_t LongestEnv(engine* E)
{
    double l = 0.0;
    for (long e = 1; e < 7; e++) {
        long eon = e - 1;
        if (eon > 2) eon = eon - 1;
        long p = 0;
        for (;;) {
            long idx = envpts_index(e, 0, p + 1);
            if (idx >= IMG_WORDS) { E->notes |= DS_NOTE_MEMORY_BEYOND; break; }
            if (!((double)img_read(E, idx) >= 0.0)) break;
            p++;
        }
        float m = (float)((double)timestretch * (double)img_read(E, envpts_index(e, 0, p)));
        envData(e, MAX) = m;
        if (E->chkOn[eon] == 1) if ((double)m > l) l = (double)m;
    }
    int32_t k = vc6_ftol(l * (double)-0x1.b4e81cp-11f); /* -1/1200 as float (1000E110) */
    return (int32_t)((uint32_t)(2 - k) * 1200u);
}

/* LoudestEnv (10001110). Returns the register value loudest * loudest. */
static double LoudestEnv(engine* E)
{
    double loudest = 0.0;
    for (int i = 0; i < 5; i++)
        if (E->chkOn[i] == 1)
            if ((double)sliLev(i) > loudest) loudest = (double)(float)sliLev(i);
    return loudest * loudest;
}

/* UpdateEnv (10001150). this level and dT stay in registers. */
static void UpdateEnv(engine* E, int e, long t)
{
    float pnt = envData(e, PNT);
    long i1 = vc6_ftol((double)pnt + 1.0);
    double next = (double)timestretch * (double)img_read(E, envpts_index(e, 0, i1));
    envData(e, NEXTT) = (float)next;
    if (!(next >= 0.0)) envData(e, NEXTT) = (float)((double)timestretch * (double)K_HOLD);
    long i0 = vc6_ftol((double)pnt);
    double level = (double)img_read(E, envpts_index(e, 1, i0)) * (double)K_0_01;
    envData(e, ENV) = (float)level;
    double endEnv = (double)img_read(E, envpts_index(e, 1, i1)) * (double)K_0_01;
    double dT = (double)envData(e, NEXTT) - (double)t;
    if (!(dT >= 1.0)) dT = 1.0;
    envData(e, dENV) = (float)((endEnv - level) / dT);
    envData(e, PNT) = (float)((double)envData(e, PNT) + 1.0);
}

/* waveform (10001350) multiplied by m. Form 0 returns the raw 64-bit fsin
 * result, which every caller multiplies by a 53-bit value first, so the
 * product is formed in ds87_sin_mul. The other forms return 53-bit values. */
static double waveform_mul(engine* E, float ph, long form, double m)
{
    double w;
    switch (form) {
    case 0:  /* sine (10001364) */
        return ds87_sin_mul(vc6_fmod((double)ph, TWOPI_D), m);
    case 1: { /* sine^2 (10001376): fabs(2 * sin(ph / 2)) - 1 */
        double s = ds87_sin(vc6_fmod((double)ph * 0.5, TWOPI_D));
        w = fabs(s + s) - 1.0;
        break;
    }
    case 2: { /* triangle (10001398) */
        if (!((double)ph >= (double)TWOPI_F)) {
            /* while(ph<TwoPi) ph+=TwoPi; - added in a register, stored once */
            double p = ph;
            if (!isfinite(p) || p < -1e9) {
                /* The original loops forever (NaN, -inf) or for minutes. */
                E->notes |= DS_NOTE_HANG;
                p = isfinite(p) ? fmod(p, TWOPI_D) + TWOPI_D : TWOPI_D;
            }
            do p += (double)TWOPI_F; while (!(p >= (double)TWOPI_F));
            ph = (float)p;
        }
        w = (double)K_TWO_PI_R * vc6_fmod((double)ph, TWOPI_D) - 1.0;
        if (w > 1.0) w = 2.0 - w;
        break;
    }
    case 3: { /* sawtooth (100013F3) */
        int32_t k = vc6_ftol((double)ph * (double)K_INV_TWOPI);
        w = ((double)ph - (double)k * (double)TWOPI_F) * (double)K_INV_PI - 1.0;
        break;
    }
    default: /* square (10001421) */
        w = ds87_sin(vc6_fmod((double)ph, TWOPI_D)) > 0.0 ? 1.0 : -1.0;
        break;
    }
    return w * m;
}

/* ---- ds2wav (10001590) ---------------------------------------------------- */
static int render(engine* E, const ds_factors* fac, ds_sound* out)
{
    char sec[32];
    char ver[32] = {0};
    char comment[256] = {0};
    int commentLen = 0;

    long Length, tpos, tplus, t, i, j;
    float x0 = 0.f, x1 = 0.f, x2 = 0.f;
    float MasterTune;
    int32_t MainFilter, HighPass;

    int32_t NON, NT, TON, DiON, TDroop = 0, DStep;
    float a, b = 0.f, c = 0.f, d = 0.f, g, TT = 0.f, TL, F1, F2;
    float TphiStart = 0.f, Tphi, TDroopRate, ddF, DAtten, DGain;

    int32_t BON, BON2, BFStep, BFStep2;
    float BdF = 0.f, BdF2 = 0.f, BPhi, BPhi2, BF, BF2, BQ, BQ2, BL, BL2;

    int32_t OON, OF1Sync = 0, OF2Sync = 0, OMode, OW1, OW2;
    float Ophi1, Ophi2, OF1, OF2, OL, Ot = 0.f, OBal1, OBal2, ODrive;
    float OcF, OcQ, Oc[6][2];
    float Oc0 = 0.f, Oc1 = 0.f, Oc2 = 0.f;

    float MFres, MFin = 0.f, MFout = 0.f;

    double mem_t = 1.0, mem_o = 1.0, mem_n = 1.0, mem_b = 1.0, mem_tune = 0.0, mem_time = 1.0;
    if (fac) {
        mem_t = fac->t; mem_o = fac->o; mem_n = fac->n; mem_b = fac->b;
        mem_tune = fac->tune; mem_time = fac->time;
    }

    /* version */
    strcpy(sec, "General");
    get_string(E, sec, "Version", "", ver, sizeof(ver));
    ver[9] = 0;
    if (lstrcmpA(ver, "DrumSynth") != 0) return DS_ERR_INPUT;
    if (ver[11] != '1' && ver[11] != '2') return DS_ERR_VERSION;

    /* master parameters */
    get_string(E, sec, "Comment", "", comment, sizeof(comment));
    while ((comment[commentLen] != 0) && (commentLen < 254)) commentLen++;
    if (commentLen == 0) { comment[0] = 32; comment[1] = 0; commentLen = 1; }
    comment[commentLen + 1] = 0;
    commentLen++;
    if ((commentLen % 2) == 1) commentLen++;

    /* 100017AB: Stretch * mem_time * 0.01f; the 0.2 test uses the register */
    {
        double ts = (double)get_float(E, sec, "Stretch", 100.f) * mem_time * (double)K_0_01;
        timestretch = (float)ts;
        if (!(ts >= (double)K_0_2F)) timestretch = K_0_2F;
        else if ((double)timestretch > 10.0) timestretch = 10.f;
    }

    DGain = 1.0f;
    DGain = (float)epow(E, 10.0, (double)get_float(E, sec, "Level", 0.f) * 0.05);

    MasterTune = get_float(E, sec, "Tuning", 0.f);
    MasterTune = (float)epow(E, K_SEMITONE, (double)MasterTune + mem_tune);
    MainFilter = (int32_t)(2u * get_int(E, sec, "Filter", 0));
    /* the product 0.0101f * Resonance goes to pow unrounded */
    MFres = (float)epow(E, (double)get_float(E, sec, "Resonance", 0.f) * (double)K_0_0101, 0.5);

    HighPass = (int32_t)get_int(E, sec, "HighPass", 0);
    getEnv(E, 7, sec, "FilterEnv");

    /* noise */
    strcpy(sec, "Noise");
    E->chkOn[1] = (int32_t)get_int(E, sec, "On", 0);
    sliLev(1) = (int32_t)get_int(E, sec, "Level", 0);
    NT = (int32_t)get_int(E, sec, "Slope", 0);
    getEnv(E, 2, sec, "Envelope");
    NON = E->chkOn[1];
    {
        /* NL stays in a register */
        double NL = (double)(int32_t)((uint32_t)sliLev(1) * (uint32_t)sliLev(1)) * mem_n;
        double nt = (double)NT;
        double neg = (double)(int32_t)(0u - (uint32_t)NT);
        if (NT < 0) {
            a = (float)(nt * (double)K_1_105 + 1.0);
            d = (float)(neg * (double)K_1_105);
            g = (float)((nt * nt * (double)K_0_0005 + 1.0) * NL);
        } else {
            a = 1.f;
            b = (float)(neg * (double)K_0_02);
            c = (float)(fabs(nt) * (double)K_0_01);
            g = (float)NL;
        }
    }
    vc6_srand(&E->rnd, 1);

    /* tone */
    strcpy(sec, "Tone");
    E->chkOn[0] = (int32_t)get_int(E, sec, "On", 0);
    TON = E->chkOn[0];
    sliLev(0) = (int32_t)get_int(E, sec, "Level", 128);
    TL = (float)((double)(int32_t)((uint32_t)sliLev(0) * (uint32_t)sliLev(0)) * mem_t);
    getEnv(E, 1, sec, "Envelope");
    {
        double f1 = (double)get_float(E, sec, "F1", 200.f) * (double)MasterTune * (double)K_TWOPI_FS;
        F1 = (float)f1;
        if (!(fabs(f1) >= K_0_001D)) F1 = K_0_001F;
    }
    F2 = (float)((double)get_float(E, sec, "F2", 120.f) * (double)MasterTune * (double)K_TWOPI_FS);
    TDroopRate = get_float(E, sec, "Droop", 0.f);
    if ((double)TDroopRate > 0.0) {
        TDroopRate = (float)(epow(E, 10.0, ((double)TDroopRate - 20.0) * (double)K_1_30)
                             * -4.0 / (double)envData(1, MAX));
        TDroop = 1;
        F2 = (float)ds87_droop_f2(F1, F2, envData(1, MAX), TDroopRate);
        ddF = (float)((double)F1 - (double)F2);
    } else {
        ddF = (float)((double)F2 - (double)F1);
    }
    Tphi = (float)((double)get_float(E, sec, "Phase", 90.f) * (double)K_DEG);

    /* overtones */
    strcpy(sec, "Overtones");
    E->chkOn[2] = (int32_t)get_int(E, sec, "On", 0);
    OON = E->chkOn[2];
    sliLev(2) = (int32_t)get_int(E, sec, "Level", 128);
    OL = (float)((double)(int32_t)((uint32_t)sliLev(2) * (uint32_t)sliLev(2)) * mem_o);
    getEnv(E, 3, sec, "Envelope1");
    getEnv(E, 4, sec, "Envelope2");
    OMode = (int32_t)get_int(E, sec, "Method", 2);
    OF1 = (float)((double)get_float(E, sec, "F1", 200.f) * (double)MasterTune * (double)K_TWOPI_FS);
    OF2 = (float)((double)get_float(E, sec, "F2", 120.f) * (double)MasterTune * (double)K_TWOPI_FS);
    OW1 = (int32_t)get_int(E, sec, "Wave1", 0);
    OW2 = (int32_t)get_int(E, sec, "Wave2", 0);
    {
        /* (float)GetPrivateProfileInt: UINT, converted unsigned (fild qword) */
        double p = (double)get_int(E, sec, "Param", 50);
        OBal2 = (float)p;
        ODrive = (float)(epow(E, p, 3.0) / epow(E, 50.0, 3.0));
    }
    OBal2 = (float)((double)OBal2 * (double)K_0_01);
    OBal1 = (float)(1.0 - (double)OBal2);
    Ophi1 = Tphi;
    Ophi2 = Tphi;
    if (MainFilter == 0) MainFilter = (int32_t)get_int(E, sec, "Filter", 0);
    if (get_int(E, sec, "Track1", 0) == 1 && TON == 1) { OF1Sync = 1; OF1 = (float)((double)OF1 / (double)F1); }
    if (get_int(E, sec, "Track2", 0) == 1 && TON == 1) { OF2Sync = 1; OF2 = (float)((double)OF2 / (double)F1); }

    {
        /* 808 cymbal set-up (10001DC3). OcA, Ocf1 and Ocf2 stay in registers;
         * the source's OcA *= 1 + 4 * OBal1 is never used and was dropped. */
        double OcA = (double)OBal1 * (double)OBal1 + (double)K_0_28;
        OcQ = (float)(OcA * OcA);
        OcF = (float)(((double)K_1_8 - (double)OcQ * (double)K_0_7) * (double)K_0_92);
        double Ocf1 = (double)TWOPI_F / (double)OF1;
        double Ocf2 = (double)TWOPI_F / (double)OF2;
        double dOc = Ocf2 - Ocf1;
        for (i = 0; i < 6; i++) {
            float v = (float)((double)i * dOc * (double)K_0_2F + Ocf1);
            Oc[i][0] = v;
            Oc[i][1] = v;
        }
    }

    /* noise band 1 */
    strcpy(sec, "NoiseBand");
    E->chkOn[3] = (int32_t)get_int(E, sec, "On", 0);
    BON = E->chkOn[3];
    sliLev(3) = (int32_t)get_int(E, sec, "Level", 128);
    BL = (float)((double)(int32_t)((uint32_t)sliLev(3) * (uint32_t)sliLev(3)) * mem_b);
    BF = (float)((double)get_float(E, sec, "F", 1000.f) * (double)MasterTune * (double)K_TWOPI_FS);
    BPhi = K_BPHI0;
    getEnv(E, 5, sec, "Envelope");
    BFStep = (int32_t)get_int(E, sec, "dF", 50);
    {
        double x = (double)BFStep;
        BQ = (float)(x * x / ((double)10000.f - (sqrt((double)BF) - (double)K_0_19) * (double)6600.f));
        BFStep = 1 + vc6_ftol(((double)40.f - x * (double)K_0_4F) / ((double)BF + (double)BQ + 1.0));
    }

    /* noise band 2: the same, but the source used double constants here */
    strcpy(sec, "NoiseBand2");
    E->chkOn[4] = (int32_t)get_int(E, sec, "On", 0);
    BON2 = E->chkOn[4];
    sliLev(4) = (int32_t)get_int(E, sec, "Level", 128);
    BL2 = (float)((double)(int32_t)((uint32_t)sliLev(4) * (uint32_t)sliLev(4)) * mem_b);
    BF2 = (float)((double)get_float(E, sec, "F", 1000.f) * (double)MasterTune * (double)K_TWOPI_FS);
    BPhi2 = K_BPHI0;
    getEnv(E, 6, sec, "Envelope");
    BFStep2 = (int32_t)get_int(E, sec, "dF", 50);
    {
        double x = (double)BFStep2;
        BQ2 = (float)(x * x / ((double)10000.f - (sqrt((double)BF2) - (double)K_0_19) * (double)6600.f));
        BFStep2 = 1 + vc6_ftol((40.0 - x * K_0_4D) / ((double)BF2 + (double)BQ2 + 1.0));
    }

    /* distortion */
    strcpy(sec, "Distortion");
    E->chkOn[5] = (int32_t)get_int(E, sec, "On", 0);
    DiON = E->chkOn[5];
    DStep = (int32_t)(1u + get_int(E, sec, "Rate", 0));
    if (DStep == 7) DStep = 20;
    else if (DStep == 6) DStep = 10;
    else if (DStep == 5) DStep = 8;

    set_clip(E, 32700);
    DAtten = 1.0f;
    if (DiON == 1) {
        double at = (double)vc6_ftol_short(LoudestEnv(E)) * (double)DGain;
        if (at > (double)32700.f) set_clip(E, 32700);
        else set_clip(E, vc6_ftol_short(at));
        /* Bits and Clipping (UINT) are converted unsigned (fild qword) */
        DAtten = (float)epow(E, 2.0, 2.0 * (double)get_int(E, sec, "Bits", 0));
        DGain = (float)(epow(E, 10.0, (double)get_int(E, sec, "Clipping", 0) * 0.05)
                        * (double)DAtten * (double)DGain);
    }

    /* prepare envelopes */
    for (i = 1; i < 8; i++) { envData(i, NEXTT) = 0; envData(i, PNT) = 0; }
    Length = LongestEnv(E);

    /* The DLL allocates 2 * Length + 1280 bytes in a 32-bit process: lengths
     * it could not allocate fail with result 3. */
    if (Length <= 0 || (uint32_t)(2u * (uint32_t)Length + 1280u) > 0x40000000u) return DS_ERR_OUTPUT;
    int16_t* wave = malloc(2 * (size_t)Length + 1280);
    if (!wave) return DS_ERR_OUTPUT;
    E->m.i[IMG_WAVEWORDS] = 0;

    if (DStep <= 0) E->notes |= DS_NOTE_HANG;
    if ((BON == 1 && BFStep == 0) || (BON2 == 1 && BFStep2 == 0)) E->notes |= DS_NOTE_HANG;

    /* generate */
    tpos = 0;
    while (tpos < Length) {
        tplus = tpos + 1199;

        if (NON == 1) { /* noise (100023C6) */
            for (t = tpos; t <= tplus; t++) {
                if ((double)t < (double)envData(2, NEXTT))
                    envData(2, ENV) = (float)((double)envData(2, dENV) + (double)envData(2, ENV));
                else UpdateEnv(E, 2, t);
                x2 = x1;
                x1 = x0;
                x0 = (float)((double)vc6_rand(&E->rnd) * (double)K_RANDMAX2 - 1.0);
                TT = (float)((((double)a * x0 + (double)TT * d) + (double)c * x2) + (double)b * x1);
                DF(t - tpos) = (float)((double)envData(2, ENV) * (double)g * (double)TT);
            }
            if ((double)t >= (double)envData(2, MAX)) NON = 0;
        } else for (j = 0; j < 1200; j++) DF(j) = 0.f;

        if (TON == 1) { /* tone (100024F8) */
            TphiStart = Tphi;
            if (TDroop == 1) {
                for (t = tpos; t <= tplus; t++)
                    phi(t - tpos) = (float)ds87_droop_phi((double)t, TDroopRate, ddF, F2);
            } else {
                for (t = tpos; t <= tplus; t++)
                    phi(t - tpos) = (float)((double)t / (double)envData(1, MAX) * (double)ddF + (double)F1);
            }
            for (t = tpos; t <= tplus; t++) {
                long k = t - tpos;
                if ((double)t < (double)envData(1, NEXTT))
                    envData(1, ENV) = (float)((double)envData(1, dENV) + (double)envData(1, ENV));
                else UpdateEnv(E, 1, t);
                /* the sum goes to fmod unrounded; only the stored Tphi is float */
                double s = (double)Tphi + (double)phi(k);
                Tphi = (float)s;
                DF(k) = (float)(ds87_sin_mul(vc6_fmod(s, TWOPI_D), envData(1, ENV)) * (double)TL + (double)DF(k));
            }
            if ((double)t >= (double)envData(1, MAX)) TON = 0;
        } else for (j = 0; j < 1200; j++) phi(j) = F2;

        if (BON == 1) { /* noise band 1 (1000266E) */
            for (t = tpos; t <= tplus; t++) {
                if ((double)t < (double)envData(5, NEXTT))
                    envData(5, ENV) = (float)((double)envData(5, dENV) + (double)envData(5, ENV));
                else UpdateEnv(E, 5, t);
                if (BFStep != 0 && (t % BFStep) == 0)
                    BdF = (float)((double)vc6_rand(&E->rnd) * (double)K_RANDMAX - 0.5);
                BPhi = (float)(((double)BQ * (double)BdF + (double)BPhi) + (double)BF);
                long k = t - tpos;
                DF(k) = (float)(ds87_cos_mul(vc6_fmod((double)BPhi, TWOPI_D), envData(5, ENV)) * (double)BL + (double)DF(k));
            }
            if ((double)t >= (double)envData(5, MAX)) BON = 0;
        }

        if (BON2 == 1) { /* noise band 2 (1000278F) */
            for (t = tpos; t <= tplus; t++) {
                if ((double)t < (double)envData(6, NEXTT))
                    envData(6, ENV) = (float)((double)envData(6, dENV) + (double)envData(6, ENV));
                else UpdateEnv(E, 6, t);
                if (BFStep2 != 0 && (t % BFStep2) == 0)
                    BdF2 = (float)((double)vc6_rand(&E->rnd) * (double)K_RANDMAX - 0.5);
                BPhi2 = (float)(((double)BQ2 * (double)BdF2 + (double)BPhi2) + (double)BF2);
                long k = t - tpos;
                DF(k) = (float)(ds87_cos_mul(vc6_fmod((double)BPhi2, TWOPI_D), envData(6, ENV)) * (double)BL2 + (double)DF(k));
            }
            if ((double)t >= (double)envData(6, MAX)) BON2 = 0;
        }

        for (t = tpos; t <= tplus; t++) { /* overtones and filter (100028AC) */
            long k = t - tpos;
            if (OON == 1) {
                float tf = (float)t;
                if ((double)t < (double)envData(3, NEXTT))
                    envData(3, ENV) = (float)((double)envData(3, dENV) + (double)envData(3, ENV));
                else if ((double)tf >= (double)envData(3, MAX)) { /* wait for OT2 */
                    envData(3, ENV) = 0;
                    envData(3, dENV) = 0;
                    envData(3, NEXTT) = K_999999;
                } else UpdateEnv(E, 3, t);

                if ((double)tf < (double)envData(4, NEXTT))
                    envData(4, ENV) = (float)((double)envData(4, dENV) + (double)envData(4, ENV));
                else if ((double)tf >= (double)envData(4, MAX)) { /* wait for OT1 */
                    envData(4, ENV) = 0;
                    envData(4, dENV) = 0;
                    envData(4, NEXTT) = K_999999;
                } else UpdateEnv(E, 4, t);

                TphiStart = (float)((double)TphiStart + (double)phi(k));
                if (OF1Sync == 1) Ophi1 = (float)((double)OF1 * (double)TphiStart);
                else Ophi1 = (float)((double)Ophi1 + (double)OF1);
                if (OF2Sync == 1) Ophi2 = (float)((double)OF2 * (double)TphiStart);
                else Ophi2 = (float)((double)Ophi2 + (double)OF2);
                Ot = 0.0f;
                switch (OMode) {
                case 0: /* add (10002A1F) */
                    Ot = (float)(waveform_mul(E, Ophi1, OW1, envData(3, ENV)) * (double)OBal1);
                    Ot = (float)((waveform_mul(E, Ophi2, OW2, envData(4, ENV)) * (double)OBal2 + (double)Ot) * (double)OL);
                    break;
                case 1: { /* FM (10002A78): the modulator is not rounded, the phase is */
                    double m = waveform_mul(E, Ophi2, OW2, envData(4, ENV)) * (double)ODrive;
                    float ph = (float)(m + (double)Ophi1);
                    Ot = (float)(waveform_mul(E, ph, OW1, envData(3, ENV)) * (double)OL);
                    break;
                }
                case 2: { /* RM (10002AC8) */
                    float d8 = (float)((double)ODrive * 0.125);
                    double m = waveform_mul(E, Ophi2, OW2, (double)d8 * (double)envData(4, ENV));
                    Ot = (float)((1.0 - (double)d8) + m);
                    Ot = (float)(waveform_mul(E, Ophi1, OW1, Ot) * (double)envData(3, ENV) * (double)OL);
                    break;
                }
                case 3: { /* 808 cymbal (10002B36) */
                    for (j = 0; j < 6; j++) {
                        float o = (float)((double)Oc[j][0] + 1.0);
                        Oc[j][0] = o;
                        if ((double)o > (double)Oc[j][1]) {
                            Oc[j][0] = (float)((double)o - (double)Oc[j][1]);
                            Ot = (float)((double)envData(3, ENV) * (double)OL);
                        }
                    }
                    double cf = (double)envData(4, ENV) * (double)OcF; /* Ocf1, a register */
                    Oc0 = (float)(cf * (double)Oc1 + (double)Oc0);
                    double q = ((double)Ot + (double)Oc2) - (double)OcQ * (double)Oc1;
                    Oc2 = Ot;
                    Oc1 = (float)((q - (double)Oc0) * cf + (double)Oc1);
                    Ot = Oc1;
                    break;
                }
                }
            }

            if (MainFilter == 1 || MainFilter == 2) { /* 10002BED, 10002CD5 */
                if ((double)t < (double)envData(7, NEXTT))
                    envData(7, ENV) = (float)((double)envData(7, dENV) + (double)envData(7, ENV));
                else UpdateEnv(E, 7, t);
                float MFtmp = envData(7, ENV);
                double fb; /* MFfb stays in a register */
                if ((double)MFtmp > (double)K_0_2F)
                    fb = (double)K_1_001 - epow(E, 10.0, (double)MFtmp - 1.0);
                else
                    fb = (double)K_0_999 - (double)MFtmp * (double)K_0_7824;
                double m = (1.0 / fb + 1.0) * ((double)MFin - (double)MFout) * (double)MFres;
                if (MainFilter == 1) m = m + (double)Ot;                       /* filter overtones */
                else m = (m + (double)DF(k)) + (double)Ot;                     /* filter all */
                MFin = (float)(((double)MFin - m) * fb + m);
                MFout = (float)(((double)MFout - (double)MFin) * fb + (double)MFin);
                if (MainFilter == 1)
                    DF(k) = (float)(((double)MFout - (double)HighPass * (double)Ot) + (double)DF(k));
                else
                    DF(k) = (float)((double)MFout - ((double)Ot + (double)DF(k)) * (double)HighPass);
            } else {
                DF(k) = (float)((double)Ot + (double)DF(k)); /* no filter */
            }
        }

        if (DiON == 1) { /* bit resolution and downsampling (10002E00) */
            for (j = 0; j < 1200; j++)
                DF(j) = (float)((double)vc6_ftol((double)DF(j) / (double)DAtten) * (double)DGain);
            if (DStep > 0) {
                for (j = 0; j < 1200; j += DStep) {
                    /* the sum stays in a register; groups that run past DF[1199]
                     * read and write the memory after it, envpts[0] */
                    double ave = 0.0;
                    long end = j + DStep - 1;
                    for (long jj = j; jj <= end; jj++) ave = ave + (double)img_read(E, IMG_DF + jj);
                    float av = (float)(ave / (double)DStep);
                    for (long jj = j; jj <= end; jj++) *img_ptr(E, IMG_DF + jj) = av;
                }
            }
        } else {
            for (j = 0; j < 1200; j++) DF(j) = (float)((double)DGain * (double)DF(j));
        }

        { /* clipping and output (10002EA0) */
            int16_t clip = get_clip(E);
            for (j = 0; j < 1200; j++) {
                float v = DF(j);
                int16_t s;
                if (!((double)clip >= (double)v)) s = clip;              /* also NaN */
                else if ((double)v < -(double)clip) s = (int16_t)(uint16_t)(0u - (uint16_t)clip);
                else s = vc6_ftol_short(v);
                wave[E->m.i[IMG_WAVEWORDS]] = s;
                E->m.i[IMG_WAVEWORDS]++;
            }
        }
        tpos = tpos + 1200;
    }

    out->samples = wave;
    out->length = Length;
    memcpy(out->comment, comment, sizeof(comment));
    out->comment_length = commentLen;
    return DS_OK;
}

int ds_render(const ds_source* source, const ds_factors* factors, ds_sound* out)
{
    memset(out, 0, sizeof(*out));
    /* Everything starts at zero, like the DLL's globals after loading. */
    engine* E = calloc(1, sizeof(engine));
    if (!E) return DS_ERR_OUTPUT;
    E->src = source;
    int r = render(E, factors, out);
    out->notes = E->notes;
    free(E);
    return r;
}

void ds_sound_free(ds_sound* sound)
{
    if (!sound) return;
    free(sound->samples);
    sound->samples = NULL;
    sound->length = 0;
}

/* ---- Test entries (tools/probes/probe64.c) -------------------------------- */

/* A double as an x87 80-bit value (10 bytes, little endian). */
void ds_double_to_80(double d, unsigned char out[10])
{
    uint64_t b;
    memcpy(&b, &d, 8);
    unsigned sign = (unsigned)(b >> 63);
    unsigned e = (unsigned)((b >> 52) & 0x7FF);
    uint64_t m = b & 0xFFFFFFFFFFFFFull;
    uint64_t mant;
    unsigned ex;
    if (e == 0 && m == 0) { mant = 0; ex = 0; }
    else if (e == 0x7FF) { mant = 0x8000000000000000ull | (m << 11); ex = 0x7FFF; }
    else if (e == 0) {
        int shift = 0;
        while (!(m & (1ull << 52))) { m <<= 1; shift++; }
        mant = m << 11;
        ex = (unsigned)(16383 - 1022 - shift);
    } else { mant = 0x8000000000000000ull | (m << 11); ex = e - 1023 + 16383; }
    memcpy(out, &mant, 8);
    uint16_t se = (uint16_t)((sign << 15) | ex);
    memcpy(out + 8, &se, 2);
}

/* waveform(ph, form) as the DLL returns it in st(0): the raw fsin result for
 * form 0, a 53-bit value for the others. */
void ds_test_waveform80(float ph, long form, unsigned char out[10])
{
    static engine dummy;
    if (form == 0) ds87_test_sin80(vc6_fmod((double)ph, TWOPI_D), out);
    else ds_double_to_80(waveform_mul(&dummy, ph, form, 1.0), out);
}
