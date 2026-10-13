# UI mockups

These browser mockups are the visual and interaction plan for the iOS app. They are source files that can be opened directly in a browser, reviewed state by state, and translated into SwiftUI. Each screen's README records the required content, behavior, and relevant product constraints alongside its proposed presentation.

## Screens

| Screen | Open the mockup | Read the screen specification |
| --- | --- | --- |
| Today | [Interactive prototype](today/index.html) | [Component and state notes](today/README.md) |
| Rules | [Interactive prototype](rules/index.html) | [Component and state notes](rules/README.md) · [Handoff](handoffs/rules-list.md) |

## Approach for this proof of concept

Use **one small, standalone prototype per screen**. There is no shared JavaScript framework, bundler, package manager, or remote asset dependency. A detailed process and common visual rules provide consistency while leaving room to fit each screen's content. When repeated UI patterns become stable across several screens, consider extracting actual shared code.

Each new screen lives in `mockups/<screen-name>/`:

```text
index.html   Semantic app markup plus review controls outside the phone frame
styles.css   Screen layout and named design tokens
app.js       Small review fixtures and interactions, if needed
README.md    SwiftUI mapping, state behavior, and phase boundaries
```

The review shell may show a device frame and scenario buttons. Everything outside the phone's inner screen is for design review only. Do not translate the fake status bar, Dynamic Island, device bezel, desktop notes, or scenario buttons into SwiftUI.

## Repeatable workflow for another screen

1. **Read the product requirements.** Use `plan/ui-screens.md` and the relevant phase notes. List the screen's purpose, required content, actions, unavailable states, and platform limits before drawing it.
2. **Choose review scenarios.** Include the normal state, meaningful empty state, and failure or edge states that change the layout. Give each scenario an obvious button in the review shell and, when useful, a direct `?scenario=` URL. Keep those fixtures separate from the app UI.
3. **Build the phone view with semantic HTML.** Use headings in order, real buttons and labeled inputs, visible status words, and accessible names for actions. Keep important information high on the screen, then allow natural scrolling. Do not add interactions that the app cannot support.
4. **Apply the visual system below.** Put semantic color variables at the top of `styles.css`. Use the same state meanings, type hierarchy, icon style, spacing rhythm, and calm tone. Adapt composition to the screen rather than copying Today's cards mechanically.
5. **Make state data readable.** If JavaScript is useful, keep example fixtures in a clearly named object and render from a small state model. Do not copy production scheduling or enforcement logic into the mockup. Indicate what is illustrative.
6. **Write the screen README.** Explain what is review-only, how HTML elements map to SwiftUI, what each state means, where actions go, what data the app must provide, and what belongs to a later phase.
7. **Review before committing.** Open the HTML directly in a browser at desktop and phone widths. Switch through every scenario, inspect scrolling and long text, check keyboard access, and verify that errors and simulation limits are stated accurately. Commit only the source files needed to reproduce the mockup; keep temporary screenshots and browser profiles outside the repo.

## Common visual system

**Character.** Calm, factual, and adult. Show status and consequences clearly. Avoid scores, streaks, guilt, celebratory prompts, and decorative marks that look like progress. Status always has a text label; color reinforces it.

**Color.** The mockups use a cool neutral canvas with soft semantic gradients. Define colors by meaning so future screens can adapt without giving one color two conflicting jobs:

| Use | Base token | Supporting treatment |
| --- | --- | --- |
| Canvas / ink / secondary text | `#F7F8FD` / `#172344` / `#64708D` | White cards, subtle borders `#E7EAF4` |
| Navigation and controls | blue `#355FD7`, optional purple `#7354CC` | Use for actions and neutral product identity |
| Active restriction | muted teal `#347E68` | mint `#EAF7EF`; hero gradient `#D8F2E2` → `#B6E6C9` → `#94D5B5` |
| Paused rule | amber `#97560C` | cream `#FFF0D3`; hero gradient `#FFE4AE` → `#F1BC58` |
| Inactive / no rules | slate `#5E687C` | gray `#E7EAF0`; hero gradient `#EDF0F5` → `#D8DEE8` |
| Unable to enforce / error | muted coral `#A1465B` | rose `#FCECF0`; hero gradient `#F9DCE1` → `#F2C0CA` → `#E9A3B2` |

The palette above is a starting point, not a requirement to put a large gradient on every screen. Preserve the semantic meaning. A paused rule can coexist with an actively restricted target: the pause context is amber, and the still-restricted target keeps its active treatment. The mockups currently specify a light appearance; any later dark appearance needs semantic equivalents with readable contrast.

**Typography.** Use the platform system font, San Francisco. Build a clear scale: screen title around 34 pt bold, main status around 27 pt bold, section titles around 18 pt semibold, target names around 14–16 pt semibold, and supporting text around 12–13 pt in the HTML reference. SwiftUI should use Dynamic Type styles, so those numbers are visual guidance at a default size rather than fixed accessibility limits.

**Shape and space.** The phone content uses roughly 20 pt horizontal padding, about 15–16 pt between major cards, 24 pt corner radii for a hero, 18 pt for ordinary cards, and 11–15 pt for controls and icon badges. Use light shadows and enough space for readable state descriptions. Let content scroll rather than shrinking critical copy.

**Icons.** Use simple local line icons in HTML. In SwiftUI, prefer equivalent SF Symbols and native controls; no third-party icon pack is needed. Icons support words rather than replacing them. Sample-app letter badges are placeholders only, never a fabricated installed-app list.

**Copy and truthfulness.** Phase 0 previews must prominently say **Simulation — No apps or websites are actually blocked**. Use conditional language such as “would be restricted.” Distinguish saved rules from enforced restrictions, active from paused, and no rules from nothing active now. Where platforms cannot perform an action, show the limit or the setup path in context.

## What is canonical

Use the screen guide for required behavior, the screen's `index.html` and `styles.css` for its reviewed appearance, and the screen's `README.md` for how to translate that appearance into app behavior. Example JavaScript fixtures make the mockup inspectable; the Swift rule model remains the implementation source of truth.
