# Clam

**Fold your phone shut, and your distracting apps stay shut.**

An iOS screen-time app built to the recipe in the "30,600 apps" research: proven market, one
sentence pitch, onboarding that sells, hard paywall, one core loop, shareable result. Designed
around the iPhone Duo (timer on the outer display while folded) but works identically on every
iPhone with a lock screen.

- `playbook/01-strategy.md` — why this idea, positioning vs. Opal/Jomo/Brick, pricing, targets, risks, 30-day plan
- `playbook/02-onboarding-and-paywall.md` — every onboarding screen and the belief it moves
- `playbook/03-distribution.md` — formats, 20 hooks, creator brief, tier ladder, Duo launch week
- `playbook/04-launch-checklist.md` — entitlement request, App Store Connect, build steps
- `playbook/05-naming.md` — why the app is called Clam and what was rejected
- `playbook/06-app-store-listing.md` — title, subtitle, keywords, description, screenshots, review notes
- `playbook/07-entitlement-request.md` — copy-paste answers for the Family Controls request
- `playbook/08-launch-videos.md` — shot lists for the first 10 videos
- `playbook/09-creator-outreach.md` — DM, brief, pay and tracking for small creators
- `playbook/10-app-store-connect.md` — identifiers, agreements, in-app purchases, privacy labels, TestFlight, submission
- `playbook/11-site-and-email-runbook.md` — reusable: domain, GitHub Pages, Cloudflare DNS and free support email
- `playbook/12-social-kit.md` — handles, bios, pinned post, two-week schedule, captions, reply templates, Reddit posts
- `playbook/13-roadmap.md` — records and badges (built), Game Center friends/leaderboards/challenges (next), what waits for evidence
- `docs/brand/` — profile picture, banner, first post image
- `docs/index.html`, `privacy.html`, `terms.html` — landing page (getclam.app) and legal pages, served by GitHub Pages
- `docs/how-to-block-apps-on-iphone.html`, `block-tiktok-instagram-on-iphone.html`, `focus-mode-vs-app-blocker.html` — guide pages; plus `robots.txt`, `sitemap.xml`, `404.html`, `site.webmanifest`
- `scripts/make-brand.swift` — regenerates `docs/og.png`, favicons, manifest icons and the site's sized screenshots

## What's in the box

| Target | What it is |
|---|---|
| `Clam` | SwiftUI app: 9-step onboarding, taste session, StoreKit 2 paywall, home, active session, result + share card, settings, Siri/Action Button intent |
| `ClamShield` | Shield Configuration extension: the branded block screen users see when they open a locked app |
| `ClamWidgets` | Live Activity countdown (Lock Screen / Dynamic Island / iPhone Duo outer display) and a Home Screen "Clam up" widget |
| `ClamMonitor` | Device Activity monitor: clears the shield when the session ends even if the app was killed |
| `ClamTests` | Unit tests for streak, reveal math and durations |
| `Shared` | App Group constants and the Live Activity attributes shared by all three |

No backend. Screen Time API (FamilyControls + ManagedSettings), ActivityKit, StoreKit 2,
UserDefaults in an App Group. Analytics events go to the console and, once a key is set in
`Clam/App/Config.swift`, to PostHog (anonymous, no session replay).

## Build

The Xcode project is generated from `project.yml`, so there is no `.xcodeproj` checked in.

```bash
brew install xcodegen
xcodegen generate
open Clam.xcodeproj
```

1. Set your team on all four app/extension targets (Signing & Capabilities).
2. Bundle IDs are `app.getclam.clam` and friends, matching the getclam.app domain.
3. **Simulator** runs everything except real app blocking: onboarding, paywall (StoreKit test
   config), sessions, Live Activity (lock with ⌘L) and the share card all work. Screen Time is
   stubbed there (see `ScreenTimeManager.isSimulator`), so "choose apps" pretends four were
   picked. A **physical iPhone** is needed to see the shield and the block screen.
4. The `Clam` scheme uses `Clam/Resources/Products.storekit`, so the paywall works locally
   without App Store Connect.

**Family Controls entitlement.** Development builds work as soon as the capability is on the
App ID. Distribution needs Apple's approval, per bundle ID, for the app and the shield extension.
Request it on day one: https://developer.apple.com/contact/request/family-controls-distribution

## Core loop

```
Home ──"Clam up"──▶ shield up + Live Activity ──timer ends──▶ shield down ──▶ result card ──▶ share
                              │
                       hold 10s to give up ──▶ streak resets
```

## Where the numbers come from

The "17 years" hook and the 4.5 h/day average are widely cited estimates. The copy lives in
`Clam/Views/Onboarding/OnboardingScreens.swift`. The 40% reduction assumption in
`OnboardingAnswers.assumedReduction` is deliberately conservative. Replace all three with sourced
numbers before submission and cite them in the App Store description.

## Status

Builds and tests green on CI (macOS runner, Xcode 26.6). All thirteen screens captured on an
iPhone 17 Pro Max simulator in `docs/screenshots/` via the Screenshots workflow. Landing page,
privacy and terms live at getclam.app; support@getclam.app forwards to Gmail. Not yet run on a
physical iPhone, so the Screen Time shield and block screen are untested on device. Next: Apple
Developer Program, App IDs, the three Family Controls entitlement requests, then TestFlight.
