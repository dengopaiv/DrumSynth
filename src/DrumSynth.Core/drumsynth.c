// DrumSynth Core - Modern portable synthesis engine
// Original (c) 1998-2000 Paul Kellett (mda-vst.com)
// Modernized for cross-platform use
// MIT/GPL-2.0 dual license

#include "drumsynth.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define FS      44100
#define TWOPI   6.2831853f
#define MAX     0
#define ENV     1
#define PNT     2
#define DENV    3
#define NEXTT   4

// Global state (kept for compatibility with original algorithm)
static float envpts[8][3][32];
static float envData[8][6];
static int   chkOn[8], sliLev[8];
static float timestretch;
static short DD[1200];
static float DF[1200];
static float phi[1200];
static short clippoint;

static float mem_t = 1.0f, mem_o = 1.0f, mem_n = 1.0f, mem_b = 1.0f;
static float mem_tune = 0.0f, mem_time = 1.0f;

// Simple INI file parser
static char* trim(char* str) {
    while (isspace((unsigned char)*str)) str++;
    if (*str == 0) return str;
    char* end = str + strlen(str) - 1;
    while (end > str && isspace((unsigned char)*end)) end--;
    end[1] = '\0';
    return str;
}

static int get_ini_string(const char* filename, const char* section, const char* key,
                          char* buffer, int bufsize, const char* def) {
    FILE* fp = fopen(filename, "r");
    if (!fp) {
        strncpy(buffer, def, bufsize - 1);
        buffer[bufsize - 1] = 0;
        return (int)strlen(buffer);
    }

    char line[512];
    char current_section[64] = "";
    int found = 0;

    while (fgets(line, sizeof(line), fp)) {
        char* trimmed = trim(line);

        // Section header
        if (trimmed[0] == '[') {
            char* end = strchr(trimmed, ']');
            if (end) {
                *end = 0;
                strncpy(current_section, trimmed + 1, sizeof(current_section) - 1);
            }
            continue;
        }

        // Key=Value
        if (_stricmp(current_section, section) == 0) {
            char* eq = strchr(trimmed, '=');
            if (eq) {
                *eq = 0;
                char* k = trim(trimmed);
                char* v = trim(eq + 1);
                if (_stricmp(k, key) == 0) {
                    strncpy(buffer, v, bufsize - 1);
                    buffer[bufsize - 1] = 0;
                    found = 1;
                    break;
                }
            }
        }
    }

    fclose(fp);

    if (!found) {
        strncpy(buffer, def, bufsize - 1);
        buffer[bufsize - 1] = 0;
    }

    return (int)strlen(buffer);
}

static int get_ini_int(const char* filename, const char* section, const char* key, int def) {
    char buf[32];
    get_ini_string(filename, section, key, buf, sizeof(buf), "");
    if (buf[0] == 0) return def;
    return atoi(buf);
}

static float get_ini_float(const char* filename, const char* section, const char* key, float def) {
    char buf[32];
    get_ini_string(filename, section, key, buf, sizeof(buf), "");
    if (buf[0] == 0) return def;
    return (float)atof(buf);
}

static void write_ini_string(FILE* fp, const char* key, const char* value) {
    fprintf(fp, "%s=%s\n", key, value);
}

static void write_ini_int(FILE* fp, const char* key, int value) {
    fprintf(fp, "%s=%d\n", key, value);
}

static void write_ini_float(FILE* fp, const char* key, float value) {
    fprintf(fp, "%s=%.2f\n", key, value);
}

// Envelope parsing
static void getEnv(int env, const char* envStr) {
    char en[512];
    char s[16];
    int i = 0, o = 0, ep = 0;

    strncpy(en, envStr, sizeof(en) - 1);
    en[sizeof(en) - 1] = 0;

    while (en[i] != 0) {
        if (en[i] == ',') {
            s[o] = 0;
            envpts[env][0][ep] = (float)atof(s);
            o = 0;
        } else if (en[i] == ' ') {
            s[o] = 0;
            envpts[env][1][ep] = (float)atof(s);
            o = 0;
            ep++;
        } else {
            if (o < 15) {
                s[o++] = en[i];
            }
        }
        i++;
    }
    s[o] = 0;
    envpts[env][1][ep] = (float)atof(s);
    envpts[env][0][ep + 1] = -1;
    envData[env][MAX] = envpts[env][0][ep];
}

static void getEnvFromFile(int env, const char* section, const char* key, const char* filename) {
    char buf[512];
    get_ini_string(filename, section, key, buf, sizeof(buf), "0,0 100,0");
    getEnv(env, buf);
}

static int LongestEnv(void) {
    int e, eon, p;
    float l = 0.f;

    for (e = 1; e < 7; e++) {
        eon = e - 1;
        if (eon > 2) eon = eon - 1;
        p = 0;
        while (envpts[e][0][p + 1] >= 0.f) p++;
        envData[e][MAX] = envpts[e][0][p] * timestretch;
        if (chkOn[eon] == 1)
            if (envData[e][MAX] > l) l = envData[e][MAX];
    }
    return 2400 + (1200 * (int)(l / 1200));
}

static float LoudestEnv(void) {
    float loudest = 0.f;
    int i = 0;
    while (i < 5) {
        if (chkOn[i] == 1)
            if (sliLev[i] > loudest) loudest = (float)sliLev[i];
        i++;
    }
    return (loudest * loudest);
}

static void UpdateEnv(int e, long t) {
    float endEnv, dT;
    envData[e][NEXTT] = envpts[e][0][(long)(envData[e][PNT] + 1.f)] * timestretch;
    if (envData[e][NEXTT] < 0) envData[e][NEXTT] = 442000 * timestretch;
    envData[e][ENV] = envpts[e][1][(long)(envData[e][PNT] + 0.f)] * 0.01f;
    endEnv = envpts[e][1][(long)(envData[e][PNT] + 1.f)] * 0.01f;
    dT = envData[e][NEXTT] - (float)t;
    if (dT < 1.0) dT = 1.0;
    envData[e][DENV] = (endEnv - envData[e][ENV]) / dT;
    envData[e][PNT] = envData[e][PNT] + 1.0f;
}

static float waveform(float ph, int form) {
    float w;
    switch (form) {
        case 0: w = (float)sin(fmod(ph, TWOPI)); break;
        case 1: w = (float)fabs(2.0f * (float)sin(fmod(0.5f * ph, TWOPI))) - 1.f; break;
        case 2:
            while (ph < TWOPI) ph += TWOPI;
            w = 0.6366197f * (float)fmod(ph, TWOPI) - 1.f;
            if (w > 1.f) w = 2.f - w;
            break;
        case 3:
            w = ph - TWOPI * (float)(int)(ph / TWOPI);
            w = (0.3183098f * w) - 1.f;
            break;
        default:
            w = (sin(fmod(ph, TWOPI)) > 0.0) ? 1.f : -1.f;
            break;
    }
    return w;
}

DS_API const char* DS_CALL ds_version(void) {
    return "DrumSynth 3.0 (Modern)";
}

DS_API void DS_CALL ds_init_params(DrumSynthParams* params) {
    memset(params, 0, sizeof(DrumSynthParams));

    params->stretch = 100.0f;
    params->level = 0.0f;
    params->tuning = 0.0f;

    params->tone_level = 128;
    params->tone_f1 = 200.0f;
    params->tone_f2 = 120.0f;
    params->tone_phase = 90.0f;
    strcpy(params->tone_envelope, "0,100 100,30 200,0");

    params->noise_level = 128;
    params->noise_fixed_seq = 1;
    strcpy(params->noise_envelope, "0,100 100,30 200,0");

    params->over_level = 128;
    params->over_f1 = 200.0f;
    params->over_f2 = 120.0f;
    params->over_method = 2;
    params->over_param = 50;
    strcpy(params->over_envelope1, "0,100 100,30 200,0");
    strcpy(params->over_envelope2, "0,100 100,30 200,0");

    params->band1_level = 128;
    params->band1_f = 1000.0f;
    params->band1_df = 50;
    strcpy(params->band1_envelope, "0,100 100,30 200,0");

    params->band2_level = 128;
    params->band2_f = 3100.0f;
    params->band2_df = 40;
    strcpy(params->band2_envelope, "0,100 100,30 200,0");

    strcpy(params->filter_envelope, "0,100 442000,100 443000,0");
}

DS_API int DS_CALL ds_load_file(const char* filename, DrumSynthParams* params) {
    char buf[512];

    // Check version
    get_ini_string(filename, "General", "Version", buf, sizeof(buf), "");
    if (strstr(buf, "DrumSynth") == NULL) return DS_ERR_VERSION;

    ds_init_params(params);

    // General
    get_ini_string(filename, "General", "Comment", params->comment, sizeof(params->comment), "");
    params->tuning = get_ini_float(filename, "General", "Tuning", 0.0f);
    params->stretch = get_ini_float(filename, "General", "Stretch", 100.0f);
    params->level = get_ini_float(filename, "General", "Level", 0.0f);
    params->filter_on = get_ini_int(filename, "General", "Filter", 0);
    params->filter_highpass = get_ini_int(filename, "General", "HighPass", 0);
    params->filter_resonance = get_ini_int(filename, "General", "Resonance", 0);
    get_ini_string(filename, "General", "FilterEnv", params->filter_envelope,
                   sizeof(params->filter_envelope), "0,100 442000,100 443000,0");

    // Tone
    params->tone_on = get_ini_int(filename, "Tone", "On", 0);
    params->tone_level = get_ini_int(filename, "Tone", "Level", 128);
    params->tone_f1 = get_ini_float(filename, "Tone", "F1", 200.0f);
    params->tone_f2 = get_ini_float(filename, "Tone", "F2", 120.0f);
    params->tone_droop = get_ini_float(filename, "Tone", "Droop", 0.0f);
    params->tone_phase = get_ini_float(filename, "Tone", "Phase", 90.0f);
    get_ini_string(filename, "Tone", "Envelope", params->tone_envelope,
                   sizeof(params->tone_envelope), "0,100 100,30 200,0");

    // Noise
    params->noise_on = get_ini_int(filename, "Noise", "On", 0);
    params->noise_level = get_ini_int(filename, "Noise", "Level", 128);
    params->noise_slope = get_ini_int(filename, "Noise", "Slope", 0);
    params->noise_fixed_seq = get_ini_int(filename, "Noise", "FixedSeq", 1);
    get_ini_string(filename, "Noise", "Envelope", params->noise_envelope,
                   sizeof(params->noise_envelope), "0,100 100,30 200,0");

    // Overtones
    params->over_on = get_ini_int(filename, "Overtones", "On", 0);
    params->over_level = get_ini_int(filename, "Overtones", "Level", 128);
    params->over_f1 = get_ini_float(filename, "Overtones", "F1", 200.0f);
    params->over_f2 = get_ini_float(filename, "Overtones", "F2", 120.0f);
    params->over_wave1 = get_ini_int(filename, "Overtones", "Wave1", 0);
    params->over_wave2 = get_ini_int(filename, "Overtones", "Wave2", 0);
    params->over_track1 = get_ini_int(filename, "Overtones", "Track1", 0);
    params->over_track2 = get_ini_int(filename, "Overtones", "Track2", 0);
    params->over_method = get_ini_int(filename, "Overtones", "Method", 2);
    params->over_param = get_ini_int(filename, "Overtones", "Param", 50);
    params->over_filter = get_ini_int(filename, "Overtones", "Filter", 0);
    get_ini_string(filename, "Overtones", "Envelope1", params->over_envelope1,
                   sizeof(params->over_envelope1), "0,100 100,30 200,0");
    get_ini_string(filename, "Overtones", "Envelope2", params->over_envelope2,
                   sizeof(params->over_envelope2), "0,100 100,30 200,0");

    // NoiseBand
    params->band1_on = get_ini_int(filename, "NoiseBand", "On", 0);
    params->band1_level = get_ini_int(filename, "NoiseBand", "Level", 128);
    params->band1_f = get_ini_float(filename, "NoiseBand", "F", 1000.0f);
    params->band1_df = get_ini_int(filename, "NoiseBand", "dF", 50);
    get_ini_string(filename, "NoiseBand", "Envelope", params->band1_envelope,
                   sizeof(params->band1_envelope), "0,100 100,30 200,0");

    // NoiseBand2
    params->band2_on = get_ini_int(filename, "NoiseBand2", "On", 0);
    params->band2_level = get_ini_int(filename, "NoiseBand2", "Level", 128);
    params->band2_f = get_ini_float(filename, "NoiseBand2", "F", 3100.0f);
    params->band2_df = get_ini_int(filename, "NoiseBand2", "dF", 40);
    get_ini_string(filename, "NoiseBand2", "Envelope", params->band2_envelope,
                   sizeof(params->band2_envelope), "0,100 100,30 200,0");

    // Distortion
    params->dist_on = get_ini_int(filename, "Distortion", "On", 0);
    params->dist_clipping = get_ini_int(filename, "Distortion", "Clipping", 0);
    params->dist_bits = get_ini_int(filename, "Distortion", "Bits", 0);
    params->dist_rate = get_ini_int(filename, "Distortion", "Rate", 0);

    return DS_OK;
}

DS_API int DS_CALL ds_save_file(const char* filename, const DrumSynthParams* params) {
    FILE* fp = fopen(filename, "w");
    if (!fp) return DS_ERR_OUTPUT;

    fprintf(fp, "[General]\n");
    write_ini_string(fp, "Version", "DrumSynth v2.0");
    write_ini_string(fp, "Comment", params->comment);
    write_ini_float(fp, "Tuning", params->tuning);
    write_ini_float(fp, "Stretch", params->stretch);
    write_ini_float(fp, "Level", params->level);
    write_ini_int(fp, "Filter", params->filter_on);
    write_ini_int(fp, "HighPass", params->filter_highpass);
    write_ini_int(fp, "Resonance", params->filter_resonance);
    write_ini_string(fp, "FilterEnv", params->filter_envelope);

    fprintf(fp, "\n[Tone]\n");
    write_ini_int(fp, "On", params->tone_on);
    write_ini_int(fp, "Level", params->tone_level);
    write_ini_float(fp, "F1", params->tone_f1);
    write_ini_float(fp, "F2", params->tone_f2);
    write_ini_float(fp, "Droop", params->tone_droop);
    write_ini_float(fp, "Phase", params->tone_phase);
    write_ini_string(fp, "Envelope", params->tone_envelope);

    fprintf(fp, "\n[Noise]\n");
    write_ini_int(fp, "On", params->noise_on);
    write_ini_int(fp, "Level", params->noise_level);
    write_ini_int(fp, "Slope", params->noise_slope);
    write_ini_int(fp, "FixedSeq", params->noise_fixed_seq);
    write_ini_string(fp, "Envelope", params->noise_envelope);

    fprintf(fp, "\n[Overtones]\n");
    write_ini_int(fp, "On", params->over_on);
    write_ini_int(fp, "Level", params->over_level);
    write_ini_float(fp, "F1", params->over_f1);
    write_ini_float(fp, "F2", params->over_f2);
    write_ini_int(fp, "Wave1", params->over_wave1);
    write_ini_int(fp, "Wave2", params->over_wave2);
    write_ini_int(fp, "Track1", params->over_track1);
    write_ini_int(fp, "Track2", params->over_track2);
    write_ini_int(fp, "Method", params->over_method);
    write_ini_int(fp, "Param", params->over_param);
    write_ini_int(fp, "Filter", params->over_filter);
    write_ini_string(fp, "Envelope1", params->over_envelope1);
    write_ini_string(fp, "Envelope2", params->over_envelope2);

    fprintf(fp, "\n[NoiseBand]\n");
    write_ini_int(fp, "On", params->band1_on);
    write_ini_int(fp, "Level", params->band1_level);
    write_ini_float(fp, "F", params->band1_f);
    write_ini_int(fp, "dF", params->band1_df);
    write_ini_string(fp, "Envelope", params->band1_envelope);

    fprintf(fp, "\n[NoiseBand2]\n");
    write_ini_int(fp, "On", params->band2_on);
    write_ini_int(fp, "Level", params->band2_level);
    write_ini_float(fp, "F", params->band2_f);
    write_ini_int(fp, "dF", params->band2_df);
    write_ini_string(fp, "Envelope", params->band2_envelope);

    fprintf(fp, "\n[Distortion]\n");
    write_ini_int(fp, "On", params->dist_on);
    write_ini_int(fp, "Clipping", params->dist_clipping);
    write_ini_int(fp, "Bits", params->dist_bits);
    write_ini_int(fp, "Rate", params->dist_rate);

    fclose(fp);
    return DS_OK;
}

DS_API int DS_CALL ds_estimate_length(const DrumSynthParams* params) {
    // Setup for length estimation
    timestretch = 0.01f * params->stretch;
    if (timestretch < 0.2f) timestretch = 0.2f;
    if (timestretch > 10.f) timestretch = 10.f;

    chkOn[0] = params->tone_on;
    chkOn[1] = params->noise_on;
    chkOn[2] = params->over_on;
    chkOn[3] = params->band1_on;
    chkOn[4] = params->band2_on;
    chkOn[5] = params->dist_on;

    getEnv(1, params->tone_envelope);
    getEnv(2, params->noise_envelope);
    getEnv(3, params->over_envelope1);
    getEnv(4, params->over_envelope2);
    getEnv(5, params->band1_envelope);
    getEnv(6, params->band2_envelope);

    return LongestEnv();
}

// Main synthesis function - ported from original
DS_API int DS_CALL ds_synthesize(const DrumSynthParams* params, int16_t* buffer, int max_samples) {
    long Length, tpos = 0, tplus, totmp, t, i, j;
    float x[3] = {0.f, 0.f, 0.f};
    float MasterTune, randmax, randmax2;
    int MainFilter, HighPass;

    long NON, NT, TON, DiON, TDroop = 0, DStep;
    float a, b = 0.f, c = 0.f, d = 0.f, g, TT = 0.f, TTT = 0.f, TL, NL, F1, F2, Fsync;
    float TphiStart = 0.f, Tphi, TDroopRate, ddF, DAtten, DGain;

    long BON, BON2, BFStep, BFStep2, botmp;
    float BdF = 0.f, BdF2 = 0.f, BPhi, BPhi2, BF, BF2, BQ, BQ2, BL, BL2;

    long OON, OF1Sync = 0, OF2Sync = 0, OMode, OW1, OW2;
    float Ophi1, Ophi2, OF1, OF2, OL, Ot, OBal1, OBal2, ODrive;
    float Ocf1, Ocf2, OcF, OcQ, OcA, Oc[6][2];
    float Oc0 = 0.0f, Oc1 = 0.0f, Oc2 = 0.0f;

    float MFfb, MFtmp, MFres, MFin = 0.f, MFout = 0.f;
    float DownAve;
    long DownStart, DownEnd, jj;

    int wavewords = 0;

    // Setup parameters
    mem_t = 1.0f;
    mem_o = 1.0f;
    mem_n = 1.0f;
    mem_b = 1.0f;
    mem_tune = 0.0f;
    mem_time = 1.0f;

    timestretch = 0.01f * mem_time * params->stretch;
    if (timestretch < 0.2f) timestretch = 0.2f;
    if (timestretch > 10.f) timestretch = 10.f;

    DGain = 1.0f;
    DGain = (float)pow(10.0, 0.05 * params->level);

    MasterTune = (float)pow(1.0594631f, params->tuning + mem_tune);
    MainFilter = 2 * params->filter_on;
    MFres = 0.0101f * params->filter_resonance;
    MFres = (float)pow(MFres, 0.5f);
    HighPass = params->filter_highpass;
    getEnv(7, params->filter_envelope);

    // Noise
    chkOn[1] = params->noise_on;
    sliLev[1] = params->noise_level;
    NT = params->noise_slope;
    getEnv(2, params->noise_envelope);
    NON = chkOn[1];
    NL = (float)(sliLev[1] * sliLev[1]) * mem_n;
    if (NT < 0) {
        a = 1.f + (NT / 105.f);
        d = -NT / 105.f;
        g = (1.f + 0.0005f * NT * NT) * NL;
    } else {
        a = 1.f;
        b = -NT / 50.f;
        c = (float)fabs((float)NT) / 100.f;
        g = NL;
    }
    srand(1);  // Fixed random sequence

    // Tone
    chkOn[0] = params->tone_on;
    TON = chkOn[0];
    sliLev[0] = params->tone_level;
    TL = (float)(sliLev[0] * sliLev[0]) * mem_t;
    getEnv(1, params->tone_envelope);
    F1 = MasterTune * TWOPI * params->tone_f1 / FS;
    if (fabs(F1) < 0.001f) F1 = 0.001f;
    F2 = MasterTune * TWOPI * params->tone_f2 / FS;
    Fsync = F2;
    TDroopRate = params->tone_droop;
    if (TDroopRate > 0.f) {
        TDroopRate = (float)pow(10.0f, (TDroopRate - 20.0f) / 30.0f);
        TDroopRate = TDroopRate * -4.f / envData[1][MAX];
        TDroop = 1;
        F2 = F1 + ((F2 - F1) / (1.f - (float)exp(TDroopRate * envData[1][MAX])));
        ddF = F1 - F2;
    } else {
        ddF = F2 - F1;
    }
    Tphi = params->tone_phase / 57.29578f;

    // Overtones
    chkOn[2] = params->over_on;
    OON = chkOn[2];
    sliLev[2] = params->over_level;
    OL = (float)(sliLev[2] * sliLev[2]) * mem_o;
    getEnv(3, params->over_envelope1);
    getEnv(4, params->over_envelope2);
    OMode = params->over_method;
    OF1 = MasterTune * TWOPI * params->over_f1 / FS;
    OF2 = MasterTune * TWOPI * params->over_f2 / FS;
    OW1 = params->over_wave1;
    OW2 = params->over_wave2;
    OBal2 = (float)params->over_param;
    ODrive = (float)pow(OBal2, 3.0f) / (float)pow(50.0f, 3.0f);
    OBal2 *= 0.01f;
    OBal1 = 1.f - OBal2;
    Ophi1 = Tphi;
    Ophi2 = Tphi;
    if (MainFilter == 0)
        MainFilter = params->over_filter;
    if ((params->over_track1 == 1) && (TON == 1)) {
        OF1Sync = 1;
        OF1 = OF1 / F1;
    }
    if ((params->over_track2 == 1) && (TON == 1)) {
        OF2Sync = 1;
        OF2 = OF2 / F1;
    }

    OcA = 0.28f + OBal1 * OBal1;
    OcQ = OcA * OcA;
    OcF = (1.8f - 0.7f * OcQ) * 0.92f;
    OcA *= 1.0f + 4.0f * OBal1;
    Ocf1 = TWOPI / OF1;
    Ocf2 = TWOPI / OF2;
    for (i = 0; i < 6; i++)
        Oc[i][0] = Oc[i][1] = Ocf1 + (Ocf2 - Ocf1) * 0.2f * (float)i;

    // Noise bands
    chkOn[3] = params->band1_on;
    BON = chkOn[3];
    sliLev[3] = params->band1_level;
    BL = (float)(sliLev[3] * sliLev[3]) * mem_b;
    BF = MasterTune * TWOPI * params->band1_f / FS;
    BPhi = TWOPI / 8.f;
    getEnv(5, params->band1_envelope);
    BFStep = params->band1_df;
    BQ = (float)BFStep;
    BQ = BQ * BQ / (10000.f - 6600.f * ((float)sqrt(BF) - 0.19f));
    BFStep = 1 + (int)((40.f - (BFStep / 2.5f)) / (BQ + 1.f + (1.f * BF)));

    chkOn[4] = params->band2_on;
    BON2 = chkOn[4];
    sliLev[4] = params->band2_level;
    BL2 = (float)(sliLev[4] * sliLev[4]) * mem_b;
    BF2 = MasterTune * TWOPI * params->band2_f / FS;
    BPhi2 = TWOPI / 8.f;
    getEnv(6, params->band2_envelope);
    BFStep2 = params->band2_df;
    BQ2 = (float)BFStep2;
    BQ2 = BQ2 * BQ2 / (10000.f - 6600.f * ((float)sqrt(BF2) - 0.19f));
    BFStep2 = 1 + (int)((40 - (BFStep2 / 2.5)) / (BQ2 + 1 + (1 * BF2)));

    // Distortion
    chkOn[5] = params->dist_on;
    DiON = chkOn[5];
    DStep = 1 + params->dist_rate;
    if (DStep == 7) DStep = 20;
    if (DStep == 6) DStep = 10;
    if (DStep == 5) DStep = 8;

    clippoint = 32700;
    DAtten = 1.0f;

    if (DiON == 1) {
        DAtten = DGain * (short)LoudestEnv();
        if (DAtten > 32700) clippoint = 32700;
        else clippoint = (short)DAtten;
        DAtten = (float)pow(2.0, 2.0 * params->dist_bits);
        DGain = DAtten * DGain * (float)pow(10.0, 0.05 * params->dist_clipping);
    }

    // Prepare envelopes
    randmax = 1.f / RAND_MAX;
    randmax2 = 2.f * randmax;
    for (i = 1; i < 8; i++) {
        envData[i][NEXTT] = 0;
        envData[i][PNT] = 0;
    }
    Length = LongestEnv();

    if (Length > max_samples) Length = max_samples;

    // Generate
    tpos = 0;
    while (tpos < Length) {
        tplus = tpos + 1199;
        if (tplus >= Length) tplus = Length - 1;

        if (NON == 1) {
            for (t = tpos; t <= tplus; t++) {
                if (t < envData[2][NEXTT])
                    envData[2][ENV] = envData[2][ENV] + envData[2][DENV];
                else
                    UpdateEnv(2, t);
                x[2] = x[1];
                x[1] = x[0];
                x[0] = (randmax2 * (float)rand()) - 1.f;
                TT = a * x[0] + b * x[1] + c * x[2] + d * TT;
                DF[t - tpos] = TT * g * envData[2][ENV];
            }
            if (t >= envData[2][MAX]) NON = 0;
        } else {
            for (j = 0; j < 1200; j++) DF[j] = 0.f;
        }

        if (TON == 1) {
            TphiStart = Tphi;
            if (TDroop == 1) {
                for (t = tpos; t <= tplus; t++)
                    phi[t - tpos] = F2 + (ddF * (float)exp(t * TDroopRate));
            } else {
                for (t = tpos; t <= tplus; t++)
                    phi[t - tpos] = F1 + (t / envData[1][MAX]) * ddF;
            }
            for (t = tpos; t <= tplus; t++) {
                totmp = t - tpos;
                if (t < envData[1][NEXTT])
                    envData[1][ENV] = envData[1][ENV] + envData[1][DENV];
                else
                    UpdateEnv(1, t);
                Tphi = Tphi + phi[totmp];
                DF[totmp] += TL * envData[1][ENV] * (float)sin(fmod(Tphi, TWOPI));
            }
            if (t >= envData[1][MAX]) TON = 0;
        } else {
            for (j = 0; j < 1200; j++) phi[j] = F2;
        }

        if (BON == 1) {
            for (t = tpos; t <= tplus; t++) {
                if (t < envData[5][NEXTT])
                    envData[5][ENV] = envData[5][ENV] + envData[5][DENV];
                else
                    UpdateEnv(5, t);
                if ((t % BFStep) == 0)
                    BdF = randmax * (float)rand() - 0.5f;
                BPhi = BPhi + BF + BQ * BdF;
                botmp = t - tpos;
                DF[botmp] = DF[botmp] + (float)cos(fmod(BPhi, TWOPI)) * envData[5][ENV] * BL;
            }
            if (t >= envData[5][MAX]) BON = 0;
        }

        if (BON2 == 1) {
            for (t = tpos; t <= tplus; t++) {
                if (t < envData[6][NEXTT])
                    envData[6][ENV] = envData[6][ENV] + envData[6][DENV];
                else
                    UpdateEnv(6, t);
                if ((t % BFStep2) == 0)
                    BdF2 = randmax * (float)rand() - 0.5f;
                BPhi2 = BPhi2 + BF2 + BQ2 * BdF2;
                botmp = t - tpos;
                DF[botmp] = DF[botmp] + (float)cos(fmod(BPhi2, TWOPI)) * envData[6][ENV] * BL2;
            }
            if (t >= envData[6][MAX]) BON2 = 0;
        }

        for (t = tpos; t <= tplus; t++) {
            if (OON == 1) {
                if (t < envData[3][NEXTT])
                    envData[3][ENV] = envData[3][ENV] + envData[3][DENV];
                else {
                    if (t >= envData[3][MAX]) {
                        envData[3][ENV] = 0;
                        envData[3][DENV] = 0;
                        envData[3][NEXTT] = 999999;
                    } else
                        UpdateEnv(3, t);
                }

                if (t < envData[4][NEXTT])
                    envData[4][ENV] = envData[4][ENV] + envData[4][DENV];
                else {
                    if (t >= envData[4][MAX]) {
                        envData[4][ENV] = 0;
                        envData[4][DENV] = 0;
                        envData[4][NEXTT] = 999999;
                    } else
                        UpdateEnv(4, t);
                }

                TphiStart = TphiStart + phi[t - tpos];
                if (OF1Sync == 1) Ophi1 = TphiStart * OF1;
                else Ophi1 = Ophi1 + OF1;
                if (OF2Sync == 1) Ophi2 = TphiStart * OF2;
                else Ophi2 = Ophi2 + OF2;
                Ot = 0.0f;

                switch (OMode) {
                    case 0:  // Add
                        Ot = OBal1 * envData[3][ENV] * waveform(Ophi1, OW1);
                        Ot = OL * (Ot + OBal2 * envData[4][ENV] * waveform(Ophi2, OW2));
                        break;
                    case 1:  // FM
                        Ot = ODrive * envData[4][ENV] * waveform(Ophi2, OW2);
                        Ot = OL * envData[3][ENV] * waveform(Ophi1 + Ot, OW1);
                        break;
                    case 2:  // RM
                        Ot = (1 - ODrive / 8) + (((ODrive / 8) * envData[4][ENV]) * waveform(Ophi2, OW2));
                        Ot = OL * envData[3][ENV] * waveform(Ophi1, OW1) * Ot;
                        break;
                    case 3:  // 808 Cymbal
                        for (j = 0; j < 6; j++) {
                            Oc[j][0] += 1.0f;
                            if (Oc[j][0] > Oc[j][1]) {
                                Oc[j][0] -= Oc[j][1];
                                Ot = OL * envData[3][ENV];
                            }
                        }
                        Ocf1 = envData[4][ENV] * OcF;
                        Oc0 += Ocf1 * Oc1;
                        Oc1 += Ocf1 * (Ot + Oc2 - OcQ * Oc1 - Oc0);
                        Oc2 = Ot;
                        Ot = Oc1;
                        break;
                }
            }

            if (MainFilter == 1) {
                if (t < envData[7][NEXTT])
                    envData[7][ENV] = envData[7][ENV] + envData[7][DENV];
                else
                    UpdateEnv(7, t);

                MFtmp = envData[7][ENV];
                if (MFtmp > 0.2f)
                    MFfb = 1.001f - (float)pow(10.0f, MFtmp - 1);
                else
                    MFfb = 0.999f - 0.7824f * MFtmp;

                MFtmp = Ot + MFres * (1.f + (1.f / MFfb)) * (MFin - MFout);
                MFin = MFfb * (MFin - MFtmp) + MFtmp;
                MFout = MFfb * (MFout - MFin) + MFin;

                DF[t - tpos] = DF[t - tpos] + (MFout - (HighPass * Ot));
            } else if (MainFilter == 2) {
                if (t < envData[7][NEXTT])
                    envData[7][ENV] = envData[7][ENV] + envData[7][DENV];
                else
                    UpdateEnv(7, t);

                MFtmp = envData[7][ENV];
                if (MFtmp > 0.2f)
                    MFfb = 1.001f - (float)pow(10.0f, MFtmp - 1);
                else
                    MFfb = 0.999f - 0.7824f * MFtmp;

                MFtmp = DF[t - tpos] + Ot + MFres * (1.f + (1.f / MFfb)) * (MFin - MFout);
                MFin = MFfb * (MFin - MFtmp) + MFtmp;
                MFout = MFfb * (MFout - MFin) + MFin;

                DF[t - tpos] = MFout - (HighPass * (DF[t - tpos] + Ot));
            } else {
                DF[t - tpos] = DF[t - tpos] + Ot;
            }
        }

        if (DiON == 1) {
            for (j = 0; j < 1200; j++)
                DF[j] = DGain * (int)(DF[j] / DAtten);

            for (j = 0; j < 1200; j += DStep) {
                DownAve = 0;
                DownStart = j;
                DownEnd = j + DStep - 1;
                for (jj = DownStart; jj <= DownEnd; jj++)
                    DownAve = DownAve + DF[jj];
                DownAve = DownAve / DStep;
                for (jj = DownStart; jj <= DownEnd; jj++)
                    DF[jj] = DownAve;
            }
        } else {
            for (j = 0; j < 1200; j++)
                DF[j] *= DGain;
        }

        for (j = 0; j < 1200 && wavewords < Length; j++) {
            if (DF[j] > clippoint)
                buffer[wavewords++] = clippoint;
            else if (DF[j] < -clippoint)
                buffer[wavewords++] = -clippoint;
            else
                buffer[wavewords++] = (short)DF[j];
        }

        tpos = tpos + 1200;
    }

    return wavewords;
}

DS_API int DS_CALL ds_to_wav(const char* dsfile, const char* wavfile) {
    DrumSynthParams params;

    int result = ds_load_file(dsfile, &params);
    if (result != DS_OK) return result;

    int length = ds_estimate_length(&params);
    int16_t* buffer = (int16_t*)malloc(length * sizeof(int16_t));
    if (!buffer) return DS_ERR_MEMORY;

    int samples = ds_synthesize(&params, buffer, length);
    if (samples <= 0) {
        free(buffer);
        return DS_ERR_MEMORY;
    }

    // Write WAV file
    FILE* fp = fopen(wavfile, "wb");
    if (!fp) {
        free(buffer);
        return DS_ERR_OUTPUT;
    }

    // WAV header
    uint32_t dataSize = samples * 2;
    uint32_t fileSize = 36 + dataSize;
    uint16_t audioFormat = 1;  // PCM
    uint16_t numChannels = 1;
    uint32_t sampleRate = 44100;
    uint32_t byteRate = 88200;
    uint16_t blockAlign = 2;
    uint16_t bitsPerSample = 16;

    fwrite("RIFF", 1, 4, fp);
    fwrite(&fileSize, 4, 1, fp);
    fwrite("WAVE", 1, 4, fp);
    fwrite("fmt ", 1, 4, fp);
    uint32_t fmtSize = 16;
    fwrite(&fmtSize, 4, 1, fp);
    fwrite(&audioFormat, 2, 1, fp);
    fwrite(&numChannels, 2, 1, fp);
    fwrite(&sampleRate, 4, 1, fp);
    fwrite(&byteRate, 4, 1, fp);
    fwrite(&blockAlign, 2, 1, fp);
    fwrite(&bitsPerSample, 2, 1, fp);
    fwrite("data", 1, 4, fp);
    fwrite(&dataSize, 4, 1, fp);
    fwrite(buffer, 2, samples, fp);

    fclose(fp);
    free(buffer);

    return DS_OK;
}
