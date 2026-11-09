# DrumSynth

A faithful, screen-reader-accessible recreation of **mda DrumSynth 2.0**, the drum sound synthesizer by Paul Kellett (1998–2000). This repository is the upstream for it.

The original source and binary are kept as the specification. The new engine (`engine/`, C17, 64-bit, Windows) renders every preset byte for byte identical to the original DLL, and the accessible wxWidgets GUI (`app/`) does everything the original program did. Every change to the engine is checked against the original's frozen checksums (`tools/check_reference.py`). See [docs/plan.md](docs/plan.md).

## Download and use

The current release is **DrumSynth 4.0.0, accessible edition**: `DrumSynth-4.0.0-win64.zip` on the GitHub releases page, for Windows 10 or 11, 64-bit.
- Unzip it and start `DrumSynth.exe`; nothing is installed. It comes with 31 kits of sounds.
- Usage and keys: [docs/gui-help.md](docs/gui-help.md). The program's Help button opens it as a web page.
- File formats (`.ds`, `.dse`, WAV, `DrumSyn.ini`): [docs/reference/file-formats.md](docs/reference/file-formats.md).
- What's new: [docs/release-notes.md](docs/release-notes.md).

## Building

- The engine: [engine/README.md](engine/README.md).
- The program: [app/README.md](app/README.md), which needs Visual Studio, CMake and wxWidgets from vcpkg.
- A full release, built, tested and zipped into `dist/`: `python tools/make_release.py`.

## What's here

| Path | What it is |
|---|---|
| `drumsynth.c`, `drumsynth.h` | Original DrumSynth 2.0 engine source (the `ds2wav.dll` renderer) |
| `gui/` | Original Visual Basic 6 GUI |
| `dll/` | Original DLL project files |
| `help/` | Original WinHelp source |
| `bin/` | Original binaries: `drumsyn.exe`, `ds2wav.dll`, `drumsyn.hlp`, and `library.zip`, the preset library shipped with 2.0 (764 presets) |
| `drumsynths/` | A later preset collection: 687 presets in 29 folders (86 of them exist nowhere else), and 6 WAVs saved by the original program |
| `engine/` | **The C17 engine**, exact to the original ([engine/README.md](engine/README.md)) |
| `app/` | **The accessible wxWidgets GUI** on the engine ([app/README.md](app/README.md)) |
| `src/` | The earlier modern port: the engine in `src/DrumSynth.Core/` and a C#/WPF app in `src/DrumSynth.App/`. Kept for reference |
| `tools/` | Render comparison and analysis tools ([tools/README.md](tools/README.md)) |
| `docs/` | Plan, findings, how-tos, reports and the envelope library ([docs/README.md](docs/README.md)) |
| `BUILD.md` | How to build the WPF port (3.0) |

## Branches

- `master`: the main branch: the original DrumSynth 2.0 files, the C17 engine, the accessible GUI, the tools and the docs. Releases are made from it.
- `refactor`: where the 4.0 work was done; merged into `master`.
- `modern-wpf`: the 3.0 WPF port, kept for reference.

## Licence

Original DrumSynth © 1998–2000 Paul Kellett, released under the MIT licence (`MIT License.txt`) or the GPL, version 2 or (at your option) any later version (`gpl-2.0.txt`); see `readme.license`.
