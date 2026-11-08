// vbtext.cpp - see vbtext.h.
#include "vbtext.h"

#include <cmath>
#include <cstdio>
#include <cstdlib>

namespace vb {

double Val(const std::string& in)
{
    std::string s;
    for (char c : in)
        if (c != ' ' && c != '\t' && c != '\n' && c != '\r') s += c;
    size_t i = 0;
    if (s.size() >= 2 && s[0] == '&' && (s[1] == 'H' || s[1] == 'h' || s[1] == 'O' || s[1] == 'o')) {
        int base = (s[1] == 'H' || s[1] == 'h') ? 16 : 8;
        long long v = 0;
        for (i = 2; i < s.size(); i++) {
            int d;
            char c = s[i];
            if (c >= '0' && c <= '9') d = c - '0';
            else if (base == 16 && c >= 'a' && c <= 'f') d = c - 'a' + 10;
            else if (base == 16 && c >= 'A' && c <= 'F') d = c - 'A' + 10;
            else break;
            if (d >= base) break;
            v = v * base + d;
        }
        return static_cast<double>(static_cast<short>(v)); // &H values are Integer-sized
    }
    std::string num;
    if (i < s.size() && (s[i] == '+' || s[i] == '-')) num += s[i++];
    bool digits = false;
    while (i < s.size() && isdigit(static_cast<unsigned char>(s[i]))) { num += s[i++]; digits = true; }
    if (i < s.size() && s[i] == '.') {
        num += s[i++];
        while (i < s.size() && isdigit(static_cast<unsigned char>(s[i]))) { num += s[i++]; digits = true; }
    }
    if (digits && i < s.size() && (s[i] == 'e' || s[i] == 'E' || s[i] == 'd' || s[i] == 'D')) {
        std::string e = "e";
        size_t j = i + 1;
        if (j < s.size() && (s[j] == '+' || s[j] == '-')) e += s[j++];
        bool ed = false;
        while (j < s.size() && isdigit(static_cast<unsigned char>(s[j]))) { e += s[j++]; ed = true; }
        if (ed) num += e;
    }
    if (!digits) return 0.0;
    return std::strtod(num.c_str(), nullptr);
}

int CInt(double x)
{
    return static_cast<int>(std::nearbyint(x));
}

std::string Format(double x, int decimals)
{
    char buf[64];
    std::snprintf(buf, sizeof(buf), "%.*f", decimals, x);
    return buf;
}

static std::string ToDb(double a)
{
    if (a < 1) return "Mute";
    return Format(20.0 * std::log10(a / 32767.0), 1) + " dB";
}

std::string LevelDb(int level) { return ToDb(static_cast<double>(level) * level); }

std::string EnvLevelText(double level, bool percent)
{
    double y = level * 327.67;
    if (percent) return Format(0.00305 * y, 0) + " %";
    return ToDb(y);
}

std::string Time(double t)
{
    const double fs = 44100.0;
    if (t == 0) return "0 ms";
    if (t < fs / 100) return Format(1000 * t / fs, 3) + " ms";
    if (t < fs / 10) return Format(1000 * t / fs, 1) + " ms";
    return Format(1000 * t / fs, 0) + " ms";
}

std::string DroopName(int d)
{
    if (d < 2) return "Linear";
    if (d < 25) return "Slow";
    if (d < 66) return "Exp";
    return "Fast";
}

std::string SlopeName(int s)
{
    if (s < -80) return "Red";
    if (s < -20) return "Pink";
    if (s < 20) return "White";
    if (s < 80) return "Azure";
    return "Blue";
}

std::string MasterDb(int l) { return (l > 0 ? "+" : "") + std::to_string(l) + " dB"; }

std::string ClipDb(int c) { return Format(-c, 0) + " dB"; }

}  // namespace vb
