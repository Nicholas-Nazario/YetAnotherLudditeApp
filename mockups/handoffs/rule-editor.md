# Feature: Rule Editor

## Status

APPROVED

## Reference Files

- `mockups/rule-editor/index.html`
- `mockups/rule-editor/styles.css`
- `mockups/rule-editor/app.js`
- `mockups/rule-editor/README.md`
- `mockups/today/styles.css` (established visual language and token values)
- `mockups/rules/styles.css` (grouped surfaces, navigation rhythm, and simulation notice)
- `YetAnotherLudditeApp/App/RuleEditorView.swift` (current native form and save flow)
- `YetAnotherLudditeApp/Shared/Rules/Rule.swift` (schedule and validation model)
- `YetAnotherLudditeApp/Shared/Rules/DomainPattern.swift` (current website matching model)
- `YetAnotherLudditeApp/Simulation/SimulationCatalog.swift` (sample app identities)

## Overview

The Rule editor is a single scrollable form for creating or editing one rule. It lets the user name the rule, choose when it applies, and select app and website targets. The screen is a management form; it must not imply that Phase 0 restrictions are enforced on the device.

## Screen Structure

1. Native navigation bar with **Cancel**, centered **New Rule** or **Edit Rule** title, and **Save**.
2. Phase 0 Simulation banner: “No apps or websites are actually blocked.”
3. **Name** section: rule name, then independent **Enabled** toggle.
4. **Schedule** section: seven individual weekday controls; summary; start and end times; overnight and minimum-duration helper text.
5. **Targets** section:
   - **Apps** subsection with the existing Simulator sample choices and a concise explanation.
   - **Websites** subsection with current entries, removal actions, address field, Match control, explanatory preview, and Add website action.

Keep the complete form in one vertical scroll. Do not split it into steps or add shortcut day presets.

## Layout

- Use a standard native navigation bar within the current `NavigationStack`; keep Cancel and Save in their conventional leading/trailing toolbar placements.
- Place the simulation banner immediately before the form sections.
- Keep section order exactly **Name → Schedule → Targets**. Use section labels outside white, rounded grouped surfaces, following the mockup’s spacing and the project’s existing form/card language.
- Use approximately 18–20 pt horizontal content inset, 20–24 pt between major sections, and 7–9 pt between a section heading and its content surface. Let controls and rows grow for Dynamic Type.
- Keep the seven day controls in one row when they fit. Their interactive hit areas should be at least 44 pt; if necessary at larger text sizes, allow horizontal scrolling or wrapping while retaining full weekday labels for accessibility.
- Keep start and end controls in separate full-width rows. Show the current schedule summary directly below the weekday controls; when there are no selected days, show **Choose at least one day**.
- Put field errors immediately after the related field group. Validation may scroll to and focus the first invalid field, but all detected errors should remain visible.
- Allow natural vertical scrolling with keyboard and safe-area handling. Keep Save available in the navigation bar while scrolling.
- The prototype specifies light appearance only. Use semantic system colors for native light/dark support if the app already supports both.

## Design Tokens

No shared token file exists, and no global token changes are requested. Use the current mockup tokens:

- Canvas `#F7F8FD`; primary text `#172344`; secondary text `#64708D`; white grouped surface `#FFFFFF`.
- Primary action blue `#355FD7` (deep blue `#273F9B`); purple identity `#7354CC`.
- Separator/border `#E7EAF4`; error text `#A1465B` with error wash `#FCECF0`.
- Group surface radius approximately 14–18 pt; section spacing 20–24 pt; control hit area at least 44 pt.
- Use the platform system font and Dynamic Type. At default size, title around 17 pt in the navigation bar, section headings 15–16 pt semibold, field text around 15 pt, and helper/error text around 11–13 pt.

## Components

- **Simulation banner:** Reuse the existing `SimulationBanner`; preserve the explicit no-blocking copy.
- **Name field:** Full-width text field with a clear prompt. Use word capitalization. The **Enabled** switch remains a separate row and defaults on for a new rule.
- **Weekday picker:** Seven individual toggle-style controls Monday through Sunday. No weekday/weekend/every-day preset.
- **Time controls:** Native hour-and-minute DatePickers for **Starts** and **Ends**. Initial display values are 9:00 AM and 5:00 PM.
- **Apps:** Reuse `SimulationCatalog.apps`: Sample App A, Sample App B, and Sample App C. Preserve the note that these are Simulator examples, not apps installed on the phone. Tapping a row toggles that sample app.
- **Website list:** Show each saved host and its matching scope, with a labeled remove control. Allow editing/removing the last target in the draft; Save then validates that at least one target remains.
- **Website composer:** URL-keyboard text field with autocorrection/capitalization disabled and placeholder `www.youtube.com`; Match control defaults to **This website** and offers **All subdomains**; show a concise preview before Add website.
- **Validation:** Inline field errors; keep entered values and selections while correcting issues.
- **Unsaved-change confirmation:** On Cancel or navigation dismissal after a change, confirm before discarding. Keep Editing returns to the form; Discard Changes dismisses it.

## Interactions

- **Cancel:** If unchanged, return to Rules. If dirty, ask whether to discard unsaved changes. A confirmation should cover system back/swipe dismissal too where practical.
- **Save:** Validate name, selected days, valid time range of at least 15 minutes, website draft state, and at least one target. Keep Save available; do not toggle Enabled automatically based on schedule state.
- **Validation:** Show every applicable error inline, then scroll to and focus the first invalid field in screen order. Clear an error when its condition is corrected.
- **Days:** Toggle each day independently. Days represent the schedule’s start day. No selected day means the form is incomplete and Save shows an error; it does not automatically disable the rule.
- **Schedule summary:** Update as days and time values change. An overnight interval is described as ending **next day**. Minimum valid duration is 15 minutes.
- **Targets:** App rows toggle sample identities. Website Add validates and appends the entry; removing an entry updates the draft. Website text that is not added remains visible and Save directs the user to add or clear it.
- **Website Match:** Defaults to **This website**. For `youtube.com`, this includes `youtube.com` and `www.youtube.com`, but not `m.youtube.com`. **All subdomains** includes the base host and any subdomain; use `m.youtube.com` as the visible example.
- **Website host normalization:** Normalize case and a leading `www.` to the base host for matching. A trailing path may be accepted as URL input and only the hostname is stored, consistent with the current parser. Do not expose wildcard syntax in this screen.
- **Duplicate websites:** Reject an identical host-and-scope entry with an inline error. The same host with a different scope is representable as a separate entry, matching current `DomainPattern` identity semantics.
- **Save success:** Persist through the existing app model and dismiss the editor. The mockup toast is review feedback only.

## UI States

- **New rule default:** Blank name, Enabled on, no days selected, 9:00 AM–5:00 PM picker values, no targets, no validation errors until Save. Schedule summary says **Choose at least one day**.
- **Editing existing rule:** Prefill every property; initial values are not assumed to be the new-rule defaults.
- **Selected schedule:** Show chosen days and localized time range; overnight range includes **next day**.
- **No selected days:** On Save show **Choose at least one day** inline. Keep Enabled independent.
- **No targets:** On Save show a target-required error; allow last-target removal in the draft while retaining the rest of the entered values.
- **Invalid duration:** On Save show the minimum-duration error near the time controls.
- **Unadded website:** Preserve text and show **Add this website or clear the field before saving** next to the address composer.
- **Invalid/duplicate website:** Show an inline message next to the website field and keep the input for correction.
- **Unsaved changes:** Confirmation offers **Keep Editing** and **Discard Changes**.
- **Save success/storage failure:** Existing app save behavior applies. On persistence failure, retain the form and show the existing error feedback.
- **Loading/empty/error data states:** No new asynchronous content state is specified; preserve existing app model behavior.

## Accessibility

- Use native form controls and accessibility values for day toggles, time pickers, website matching, and selected app states.
- Weekday controls must expose full day names, not only single-letter visual labels.
- Ensure 44 pt minimum interactive targets; provide a larger hit area around day buttons and website removal controls.
- Associate inline errors with their fields, announce validation results, and move VoiceOver focus to the first invalid field after Save.
- Respect Dynamic Type; allow section text, helper copy, errors, and app/website rows to wrap. Avoid clipped horizontal day labels at accessibility sizes.
- Use accessible names for website removal, such as **Remove youtube.com**. Do not rely on color alone to indicate selected or invalid states.
- Preserve sufficient contrast for secondary copy, segmented options, and error messages.

## Native Implementation Notes

- The current `RuleEditorView` already uses a single SwiftUI `Form`, `Toggle`, `DatePicker`, and `TextField`. Preserve the existing model/save architecture and adapt layout and inline validation rather than creating a new flow.
- Change new-rule schedule initialization from weekdays to an empty `weekdays` set; keep the initial 9:00 AM–5:00 PM values and `isEnabled == true`. Do not infer the Enabled value from whether days are selected.
- Current `Rule.validationMessage()` returns only one error. The approved UI requires multiple applicable inline errors, so use field-specific validation results or an equivalent presentation layer while retaining the underlying validation rules.
- Existing save validation requires a selected day and at least one target, consistent with this design. Ensure a failed Save does not mutate stored state. Preserve draft values during validation.
- Keep the current overnight start-day semantics and 15-minute minimum. Continue using the provided calendar/date for reproducible schedule evaluation.
- **Matcher alignment required:** `DomainPattern.matches(host:)` currently treats `.exactHost` as only the stored host. The agreed **This website** option must match both the entered base host and its `www` host. Normalize a user-entered leading `www.` consistently before saving; include exact cases such as input `www.youtube.com`. The broad option matches the base host and suffix-bounded subdomains (not lookalikes such as `notyoutube.com`). This is a product behavior update required by the agreed UX, not just a label change.
- Current parsing can interpret `*.` as including subdomains. Do not surface that syntax in the UI; decide during native implementation whether to keep parser compatibility for old saved data, while ensuring the visible form uses only Match.
- Use `NavigationStack` toolbar items for Cancel/Save, native `Form` or equivalent grouped sections for the continuous scroll, and a native alert/confirmation dialog for discard. The HTML time input and custom segmented style are visual aids; use native `DatePicker` and `Picker`/segmented control.
- In Phase 0, keep all explanatory copy accurate: sample apps are examples, website matching is a preview, and Safari and Private Browsing are not restricted.

## Acceptance Criteria

- The editor is one vertically scrollable form in Name, Schedule, Targets order.
- A new rule starts enabled with no days selected and 9:00 AM–5:00 PM values; the schedule summary prompts the user to choose a day.
- The seven day controls are individually selectable with no shortcut presets.
- Start/end time changes update the summary; overnight schedules show **next day** and retain start-day semantics; durations under 15 minutes fail validation.
- **Enabled** is independent from selected schedule days and does not change automatically.
- Sample app choices match `SimulationCatalog` and are clearly described as Simulator examples.
- The website field shows `www.youtube.com` as its placeholder. The default **This website** option covers the base host and `www` version, but not `m.youtube.com`.
- **All subdomains** covers the base and its subdomains with suffix-boundary matching.
- Website input normalizes a leading `www.`; a user never needs to type wildcard syntax.
- Website entries can be added and removed; invalid and duplicate entries show inline errors.
- Save with a blank name, no days, invalid duration, no targets, or unadded website text keeps the draft and displays corresponding inline guidance. Multiple applicable errors are visible together; the first invalid field receives focus.
- Removing the final target is allowed in the draft and produces a target-required error on Save.
- Cancel with no changes dismisses. Cancel or back dismissal with changes confirms before discarding.
- Save success and storage errors use the existing app model behavior; no partial changes are persisted after validation failure.
- The simulation banner and website note do not imply real app, Safari, or Private Browsing restrictions.
- Layout remains readable with larger Dynamic Type and keyboard presentation, with no clipped or inaccessible controls.

## Open Questions

None. The user has explicitly settled the interaction and edge-case decisions. This handoff records the approved design; native implementation is tracked separately from this mockup.

## Browser Validation

On 2026-10-12, all four scenarios rendered in installed Chrome via Playwright at 1280, 390, and 320 px without page or form horizontal overflow or JavaScript errors. Default, validation-error, and enlarged-text screenshots are available in [the original mockup PR](https://github.com/Nicholas-Nazario/YetAnotherLudditeApp/pull/8). Review-only screenshots are not stored in the source tree. The enlarged-text capture is a browser stress example, not native Dynamic Type verification. No native build or enforcement check was performed for this mockup PR.
