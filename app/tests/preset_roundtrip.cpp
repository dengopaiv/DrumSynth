// preset_roundtrip - load every preset as the GUI does (Preset::Load, the
// original's openfile), save it again (Preset::Save, savefile), and render
// both with the engine.
//
//   preset_roundtrip LISTFILE     one .ds path per line
//
// Prints one line per preset: "same", or "differs" with the reason the
// original GUI would also change the sound when re-saving: envelope values
// that are not whole numbers (putenv writes Format(x, "0")), or values a
// control cannot hold. Exit code 1 if a preset differs for any other reason.
#include <cmath>
#include <cstdio>
#include <string>
#include <vector>
#include <windows.h>

#include "drumsynth.h"
#include "preset.h"

static bool RenderFile(const std::wstring& path, std::vector<int16_t>* out)
{
    FILE* f = _wfopen(path.c_str(), L"rb");
    if (!f) return false;
    std::string text;
    char buf[65536];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), f)) > 0) text.append(buf, n);
    fclose(f);
    ds_ini* ini = ds_ini_parse(text.data(), text.size());
    ds_source src = ds_ini_source(ini);
    ds_sound s;
    int r = ds_render(&src, nullptr, &s);
    ds_ini_free(ini);
    if (r != DS_OK) return false;
    out->assign(s.samples, s.samples + s.length);
    ds_sound_free(&s);
    return true;
}

static bool WholeEnvelopes(const Preset& p)
{
    for (int e = 1; e <= 7; e++)
        for (const EnvPoint& pt : p.env[e])
            if (pt.time != std::floor(pt.time) || pt.level != std::floor(pt.level)) return false;
    return true;
}

int main(int argc, char** argv)
{
    if (argc != 2) { fprintf(stderr, "usage: preset_roundtrip LISTFILE\n"); return 2; }
    FILE* list = fopen(argv[1], "rb");
    if (!list) return 2;
    wchar_t tmp[MAX_PATH];
    GetTempPathW(MAX_PATH, tmp);
    std::wstring out = std::wstring(tmp) + L"ds_roundtrip.ds";
    char line[4096];
    int same = 0, rounding = 0, other = 0;
    while (fgets(line, sizeof(line), list)) {
        std::string p(line);
        while (!p.empty() && (p.back() == '\n' || p.back() == '\r')) p.pop_back();
        if (p.empty()) continue;
        std::wstring in(p.begin(), p.end());
        Preset preset = Preset::NewSound();
        std::string version;
        if (!preset.Load(in, &version)) { printf("unreadable\t%s\n", p.c_str()); other++; continue; }
        DeleteFileW(out.c_str());
        preset.Save(out);
        std::vector<int16_t> a, b;
        bool ra = RenderFile(in, &a), rb = RenderFile(out, &b);
        if (ra != rb) { printf("differs (renders %d/%d)\t%s\n", ra, rb, p.c_str()); other++; continue; }
        if (a == b) { same++; printf("same\t%s\n", p.c_str()); continue; }
        // reasons the original GUI also changes the sound when re-saving
        if (!WholeEnvelopes(preset)) { rounding++; printf("differs (envelope decimals rounded)\t%s\n", p.c_str()); }
        else if (preset.masterOn == 0) {
            rounding++;
            printf("differs (Master off on loading: saved as Tuning 0, Stretch 100, Level 0)\t%s\n", p.c_str());
        } else if (preset.otFilter == 1 && preset.filter == 1 &&
                   GetPrivateProfileIntW(L"General", L"Filter", 0, in.c_str()) != 0) {
            rounding++;
            printf("differs (both filter boxes: saved as overtones-only filter)\t%s\n", p.c_str());
        } else { other++; printf("differs\t%s\n", p.c_str()); }
    }
    fprintf(stderr, "same %d, differ as the original GUI's re-saving does %d, differ otherwise %d\n", same,
            rounding, other);
    return other ? 1 : 0;
}
