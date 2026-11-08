# DrumSynth

A faithful, screen-reader-accessible recreation of **mda DrumSynth 2.0**, the drum sound synthesizer by Paul Kellett (1998–2000). This repository is the upstream for it.

The original source and binary are kept as the specification. A new engine (C17, 64-bit, Windows) and a wxWidgets GUI are being built against it. Every change to the engine is checked by rendering all 849 presets and comparing them sample by sample with the original DLL. See [docs/plan.md](docs/plan.md).

## What's here

| Path | What it is |
|---|---|
| `drumsynth.c`, `drumsynth.h` | Original DrumSynth 2.0 engine source (the `ds2wav.dll` renderer) |
| `gui/` | Original Visual Basic 6 GUI |
| `dll/` | Original DLL project files |
| `help/` | Original WinHelp source |
| `bin/` | Original binaries: `drumsyn.exe`, `ds2wav.dll`, `drumsyn.hlp`, and `library.zip`, the preset library shipped with 2.0 (764 presets) |
| `drumsynths/` | A later preset collection: 687 presets in 29 folders (86 of them exist nowhere else), and 6 WAVs saved by the original program |
| `src/` | The earlier modern port: the engine in `src/DrumSynth.Core/` and a C#/WPF app in `src/DrumSynth.App/`. Kept for reference |
| `tools/` | Render comparison and analysis tools ([tools/README.md](tools/README.md)) |
| `docs/` | Plan, findings, how-tos, reports and the envelope library ([docs/README.md](docs/README.md)) |
| `BUILD.md` | How to build the WPF port |

## Branches

- `master`: the original DrumSynth 2.0 files.
- `modern-wpf`: the WPF port.
- `refactor`: current work. The tools, the docs, the preset collection and the rewrite.

## Licence

Original DrumSynth © 1998–2000 Paul Kellett, released under the MIT licence (`MIT License.txt`) or the GPL, version 2 or (at your option) any later version (`gpl-2.0.txt`); see `readme.license`.
