# Feature: Rules List

## Status

APPROVED

Approved by the user on 2026-10-12. This approval applies to the current Rules list prototype, including the per-rule active countdown.

## Reference Files

- `mockups/rules/index.html`
- `mockups/rules/styles.css`
- `mockups/rules/app.js`
- `mockups/rules/README.md`
- `mockups/today/styles.css` (established visual language and token reference)
- `YetAnotherLudditeApp/App/RulesView.swift` (current list and detail navigation)
- `YetAnotherLudditeApp/App/AppModel.swift` (current and preview date state)
- `YetAnotherLudditeApp/Shared/Rules/Rule.swift` (weekly schedule and enabled/pause model)

## Overview

The Rules list helps people find and manage one saved rule. Today remains responsible for explaining the combined effect of rules and previewing another time. Rule list status follows the current device time and is independent of Today’s preview time.

## Screen Structure

1. Native navigation title **Rules** with a top-right plus action.
2. Phase 0 Simulation notice stating that no apps or websites are actually blocked.
3. Scrollable, native-style grouped list with nonempty sections in this order: Active, Paused, Upcoming, Disabled.
4. Each section header includes a rule count. Rules are alphabetized within each section.
5. When there are no rules, show “No rules yet” with a short explanation and no additional create button.
6. Existing three-tab navigation remains Today, Rules, Settings.

## Layout

- Follow a mobile-first iPhone layout with safe areas and normal native navigation behavior.
- Use grouped list sections with full-width tappable rows and separators, not individual floating cards.
- Keep the screen scrollable. Do not truncate rule names, schedules, counts, or pause expiry at larger text sizes.
- Row information order: rule name; human-friendly schedule; app and website counts. Active rows add **Ends in {time}** for the current schedule window; Paused rows add **Paused until [time]**.
- Display the active countdown in compact relative form, for example **Ends in 2h 40m**, and refresh the label at minute granularity. Recompute the state at the scheduled end; an enabled, unpaused rule moves to Upcoming.
- Match the prototype’s default-size rhythm: about 20 pt horizontal screen inset; 17 pt between sections; 8 pt between a section header and its rows; 13–15 pt row insets; and a 44 pt toolbar hit target. These are visual references; native list insets and Dynamic Type may adjust the final dimensions.
- Allow rows to grow naturally for the name, schedule, counts, and contextual state detail (countdown for Active, pause expiry for Paused).
- The section communicates Active, Upcoming, and Disabled states, so those labels are not repeated on each row.
- Common day patterns use **Weekdays**, **Weekends**, or **Every day**. Custom consecutive days may use a range, while nonconsecutive days are listed.
- Display localized start and end times on the schedule line. For overnight schedules use **next day**; selected weekdays describe the start day.

## Design Tokens

Use values already established in `mockups/today/styles.css`: canvas `#F7F8FD`, ink `#172344`, muted text `#64708D`, blue action `#355FD7`, active teal `#347E68` / `#EAF7EF`, paused amber `#97560C` / `#FFF0D3`, inactive slate `#5E687C` / `#E7EAF0`, and separators `#E7EAF4`. The Phase 0 notice uses the established lavender treatment. The prototype mirrors these values locally; no shared token file was needed.

Use the system font with Dynamic Type. At the default size, the screen title is about 34 pt bold, section titles and rule names about 15 pt semibold, and schedule/count/state details about 12 pt. Use a white grouped-list surface against the cool neutral canvas, 15 pt grouped corners, and subtle separators without strong row shadows. These are visual references, not fixed accessibility sizes. The mockup defines the light appearance only.

## Components

- **Navigation title and toolbar plus:** Existing native navigation bar; plus has accessible label **Create rule**.
- **Simulation notice:** Existing `SimulationBanner`, visible at the app level for Phase 0 accuracy.
- **Rule section:** Native `List` section with visible state heading and numeric count; omit empty sections.
- **Rule row:** Native `NavigationLink` to details. Show name, schedule, target counts, and pause expiry only for paused rules.
- **Active countdown:** A secondary line in each Active row showing the remaining time in that rule’s current scheduled window. It does not describe the combined effect of overlapping rules; Today owns that explanation.
- **Empty state:** Heading and concise explanatory sentence; toolbar plus remains the single create action.

## Navigation and Interactions

- Tap the top-right plus to open the existing rule editor.
- Tap a rule row to open its detail screen.
- Keep edit, pause/resume, enable/disable, and delete actions in rule details. Do not add inline controls or list swipe actions.
- Compute Active and Upcoming from the current device time, current schedule, enabled state, and pause state. Do not use Today’s selected preview time.
- The existing `AppModel.currentDate` can reflect Today’s preview date. For Rules status and countdowns, use live device time independently of `previewDate`; preserve the shared preview behavior on Today.
- Compute the next end boundary using the same `Calendar` and time zone as schedule evaluation, including overnight start-day semantics. Update the formatted remaining time at minute granularity and recalculate the section when the current scheduled window ends.
- Disabled state takes precedence over a still-unexpired pause. If re-enabled before that timer expires, the rule becomes Paused.
- The prototype’s review scenario controls and device frame are outside the app and are not to be implemented.

## UI States

- **Default mixed list:** Four groups with alphabetized names and varied target counts.
- **No rules:** No state sections; explanatory empty state; plus remains available.
- **Paused:** Pause expiry appears in the row.
- **Active countdown:** Each Active row shows its own remaining time, such as **Ends in 42m** or **Ends in 2h 40m**.
- **Countdown boundary:** When an active window ends, an enabled and unpaused rule leaves Active and appears in Upcoming until its next scheduled window. A disabled or paused rule remains in its higher-priority state group.
- **Disabled with pause timer retained:** The rule stays in Disabled and does not show the pause expiry.
- **Upcoming:** Visible schedule and target counts under Upcoming.
- **Loading and storage errors:** Existing app-level handling applies; no new error behavior is specified by this mockup.

## Accessibility

- Use native `List`, `Section`, and `NavigationLink` so navigation and grouping are announced naturally.
- Expose the full rule name, localized schedule, target counts, and pause expiry (when present) to VoiceOver.
- Include the current active countdown in the row’s VoiceOver description; refresh it with the visible value without announcing every minute when the row is not focused.
- Keep the countdown as readable text, not color or an icon alone. It should remain available to VoiceOver when the row receives focus.
- Label the plus button **Create rule**.
- Respect Dynamic Type; let rows and headings expand and wrap.
- Use state text and readable contrast; do not depend on color alone.

## Native Implementation Notes

The fake status bar, phone frame, scenario panel, toast, and tab bar styling exist only to support review. Use the project’s native `TabView`, `NavigationStack`, `List`, `Section`, and `NavigationLink`. Keep the existing `SimulationBanner` for Phase 0. The current `RulesView` has a basic row and detail navigation; implement section grouping, counts, target counts, schedule wording, and the active countdown in SwiftUI. Read schedule semantics from `Rule`/`WeeklySchedule`, but pass live device time and the current calendar into status and end-boundary calculations. Do not use `AppModel.previewDate` for this list. The existing model checks disabled before pause, matching the agreed grouping precedence. Keep all rule mutations in `RuleDetailView`; the list remains a navigation surface.

## Acceptance Criteria

- Nonempty groups appear in Active, Paused, Upcoming, Disabled order and carry counts.
- Groups with no rules are hidden.
- Names sort alphabetically within their group.
- Active/Upcoming use current device time, not Today’s preview date.
- Active rows show the remaining time to that rule’s current scheduled end in **Ends in {time}** form; refresh at minute granularity and reclassify the rule at the end boundary.
- Countdown calculation follows the current local calendar and overnight start-day semantics; Today’s preview time does not affect it.
- Disabled overrides a retained pause timer; re-enabling before expiry yields Paused.
- Every row displays the rule name, schedule, and app/site counts; Paused rows include their expiry.
- Overnight schedule copy says **next day** and treats selected days as start days.
- Rows navigate to details and the toolbar plus opens rule creation; no inline actions appear.
- Empty state contains no duplicate Create rule button.
- The Phase 0 notice accurately says no apps or websites are actually blocked.

## Known Limitations and Open Questions

- The prototype uses static illustrative rule fixtures and countdown values. It does not calculate schedule status, advance the countdown, pause expiry, or enforcement.
- Detail and editor destinations are represented by prototype feedback only; their existing app screens provide the actual destinations.
- No unresolved design questions remain. The user approved the current prototype, including the countdown, on 2026-10-12.
