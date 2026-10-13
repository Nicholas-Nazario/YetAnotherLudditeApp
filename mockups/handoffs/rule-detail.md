# Feature: Rule Detail

## Status

APPROVED

Explicitly approved by the user on 2026-10-12 (“approve it”). Approval covers the completed Rule detail reference, including “Check website,” neutral gray “Pause rule,” and blue “Resume now.” Pause confirmation and target explanation screens remain separate design work.

## Reference Files

- `mockups/rule-detail/index.html`
- `mockups/rule-detail/styles.css`
- `mockups/rule-detail/app.js`
- `mockups/rule-detail/README.md`
- `mockups/rules/styles.css` — imported visual system and token source
- `mockups/handoffs/rule-editor.md` — target matching labels and semantics
- Read-only native context: `YetAnotherLudditeApp/App/RulesView.swift`, including `RuleDetailView`

## Overview

Explain one rule's schedule, selected targets, current effect, and next relevant transition. Keep temporary Pause visually neutral in gray and Resume now blue, keep indefinite Enabled separate, and provide direct Edit and Delete controls. Phase 0 remains a simulation.

## Screen Structure

1. Native back navigation to Rules and trailing Edit action.
2. Full wrapping rule name.
3. Simulation notice: “No apps or websites are actually blocked.”
4. Compact grouped status surface: text state, explanation, next relevant time, and Pause/Resume when enabled.
5. Schedule group with day pattern and time range.
6. Apps group with count and explanation links; Phase 0 sample identity note.
7. Websites group with count, host, scope, and website-check links; overlap note below.
8. Rule controls group with Enabled switch and indefinite-disable helper.
9. Separate destructive Delete rule row.

## Layout

- Native navigation controls remain available while content scrolls. Use native safe areas and existing tab navigation.
- Default content inset 20 pt; major section gap 21 pt; section label gap 8 pt.
- Group radius 15 pt; status padding 17 pt; schedule padding 15 pt; target row padding 12 pt vertical / 14 pt horizontal.
- Rule name about 30 pt bold at default size; body 14–15 pt; helper 12–13 pt. Use Dynamic Type styles instead of fixed point limits.
- Target rows at least 60 pt high; Pause/Resume at least 44 pt; Delete at least 48 pt. All native interactive hit areas at least 44 × 44 pt.
- Long names/hosts wrap and surfaces grow. Status and schedule text remain complete. Use vertical scrolling without horizontal clipping.
- External review panel stacks above the phone at 850 px and below; phone frame disappears at 460 px and below. These are web review breakpoints, not native device rules.

## Design Tokens

Reuse `mockups/rules/styles.css :root` without modifications:

- Canvas `#F7F8FD`, ink `#172344`, muted `#64708D`, surface white, border `#E7EAF4`.
- Resume now uses action blue `#355FD7`, hover deep blue `#273F9B`. Pause rule uses gray `#E7EAF0` with slate text `#5E687C`, hover `#D8DEE8`; retain its position and 44 pt hit area without primary-action emphasis.
- Active text `#236653` on `#EAF7EF`; paused `#97560C` on `#FFF0D3`; inactive `#5E687C` on `#E7EAF0`.
- Existing Simulation lavender treatment.
- Error/destructive treatment `#A1465B` and error wash `#FCECF0`, matching the editor/Today references.

No shared `design-tokens.json` exists; no global token changes are introduced. Light appearance is specified.

## Components

- Compact status card; state badge communicates meaning through words and color.
- Schedule surface with full day/time range. Common day patterns match Rules. Overnight boundaries say next day; helper explains selected start days.
- App row: placeholder sample badge, complete name, current-restrictions subtitle, navigation chevron. Native live tokens later require a separate Phase 1 adaptation.
- Website row: complete normalized host, visible matching scope, Check website subtitle, chevron.
- Enabled switch: independent of pause and schedule; helper explains indefinite disabling.
- Destructive row and native confirmation dialog.
- Inline failure message / existing error presentation must preserve the rule; review toast is only prototype feedback.

## Interactions

- Back returns to Rules. Edit opens the existing saved-rule editor; successful edit refreshes detail.
- Pause opens an overlap-aware duration confirmation. It never immediately pauses without confirmation. The sheet is a separate design surface; its prototype destination is a toast.
- Pause remains available for Upcoming. Its confirmation explains whether the pause covers the next scheduled start. Hide Pause/Resume when disabled.
- Resume now clears the pause only. Recompute status from the current schedule; outside the window it becomes Upcoming.
- Enabled off disables indefinitely without changing schedule, targets, or an existing pause. Enabled on respects any unexpired retained pause. Explain that retained pause in the Disabled status surface.
- Apps navigate to complete current restriction reasons across every applicable rule; an inactive target shows an honest no-current-restriction state there.
- Website rows open the website checker prefilled with their host. A base-host check cannot establish identical overlap for all subdomains.
- Delete confirmation explains removal and other-rule overlap; cancel leaves everything unchanged. Successful deletion returns to Rules; failed deletion stays on detail.
- Every mutation persists through AppModel and refreshes status only on success. No optimistic success after failed storage.
- Review state changes are local fixtures. There is no product time override.

## UI States

- Active: simulated restriction count and scheduled end.
- Upcoming: outside scheduled hours and next scheduled start.
- Paused during an active window: exact localized expiry; say restrictions resume then only if schedule is active at expiry.
- Paused outside the schedule or expiring outside it: show pause expiry plus next applicable start. Do not imply pause expiry starts restriction unconditionally.
- Disabled: no effect until enabled. If an unexpired pause is retained, explicitly say enabling before expiry keeps it paused.
- Overnight: explicit next-day end and schedule start-day explanation.
- Empty subgroup: “No apps in this rule” / “No websites in this rule.” A valid stored rule has at least one target overall.
- Long content: full wrapping name and host; all actions remain reachable.
- Storage error: retain saved values; explain failure and allow retry. The error fixture simulates failure on every mutation.
- Deleted/unavailable rule: explain that it was deleted and offer return to Rules. Normal successful local deletion navigates back immediately.
- Loading: use existing local-loading behavior; never show invented successful current data while loading. No new loading surface is proposed.
- Selected: review scenario uses aria-pressed; native Enabled reflects stored state.

## Accessibility

- Use Dynamic Type; support wrapping names, schedules, hosts, and complete state explanations.
- Give targets labels including their names and action; website labels include scope. Enabled has a visible label and explanatory accessibility description.
- Use native switch semantics; minimum interactive areas 44 × 44 pt. Decorative badges and chevrons are excluded from announcements.
- Reading order follows screen structure. Text identifies every state; do not rely on color alone.
- Dialog traps focus, Escape/cancel leaves data intact, and dismissal returns focus to Delete. Native confirmationDialog supplies system behavior.
- Expose mutation errors accessibly and retain focus on the changed control when it remains available. Respect reduced motion.

## Native Implementation Notes

Use the existing RuleDetailView, AppModel mutation methods, NavigationStack, editor sheet, pause sheet, and reason/host destinations. Keep the architecture and local-only persistence. No dependency is needed beyond Apple's frameworks.

Use the current date and local calendar consistently for status, pause expiry, and schedule transitions. Pass date/calendar into calculations; refresh on foreground entry and schedule/pause boundaries. Disabled takes precedence over pause, then active schedule. Share presentation calculations where appropriate with Rules rather than inventing a second evaluator.

The agreed This website label follows the Rule editor's proposed base-plus-www behavior; verify that its matcher update is approved and implemented before using the label in native UI. All subdomains includes base and suffix-bounded subdomains. Preserve overnight start-day semantics and all applicable overlap reasons.

No app, Safari, or Private Browsing enforcement is implied by this Phase 0 design. Later permission/enforcement errors and live-token labels require a Phase 1 handoff. The phone frame, fixed fixtures, symbols used for tabs, and review controls are not native implementation requirements.

## Acceptance Criteria

- Screen follows the documented hierarchy with Edit in the toolbar and a full wrapping name.
- Simulation notice is present; sample apps are clearly labeled as examples.
- State priority is Disabled → Paused → Active/Upcoming and uses current time.
- Active shows its scheduled end; Upcoming shows its next start; Paused distinguishes expiry from the next scheduled application.
- Pause uses a neutral gray button; Resume now uses blue. Both remain separate from Enabled; Pause opens confirmation and does not mutate immediately.
- Enabling a disabled rule with an unexpired pause remains Paused, with explanatory copy visible before enabling.
- Target groups show names and matching scope; website actions and accessibility labels use “Check website.” Empty subgroups are honest. Explanations consider all responsible rules.
- Overnight schedules specify next day and start-day semantics.
- Delete requires confirmation, navigates after success, and preserves detail on failure. Other rules' effects are never promised to end.
- Failed changes preserve saved state and provide actionable feedback.
- All content and controls remain readable and reachable at larger text sizes with safe-area-aware scrolling.

## Known Limitations and Open Questions

No unresolved decision for this detail layout. Pause confirmation and target explanation screens remain separate design work; their destination placeholders do not validate those flows. Fixed fixtures do not prove native scheduling, persistence, or device enforcement. Light appearance only; native dark appearance and Dynamic Type require validation during implementation.

## Validation

Validated in headless installed Chrome via Playwright on 2026-10-12:

- All seven scenarios at 1280, 390, and 320 px viewport widths; no page/content horizontal overflow and Delete reachable by scrolling.
- Enable/Disable, retained-pause re-enable, Resume now, error preservation, Delete confirmation/cancel, focus return, deletion success, scenario reset, and direct overnight query link.
- Enlarged body/title text stress check remained scrollable without horizontal clipping. This is not native Dynamic Type verification.
- No JavaScript page errors during these checks.
- After the requested button revision, browser computed-style checks confirmed gray Pause (`#E7EAF0`) and blue Resume (`#355FD7`); Pause still leads to the confirmation destination without applying a pause.
- Desktop Active and mobile Disabled screenshots visually inspected. Temporary screenshots remain outside the repository.

No native build, device enforcement, VoiceOver, or dark-appearance validation was performed.

## Next Step

The iOS agent may implement this approved Rule detail reference natively, then validate it against the mockup and report deviations. This approval does not include designs for the separate pause confirmation or target explanation screens. This UX task did not implement native code.
