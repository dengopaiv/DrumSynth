# DrumSynth engine (C17, 64-bit Windows)

The DrumSynth 2.0 engine, rewritten so that it gives **exactly** the output of the original `bin/ds2wav.dll`, sample for sample and byte for byte. It is byte-identical on:
- all 849 presets;
- 454 single-feature test presets;
- the 1995 of 2000 random presets that the original can render. It hangs on the other 5; the engine flags them with `DS_NOTE_HANG`.

The reference conditions are in [docs/findings.md](../docs/findings.md); how it was done is in [docs/rewrite-plan.md](../docs/rewrite-plan.md) and [docs/disasm/README.md](../docs/disasm/README.md).

## Building

Visual Studio with the C++ tools (MSVC and ml64), and CMake:

```
cmake -S engine -B build/engine -A x64
cmake --build build/engine --config Release
```

This gives a static library, `drumsynth_engine`. The renderers in `tools/renderers` and the probes in `tools/probes` include it as a subdirectory. The engine is 64-bit only, because its x87 routines are ml64 assembly.

## Using it

```c
#include "drumsynth.h"

/* like the original ds2wav(): .ds file in, WAV file out */
int r = ds_render_file("C:\\sounds\\kick.ds", "C:\\sounds\\kick.wav");

/* or in memory */
ds_ini* ini = ds_ini_parse(text, length);      /* .ds text, parsed like Windows does */
ds_source src = ds_ini_source(ini);
ds_sound sound;
if (ds_render(&src, NULL, &sound) == DS_OK) {  /* NULL: ds2wav's factors */
    /* sound.samples: sound.length 16-bit samples at 44.1 kHz, mono */
    ds_write_wav("out.wav", &sound);           /* the original's exact file */
    ds_sound_free(&sound);
}
ds_ini_free(ini);
```

- **Result codes** are the original's:
  - 0: OK;
  - 1: wrong version;
  - 2: not a DrumSynth file;
  - 3: cannot write, or out of memory.
- **The `ds_factors` argument** reproduces the original's `ds2mem()` level, tuning and time factors.
- **`ds_sound.notes`** flags the rare inputs where the rewrite can't follow the original. Examples are where the original would hang, or would read uninitialized memory. None of the presets does this. See `drumsynth.h` and findings section 9.
- **No global state:** renders are independent and can run in parallel.

## Files

| File | What it is |
|---|---|
| `include/drumsynth.h` | The public interface |
| `src/ds_engine.c` | The synthesis: a transcription of `ds2wav()` from the DLL's machine code, with the DLL's addresses in comments |
| `src/ds_vc6.c`, `ds_vc6.h` | Visual C++ 6 runtime behaviour: `_ftol`, `rand`, `sscanf("%f")`'s scanning, `pow` and `fmod` special cases |
| `src/ds_vc6_fltin.c` | VC6's text-to-float conversion (`__strgtold12`, `__ld12mul`, `_ld12cvt`), transcribed, including its rounding quirk |
| `x87/ds_x87.asm`, `src/ds_x87.h` | The x87 sequences: `fsin`, `fcos`, `pow` (`fyl2x`/`f2xm1`/`fscale`) and the inlined `exp` |
| `src/ds_ini.c` | `.ds` parsing by the rules of `GetPrivateProfileStringA`/`IntA` ([docs/reference/ini-rules.md](../docs/reference/ini-rules.md)) |
| `src/ds_source_win.c` | A source calling the Windows functions themselves, for comparison |
| `src/ds_wav.c` | The WAV writer, the file the original writes, byte for byte, and `ds_render_file` |

## Rules for changing the engine

1. **The reference checksums are the specification.** `python tools/check_reference.py` must report 0 differences after every change. If a change is meant to alter the sound, explain why in `docs/findings.md`.
2. **Keep `/fp:precise`**, so the compiler doesn't contract or reorder `double` arithmetic. Don't build with `/fp:fast`.
3. **Keep the order of operations and every `float`/`double` boundary as they are.** Each one is the DLL's. When in doubt, read `docs/disasm/ds2wav-engine.asm` at the address in the comment.
4. **`tools/probes/run_probes.py`** must still report 0 differences after any change to `ds_vc6*.c`, `ds_x87.asm` or `ds_ini.c`.
