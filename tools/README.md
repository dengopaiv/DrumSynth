# Tools

Scripts and programs for studying the original DrumSynth 2.0 and checking the rewrite against it. Python 3 (3.10 or newer; 3.13 is used), standard library plus numpy for `compare_wavs.py`. Windows for the renderers.

| Tool | What it does | Documentation |
|---|---|---|
| `renderers/` | C programs that render `.ds` files to `.wav`: `ref_render` (the original `bin/ds2wav.dll`), `src_render` (the original `drumsynth.c`), `new_render` (the modern port). One shared command line in `renderer_main.c`. Built with CMake. | [docs/rendering.md](../docs/rendering.md) |
| `dslib.py` | Shared Python module: loads the preset collections (`bin/library.zip` and `drumsynths/` by default), removes duplicate presets, parses `.ds` files like `GetPrivateProfileString`, names the features a preset uses, reads WAV files. | the module's docstrings |
| `render_all.py` | Renders all 849 unique presets with one renderer into `renders/<name>/`, one process per preset by default. | [docs/rendering.md](../docs/rendering.md) |
| `compare_wavs.py` | Compares two render sets sample by sample; writes a markdown report and a CSV to `docs/reports/`. | [docs/rendering.md](../docs/rendering.md) |
| `make_envelope_library.py` | Builds the envelope library in `docs/envelopes/` from the presets. | [docs/envelopes/README.md](../docs/envelopes/README.md) |

Run the Python tools from the repository root, for example `python tools/render_all.py ref`. They find the repository from their own location, so the current folder only matters for relative paths you pass in.

## Notes on the code

- **Same presets everywhere:** every tool loads presets through `dslib.load_presets()`. The envelope library and the render reports therefore cover exactly the same 849 presets. A preset found in both collections counts once, under the first collection; byte-identical files count as the same, ignoring CR characters.
- **Reading keys like the original:** `dslib.parse_ds()` lower-cases section and key names and keeps the *first* occurrence of a key, as Windows' `GetPrivateProfileString` does.
- **Original WAVs:** `dslib` picks up a WAV saved next to a preset with the same name. If the preset is a duplicate, the WAV is moved to the copy that is kept, which is how `Percussion/Shaker_1.WAV` ends up with `library/Latin/Shaker_1.ds`.
- **Why the renderers zero the stack and start fresh processes:** see [docs/findings.md](../docs/findings.md), sections 4 and 5.
