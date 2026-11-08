# The machine code of `bin/ds2wav.dll`

Phase 1 of [the rewrite plan](../rewrite-plan.md): what the original engine's machine code does, compared with its source code, `drumsynth.c`. Written 2026-11-08 from `dumpbin /disasm`. The C17 engine in `engine/` is a transcription of this analysis. Every point below is reproduced there, at the DLL address it names.

## Files

| File | What it is |
|---|---|
| [ds2wav-engine.asm](ds2wav-engine.asm) | The code compiled from `drumsynth.c`, `10001000`–`10003010`, annotated: globals by name (`envData[2][NEXTT]`), constants with their values (`float 0.0099999998`), calls by name. |
| [runtime.asm](runtime.asm) | The Visual C++ 6 runtime routines the engine depends on: `_ftol`, `rand`/`srand`, `_CIfmod`, `_CIpow`, and the text-to-float conversion behind `sscanf("%f")`. |

To remake them:
- run `python tools/disasm/make_listings.py`, which needs `dumpbin` from Visual Studio;
- `tools/disasm/annotate.py ASM START END` prints any other range;
- `tools/disasm/peconst.py ADDRESS[:f|d|s|i]` reads a constant.

Addresses are virtual addresses at the DLL's image base, `0x10000000`. The DLL is 32-bit, built by Visual C++ 6 with optimization: frame-pointer omission and register allocation of locals. It does not set `/Op` (improve float consistency), which is why the points below exist. It links the C runtime statically.

## Function map

| Address | Function | Notes |
|---|---|---|
| 10001000 | `DllMain` | returns 1 |
| 10001010 | `LongestEnv` | |
| 10001110 | `LoudestEnv` | returns its result in `st(0)`, not rounded |
| 10001150 | `UpdateEnv` | |
| 10001230 | `getEnv` | |
| 10001350 | `waveform` | jump table at 10001450; returns `st(0)` unrounded |
| 10001460 | `GetPrivateProfileFloat` | |
| 100014C0 | `ds2mem` (export) | |
| 10001530 | `ds2buf` (export) | |
| 10001590 | `ds2wav` (export) | stack frame 2FCh bytes |
| 10003060 | `_ftol` | |
| 10003087 | `sscanf` → `_input` (10003DF5) | `%f` stores through `_fassign` (10003A8F, via the pointer at 1000F238) |
| 100030CA | `_CIfmod` | → dispatcher 10004930 → `fprem` loop 100030D4 |
| 100032AA / 100032B7 | `srand` / `rand` | |
| 10003590 | `_CIpow` | main body 100035B2, `2^x` at 10008710 |

## The global variables

The DLL's globals from `phi[]` to `timestretch` lie in one block of memory. The original reads and writes past the end of its arrays (see "Reading and writing past the arrays" below), so the rewrite keeps the same layout (`struct ds_image` in `engine/src/ds_engine.c`).

| Address | Variable | Image word |
|---|---|---|
| 10012880 | `chkOn[8]` | (before the image) |
| 100128A0 | `phi[1200]` | 0 |
| 10013B60 | `DF[1200]` | 1200 |
| 10014E20 | `envpts[8][3][32]` | 2400 |
| 10015A20 | `wavewords` | 3168 |
| 10015A24 | unused (never referenced) | 3169 |
| 10015A40 | `sliLev[8]` | 3176 |
| 10015A60 | `clippoint` (short) | 3184 |
| 10015A64 | unused | 3185 |
| 10015A80 | `envData[8][6]` | 3192 |
| 10015B40 | `timestretch` | 3240 |
| 10015B44… | runtime library data | — |
| 100124E8 | `busy` | |
| 100124EC | `wave` (pointer) | |
| 100124F0 | `wavemode` | |
| 1000F030–1000F044 | `mem_t`, `mem_o`, `mem_n`, `mem_b`, `mem_tune`, `mem_time` | |

`envData[e][k]`: `MAX` = 0, `ENV` = 1, `PNT` = 2, `dENV` = 3, `NEXTT` = 4 (the source's `#define`s); word 5 is unused.

## Where `ds2wav`'s locals live

Offsets from `esp` after the prologue (`sub esp,2FCh` plus four register pushes). When reading the listing, subtract 4 for every `push` still outstanding at that instruction.

| Offset | Variable | Type | Offset | Variable | Type |
|---|---|---|---|---|---|
| 10h | temporaries (float `t`, `ODrive/8`, `DownAve`) | float | A8h | `commentLen` | int |
| 14h | `t` | int | ACh | `TT` | float |
| 18h | `tpos` | int | B0h | `OW2` | int |
| **1Ch** | **`Ot`** (never initialized) | float | B4h | `BPhi` | float |
| 20h | `Length` | int | B8h | `Oc0` | float |
| 28h | `MFin` | float | BCh | `BF2` | float |
| 2Ch | `F1` | float | C0h | `BF` | float |
| 30h | `NT`, later `DAtten`, loop `i` | int/float | C4h | `BPhi2` | float |
| 34h | `MFout` | float | C8h | `OW1` | int |
| 38h | `MasterTune` (read value), later `MFtmp` | float | CCh | `ddF` | float |
| 3Ch | `Tphi` | float | D0h | `OBal1` | float |
| 40h | `Ophi2` | float | D4h | `Param` (int64), `DiON` | int |
| 44h | `Ophi1` | float | DCh | `BFStep` | int |
| 48h | `F2` | float | E0h–E8h | `x[0]`, `x[1]`, `x[2]` | float |
| 4Ch | `sec[32]` | char | ECh | `d` | float |
| 6Ch | `TDroopRate` | float | F0h | `g` | float |
| 70h | `OF1` | float | F4h | `BQ` | float |
| 74h | `Oc1` | float | F8h | `Oc2` | float |
| 78h | `TphiStart` | float | FCh | `TON` | int |
| 7Ch | `DGain` | float | 100h | `MFres` | float |
| 80h | `OF2` | float | 104h | `c` | float |
| 84h | `DStep` | int | 108h | `HighPass` | int |
| 88h | `OBal2` | float | 10Ch | `OF1Sync` | int |
| 8Ch | `OL` | float | 110h | `progress` | int |
| 90h | `BFStep2` | int | 114h | `ODrive` | float |
| 94h | `BdF` | float | 118h | `b` | float |
| 98h | `BdF2` | float | 11Ch | `BQ2` | float |
| 9Ch | `fp`, earlier the double constants 2.0 and 10.0 for `pow` | | 120h | `a` | float |
| A4h | `MainFilter` | int | 124h | `OF2Sync` | int |
| 128h | `BON` | int | 12Ch | `BON2` | int |
| 130h | `NON` | int | 134h | `OcQ` | float |
| 138h | `TDroop` | int | 13Ch | `TL` | float |
| 140h | `OON` | int | 144h | `OMode` | int |
| 148h | `OcF` | float | 14Ch | `BL2` | float |
| 150h | `BL` | float | 154h | `WH` (44 bytes) | struct |
| 180h | `WI` (44 bytes) | struct | 1ACh | `ver[32]` | char |
| 1CCh | `percent[16]` | char | 1DCh | `Oc[6][2]` | float |
| 20Ch | `comment[256]` | char | | | |

The prologue sets these to 0: `progress`, `x[0..2]`, `b`, `c`, `d`, `TT`, `TphiStart`, `BdF`, `BdF2`, `OF1Sync`, `OF2Sync`, `Oc0`, `Oc1`, `Oc2`, `TDroop`, `MFin` and `MFout`, as the source says.

`Ot` is the only local that is read before it is written: with the overtones off it is never assigned. That is [findings section 4](../findings.md).

**Never stored at all:** some of the source's variables exist only in x87 registers, at 53-bit precision, never rounded to `float`:

| Variable | Kept in a register |
|---|---|
| `NL` | from its computation to the stores of `g` |
| `OcA` | its second use, `OcA *= 1 + 4*OBal1`, is dead code and was dropped |
| `Ocf1`, `Ocf2` | in the set-up |
| `Ocf1` | in the 808 loop |
| `MFfb` and the filter's intermediate `MFtmp` | |
| `DownAve` | |
| `endEnv`, `dT` and the new "this level" | in `UpdateEnv` |
| `loudest` | in `LoudestEnv` |
| `l` | in `LongestEnv` |
| `Fsync` | removed: it is never used |

## Arithmetic: what the compiler did that the source doesn't show

The x87 unit runs at the Windows default control word `0x027F`: 53-bit precision, round to nearest, all exceptions masked. The DLL never changes it, except inside `_ftol`, `_CIfmod` and `_CIpow`. At that precision every `+ - * /` and `fsqrt` is rounded correctly to 53 bits, exactly like C `double` arithmetic. So wherever the DLL keeps a value in a register, the rewrite uses a `double`, and wherever it stores to a `float`, the rewrite rounds to `float`. The only differences are the exponent range, which matters only for `exp` (handled in assembly), and the transcendental instructions, covered under "The transcendental instructions" below.

### Divisions by constants became multiplications by a `float` reciprocal

The reciprocal is rounded to `float`, so the result can differ from the division in the last bit, and after truncation by a whole unit.

| Source | Compiled as | Constant (address) |
|---|---|---|
| `l / 1200` (LongestEnv) | `l * -0.00083333335f`, truncated, negated | 1000E110 |
| `ph / TwoPi` (saw) | `ph * 0.15915494f` | 1000E13C |
| `NT / 105.f`, `-NT / 105.f` | `NT * 0.0095238099f` | 1000E1F0 |
| `-NT / 50.f` | `-NT * 0.02f` | 1000E1E8 |
| `fabs(NT) / 100.f` | `fabs(NT) * 0.01f` | 1000E1E4 |
| `Phase / 57.29578f` | `Phase * 0.017453292f` | 1000E1C0 |
| `(TDroopRate - 20.0f) / 30.0f` | `(TDroopRate - 20) * 0.033333335f` | 1000E1C8 |
| `BFStep / 2.5f` | `BFStep * 0.4f` | 1000E18C |
| `BFStep2 / 2.5` | `BFStep2 * 0.4` (double) | 1000E180 |
| `ODrive / 8` | `ODrive * 0.125` (exact) | 1000E164 |
| `MasterTune * TwoPi * F / Fs` | `F * MasterTune * 0.00014247587f`: **TwoPi / Fs folded into one `float` constant** and the product reordered | 1000E1E0 |
| `TwoPi / 8.f` | `0.78539819f` | immediate 3F490FDB |
| `2.f * randmax` | `6.1037019e-05f` | 1000E16C |

### Operations reordered

| Where | Source | Compiled |
|---|---|---|
| noise filter | `a*x0 + b*x1 + c*x2 + d*TT` | `((a*x0 + TT*d) + c*x2) + b*x1` |
| noise output | `TT * g * ENV` | `(ENV * g) * TT` |
| noise slope | `(1 + 0.0005f*NT*NT) * NL` | `(NT*NT*0.0005f + 1) * NL` |
| tone | `TL * ENV * sin` | `(sin * ENV) * TL`, then `+ DF` |
| noise bands | `cos * ENV * BL` | the same order, then `+ DF` |
| noise bands | `BPhi + BF + BQ*BdF` | `(BQ*BdF + BPhi) + BF` |
| BFStep | `BQ + 1.f + (1.f * BF)` | `(BF + BQ) + 1` |
| 808 set-up | `Ocf1 + (Ocf2 - Ocf1) * 0.2f * i` | `(i * (Ocf2 - Ocf1)) * 0.2f + Ocf1` |
| overtones, add | `OBal1 * ENV3 * w1` | `(w1 * ENV3) * OBal1` |
| overtones, RM | `OL * ENV3 * w1 * Ot` | `((w1 * Ot) * ENV3) * OL` |
| filter all | `DF + Ot + MFres*(…)` | `(MFres-term + DF) + Ot` |
| distortion | `DAtten * DGain * pow(…)` | `(pow * DAtten) * DGain` |
| stretch | `.01f * mem_time * Stretch` | `(Stretch * mem_time) * 0.01f` |

### Values the source rounds to `float` but the DLL doesn't

`(float)` casts that VC6 left out (it keeps the register value):

| Value | Kept unrounded |
|---|---|
| `(float)sin(...)` in the tone | |
| `(float)cos(...)` in the noise bands | |
| `(float)sqrt(BF)` | |
| `(float)pow(...)` | in `ODrive` |
| `(float)exp(...)` | in the droop |
| `(float)fabs(...)` | |
| the `waveform()` return value | it is the raw `fsin` result for form 0 |
| the FM modulator `Ot` | only the phase sum `Ophi1 + Ot` is rounded, by being passed as a `float` argument |
| the triangle's `while (ph < TwoPi) ph += TwoPi` | the sum is rounded once, after the loop |

### Comparisons made on the register, not on the stored `float`

| Comparison | The DLL compares |
|---|---|
| `timestretch < 0.2f` | the unrounded product |
| `fabs(F1) < 0.001f` | the unrounded product, against `(double)0.001f` |
| `NEXTT < 0` in `UpdateEnv` | the unrounded product |
| in the tone loop | the unrounded sum `Tphi + phi[]` goes to `fmod`; only the stored `Tphi` is rounded |

### Integers read as unsigned

`GetPrivateProfileInt` returns `UINT`. Where the source converts it straight to floating point, VC6 converts it unsigned, with `fild qword` and a zero high word:
- `Param` (`OBal2`);
- `Bits`;
- `Clipping`.

So a negative `Param` becomes about 4.29 × 10⁹. Where the value is first stored in an `int`, as with `Level`, `Slope` or `dF`, it is signed.

### Comparisons with NaN

The x87 sets all condition flags for an unordered compare, and VC6's tests decide what NaN does:

| Where | What a NaN does |
|---|---|
| `UpdateEnv` | a NaN `NEXTT` holds; a NaN `dT` becomes 1 |
| section end tests | never end on NaN |
| clipping | **a NaN sample is written as `clippoint`** |
| bit reduction | `_ftol` turns NaN into 0 |

## The transcendental instructions

| Source | Compiled | Rewrite |
|---|---|---|
| `sin(fmod(x, TwoPi))` | `_CIfmod` then inline `fsin`. No range reduction or checks; the 64-bit `fsin` result is used directly by the next `fmul`. | `ds87_sin_mul`, `ds87_sin` |
| `cos(fmod(x, TwoPi))` | the same with `fcos` | `ds87_cos_mul` |
| `exp(x)` | inlined: `fldl2e; fmulp` (rounded to 53 bits) `; fld st0; frndint; fxch; fsub; f2xm1; fld1; faddp; fscale; fstp st1` | `ds87_droop_phi`, `ds87_droop_f2`, as whole chains, because the result can lie far outside the `double` range (`exp(-1857)` for steep droops) |
| `pow(x, y)` | `_CIpow`: `fyl2x`, then `frndint`, `f2xm1`, `fld1; faddp`, `fscale` (10008710). Integer exponents are not special: `pow(50, 3)` is computed through logarithms. It runs at the caller's precision control; `and 300h; or 7Fh` only resets rounding and exception masks. | `ds87_pow_core` and `vc6_pow` |
| `fmod(x, TwoPi)` | `_CIfmod`. It classifies both arguments with `fxam` (10004C07) and dispatches through a table (1000F1E0). For finite non-zero arguments it runs `fprem` until done, which is exact like C `fmod`. **A zero `x` gives +0** (C keeps −0). An infinite `x` or a zero `y` gives the "indefinite" NaN. | `vc6_fmod` |
| `sqrt(x)` | `fsqrt`, correctly rounded at 53 bits, the same as C `sqrt` | C `sqrt` |

`fsin`, `fcos`, `fyl2x` and `f2xm1` are not specified to the last bit, so they may differ between processor models. The rewrite runs the same instructions on the same processor, which is exact there. See the Risks section of the rewrite plan.

## Conversions

- **`_ftol` (10003060)** sets rounding to truncate, does `fistp qword` and returns the low 32 bits.
  - Out of the 64-bit range, and for NaN, `fistp` stores `0x8000000000000000`, so the result is 0.
  - A `(short)` cast takes the low 16 bits of that.
  - Rewrite: `vc6_ftol`.
- **`rand()` (100032B7):** `seed = seed*214013 + 2531011`, returning `(seed >> 16) & 0x7FFF`, with the seed in the per-thread data. `srand(1)` runs on every render. Rewrite: `vc6_rand`.
- **`sscanf("%f")`** collects the characters itself, then converts them through:
  - `_atoflt` (100099F7);
  - `__strgtold12` (1000C007), which builds a 12-byte value with an 80-bit mantissa, using `__mtold12`, `__multtenpow12` and `__ld12mul` with VC6's own tables of powers of ten;
  - `_ld12cvt` with `_RoundMan`, which rounds to `float`.

  This is not the correctly rounded `float`:
  - `__ld12mul` forms only the upper partial products and propagates a carry into one 16-bit word only.
  - **`_RoundMan` rounds up only if the rounding bit is set and some bit two or more places further on is set**, because its tail test `_IsZeroTail` (10009638) starts one bit too late. So exact ties round down.
  - About 2.6% of a set of numbers chosen close to rounding boundaries come out differently from correct rounding. No preset value is affected.
  - Rewrite: `engine/src/ds_vc6_fltin.c`, a transcription of all of it. It agrees with the DLL on all 112,872 probe strings ([probes.md](../reference/probes.md)).
- **What `sscanf` returns** matters, because `getEnv` writes 0 only when it returns 0:
  - 1 when a number was read;
  - 0 when the text does not start with a number (`"abc"`, `"-x"`);
  - EOF (−1) when the text ends before any digit (`""`, `"-"`, `"."`). With EOF, `getEnv` leaves the old value in place.

## Reading presets

- **`GetPrivateProfileFloat` (10001460)** reads at most 15 characters into a 16-byte buffer, then calls `sscanf`. An empty value gives the default; text that is not a number gives 0.
- **`getEnv` (10001230):**
  - `GetPrivateProfileString` with a 256-byte buffer and the default `"0,0 100,0"`.
  - A token is collected in `s`, an 8-byte buffer that lies **directly below `en` on the stack** (`s` at frame 0Ch, `en` at 14h). A token longer than 7 characters runs on into the part of `en` that has already been read, so it is still read whole. The overflow is harmless in the DLL, though not in a rebuild with a different stack layout.
  - `s` keeps its contents between tokens, so two separators in a row read the previous token again.
  - Before the first character of an envelope, `s` holds whatever the stack held. That happens only if the string starts with `,` or a space; no preset does.
- **Windows' profile functions** have rules that decide what a preset means: line ends, white space, comments, quotes, the first section only, and `GetPrivateProfileInt`'s number syntax. They are listed in `engine/src/ds_ini.c` and were found by experiment ([ini-rules.md](../reference/ini-rules.md)).

## Reading and writing past the arrays

These happen in the DLL and are reproduced, because the global variables keep the DLL's layout:

| What | Where it goes | When |
|---|---|---|
| `getEnv` with more than 32 points | `envpts[e][0][32+k]` is `envpts[e][1][k]`. Past that come the unused third row and the next envelope; `getEnv` reads the envelopes in the order 7, 2, 1, 3, 4, 5, 6, so later ones overwrite earlier ones. The FilterEnv (7) runs into `wavewords`, then `sliLev`, `clippoint` and `envData`, and with 104 or more points into `timestretch`. | any hand-edited preset |
| `UpdateEnv` after the last point | It reads the level of the point after the last one, which is `envpts[e][1][ep+1]`, normally 0. After the hold time of 442000 × stretch samples it reads one point further on every sample, through the rest of `envpts`, then `wavewords`, `sliLev`, `envData`… | a section still running 442000 samples after its envelope began, such as the filter |
| downsampling | When `DStep` does not divide 1200 (`Rate` of 8 or more), the last group reads and writes past `DF[1199]` into `envpts[0]`, which is otherwise unused, and the next block reads it back. | `Rate` outside the GUI's 0–7 |

Reads beyond `timestretch` would see the runtime library's own data. The rewrite reads 0 there and reports `DS_NOTE_MEMORY_BEYOND`.

## Where the original hangs or crashes

The rewrite does something defined in each case and reports `DS_NOTE_HANG`:
- the triangle waveform with a NaN or −∞ phase: `while (ph < TwoPi)` never ends;
- distortion `Rate` below 0: `DStep` ≤ 0 and the downsampling loop never ends;
- a noise band whose step works out to 0: `t % 0` is a division fault;
- an envelope string that starts with a separator: reads stack garbage (`DS_NOTE_TOKEN_START`).

## The WAV file

`ds2wav` writes the following, byte for byte as `engine/src/ds_wav.c` does:
- a 44-byte header, whose RIFF length counts the INFO chunk;
- the samples;
- a 44-byte `LIST`/`INFO` chunk with `ISFT` `"DrumSynth v2.0 "` and a zero byte;
- `ICMT` with the comment: `commentLen` bytes, including the terminating zero, padded to an even length.

An empty comment becomes a single space. Comments longer than 253 characters are cut, and the cut copy has no terminating zero.

## `ds2mem` and `ds2buf`

The GUI never calls them; it only uses `ds2wav` (`gui/DRUMSYN.FRM` and `genform.frm`).

- **`ds2mem`** sets `wavemode = 1` and the six `mem_*` factors, and calls `ds2wav(dsfile, "", 0)`.
  - It returns `wavewords`, or 0 on failure.
  - Its `buffer` argument is unused: the source assigns it to a local.
- **`ds2buf`** copies `min(samples, wavewords)` samples and frees the buffer.
- Both are reproduced by `ds_render` with a `ds_factors` argument. `ds2wav` itself resets `mem_tune` to 0 and the others to 1 when it isn't called through `ds2mem`.
