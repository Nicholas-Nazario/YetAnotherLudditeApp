# Feature: Why Blocked

## Status

APPROVED

The user authorized mockup implementation on 2026-10-12 and approved the reviewed design on 2026-10-17: “the mock looks good”. Approval covers the app and website explanations, complete responsible-rule list, direct Pause actions, and Check another address disclosure. Native implementation uses the existing approved full Pause review, as documented below.

## Reference Files

- `mockups/why-blocked/index.html`
- `mockups/why-blocked/styles.css`
- `mockups/why-blocked/app.js`
- `mockups/why-blocked/README.md`
- `mockups/rules/styles.css` — reused tokens and review shell
- `mockups/handoffs/pause-review.md` — approved native pause design
- `mockups/handoffs/rule-detail.md` — detail destination
- Read-only native context: `App/RootView.swift`, `App/TodayView.swift`, `Shared/Rules/DomainPattern.swift`

## Overview

Explain all rules currently responsible for a selected sample app or concrete website host. Show individual timing and matching scope. Offer a direct Pause… action that retains the existing overlap-aware confirmation. Website inspection is behind Check another address.

## Screen Structure

1. Native back navigation and inline Why blocked title.
2. Target badge, type label, and full wrapping target name/checked host.
3. Persistent Simulation notice: No apps or websites are actually blocked.
4. Sample-identity explanation or website/www equivalence explanation.
5. Website-only Check another address disclosure and optional form.
6. Current simulated result, count, and overlap explanation.
7. Complete Responsible rules list, with detail and pause actions.
8. Immediate-state timing caveat.

## Layout

Use approximately 20 pt horizontal content insets, 18 pt between identity/notice and content sections, 23 pt between result and reasons, and 12 pt between cards. Target badge 46 pt; target name about 25 pt bold at standard size. Result radius 18 pt and padding 17 pt; rule radius 15 pt and content padding 15 pt. Section titles about 15 pt semibold, rule names 16 pt semibold, body 13 pt, helper 12 pt. These are default-size references; use Dynamic Type styles natively.

All screen content below the navigation bar scrolls naturally. Respect top/bottom safe areas and the keyboard. No fixed action footer or new tab controls are specified. Preserve the existing navigation/tab container behavior. Card names, hosts, schedule copy, and reasons wrap without line limits. Enlarge and stack the footer controls when necessary. Use real safe areas rather than translating the HTML bezel/status bar/home indicator. Review-only desktop/mobile shell breakpoints are not native layout constraints.

## Design Tokens

Reuse the Rules tokens: canvas #F7F8FD, ink #172344, secondary #64708D, borders #E7EAF4, white surfaces, blue #355FD7 / deep blue #273F9B controls. Active result uses #EAF7EF with #236653 supporting text; inactive result uses #E7EAF0 / #5E687C. Error #FCECF0 / #A1465B. Simulation uses the existing lavender notice. No established token values change. `design-tokens.json` does not currently exist; the existing Rules CSS and mockups README remain the token references. Light appearance only.

## Components

- **Target heading:** Sample letter badge or native globe symbol, type label, accessible full name. Sample badge is a demo identity.
- **Result:** Active count and overlap explanation; neutral empty result; never imply actual Phase 0 enforcement.
- **Reason card:** Main detail link with name, schedule, current window end, and matching pattern. Separate footer with Applies now and Pause…; do not nest a button inside a navigation link.
- **Address disclosure:** Expandable form with explicit label, Check host, helper copy, and inline validation.
- **Data error:** Unknown-state description and Try again action.

## Interactions

- Today app target opens app explanation; website target opens a prechecked concrete base host. The host heading identifies the current query.
- Main reason link opens Rule detail for that exact rule. Returning refreshes reasons.
- Pause… opens the approved Pause review for that exact rule. Cancel makes no change; successful confirmation returns to recomputed reasons. No pause-all action.
- After the last responsible rule disappears, transition to No active restriction without dismissing the screen.
- Website disclosure opens in place; collapse retains input. Check host or keyboard submit performs local validation/evaluation. Editing alone leaves the current checked-host result intact. On invalid input, retain the previous result, identify its host in the error, and focus the invalid field. On success update the target heading, rules, and result; leave disclosure open.
- Reload on foreground entry and schedule/pause boundaries. Use a common evaluation date/calendar for all reasons and timings. Do not add product preview-time controls.
- Retry reloads local rules; unresolved failure remains an error.

## UI States

- **Default overlap:** Sample App A, Work Hours until 5:00 PM and Lunch until 1:00 PM. Both listed, neither hidden in a count-only summary.
- **Single rule:** One responsible card and its end time; pause still opens review.
- **Website:** m.youtube.com matches a parent including-subdomains rule plus an exact stored host/www-equivalent rule. Display both match explanations.
- **Empty:** No active rule restricts this target now. Paused, disabled, and out-of-schedule rules are excluded. No fabricated upcoming transition.
- **Many/long names:** Entire list is scrollable; full names wrap.
- **Live boundary:** Lunch disappears at its window end while Work Hours remains.
- **Invalid input:** Inline error; no result asserted for the invalid address. Explicitly identify the previous checked host whose result remains visible.
- **Loading:** Retain target identity and Simulation; labeled progress indicator; withhold stale results and actions. Not rendered as a timed fixture.
- **Local error:** Current state unknown; hide result/reasons and show Retry. Do not show zero responsible rules as a successful evaluation.
- **Pause saving/error:** Existing approved Pause review owns validation, disabled confirmation, save failure, and retained selection. Successful return updates this screen.

## Accessibility

Use native Dynamic Type fonts, minimum 44 × 44 pt controls, visible labels, and text alongside semantic color. Wrap content and avoid fixed card heights. Announce meaningful checked-host/result changes and validation errors. Give Pause… a rule-specific accessible label. Read the reason link as rule name, schedule, current window end, and matching explanation; decorative chevrons/badges are hidden. Preserve modal focus on cancellation; when a paused card disappears, move focus to the updated result. Keyboard return checks the address. Scroll focused input/errors above the keyboard. Verify semantic colors against native rendering and larger text. HTML enlarged text is a review aid only.

## Native Implementation Notes

Reuse existing WhyBlockedAppView/WebsiteLookupView navigation, model querying, SimulationBanner, RuleDetailView, and PauseRuleView. Do not copy fixture logic into the rule engine. Each responsible rule appears once even when multiple patterns in that rule match. Disabled/paused/out-of-window rules are absent. Window-end copy must handle overnight end dates and localized time; use “tomorrow” or a full date as necessary, not always “today.” Window end describes that rule's current contribution; later rules may continue restrictions.

Current DomainPattern parsing removes www and exact matching includes the stored host's www equivalent. Preserve that behavior; do not claim strict exact-host behavior or change normalization as part of this screen. The general screen guide differs on this point; resolving that product behavior is separate work requiring review. No entered host is fetched and no website/history data is persisted by the lookup. No accounts, analytics, network calls, or enforcement extensions are introduced.

The prototype pause dialog demonstrates selection, overlap review, and return updates. Its reduced duration selector is not the native specification. Native must use the existing approved full Pause review, including Custom and the full 15-minute–24-hour range. Detail destinations use review-only messages because the existing detail prototype has fixed fixtures.

## Acceptance Criteria

- Both target variants are reachable through existing Today navigation.
- Simulation remains prominent in all result, empty, loading, and error states.
- Every currently responsible rule is shown once; no inactive rule appears.
- Cards show rule-specific localized schedule/end timing and matching explanation where applicable.
- Pausing one rule leaves all other responsible rules visible; pausing the last shows the empty result.
- Schedule and pause boundaries refresh an open screen without a user time override.
- Website results correspond to the explicitly displayed checked host, never unsubmitted edits.
- Host/www equivalence and subdomain dot-boundary behavior match the existing native model.
- Invalid input retains its draft and identifies any previous result; data failure is unknown state rather than unrestricted.
- Large text, long names, many rules, and keyboard do not hide content or actions.
- Native implementation uses the approved full Pause review rather than the prototype flow dialog.

## Open Questions and Known Limitations

No remaining layout decisions from discovery. User design approval is recorded above; subsequent design changes require renewed approval.

The prototype is fixed illustrative data, with a review-only schedule boundary and local simulated pauses. It does not persist changes, implement future evaluation/pause expiry, or load actual app data. Detail navigation is represented by a destination message. Dark appearance, device enforcement, native Dynamic Type, and VoiceOver are not verified by this mockup.

## Validation

Chrome through Playwright passed all six fixtures at 1280, 390, and 320 px with standard and enlarged browser text, without page or content horizontal overflow. Confirmed selected-rule pause consequences and updated duration timing, removal of only the confirmed rule, empty result after the last pause, Lunch boundary update, host/www normalization, exact/subdomain fixture matching, invalid input retaining the previous checked-host result, and retry recovery. No JavaScript page errors were observed.

Escape cancellation preserved both rules and restored focus to the initiating Pause button. The last long-name rule's action remained reachable at 320 px with enlarged text. Visually inspected default, expanded website inspection, narrow website rule cards, larger-text/long-name cards, and error screenshots. Temporary captures and check scripts are in `/tmp/why-blocked-review/`, outside the repository. `git diff --check` passed. No native builds/tests, native Dynamic Type, VoiceOver, dark appearance, or device enforcement checks were performed.

## Next Step

The iOS agent implements the approved design natively, runs relevant builds/tests, and validates against this reference. Native implementation has not started as part of this UX work.
