/* ds_vc6_fltin.c - Visual C++ 6's conversion of text to float, as used by
 * sscanf("%f") in the original ds2wav.dll, transcribed from the DLL's
 * machine code:
 *
 *   _fassign (10003A8F) -> _atoflt (100099F7)
 *     -> __strgtold12 (1000C007): text to a 12-byte "long double" with an
 *        80-bit mantissa, using
 *          __mtold12 (1000BF40): the digits as a 96-bit integer,
 *          __multtenpow12 (1000D4CA) and __ld12mul (1000D2AA): scaling by
 *          powers of ten from tables, with VC6's truncated 80-bit multiply;
 *     -> _ld12tof (100099B4) -> _ld12cvt (10009832) with _RoundMan
 *        (100096D7): rounding the 80-bit mantissa to float.
 *
 * The results are not always the correctly rounded float. In particular
 * _RoundMan rounds up only if the bit after the last kept bit is set and
 * some bit *two or more* places further on is set, because its
 * "_IsZeroTail" check (10009638) starts one bit too late. So an exact tie
 * rounds down, and so does a value whose only extra bit is the one right
 * after the rounding bit. Together with the truncation in __ld12mul this
 * decides the last bit of numbers that lie very close to a float rounding
 * boundary. tools/probes compares this file with the DLL's own sscanf.
 *
 * Layout of the 12-byte value (little endian): bytes 0-9 mantissa (bit 79,
 * the top bit of byte 9, is the integer bit), bytes 10-11 sign and biased
 * exponent (bias 0x3FFF). */
#include <stdint.h>
#include <string.h>

#include "ds_vc6.h"

typedef struct { uint8_t b[12]; } ld12;

static uint16_t rd16(const uint8_t* p) { return (uint16_t)(p[0] | (p[1] << 8)); }
static uint32_t rd32(const uint8_t* p) { return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24); }
static void wr16(uint8_t* p, uint16_t v) { p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8); }
static void wr32(uint8_t* p, uint32_t v) { p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8); p[2] = (uint8_t)(v >> 16); p[3] = (uint8_t)(v >> 24); }

/* __addl (1000BE66): *sum = a + b, returns the carry. */
static int addl(uint32_t a, uint32_t b, uint32_t* sum)
{
    uint32_t r = a + b;
    *sum = r;
    return (r < a || r < b) ? 1 : 0;
}

/* __add_12 (1000BE87): 96-bit add of the three dwords LO, MED, HI. */
static void add_12(ld12* x, const ld12* y)
{
    uint32_t lo = rd32(x->b), med = rd32(x->b + 4), hi = rd32(x->b + 8), r;
    if (addl(lo, rd32(y->b), &r)) {
        uint32_t m2;
        if (addl(med, 1, &m2)) hi++;
        med = m2;
    }
    lo = r;
    if (addl(med, rd32(y->b + 4), &r)) hi++;
    med = r;
    addl(hi, rd32(y->b + 8), &hi);
    wr32(x->b, lo); wr32(x->b + 4, med); wr32(x->b + 8, hi);
}

/* __shl_12 (1000BEE5) and __shr_12 (1000BF13): 96-bit shifts by one. */
static void shl_12(ld12* x)
{
    uint32_t lo = rd32(x->b), med = rd32(x->b + 4), hi = rd32(x->b + 8);
    wr32(x->b, lo << 1);
    wr32(x->b + 4, (med << 1) | (lo >> 31));
    wr32(x->b + 8, (hi << 1) | (med >> 31));
}

static void shr_12(ld12* x)
{
    uint32_t lo = rd32(x->b), med = rd32(x->b + 4), hi = rd32(x->b + 8);
    wr32(x->b + 4, (med >> 1) | (hi << 31));
    wr32(x->b, (lo >> 1) | (med << 31));
    wr32(x->b + 8, hi >> 1);
}

/* __mtold12 (1000BF40): digit values (0..9, one may be 10, see below) to a
 * normalized 12-byte value. */
static void mtold12(const uint8_t* man, unsigned len, ld12* x)
{
    uint16_t expn = 0x404E; /* LD_BIASM1 + 80 */
    memset(x->b, 0, 12);
    for (; len > 0; len--, man++) {
        ld12 tmp = *x;
        shl_12(x);
        shl_12(x);
        add_12(x, &tmp);
        shl_12(x);                       /* x * 10 */
        memset(tmp.b, 0, 12);
        wr32(tmp.b, (uint32_t)(int32_t)(int8_t)*man);
        add_12(x, &tmp);
    }
    while (rd32(x->b + 8) == 0) {
        uint32_t med = rd32(x->b + 4), lo = rd32(x->b);
        wr32(x->b + 8, med >> 16);
        wr32(x->b + 4, (med << 16) | (lo >> 16));
        wr32(x->b, lo << 16);
        expn = (uint16_t)(expn + 0xFFF0);
    }
    while (!(rd32(x->b + 8) & 0x8000)) {
        shl_12(x);
        expn = (uint16_t)(expn + 0xFFFF);
    }
    wr16(x->b + 10, expn);
}

/* __ld12mul (1000D2AA): *px *= *py with VC6's partial-product multiply:
 * only the products of 16-bit mantissa words whose positions add up to the
 * top half are formed, and a carry is added to one 16-bit word only. The
 * result is rounded to 80 bits half to even on its low 16 bits. */
static void ld12mul(ld12* px, const ld12* py)
{
    uint16_t ex = rd16(px->b + 10), ey = rd16(py->b + 10);
    uint16_t sign = (uint16_t)((ex ^ ey) & 0x8000);
    ex &= 0x7FFF;
    ey &= 0x7FFF;
    uint32_t expsum = (uint32_t)ex + ey; /* [ebp+8], compared as a 16-bit word */
    int sticky = 0;
    uint8_t t[12];                       /* tempman, ebp-24h */
    memset(t, 0, 12);

    if (ex >= 0x7FFF || ey >= 0x7FFF || (uint16_t)expsum > 0xBFFD) goto overflow;
    if ((uint16_t)expsum <= 0x3FBF) { memset(px->b, 0, 12); return; }
    if (ex == 0) {
        expsum++;
        if ((rd32(px->b + 8) & 0x7FFFFFFF) == 0 && rd32(px->b + 4) == 0 && rd32(px->b) == 0) {
            wr16(px->b + 10, 0);
            return;
        }
    }
    if (ey == 0) {
        expsum++;
        if ((rd32(py->b + 8) & 0x7FFFFFFF) == 0 && rd32(py->b + 4) == 0 && rd32(py->b) == 0) {
            memset(px->b, 0, 12);
            return;
        }
    }

    for (int i = 0, n = 5; n > 0; i++, n--) {
        int r = 4 + 2 * i;               /* byte offset of the carry word */
        for (int k = 0; k < n; k++) {
            uint32_t prod = (uint32_t)rd16(px->b + 2 * (i + k)) * rd16(py->b + 8 - 2 * k);
            uint32_t sum;
            if (addl(rd32(t + r - 4), prod, &sum)) {
                wr32(t + r - 4, sum);
                wr16(t + r, (uint16_t)(rd16(t + r) + 1));
            } else {
                wr32(t + r - 4, sum);
            }
        }
    }

    expsum += 0xC002;
    if ((int16_t)expsum > 0) {
        while (!(t[11] & 0x80)) {
            shl_12((ld12*)t);
            expsum += 0xFFFF;
            if (!((int16_t)expsum > 0)) break;
        }
    }
    if (!((int16_t)expsum > 0)) {
        expsum += 0xFFFF;
        if ((int16_t)expsum < 0) {
            int n = -(int16_t)expsum;
            expsum += (uint32_t)n;
            for (; n > 0; n--) {
                if (t[0] & 1) sticky++;
                shr_12((ld12*)t);
            }
            if (sticky) t[0] |= 1;
        }
    }
    if (rd16(t) > 0x8000 || (rd32(t) & 0x1FFFF) == 0x18000) {
        if (rd32(t + 2) == 0xFFFFFFFFu) {
            wr32(t + 2, 0);
            if (rd32(t + 6) == 0xFFFFFFFFu) {
                wr32(t + 6, 0);
                if (rd16(t + 10) == 0xFFFF) {
                    expsum++;
                    wr16(t + 10, 0x8000);
                } else {
                    wr16(t + 10, (uint16_t)(rd16(t + 10) + 1));
                }
            } else {
                wr32(t + 6, rd32(t + 6) + 1);
            }
        } else {
            wr32(t + 2, rd32(t + 2) + 1);
        }
    }
    if ((uint16_t)expsum >= 0x7FFF) goto overflow;
    wr16(px->b, rd16(t + 2));
    wr32(px->b + 2, rd32(t + 4));
    wr32(px->b + 6, rd32(t + 8));
    wr16(px->b + 10, (uint16_t)((uint16_t)expsum | sign));
    return;

overflow:
    wr32(px->b + 4, 0);
    wr32(px->b, 0);
    wr32(px->b + 8, sign ? 0xFFFF8000u : 0x7FFF8000u);
}

/* _pow10pos and _pow10neg (DLL .data 10012110 and 10012270): 10^1..10^7,
 * 10^8..10^56 in steps of 8, 10^64..10^448, 10^512..10^3584, 10^4096, and
 * their reciprocals, each as 12 bytes. */
static const uint8_t pow10pos[29][12] = {
    {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xa0,0x02,0x40},
    {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xc8,0x05,0x40},
    {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xfa,0x08,0x40},
    {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x9c,0x0c,0x40},
    {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x50,0xc3,0x0f,0x40},
    {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x24,0xf4,0x12,0x40},
    {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0x96,0x98,0x16,0x40},
    {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x20,0xbc,0xbe,0x19,0x40},
    {0x00,0x00,0x00,0x00,0x00,0x04,0xbf,0xc9,0x1b,0x8e,0x34,0x40},
    {0x00,0x00,0x00,0xa1,0xed,0xcc,0xce,0x1b,0xc2,0xd3,0x4e,0x40},
    {0x20,0xf0,0x9e,0xb5,0x70,0x2b,0xa8,0xad,0xc5,0x9d,0x69,0x40},
    {0xd0,0x5d,0xfd,0x25,0xe5,0x1a,0x8e,0x4f,0x19,0xeb,0x83,0x40},
    {0x71,0x96,0xd7,0x95,0x43,0x0e,0x05,0x8d,0x29,0xaf,0x9e,0x40},
    {0xf9,0xbf,0xa0,0x44,0xed,0x81,0x12,0x8f,0x81,0x82,0xb9,0x40},
    {0xbf,0x3c,0xd5,0xa6,0xcf,0xff,0x49,0x1f,0x78,0xc2,0xd3,0x40},
    {0x6f,0xc6,0xe0,0x8c,0xe9,0x80,0xc9,0x47,0xba,0x93,0xa8,0x41},
    {0xbc,0x85,0x6b,0x55,0x27,0x39,0x8d,0xf7,0x70,0xe0,0x7c,0x42},
    {0xbc,0xdd,0x8e,0xde,0xf9,0x9d,0xfb,0xeb,0x7e,0xaa,0x51,0x43},
    {0xa1,0xe6,0x76,0xe3,0xcc,0xf2,0x29,0x2f,0x84,0x81,0x26,0x44},
    {0x28,0x10,0x17,0xaa,0xf8,0xae,0x10,0xe3,0xc5,0xc4,0xfa,0x44},
    {0xeb,0xa7,0xd4,0xf3,0xf7,0xeb,0xe1,0x4a,0x7a,0x95,0xcf,0x45},
    {0x65,0xcc,0xc7,0x91,0x0e,0xa6,0xae,0xa0,0x19,0xe3,0xa3,0x46},
    {0x0d,0x65,0x17,0x0c,0x75,0x81,0x86,0x75,0x76,0xc9,0x48,0x4d},
    {0x58,0x42,0xe4,0xa7,0x93,0x39,0x3b,0x35,0xb8,0xb2,0xed,0x53},
    {0x4d,0xa7,0xe5,0x5d,0x3d,0xc5,0x5d,0x3b,0x8b,0x9e,0x92,0x5a},
    {0xff,0x5d,0xa6,0xf0,0xa1,0x20,0xc0,0x54,0xa5,0x8c,0x37,0x61},
    {0xd1,0xfd,0x8b,0x5a,0x8b,0xd8,0x25,0x5d,0x89,0xf9,0xdb,0x67},
    {0xaa,0x95,0xf8,0xf3,0x27,0xbf,0xa2,0xc8,0x5d,0xdd,0x80,0x6e},
    {0x4c,0xc9,0x9b,0x97,0x20,0x8a,0x02,0x52,0x60,0xc4,0x25,0x75},
};

static const uint8_t pow10neg[29][12] = {
    {0xcd,0xcc,0xcd,0xcc,0xcc,0xcc,0xcc,0xcc,0xcc,0xcc,0xfb,0x3f},
    {0x71,0x3d,0x0a,0xd7,0xa3,0x70,0x3d,0x0a,0xd7,0xa3,0xf8,0x3f},
    {0x5a,0x64,0x3b,0xdf,0x4f,0x8d,0x97,0x6e,0x12,0x83,0xf5,0x3f},
    {0xc3,0xd3,0x2c,0x65,0x19,0xe2,0x58,0x17,0xb7,0xd1,0xf1,0x3f},
    {0xd0,0x0f,0x23,0x84,0x47,0x1b,0x47,0xac,0xc5,0xa7,0xee,0x3f},
    {0x40,0xa6,0xb6,0x69,0x6c,0xaf,0x05,0xbd,0x37,0x86,0xeb,0x3f},
    {0x33,0x3d,0xbc,0x42,0x7a,0xe5,0xd5,0x94,0xbf,0xd6,0xe7,0x3f},
    {0xc2,0xfd,0xfd,0xce,0x61,0x84,0x11,0x77,0xcc,0xab,0xe4,0x3f},
    {0x2f,0x4c,0x5b,0xe1,0x4d,0xc4,0xbe,0x94,0x95,0xe6,0xc9,0x3f},
    {0x92,0xc4,0x53,0x3b,0x75,0x44,0xcd,0x14,0xbe,0x9a,0xaf,0x3f},
    {0xde,0x67,0xba,0x94,0x39,0x45,0xad,0x1e,0xb1,0xcf,0x94,0x3f},
    {0x24,0x23,0xc6,0xe2,0xbc,0xba,0x3b,0x31,0x61,0x8b,0x7a,0x3f},
    {0x61,0x55,0x59,0xc1,0x7e,0xb1,0x53,0x7c,0x12,0xbb,0x5f,0x3f},
    {0xd7,0xee,0x2f,0x8d,0x06,0xbe,0x92,0x85,0x15,0xfb,0x44,0x3f},
    {0x24,0x3f,0xa5,0xe9,0x39,0xa5,0x27,0xea,0x7f,0xa8,0x2a,0x3f},
    {0x7d,0xac,0xa1,0xe4,0xbc,0x64,0x7c,0x46,0xd0,0xdd,0x55,0x3e},
    {0x63,0x7b,0x06,0xcc,0x23,0x54,0x77,0x83,0xff,0x91,0x81,0x3d},
    {0x91,0xfa,0x3a,0x19,0x7a,0x63,0x25,0x43,0x31,0xc0,0xac,0x3c},
    {0x21,0x89,0xd1,0x38,0x82,0x47,0x97,0xb8,0x00,0xfd,0xd7,0x3b},
    {0xdc,0x88,0x58,0x08,0x1b,0xb1,0xe8,0xe3,0x86,0xa6,0x03,0x3b},
    {0xc6,0x84,0x45,0x42,0x07,0xb6,0x99,0x75,0x37,0xdb,0x2e,0x3a},
    {0x33,0x71,0x1c,0xd2,0x23,0xdb,0x32,0xee,0x49,0x90,0x5a,0x39},
    {0xa6,0x87,0xbe,0xc0,0x57,0xda,0xa5,0x82,0xa6,0xa2,0xb5,0x32},
    {0xe2,0x68,0xb2,0x11,0xa7,0x52,0x9f,0x44,0x59,0xb7,0x10,0x2c},
    {0x25,0x49,0xe4,0x2d,0x36,0x34,0x4f,0x53,0xae,0xce,0x6b,0x25},
    {0x8f,0x59,0x04,0xa4,0xc0,0xde,0xc2,0x7d,0xfb,0xe8,0xc6,0x1e},
    {0x9e,0xe7,0x88,0x5a,0x57,0x91,0x3c,0xbf,0x50,0x83,0x22,0x18},
    {0x4e,0x4b,0x65,0x62,0xfd,0x83,0x8f,0xaf,0x06,0x94,0x7d,0x11},
    {0xe4,0x2d,0xde,0x9f,0xce,0xd2,0xc8,0x04,0xdd,0xa6,0xd8,0x0a},
};

/* __multtenpow12 (1000D4CA): *x *= 10^pow, three bits of pow at a time.
 * Table entries whose low word is 0x8000 or more were rounded up when the
 * table was made; they are "unrounded" (low mantissa dword - 1) first. */
static void multtenpow12(ld12* x, int pow, int mult12)
{
    const uint8_t (*table)[12] = pow10pos;
    if (pow == 0) return;
    if (pow < 0) { pow = -pow; table = pow10neg; }
    if (!mult12) wr16(x->b, 0);
    int group = -1; /* index of entry 0 of the current group, minus one */
    while (pow) {
        int last3 = pow & 7;
        pow >>= 3;
        if (last3) {
            ld12 m;
            memcpy(m.b, table[group + last3], 12);
            if (rd16(m.b) >= 0x8000) wr32(m.b + 2, rd32(m.b + 2) - 1);
            ld12mul(x, &m);
        }
        group += 7;
    }
}

/* __strgtold12 (1000C007) with mult12 = scale = decpt = implicit_E = 0, as
 * _atoflt calls it. Returns its flags (1 underflow, 2 overflow, 4 no digits). */
static int vc6_isdigit(uint8_t c) { return c >= '0' && c <= '9'; }

static unsigned strgtold12(ld12* out, const char* str)
{
    enum { S_INIT, S_EAT0L, S_SIGNM, S_GETL, S_GETR, S_POINT, S_E, S_SIGNE, S_EAT0E, S_GETE, S_END, S_PLUSMINUS };
    uint8_t buf[32];
    unsigned manlen = 0;
    int exp_adj = 0, exp_sign = 1, found_digit = 0, found_decpoint = 0, found_exponent = 0;
    int overflow = 0, underflow = 0;
    unsigned flags = 0;
    int32_t exp = 0;
    uint16_t man_sign = 0;
    const uint8_t* p = (const uint8_t*)str;
    const uint8_t* savedp = p;
    int state = S_INIT;
    uint8_t c;

    while (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r') p++;
    while (state != S_END) {
        c = *p++;
        switch (state) {
        case S_INIT:
            if (c >= '1' && c <= '9') { state = S_GETL; p--; }
            else if (c == '.') state = S_POINT;
            else if (c == '+') { state = S_SIGNM; man_sign = 0; }
            else if (c == '-') { state = S_SIGNM; man_sign = 0x8000; }
            else if (c == '0') state = S_EAT0L;
            else { state = S_END; p--; }
            break;
        case S_EAT0L:
            found_digit = 1;
            if (c >= '1' && c <= '9') { state = S_GETL; p--; }
            else if (c == '.') state = S_GETR;
            else if (c == '+' || c == '-') { p--; state = S_PLUSMINUS; }
            else if (c == '0') state = S_EAT0L;
            else if (c == 'D' || c == 'E' || c == 'd' || c == 'e') state = S_E;
            else { state = S_END; p--; }
            break;
        case S_SIGNM:
            if (c >= '1' && c <= '9') { state = S_GETL; p--; }
            else if (c == '.') state = S_POINT;
            else if (c == '0') state = S_EAT0L;
            else { state = S_END; p = (const uint8_t*)str; }
            break;
        case S_GETL:
            found_digit = 1;
            for (; vc6_isdigit(c); c = *p++) {
                if (manlen < 25) buf[manlen++] = (uint8_t)(c - '0');
                else exp_adj++;
            }
            if (c == '.') state = S_GETR;
            else if (c == '+' || c == '-') { p--; state = S_PLUSMINUS; }
            else if (c == 'D' || c == 'E' || c == 'd' || c == 'e') state = S_E;
            else { state = S_END; p--; }
            break;
        case S_GETR:
            found_digit = 1;
            found_decpoint = 1;
            if (manlen == 0) for (; c == '0'; c = *p++) exp_adj--;
            for (; vc6_isdigit(c); c = *p++) {
                if (manlen < 25) { buf[manlen++] = (uint8_t)(c - '0'); exp_adj--; }
            }
            if (c == '+' || c == '-') { p--; state = S_PLUSMINUS; }
            else if (c == 'D' || c == 'E' || c == 'd' || c == 'e') state = S_E;
            else { state = S_END; p--; }
            break;
        case S_POINT:
            found_decpoint = 1;
            if (vc6_isdigit(c)) { state = S_GETR; p--; }
            else { state = S_END; p = (const uint8_t*)str; }
            break;
        case S_E:
            savedp = p - 2;
            if (c >= '1' && c <= '9') { state = S_GETE; p--; }
            else if (c == '+') state = S_SIGNE;
            else if (c == '-') { exp_sign = -1; state = S_SIGNE; }
            else if (c == '0') state = S_EAT0E;
            else { state = S_END; p = savedp; }
            break;
        case S_SIGNE:
            if (c >= '1' && c <= '9') { state = S_GETE; p--; }
            else if (c == '0') state = S_EAT0E;
            else { state = S_END; p = savedp; }
            break;
        case S_EAT0E:
            found_exponent = 1;
            for (; c == '0'; c = *p++) {}
            if (c >= '1' && c <= '9') { state = S_GETE; p--; }
            else { state = S_END; p--; }
            break;
        case S_GETE: {
            found_exponent = 1;
            int32_t e = 0;
            for (; vc6_isdigit(c); c = *p++) {
                e = e * 10 + (c - '0');
                if (e > 0x1450) { e = 0x1451; break; }
            }
            exp = e;
            for (; vc6_isdigit(c); c = *p++) {}
            state = S_END;
            p--;
            break;
        }
        case S_PLUSMINUS: /* a sign after the mantissa: only with implicit_E */
            state = S_END;
            p--;
            break;
        }
    }

    ld12 tmp;
    memset(tmp.b, 0, 12);
    if (!found_digit) {
        flags = 4;
    } else {
        if (manlen > 24) {
            if (buf[23] >= 5) buf[23]++;
            manlen = 24;
            exp_adj++;
        }
        if (manlen > 0) {
            while (manlen > 0 && buf[manlen - 1] == 0) { manlen--; exp_adj++; }
            mtold12(buf, manlen, &tmp);
            if (exp_sign < 0) exp = -exp;
            exp += exp_adj;
            (void)found_exponent; /* scale is 0 */
            (void)found_decpoint; /* decpt is 0 */
            if (exp > 0x1450) overflow = 1;
            else if (exp < -0x1450) underflow = 1;
            else multtenpow12(&tmp, exp, 0);
            if (overflow) {
                memset(tmp.b, 0, 12);
                wr32(tmp.b + 6, 0x80000000u);
                wr16(tmp.b + 10, 0x7FFF);
                flags = 2;
            } else if (underflow) {
                memset(tmp.b, 0, 12);
                flags = 1;
            }
        }
    }
    *out = tmp;
    wr16(out->b + 10, (uint16_t)(rd16(out->b + 10) | man_sign));
    return flags;
}

/* ---- _ld12cvt (10009832) for float -------------------------------------- */
/* The mantissa as three 32-bit words, most significant first. Bit position
 * 0 is the top bit of man[0]. */
static int is_zero_tail(const uint32_t man[3], int n) /* 10009638: positions > n */
{
    int w = n / 32, b = n % 32;
    uint32_t mask = ~(0xFFFFFFFFu << (31 - b));
    if (man[w] & mask) return 0;
    for (w++; w < 3; w++) if (man[w]) return 0;
    return 1;
}

static int inc_man(uint32_t man[3], int n) /* 10009681: add 1 at position n */
{
    int w = n / 32, b = n % 32;
    uint32_t r;
    int carry = addl(man[w], 1u << (31 - b), &r);
    man[w] = r;
    for (w--; w >= 0 && carry; w--) {
        carry = addl(man[w], 1, &r);
        man[w] = r;
    }
    return carry;
}

static int round_man(uint32_t man[3], int precision) /* 100096D7 */
{
    int retval = 0;
    int w = precision / 32, b = precision % 32;
    uint32_t bit = 1u << (31 - b);
    if (man[w] & bit) {
        if (!is_zero_tail(man, precision + 1)) retval = inc_man(man, precision - 1);
    }
    man[w] &= 0xFFFFFFFFu << (31 - b);
    for (int i = w + 1; i < 3; i++) man[i] = 0;
    return retval;
}

static void shr_man(uint32_t man[3], int n) /* 100097A5 */
{
    int nw = n / 32, nb = n % 32;
    uint32_t mask = ~(0xFFFFFFFFu << nb), carry = 0;
    for (int i = 0; i < 3; i++) {
        uint32_t low = man[i] & mask;
        man[i] = (man[i] >> nb) | carry;
        carry = (32 - nb) >= 32 ? low : low << (32 - nb); /* x86 shifts by cl & 31 */
    }
    for (int i = 2; i >= 0; i--) man[i] = (i >= nw) ? man[i - nw] : 0;
}

static uint32_t ld12_to_float_bits(const ld12* x)
{
    /* FloatFormat (10011AC8): max_exp 128, min_exp -127, precision 24,
     * exp_width 8, format_width 32, bias 127 */
    const int max_exp = 128, min_exp = -127, precision = 24, exp_width = 8, bias = 127;
    uint16_t e = rd16(x->b + 10);
    uint32_t sign = e & 0x8000;
    int exponent = (int)(e & 0x7FFF) - 0x3FFF;
    uint32_t man[3] = { rd32(x->b + 6), rd32(x->b + 2), (uint32_t)rd16(x->b) << 16 };
    uint32_t bexp = 0;

    if (exponent == -0x3FFF) {
        bexp = 0;
        if (!(man[0] == 0 && man[1] == 0 && man[2] == 0)) { man[0] = man[1] = man[2] = 0; }
    } else {
        uint32_t saved[3] = { man[0], man[1], man[2] };
        if (round_man(man, precision)) exponent++;
        if (exponent < min_exp - precision) {
            man[0] = man[1] = man[2] = 0;
            bexp = 0;
        } else if (exponent <= min_exp) {
            man[0] = saved[0]; man[1] = saved[1]; man[2] = saved[2];
            shr_man(man, min_exp - exponent);
            round_man(man, precision);
            shr_man(man, exp_width + 1);
            bexp = 0;
        } else if (exponent >= max_exp) {
            man[0] = 0x80000000u; man[1] = man[2] = 0;
            shr_man(man, exp_width);
            bexp = (uint32_t)(bias + max_exp);
        } else {
            bexp = (uint32_t)(bias + exponent);
            man[0] &= 0x7FFFFFFFu;
            shr_man(man, exp_width);
        }
    }
    return (bexp << (31 - exp_width)) | (sign ? 0x80000000u : 0) | man[0];
}

float vc6_atoflt(const char* text)
{
    ld12 x;
    strgtold12(&x, text);
    uint32_t bits = ld12_to_float_bits(&x);
    float f;
    memcpy(&f, &bits, 4);
    return f;
}
