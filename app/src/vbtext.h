// vbtext.h - the text conversions of the original Visual Basic GUI
// (gui/DRUMSYN.FRM, gui/drumsyn.bas), so values read, shown and written
// exactly as the original did them.
#pragma once

#include <string>

namespace vb {

// Val(): white space anywhere is ignored; an optional sign, digits, '.',
// an E or D exponent, or &H / &O prefixes; stops at the first other character.
double Val(const std::string& s);
// CInt(): round half to even (assigning a Double to an Integer control).
int CInt(double x);
// Format(x, "0"), Format(x, "0.0"), Format(x, "0.000"): fixed decimals.
std::string Format(double x, int decimals);

// The GUI's display texts.
std::string LevelDb(int sliderLevel);          // todB(level^2): "-6.0 dB" or "Mute"
std::string EnvLevelText(double level, bool percent); // todB(level*327.67) or "N %"
std::string Time(double samples);              // toTime(): "0 ms", "1.234 ms", ...
std::string DroopName(int droop);              // Linear, Slow, Exp, Fast
std::string SlopeName(int slope);              // Red, Pink, White, Azure, Blue
std::string MasterDb(int level);               // "+3 dB", "0 dB", "-3 dB"
std::string ClipDb(int clip);                  // "-12 dB"

}  // namespace vb
