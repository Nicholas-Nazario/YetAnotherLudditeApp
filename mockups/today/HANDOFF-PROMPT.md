# Paste-ready prompt: implement the Today screen in SwiftUI

You are a SwiftUI engineer implementing the **Today** screen of Yet Another Luddite App. Treat the existing HTML prototype as the visual plan for this screen and `plan/ui-screens.md` as its product behavior guide. Your job is to translate the design into a native, accessible iOS interface using the app's real rule state. Preserve the app's privacy-first, adult self-management tone.

## Read these files first

1. `README.md` and `plan/README.md` for the product mission and phase boundaries.
2. `plan/ui-screens.md`, especially **Today**, shared UI states, and copy principles.
3. `mockups/today/index.html` in a browser for the visible design. The phone's inner screen is the UI. Use the review controls to see **Active overlap**, **Nothing active**, **One rule paused**, **Unable to enforce**, and **No rules yet**. Direct links use `?scenario=overlap`, `quiet`, `paused`, `unavailable`, or `no-rules`.
4. `mockups/today/styles.css` for visual tokens, gradients, spacing, and radii; `mockups/today/README.md` for component and state mapping. `mockups/today/app.js` contains illustrative fixtures and interaction wiring. Its sample schedule calculations are not production logic.
5. Existing Swift code: `YetAnotherLudditeApp/App/RootView.swift`, `YetAnotherLudditeApp/App/AppModel.swift`, and `YetAnotherLudditeApp/Shared/Rules/RuleEvaluator.swift`.

## Design vision

Today should feel like a calm control panel for a choice the person made. At a glance, it should answer **what is happening now**, **what changes next**, and **which apps or sites are affected and why**. Use confident hierarchy, generous breathing room, short factual copy, and restrained decoration. Avoid gamification, guilt, activity tracking, or celebratory language. The visual treatment may feel polished, but the status must be more important than ornament.

The screen order is: date and Today title with Add rule → prominent Phase 0 Simulation banner → large status summary → next expected change or action needed → preview-time control → effective target list or empty state. Keep the summary and next change visible high on the screen. Let the target list scroll naturally; do not compress text to force every card above the fold.

## Color system

Use **semantic color assets** in SwiftUI. Blue and purple are product/navigation colors; they do not describe whether a restriction is working. Status colors appear in the summary, supporting panel, count badge, target edge, and status label. The current HTML palette is intentionally soft, with readable dark text on light gradients:

| State | Core color | Summary gradient and text | Supporting surface |
| --- | --- | --- | --- |
| Active restriction | muted teal `#347E68` | `#D8F2E2` → `#B6E6C9` → `#94D5B5`; dark green text `#184D3E` | mint `#EAF7EF` |
| Rule paused | amber `#97560C` | `#FFE4AE` → `#F1BC58`; dark brown text `#4E3617` | warm cream `#FFF0D3` |
| Inactive or no rules | slate `#5E687C` | `#EDF0F5` → `#D8DEE8`; dark slate text `#2F3A4B` | gray `#E7EAF0` |
| Unable to enforce | muted coral `#A1465B` | `#F9DCE1` → `#F2C0CA` → `#E9A3B2`; dark burgundy text `#642A39` | pale rose `#FCECF0` |

Shared neutrals: canvas `#F7F8FD`, primary ink `#172344`, secondary text `#64708D`, white cards, subtle line `#E7EAF4`. Use blue `#355FD7` for Add rule, preview-time actions, links, and the selected Today tab. Purple `#7354CC` is available for neutral brand or rule context but should not compete with the status color. The supplied mock specifies a light appearance. If the app supports Dark Mode, derive semantic dark equivalents that preserve the same state meaning and contrast. Text and icons must carry the meaning even without color.

The paused state has an important nuance: **pausing one rule may leave a target restricted by another**. In that case the overall summary is amber, while the still-effective target keeps its active green badge or edge. The error state is the most urgent, but its soft coral gradient keeps the interface calm; the words “Unable to enforce” and an alert symbol make the failure explicit.

## Typography, shape, and iconography

Use the iOS system San Francisco typeface through SwiftUI's semantic text styles. Do not add a custom font. At the default text size, the mock's hierarchy is approximately 34 pt bold for Today, 27 pt bold for the summary headline, 18 pt semibold for section headings, 14–16 pt semibold for target names, and 12–13 pt for supporting labels. Use Dynamic Type rather than hard-coding those measurements at every size. Keep target reasons, times, and scope readable when text grows.

The app canvas has about 20 pt horizontal padding. The summary uses a roughly 24 pt corner radius; target, next-change, and preview cards use about 18 pt. Controls and icon badges use smaller 11–15 pt radii. Shadows are modest. The top-right element in the summary is a **text status pill**: Active, Paused, Inactive, Alert, or No rules. There is no decorative star or decorative rule-progress marker.

The prototype's line icons are local SVG shapes. Use **SF Symbols** in SwiftUI rather than adding an icon package: `plus` for Add rule, `eye` for Simulation, `calendar` for the next transition, `exclamationmark.triangle` for enforcement failure, `clock` for preview time, `globe` for websites, and `chevron.right` for disclosure. The mock uses lettered badges for **Sample App A/B**; those are examples, not claims about installed apps. Keep real app selection tied to Apple's picker in the later device phase. The fake 9:41 status bar, Dynamic Island, home indicator, device bezel, desktop review controls, and prototype toasts are not app UI. Let iOS render its own system surfaces.

## Content and behavior to preserve

- **Phase 0 Simulation:** Keep the banner near the top: “Simulation — No apps or websites are actually blocked.” Use “would be restricted” in summary copy. An Active pill refers to an active *preview rule*, never real blocking. Do not suggest that Safari or another app is actually blocked in Simulator.
- **Current status:** Derive the effective targets and all responsible rules from the existing `AppModel.snapshot` and `RuleEvaluator`. The prototype's Work Hours, Lunch, and Evening Wind Down examples only demonstrate presentation. Do not copy `todayViewState()` from JavaScript as app business logic.
- **Next change:** Use `RuleSnapshot.nextRuleChange` for the time. The accompanying explanation must accurately describe the effect of the change; if the effect cannot be derived safely, give a neutral time description instead of guessing. When one overlapping rule ends and another continues, explicitly say that the target remains restricted.
- **Preview time:** The actual app defaults to the device's current time. `AppModel.previewDate` already supports choosing another date/time; resetting should set it to `nil` and return to live time. A chosen preview time should be visibly labeled. The mock's fixed October 12 demo time and “Reset to demo time” text are review fixtures only.
- **Targets:** Show effective sample apps and website patterns, their scope, and the responsible rule names or count. An app action opens the existing Why blocked view; a website action opens host inspection for a concrete host. Keep an accessible route to every responsible rule. Do not treat a domain-and-subdomains pattern as identical to one exact host.
- **Empty states:** With no rules, say what a rule does and offer one Create rule action. With rules but no current restriction, say that nothing is active and show the next scheduled change. Use gray, not success green, for both.
- **Pause state:** Show the pause end time and explain any remaining overlap. Use the amber Today treatment when a pause affects the current scheduled state; a paused rule unrelated to the current time should not recolor the whole screen. Do not imply that pausing one rule releases a target if another rule still applies. Avoid promising a second-accurate automatic resume.
- **Unable to enforce:** This is a future device-enforcement state. When an actual permission or extension signal exists, use the coral treatment, “Unable to enforce,” and an **Action needed** panel with a direct fix path. Do not fabricate this state in the Phase 0 simulator or equate “rule saved” with “restriction enforced.”
- **Navigation:** Add rule opens the real editor. Target actions open the appropriate real detail/inspection screens. The mock shows Today, Rules, Guides, Settings to communicate the intended navigation; Guides arrives in a later phase. Do not add an empty Guides destination solely to imitate the mock.

## Existing implementation seams

`RootView.swift` currently defines `TodayView`, `SimulationBanner`, `WhyBlockedAppView`, and `WebsiteLookupView`. `AppModel` exposes `rules`, `snapshot`, `previewDate`, `currentDate`, `refreshClock()`, and rule lookup methods. Build the UI around those existing interfaces, or introduce a small Today view model if that makes state descriptions easier to test. Keep schedule and overlap calculations in the rule layer. The HTML is the appearance and flow reference; the Swift model remains the source of truth.

## Accessibility and completion check

Use text plus color for all states, support VoiceOver and Dynamic Type, maintain readable contrast, and respect reduced motion. A target's accessible description should include its name, app or website type, website scope when relevant, enforcement state, and responsible rules. Keep tap targets generous and distinguish Add rule, preview-time change, target inspection, and status information as separate actions.

Before calling the screen complete, compare the SwiftUI result with all five mock states at a normal iPhone size and a larger text size. Verify the Simulation copy, empty states, pause overlap, next-change explanation, target navigation, and preview-time reset. A passing build alone is insufficient if the interface suggests blocking that the simulator cannot perform.
