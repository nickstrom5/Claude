# Shelf

**Fold your phone shut, and your distracting apps stay shut.**

An iOS screen-time app built to the recipe in the "30,600 apps" research: proven market, one
sentence pitch, onboarding that sells, hard paywall, one core loop, shareable result. Designed
around the iPhone Duo (timer on the outer display while folded) but works identically on every
iPhone with a lock screen.

- `docs/01-strategy.md` — why this idea, positioning vs. Opal/Jomo/Brick, pricing, targets, risks, 30-day plan
- `docs/02-onboarding-and-paywall.md` — every onboarding screen and the belief it moves
- `docs/03-distribution.md` — formats, 20 hooks, creator brief, tier ladder, Duo launch week
- `docs/04-launch-checklist.md` — entitlement request, App Store Connect, build steps

## What's in the box

| Target | What it is |
|---|---|
| `Shelf` | SwiftUI app: 9-step onboarding, taste session, StoreKit 2 paywall, home, active session, result + share card, settings |
| `ShelfShield` | Shield Configuration extension: the branded block screen users see when they open a locked app |
| `ShelfWidgets` | Live Activity: countdown on the Lock Screen / Dynamic Island / iPhone Duo outer display |
| `Shared` | App Group constants and the Live Activity attributes shared by all three |

No backend. Screen Time API (FamilyControls + ManagedSettings), ActivityKit, StoreKit 2,
UserDefaults in an App Group. Analytics events are defined and logged locally; swap in a
provider in `Shelf/Services/Analytics.swift`.

## Build

The Xcode project is generated from `project.yml`, so there is no `.xcodeproj` checked in.

```bash
brew install xcodegen
xcodegen generate
open Shelf.xcodeproj
```

1. Set your team on all three targets (Signing & Capabilities).
2. Change the bundle ID prefix in `project.yml` if you don't own `com.shelfapp`.
3. Run on a **physical iPhone**. Screen Time and Live Activities don't run in the simulator.
4. The `Shelf` scheme uses `Shelf/Resources/Products.storekit`, so the paywall works locally
   without App Store Connect.

**Family Controls entitlement.** Development builds work as soon as the capability is on the
App ID. Distribution needs Apple's approval, per bundle ID, for the app and the shield extension.
Request it on day one: https://developer.apple.com/contact/request/family-controls-distribution

## Core loop

```
Home ──"Shelf it"──▶ shield up + Live Activity ──timer ends──▶ shield down ──▶ result card ──▶ share
                              │
                       hold 10s to give up ──▶ streak resets
```

## Where the numbers come from

The "17 years" hook and the 4.5 h/day average are widely cited estimates. The copy lives in
`Shelf/Views/Onboarding/OnboardingScreens.swift`. The 40% reduction assumption in
`OnboardingAnswers.assumedReduction` is deliberately conservative. Replace all three with sourced
numbers before submission and cite them in the App Store description.

## Status

Scaffolded end to end; not yet compiled on a Mac. First job on a Mac is `xcodegen generate`,
build, and fix whatever the compiler flags. Then run the onboarding on a device and watch where
you stop wanting to continue. That screen is the first thing to fix.
