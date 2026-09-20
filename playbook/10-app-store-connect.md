# App Store Connect setup, step by step

Do these in order. Steps 1–3 are on developer.apple.com, the rest on appstoreconnect.apple.com.
Total time about 90 minutes if the Developer Program is already active.

## 1. Developer Program

- Enroll at developer.apple.com/programs ($99/yr). Individual is fine to start; you can
  transfer to a company later. Approval is usually same-day, sometimes 48 hours.
- Until this is active nothing below is possible, and Family Controls can't be requested.

## 2. Identifiers (developer.apple.com → Certificates, Identifiers & Profiles → Identifiers)

Create four App IDs, explicit (not wildcard):

| Bundle ID | Description | Capabilities to tick |
|---|---|---|
| `app.getclam.clam` | Clam | App Groups, Family Controls, (Push Notifications not needed) |
| `app.getclam.clam.shield` | Clam Shield | App Groups, Family Controls |
| `app.getclam.clam.monitor` | Clam Monitor | App Groups, Family Controls |
| `app.getclam.clam.widgets` | Clam Widgets | App Groups |

Then Identifiers → App Groups → register `group.app.getclam.clam`, and assign it to all four
App IDs (edit each App ID → App Groups → Configure).

Family Controls here is the *development* capability. It lets you run on your own devices
immediately. Distribution still needs step 3.

## 3. Family Controls distribution requests

Three requests, text in `playbook/07-entitlement-request.md`, one per bundle ID (app, shield,
monitor). Form: https://developer.apple.com/contact/request/family-controls-distribution
Note the case numbers. Everything else can proceed while waiting.

## 4. Create the app record (App Store Connect → My Apps → +)

- Platform: iOS. Name: **Clam** (this is the reserved App Store name; if it's taken, use
  "Clam: Fold to Focus"). Primary language: English (U.S.).
- Bundle ID: `app.getclam.clam`. SKU: `clam-ios`. User access: Full.

## 5. Agreements, tax and banking (App Store Connect → Business)

- Accept the **Paid Apps Agreement**. Without it, in-app purchases won't load in TestFlight or
  production, and purchases fail with an unhelpful error.
- Add a bank account and complete the US tax form (W-9 if US-based). Payouts start 45 days
  after the end of the month a sale happens.
- Under Business → Small Business Program, apply. Apple's cut drops from 30% to 15% while
  revenue is under $1M/yr. Takes a few days, worth doing now.

## 6. In-app purchases (My Apps → Clam → Monetization → Subscriptions / In-App Purchases)

**Subscription group** "Clam Pro". Both subscriptions go in it.

| Reference name | Product ID | Type | Price (US) | Intro offer |
|---|---|---|---|---|
| Yearly | `clam.yearly` | Auto-renewable, 1 year | $19.99 | Free trial, 7 days, all territories, new subscribers |
| Monthly | `clam.monthly` | Auto-renewable, 1 month | $3.99 | none |
| Lifetime | `clam.lifetime` | Non-consumable | $29.99 | n/a |

Product IDs must match `Clam/Services/StoreManager.swift` exactly.

For each product:
- Subscription level: Yearly = 1, Monthly = 2 (same group, yearly ranks higher so upgrades
  from monthly are treated as upgrades).
- Localization (en-US): display name "Clam Yearly" / "Clam Monthly" / "Clam Lifetime",
  description one line ("Full access, billed yearly." etc.).
- Review screenshot: any screenshot of the paywall from the simulator. Required before
  submission, ignored by users.
- Subscription group localization: name "Clam Pro", app name "Clam".

Price: choose the US price and let Apple's pricing equalize other territories.

## 7. App Privacy (App Store Connect → Clam → App Privacy)

Answer honestly for the analytics setup in `Config.swift`:
- Data collected: **Product Interaction** and **Crash Data** (PostHog lifecycle + funnel events)
  → "Analytics" purpose, **not** linked to identity, **not** used for tracking.
- Everything else: not collected. No contact info, no identifiers, no usage of apps the user
  locks (Apple's Screen Time tokens are opaque and never leave the device).
- Privacy policy URL: https://getclam.app/privacy.html

## 8. App information

- Category: Productivity (primary), Health & Fitness (secondary).
- Age rating: complete the questionnaire, all "None" → 4+.
- Support URL: https://getclam.app/support.html Marketing URL: same.
- Copyright: 2026 <your name>.

## 9. Version 1.0 page

Paste from `playbook/06-app-store-listing.md`: subtitle, promotional text, description, keywords.
Upload the six screenshots (6.9-inch required; Apple scales down for smaller phones).
App Review Information: contact details, and the review notes from the listing doc. No
sign-in required.

## 10. TestFlight (once the distribution entitlement is approved)

- Xcode → Product → Archive → Distribute → App Store Connect → Upload. Xcode handles
  signing when "Automatically manage signing" is on for all four targets.
- Add yourself and ten friends as internal testers (no review needed). External testers
  need a one-time beta review, usually under 24 hours.
- Sandbox purchases: Users and Access → Sandbox → Testers → create a sandbox Apple ID. On the
  test phone, Settings → App Store → Sandbox Account → sign in with it. Trials and renewals
  run on an accelerated clock (a 1-year sub renews every hour) so you can test the flow.

## 11. Offer codes for creators (after launch)

Monetization → Subscriptions → Clam Yearly → Offer Codes → create a one-time-use batch per
creator (e.g. 100 codes, 1 month free). Codes redeem at apps.apple.com/redeem and are the
cleanest way to attribute trials to a creator.

## 12. Submit

- Build attached, all metadata complete, IAPs in "Ready to Submit" state and attached to the
  version (they review with the first build).
- Export compliance: "No" to encryption beyond HTTPS (already set via
  `ITSAppUsesNonExemptEncryption` in `project.yml`).
- Release: manual, so launch day is your choice, not Apple's.
