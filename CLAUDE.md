# Clam — notes for Claude Code sessions

iOS app (SwiftUI, iOS 17+). Read `README.md` and `docs/01-strategy.md` first.

## Build
- The Xcode project is **generated**: `xcodegen generate` (brew install xcodegen). Never commit `Clam.xcodeproj`.
- Any change to targets, files outside existing folders, entitlements or Info.plist keys goes in `project.yml`, then regenerate.
- Build: `xcodebuild build -project Clam.xcodeproj -scheme Clam -destination 'platform=iOS Simulator,name=<an iPhone>' CODE_SIGNING_ALLOWED=NO`
- Tests: same with `test -only-testing:ClamTests`.
- CI (`.github/workflows/build.yml`) does exactly this on `macos-26`. Keep it green.
- Screens: launch with `-screenshot <hook|hours|apps|triggers|reveal|permission|taste|result|paywall|home|session|settings|share>`
  to open one screen with seeded data (`Clam/App/ScreenshotMode.swift`). The `Screenshots` workflow captures all of
  them in the simulator and commits PNGs to `docs/screenshots/`. Look there before and after UI changes.

## Runtime caveats
- Screen Time (FamilyControls / ManagedSettings), the shield extension and the monitor extension only work on a physical device. In the simulator `ScreenTimeManager.isSimulator` stubs them so the whole flow is clickable.
- Live Activities work in the simulator (⌘L to lock).
- StoreKit uses `Clam/Resources/Products.storekit`; product IDs `clam.yearly`, `clam.monthly`, `clam.lifetime`.

## Conventions
- One core loop, no feature creep: onboarding → paywall → session → result. New features need a line in `docs/01-strategy.md` explaining which funnel metric they move.
- Every funnel step logs an `AnalyticsEvent`. Add events there, never ad-hoc strings. PostHog is the sink
  when `Config.postHogKey` is set; keep it anonymous (no `identify`, no replay).
- Copy lives in the views. Keep it short and direct; no "Welcome!", no feature lists.
- Dark theme only, tokens in `Clam/Design/Theme.swift`.
