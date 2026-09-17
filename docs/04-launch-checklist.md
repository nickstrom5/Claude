# Launch checklist

## Day 1 (do these before writing another line of code)

- [ ] Create the App ID in the Apple Developer portal with a final bundle ID. It is set to
      `com.clamapp.ios` in `project.yml`; change it once, everywhere, before requesting the
      entitlement (entitlements are per bundle ID).
- [ ] Enable **App Groups** (`group.com.clamapp.ios`) on the app and all three extensions.
- [ ] **Request the Family Controls (Distribution) entitlement** for the main app, the shield
      extension (`com.clamapp.ios.shield`) and the monitor extension (`com.clamapp.ios.monitor`).
      Requests are per bundle ID.
      Form: https://developer.apple.com/contact/request/family-controls-distribution
      Draft answers are in `docs/07-entitlement-request.md`.
      In 2026 this is taking days to weeks, so this is the critical path. Development builds
      work without it.
- [ ] App Store Connect: create the app, three in-app purchases matching `Clam/Resources/Products.storekit`
      (`clam.yearly`, `clam.monthly`, `clam.lifetime`), one subscription group, 7-day free trial
      intro offer on yearly.
- [ ] Turn on GitHub Pages: repo Settings → Pages → Deploy from a branch → this branch, folder `/docs`.
      That publishes `docs/index.html`, `privacy.html` and `terms.html` at
      https://nickstrom5.github.io/Claude/ which the paywall and settings already link to.
      Replace `hello@clamapp.example` in those files with a real address.

## Build

```bash
brew install xcodegen
cd Claude
xcodegen generate
open Clam.xcodeproj
```

- Select your team in Signing & Capabilities for the app and its three extensions.
- Run on a **physical device**. Screen Time APIs and Live Activities do not work in the simulator.
- Use the `Clam` scheme; StoreKit testing is wired to `Products.storekit` so purchases work
  locally without App Store Connect.

## Before submission

- [ ] Replace placeholder copy numbers in `OnboardingScreens.swift` with sourced ones (the 17-years stat
      and 4.5h average are widely cited estimates; cite them in the App Store description).
- [ ] App Store screenshots: 1) fold + lock screen timer, 2) block screen, 3) result card,
      4) one button home, 5) reveal number. Same order as the onboarding beliefs.
- [ ] App Review notes: explain Family Controls use (individual, not parental), how to test
      (pick any app in onboarding, start 1-minute session).
- [ ] Turn on analytics backend (`Analytics.swift` currently logs to console; swap in
      PostHog/Mixpanel with the same event names).

## Day of launch

- [ ] Promo codes for creators generated in App Store Connect (Offer Codes).
- [ ] Post the first 10 videos already recorded.
- [ ] Read every review daily. One fix per day for the first two weeks.
