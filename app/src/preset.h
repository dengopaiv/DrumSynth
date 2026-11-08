// preset.h - a DrumSynth sound as the original GUI holds it, with its
// loading (openfile in gui/drumsyn.bas) and saving (savefile).
//
// Values are kept as the GUI controls held them: numbers as integers, the
// text fields (frequencies, phase, tuning, stretch) as typed. Values outside
// a control's range are kept unchanged (docs/gui-checklist.md, section 6).
#pragma once

#include <string>
#include <vector>

struct EnvPoint {
    double time;   // samples
    double level;  // 0-100
};

using Envelope = std::vector<EnvPoint>;

enum EnvId { ENV_TONE = 1, ENV_NOISE, ENV_OT1, ENV_OT2, ENV_BAND1, ENV_BAND2, ENV_FILTER };

struct Preset {
    // [General]
    std::string comment;
    std::string tuning = "0.00";
    std::string stretch = "100.0";
    int masterDb = 0;
    int masterOn = 0;
    int filter = 0;       // the "Filter" box (MasterFilter)
    int highPass = 0;
    int resonance = 0;
    // [Tone]
    int toneOn = 1, toneLevel = 128, droop = 0;
    std::string toneF1 = "200", toneF2 = "120", phase = "0";
    // [Noise]
    int noiseOn = 1, noiseLevel = 128, slope = 0, fixedSeq = 1;
    // [Overtones]
    int otOn = 0, otLevel = 128, wave1 = 0, track1 = 0, wave2 = 0, track2 = 0, method = 0, param = 0;
    int otFilter = 0;     // "Filter overtones only" (chkOFilter)
    std::string otF1 = "315", otF2 = "630";
    // [NoiseBand], [NoiseBand2]
    int band1On = 0, band1Level = 128, band1Width = 40;
    std::string band1F = "1200";
    int band2On = 0, band2Level = 128, band2Width = 40;
    std::string band2F = "3100";
    // [Distortion]
    int distOn = 0, clipping = 0, bits = 0, rate = 0;

    Envelope env[8];      // 1..7 (EnvId)

    // A new sound, as the original program starts (Setup and the form's
    // control values). The comment is set by the caller.
    static Preset NewSound();

    // openfile(): read a .ds file (path in UTF-16). Missing or empty values
    // get openfile's defaults. Returns false if the file can't be read.
    bool Load(const std::wstring& path, std::string* version);
    // savefile(): write with WritePrivateProfileString, key by key, in
    // savefile's order; an existing file is updated in place.
    bool Save(const std::wstring& path) const;
    // The .ds text savefile would write to a new file (for tests).
    std::string ToText() const;
};

// The envelope helpers of the original editor.
Envelope DefaultEnvelope(int e);   // Setup()
Envelope ResetEnvelope(int e);     // mnuReset_Click
Envelope ParseEnvelope(const std::string& s);     // getEnv() in drumsyn.bas (VB Val)
std::string FormatEnvelope(const Envelope& env);  // putenv()
