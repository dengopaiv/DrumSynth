# Envelope library

Envelope shapes taken from the DrumSynth preset collections, meant as a list of ready shapes for the accessible envelope editor. The faithful way to move envelopes between presets is still the original's Copy and Paste; this library is an extra on top of it.

## Files

One file per envelope type, in the order of DrumSynth's envelope selector:

| File | Envelope | Entries | Share of that envelope's uses |
|---|---|---|---|
| `tone.ini` | Tone | 78 | 67% |
| `noise.ini` | Noise | 83 | 74% |
| `overtones-1.ini` | Overtones 1 | 76 | 74% |
| `overtones-2.ini` | Overtones 2 | 69 | 81% |
| `noise-band-1.ini` | Noise Band 1 | 72 | 72% |
| `noise-band-2.ini` | Noise Band 2 | 49 | 87% |
| `filter.ini` | Filter | 65 | 64% |

Entries in each file are sorted from most used to least used.

## Format

INI-style, UTF-8, one section per envelope:

```ini
[Envelope 1]
Name=100%, 20% at 39.7 ms, 0% at 119 ms
Envelope=0,100 1750,20 5250,0
Uses=86
TotalUses=86
Examples=bad bd.ds; bassface.ds; blip.ds; club bd.ds; creaker.ds
```

- **Envelope** uses the same syntax as the `Envelope=` keys in `.ds` files: `time,level` pairs separated by spaces. Time is in samples at 44.1 kHz before Stretch is applied, and level is 0–100 %. The value can be pasted into a `.ds` file as it is.
- **Name** is generated from the points so that it reads well aloud. Times use the original GUI's rounding (`toTime` in `gui/DRUMSYN.FRM`): three decimals under 10 ms, one decimal under 100 ms, whole ms above. Envelopes with more than 5 points are summarized: the point count, the start level, the peak if it's higher than the start, and the end. Levels are given in %, as stored in the file. The original GUI shows them in dB, except for Overtones 2 and Filter.
- **Uses** counts the presets that use this shape for this envelope type. **TotalUses** counts the presets that use it for any envelope type.
- **Examples** lists up to 5 presets using it, as `<collection>/<path>`. `library/` is `bin/library.zip` and `drumsynths/` is the `drumsynths/` folder.
- "Hold at 100% (envelope off)" entries are DrumSynth's way of switching an envelope off: full level until about 10 s (`442000` samples). They are mostly used for the filter.

## How it was made

```
python tools/make_envelope_library.py docs/envelopes
```

- **Sources:** the two collections in the repository, `bin/library.zip` (764 `.ds` files, the collection shipped with DrumSynth 2.0) and `drumsynths/` (687). The 602 files that appear in both are counted once, which leaves 849 unique presets. Presets are loaded by `tools/dslib.py`, the same loader the render tools use, so the library and the render reports cover exactly the same presets.
- **Reading envelopes:** a key is read the way DrumSynth reads it, the first occurrence in its section, like `GetPrivateProfileString`.
- **Totals:** those presets contain 5,897 envelopes in 1,713 distinct shapes.
- **What's kept:** a shape is kept if it is used 3 or more times across all envelope types. That gives 461 shapes, covering 74% of all envelope uses.
- **Where shapes appear:** a kept shape is listed in every type it was used in, so the per-file entries add up to more than 461.
- **What's left out:** 991 shapes are used only once.
- **Cutoff:** to change it, edit `MIN_USES` in the script.
- **Comparing shapes:** two shapes count as the same only when every point is the same. Scaling time doesn't merge shapes. With time normalized there are still 1,628 shapes at 1% precision and 1,400 at 5%, so the presets really are that varied.
- **Regenerating:** both sources are tracked in git, so the command above works on a fresh clone. Other collections can be given after the output folder.
- **History:** the first version (commit `b4e8ef9`) was built from `drumsynths/` and an untracked `release/library/` folder (the same presets as `bin/library.zip`). Switching to the tracked sources changed only the `Examples` lines; every shape, name and count stayed the same.
