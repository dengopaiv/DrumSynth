# Render comparison: how to run it

The render comparison renders every preset with two engines and compares the WAV files sample by sample. It is how the C17 rewrite gets checked against the original DrumSynth: after every change, render with the rewrite and compare with **ref**, the original DLL. What the comparisons have found so far is in [findings.md](findings.md); the reports are in [reports/](reports/README.md).

Everything here runs on Windows. It needs CMake, Visual Studio with the C compiler (x86 and x64), and Python 3 with numpy.

## The pieces

| File | What it does |
|---|---|
| `tools/renderers/` | Small C programs that turn `.ds` files into `.wav` files, one per engine. They share one command line (`renderer_main.c`). |
| `tools/dslib.py` | Shared Python code: loads the preset collections, removes duplicates, parses `.ds` files, lists the features a preset uses, reads WAV files. |
| `tools/render_all.py` | Renders every unique preset with one renderer into `renders/<name>/`. |
| `tools/compare_wavs.py` | Compares two render sets and writes a markdown report and a CSV to `docs/reports/`. |

`renders/` is not tracked by git: one render set of all 849 presets is about 71 MB. Reports are tracked.

## 1. Build the renderers

```
cmake -S tools/renderers -B build/renderers-x86 -A Win32
cmake --build build/renderers-x86 --config Release
cmake -S tools/renderers -B build/renderers-x64 -A x64
cmake --build build/renderers-x64 --config Release
```

The 32-bit build makes `ref_render.exe`, `src_render.exe` and `new_render.exe`. The 64-bit build makes `new_render.exe`, `c17_render.exe` (the C17 rewrite, `engine/`) and `c17_libm_render.exe` (a diagnostic variant of it). `build/` is not tracked by git.

| Program | Engine | Notes |
|---|---|---|
| `ref_render.exe` (32-bit) | the original `bin/ds2wav.dll` | Loads the DLL at run time (`--dll PATH`) and calls `ds2wav()` the way the VB6 GUI does. Must be 32-bit, because the DLL is. |
| `src_render.exe` (32-bit) | the original `drumsynth.c`, unmodified | Compiled with `/GS-`: the original writes one byte past a buffer in `getEnv()`, and the stack check would stop the program. |
| `new_render.exe` (32- and 64-bit) | the modern port `src/DrumSynth.Core/drumsynth.c` | Calls `ds_to_wav()`. |
| `c17_render.exe` (64-bit) | the C17 rewrite, `engine/` | Calls `ds_render_file()`. `--dll winapi` reads presets with the Windows profile functions instead of the engine's own parser. |
| `c17_libm_render.exe` (64-bit) | the C17 rewrite built with `DS_ABLATE_LIBM` | Today's C library for `sin`, `cos`, `pow`, `exp`, `fmod` and text-to-float. Shows what the x87 reproduction is worth (findings, section 8). |

### The renderers' command line

```
<renderer> [--dll PATH] [--fpu 24|53|64] [--no-clear-stack] IN.ds OUT.wav
<renderer> [--dll PATH] [--fpu 24|53|64] [--no-clear-stack] LISTFILE
```

- **LISTFILE** has one `IN.ds<TAB>OUT.wav` per line. All the files are rendered in one process.
- **Output:** for every file, the renderer prints `<result code><TAB><input>`. The exit code is 0 when everything rendered, 1 when something failed and 2 for a usage or setup error.
- **Paths** are made absolute before they're passed on. The original engine looks in the Windows folder when it's given a bare file name.
- **`--dll PATH`** is for `ref_render` only: the DLL to load.
- **`--fpu 24|53|64`** sets the x87 precision. It's for 32-bit builds only and is applied after the DLL is loaded. The precision in effect is printed on stderr.
- **`--no-clear-stack`** skips zeroing the stack before each render. Normally 256 KB of stack is zeroed first, because the original reads the uninitialized variable `Ot` (findings, section 4).

## 2. Render

```
python tools/render_all.py ref
python tools/render_all.py new
```

Renderers known to `render_all.py`:

| Name | What |
|---|---|
| `ref` | original DLL, Windows default precision (53 bits). **The reference.** |
| `ref-fpu24` | original DLL at 24-bit precision (diagnostic) |
| `src` | original source, today's compiler, 32-bit |
| `new` | modern port, 64-bit |
| `new-x86` | modern port, 32-bit |
| `c17` | **the C17 rewrite** (`engine/`), 64-bit, its own `.ds` parser |
| `c17-winapi` | the C17 rewrite reading presets with the Windows functions |
| `c17-libm` | diagnostic: the C17 rewrite with today's C library math |
| `original` | no rendering: copies the 6 WAVs saved by the original program |
| `custom` | any program with the same command line: `--exe PROGRAM [OPTIONS] --name NAME [--description TEXT]` |

Options:

- **`--name NAME`** writes to `renders/NAME/` instead of `renders/<renderer>/`.
- **`--batch`** renders all presets in one process. The default is one process per preset, so every render starts like the first sound after DrumSynth starts (findings, section 5). Use `--batch` only to study how one render affects the next.
- **`--order reverse`** renders in reverse order. With `--batch`, this shows the carry-over between renders.
- **`--raw-stack`** passes `--no-clear-stack` to the renderer.
- **`--collections PATH ...`** uses other preset folders or zips. The default is `bin/library.zip` and `drumsynths/`.
- **`--out DIR`** writes somewhere other than `renders/`.
- **`--jobs N`** renders N presets at once, each in its own process. The default is the number of processors. It has no effect with `--batch`.
- **`--timeout S`** stops a render after S seconds and counts it as failed, "no result". The default is 120. Some inputs make the original DLL loop forever (findings, section 9).
- The C17 renderer reports its notes (`DS_NOTE_*`) on stderr. `render_all.py` collects them, and any timeouts, in `renders/<name>/notes.csv`.

What a run writes:

- `renders/presets/NNNN.ds`: the 849 unique presets, numbered. Numbered ASCII names keep the original engine's ANSI file functions away from names like "JürgenSohn".
- `renders/<name>/NNNN.wav`: one render per preset.
- `renders/<name>/manifest.csv`: the id, collection path, checksum and features of each preset.
- `renders/<name>/info.txt`: what rendered it, from which commit (with a note if `src/`, `drumsynth.c` or `engine/` had uncommitted changes), the mode, the order, the date, **the CPU** and the counts. The CPU matters because the x87 transcendental instructions may differ in their last bit between processor models.
- `renders/<name>/failures.csv`: presets the renderer reported an error for.

A full run takes 20–35 seconds per renderer in the default mode.

## 3. Compare

```
python tools/compare_wavs.py ref new
```

This writes `docs/reports/ref-vs-new.md` and `docs/reports/ref-vs-new.csv`. `--report PATH`, `--csv PATH` and `--renders DIR` change the locations; `--worst N` sets how many presets the report lists. Both sets must come from the same preset list; the script stops if their manifests differ.

What is measured for each preset (CSV columns):

| Column | Meaning |
|---|---|
| `tier` | identical, within 1 step, small, large, or length differs (see below) |
| `length a`, `length b` | number of samples |
| `differing samples` | how many samples are not the same |
| `max diff` | the largest difference of a single sample, of 32768 |
| `diff dBFS` | RMS of the difference, relative to full scale |
| `diff vs sound dB` | RMS of the difference relative to the RMS of A: how loud the difference is compared with the sound |
| `first diff ms` | where the first difference is |
| `peak a`, `peak b`, `rms a dBFS` | levels |
| `clipped a`, `clipped b` | samples at DrumSynth's clip point (32700) or beyond |
| `lag` | for large differences only: a shift of up to ±64 samples that makes B match A to −60 dB, if there is one |
| `file bytes identical` | 1 if the whole WAV files are byte for byte the same (header, samples, INFO chunk) |
| `features` | the DrumSynth features the preset uses (from `dslib.features()`) |

The categories:

- **identical**: every sample is the same, and the lengths match.
- **within 1 step**: no sample differs by more than 1. That's rounding.
- **small**: the difference is at least 60 dB below the sound.
- **large**: anything else. A real difference that needs explaining.
- **length differs**: the lengths don't match. The other figures cover the part both have.

The report lists:

- the two render sets, with their descriptions and commits;
- how many presets fall in each category;
- a table **by feature** showing which DrumSynth features the differing presets use. A feature whose presets are all identical can't be the cause. Sorted by the number of large differences;
- the presets with the **largest differences**.

## More test presets

`tools/probes/make_presets.py` generates presets beyond the 849 real ones:
- `features`: single-feature sweeps and edge cases;
- `fuzz`: random presets from a seed.

Render and compare them in their own folders:

```
python tools/probes/make_presets.py features renders/gen/features
python tools/render_all.py ref --collections renders/gen/features --out renders/features
python tools/render_all.py c17 --collections renders/gen/features --out renders/features
python tools/compare_wavs.py ref c17 --renders renders/features --report docs/reports/features-ref-vs-c17.md
```

The same works with `fuzz renders/gen/fuzz --count 2000` and `--out renders/fuzz`.

`tools/probes/run_probes.py` compares the DLL's internal routines with the engine's, and Windows' profile functions with the engine's parser. Its report is [reference/probes.md](reference/probes.md).

## The regression test

`python tools/check_reference.py` renders the three sets (presets, features, fuzz) with `c17`. It compares every WAV file with the MD5 checksums of the DLL's renders in [reference/checksums.csv](reference/checksums.csv), and reports any difference. It runs in a few minutes. `--update` rewrites the checksums from the ref renders; do that only when the reference itself changes.

## Checking a change to the engine

0. For the C17 engine: `python tools/check_reference.py` must still report 0 differences.
1. Change the engine and rebuild the renderer.
2. Render: `python tools/render_all.py new`, or `custom` for an experimental build.
3. Compare against the reference: `python tools/compare_wavs.py ref new`.
4. Compare against the previous state too, to see exactly what the change did. Keep the old render set under another name with `--name`.
5. Commit the report together with the change, and add any new explanation to [findings.md](findings.md).
