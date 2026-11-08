# Rewrite plan: an engine as exact as possible

Plan for the C17 engine (64-bit, Windows), written 2026-11-08. The background is in [findings.md](findings.md). The general plan and decisions are in [plan.md](plan.md).

## Status (2026-11-08): done

All phases are complete. The C17 engine (`engine/`) renders these **byte for byte identical** to `ref`, whole WAV files included:

| Test set | Renders | Report |
|---|---|---|
| unique presets | 849 | [reports/ref-vs-c17.md](reports/ref-vs-c17.md) |
| single-feature presets | 454 | [reports/features-ref-vs-c17.md](reports/features-ref-vs-c17.md) |
| random presets | 1995 (the DLL hangs on the other 5; the engine flags them) | [reports/fuzz-ref-vs-c17.md](reports/fuzz-ref-vs-c17.md) |

Its routines agree bit for bit with the DLL's own on about 1.9 million inputs ([reference/probes.md](reference/probes.md)). The checksums are frozen in [reference/checksums.csv](reference/checksums.csv) and checked by `tools/check_reference.py`: 3304 renders, 0 differences, in about 30 seconds.

| Phase | Result |
|---|---|
| 1. Read the machine code | [disasm/README.md](disasm/README.md), with annotated listings. Every floating-point operation of `ds2wav()` and its helpers is accounted for, and so are the runtime routines behind `fmod`, `pow`, `rand`, `_ftol` and `sscanf("%f")`. |
| 2. Test material | `tools/probes/`: `probe32` calls the DLL's internal routines by address, `probe64` the engine's, `ini_probe` compares with Windows, `make_presets.py` generates single-feature and random presets. The CPU goes into `info.txt`, and `compare_wavs.py` compares whole files byte for byte. |
| 3. Engine skeleton | `engine/`, the `c17_render` renderer and `c17` in `render_all.py`. The disassembly was complete before any code was written, so the first version was already a full transcription. It was identical on all 849 presets at once. The "plain C library" baseline was therefore made afterwards, as a diagnostic build: `c17-libm`, 684 identical. See findings, section 8. |
| 4. Rounding points and constants | in `ds_engine.c`, each with its DLL address |
| 5. x87 math routines | `x87/ds_x87.asm`: `fsin`, `fcos`, `_CIpow`'s core, the inlined `exp` |
| 6. 80-bit chains | The `fsin`/`fcos` result times the next factor; the droop `exp` chains, whose values lie outside the `double` range. Everything else is 53-bit, which C `double` reproduces. |
| 7. Parsing | VC6's text-to-float conversion, transcribed (`ds_vc6_fltin.c`, including a rounding quirk); `sscanf`'s return values; the Windows profile rules ([reference/ini-rules.md](reference/ini-rules.md)). The probes show 0 differences. |
| 8. WAV bytes and `ds2mem` | Byte-identical files; `ds_factors` reproduces `ds2mem`'s factors. |
| 9. Hardening | The feature and random presets, and the probes' edge inputs, include NaN, infinities, denormals, zero, negative and huge values. Where the original hangs, crashes or reads garbage, the engine does something defined and reports it in `ds_sound.notes` (findings, section 9). Speed is about the same as the DLL: 100 s of sound in 0.75 s. |
| 10. Freeze | [reference/checksums.csv](reference/checksums.csv) and `tools/check_reference.py`. |

The rest of this document is the plan as written before the work.

## What "precise" means here

**Precise means: the same output as the original, sample for sample.** The target is **ref**, the original `bin/ds2wav.dll` rendered under the reference conditions (findings, "What the rewrite has to do"). Success means every preset renders **identical** to ref, not merely "close".

Computing with *more* precision than the original, for example `double` everywhere, would *not* be more faithful. The original rounds to `float` at particular points, and those roundings are part of its sound. A higher-precision "clean" mode could be added later as an option, but it would be a different sound and would never replace the faithful one.

## Why the source code alone can't give exact output

We have the exact source (findings, section 2). But the output also depends on decisions the 2000 compiler, Visual C++ 6, made that the source doesn't show.

- **Rounding points.** VC6 did the arithmetic on the x87 unit at 53-bit precision. It rounded a value to `float` only when it stored it to a `float` in memory. Some values stayed in registers across operations, or across loop iterations, at full precision (findings, section 3).
- **The math library.** `sin`, `cos`, `fmod`, `exp`, `pow` and `sqrt` come from VC6's C runtime, linked into the DLL. They're built on x87 instructions; the DLL's disassembly contains `fsin` 4 times, `fcos` 2, `fprem` 9, `fprem1` 2, `f2xm1` 4, `fyl2x` 4, `fscale` 8 and `fsqrt` 2. Today's math library computes these differently, and its last bits differ.
- **Constant folding and constant types.** Which constants VC6 combined at compile time, and whether each is a `float` or a `double`. For example, the noise band 1 step uses `2.5f` and `40.f`, while noise band 2 uses `2.5` and `40`, which are doubles (`drumsynth.c` lines 380 and 392).
- **Conversions.** How floats become integers (VC6's `_ftol`), and how text becomes numbers (VC6's `sscanf("%f")`).

All of this can be read from the DLL's machine code. Reading it is the core of the plan.

## Everything that has to match

| # | What | How it will be matched | How it will be checked |
|---|---|---|---|
| 1 | Rounding points: which values are stored as `float`, which stay at 53-bit precision | Read from the disassembly; in C, `double` for register values and `float` exactly where the DLL stores to `float` | Render comparison; single-feature test presets |
| 2 | Order of operations and constant types | Copied from the disassembly, including constants VC6 folded | Same |
| 3 | `sin`, `cos`, `fmod`, `exp`, `pow`, `sqrt` | The same x87 instructions, in the same sequence as VC6's runtime routines, written in 64-bit assembly (`ml64`). x64 processors still execute x87 instructions, and 64-bit Windows saves their state | Call the DLL's own routines on millions of inputs and compare bit for bit (see "Calling the DLL's internal functions") |
| 4 | Values that pass between operations at 80-bit precision, such as a `fsin` result used straight in a multiply | Where the disassembly shows such chains, the whole chain is written in assembly, so the value never passes through a 64-bit `double` | Render comparison |
| 5 | Float to integer: `(short)`, `(int)`, `(long)` | Truncation, as in VC6's `_ftol`, including what happens out of range | Test presets with extreme levels and gains |
| 6 | Random numbers | The VC6 `rand()` formula (`seed * 214013 + 2531011`, result `(seed >> 16) & 0x7FFF`), reseeded with 1 on every render. To be confirmed in the disassembly | Noise-only test presets |
| 7 | Text to numbers | The same results as VC6's `sscanf("%f")`, parsing to `double` then rounding to `float`, if that's what the disassembly shows | Every number string in every preset, and generated ones, parsed by the DLL's own routine and by the rewrite |
| 8 | Reading `.ds` files | The same results as `GetPrivateProfileString` / `GetPrivateProfileInt`: the first occurrence of a key, case-insensitive names, trimming, the default values, and the 16-character limit of the original's `GetPrivateProfileFloat` buffer | Every preset and generated odd files read by the Windows functions and by the rewrite's parser, compared value by value |
| 9 | Envelope parsing, including its quirks | The same values as the original's `getEnv()` for every valid input. Overlong numbers are handled safely; the original would overflow there, and no preset has one | All envelope strings in all presets, plus generated ones |
| 10 | Length of the sound | The same `LongestEnv()` arithmetic | Lengths in the render comparison |
| 11 | Clipping and output | The same clip point logic and the same conversion to 16-bit | Render comparison |
| 12 | The WAV file, byte for byte | The same header and INFO chunk: software name, comment, padding, and the original's length fields | A byte comparison of whole files, a new option in `compare_wavs.py` |
| 13 | The state at the start of a render | Everything zeroed, matching the reference's "first sound after start"; `Ot` starts at 0 | Reverse-order batch renders must be identical |
| 14 | `ds2mem()`, the in-memory path with per-section level, tuning and time factors (`mem_t`, `mem_o`, `mem_n`, `mem_b`, `mem_tune`, `mem_time`) | The same arithmetic; the GUI may use it for playback (to be checked in `gui/`) | Calling the DLL's `ds2mem` and `ds2buf` with the same factors |

## Calling the DLL's internal functions

The DLL exports only `ds2wav`, `ds2mem` and `ds2buf`. But its internal functions sit at fixed addresses inside it: its math routines, its `sscanf`, its `rand`. Once the disassembly identifies them, a 32-bit test program can load the DLL and call them directly by address. That gives exact reference values for any input, not only what can be heard in a render:

- the math routines on millions of inputs, including the ranges the engine uses (phases 0 to 2π, envelope products, the arguments of `exp` and `pow` in the droop and gain formulas);
- the number parser on every number string found in the presets, plus generated ones;
- `rand()` sequences.

The rewrite's routines are tested against these tables bit for bit. A difference shows up at its source, before it can disappear into a render.

## Test material beyond the 849 presets

The presets only exercise the code paths that someone happened to use. To cover the rest:

- **Single-feature test presets**, generated by a script, `tools/probes/`. Each section is used alone, swept across its parameters:
  - tone, with and without droop;
  - noise, with every slope from −100 to 100;
  - each overtone method with each pair of waveforms, with and without tracking;
  - noise bands, across frequency and width;
  - distortion, with every Bits and Rate setting;
  - the filter, low-pass and high-pass, across resonance;
  - stretch and tuning.

  A difference then points at one section.
- **Random presets**, generated by a seeded script, `tools/fuzz/`. All values come from the original GUI's ranges, plus edge values: level 1 and 181, empty and single-point envelopes, 32-point envelopes, extreme frequencies, missing keys and version 1 files. Thousands of these are rendered with ref and the rewrite.
- **The CPU.** It's recorded in every render set's `info.txt`, because the transcendental x87 instructions may give different last bits on different processors (see "Risks").

## Phases

Each phase ends with a commit, a report in `docs/reports/`, and its results written into [findings.md](findings.md).

1. **Read the machine code.**
   - **What:** disassemble `bin/ds2wav.dll` with `dumpbin /disasm`.
   - **Which functions:**
     - `ds2wav` (at relative address `0x1590`), `ds2mem` (`0x14C0`) and `ds2buf` (`0x1530`);
     - the internal functions `getEnv`, `UpdateEnv`, `LongestEnv`, `LoudestEnv`, `waveform` and `GetPrivateProfileFloat`;
     - the runtime routines they call: `sin`, `cos`, `fmod`, `exp`, `pow`, `sqrt`, `rand`, `srand`, `sscanf`, `_ftol`.
   - **Output:** `docs/disasm/`, holding the listing with each block matched to its source lines, and a table of every variable and intermediate value with where it lives (`float` in memory, `double` in memory, x87 register) and where it's rounded.
   - **Done when** every floating-point operation in the synthesis loop is accounted for.
2. **Build the test material.**
   - The test program that calls the DLL's internal functions, with reference tables.
   - The single-feature presets and the random presets.
   - The whole-file byte comparison in `compare_wavs.py`.
   - The CPU recorded in `info.txt`.
   - A list of reference checksums for all renders (`docs/reference/`), so regressions can be checked quickly.
3. **The engine skeleton.**
   - **Code:** `engine/` with a public header, the state structure, the parser, the random generator, the WAV writer, the render function, and an `engine/x87/` folder for the assembly.
   - **Renderer:** `c17_render` in `tools/renderers/`, and `c17` in `render_all.py`.
   - **Arithmetic:** plain `double` to start with.
   - **Report:** `ref-vs-c17`, the baseline.
4. **Rounding points and constants (items 1, 2, 5)** from phase 1. Report.
5. **The x87 math routines (item 3)** in assembly, tested bit for bit against the DLL's own routines. Report.
6. **80-bit chains (item 4)**, where phase 1 found them. Report.
7. **Parsing (items 7–9)**, tested value by value against the DLL and the Windows functions. Report.
8. **WAV bytes and `ds2mem` (items 12, 14).** Report.
9. **Hardening.**
   - The single-feature and random presets all come out identical.
   - Edge cases: denormal numbers, NaN, very large values.
   - Performance is checked.
   - Report.
10. **Freeze.** The reference checksums become the engine's regression test. Every later change must keep them, or explain in findings.md why not.

Phases 4 to 7 can overlap: each fix is measured as soon as it's made.

## Risks and how they're handled

- **CPU dependence.** `fsin`, `fcos`, `f2xm1` and `fyl2x` are not specified to the last bit. Intel and AMD processors, and different generations, may differ in rare cases.
  - Executing the same instructions makes the rewrite match the DLL **on the same machine**, whatever that machine is.
  - The reference checksums are recorded with the CPU model; the current machine is an Intel Core i7-8850H.
  - If another CPU gives different results, that's documented, not hidden.
- **x87 in 64-bit code.** MSVC has no inline assembly in 64-bit builds, so the routines go into `.asm` files assembled with `ml64` (installed with Visual Studio). Values pass in and out through SSE registers as 64-bit `double`s. A value the original kept at 80 bits between two operations therefore has to stay inside one assembly routine (item 4).
- **Underflow and the exponent range.** x87 registers have a much larger exponent range than `double` or `float`. A value that underflows to 0 as a `float` can survive in a register. The pitch droop computes `exp(-171.9)` for some presets. Matching the store points (item 1) handles this, and the single-feature presets check it.
- **Effort.** Reading the machine code is the largest single task, but it's bounded. It covers one synthesis function and about a dozen runtime routines; the whole DLL is 18,366 lines of disassembly, most of it C runtime code that isn't used.
- **Things that can't be reproduced.** The behaviour that depends on stack garbage or on the previous sound (findings, sections 4 and 5) is replaced by the defined starting state on purpose. That's the documented reference, not a deviation.

## Alternatives considered

- **Run the original DLL in a 32-bit helper process.** Exact by definition, but it isn't a rewrite: it keeps the bugs (`Ot`, the carry-over between renders), can't be extended, and depends on a 32-bit binary forever. It's useful only as the reference.
- **Software emulation of the x87 unit** (for example, an 80-bit floating-point library). That makes the arithmetic exact, but `fsin`, `f2xm1` and the others aren't specified to the bit, so it couldn't match them. Executing the real instructions is more exact.
- **`double` everywhere.** Cheap, and probably close to the original, but not exact. It's the phase 3 baseline, which shows how much each later phase gains.
