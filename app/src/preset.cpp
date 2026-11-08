// preset.cpp - see preset.h. Line references are to gui/drumsyn.bas
// (openfile, savefile, getEnv, putenv) and gui/DRUMSYN.FRM (Setup,
// mnuReset_Click).
#include "preset.h"

#include <cmath>
#include <cstdio>
#include <windows.h>

#include "drumsynth.h"
#include "vbtext.h"

namespace {

std::wstring Widen(const std::string& s)
{
    if (s.empty()) return std::wstring();
    int n = MultiByteToWideChar(CP_ACP, 0, s.data(), (int)s.size(), nullptr, 0);
    std::wstring w(n, L'\0');
    MultiByteToWideChar(CP_ACP, 0, s.data(), (int)s.size(), w.data(), n);
    return w;
}

// getini(): GetPrivateProfileString with a 255-character buffer; nothing
// read (missing or empty) gives the default.
struct Reader {
    ds_ini* ini;
    std::string get(const char* sec, const char* key, const char* def) const
    {
        char buf[256];
        unsigned n = ds_ini_get_string(ini, sec, key, "", buf, 255);
        return n == 0 ? std::string(def) : std::string(buf, n);
    }
    int num(const char* sec, const char* key, const char* def) const
    {
        return vb::CInt(vb::Val(get(sec, key, def)));
    }
};

// Format(x, "0"): VB rounds half away from zero.
std::string Int0(double x)
{
    double r = x < 0 ? -std::floor(-x + 0.5) : std::floor(x + 0.5);
    char buf[64];
    std::snprintf(buf, sizeof(buf), "%.0f", r);
    return buf;
}

}  // namespace

Envelope DefaultEnvelope(int e)
{
    if (e == ENV_FILTER) return {{0, 100}, {444000, 100}, {444000, 0}};
    // Setup(): envelope cee gets the shape of ce, with 2 and 6 swapped
    int ce = e == 2 ? 6 : e == 6 ? 2 : e;
    return {{0, 100}, {(1 - ce / 8.0) * 2000, 20}, {(1 - ce / 8.0) * 6000, 0}};
}

Envelope ResetEnvelope(int e)
{
    if (e == ENV_FILTER) return {{0, 100}, {442000, 100}, {442000, 0}};
    return {{0, 100}, {(1 - e / 8.0) * 6000, 30}, {(1 - e / 8.0) * 12000, 0}};
}

Envelope ParseEnvelope(const std::string& en)
{
    // getEnv() in drumsyn.bas: "," ends a time, " " a level; Val() of each
    Envelope env;
    EnvPoint cur{0, 0};
    std::string s;
    for (char c : en) {
        if (c == ',') { cur.time = vb::Val(s); s.clear(); }
        else if (c == ' ') { cur.level = vb::Val(s); s.clear(); env.push_back(cur); cur = {0, 0}; }
        else s += c;
    }
    cur.level = vb::Val(s);
    env.push_back(cur);
    // the loops of the original stop at the first negative time
    for (size_t i = 0; i < env.size(); i++)
        if (env[i].time < 0) { env.resize(i); break; }
    if (env.empty()) env.push_back({0, 0});
    return env;
}

std::string FormatEnvelope(const Envelope& env)
{
    std::string s;
    for (const EnvPoint& p : env) s += Int0(p.time) + "," + Int0(p.level) + " ";
    return s;
}

bool SaveEnvelopeFile(const std::wstring& path, const Envelope& env, const std::string& from)
{
    std::string text = "[DrumSynth Envelope]\r\nVersion=1\r\nEnvelope=" + FormatEnvelope(env) + "\r\n";
    if (!from.empty()) text += "From=" + from + "\r\n";
    FILE* f = _wfopen(path.c_str(), L"wb");
    if (!f) return false;
    bool ok = fwrite(text.data(), 1, text.size(), f) == text.size();
    return fclose(f) == 0 && ok;
}

bool LoadEnvelopeFile(const std::wstring& path, Envelope* env)
{
    FILE* f = _wfopen(path.c_str(), L"rb");
    if (!f) return false;
    std::string text;
    char buf[65536];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), f)) > 0) text.append(buf, n);
    fclose(f);
    ds_ini* ini = ds_ini_parse(text.data(), text.size());
    if (!ini) return false;
    // the Windows rules, as for .ds files, but with room for any envelope
    std::vector<char> value(text.size() + 1);
    unsigned len = ds_ini_get_string(ini, "DrumSynth Envelope", "Envelope", "", value.data(), (unsigned)value.size());
    ds_ini_free(ini);
    if (len == 0) return false;
    *env = ParseEnvelope(std::string(value.data(), len));
    return true;
}

Preset Preset::NewSound()
{
    Preset p;
    for (int e = 1; e <= 7; e++) p.env[e] = DefaultEnvelope(e);
    return p;
}

bool Preset::Load(const std::wstring& path, std::string* version)
{
    FILE* f = _wfopen(path.c_str(), L"rb");
    if (!f) return false;
    std::string text;
    char buf[65536];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), f)) > 0) text.append(buf, n);
    fclose(f);
    ds_ini* ini = ds_ini_parse(text.data(), text.size());
    if (!ini) return false;
    Reader r{ini};

    const char* sc = "General";
    if (version) *version = r.get(sc, "Version", "");
    comment = r.get(sc, "Comment", "");
    tuning = r.get(sc, "Tuning", "0.00");
    stretch = r.get(sc, "Stretch", "100.0");
    masterDb = r.num(sc, "Level", "0");
    // the original's test: Master off only if all three are 0
    masterOn = (vb::Val(tuning) == 0 && vb::Val(stretch) == 0 && masterDb == 0) ? 0 : 1;
    filter = r.num(sc, "Filter", "0");
    highPass = r.num(sc, "HighPass", "0");
    resonance = r.num(sc, "Resonance", "0");
    env[ENV_FILTER] = ParseEnvelope(r.get(sc, "FilterEnv", "0,100 442000,100 443000,0"));

    sc = "Tone";
    toneOn = r.num(sc, "On", "0");
    toneLevel = r.num(sc, "Level", "128");
    toneF1 = r.get(sc, "F1", "200");
    toneF2 = r.get(sc, "F2", "120");
    droop = r.num(sc, "Droop", "0");
    phase = r.get(sc, "Phase", "90");
    env[ENV_TONE] = ParseEnvelope(r.get(sc, "Envelope", "0,100 100,30 200,0"));

    sc = "Noise";
    noiseOn = r.num(sc, "On", "0");
    noiseLevel = r.num(sc, "Level", "128");
    slope = r.num(sc, "Slope", "0");
    fixedSeq = r.num(sc, "FixedSeq", "0");
    env[ENV_NOISE] = ParseEnvelope(r.get(sc, "Envelope", "0,100 100,30 200,0"));

    sc = "Overtones";
    otOn = r.num(sc, "On", "0");
    otLevel = r.num(sc, "Level", "128");
    otF1 = r.get(sc, "F1", "200");
    wave1 = r.num(sc, "Wave1", "0");
    track1 = r.num(sc, "Track1", "0");
    otF2 = r.get(sc, "F2", "120");
    wave2 = r.num(sc, "Wave2", "0");
    track2 = r.num(sc, "Track2", "0");
    otFilter = r.num(sc, "Filter", "0");
    if (otFilter == 1) filter = 1;
    method = r.num(sc, "Method", "2");
    param = r.num(sc, "Param", "50");
    env[ENV_OT1] = ParseEnvelope(r.get(sc, "Envelope1", "0,100 100,30 200,0"));
    env[ENV_OT2] = ParseEnvelope(r.get(sc, "Envelope2", "0,100 100,30 200,0"));

    sc = "NoiseBand";
    band1On = r.num(sc, "On", "0");
    band1Level = r.num(sc, "Level", "128");
    band1F = r.get(sc, "F", "1000");
    band1Width = r.num(sc, "dF", "50");
    env[ENV_BAND1] = ParseEnvelope(r.get(sc, "Envelope", "0,100 100,30 200,0"));

    sc = "NoiseBand2";
    band2On = r.num(sc, "On", "0");
    band2Level = r.num(sc, "Level", "128");
    band2F = r.get(sc, "F", "1000");
    band2Width = r.num(sc, "dF", "50");
    env[ENV_BAND2] = ParseEnvelope(r.get(sc, "Envelope", "0,100 100,30 200,0"));

    sc = "Distortion";
    distOn = r.num(sc, "On", "0");
    clipping = r.num(sc, "Clipping", "0");
    bits = r.num(sc, "Bits", "0");
    rate = r.num(sc, "Rate", "0");
    ds_ini_free(ini);
    return true;
}

namespace {

// The key/value pairs savefile() writes, in its order.
struct Item { const char* sec; const char* key; std::string value; };

std::vector<Item> SaveItems(const Preset& p)
{
    auto I = [](int v) { return std::to_string(v); };
    std::vector<Item> v;
    const char* sc = "General";
    v.push_back({sc, "Version", "DrumSynth v2.0"});
    v.push_back({sc, "Comment", p.comment});
    if (p.masterOn == 1) {
        v.push_back({sc, "Tuning", p.tuning});
        v.push_back({sc, "Stretch", p.stretch});
        v.push_back({sc, "Level", I(p.masterDb)});
    } else {
        v.push_back({sc, "Tuning", "0"});
        v.push_back({sc, "Stretch", "100"});
        v.push_back({sc, "Level", "0"});
    }
    v.push_back({sc, "Filter", p.otFilter == 0 ? I(p.filter) : "0"});
    v.push_back({sc, "HighPass", I(p.highPass)});
    v.push_back({sc, "Resonance", I(p.resonance)});
    v.push_back({sc, "FilterEnv", FormatEnvelope(p.env[ENV_FILTER])});
    sc = "Tone";
    v.push_back({sc, "On", I(p.toneOn)});
    v.push_back({sc, "Level", I(p.toneLevel)});
    v.push_back({sc, "F1", p.toneF1});
    v.push_back({sc, "F2", p.toneF2});
    v.push_back({sc, "Droop", I(p.droop)});
    v.push_back({sc, "Phase", p.phase});
    v.push_back({sc, "Envelope", FormatEnvelope(p.env[ENV_TONE])});
    sc = "Noise";
    v.push_back({sc, "On", I(p.noiseOn)});
    v.push_back({sc, "Level", I(p.noiseLevel)});
    v.push_back({sc, "Slope", I(p.slope)});
    v.push_back({sc, "Envelope", FormatEnvelope(p.env[ENV_NOISE])});
    v.push_back({sc, "FixedSeq", I(p.fixedSeq)});
    sc = "Overtones";
    v.push_back({sc, "On", I(p.otOn)});
    v.push_back({sc, "Level", I(p.otLevel)});
    v.push_back({sc, "F1", p.otF1});
    v.push_back({sc, "Wave1", I(p.wave1)});
    v.push_back({sc, "Track1", I(p.track1)});
    v.push_back({sc, "F2", p.otF2});
    v.push_back({sc, "Wave2", I(p.wave2)});
    v.push_back({sc, "Track2", I(p.track2)});
    v.push_back({sc, "Method", I(p.method)});
    v.push_back({sc, "Param", I(p.param)});
    v.push_back({sc, "Envelope1", FormatEnvelope(p.env[ENV_OT1])});
    v.push_back({sc, "Envelope2", FormatEnvelope(p.env[ENV_OT2])});
    v.push_back({sc, "Filter", p.filter == 1 ? I(p.otFilter) : "0"});
    sc = "NoiseBand";
    v.push_back({sc, "On", I(p.band1On)});
    v.push_back({sc, "Level", I(p.band1Level)});
    v.push_back({sc, "F", p.band1F});
    v.push_back({sc, "dF", I(p.band1Width)});
    v.push_back({sc, "Envelope", FormatEnvelope(p.env[ENV_BAND1])});
    sc = "NoiseBand2";
    v.push_back({sc, "On", I(p.band2On)});
    v.push_back({sc, "Level", I(p.band2Level)});
    v.push_back({sc, "F", p.band2F});
    v.push_back({sc, "dF", I(p.band2Width)});
    v.push_back({sc, "Envelope", FormatEnvelope(p.env[ENV_BAND2])});
    sc = "Distortion";
    v.push_back({sc, "On", I(p.distOn)});
    v.push_back({sc, "Clipping", I(p.clipping)});
    v.push_back({sc, "Bits", I(p.bits)});
    v.push_back({sc, "Rate", I(p.rate)});
    return v;
}

}  // namespace

bool Preset::Save(const std::wstring& path) const
{
    for (const Item& it : SaveItems(*this)) {
        if (!WritePrivateProfileStringW(Widen(it.sec).c_str(), Widen(it.key).c_str(),
                                        Widen(it.value).c_str(), path.c_str()))
            return false;
    }
    WritePrivateProfileStringW(nullptr, nullptr, nullptr, path.c_str()); // flush the cache
    return true;
}

std::string Preset::ToText() const
{
    std::string out, sec;
    for (const Item& it : SaveItems(*this)) {
        if (sec != it.sec) {
            if (!sec.empty()) out += "\r\n";
            sec = it.sec;
            out += "[" + sec + "]\r\n";
        }
        out += std::string(it.key) + "=" + it.value + "\r\n";
    }
    return out;
}
