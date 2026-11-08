// msaa_dump - list what MSAA (the interface NVDA and JAWS use for Win32
// controls) reports for every control of a running DrumSynth window: class,
// role, name, value and state. Every focusable control must have a name, and
// the sliders must report their value text.
//
//   msaa_dump ["window title start"]     (default "DrumSynth")
//
// Exit code 1 if a focusable control has no name.
#include <cstdio>
#include <string>
#include <windows.h>
#include <oleacc.h>

static std::wstring g_title = L"DrumSynth";
static HWND g_found = nullptr;
static int g_unnamed = 0;

static BOOL CALLBACK FindTop(HWND h, LPARAM)
{
    wchar_t t[256];
    GetWindowTextW(h, t, 256);
    if (wcsncmp(t, g_title.c_str(), g_title.size()) == 0 && IsWindowVisible(h)) { g_found = h; return FALSE; }
    return TRUE;
}

static BOOL CALLBACK Child(HWND h, LPARAM)
{
    if (!IsWindowVisible(h)) return TRUE;
    wchar_t cls[128];
    GetClassNameW(h, cls, 128);
    IAccessible* acc = nullptr;
    if (FAILED(AccessibleObjectFromWindow(h, OBJID_CLIENT, IID_IAccessible, (void**)&acc)) || !acc) return TRUE;
    VARIANT self;
    self.vt = VT_I4;
    self.lVal = CHILDID_SELF;
    VARIANT role, state;
    BSTR name = nullptr, value = nullptr;
    acc->get_accRole(self, &role);
    acc->get_accState(self, &state);
    acc->get_accName(self, &name);
    acc->get_accValue(self, &value);
    wchar_t roleText[64] = L"?";
    if (role.vt == VT_I4) GetRoleTextW(role.lVal, roleText, 64);
    bool focusable = state.vt == VT_I4 && (state.lVal & STATE_SYSTEM_FOCUSABLE);
    bool interactive = role.vt == VT_I4 && role.lVal != ROLE_SYSTEM_STATICTEXT && role.lVal != ROLE_SYSTEM_GROUPING &&
                       role.lVal != ROLE_SYSTEM_CLIENT && role.lVal != ROLE_SYSTEM_WINDOW &&
                       role.lVal != ROLE_SYSTEM_SPINBUTTON &&  // the arrows of a spin field; the field has the name
                       role.lVal != ROLE_SYSTEM_STATUSBAR;
    if (focusable && interactive && (!name || !*name)) g_unnamed++;
    if (interactive || (name && *name))
        wprintf(L"%-20s | %-16s | %s%s%s\n", cls, roleText, name ? name : L"", value && *value ? L" | value: " : L"",
                value ? value : L"");
    SysFreeString(name);
    SysFreeString(value);
    acc->Release();
    return TRUE;
}

int wmain(int argc, wchar_t** argv)
{
    if (argc > 1) g_title = argv[1];
    CoInitialize(nullptr);
    EnumWindows(FindTop, 0);
    if (!g_found) { wprintf(L"window not found\n"); return 2; }
    EnumChildWindows(g_found, Child, 0);
    wprintf(L"focusable controls without a name: %d\n", g_unnamed);
    return g_unnamed ? 1 : 0;
}
