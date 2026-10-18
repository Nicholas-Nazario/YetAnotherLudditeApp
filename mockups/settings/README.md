# Settings and privacy

Open `index.html` directly in a browser. This Phase 0 reference explains simulation, local-only storage, deletion, and the app's public project links. It introduces no accounts, permissions, data collection, or enforcement.

## Review fixtures

Use the review buttons or `?scenario=default`, `empty`, `unreadable`, `delete-error`, or `deleting`. Enlarged browser text is a review aid; it is not verified native Dynamic Type. The frame, fake status bar, example version, review controls, and 350 ms deletion delay are presentation fixtures. Nothing is written, deleted, transmitted, or persisted by the prototype. Manifesto and repository links open external pages only on selection.

## Content and interactions

The screen is a top-level Settings tab, with Today and Rules as its peers. Reuse the existing visual system and SimulationBanner. Keep the simulation explanation first, followed by Privacy, Local data, and About. Use readable grouped rows rather than introducing privacy switches for features that do not exist.

Privacy states that rules stay on the device and are not sent to the project or third parties; no account, analytics, browsing history, app usage history, or behavioral profiles exist. The backup note explains that users must recreate their rules after a restore or reinstall. Do not imply that an absence of rule transmission prevents an explicitly selected public GitHub link from making a browser request.

Local data shows the saved-rule count, not the currently active rule count. The destructive action opens confirmation; Cancel receives initial focus. Confirm deletes all local rule data, including schedules, targets, and pauses, and clears simulated restrictions. Only report success after deletion succeeds. An empty known store disables deletion and explains that nothing is saved. An unreadable file displays Unavailable instead of zero, explains that the file was retained, and keeps deletion enabled as a recovery path. Recovery confirmation describes permanent deletion of an unreadable file whose rule count is unknown. Do not describe this as repair or recovery of the lost rules.

After failure, retain the previously displayed state, show an inline error, and keep deletion available for another explicitly confirmed attempt. Do not claim that all data is intact or that restrictions were cleared. During an actual pending operation, prevent duplicate submission and announce progress; do not add an artificial delay to native code. Successful reset changes the count to zero and announces success in place. Selecting another fixture resets the demonstration.

About shows app identity, example Version 1.0 (1), manifesto/repository links, and MIT licensing. Native uses actual bundle version/build values. Both links point to the existing GitHub project; the manifesto target is the README's Manifesto heading. Native opens them using the system URL mechanism; no embedded WebView, rule/query data, or tracking parameters. No live external-page verification was performed as part of this mockup.

## Native mapping

Adapt SettingsView using native Form/Section or equivalent flexible grouped content inside its existing NavigationStack and TabView. Use the existing SimulationBanner and resetLocalData operation. The HTML dialog expresses confirmation content and intent; use native confirmationDialog/alert with destructive and cancel roles. The native action arrangement follows iOS conventions rather than copying HTML button order. Keep the existing app-level error architecture in mind: avoid duplicate global and inline errors for the same failure. Only mutate displayed saved-rule state after successful repository deletion.

Do not implement Screen Time, Safari status, Private Browsing controls, Shortcuts setup, appearance settings, account flows, export/sync, or analytics toggles. Those are outside this Phase 0 reference.

## Accessibility and validation

All rows and confirmations wrap; use semantic Dynamic Type styles, at least 44 pt touch targets, visible focus, and explicit destructive labels. Preserve focus on cancellation and place focus on the result after successful deletion if the initiating action becomes disabled. Use one meaningful completion/error announcement rather than repeated announcements during rendering. Content scrolls above the existing tab bar and safe areas.

See `../handoffs/settings-and-privacy.md` for confirmed validation results and the approval status. Light appearance is the current reference. Native Dynamic Type, VoiceOver, dark appearance, and actual file deletion require native implementation validation.
