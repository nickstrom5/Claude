# Runbook: static site + custom domain + free support email for an iOS app

Reusable for any app. Replace: `APP` (app name), `DOMAIN` (e.g. getclam.app), `GH_USER`
(GitHub username), `REPO` (repo name), `GMAIL` (the Gmail inbox that receives support mail).
Cost: the domain only (~$15/yr for .app at Cloudflare). Everything else is free.

## 1. Domain
- Buy DOMAIN at Cloudflare Registrar (dash.cloudflare.com → Domain Registration). At-cost
  pricing, 1 year is enough. Avoid Squarespace/GoDaddy (3-year defaults, markups).

## 2. Site files (in the repo, folder `/docs`)
- `docs/index.html` landing page (hero, how it works, pricing, FAQ, footer links)
- `docs/privacy.html` privacy policy
- `docs/terms.html` terms (must cover auto-renewing subscriptions and the cancel-24h rule)
- `docs/CNAME` one line containing DOMAIN
- Landing page has one App Store button driven by a JS constant `APP_STORE_URL = ""`:
  empty shows "Get early access" (mailto), set shows "Download on the App Store".
- All mailto links use `support@DOMAIN` or `hello@DOMAIN`.
- SEO files at the site root: `robots.txt`, `sitemap.xml`, `404.html`, `site.webmanifest`, `.nojekyll`,
  `og.png`, `favicon.svg`, `favicon-32.png`, `apple-touch-icon.png`, `icon-192.png`, `icon-512.png`.
  The PNGs and the sized screenshots (`docs/screenshots/web-*.png`) come from `swift scripts/make-brand.swift`.
- Every page carries its own title, description, canonical, Open Graph/Twitter tags and JSON-LD. The
  FAQ text on the index is mirrored word for word in the `FAQPage` JSON-LD: change both or neither.
  Prices appear in the pricing cards, the last FAQ answer and the JSON-LD `offers`; all three must
  match `Products.storekit`.

## 3. GitHub Pages
- Repo → Settings → Pages: Source "Deploy from a branch", branch = main (or yours), folder
  `/docs`. Save.
- Custom domain = DOMAIN. Save. Shows "DNS check in progress" until step 4.
- Account level: github.com/settings/pages_verified_domains → Add DOMAIN. It shows a TXT record
  name (`_github-pages-challenge-GH_USER`) and value. Keep for step 4; click Verify after.

## 4. Cloudflare DNS (DOMAIN → DNS → Records), all **DNS only** (grey cloud, not proxied)

| Type | Name | Content |
|---|---|---|
| A | `@` | 185.199.108.153 |
| A | `@` | 185.199.109.153 |
| A | `@` | 185.199.110.153 |
| A | `@` | 185.199.111.153 |
| CNAME | `www` | `GH_USER.github.io` |
| TXT | `_github-pages-challenge-GH_USER` | value from step 3 |

- Delete any registrar parking A/AAAA/CNAME records on the apex.
- Back in GitHub Pages settings, click Save next to the domain. Green within minutes.
- Tick "Enforce HTTPS" when it appears (up to an hour for the certificate).
- `scripts/cloudflare-setup.sh` in this repo does this section and the next via the API.

## 5. Inbound email (Cloudflare → DOMAIN → Email → Email Routing)
- Enable Email Routing; accept the MX/SPF/DKIM records it adds.
- Destination addresses → add GMAIL → click the verification link Cloudflare emails you.
- Routing rules → `support@DOMAIN` → GMAIL; same for `hello@DOMAIN`. Enable catch-all → GMAIL.

## 6. Outbound email (reply as support@DOMAIN from Gmail)
- Google Account → Security → 2-Step Verification on → App passwords → create one.
- Gmail → Settings → Accounts and Import → "Send mail as" → Add another email address:
  name "APP Support", email `support@DOMAIN`, untick "Treat as alias".
  SMTP `smtp.gmail.com`, port 587, TLS, username = full GMAIL address,
  password = the app password (not the account password).
- Gmail emails a confirmation code to support@DOMAIN, which forwards to GMAIL. Enter it.
- Gmail filter: `to:(support@DOMAIN OR hello@DOMAIN)` → label "APP support", skip inbox.
- Never paste or screenshot the app password; revoke and recreate it if you do.

## 7. Verify
- `https://DOMAIN/privacy.html` loads with a padlock.
- Mail from another address to support@DOMAIN arrives in GMAIL; a reply shows From: support@DOMAIN.

## 8. Use the URLs
- App Store Connect: support URL `https://DOMAIN/`, privacy policy `https://DOMAIN/privacy.html`.
- In-app: paywall footer and settings link to privacy.html and terms.html; feedback → support@DOMAIN.
- Bundle ID convention: reverse of DOMAIN, e.g. `app.getclam.APP` (extensions `.shield`, `.widgets`).

## 9. SEO after launch
- Google Search Console (search.google.com/search-console): add a **Domain** property for DOMAIN and
  verify with the TXT record it gives you (Cloudflare DNS, DNS only). Bing Webmaster Tools
  (bing.com/webmasters): add the site, or import it from Search Console in one click.
- In both, submit the sitemap: `https://DOMAIN/sitemap.xml`. When pages change, update their
  `<lastmod>` in `docs/sitemap.xml`.
- Once the App Store Connect record exists, fill in the App Store ID in two places in
  `docs/index.html`: uncomment `<meta name="apple-itunes-app" content="app-id=APP_ID">` in the
  `<head>` with the numeric Apple ID (the Safari smart banner), and set `APP_STORE_URL` in the script
  at the bottom (switches every button to "Download on the App Store").
- Request indexing: Search Console → URL Inspection → paste `https://DOMAIN/` → Request indexing.
  Repeat for each guide page. In Bing use URL Submission.
- Check the link preview: paste the URL into iMessage or a social post composer and confirm
  `og.png` shows. Validate the structured data at search.google.com/test/rich-results and
  validator.schema.org.
- Do not add `aggregateRating` or review markup until real App Store ratings exist, and then only
  with the real numbers.
- The site screenshots come from `docs/screenshots/`. Several current captures have the iOS
  notification permission alert on top of them; recapture (dismiss the alert first) before using the
  home, session, result or paywall screens on the site, then add them to `shots` in
  `scripts/make-brand.swift`.

## Gotchas
- Orange (proxied) cloud on the A records means GitHub can never issue HTTPS. Must be grey.
- Gmail auto-fills the SMTP server as `smtp.DOMAIN`; it must be `smtp.gmail.com`.
- Too many failed Send-as attempts locks that dialog for about an hour.
- Cloudflare forwarding is inactive until the destination address is verified by email.
- A bounce saying "DNS type mx lookup had no relevant answers" means Email Routing isn't enabled.
