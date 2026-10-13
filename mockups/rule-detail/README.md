# Rule detail · UX implementation reference

Open [index.html](index.html) directly in a browser. No build step or remote assets are required. The local stylesheet imports the existing Rules styles, so retain both directories when sharing the prototype.

## Design direction

One scrollable detail screen explains one rule, provides a neutral gray Pause action and a blue Resume now action, and separates indefinite disabling into an Enabled switch below its targets. Use restrained grouped white surfaces, not a dashboard hero. Edit stays in the navigation toolbar. The rule name wraps in the content header.

The simulation notice remains visible in every fixture: no apps or websites are actually blocked. Sample apps are Simulator examples. Website rows describe saved matching scope, not browser enforcement.

## Review scenarios

Use the external scenario buttons or `?scenario=active`, `upcoming`, `paused`, `disabled`, `overnight`, `long`, or `error`. Switching scenarios resets the local fixture and scroll position. Times are fixed illustrations, not an evaluator or live clock.

- Active: Work Hours would restrict two apps and one website. Other-rule overlap is explained through the target destination and pause confirmation, not inferred from this rule's counts.
- Upcoming: outside scheduled hours, with the next start time; no websites provides the empty subgroup example.
- Paused: pause until 12:35 PM within a 9 AM–5 PM active window.
- Disabled: an unexpired pause remains stored. Re-enabling yields Paused; Resume now then yields Active.
- Overnight: Mon–Fri start days, 10 PM–7 AM next day, and tomorrow's end.
- Long content: wrapping title and host, nonconsecutive days, several targets.
- Save failure: Enabled, Resume/Pause, and Delete attempts preserve the existing rule and show failure feedback.

## Interaction boundaries

Enabled and Resume now update only the in-memory fixture. Delete opens a confirmation dialog; cancelling preserves the rule, successful deletion shows a review-only return link. Native success should navigate directly back to Rules. Native failure must stay on detail and retain persisted state.

Pause, Edit, app explanations, website checks, and Settings display explicitly labeled destination toasts. Pause does not immediately mutate the rule. Its duration and overlap confirmation will have a separate mockup. Back, Today, and Rules link to existing prototypes. Editing an existing rule is not implemented by linking to the unrelated new-rule fixture.

## Native mapping

Use NavigationStack toolbar actions, grouped List/Sections or equivalent surfaces, native Toggle, and confirmationDialog. Use the rule's current effective state and date/calendar-based schedule boundaries. The tabs, device frame, fake status bar, and review controls are illustrative. Do not reproduce them inside a pushed native view.

State priority is Disabled → Paused → Active/Upcoming. Paused outside its schedule must show the next scheduled start, rather than promising restriction at pause expiry. Resuming ends the pause; it does not turn on a disabled rule or override schedule hours. Enabled never changes schedule or targets.

App explanations list all currently applicable enabled, unpaused rules for that app. Website checks start with a concrete host and explain all matching rules; checking a base host does not establish identical overlap for every subdomain. This website/All subdomains labels follow the Rule editor handoff; align native matcher behavior with that specification before adopting its labels.

## Styling and accessibility

Use the imported Rules semantic tokens. No token values or shared token files are changed. Content has 20 pt default inset, 21 pt major section gaps, 15 pt group radii, and flexible heights. Buttons and toggles provide at least 44 pt hit areas. Use Dynamic Type and full wrapping; never truncate hosts or status explanations. Reading order follows name, notice, status/action, schedule, apps, websites, controls, deletion. Text carries every status meaning.

This reference specifies light appearance. Native dark appearance and accessibility text sizes require native validation. See [handoff](../handoffs/rule-detail.md) for the full contract and review status.
