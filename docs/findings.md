# Findings: how the original DrumSynth 2.0 engine really behaves

Measured on 2026-11-08 with the render comparison tools (`tools/renderers/`, `tools/render_all.py`, `tools/compare_wavs.py`; how to run them is in [rendering.md](rendering.md)). Every number here comes from a report in [reports/](reports/README.md) or from an experiment described below. All renders cover the same 849 unique presets from `bin/library.zip` and `drumsynths/`.

These findings define what "faithful" means for the C17 rewrite. The summary is at the end, in [What the rewrite has to do](#what-the-rewrite-has-to-do).

## Names used in this document

| Name | What it is |
|---|---|
| **ref** | The original `bin/ds2wav.dll` from DrumSynth 2.0, a 32-bit binary from 2000, called through `ref_render.exe`. **This is the reference.** |
| **ref-fpu24** | The same DLL with the x87 floating-point unit set to 24-bit precision. A diagnostic only. |
| **src** | The original source, `drumsynth.c` in the repository root, unmodified, compiled with today's MSVC as 32-bit. |
| **new** / **new-x86** | The modern port, `src/DrumSynth.Core/drumsynth.c`, compiled with today's MSVC as 64-bit / 32-bit. |
| **original** | The 6 WAV files saved by the original DrumSynth program, found next to their presets in `drumsynths/`. |

Results are sorted into categories: **identical** (every sample the same), **within 1 step** (no sample differs by more than 1 of 32768, which is rounding), **small** (the difference is at least 60 dB below the sound), **large** (anything else) and **length differs**.

---

## 1. The reference renderer reproduces the original program

The 6 WAVs saved by the original program are the only output of the real DrumSynth we have. Five were saved by DrumSynth v2.0 and one (`Percussion/Shaker_1.WAV`) by v1.0, as their INFO chunks say. Report: [ref-vs-original](reports/ref-vs-original.md).

| WAV | Noise | Result |
|---|---|---|
| `DF-MOD` | off | **identical** |
| `kraftwerk` | off | **identical** |
| `bell` | on, at level 1 | small: −85.9 dB, largest difference 5 |
| `fat and dark` | on | large |
| `hardcore clap` | on | large |
| `Shaker_1` (v1.0) | on | large |

- **Both WAVs without noise match bit for bit.** So `ref_render` calls the DLL exactly the way the program did, and the DLL in `bin/` is the engine that made these files.
- **The four with noise all differ, and only in the noise.** For `fat and dark` and `hardcore clap` the RMS level is the same as the render (10,986 vs 10,784 and 8,502 vs 8,650) but the correlation is near zero (+0.16 and −0.04). That's what two different random sequences look like. `bell` has its noise at level 1, so the different noise changes at most 5 steps.
- **Why the noise differs is not proven.** All four presets have `FixedSeq=0` ("always same random sequence" off). The DLL's source ignores that switch and calls `srand(1)` on every render (line 310 has the check commented out, line 311 always reseeds). The DLL behaves the same way: rendering one preset three times in one process gives three identical files. So these WAVs were probably saved by a different build that honoured `FixedSeq`, where the noise continued from whatever was played before. With `FixedSeq=0` the noise is meant to be different every time, so there's no single right answer for it.
- **Test that ruled out the alternatives:** the x87 precision setting (24, 53 or 64 bits) doesn't change any of these 6 results, and neither do the file comments, which match between WAV and preset.

## 2. The DLL was built from this repository's `drumsynth.c`

Report: [ref-fpu24-vs-src](reports/ref-fpu24-vs-src.md).

- At the Windows default x87 precision, the original source built today (`src`) matches the DLL bit for bit on only **75 of 849** presets ([ref-vs-src](reports/ref-vs-src.md): 75 identical, 188 within 1 step, 213 small, 373 large).
- With the DLL forced to 24-bit precision (`ref-fpu24`), `src` matches far better: **167 identical, 305 within 1 step, 272 small, 105 large.** 24-bit precision is the precision of a C `float`, which is what today's compiler uses.
- Single-section test presets confirm it. With the DLL at 24 bits, tone alone, noise alone and additive overtones alone each come out within 1 step of `src`.
- **Conclusion:** the DLL is this source. The remaining differences come from how the 2000-era compiler (Visual C++ 6) evaluates floating-point expressions on the x87 unit, not from different code.
- Most of the 105 presets still "large" at 24 bits use the **808 Cymbal** overtone method. It compares accumulating counters against thresholds (`Oc[j][0] > Oc[j][1]`), so the smallest rounding change moves a pulse by a whole sample.

## 3. The original's sound depends on x87 precision; the noise bands most of all

- **The DLL runs at 53-bit precision** when it's loaded normally. That's the Windows default, reported by `ref_render` on stderr. A raw control word of `0x027F` was read before and after loading the DLL and after each render.
- **53 and 64 bits give identical output**, and 24 bits differs ([ref-vs-ref-fpu24](reports/ref-vs-ref-fpu24.md): 91 identical, 355 large).
- **Where the precision matters:** Visual C++ 6 keeps some intermediate values in x87 registers, with the precision setting deciding their accuracy, instead of rounding them to `float` after every step. Values that accumulate over thousands of samples then drift apart.
- **The noise bands are by far the most sensitive.** In the comparison of `ref` with `src`, noise band 1 is the worst feature: 291 of 396 presets are "large". A test preset with only noise band 1 (F 1000, dF 50) differs completely from sample 74 on. The same preset with `dF=0` (no random frequency jumps) matches within 1 step.
- **Experiment:** variants of the original source were compiled with single variables changed from `float` to `double`.
  - With the noise band phase `BPhi` as `double` (line 510: `BPhi = BPhi + BF + BQ * BdF;`), the largest difference drops from 32,716 to 2,564, and the first difference moves from sample 74 to sample 89.
  - Making `BdF` and `BQ` double as well doesn't improve it further.
  - So the phase is part of the answer, but other intermediate values are also kept at higher precision.
- **Method used:** variants built from a copy of `drumsynth.c` with `#define`s for the variable types, rendered with the same front end (`renderer_main.c`) and compared sample by sample. The variant sources were scratch files and aren't in the repository.

**Changing the precision must be done after the DLL is loaded.** Setting the x87 precision before `LoadLibrary` had no effect on any preset. That's why `ref_render` applies `--fpu` after loading the DLL. The DLL's own C runtime start-up runs during `LoadLibrary`, which is the likely reason.

## 4. Uninitialized variable `Ot`: a sound with overtones off picks up garbage

**The bug.** `Ot` is the overtone section's output for the current sample.

- **Where:** it's declared at `drumsynth.c:242` without a value. It is set only inside `if(OON==1)`, when the overtones section is on (line 565, `Ot=0.0f;`, then the method's formula).
- **How it's used:** it's added to every sample regardless, at line 639 (no filter: `DF[t - tpos] = DF[t - tpos] + Ot;`), and fed into the filter at lines 615 and 633.
- **The effect:** with overtones off, every sample gets whatever happened to be in that stack slot, a constant offset or, if the bits form a NaN, broken output.

**Evidence.**
- **First noticed by accident.** Rebuilding the host program changed 8 presets. They were the first 8 rendered in the run (0001–0008, `library/Acoustic/`), all with overtones off.
- **The usual causes were ruled out.** The x87 control word, status word and register stack were checked with `fnstenv`, and the DLL's imports were listed: it links its C runtime statically, so no system library is involved.
- **Path strings matter.** With forward-slash paths those 8 presets came out differently from backslash paths. Windows' INI functions leave different data on the stack depending on the path.
- **Order matters too.** Rendered after a preset that has overtones on (0009 is the first), the same 8 presets were unaffected. A render with overtones on leaves its last `Ot` value in that slot, usually exactly 0 because the overtone envelope has ended.
- **How big it is.** Rendered one per process without clearing the stack, **188 of 849 presets** change ([ref-vs-ref-raw-stack](reports/ref-vs-ref-raw-stack.md): 661 identical, 188 large).

**In the modern port.** The port has the same bug (`src/DrumSynth.Core/drumsynth.c:452`), and it is worse there.

- **Why worse:** `ds_to_wav` first runs the port's own INI parser, whose 512-byte line buffers (line 54) leave preset text on the stack. `Ot` then starts as a large garbage value.
- **The 5 presets it breaks:** `yr 808 hummer`, `neo808`, `very basic snare`, `clappy snare` and `original hc`. Their output sits at the clip level, 32700, from the first sample.
- **Proof:** with `Ot = 0.0f` added to the declaration, all of them render identically to the original source.
- **Which builds show it:** these 5 break in the **32-bit** build of the port (`new-x86`). In the 64-bit build (`new`) the slot happens to hold 0 with today's compiler and `renderer_main.c`, so they come out right. The bug is still there and can return with any change to the build. Against the original source, the 64-bit port matches 820 of 849 presets, 19 within 1 step, 9 small and 1 large, all from 64-bit vs 32-bit math ([src-vs-new](reports/src-vs-new.md)).

**What the reference does.** The renderers zero 256 KB of stack before every render (`clear_stack()` in `tools/renderers/renderer_main.c`), so `Ot` reads as 0. That's the value it has in the original program after any sound with overtones. `--no-clear-stack` (or `render_all.py --raw-stack`) turns this off.

## 5. Envelope tables carry over from one render to the next

**The bug.** The envelope points are kept in a global array, `envpts[8][3][32]`.

- **How a preset's envelope is stored:** `getEnv()` writes its points and marks the end with a time of −1 in the next slot. It leaves that slot's *level* unchanged.
- **What happens after the last point:** `UpdateEnv()` (line 72) reads the next point's level (line 79: `endEnv = envpts[e][1][...PNT + 1]`). It then ramps towards it over about 10 seconds (`442000 * timestretch` samples).
- **The result:** after its last point, an envelope slowly heads for a level left behind by an earlier preset. In a fresh process, or the first time a table row is used, that level is 0.

**Evidence.** All 849 presets were rendered in one process, in normal and in reverse order ([ref-batch-vs-ref-batch-reverse](reports/ref-batch-vs-ref-batch-reverse.md)).

- **489 presets change with the order**, mostly a little: 360 identical, 85 within 1 step, 358 small and 46 large.
- **The largest change** is `drumsynths/original hc.ds` at −22.5 dB. It has a pitch droop and `Stretch=50`, which halves its length. The next largest is −45.6 dB.
- **All engines behave the same:** the source build and the modern port show the same pattern, because they share the code.
- **Proof of the cause:** a variant of the original source that clears `envpts` and `envData` at the start of each render gives **849 of 849 identical** results in both orders.

**What the reference does.** By default `render_all.py` renders **every preset in a process of its own**, so every render starts like the first sound after DrumSynth starts, with all tables zero. One process per preset compared with one process for everything: [ref-vs-ref-batch](reports/ref-vs-ref-batch.md), 465 identical and 33 large. `--batch` keeps the single-process mode for studying this.

**What it means for faithfulness.** In the original program, what you hear depends slightly on the sounds played before. That can't be reproduced without the history, so the faithful choice is the defined starting state.

## 6. Smaller things found

- **One-byte overflow in `getEnv()`.** `char en[256]` (line 89) is followed by `en[256]=0; //be safe!` (line 92), which writes one byte past the buffer. Today's compiler places a stack check (`/GS`) right there, so `src_render` is built with `/GS-` to run the original code unmodified.
- **Short number buffer in `getEnv()`.** `char s[8]` holds each number, so a number longer than 7 characters would overflow it, and an envelope string over 255 characters would be cut off. **No preset in either collection has either**, so this has no effect today, but the rewrite must handle long input safely.
- **The modern port's different defaults.** For keys a preset leaves out, the port uses noise level 128 (original 0) and noise band 2 F 3100 / dF 40 (original 1000 / 50). **No preset is affected:** apart from `Ot`, the port matches the original source.
- **Port compared with original, same compiler.** With both built as 32-bit by today's compiler ([src-vs-new-x86](reports/src-vs-new-x86.md)): 843 identical, 1 within 1 step, 5 large. The 5 are the `Ot` presets from section 4.
- **The port as 32-bit and as 64-bit** ([new-x86-vs-new](reports/new-x86-vs-new.md)): 814 identical, 20 within 1 step, 9 small, 6 large. The 6 large are the 5 `Ot` presets, whose stack garbage differs between builds, plus `drumsynths/spicy bd.ds` at −56.8 dB. `spicy bd` is also the one large difference between the original source (32-bit) and the 64-bit port. It uses the RM overtones with tracking, bit reduction and downsampling, so a rounding change can flip a bit-reduction step.
- **The original renders are deterministic.** The same preset rendered several times in one process, and whole runs repeated, give identical files once the stack and the starting state are controlled.
- **The original only accepts version 1 and 2 files.** It checks the 12th character of `Version=` (`DrumSynth v1.x` or `v2.x`); 171 presets are v1.0 files.
- **Absolute paths are required.** The original reads presets with `GetPrivateProfileString`, which looks in the Windows folder when given a bare file name. `renderer_main.c` makes every path absolute.
- **Distortion `Rate` 7 is the same as 4, and the labels from 4 up are one step off** (found 2026-11-09, while writing [reference/file-formats.md](reference/file-formats.md)).
  - The engine averages blocks of `DStep = 1 + Rate` samples, then remaps 7 to 20, 6 to 10 and 5 to 8 (line 397). So Rates 0–7 give blocks of 1, 2, 3, 4, **8, 10, 20, 8**.
  - The program labels the Rates "[none]", "11 kHz", "7 kHz", "5 kHz", "4 kHz", "3 kHz", "2 kHz", "1 kHz". These are half the reduced sample rate, the highest frequency left. They fit blocks of 1, 2, 3, 4, **5, 8, 10, 20**. The remapping was probably meant for `DStep` 6, 7 and 8, one higher.
  - In practice, "4 kHz" gives about 2.8 kHz, "3 kHz" about 2.2 kHz, "2 kHz" about 1.1 kHz, and "1 kHz" the same as "4 kHz".
  - Measured with the original DLL (`ref_render`): a noise preset rendered at Rate 3–7 holds each sample for 4, 8, 10, 20 and 8 samples.
  - The C17 engine does the same (`engine/src/ds_engine.c`, `DStep`). The program keeps the original labels, and the help explains them.

## 7. The machine code holds more than the source (from the disassembly)

The full analysis is in [disasm/README.md](disasm/README.md). In short, the output also depends on these, which the source does not show:

- VC6 replaced divisions by constants with multiplications by a `float` reciprocal: `l / 1200` in the sound length, `ph / TwoPi` in the sawtooth, and the noise slope, phase, droop and band-width divisions. It also folded `TwoPi / Fs` into one `float` constant.
- It reordered sums and products, for example the noise filter, the band-width step and the filter-all input.
- It kept some values in x87 registers at 53 bits and never rounded them to `float`:
  - the noise level `NL`;
  - the `sqrt`, `pow`, `exp` and `fabs` results;
  - the tone phase sum that goes to `fmod`;
  - the filter feedback.
- `exp` is an inline x87 sequence, and `sin`/`cos` are bare `fsin`/`fcos` whose 64-bit results go straight into the next multiplication.
- `fmod` of ±0 gives +0.
- `GetPrivateProfileInt` results are converted to floating point as unsigned numbers, for `Param`, `Bits` and `Clipping`.
- A NaN sample is written as the clip level.
- `sscanf("%f")` does not round correctly. VC6's 80-bit conversion rounds exact ties down, and in a few other cases near a rounding boundary, because its tail test starts one bit late. No preset value is affected.
- The original reads and writes past its envelope tables:
  - more than 32 points spill into the next row;
  - after the hold time, `UpdateEnv` walks on through memory one point per sample;
  - downsampling with a `Rate` above 7 spills into `envpts[0]`.

  What it finds there is part of its output, so the rewrite keeps the DLL's memory layout for these variables.

The `getEnv` buffer overflow (section 6) turns out to be harmless in the DLL. The 8-byte token buffer lies directly below the envelope string on the stack, so a long token runs on into the part of the string already read, and is still read whole.

## 8. How much each part of the reproduction matters

A diagnostic build of the C17 engine uses today's C library for `sin`, `cos`, `pow`, `exp`, `fmod` and text-to-float instead of the x87 sequences and VC6 routines (`c17-libm`). Against ref:

| Build | Identical | Within 1 step | Small | Large |
|---|---|---|---|---|
| `c17-libm` | 684 | 67 | 81 | 17 |
| `c17` | **849** | 0 | 0 | 0 |

All 165 differences in `c17-libm` are in presets with tone droop, whose pitch curve is an `exp`. So the inlined x87 `exp` is what matters most. For these presets, today's `sin`, `cos` and `pow` round the same as the x87 instructions almost always. Report: [ref-vs-c17-libm](reports/ref-vs-c17-libm.md).

## 9. The C17 rewrite is exact

The rewrite (`engine/`) renders every one of the 849 presets **byte for byte identical** to ref, whole WAV files included ([ref-vs-c17](reports/ref-vs-c17.md)). It is also identical on these:

| Test set | Renders | Report |
|---|---|---|
| single-feature presets | 454 | [features-ref-vs-c17](reports/features-ref-vs-c17.md) |
| random presets | 1995 of 2000 | [fuzz-ref-vs-c17](reports/fuzz-ref-vs-c17.md) |

The other 5 random presets make **the original DLL hang**: it never finishes, and the renderer stops it after the timeout. The rewrite renders them and flags each with `DS_NOTE_HANG`. All five use the triangle waveform for overtone 1 with tracking (`Wave1=2`, `Track1=1`).
- In three of them, the tone envelope has only one point, so its length `envData[1][MAX]` is 0. The tone's pitch sweep divides by it (`t / MAX`, or `-4 / MAX` with droop), so the tone phase becomes NaN. With tracking, so does the overtone phase, and the triangle's `while (ph < TwoPi) ph += TwoPi` never ends.
- In the other two, the tone envelope has 32 points, the most the tables hold. Its end marker is written into the first level (section 7). The rewrite found a non-finite phase at the same place.

This is a hang in the original program, not only in test conditions. A preset saved with a one-point tone envelope and tracked triangle overtones would freeze DrumSynth 2.0 when played. None of the 849 presets does this. No preset triggers any other note either.

Its routines agree bit for bit with the DLL's own, called by address, on about 1.9 million inputs, and its parser agrees with Windows on about 182,000 queries ([reference/probes.md](reference/probes.md)).

### Where the rewrite cannot follow the original

The rewrite does something defined in each of these cases and flags it in `ds_sound.notes`:

- **Garbage the original reads:**
  - the uninitialized `Ot`, defined as 0 (section 4);
  - the envelope state left by the previous render, defined as the first sound after start (section 5);
  - `getEnv`'s token buffer before the first character of an envelope that starts with a separator (`DS_NOTE_TOKEN_START`);
  - the runtime library's memory, when `UpdateEnv` walks past `timestretch` (`DS_NOTE_MEMORY_BEYOND`).
- **Cases where the original hangs or crashes** (`DS_NOTE_HANG`):
  - the triangle waveform at a NaN or −∞ phase;
  - distortion `Rate` below 0;
  - a noise band whose step is 0.
- **`pow` with a non-finite argument, or a result outside the `double` range** (`DS_NOTE_POW_SPECIAL`). There `_CIpow` goes through its error handler, and the rewrite gives the IEEE result.
  - It happens when the filter envelope runs past its end: `UpdateEnv` then reads envelope *times* as levels, and the filter computes `pow(10, huge)`.
  - It happened in 18 of the random presets, and every one of them came out identical to the DLL.
- **Files with NUL bytes or a byte order mark**, which Windows reads by its own guesses ([reference/ini-rules.md](reference/ini-rules.md)).
- **A different processor.** `fsin`, `fcos`, `fyl2x` and `f2xm1` may differ in the last bit between processor models. The reference checksums were made on an Intel Core i7-8850H. On another CPU, run `tools/check_reference.py`; differences there would be the CPU's, and are to be documented here.

## What the rewrite has to do

The C17 rewrite (64-bit, Windows) is judged against **ref**: the original DLL at the Windows default precision, each preset rendered in a fresh process, stack cleared. Concretely:

1. **Start every render from a defined state.** Keep all state in a structure that is zeroed for each render, so a render can't depend on the previous one. That matches the reference's "first sound after start" (section 5).
2. **Initialize `Ot` to 0** (section 4).
3. **Reproduce Visual C++ 6's x87 evaluation**, done as described in sections 7–9: register values as `double`, `float` exactly where the DLL stores, and the transcendental sequences in ml64 assembly.
4. **Implement the random generator explicitly**, with the same formula as Microsoft's C runtime (`seed = seed * 214013 + 2531011`, result `(seed >> 16) & 0x7FFF`), reseeded with 1 on every render. Then the result doesn't depend on the compiler's `rand()`.
5. **Keep `FixedSeq` ignored**, as the DLL does (section 1).
6. **Parse safely**, without the original's overflows (section 6), while giving the same values. This is done: the parser follows Windows' rules, and VC6's number conversion is transcribed.
7. **Check every step** by rendering with the rewrite and comparing against `ref` with `tools/compare_wavs.py`. The goal is as many presets as possible identical or within 1 step, with every remaining difference explained.

## Open questions

- ~~Exactly which intermediate values VC6 kept in x87 registers~~: answered by the disassembly (section 7).
- Whether other processors give the same `fsin`/`fcos`/`f2xm1`/`fyl2x` results as the i7-8850H. To find out, run `tools/check_reference.py` on an AMD processor and a recent Intel one.
- Whether some 2005–2006 build of DrumSynth honoured `FixedSeq` (section 1). That build isn't available; the evidence is only the 4 WAVs with noise.
- The x87 precision the original VB6 program ran at. The 2 noise-free WAVs match at 53 bits, but they don't depend on precision, so they can't confirm it. 53 bits is the Windows default, and the VB6 runtime isn't known to change it.
