// access.cpp - see access.h.
#include "access.h"

#include <wx/access.h>
#include <wx/app.h>
#include <windows.h>
#include <uiautomation.h>

namespace {

// Tolk (https://github.com/dkager/tolk), loaded at run time if present.
struct Tolk {
    using LoadFn = void(__cdecl*)();
    using OutputFn = bool(__cdecl*)(const wchar_t*, bool);
    OutputFn output = nullptr;
    Tolk()
    {
        HMODULE h = LoadLibraryW(L"Tolk.dll");
        if (!h) return;
        auto load = reinterpret_cast<LoadFn>(GetProcAddress(h, "Tolk_Load"));
        output = reinterpret_cast<OutputFn>(GetProcAddress(h, "Tolk_Output"));
        if (load) load();
        else output = nullptr;
    }
};

bool UiaNotify(const wxString& text, wxWindow* window)
{
    if (!window) return false;
    IRawElementProviderSimple* provider = nullptr;
    if (FAILED(UiaHostProviderFromHwnd(static_cast<HWND>(window->GetHWND()), &provider)) || !provider)
        return false;
    BSTR msg = SysAllocString(text.wc_str());
    BSTR id = SysAllocString(L"DrumSynth");
    HRESULT hr = UiaRaiseNotificationEvent(provider, NotificationKind_Other,
                                           NotificationProcessing_ImportantMostRecent, msg, id);
    SysFreeString(msg);
    SysFreeString(id);
    provider->Release();
    return SUCCEEDED(hr);
}

class SliderAccessible : public wxWindowAccessible {
public:
    explicit SliderAccessible(ValueSlider* s) : wxWindowAccessible(s), slider_(s) {}
    wxAccStatus GetName(int childId, wxString* name) override
    {
        if (childId != wxACC_SELF) return wxACC_NOT_IMPLEMENTED;
        *name = slider_->AccessibleName();
        return wxACC_OK;
    }
    wxAccStatus GetValue(int childId, wxString* value) override
    {
        if (childId != wxACC_SELF) return wxACC_NOT_IMPLEMENTED;
        *value = slider_->ValueText();
        return wxACC_OK;
    }

private:
    ValueSlider* slider_;
};

}  // namespace

void Announce(const wxString& text, wxWindow* window)
{
    static Tolk tolk;
    if (tolk.output && tolk.output(text.wc_str(), true)) return;
    UiaNotify(text, window ? window : wxTheApp->GetTopWindow());
}

ValueSlider::ValueSlider(wxWindow* parent, int value, int min, int max, const wxString& name,
                         Formatter format, int pageSize)
    : wxSlider(parent, wxID_ANY, value, min, max, wxDefaultPosition, wxSize(140, -1),
               wxSL_HORIZONTAL),
      name_(name), format_(std::move(format))
{
    SetPageSize(pageSize);
    SetLineSize(1);
    SetAccessible(new SliderAccessible(this));
    SetToolTip(name);
}

wxString ValueSlider::ValueText() const
{
    wxString t = format_ ? format_(GetValue()) : wxString::Format("%d", GetValue());
    if (!raw_.empty()) t += wxString::Format(" (out of range: %s)", raw_);
    return t;
}

void ValueSlider::NotifyValueChanged()
{
    wxAccessible::NotifyEvent(wxACC_EVENT_OBJECT_VALUECHANGE, this, wxOBJID_CLIENT, wxACC_SELF);
}
