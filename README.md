# Yet Another Luddite App

## Run the Phase 0 prototype

Open [YetAnotherLudditeApp.xcodeproj](YetAnotherLudditeApp.xcodeproj) in Xcode 27, select an iPhone Simulator, and run the `YetAnotherLudditeApp` scheme. Keep Xcode's Devices window visible while interacting with the app; this Xcode installation does not include a separate Simulator app. The project targets iOS 16 or later, but the current workspace has an iOS 27 Simulator runtime. A paid Apple Developer Program membership is not needed for this simulated prototype.

The app can create local rules for sample apps and website domains, preview schedules and overlaps, and pause rules. It labels these results **Simulation** because it does not block real apps or websites. Rule data is stored in the app container and excluded from app backups, so it will not return after a restore or reinstall. Use Settings to delete it.

To build and test from the command line with a matching Simulator installed:

```sh
xcodebuild -project YetAnotherLudditeApp.xcodeproj -scheme YetAnotherLudditeApp -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project YetAnotherLudditeApp.xcodeproj -scheme YetAnotherLudditeApp -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO test
```

## Manifesto

Our phones are useful tools. They can also make it difficult to spend our time the way we intend. Yet Another Luddite App exists to help adults set boundaries for their own devices and follow through on them.

The person using the phone is in charge. This is a self-management app, not a system for monitoring or controlling someone else.

### What guides us

**Give people practical control.** Let users schedule when selected apps and websites are unavailable. Make active rules, upcoming changes, and ways to edit or remove a rule clear.

**Respect privacy by default.** Require no account. Run on the device, with no service operated by this project. Collect no usage history, browsing history, analytics, or behavioral profile. Store only the local configuration needed to keep a user's chosen rules working after the app closes or the device restarts. Do not transmit that configuration to us or to a third party.

**Be honest about the platform.** Use public iOS APIs and explain their limits. If a behavior belongs in Apple's Shortcuts app, such as changing Color Filters when Camera opens, guide the user through setting it up rather than claiming the app can do it silently.

**Keep the product small and understandable.** Every feature should help a user make or maintain an intentional boundary. Avoid feeds, streaks, scores, engagement prompts, and unnecessary permissions.

**Remain open.** The source code is available for inspection, modification, and contribution under the [MIT License](LICENSE). Privacy and behavior should be verifiable in the code, not just promised in copy.

### The standard for new features

Before adding a feature, ask: Does it help someone use their own device more intentionally? Can it work locally, without collecting activity data or requiring an account? Can we explain its behavior and limits plainly? If the answer is no, it does not belong here.
