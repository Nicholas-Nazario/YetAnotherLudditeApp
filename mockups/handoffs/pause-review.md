# Feature: Pause Review

## Status

APPROVED

Explicitly approved by the user on 2026-10-12 (“approve it”). Approval covers the completed Pause review reference, including the compact effect summary, expandable target details, gray confirmation button, Custom hours/minutes wheels, and concise website address/result rows.

## Reference Files

- `mockups/pause-review/index.html`
- `mockups/pause-review/styles.css`
- `mockups/pause-review/app.js`
- `mockups/pause-review/README.md`
- `mockups/rules/styles.css` — imported tokens and review shell
- `mockups/handoffs/rule-detail.md` — approved source of the Pause entry point
- Read-only native context: `YetAnotherLudditeApp/App/PauseRuleView.swift` and `AppModel.swift`

## Overview

Review the duration and consequences before temporarily suspending one rule. Keep default copy short with app outcome counts and a website caveat; reveal target-level explanations on demand. Confirmation stays gray to avoid encouraging a pause.

## Screen Structure

1. Full-height sheet, Cancel leading, Pause rule navigation title.
2. Full wrapping rule name, persistent Phase 0 Simulation notice, one sentence explaining that other rules apply.
3. Duration presets and optional custom hours/minutes wheels.
4. Pause ends timing and next scheduled application explanation.
5. Effect of this pause compact summary, View affected targets disclosure, immediate-effect caveat.
6. Inline persistence error when needed.
7. Fixed gray Confirm pause footer within native safe areas; no tabs inside the sheet.

## Layout

Default content inset 20 pt, section separation 21–22 pt, 15 pt grouped radius. Timing card padding 15 pt; effect card horizontal padding 15 pt. Rule name approximately 25 pt bold; section headings 15 pt semibold; body 14 pt; helper 12–13 pt. Native values use Dynamic Type styles rather than fixed limits.

Duration choices form four equal columns with 7 pt gaps where they fit, wrapping to two or fewer columns on narrow screens or accessibility text sizes. Each interactive area is at least 44 × 44 pt. Confirm pause is at least 48 pt high with 12 pt footer inset. The scroll region handles expanded targets, long names, and keyboard. Footer respects keyboard and safe areas; do not obscure the custom wheel or final error. The native custom control uses an iOS duration wheel, not a text field or keyboard.

Prototype desktop phone frame is review-only. Below 850 px the review panel stacks above the phone; below 460 px the phone fills the width. These are web review breakpoints, not native constraints.

## Design Tokens

Reuse Rules semantic tokens: canvas `#F7F8FD`, ink `#172344`, secondary `#64708D`, border `#E7EAF4`, white surfaces. Confirm uses gray `#E7EAF0` and slate text `#5E687C`, hover `#D8DEE8`. Cancel/disclosure use established blue. Selected duration uses gray with a visible border and selection semantics. Error uses `#A1465B` / `#FCECF0`. Reuse Simulation lavender. No global token changes or shared token file are introduced. Light appearance only.

## Components

- Duration selection: 15 min, 30 min, 1 hour, Custom. Defaults to 15 minutes; no long-duration shortcuts.
- Custom duration wheels: separate Hours (0–24) and Minutes (0–59), default 0 hours 15 minutes. Valid range 15 minutes–24 hours; at 24 hours only 0 minutes is valid. Invalid combinations show guidance and disable confirmation.
- Timing surface: exact localized pause expiry with date when needed, followed by schedule consequence.
- Compact effect summary: app counts released now and remaining covered by others. Omit zero-result lines; say all remain covered when appropriate. No website release count across wildcard patterns.
- Disclosure: View affected targets / Hide affected targets. Collapsed initially. Apps list every current responsible rule excluding the paused rule; websites show concrete-address outcomes and matching scopes.
- Gray confirmation, separate Cancel, persistence error retaining the draft.

## Interactions

- Open from the approved Rule detail Pause action, only for enabled unpaused rules; opening does not modify the rule.
- Selecting a duration updates expiry and schedule information. Custom drafts persist when switching presets. Invalid custom combinations disables confirmation and shows inline guidance.
- Duration is elapsed time from confirmation, matching AppModel's 15–1,440 minute pause behavior. Compute preview using current time and refresh before saving. Re-evaluate reasons on time boundaries/foreground; never commit an expiry based on stale sheet-opening time.
- Confirmation persists through AppModel. On success dismiss and refresh Rule detail; on failure stay open, keep duration/disclosure state, announce error, and allow retry. Cancel/swipe dismisses without changes. No unsaved-change alert is needed for this uncommitted selection.
- Disclosure does not change the duration or pause; collapse retains the choice and returns focus to its header as appropriate.
- Summary explains immediate effects. Other enabled, unpaused rules can begin/end later; no claim of continuous release is made.
- Website effects are evaluated for concrete hosts. Do not infer that an entire subdomain pattern is released from a base-host check. The mockup includes base/www/m examples only; native host checks must expose all matching rules for the address entered. This sheet's minimal disclosure does not redesign the separate Check website screen.
- If the rule is disabled, deleted, or paused elsewhere while open, show an explanatory unavailable message and prevent confirmation; return to detail. Do not silently replace an existing pause.

## UI States

- Mixed overlap: one app would no longer be restricted, one remains covered by Lunch; website effects vary by address.
- No overlap: two apps would no longer be restricted; no website caveat for an apps-only rule.
- All apps overlapping: two apps remain covered; list all responsible rule names in expanded detail.
- Upcoming: Nothing changes now. If expiry precedes or equals next start, show unchanged scheduled start. If expiry falls inside the window, show delayed start at expiry; if it follows the window, show the next applicable start.
- Websites only: website-address caveat with expandable address examples; no empty app counts.
- Expiry outside schedule: show next applicable scheduled start; never say restrictions resume just because the pause expires. Expiry during a scheduled window: conditional simulated resumption then.
- Invalid duration: keep input and focus, show inline error and disabled confirmation; 15 and 1,440 are valid boundaries.
- Persistence error: retain selection, no success/dismissal, visible actionable error.
- Success: native dismissal to paused Rule detail; prototype gives an explicitly labeled success toast.
- Empty/unavailable: stale deleted/disabled rule or invalid targetless data cannot be paused; explain and offer Cancel. Existing saved rules require targets.
- Loading: use existing local loading; confirmation unavailable while consequence data is unavailable. No extra loading layout introduced.

## Accessibility

Text labels describe controls and consequences; selected presets announce selection. Custom wheels have Hours and Minutes labels, range guidance, and associated invalid state. Announce errors and timing changes without repeated disruptive focus movement. Disclosure exposes expanded state; collapsed content is absent from reading/focus order.

Allow all text and target/rule names to wrap with Dynamic Type; avoid truncated overlap explanations. Minimum touch area 44 × 44 pt. Native focus follows Cancel, title/context, duration, timing, effects/disclosure, error if present, confirmation. Keep footer and custom wheels accessible with keyboard and actual safe areas. Color reinforces meaning only. Respect reduced motion.

## Native Implementation Notes

Adapt existing PauseRuleView rather than adding dependencies or changing local storage. Keep rule evaluation and overlap calculations in Shared/Rules with explicit date/calendar. Apply all enabled, unpaused rules and preserve schedule start-day, overnight, boundary, pause-expiry, and domain matching semantics. A target remains restricted while any other applicable rule covers it.

App counts cover selected identities, not categories or installed-app guesses. Phase 0 uses sample identities and conditional copy, with persistent Simulation notice. Phase 1 live-token labels and system timing reliability require separate adaptations; do not promise second-accurate device resumption. Safari/Private Browsing are not blocked in this prototype.

Use native sheet, NavigationStack, DisclosureGroup and suitable grouped content; provide confirmation via a safeAreaInset footer or equivalent. The HTML details element is a disclosure reference, not a WebView requirement. Fixed review fixtures never enter product time state.

## Acceptance Criteria

- Full-height pause sheet uses the documented order, no tabs, Cancel and gray Confirm pause.
- Default 15 minutes; only 15 min, 30 min, 1 hour, Custom presets; inclusive 15–1,440 custom range with inline error/disabled confirmation.
- Pause-end time and next schedule consequence update correctly, including next-day expiry and active/inactive expiry boundaries.
- Compact immediate app effect counts remain visible; complete target details are initially collapsed and expandable.
- Website summary does not promise an entire subdomain pattern is released; named addresses have complete applicable-rule explanations.
- Upcoming rule makes clear nothing changes now and whether its next scheduled start is affected.
- No pause is saved on open, duration selection, disclosure, or Cancel. Success persists and dismisses; failure preserves selection and the rule.
- Larger text/keyboard retain reachable controls and complete explanatory copy.
- Simulation and sample identity limitations are explicit; no real enforcement claim.

## Known Limitations and Open Questions

No unresolved layout decision. Example website results are fixed illustrative address checks, not a live matching engine. Native complete rule maps and host-check navigation remain implementation work. Success/Cancel are prototype feedback only. Dark appearance, native keyboard, VoiceOver and Dynamic Type require native validation. This design does not revise the approved Rule detail reference.

## Validation

Validated in installed Chrome via Playwright on 2026-10-12:

- All seven fixtures at 1280, 390, and 320 px; no page/content horizontal overflow; confirmation footer remained reachable.
- Disclosure initially collapsed and expanded on request; selected duration state retained after storage failure.
- Custom values 14, 15, 1,440, 1,441, blank, and fractional input; inclusive limits and disabled-invalid behavior confirmed.
- 24-hour expiry showed tomorrow and scheduled resumption within the next day's active window. Upcoming scenarios covered expiry before, inside, and after the next window.
- Enlarged body text at 320 px remained scrollable without horizontal overflow and retained the confirmation footer. This is a browser stress check, not native Dynamic Type verification.
- Default, expanded, and enlarged-text screenshots visually inspected. Screenshots remain in `/tmp`, outside the repository.
- No JavaScript page errors during the checks.

No native build, keyboard/device, VoiceOver, or dark-appearance verification was performed.

## Next Step

The iOS agent may implement this approved Pause review reference natively, validate it against the mockup, and report deviations. No native code was changed by this UX task.

## Review revisions

Custom now uses separate hours/minutes scrollers (native iOS duration wheels in SwiftUI) rather than typed minutes. The HTML uses scrollable select lists to demonstrate selection and keyboard access; it is not an exact rendering of the native wheel. Website details use concise address/result rows: “youtube.com + www — Would be unrestricted” and “m.youtube.com — Still restricted · Mobile Break until 2 PM,” followed by “Other addresses may differ.” These rows remain conditional on the Phase 0 Simulation notice; show every responsible rule if more than one applies.

Use two native SwiftUI wheel Pickers (hours 0–24 and minutes 0–59), or an equivalent control that supports the complete 24-hour endpoint. Validate the combined duration; do not assume a stock countdown picker supports exactly 24 hours. Initial wheel values are 0:15; preserve them when switching presets.
