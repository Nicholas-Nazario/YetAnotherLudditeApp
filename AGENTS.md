# Agent guidance

## Project boundaries

- This is a native Swift and SwiftUI iOS app. Keep runtime dependencies to Apple's frameworks unless the user approves a concrete need for another dependency.
- Follow the existing separation between `App/` screens and app state, `Shared/Rules/` calculations and models, `Shared/Storage/` persistence, and `Simulation/` demo data.
- Keep rule evaluation independent of global time. Pass the date and calendar into calculations so schedules and preview-time behavior remain reproducible.
- Preserve local-only storage and the app's privacy commitments. Do not add accounts, analytics, behavioral tracking, cloud sync, or network transmission of rule data without explicit user direction.

## Product behavior

- Be precise about what the app enforces. Phase 0 uses sample app identities and simulates restrictions; never present its results as real blocking or imply that Safari or Private Browsing is blocked.
- Keep overlapping-rule explanations complete: an item remains restricted while any applicable enabled, unpaused rule includes it.
- Treat schedule boundaries, overnight start days, pause expiry, host normalization, and exact-host versus subdomain matching as user-visible behavior. Preserve their documented semantics when changing the implementation.
- Keep accessible labels and support for larger Dynamic Type sizes in SwiftUI screens.

## Changes and pull requests

- Keep pull requests focused on the requested product or engineering change.
- Do not include files under `plan/` or `mockups/` in a pull request unless the user asks for those files. Avoid adding README links to files excluded from the pull request.
- Update the README when build or run instructions change. When the user asks for build or test verification, use the documented Xcode project, scheme, and Simulator destination.
- Do not claim device enforcement, platform compatibility, or test coverage that has not been verified.
