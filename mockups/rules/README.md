# Rules screen · UI/UX implementation reference

Open [index.html](index.html) directly in a browser. The prototype has no build step, packages, fonts, or network dependencies. Review scenario controls and the device frame are outside the app; only the phone screen interior is the UI reference.

For a direct state link, append `?scenario=no-rules` or `?scenario=paused-disabled`. The default shows all rule states.

## Design intent

Rules is for finding and managing one rule. Today is responsible for showing the combined effect of rules and supports previewing a different time. Rule status in this list follows the current device time and does not follow Today’s preview time.

The list uses native-style sections in this order: **Active**, **Paused**, **Upcoming**, **Disabled**. Empty sections are hidden. Each section shows its rule count, and rows are sorted alphabetically by name within the section. A rule that is disabled while its pause timer remains unexpired belongs in Disabled; if re-enabled before the timer expires, it belongs in Paused.

Each row shows the rule name, a single schedule line, app and website counts, and a chevron. Active rows add **Ends in {time}** for the remaining time in the current scheduled window. Paused rows instead show the pause expiry. Tapping a row opens its details. There are no inline controls. The plus icon in the upper-right is the only create action. The empty state has explanatory copy and no duplicate create button.

## Screen structure and SwiftUI mapping

| HTML component | Intended SwiftUI element | Behavior |
| --- | --- | --- |
| `.app-header` | Navigation title and toolbar item | Rules title and plus action. The plus opens the rule editor. |
| `.simulation-banner` | Existing `SimulationBanner` | Keep the Phase 0 notice visible and clear that nothing is actually blocked. It describes the app’s current product behavior; it is not repeated as a row status. |
| `.rule-section` | `List` section | Render only nonempty sections in the agreed state order. Put the rule count in the section header. |
| `.rule-row` | `NavigationLink` row | Opens `RuleDetailView`. No swipe or inline actions are introduced by this design. |
| `.empty-state` | Empty content view inside the list | “No rules yet” and one explanatory sentence; create remains available in the toolbar. |
| `.tab-bar` | Existing app `TabView` | Today, Rules, and Settings. The fake bar is review-only. |

## Layout and row content

- Keep the screen vertically scrollable. The navigation bar and toolbar action remain available through native navigation behavior.
- Use native grouped list sections and rows rather than independent floating cards.
- Keep the rule name first, then the schedule, then target counts. The status is communicated by the section header; do not repeat Active, Upcoming, or Disabled in every row.
- In an Active row, add **Ends in {time}** after the target counts (for example, **Ends in 2h 40m**). Derive the remaining time from that rule’s current scheduled window and refresh the displayed value at minute granularity. At the schedule boundary, recompute the rule state and move it out of Active.
- In a Paused section, add **Paused until [localized time]** to the row so the expiry is visible without opening details.
- Use singular and plural counts naturally, such as **1 app · 2 websites**.
- Schedule wording uses **Weekdays**, **Weekends**, or **Every day** for common patterns. Custom consecutive days can use a range (for example, **Tue–Sat**); nonconsecutive days are listed (for example, **Mon, Wed, Fri**).
- Show the localized time range on the same line as the day pattern. Overnight schedules use **next day**, and selected days refer to the day the schedule starts: **Weekdays · 10:00 PM–7:00 AM next day**.
- Let text wrap at larger Dynamic Type sizes. Do not truncate names, schedules, counts, or pause expiry.

## Components and tokens

The prototype reuses the Today screen’s semantic colors, system font stack, cool neutral canvas, blue action color, subtle separators, and accessible text hierarchy. Relevant values are defined locally in `styles.css` to match `today/styles.css`; shared `design-tokens.json` does not exist, so no global token file was introduced.

The simulation notice uses the existing lavender treatment. Active counts use muted teal, paused counts and expiry use amber, and upcoming/disabled counts use slate. Each state remains named in text; color is supplementary. Rule rows use a restrained white grouped-list surface with separators rather than elevated cards.

## Interactions

- **Plus:** Opens the rule editor.
- **Rule row:** Opens the corresponding rule detail screen.
- **Scenario controls:** Review-only controls outside the app frame. They switch the static review fixture and can be linked with `?scenario=`.
- **Tabs:** The mock tab bar reflects the app’s current three-tab navigation; only Rules has a screen in this prototype.
- **State changes:** The production app recomputes status from the current device time and the rule’s enabled and pause values. Do not add a time preview control to Rules.

The prototype toast only indicates the destination of the plus and row actions. It does not implement the editor or detail screen.

## UI states

- **Mixed list:** Active, Paused, Upcoming, and Disabled sections with alphabetized rows, representative one/multiple target counts, and example active countdowns.
- **No rules:** Hidden rule sections and a centered “No rules yet” explanation. The plus remains in the toolbar.
- **Paused and disabled:** Shows a pause expiry for the Paused rule. A Disabled fixture retains a pause value but does not surface it, demonstrating that Disabled takes precedence.
- **Empty groups:** Omitted from the rendered list.
- **Loading and persistence errors:** Not separately mocked; the existing app reports local storage errors through its app-level alert.

Fixture statuses and countdown values are static and illustrative. JavaScript groups and alphabetizes those labels for review but does not implement schedule evaluation, countdown progression, pause expiry, or target enforcement logic.

## Accessibility

- Use native `List`, `Section`, and `NavigationLink` semantics in SwiftUI.
- Make each row’s accessible description include the rule name, complete schedule, app/website counts, the active countdown or pause expiry when relevant.
- Keep the plus action labeled **Create rule**; never rely on the plus glyph alone for VoiceOver.
- Support Dynamic Type and allow rows and section headers to grow vertically.
- Preserve visible text labels for every state and sufficient contrast in both text and status accents.

## Native implementation notes

The HTML phone frame, fake status bar, scenario controls, toast, and tab bar styling are review aids. Use the app’s existing SwiftUI navigation and tab components. Rule states should use the app model’s current device time, not `previewDate`. The existing model checks disabled before pause, matching the agreed grouping precedence. Keep all rule mutations in `RuleDetailView`; the list remains a navigation surface.

## Acceptance criteria

- The list shows nonempty state groups in Active, Paused, Upcoming, Disabled order, with a count in each header.
- Rules are alphabetized by name within each group.
- Active and Upcoming status is based on the current device time, independent of Today’s preview time.
- Disabled takes precedence over an unexpired pause; re-enabling before pause expiry returns the rule to Paused.
- Rows show name, human-friendly schedule, and app/website counts; paused rows also show their expiry.
- Active rows show **Ends in {time}** for the current scheduled window; refresh the displayed value at minute granularity and move the rule to Upcoming at its schedule boundary when still enabled.
- Overnight times end with **next day**, and the selected days represent start days.
- Tapping a row opens details; the plus opens the rule editor; no inline controls appear.
- The no-rules state has explanatory copy and no duplicate create button.
- Phase 0 keeps the app-level notice that no apps or websites are actually blocked.

## Open questions

None. The design direction was agreed with the user before prototyping.
