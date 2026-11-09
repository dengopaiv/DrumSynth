# DrumSynth docs

Reference material for the faithful, screen-reader-accessible DrumSynth recreation. The original DrumSynth 2.0 source (`drumsynth.c`, `gui/`) and binary (`bin/ds2wav.dll`) are the specification for sound and features.

| Document | What's in it |
|---|---|
| [plan.md](plan.md) | Goal, decisions with dates and reasons, what's done, what's next |
| [rewrite-plan.md](rewrite-plan.md) | How the C17 engine will be made to match the original exactly: what has to match, how each part is checked, phases, risks |
| [disasm/](disasm/README.md) | The original DLL's machine code, annotated, and what it does that the source doesn't show: every rounding point, reordering, constant and runtime routine |
| [reference/file-formats.md](reference/file-formats.md) | **The file formats:** every key of a `.ds` sound file, how the engine reads it and what it does; `.dse` envelope files; the WAV files; the program's `DrumSyn.ini` |
| [reference/](reference/probes.md) | Reference data: the probe results (DLL routines vs the engine's, bit for bit), Windows' `.ds` reading rules ([ini-rules.md](reference/ini-rules.md)), and the checksums of all reference renders ([checksums.csv](reference/checksums.csv)) |
| [gui-checklist.md](gui-checklist.md) | Every feature of the original GUI, with its accessible equivalent and status |
| [release-notes.md](release-notes.md) | What each release brings |
| [gui-help.md](gui-help.md) | The help of the new GUI (the original help text, with the keys). The program shows it as `gui-help.html`, made by `tools/make_help_html.py`; keep the file to the Markdown that script supports. |
| [findings.md](findings.md) | How the original engine really behaves, measured: the reference, x87 precision, the uninitialized `Ot`, state carried between renders, and what the C17 rewrite has to do |
| [rendering.md](rendering.md) | How to build the renderers, render all presets and compare two engines |
| [reports/](reports/README.md) | The render comparison reports, with a table of what each one shows |
| [envelopes/](envelopes/README.md) | Library of envelope shapes found in the presets, one file per envelope type, in `.ds` syntax; shipped in the release as `.dse` envelope files |

The tools themselves are listed in [../tools/README.md](../tools/README.md); the engine is described in [../engine/README.md](../engine/README.md).
