# Render comparison reports

Each report compares two render sets of the same 849 presets. It was made by `tools/compare_wavs.py A B` (see [../rendering.md](../rendering.md)), and comes as a markdown file, `A-vs-B.md`, and a CSV with every preset, `A-vs-B.csv`. What the results mean is explained in [../findings.md](../findings.md).

All of these were rendered on 2026-11-08 from commit `2dcdfbe`, with the renderers in `tools/renderers/` at the state of the commit that added this file. Unless a name says otherwise, each preset was rendered in a process of its own with the stack cleared, which is the reference conditions.

## The render sets

| Name | Engine | Conditions |
|---|---|---|
| `ref` | original `bin/ds2wav.dll` | Windows default x87 precision (53 bits), one process per preset, stack cleared. **The reference.** |
| `ref-fpu24` | original DLL | x87 precision 24 bits |
| `ref-batch` | original DLL | all presets in one process, normal order |
| `ref-batch-reverse` | original DLL | all presets in one process, reverse order |
| `ref-raw-stack` | original DLL | stack not cleared before rendering |
| `src` | original `drumsynth.c`, today's MSVC, 32-bit | |
| `new-x86` | modern port `src/DrumSynth.Core`, 32-bit | |
| `new` | modern port, 64-bit | |
| `original` | the 6 WAVs saved by the original program | not rendered |

## The reports

Counts are presets per category: identical / within 1 step / small / large.

| Report | What it shows | Identical | Within 1 | Small | Large |
|---|---|---|---|---|---|
| [ref-vs-original](ref-vs-original.md) | The reference renderer reproduces the original program. The 2 WAVs without noise are identical; the 4 with noise differ in their random sequence. Only 6 presets have a WAV. | 2 | 0 | 1 | 3 |
| [ref-vs-ref-raw-stack](ref-vs-ref-raw-stack.md) | What the uninitialized `Ot` does when the stack isn't cleared (findings, section 4) | 661 | 0 | 0 | 188 |
| [ref-batch-vs-ref-batch-reverse](ref-batch-vs-ref-batch-reverse.md) | One render changes the next: the order matters when everything runs in one process (section 5) | 360 | 85 | 358 | 46 |
| [ref-vs-ref-batch](ref-vs-ref-batch.md) | Fresh start for every preset compared with one process for all (section 5) | 465 | 74 | 277 | 33 |
| [ref-vs-ref-fpu24](ref-vs-ref-fpu24.md) | How much the x87 precision changes the original's sound (section 3) | 91 | 196 | 207 | 355 |
| [ref-fpu24-vs-src](ref-fpu24-vs-src.md) | At 24-bit precision the DLL is close to its source built today: the DLL is this source (section 2) | 167 | 305 | 272 | 105 |
| [ref-vs-src](ref-vs-src.md) | The original source built with today's compiler, against the original binary: the compiler alone (sections 2 and 3) | 75 | 188 | 213 | 373 |
| [src-vs-new-x86](src-vs-new-x86.md) | The modern port against the original source, both built the same way: the port's code changes. The 5 large ones are the `Ot` bug (section 4) | 843 | 1 | 0 | 5 |
| [src-vs-new](src-vs-new.md) | The modern port as 64-bit against the original source as 32-bit. In this build the `Ot` slot happens to hold 0, so only 64-bit vs 32-bit rounding remains | 820 | 19 | 9 | 1 |
| [new-x86-vs-new](new-x86-vs-new.md) | The modern port as 32-bit and as 64-bit. The 5 `Ot` presets plus `spicy bd` | 814 | 20 | 9 | 6 |
| [ref-vs-new](ref-vs-new.md) | **Where the modern port stands against the reference.** This is the starting point for the C17 rewrite. | 75 | 188 | 213 | 373 |

`ref-vs-new` and `ref-vs-src` put every preset in the same category: the 29 presets where `src` and `new` differ are already in the same category against `ref`, and their values only move slightly.

## Remaking the reports

```
for r in ref ref-fpu24 src new new-x86 original; do python tools/render_all.py $r; done
python tools/render_all.py ref --batch --name ref-batch
python tools/render_all.py ref --batch --order reverse --name ref-batch-reverse
python tools/render_all.py ref --raw-stack --name ref-raw-stack
python tools/compare_wavs.py ref original
python tools/compare_wavs.py ref ref-raw-stack
python tools/compare_wavs.py ref-batch ref-batch-reverse
python tools/compare_wavs.py ref ref-batch
python tools/compare_wavs.py ref ref-fpu24
python tools/compare_wavs.py ref-fpu24 src
python tools/compare_wavs.py ref src
python tools/compare_wavs.py src new-x86
python tools/compare_wavs.py src new
python tools/compare_wavs.py new-x86 new
python tools/compare_wavs.py ref new
```

The renderers must be built first (see [../rendering.md](../rendering.md)). `ref-raw-stack` depends on what the host program leaves on the stack, so its numbers can change when `ref_render.exe` is rebuilt. All the other sets are reproducible.
