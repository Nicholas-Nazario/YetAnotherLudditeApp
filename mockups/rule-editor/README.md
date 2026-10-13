# Rule editor mockup

This standalone prototype shows the agreed create and edit form for rules. Open `index.html` directly in a browser. The review controls outside the phone switch between New rule, Editing a rule, Validation errors, and Unsaved changes.

## Screen intent

The editor is one vertically scrollable form, in the order **Name → Schedule → Targets**. It supports finding and managing one saved rule while letting a person review and update its name, weekly schedule, enabled state, and sample app or website targets.

## Form behavior

- A new rule is enabled, has no days selected, and starts with 9:00 AM and 5:00 PM time values. Until days are selected, the summary says “Choose at least one day.”
- The seven day controls are individually selectable, Monday through Sunday. Selected days refer to the schedule start day. Overnight ranges show “next day”; the minimum duration is 15 minutes.
- Save validates the name, at least one selected day, a valid duration, and at least one app or website. Applicable errors appear beside their fields; the form scrolls to and focuses the first issue in form order.
- Website text that has not been added remains in the input. Save asks the user to add it or clear it. Invalid and duplicate entries show an inline error.
- The website field placeholder is `www.youtube.com`. Match defaults to **This website**: it includes the base host and its `www` version, but not other subdomains. **All subdomains** also includes hosts such as `m.youtube.com`. Typing a `www.` host normalizes it to the base host. No wildcard syntax is shown.
- App selections are sample Simulator identities only. The screen clearly says that website entries are previews and Safari and Private Browsing are not restricted in Phase 0.
- Cancel returns to Rules when the form is unchanged. With unsaved edits, it shows a discard confirmation. Save provides review feedback; the actual app saves through its existing model and dismisses the editor.

## Review scenarios

- **New rule:** Empty name, no selected schedule days, no targets; default time values 9:00 AM–5:00 PM; Enabled on.
- **Editing a rule:** Populated `Evening Reset`, all days, overnight 10:00 PM–7:00 AM schedule, two sample app identities and one website.
- **Validation errors:** Empty name, no days, zero-length schedule, no selected targets, and an unadded website string show inline messages together.
- **Unsaved changes:** A changed existing rule and the discard confirmation are visible.

Scenario controls, device frame, status bar, toast, and sample fixtures are review-only. The form uses basic HTML controls to demonstrate interactions; the intended native equivalents are SwiftUI `Form`/`ScrollView`, `TextField`, `Toggle`, day-selection buttons, `DatePicker`, `Picker`, and an alert or confirmation dialog.

## Validation performed

Use the scenario controls and interact with the form to inspect schedule selection, overnight summary, website scope preview, target addition/removal, errors, and unsaved-change confirmation. No enforcement or persistence behavior is implemented in this prototype.

Browser validation on 2026-10-12 rendered all four scenarios at 1280, 390, and 320 px without horizontal overflow or JavaScript page errors. Review screenshots are in `screenshots/`; the larger-text example is a browser stress capture, not native Dynamic Type verification.
