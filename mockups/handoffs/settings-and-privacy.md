# Feature: Settings and Privacy

## Status

APPROVED

Mockup implementation authorized on 2026-10-17 (“ok, let's do it”). The user explicitly approved the reviewed design on 2026-10-17: “looks good”. Approval covers the Phase 0 simulation/privacy content, local-data deletion and confirmation, unreadable-file recovery, operation states, and About section.

## Reference Files

- `mockups/settings/index.html`
- `mockups/settings/styles.css`
- `mockups/settings/app.js`
- `mockups/settings/README.md`
- `mockups/rules/styles.css` — reused tokens and review shell
- `mockups/README.md` — common visual system
- Read-only native context: `App/SettingsView.swift`, `App/AppModel.swift`, `App/RootView.swift`, `Shared/Storage/RuleRepository.swift`
- Product context: `plan/ui-screens.md`, Phase 0 Settings and privacy; root README privacy/manifesto

## Overview

Give Phase 0 users a clear explanation of simulation and privacy, a deliberate local-data deletion path, and the app's version/project links. Preserve local-only rule storage and accurate limits. Do not preview later enforcement/permission controls as usable settings.

## Screen Structure

1. Settings title in the existing Settings tab.
2. Persistent Simulation notice and short explanation of this build.
3. Privacy: On this device; No account. No tracking.; backup/restore note.
4. Local data: saved-rule count, optional unreadable-file explanation, Delete all local rules…, consequence note, optional operation result/error.
5. About: app name, version/build, manifesto, GitHub source, MIT License note.
6. Existing Today / Rules / Settings tab bar and native safe areas.

## Layout

Scrollable content with approximately 20 pt horizontal insets and 24 pt section gaps. Title about 34 pt bold at standard size. Section labels 15 pt semibold with 10 pt separation from grouped surface. Group radius 15 pt, 15 pt row insets, subtle existing borders. Main row headings about 15 pt semibold, supporting copy 13 pt, notes 12 pt. These are default-size visual references; native must use Dynamic Type styles.

Rows expand vertically without truncation. Count rows can stack label and value at larger text sizes. Links are at least 48 pt high; destructive row at least 48 pt and wrapping. Keep all content scrollable above the tab bar/home safe area. The confirmation accommodates large text and small devices; native uses system layout. The desktop device bezel, status bar, review shell, and CSS breakpoints are not native components. No keyboard or input fields are needed.

## Design Tokens

Reuse existing Rules CSS tokens: canvas #F7F8FD, ink #172344, muted #64708D, white surfaces, line #E7EAF4, blue #355FD7/deep blue #273F9B controls. Simulation uses the existing lavender banner. Destruction/error uses the established #A1465B and #FCECF0 pair, declared locally as error/error-wash variables. Status uses existing neutral #5E687C / #E7EAF0. No global token changes. `design-tokens.json` is not currently present; use Rules CSS and the shared README as the existing references. Light appearance only; native dark equivalents need separate visual validation.

## Components

- **SimulationBanner:** Existing reusable notice with exact no-blocking explanation.
- **Privacy group:** Two static title/body rows; no privacy switches.
- **Saved rules row:** All saved rules count, including disabled/paused rules. Display Unavailable when storage cannot be read.
- **Unreadable-file explanation:** Inline coral context, retained-file explanation, recovery action below.
- **Delete row:** Explicit destructive text with an ellipsis indicating confirmation.
- **Confirmation:** Destructive and Cancel roles; count-specific consequence or unknown-count unreadable-file wording. Mention irreversible deletion. This does not promise actual device restrictions are removed in Phase 0.
- **Operation feedback:** Inline pending/success status or failure; text accompanies color.
- **About group:** Identity/version, labeled external links, licensing note.

## Interactions

- Open from Settings tab; switching tabs uses the existing navigation architecture.
- Delete row opens native confirmation. Cancel, dismissal, or browser Escape in the prototype makes no change. Initial confirmation focus goes to Cancel; do not encourage accidental deletion.
- Confirmation for readable data names the current saved-rule count and deletion of schedules, targets, and pauses. Re-evaluate the current store at execution; do not act on a stale fixture count.
- For unreadable data, explain that the retained file will be permanently deleted, the count is unknown, and the user can start again afterward.
- Confirm invokes the existing repository reset. Prevent duplicate requests while pending. No artificial native delay is required.
- Only successful completion clears rules/pauses, updates simulated restrictions, marks storage ready, sets count to zero, removes the read-error explanation, and announces success. Disable further deletion when empty.
- Failure retains current displayed state, shows an inline error, and allows another attempt through confirmation. Do not claim success, intact data, or cleared restrictions when the result is uncertain.
- Manifesto opens the GitHub README Manifesto anchor; source opens the repository. Use the system browser/URL action. Neither link sends rule data or includes tracking parameters.

## UI States

- **Default:** Example 4 saved rules; deletion enabled; no operation result.
- **Empty:** Count 0; deletion disabled; “No local rules are saved on this device.” Privacy/About remain available.
- **Unreadable store:** Count Unavailable, retained-file explanation, enabled destructive recovery. Do not claim that no rules exist.
- **Confirmation:** Count-specific or unreadable-file variant. No mutation before Confirm.
- **Pending:** Deleting local rules… action disabled; progress status and busy semantics. Do not disable unrelated public links or tab navigation unnecessarily. Operation ownership must outlive the view if it is asynchronous.
- **Success:** Count 0, read failure removed, deletion disabled, “All local rules deleted. Simulated restrictions are cleared.”
- **Deletion error:** Inline failure and an enabled confirmation path; no success message. The fixture fails each confirmed attempt to let reviewers inspect persistence of this state.
- **Loading:** If initial store loading is asynchronous, count displays Loading… rather than 0 and deletion remains disabled until the load resolves. Static Privacy/About stay available. Not a separate prototype fixture; current native load is synchronous.
- **Selected:** Settings tab selected; external review scenario selection is not product UI.

## Accessibility

Support native Dynamic Type with fully wrapping headings, notes, links, count rows, and confirmation content. Use at least 44 × 44 pt touch targets, screen reader names matching visible labels, and explicit native destructive/cancel roles. Include opens-in-browser context for public links. Hide decorative glyphs from accessibility. Restore initiating-control focus on cancellation. After deletion disables that control, focus the completion status; focus the error on failure. Avoid duplicate global/inline announcements. Expose operation progress and meaningful completion changes. Verify native contrast and system disabled styling in the implemented app.

## Native Implementation Notes

The current SettingsView already has simulation/privacy/local reset sections. Reuse that architecture, AppModel.resetLocalData(), SimulationBanner, and the existing TabView. Add bundle-derived version/build and public project links. Replace example version text with actual metadata rather than hardcoding it.

Repository deletion is currently synchronous and the model only clears rules after deleteAll succeeds. Maintain that sequence. Current errors use RootView's global Local rules alert; rendering inline failures may need a result-returning model operation or dedicated state. Keep errors visible without presenting the same failure twice. Do not change unrelated pause edits present in the working tree.

Local-rule data is excluded from backups by the current storage implementation. Preserve that behavior and the restore/reinstall explanation. The UI action deletes the local rule file and clears simulated results; it is not a secure-erasure guarantee or a real system-enforcement reset. Future “remove restrictions” behavior needs its own approved design when real enforcement exists.

No account, sync, tracking, analytics, usage history, data transmission, Safari controls, Screen Time switches, Shortcuts setup, or new dependencies are introduced. Public links are user-initiated browser navigation, not automatic fetches. The prototype's dialog is a content/interaction reference for native confirmationDialog or alert, not a custom native modal requirement.

## Acceptance Criteria

- Settings is reachable in the existing tab navigation and preserves tab safe areas.
- Simulation explicitly says no apps or websites are actually blocked.
- Privacy explains local-only rules, absence of account/tracking, and backup exclusions without misleading toggles.
- Saved count includes every saved rule and does not present read failure or loading as zero.
- Deletion requires explicit confirmation; cancellation has no effect.
- Unreadable-file recovery stays available and uses unknown-count wording.
- Empty and pending states prevent duplicate/unnecessary deletion.
- Success is shown only after actual deletion; failures remain visible and retryable.
- Success clears simulated results and stale read-error state.
- About uses actual version/build metadata and opens the specified public project/manifesto destinations without transmitting rule data.
- Large text and narrow layouts keep the whole screen and confirmation reachable without clipping.
- No native enforcement, Safari, permission, or tracking capability is implied.

## Open Questions

No product decisions remain open for this Phase 0 design. User approval is recorded above; subsequent design changes require renewed approval. Public link destinations come from the current project repository and README anchor; their live availability has not been checked. Example version 1.0 (1) is illustrative.

## Validation

Chrome through Playwright passed all five fixtures at 1280, 390, and 320 px with standard and enlarged browser text: no document/content horizontal overflow, disabled deletion for empty/pending states, unknown count and enabled recovery for unreadable files, Cancel/Escape preserving state and restoring initiating focus, successful reset and unreadable-file recovery, failure without success or count clearing, and reachable About links after scrolling. Enlarged confirmation at 320 px did not overflow. No JavaScript page errors were observed.

Visually inspected default, unreadable data, deletion failure, enlarged screen content, narrow enlarged confirmation, and narrow enlarged About screenshots. Scripts and six captures are temporary in `/tmp/settings-review/`; no review images were added to the repository. No native implementation, native Dynamic Type, VoiceOver, dark appearance, actual file deletion, or live public-link availability verification is included in this UX work.

## Next Step

The iOS agent implements the approved design in SwiftUI, runs relevant builds/tests, and validates against this reference. No native implementation was performed as part of this UX work.
