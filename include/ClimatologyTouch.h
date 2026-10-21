#ifndef CLIMATOLOGY_TOUCH_H
#define CLIMATOLOGY_TOUCH_H

#ifdef __OCPN__ANDROID__
#include <wx/checkbox.h>
#include <wx/choice.h>
#include <wx/control.h>
#include <wx/scrolwin.h>
#include <wx/slider.h>
#include <wx/stattext.h>
#include <wx/textctrl.h>
#include <wx/spinctrl.h>

// Qt styles are applied after wxFormBuilder has cached desktop-sized controls.
// Recalculate their text metrics and reserve a usable touch target afterwards.
inline void ClimatologyTouchControls(wxWindow* window, const wxFont& font) {
    window->SetFont(font);
    for (wxWindowList::iterator it = window->GetChildren().begin();
         it != window->GetChildren().end(); ++it)
        ClimatologyTouchControls(*it, font);
    window->InvalidateBestSize();
    if (wxCheckBox* checkbox = dynamic_cast<wxCheckBox*>(window)) {
        const int text_width = checkbox->GetTextExtent(checkbox->GetLabel()).x;
        checkbox->SetMinSize(wxSize(text_width + 54, 48));
    } else if (dynamic_cast<wxChoice*>(window)) {
        window->SetMinSize(wxSize(150, 48));
    } else if (dynamic_cast<wxSpinCtrl*>(window)) {
        window->SetMinSize(wxSize(100, 48));
    } else if (dynamic_cast<wxSlider*>(window)) {
        window->SetMinSize(wxSize(180, 48));
    } else if (dynamic_cast<wxButton*>(window)) {
        window->SetMinSize(wxSize(-1, 48));
    } else if (dynamic_cast<wxTextCtrl*>(window)) {
        window->SetMinSize(wxSize(90, 48));
    }
    if (wxScrolledWindow* scrolled = dynamic_cast<wxScrolledWindow*>(window)) {
        scrolled->SetScrollRate(12, 12);
        scrolled->FitInside();
    }
    window->Layout();
}

inline wxFont ClimatologyTouchFont() {
    wxFont font = GetOCPNGUIScaledFont_PlugIn(_("Dialog"));
    if (!font.IsOk()) font = *wxNORMAL_FONT;
    font.SetPointSize(wxMax(14, font.GetPointSize()));
    return font;
}
#endif
#endif
