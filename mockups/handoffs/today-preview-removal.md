# Feature: Today Preview Removal

## Status

APPROVED

## Reference Files

- `mockups/today/index.html`
- `mockups/today/styles.css`
- `mockups/today/app.js`
- `mockups/today/README.md`
- Token reference: `mockups/today/styles.css :root` (no shared `design-tokens.json` exists; no token changes).
- Read-only context: `plan/phase-1-plan.md` and `YetAnotherLudditeApp/App/TodayView.swift`.

## Overview

Today always describes what applies at current device time. Users choose apps and set schedules. Remove the product time override while preserving the Phase 0 simulation notice, status hierarchy, target list, overlapping-rule explanations, and next-change information. Future-time scenarios belong in automated tests and developer tools. Phase 1 authorization and live-enforcement UI require separate designs.

## Screen Structure

1. Date, Today title, and Add rule action.
2. Simulation notice: “No apps or websites are actually blocked.”
3. Your boundaries summary and textual status.
4. Next expected change and its effect.
5. “Restricted now” heading with target count.
6. Existing target cards, or the applicable empty state.
7. Existing navigation; no navigation redesign is included.

No Preview time card, expanded date/time picker, Change/Done actions, or Reset action remains. Do not add a replacement time control.

## Layout

- Preserve existing 20 px horizontal content inset and 28 px bottom content padding.
- Header-to-notice spacing remains 21 px; notice-to-summary spacing remains 16 px.
- Summary-to-next-change gap remains 15 px. Next change connects directly to the target section with a 25 px gap.
- Preserve 12 px heading-to-list spacing and 10 px between target cards.
- Preserve summary padding (21 px), next-card padding (16 px), target-card padding (14 px vertically, 12 px horizontally), and existing radii.
- At viewport widths up to 850 px, the external review panel stacks above the phone. At 460 px and below, the phone canvas fills the viewport width; content scrolls independently above navigation.
- Native layout uses actual safe areas for status bar, Dynamic Island, tabs, and home indicator. The bezel and fixed review height are not native dimensions.
- Content height grows with text. At accessibility sizes, wrap text and place target actions below reasons when a horizontal arrangement cannot fit. Avoid horizontal scrolling or clipping.

## Design Tokens

Reuse `styles.css :root`: canvas `#F7F8FD`, ink `#172344`, muted `#64708D`, action blue `#355FD7`, active `#347E68` / `#EAF7EF`, paused `#97560C` / `#FFF0D3`, inactive `#5E687C` / `#E7EAF0`, line `#E7EAF4`, and white card surfaces. Preserve existing gradients and lavender Simulation treatment. Large and medium radii remain 24 px and 18 px. No token values are changed.

Use system fonts and native Dynamic Type equivalents for the existing hierarchy: 34 px Today title, 27 px summary, 18 px target heading, and existing supporting styles. These default reference sizes do not limit accessibility scaling.

## Components

Reuse the header, Simulation notice, summary, next-change card, heading/count, target cards, empty card, and native navigation destinations. Remove the preview component completely, including its JavaScript bindings and CSS. “Restricted now” describes simulated current schedule results in Phase 0; the persistent notice qualifies those results.

## Navigation and Interactions

- Add rule opens the existing editor; no-rules Create rule opens the same destination.
- Preserve Why blocked and Check host target actions and their existing destinations.
- Today status, targets, overlap explanations, and next change use one current-device-time evaluation and the local calendar. Refresh on foreground entry and at schedule/pause boundaries; avoid stale reasons or next-change labels.
- A target remains restricted in the simulated result while any applicable enabled, unpaused rule includes it. Ending or pausing one overlapping rule does not release a target covered by another.
- Keep explicit date/calendar inputs in calculations for deterministic automated tests. No user-selectable evaluation time appears in product state or Today.
- External scenario buttons and URL query links remain developer review aids with fixed illustrative dates. Their fixture time is not a native product control. Review buttons retain selected styling and `aria-pressed`; selecting one resets the review scroll position.
- Prototype destination toasts remain illustrative only.

## UI States

- **Default / active overlap:** At the fixed Monday 12:20 PM review fixture, two targets would be restricted. Sample App A shows Work Hours + Lunch; youtube.com shows Work Hours with subdomains. At 1 PM Lunch ends, but Work Hours still covers Sample App A.
- **Nothing active:** Inactive summary, zero count, and “Nothing active at this time.” Supporting copy says the next scheduled change is shown above. Keep that next-change card visible.
- **No rules:** “A fresh start,” zero count, “No rules yet,” and Create rule. The schedule card says “No changes scheduled”; do not invent a transition.
- **Paused:** Work Hours is paused until 12:35 PM; Lunch still covers Sample App A. Next change explains resumption and its combined effect.
- **Selected:** External review buttons show the selected fixture; no product time selection exists.
- **Loading, storage error, disabled actions:** No new states or behavior are introduced by preview removal. Retain existing app-level handling; do not display stale data as a successful current evaluation. Disabled and paused rules do not contribute effective reasons.
- **Enforcement error fixture:** Preserve the existing external “Unable to enforce” example solely as an illustrative later-phase review aid. Its permission/extension copy is not an approved Phase 1 implementation specification. The Phase 0 Simulation notice stays visible in every fixture.

## Accessibility

- Preserve readable text labels for status; color alone must not carry meaning.
- Label the plus action “Add rule.” Target action labels include their target names. Expose target type, website scope, responsible rule names/count, and simulation context to VoiceOver.
- Reading order follows header, Simulation, summary, next change, target heading/count, and target cards or empty state. Removed controls must leave no focus stops or accessibility labels.
- Native interactive targets are at least 44 × 44 pt, including text actions. The existing web reference does not demonstrate all native hit areas.
- Use Dynamic Type, wrapping and flexible card height; preserve complete overlap explanations. Stack actions as needed at accessibility sizes.
- Preserve keyboard focus indication for review controls and reduced-motion behavior. Decorative icons should not create redundant announcements.
- Maintain readable contrast in the existing palette; validate native light/dark and accessibility rendering during implementation. This reference defines light appearance only.

## Native Implementation Notes

`TodayView.swift` still contains preview state, binding, simulator-only card, picker and preview accessibility copy; these were read, not modified. After layout approval, the iOS agent removes those controls and uses current device time for presentation. Coordinate removal of model time overrides in the native scope so Simulator also uses current device time. Pass date/calendar into rule calculations rather than reading global time inside them.

Preserve sample identities and the accurate Phase 0 banner. Do not imply Safari or Private Browsing is blocked. Preserve documented schedule boundaries, overnight start-day semantics, pause expiry, host normalization, and exact-host/subdomain matching. No accounts, tracking, network transmission or storage changes are specified.

Use native navigation and safe areas. The external panel, fixed dates, phone frame, fake status bar, toasts and review tab styling are not implementation requirements. Existing approved Rules/editor designs remain separate; any stale references to Today preview behavior are superseded by this focused decision, without changing their approved layouts.

## Acceptance Criteria

- No product Preview time, date/time picker, Change/Done, Reset, or copy inviting another-time viewing remains, including Simulator builds.
- Today status, overlap explanations and next change all use current device time and local calendar, with no product override.
- Header → Simulation → summary → next change → targets hierarchy remains; next change and targets have a 25 pt default reference gap.
- Default overlap retains both responsible rule names and correctly explains continued restriction after Lunch ends.
- Nothing-active and no-rules states retain their distinct copy, zero count, and appropriate next-change/schedule information.
- All five external review scenarios and direct query links remain usable and clearly labeled as developer aids.
- Phase 0 notice remains accurate and visible; no real app, Safari or Private Browsing blocking is claimed.
- Responsive layout scrolls without clipping; native larger text wraps, preserves complete explanations and has accessible touch targets.
- Removed controls have no residual event handlers, CSS or accessibility focus stops.
- Native implementation starts only after explicit approval of this revised layout.

## Known Limitations and Open Questions

The HTML uses fixed developer fixtures and a small illustrative evaluator; it does not follow the device clock or prove enforcement. Destinations remain toast placeholders. No browser visual verification or native build was performed for this revision. Light appearance is the only reference; no new loading/error or Phase 1 authorization design is included.

No unresolved product decision remains for preview removal. The revised spacing and wording await explicit user design approval.
