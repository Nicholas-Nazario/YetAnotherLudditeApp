# Today screen · UI/UX implementation reference

Open [index.html](index.html) in a browser. It has no build step, packages, fonts, or network dependencies. The phone frame is a review aid; only its inner screen represents app UI. The scenario controls outside the frame expose states for design review and do not belong in the iOS app.

The fake 9:41 status bar, Dynamic Island, home indicator, and device bezel are presentation only. SwiftUI should rely on iOS for those surfaces.

For a direct state link, append `?scenario=overlap`, `?scenario=quiet`, `?scenario=paused`, `?scenario=unavailable`, or `?scenario=no-rules` to the file URL.

## Design intent

Today answers three questions: **What is my status now? What changes next? What is affected and why?** The summary and next change are visible near the top; the target list provides detail below. The tone is calm and factual. Color signals status; blue and purple remain available for navigation and neutral controls. Every state also has an explicit text label. The visual hierarchy stays the same across active, inactive, paused, and enforcement-error states.

## Screen structure and SwiftUI mapping

| HTML component | Intended SwiftUI element | Behavior |
| --- | --- | --- |
| `.app-header` | `NavigationStack` title and toolbar action | Date, Today title, Add rule. Add rule opens Rule editor. |
| `.simulation-banner` | Prominent reusable `SimulationBanner` | Phase 0 only. Always say that no apps or websites are actually blocked. |
| `.summary-card` | Status summary view | Counts effective targets or names the unavailable state. Its upper-right label says Active, Paused, Inactive, Alert, or No rules. It is informational, not a button. |
| `.next-card` | Next transition or action-needed view | Show the next expected change and its impact. For missing enforcement, label it Action needed and show the fix path. Do not promise second-accurate execution. |
| `.preview-control` | Expandable preview-time control | Defaults to current device time in the real Phase 0 app. Choosing a date/time recomputes all visible states. Reset returns to live time. This mockup uses a fixed demo time for reproducible review. |
| `.targets-section` | Effective target list | Only effective restrictions appear here. Each target shows its type/scope and all or a count of responsible rules. In an enforcement-error state, use “Unable to enforce.” |
| `.target-card` | Target row/card | App action opens Why blocked for that app. Website action opens host inspection, where matching rules are calculated for a concrete host. |
| `.empty-state` | Empty content view | Distinct copy for no rules and no active restrictions. Create rule is the primary action when there are no rules. |
| `.tab-bar` | Four-tab primary navigation | Today, Rules, Guides, Settings. Only Today is implemented in this mockup. |

## State data contract

`app.js` keeps example state in `todayViewState(date, mode)` and passes it to `render()`. In Swift, replace the fixtures with a view model derived from the rule evaluator and enforcement status. The view model should contain:

- Preview date/time and whether it is live or user-selected.
- Summary title and explanatory sentence.
- Effective targets, each with identity, app/site type, website matching scope if applicable, responsible rule names/IDs, and enforcement state.
- Next expected transition time and a plain-language description of its effect.
- Empty-state kind: no rules, no effective targets, or none.

The mockup offers five review fixtures:

1. **Active overlap:** Work Hours and Lunch both affect Sample App A; Work Hours also affects `youtube.com` and its subdomains. The next change ends Lunch, but Sample App A stays restricted by Work Hours.
2. **Nothing active:** The list has an explanatory empty state and the next scheduled change remains visible.
3. **One rule paused:** Work Hours is paused until 12:35 PM. Lunch still affects Sample App A. The summary and next-change copy explain the overlap.
4. **Unable to enforce:** A later-phase device state. Saved rules appear as scheduled but are never described as effective blocking. A fix path belongs in Settings or the relevant setup screen.
5. **No rules yet:** One clear Create rule action, with no fabricated next change.

The date/time control also previews Work Hours (weekdays 9 AM–5 PM), Lunch (weekdays noon–1 PM), and Evening Wind Down (daily 10 PM–7 AM). This small JavaScript fixture is for UI demonstration; the app's `RuleEvaluator` remains the source of truth.

## Visual tokens

`styles.css` defines semantic tokens in `:root` and applies a `data-tone` to the summary and next-change views. Translate those tones to named SwiftUI color assets rather than choosing colors separately in each screen:

| Meaning | Main token | Treatment |
| --- | --- | --- |
| Active restriction | Muted teal `#347E68` | Light mint gradient summary, pale green supporting surfaces. |
| Rule paused | Amber `#97560C` | Warm gold summary, soft amber supporting surfaces. A target still restricted by another rule keeps its active green badge. |
| Inactive / no rules | Slate `#5E687C` | Cool gray summary and empty states. |
| Unable to enforce / error | Muted coral `#A1465B` | Light coral gradient summary, red target edge and pale rose supporting surfaces. |
| Navigation and controls | Blue `#355FD7`, purple `#7354CC` | Product identity and actions; these colors do not imply enforcement status. |

The canvas is `#F7F8FD` and ink is `#172344`. The HTML uses system fonts. SwiftUI should use Dynamic Type styles while keeping the hierarchy and relationships shown here. Cards use 18–24 px corner radii and modest shadows. Status meaning must remain readable without color.

## Interaction and accessibility requirements

- The Simulation label stays visible near the top in Phase 0, including every preview state.
- The preview date/time is a labeled control, and Reset returns to device time in the app.
- Target actions have explicit accessible names. Do not make a whole card clickable if it hides which action will happen.
- VoiceOver should announce a target, its matching scope if it is a website, enforcement state, and responsible rule count/names.
- Respect Dynamic Type and reduced motion. The mockup's fixed device frame is only for review; the SwiftUI layout should scroll and adapt naturally.
- Persistence or permission failure must have its own explicit message. A saved rule is never presented as enforced when enforcement is unavailable.

## Phase boundaries

The default Today design represents **Phase 0 simulation** with example app identities. No actual iOS app or Safari restriction is implied. The unavailable fixture previews the message hierarchy needed after device enforcement exists. The mockup does not define the Rule editor, Why blocked, Safari setup, or Settings screens; those will each have their own reference.
