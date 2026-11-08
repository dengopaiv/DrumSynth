// uia_dump - what UI Automation (the interface Narrator uses) reports for
// every control of a running DrumSynth window: control type, name, and
// value (Value pattern, or the slider's legacy MSAA value). Uses the native
// IUIAutomation client, which includes the Windows proxies for Win32
// controls (unlike PowerShell's managed client).
//
//   uia_dump ["window title start"]
//
// Exit code 1 if a focusable control has no name.
#include <cstdio>
#include <string>
#include <windows.h>
#include <uiautomation.h>

static int g_unnamed = 0;

static std::wstring Str(BSTR b) { std::wstring s = b ? b : L""; SysFreeString(b); return s; }

static void Dump(IUIAutomation* uia, IUIAutomationTreeWalker* walker, IUIAutomationElement* e, int depth)
{
    IUIAutomationElement* c = nullptr;
    walker->GetFirstChildElement(e, &c);
    while (c) {
        CONTROLTYPEID type = 0;
        c->get_CurrentControlType(&type);
        BSTR name = nullptr, ltype = nullptr;
        c->get_CurrentName(&name);
        c->get_CurrentLocalizedControlType(&ltype);
        BOOL focusable = FALSE;
        c->get_CurrentIsKeyboardFocusable(&focusable);
        std::wstring n = Str(name), t = Str(ltype), value;
        IUIAutomationValuePattern* vp = nullptr;
        if (SUCCEEDED(c->GetCurrentPatternAs(UIA_ValuePatternId, IID_PPV_ARGS(&vp))) && vp) {
            BSTR v = nullptr;
            vp->get_CurrentValue(&v);
            value = Str(v);
            vp->Release();
        }
        if (value.empty()) {
            IUIAutomationLegacyIAccessiblePattern* lp = nullptr;
            if (SUCCEEDED(c->GetCurrentPatternAs(UIA_LegacyIAccessiblePatternId, IID_PPV_ARGS(&lp))) && lp) {
                BSTR v = nullptr;
                lp->get_CurrentValue(&v);
                value = Str(v);
                lp->Release();
            }
        }
        bool interactive = type == UIA_ButtonControlTypeId || type == UIA_CheckBoxControlTypeId ||
                           type == UIA_EditControlTypeId || type == UIA_SliderControlTypeId ||
                           type == UIA_ComboBoxControlTypeId || type == UIA_ListControlTypeId;
        if (interactive && focusable && n.empty()) g_unnamed++;
        if (interactive || type == UIA_GroupControlTypeId)
            wprintf(L"%*s%s | %s%s%s\n", depth * 2, L"", t.c_str(), n.c_str(), value.empty() ? L"" : L" | value: ",
                    value.c_str());
        if (type != UIA_ListControlTypeId && type != UIA_ComboBoxControlTypeId) Dump(uia, walker, c, depth + 1);
        IUIAutomationElement* next = nullptr;
        walker->GetNextSiblingElement(c, &next);
        c->Release();
        c = next;
    }
}

int wmain(int argc, wchar_t** argv)
{
    std::wstring title = argc > 1 ? argv[1] : L"DrumSynth";
    CoInitializeEx(nullptr, COINIT_MULTITHREADED);
    IUIAutomation* uia = nullptr;
    if (FAILED(CoCreateInstance(CLSID_CUIAutomation, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&uia)))) return 2;
    HWND found = nullptr;
    for (HWND h = GetTopWindow(nullptr); h; h = GetNextWindow(h, GW_HWNDNEXT)) {
        wchar_t t[256];
        GetWindowTextW(h, t, 256);
        if (IsWindowVisible(h) && wcsstr(t, title.c_str())) { found = h; break; }
    }
    if (!found) { wprintf(L"window not found\n"); return 2; }
    IUIAutomationElement* root = nullptr;
    uia->ElementFromHandle(found, &root);
    IUIAutomationTreeWalker* walker = nullptr;
    uia->get_ControlViewWalker(&walker);
    Dump(uia, walker, root, 0);
    wprintf(L"focusable controls without a name: %d\n", g_unnamed);
    return g_unnamed ? 1 : 0;
}
