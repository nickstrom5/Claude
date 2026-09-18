# Launch checklist

## Day 1 (do these before writing another line of code)

- [ ] Create the App ID `app.getclam.clam` in the Apple Developer portal (matches `project.yml`).
- [ ] Enable **App Groups** (`group.app.getclam.clam`) on the app and all three extensions.
- [ ] **Request the Family Controls (Distribution) entitlement** for the main app, the shield
      extension (`app.getclam.clam.shield`) and the monitor extension (`app.getclam.clam.monitor`).
      Requests are per bundle ID.
      Form: https://developer.apple.com/contact/request/family-controls-distribution
      Draft answers are in `docs/07-entitlement-request.md`.
      In 2026 this is taking days to weeks, so this is the critical path. Development builds
      work without it.
- [ ] App Store Connect: create the app, three in-app purchases matching `Clam/Resources/Products.storekit`
      (`clam.yearly`, `clam.monthly`, `clam.lifetime`), one subscription group, 7-day free trial
      intro offer on yearly.
- [ ] Turn on GitHub Pages: repo Settings → Pages → Deploy from a branch → this branch, folder `/docs`.
      Under "Custom domain" enter `getclam.app` (the `docs/CNAME` file already says so) and tick
      "Enforce HTTPS" once the certificate appears.
- [ ] Run `CF_TOKEN=<token> bash scripts/cloudflare-setup.sh` on a Mac (needs `brew install jq`). It does
      the DNS records, the GitHub verification TXT and all the email routing below in one go.
      Manual equivalent:
- [ ] Cloudflare DNS for getclam.app (DNS → Records), all **DNS only** (grey cloud):
      `A @ 185.199.108.153`, `A @ 185.199.109.153`, `A @ 185.199.110.153`, `A @ 185.199.111.153`,
      `CNAME www nickstrom5.github.io`. Then https://getclam.app/privacy.html and /terms.html
      resolve, which is what the app and the App Store listing link to.
- [ ] GitHub account-level domain verification (github.com/settings/pages_verified_domains):
      TXT `_github-pages-challenge-nickstrom5` = `f608cf247e8b8dbac47ce879e36ee9`, then click Verify.
- [ ] Cloudflare Email Routing (Email → Email Routing): add destination Nickstrom5@gmail.com and
      confirm the verification mail, then custom addresses `support@getclam.app` and
      `hello@getclam.app`, plus a catch-all, all forwarding to that inbox. Cloudflare adds the MX
      records itself.
- [ ] Gmail: Settings → Accounts → "Send mail as" → add `support@getclam.app`, SMTP server
      `smtp.gmail.com`, port 587, your Gmail address and an App Password
      (myaccount.google.com → Security → App passwords). Replies then come from the app's address.
- [ ] Gmail filter: `to:(support@getclam.app OR hello@getclam.app)` → apply label "Clam support",
      skip inbox.

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
