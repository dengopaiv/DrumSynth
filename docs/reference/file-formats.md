# DrumSynth file formats

The files DrumSynth reads and writes:
- [`.ds` sound files](#ds-sound-files): every key, how the engine reads it, and what it does;
- [`.dse` envelope files](#dse-envelope-files), an addition of this edition;
- [the WAV files](#wav-files) the engine writes;
- [`DrumSyn.ini`](#drumsynini-the-programs-settings), the program's settings.

Written 2026-11-09 from the original source, which is the specification: `drumsynth.c` (the engine, `ds2wav.dll`) and `gui/drumsyn.bas` (the program's `openfile` and `savefile`). The C17 engine (`engine/`) and the accessible GUI (`app/`) read and write these files the same way, byte for byte. Line numbers below are in `drumsynth.c`.

## `.ds` sound files

A `.ds` file is a Windows INI file, ANSI (Windows-1252 on an English Windows), with CRLF line ends. The engine reads it with `GetPrivateProfileStringA` and `GetPrivateProfileIntA`. Their exact rules (white space, comments, quotes, duplicate keys, case) are in [ini-rules.md](ini-rules.md).

A small example, as the program writes it (some keys left out):

```ini
[General]
Version=DrumSynth v2.0
Comment=Simple kick
Tuning=0.00
Stretch=100.0
Level=0
Filter=0
HighPass=0
Resonance=0
FilterEnv=0,100 442000,100 443000,0 

[Tone]
On=1
Level=128
F1=200
F2=50
Droop=40
Phase=90
Envelope=0,100 1500,40 9000,0 
```

### How values are read

Each key is read in one of four ways. The tables below give the way for each key.

| Way | Read with | What it gives |
|---|---|---|
| **int** | `GetPrivateProfileIntA` | The whole number at the start: `1.9` gives 1, `12abc` gives 12, text gives 0. `0x10` is hexadecimal. Details: [ini-rules.md](ini-rules.md#getprivateprofileinta). |
| **float** | `GetPrivateProfileStringA` into **16 characters**, then `sscanf("%f")` (`GetPrivateProfileFloat`, line 136) | The decimal number at the start. Only the first 15 characters are read, so `100.000000000001` is cut to `100.000000000000`. Text that isn't a number gives 0. |
| **text** | `GetPrivateProfileStringA` into 256 characters | Up to 255 characters |
| **envelope** | text, then split into points (`getEnv`, line 87) | See [Envelopes](#envelopes) |

For every way, a **missing key, or an empty value, gives the default**. The engine and the program have different defaults for some keys, because the program's `openfile` has its own (columns "Engine default" and "Program default"). The engine's defaults only matter for files not written by the program, which always writes every key.

### `[General]`

| Key | Read as | Engine default | Program default | Program range | Meaning |
|---|---|---|---|---|---|
| `Version` | text | (none) | | `DrumSynth v2.0` | Must start with `DrumSynth`, case as written, and its 12th character must be `1` or `2`: `DrumSynth v1.0` and `DrumSynth v2.0` both work. Otherwise the engine refuses the file (return code 2 for no `DrumSynth`, 1 for another version). |
| `Comment` | text | empty | empty | free text | Stored in the WAV file (ICMT). Only the first 254 characters are used. |
| `Tuning` | float | 0 | `0.00` | free text | Semitones; decimals are cents. Every frequency except the noise generator's is multiplied by 1.0594631^Tuning (line 287). |
| `Stretch` | float | 100 | `100.0` | free text | Time stretch in percent: every envelope time is multiplied by Stretch/100. Limited to 20–1000 (line 280). |
| `Level` | float | 0 | 0 | −20 to 20 (int) | Master level in dB: the output is multiplied by 10^(Level/20). |
| `Filter` | int | 0 | 0 | 0, 1 | 1: the filter works on the whole sound. See [The filter keys](#the-filter-keys). |
| `HighPass` | int | 0 | 0 | 0, 1 | 1: the filter is high-pass instead of low-pass |
| `Resonance` | float | 0 | 0 | 0–99 (int) | Filter resonance. The feedback is √(0.0101 × Resonance), so 99 gives just under 1: self-oscillation. The program shows it as "Q = n". |
| `FilterEnv` | envelope | `0,0 100,0` | `0,100 442000,100 443000,0` | | The filter's cut-off over time: level 100 is fully open, 0 is the lowest cut-off. After its last point it holds the last level, so the program's default is "open". The engine's default holds 0, a closed filter, so a file with `Filter=1` and no `FilterEnv` is almost silent. |

**Master on.** The program has no key for its Master box. On loading, it ticks the box unless Tuning, Stretch and Level are all 0. With the box off it saves `Tuning=0`, `Stretch=100` and `Level=0`.

### `[Tone]`: the tone generator

| Key | Read as | Engine default | Program default | Program range | Meaning |
|---|---|---|---|---|---|
| `On` | int | 0 | 0 | 0, 1 | 1: the section sounds. Only exactly 1 counts. |
| `Level` | int | 128 | 128 | 1–181 | The amplitude is Level² × the envelope level, so 181 is about full scale (181² = 32761 of 32767). The program shows 20·log₁₀(Level²/32767) dB: 128 is −6.0 dB. |
| `F1` | float | 200 | `200` | free text | Start frequency in Hz |
| `F2` | float | 120 | `120` | free text | End frequency in Hz |
| `Droop` | float | 0 | 0 | 0–100 (int) | The sweep's shape. 0: a straight line from F1 to F2 over the tone envelope's length. Above 0: an exponential sweep that starts fast and still ends at F2 at the end of the envelope; it gets faster by 10^(1/30) per step (line 326). |
| `Phase` | float | 90 | `90` | free text | Start phase in degrees, for the tone and both overtones. 90 starts at the top of the wave, which gives a click. |
| `Envelope` | envelope | `0,0 100,0` | `0,100 100,30 200,0` | | The volume envelope. Its length is also the length of the sweep. |

**Droop and Stretch.** With Droop above 0, the speed of the sweep comes from the envelope's last time *before* Stretch is applied (line 327 runs before `LongestEnv` stretches it), so Stretch doesn't slow the sweep down. With Droop 0 the sweep is stretched with the envelope. This is the original's behaviour and is kept.

### `[Noise]`: the noise generator

| Key | Read as | Engine default | Program default | Program range | Meaning |
|---|---|---|---|---|---|
| `On` | int | 0 | 0 | 0, 1 | |
| `Level` | int | **0** | 128 | 1–181 | As for Tone. The engine's default is 0, silence. |
| `Slope` | int | 0 | 0 | −100 to 100 | The noise colour. Below 0 the spectrum tilts toward low frequencies, above 0 toward high ones. The program names the ranges: Red below −80, Pink below −20, White below 20, Azure below 80, then Blue. |
| `Envelope` | envelope | `0,0 100,0` | `0,100 100,30 200,0` | | The volume envelope |
| `FixedSeq` | (not read) | | 0 | 0, 1 | "Always same random sequence". The program saves it, but the engine never reads it: it restarts its random sequence (`srand(1)`) for every sound (line 311). |

### `[Overtones]`: the overtone generator

| Key | Read as | Engine default | Program default | Program range | Meaning |
|---|---|---|---|---|---|
| `On` | int | 0 | 0 | 0, 1 | |
| `Level` | int | 128 | 128 | 1–181 | As for Tone |
| `F1` | float | 200 | `200` | free text | Frequency of waveform A in Hz |
| `F2` | float | 120 | `120` | free text | Frequency of waveform B in Hz |
| `Wave1`, `Wave2` | int | 0 | 0 | 0–4 | Waveform of A and B: 0 sine, 1 sine², 2 triangle, 3 sawtooth, 4 square |
| `Track1`, `Track2` | int | 0 | 0 | 0, 1 | 1: the waveform's frequency follows the tone's sweep, in the ratio F1 (or F2) to the tone's F1. Only works when `[Tone] On=1`. |
| `Method` | int | **2** | 2 | 0–3 | How A and B combine: 0 A + B (mixed), 1 frequency modulation (B modulates A), 2 ring modulation, 3 cymbal tones |
| `Param` | int | 50 | 50 | 0–100 | Method 0: the mix, Param % of B. Methods 1 and 2: the modulation depth, (Param/50)³. Method 3: the resonance of the cymbal filter, ringing more toward 100. |
| `Envelope1` | envelope | `0,0 100,0` | `0,100 100,30 200,0` | | The level of A (methods 0–2), or of the cymbal tones (3) |
| `Envelope2` | envelope | `0,0 100,0` | `0,100 100,30 200,0` | | The level of B (method 0), the modulation depth (1, 2), or the cymbal filter's frequency (3) |
| `Filter` | int | 0 | 0 | 0, 1 | 1: the filter works on the overtones only. See [The filter keys](#the-filter-keys). |

**Cymbal tones** (method 3) are six pulse trains, with periods spread evenly from F1's to F2's, through a band-pass filter whose frequency follows `Envelope2` (lines 367 and 594). The waveform and tracking keys aren't used.

### `[NoiseBand]` and `[NoiseBand2]`: the noise bands

The two sections have the same keys.

| Key | Read as | Engine default | Program default | Program range | Meaning |
|---|---|---|---|---|---|
| `On` | int | 0 | 0 | 0, 1 | |
| `Level` | int | 128 | 128 | 1–181 | As for Tone |
| `F` | float | 1000 | `1000` | free text | Centre frequency in Hz |
| `dF` | int | 50 | 50 | 0–100 | Width of the band. A value that makes the engine's random step 0 hangs the original (line 380); the C17 engine reports it (`DS_NOTE_HANG`). |
| `Envelope` | envelope | `0,0 100,0` | `0,100 100,30 200,0` | | The volume envelope |

### `[Distortion]`

| Key | Read as | Engine default | Program default | Program range | Meaning |
|---|---|---|---|---|---|
| `On` | int | 0 | 0 | 0, 1 | Turns on all three below. Even with all three at 0, it sets the clipping point (see below). |
| `Clipping` | int | 0 | 0 | 0–60 | Gain in dB before clipping. The program shows it as "−N dB". |
| `Bits` | int | 0 | 0 | 0–7 | Bit resolution: 0 none, then 16 − 2 × Bits bits (1 = 14 bit … 7 = 2 bit). |
| `Rate` | int | 0 | 0 | 0–7 | Sample rate reduction: each block of samples is replaced by its average. Rates 0–7 give blocks of 1, 2, 3, 4, **8, 10, 20, 8** samples (line 397). The program's labels, "[none]", "11 kHz", "7 kHz", "5 kHz", "4 kHz", "3 kHz", "2 kHz", "1 kHz", are half the reduced rate, the highest frequency left, but from Rate 4 on they are one step off, and Rate 7 is the same as 4: an original bug, kept ([findings.md](../findings.md), section 6). A negative Rate hangs the original. |

**The clipping point.** With Distortion on, the output is clipped at the master gain × the Level² of the loudest section that is on, or at 32700 if that is lower (line 405). With it off, at 32700.

### The filter keys

The filter is set by two keys in different sections (lines 288 and 355):
- `[General] Filter=1` filters the whole sound.
- `[Overtones] Filter=1` filters the overtones only. It is read only when `[General] Filter` is 0.
- With both 0, there is no filter.

The program has two boxes, Filter and "Filter overtones only", and writes them as:
- `[General] Filter` is the Filter box, but 0 when "overtones only" is ticked.
- `[Overtones] Filter` is the "overtones only" box, but 0 when Filter isn't ticked.

On loading, `[Overtones] Filter=1` ticks both boxes.

### Envelopes

An envelope is a list of points, each `time,level`, separated by single spaces:

```
Envelope=0,100 1750,20 5250,0
```

- **Time** is in samples at 44,100 Hz (44100 is one second), before Stretch. **Level** is 0–100, a percentage of the section's level (or the filter's cut-off).
- The level goes in a straight line from point to point.
- **The first point** should be at time 0. **The last point** sets the section's length, and its level should be 0: the program keeps it so. A sound section stops at the end of the 1200-sample block in which its envelope ends. The filter envelope instead holds its last level for ever.
- **At most 31 points.** The engine has room for 32 numbers per row, and marks the end with −1 after the last point. A 32nd point puts that mark into the next row and changes other envelopes; the C17 engine reproduces this and reports it (`DS_NOTE_MEMORY_BEYOND`). The program's editor allows 31.
- **At most 255 characters.** The value is read into a 256-character buffer and the rest is cut off. The program writes whole numbers, so 31 points fit in most cases; an envelope pasted with longer numbers may not.
- **Numbers** are read with `sscanf("%f")`. The original copies each number into an 8-character buffer, so a number of more than 7 characters overflows it; it still reads correctly, because of where the buffer lies ([findings.md](../findings.md), section 6). The C17 engine reads it the same way, safely.
- The program writes each point followed by a space, so its envelope values end with a space. Windows removes it when reading.
- The point times of all envelopes are used as they are, whole or not. The program rounds them to whole numbers when saving.

### The sound's length

The sound is 2400 + 1200 × ⌊L / 1200⌋ samples long, where L is the latest end time, after Stretch, of the envelopes of the sections that are on (`LongestEnv`, line 39). The Overtones section counts both its envelopes. The filter envelope doesn't count.

### Keys the program writes

The program writes every key above, in the order of the tables, with `WritePrivateProfileString` (`savefile` in `gui/drumsyn.bas`; `SaveItems` in `app/src/preset.cpp`):
- An existing file is updated in place. Keys the program doesn't know, and comments, stay.
- Frequencies, Phase, Tuning and Stretch are written as typed.
- Everything else is written as a whole number, envelopes included.

Re-saving therefore changes some sounds, as the original did. The list is in the help ([gui-help.md](../gui-help.md#notes)).

## `.dse` envelope files

An addition of this edition: one envelope, saved with **Save envelope...** (Ctrl+Shift+S) and put into any envelope of any sound with **Load envelope...** (Ctrl+Shift+O). The envelope library (`tools/make_envelope_files.py`, [envelopes/](../envelopes/README.md)) is in the same format.

```ini
[DrumSynth Envelope]
Version=1
Envelope=0,100 4410,30 8820,0 
From=Kick Tone
```

| Key | Meaning |
|---|---|
| `[DrumSynth Envelope]` | The only section |
| `Version` | 1. Written for later versions of the format; not checked when loading. |
| `Envelope` | The points, in the `.ds` syntax ([Envelopes](#envelopes)). Saved as a sound's envelope is (whole numbers, a trailing space), and read as the program reads one from a `.ds` file (VB `Val()` of each number). |
| `From` | Where the envelope came from: when saved from the program, the sound's name and the envelope's, for example "Kick Tone". Only for information; not read. |

- The file is ANSI, CRLF, read with the same rules as `.ds` files ([ini-rules.md](ini-rules.md)).
- Unlike in a `.ds` file, the `Envelope` value has no 255-character limit. The point limit is the editor's, 31.
- Loading takes every point. The envelope editor's Paste takes only the first 19, as in the original.
- A file without an `Envelope` key in `[DrumSynth Envelope]` can't be loaded; the program says so.

Code: `SaveEnvelopeFile` and `LoadEnvelopeFile` in `app/src/preset.cpp`.

## WAV files

The engine writes (`ds2wav`, from line 421):
- A 44-byte header: RIFF, `WAVE`, a `fmt ` chunk for PCM, **mono, 16-bit, 44,100 Hz**, and the `data` chunk header.
- The samples, `2 × length` bytes.
- After the samples, a `LIST` `INFO` chunk:
  - `ISFT`, 16 bytes: `DrumSynth v2.0 ` and a zero byte;
  - `ICMT`: the comment and a zero byte, padded to an even length. An empty comment is written as one space.

The RIFF length counts all of it. The C17 engine writes the same bytes (`engine/src/ds_wav.c`), and the program writes them when saving with "Save .WAV" ticked or with Generate all WAVs.

## `DrumSyn.ini`: the program's settings

The program keeps its settings in `DrumSyn.ini` next to `DrumSynth.exe`, as the original did.

| Section | Key | Meaning |
|---|---|---|
| `[Window]` | `X`, `Y` | The window's position. Used when both are above 0. |
| `[Files]` | `Path` | The location: the folder that holds the kit folders. Default: the program's folder. |
| | `EnvelopePath` | The folder last used for envelope files. Default: `Envelopes`. New in this edition. |
| | `SaveWAVs` | The "Save .WAV" box of the Save dialog: 1 ticked, 0 not |

- `Path` and `EnvelopePath` are written relative to the program's folder when they are inside it, so the program's folder can be moved. A relative path is read as relative to the program's folder.
- The release ships `Path=Kits`.

Code: `LoadSettings` and `SaveSettings` in `app/src/main_frame.cpp`.
