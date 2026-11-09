# DrumSynth help

DrumSynth is a drum sound synthesizer. It's ideal for re-creating classic electronic drum machine sounds, as it uses the same simple building blocks, but it can also produce acoustic drums, instrument sounds and sound effects.

This is the help of DrumSynth 2.0 by Paul Kellett (2000), from `help/drumsyn.rtf`, for the accessible edition. Everything is usable from the keyboard and with a screen reader. The sounds are exactly the original's.

## Overview

DrumSynth doesn't try to be a real-time analogue synthesizer simulation. What it does is offer a simple set of sound creation methods based on the electronics in early drum machines such as the Roland TR-808. The controls are all laid out on a single page.

DrumSynth lets you organise and audition your sounds, and store them in very small `.ds` files. To use DrumSynth sounds in other applications, save the sound as a WAV file.

To use DrumSynth:
1. Turn on whichever sections you want to use.
2. Adjust the parameters and envelopes.
3. Press **Play** (Enter or Ctrl+P) to hear the result.

## Keys

| Key | What it does |
|---|---|
| Tab, Shift+Tab | Move between controls: Play, Kits, Sounds, Load, Save, then the sections (Tone, Overtones, Noise, Noise Band 1 and 2, Distortion, Filter, Master), the envelope editor, the comment and Help |
| Enter, Ctrl+P | Play the sound being edited. Enter keeps its usual meaning on buttons and in lists. |
| F1 to F12 | Play the first twelve sounds in the sound list; Shift+F1 to F12 play the next twelve. They are synthesized from their `.ds` files, so no WAV files are needed. |
| Ctrl+O | Load the selected sound |
| Ctrl+S | Save as |
| Ctrl+K | Go to the kit list |
| Ctrl+E | Go to the envelope point list |
| Ctrl+Shift+S | Save the current envelope as an envelope file |
| Ctrl+Shift+O | Load an envelope file into the current envelope |
| In the sound list | Space or Enter plays the sound; Delete deletes the sound; double-click loads it |
| In the point list | Ctrl+N (or Insert, without a screen reader: Insert is the NVDA key) adds a point, Delete deletes one, Ctrl+C and Ctrl+V copy and paste the envelope |
| Alt+letter | Go to a control: Alt+P Play, Alt+I kits, Alt+D sounds, Alt+L Load, Alt+S Save, Alt+T Tone on, Alt+O Overtones on, Alt+N Noise on, Alt+R Filter, Alt+A Master on, Alt+V envelope choice, Alt+G view range, Alt+M point time, Alt+C comment. Alt+F, Alt+K, Alt+E and Alt+H open the File, Kit, Envelope and Help menus. |

Sliders say their value the way the original shows it beside them: "−6.0 dB", "Slow (10)", "Pink (−58)", "Q = 20". Where the original shows only a name, as for Droop and the noise colour, the number follows it, because every step sounds different. Use the arrow keys for small steps and Page Up and Page Down for large ones.

The original also played the sound when the Ctrl key was pressed on its own. This edition doesn't: screen reader users press Ctrl to stop speech.

## Controls

### Envelopes

Each section uses an envelope for its volume. There is also an envelope for the filter cut-off frequency. One envelope at a time is edited.

**Choosing the envelope:** the **Envelope** list chooses which one. Turning a section on selects its envelope. Turning on Overtones selects "Overtone A", or "Overtone B" if A was already selected.

**The point list.** An envelope is a list of points, each with a time and a level (0 to 100):
- The **Points** list reads each point, for example "Point 2 of 3: 45.4 ms, −14.0 dB". The overtone B and filter envelopes read their levels as percentages.
- Select a point, then change its **Time** (in samples: 44100 samples are one second) and its **Level**.
- The first point always stays at time 0. The last point always has level 0.
- A point can't move past its neighbours.

**Changing points:**
- **Add point** adds a point after the selected one, halfway to the next. An envelope can have at most 31 points.
- **Delete point** deletes the selected point. The first and last points can't be deleted.
- **Copy envelope** and **Paste envelope** copy the current envelope to another. As in the original, only the first 19 points are copied.
- **Reset envelope** gives the envelope its default shape.

**Envelope files** keep envelope shapes to use again in any sound. The original program didn't have them.
- **Save envelope...** (Ctrl+Shift+S) saves the current envelope as a `.dse` file. Its name starts as the sound's name and the envelope's, for example "Kick Tone".
- **Load envelope...** (Ctrl+Shift+O) puts an envelope file into the current envelope. Any envelope file fits any envelope: a Tone shape can become a Filter shape.
- **Load envelope from sound...** takes an envelope out of another sound's `.ds` file without loading the sound. Choose the sound, then which of its seven envelopes goes into the current one. The current envelope is offered first.
- All points are kept, unlike Paste. As when saving a sound, times and levels are saved as whole numbers.
- The files go in the `Envelopes` folder next to DrumSynth unless you choose another one, which is then remembered.
- **The envelope library:** the `Envelopes` folder comes with 492 envelope shapes taken from the presets, in a folder for each envelope ("1 Tone" to "7 Filter"). The most used come first, and each file name describes the shape, for example "01 100%, 20% at 39.7 ms, 0% at 119 ms". Any of them fits any envelope.
- Loading replaces the current envelope. Load the sound again if you want the old envelope back.

**The graph** shows the envelope for sighted users, with the other active envelopes in their section colours:
- Click to add a point. Drag a point to move it, or drag it off the top or bottom to delete it.
- Right-click for Copy, Paste and Reset.
- **View range** sets how much time the graph shows, from 16 ms to 10 seconds.
- The filter envelope's last segment isn't drawn: it just continues forever at the level of the last point.

### Tone

The Tone Generator produces a swept-frequency sine wave:
- **Start and end frequency** in Hz define the sweep.
- **Droop** sets its shape, from a linear sweep ("Linear") to a very fast sweep that reaches the end frequency almost immediately ("Fast"). It goes from 0 to 100: 0 and 1 are linear, and above that each step makes the sweep faster.
- **Phase at start** can be varied to produce a click.

### Overtones

The Overtone Generator produces two waveforms, A and B, that can be played separately or combined.

**Each waveform** has its own frequency and waveform: sine, sine², triangle, sawtooth or square. With **tracking**, its frequency follows the Tone Generator's. For example, if the tone sweeps from 100 Hz to 50 Hz, an overtone at 300 Hz with tracking sweeps from 300 Hz to 150 Hz. Tracking needs Tone to be on.

**The method** combines the two waveforms:
- **A + B**: the two waveforms are mixed with the **Mix** control.
- **Frequency modulation, ring modulation**: B modulates A, and Mix becomes **Depth**, the amount of modulation.
- **Cymbal tones**: a "sea" of tones based on the two frequencies. The more unrelated they are, the noisier the result. The control becomes a resonance control (**Reson.**), and the second envelope lets different frequency ranges be emphasised. The waveform and tracking controls aren't used.

### Noise

The Noise Generator produces white noise, and its spectrum can be tilted to produce other noise "colours": Red, Pink, White, Azure, Blue. These names are only a guide.

"Always same random sequence" is saved with the sound, but DrumSynth 2.0 always uses the same random sequence anyway.

### Noise Band 1 and 2

Each produces a band of noise with adjustable centre frequency and width.

### Distortion

The whole waveform can be clipped, and reduced to a lower bit resolution or sample rate. A little clipping often makes a sound louder and harder without sounding obviously distorted.

The **Rate** names give the highest frequency left. As in the original, they are right up to "5 kHz", but from there on the sound is one step lower than its name: "4 kHz" gives about 2.8 kHz, "3 kHz" about 2.2 kHz, "2 kHz" about 1.1 kHz, and "1 kHz" sounds the same as "4 kHz". The names are kept so that sounds read and save as in the original.

### Filter

A resonant low-pass filter, or high-pass with **High-pass**, can be applied to the whole sound (**Filter**) or just the overtones (**Filter overtones only**). The filter has its own envelope for the cut-off frequency, and self-oscillates at the highest resonance.

### Master

- **Tuning** tunes the sound in semitones; decimals are cents.
- **Stretch** timestretches it from 20% to 1000% of its length.
- **Master level** sets the volume.

With **Master on** off, the sound is saved untuned, unstretched and at 0 dB. The noise generator isn't affected by tuning.

## Loading and saving

DrumSynth works with **kits**: folders of sounds inside one location folder.

- **Finding sounds:** choose a kit, then a sound. Selecting a sound with the mouse, or pressing Space or Enter on it, plays it: DrumSynth synthesizes it from its `.ds` file, without writing anything into the kit. **Load** loads the sound for editing.
- **WAV-only sounds:** WAV files that have no `.ds` file are listed as "(WAV only)". They can be played but not loaded.
- **Saving:** **Save** asks for a name. With **Save .WAV** ticked, it also saves the WAV file, which other programs need. Saving over an existing name replaces that sound.

The **Kit** menu, and the context menu of the sound list (Shift+F10 or the context menu key), have:

| Item | What it does |
|---|---|
| Generate all WAVs | Makes the WAV of every sound in the kit that doesn't have one, for other programs. DrumSynth itself doesn't need them. |
| Delete all WAVs | Deletes the WAVs of all sounds that have a `.ds` file. A WAV can always be made again from its `.ds`. |
| Delete sound | Deletes the selected sound |
| New kit | Makes a new kit folder |
| Set location | Chooses the folder that holds the kit folders |

If DrumSynth can't read, write or play a sound, it says so, and the message also appears in the status bar.

## Notes

- **Sounds that freeze the original:** some sounds would hang the original DrumSynth 2.0. One is a tone envelope with a single point together with tracked triangle overtones. This edition plays them and tells you.
- **Re-saving changes some sounds**, exactly as the original did:
  - envelope values are saved as whole numbers;
  - a sound with Tuning, Stretch and Level all 0 is loaded with Master off, and then saved with Stretch 100;
  - a sound with both filter boxes on is saved with the filter on the overtones only.
- **The file formats** of `.ds` sounds, `.dse` envelopes and the WAV files, with every key and what it does, are described in [file-formats.md](https://github.com/dengopaiv/DrumSynth/blob/master/docs/reference/file-formats.md) in the source repository. `.ds` files are plain text and can be edited in Notepad.

## Copyright

DrumSynth Version 2.0, Copyright © 2000 Paul Kellett (http://www.mda-vst.com). DrumSynth is free software and is provided "as is" with no warranty of any kind.
