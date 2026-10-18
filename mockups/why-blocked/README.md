# Why blocked

Open `index.html` directly in a browser. Six review fixtures cover app overlap, one rule, website scopes, no active matches, many/long rule names, and local-data failure. Use `?scenario=website` (or another scenario key) for a direct state. Review controls, time advancement, enlarged browser text, phone frame, fake status bar, and prototype messages are outside the native product specification.

## Screen behavior

Push from a Today target using the existing navigation stack. Show the target identity, persistent Simulation notice, current result, and every responsible rule. Only enabled, unpaused rules whose schedules include the evaluation time belong in this list. Do not truncate or collapse the rule list. A target remains restricted while any responsible rule applies.

Each card shows the name, schedule, current window end, and website matching explanation when applicable. The main card opens the selected Rule detail; the prototype reports the intended destination in a review-only toast because the separate Rule detail reference uses its own fixed fixtures. The separate Pause… button opens the approved Pause review for that rule. Return to an updated explanation after confirmation or cancellation.

The prototype's small pause dialog is a flow demonstrator with 15/30/60-minute presets, selected-rule identity, timing, overlap consequence, Cancel, and simulated confirmation. It links to the full approved Pause review reference. It does not replace that reference or define a new native pause design: native must retain Custom and the complete 15-minute–24-hour duration range. Simulated confirmation removes only the selected rule from the displayed reasons; scenario selection resets the fixture. The prototype does not evaluate pause expiry or future schedules.

## Website inspection

The checked host is the primary target heading. Expand **Check another address** to show the labeled address field and Check host button. Editing alone does not change the result. A successful check updates the checked host and complete rule list, leaving the form open for comparison. Invalid input preserves the last checked host/result and states explicitly which host those results describe.

Use current native semantics: lower-case, normalize domain/URL input, remove the leading `www.`, and treat the stored host plus its `www` version as equivalent even for exact scope. Including-subdomains scope also matches deeper hosts, at a dot boundary. Examples:

| Checked address | Work Hours: youtube.com + subdomains | Lunch: m.youtube.com + www equivalent |
| --- | --- | --- |
| youtube.com or www.youtube.com | Yes | No |
| m.youtube.com | Yes | Yes |
| www.m.youtube.com | Yes | Yes |
| music.youtube.com | Yes | No |
| notyoutube.com | No | No |

No requests are made to checked sites. Require a concrete host, not a wildcard. The prototype parser is illustrative; native parsing and matching remain authoritative. The generic screen guide's preserve-www/strict-exact description differs from the existing app and Rule editor. This reference follows the existing behavior and does not authorize a rule-engine change.

## Native mapping and states

Use NavigationStack, a scrollable flexible content column, SimulationBanner, separate NavigationLink/Button controls, a disclosure with a URL-keyboard TextField, and the existing Pause sheet. Use semantic Dynamic Type fonts and SF Symbols. Target and rule names wrap completely. Tap targets are at least 44 pt; cards and forms expand with text. After pause, keep VoiceOver focus on an appropriate updated result if the initiating card disappears. Announce meaningful result changes without repeated clock announcements.

No active matches uses a neutral result and no responsible-rule list. A local read failure shows an unknown-state error and retry rather than claiming an unrestricted result. During actual loading, retain identity/Simulation, show a labeled progress indicator, and withhold stale result/actions. Current data returns after successful retry. There is no loading delay fixture because the prototype uses synchronous local examples.

Expected window-end times describe individual rules, not a promise that the target becomes unrestricted then. Refresh native results on foreground entry and relevant schedule/pause boundaries, using one injected date and calendar. The review-only “Simulate Lunch ending” control demonstrates the complete list shrinking at 1:00 PM without navigating away. No time override belongs in the product screen.

## Validation

See the handoff for confirmed checks and remaining limitations. Light appearance is the visual reference. Enlarged browser typography is not native Dynamic Type verification. No SwiftUI changes are part of this work.
