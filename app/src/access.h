// access.h - accessibility helpers for the DrumSynth GUI.
//
// - Announce(): speaks a message through the screen reader. It uses Tolk
//   (Tolk.dll next to the program, if present), which talks to NVDA, JAWS
//   and others directly; otherwise a UI Automation notification event, which
//   NVDA and Narrator read.
// - ValueSlider: a wxSlider whose accessible value is the text the original
//   GUI shows beside it ("-6.0 dB", "Pink", "Q = 20") instead of the bare
//   number, and whose accessible name is its label.
#pragma once

#include <functional>
#include <wx/slider.h>
#include <wx/string.h>
#include <wx/window.h>

void Announce(const wxString& text, wxWindow* window);

class ValueSlider : public wxSlider {
public:
    using Formatter = std::function<wxString(int)>;
    ValueSlider(wxWindow* parent, int value, int min, int max, const wxString& name, Formatter format,
                int pageSize);
    wxString ValueText() const;
    wxString AccessibleName() const { return name_; }
    void SetAccessibleName(const wxString& n) { name_ = n; SetToolTip(n); }
    // Call after the value changes, so screen readers read the new text.
    void NotifyValueChanged();
    // A value outside the slider's range, kept from a loaded preset
    // (docs/gui-checklist.md, section 6).
    void SetRawOverride(const wxString& raw) { raw_ = raw; }
    const wxString& RawOverride() const { return raw_; }

private:
    wxString name_;
    Formatter format_;
    wxString raw_;
};
