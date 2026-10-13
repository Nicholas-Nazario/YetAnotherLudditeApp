# Pause review · UX reference

Open [index.html](index.html) directly in a browser. This standalone prototype imports the existing Rules stylesheet. No build step, remote resources, or dependencies are needed.

## Design

A full-height native sheet presents Cancel, the rule name, a Simulation notice, duration, pause-end timing, and a compact Effect of this pause summary. Confirm pause sits in a fixed gray footer above the safe area. It remains reachable while the sheet content scrolls. No tabs are shown within the sheet.

Presets are 15 min, 30 min, 1 hour, and Custom. Initial duration is 15 minutes. Custom uses separate hours and minutes wheels, defaulting to 0 hours 15 minutes, with an inclusive 15-minute to 24-hour range, with inline validation and confirmation disabled for invalid input. Selecting a preset does not erase the custom draft.

The initial effect summary gives app counts that would stop being restricted versus those still covered by other rules. It never lists all targets by default. View affected targets expands complete app explanations and representative website address results. Website patterns are not counted as wholly released: overlap may differ by address. Each actual address explanation must include all applicable rules. Collapse returns to the compact summary.

Summary refers to the immediate effect only. It does not promise that a target stays unrestricted throughout the pause. Upcoming rules say Nothing changes now and explain whether the duration covers the next scheduled start. Pause expiry and scheduled resumption are separate concepts.

## Fixtures and interactions

External controls and `?scenario=` support overlap, clear, all, upcoming, websites, invalid, and error. Fixtures are Monday October 12, 2026 at 12:20 PM, with Work Hours ending at 5 PM or Afternoon Focus running 1–4 PM. Example other rules are Lunch (until 1 PM), Study Time (until 3 PM), and Mobile Break (until 2 PM). Fixture evaluation is illustrative and does not replace native calculations.

Changing duration updates the end and schedule explanation; expanding targets uses a native HTML disclosure. Invalid wheel combinations retain their selection. The error scenario preserves the chosen duration and keeps the sheet open after confirmation fails. Successful confirmation and Cancel show review-only destination feedback; they do not persist data or change a rule. In the native app they dismiss to Rule detail on success or cancellation.

The developer review panel, phone frame, fake status bar, and toasts are not native UI. Use a sheet with NavigationStack, native buttons, a grouped list/scroll view, DisclosureGroup, and a safe-area-aware confirmation footer. Match footer behavior to keyboard presentation and use a native hours/minutes duration wheel for Custom.

## Accessibility and limitations

Maintain 44 pt minimum touch targets, visible status words and field labels, accessible expanded state, complete wrapping text, and Dynamic Type. Presets wrap to two columns on narrow widths; native accessibility sizes should wrap similarly. Light appearance only; native keyboard, dark mode, VoiceOver, and Dynamic Type require implementation validation.

Phase 0 does not block apps, Safari, or Private Browsing. Sample identities are illustrative. No network or tracking is introduced. See [handoff](../handoffs/pause-review.md) for behavior and review status.

## Validation

Chrome/Playwright checks passed across seven fixtures at 1280, 390, and 320 px: no horizontal overflow, accessible scrolling/footer, disclosure state, custom duration limits, next-day and upcoming timing, and selection retention after a simulated storage failure. Enlarged text remained scrollable. Default, expanded, and enlarged-text screenshots were visually inspected; temporary captures are outside the repository. No native build, Dynamic Type, keyboard, VoiceOver, or dark-mode verification was performed.

## Review revisions

Custom now uses separate hours/minutes scrollers (native iOS duration wheels in SwiftUI) rather than typed minutes. The HTML uses scrollable select lists to demonstrate selection and keyboard access; it is not an exact rendering of the native wheel. Website details use concise address/result rows: “youtube.com + www — Would be unrestricted” and “m.youtube.com — Still restricted · Mobile Break until 2 PM,” followed by “Other addresses may differ.” These rows remain conditional on the Phase 0 Simulation notice; show every responsible rule if more than one applies.
