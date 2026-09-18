# Clam — Strategy

> One sentence: **Fold your phone shut, and your distracting apps stay shut.**

## 1. Why this idea

The research thread's filter is simple: pick a problem people already feel every day, already
Google, already pay to fix, where several competitors are already making $20k+/mo. Screen-time
addiction passes every check, and it is the one category that gets *more* acute with a new,
bigger, more beautiful phone.

| Check | Evidence |
|---|---|
| Daily felt pain | "Screen time" is a built-in iOS feature people already look at and feel bad about. |
| Proven spend | Opal: 4M+ downloads, ~$100/yr pricing. Jomo, one sec, Brick, Roots, Clearspace, Refocus all charge subscriptions. |
| Loud complaints | Reviews across the category repeat three things: too easy to bypass, too complicated, too expensive. |
| 7-second demo | Fold phone → apps locked. Open phone → branded block screen. Timer on the outer screen. Nothing to explain. |
| Shareable result | "I clammed up my phone for 3h 12m today" card. Streaks. Hours saved. Before/after screen-time screenshots. |
| No backend needed for v1 | Screen Time API + StoreKit 2 + Live Activities all run on device. Zero server cost. |

## 2. The iPhone Duo angle (and why it still works on every iPhone)

The Duo ships October 23 with a 7.6-inch inner display and a 5.4-inch outer display. Its whole
pitch is "open it up and get lost in it". Our pitch is the opposite motion: **closing the phone is
the commitment.**

- **Fold to focus.** Start a session, close the phone. The Live Activity (lock screen + Dynamic
  Island) shows the countdown on the outer 5.4-inch display. Unfolding to the big screen and
  tapping Instagram hits our branded shield.
- **Every other iPhone** gets the exact same product: the Live Activity sits on the lock screen
  and in the Dynamic Island. "Fold" just becomes "lock".
- We do **not** depend on any fold-state API. Nothing in the app breaks if Apple never exposes one.
  It is a marketing frame and a Live Activity, both of which exist today.

Launch timing: the Duo lands in reviewers' hands the week of October 23. Every tech creator will be
making "first apps to install on the iPhone Duo" content. That is a free distribution window we
should be live for.

## 3. Positioning against the category

| Competitor | What they do well | What users hate | Clam's answer |
|---|---|---|---|
| Opal | Brand, deep scheduling, stats | Price (~$100/yr), heavy, "too many features" | One button. One price a third of theirs. |
| Jomo | Cheaper, Mac support | Setup complexity | Zero-config: pick apps once, then one tap. |
| one sec | Friction (breathing pause) | Doesn't actually block; needs Shortcuts setup | Real blocking, no Shortcuts. |
| Brick | Physical NFC brick is a great ritual | $59 hardware, forget the brick | The *phone itself* is the brick: fold it. |
| ScreenZen | Free | Free means no push to change; easy to skip | Paid means committed. Early-exit costs a 10-second hold and your streak. |

**One-line differentiation:** Clam is the simplest real blocker on iOS. Choose apps once, then
every session is one tap and one fold. The ritual is the product.

## 4. Product (v1 = onboarding + paywall + core loop, nothing else)

**Core loop**
1. Tap **Clam up** → pick 25 / 50 / 90 min, or any length from 5 min to 4 h.
2. Shield goes up on your chosen apps immediately (ManagedSettings). Live Activity starts.
3. Lock / fold the phone. Timer stays visible on the outer screen.
4. Session ends → shield drops → result card ("2h 14m clammed up · 6-day streak") → share.
5. Early exit is allowed but *costs something*: a 10-second hold and your streak resets.

Entry points besides the app: Siri ("Clam up my phone"), the Shortcuts app, the Action Button,
and a small Home Screen widget with a "Clam up" button. All run the same intent. Each one is a
video (see `playbook/08-launch-videos.md`).

**What is deliberately not in v1:** schedules, website blocking UI, family plans, Mac app, stats
beyond streak + minutes, AI anything. Every one of these is a v1.x candidate only if reviews ask.

## 5. Monetization

Subscription, hard paywall at the end of onboarding (after the user has already completed a live
60-second session and seen the shield work).

| Plan | Price | Notes |
|---|---|---|
| Yearly | **$39.99** with 7-day free trial | Default selection. ~$3.33/mo framing. |
| Monthly | $7.99 | Anchor to make yearly look obvious. |
| Lifetime | $69.99 | For the "I hate subscriptions" cohort; also boosts yearly. |

Why these numbers: Opal charges ~$100/yr, so $39.99 reads as "the honest one" while still being
a real business. A 7-day trial with a "remind me before it ends" toggle is the single most
consistently tested paywall pattern in the category.

**Unit-economics targets (month 3):**

| Metric | Target |
|---|---|
| Install → onboarding complete | 60% |
| Onboarding complete → trial start | 25% |
| Trial → paid | 40% |
| Blended install → paid | ~6% |
| Yearly ARPU after Apple's cut (small-business 15%) | ~$34 |
| Break-even CPI at 6% install→paid | ~$2.00 |

At 10,000 installs/mo (achievable from organic short-form alone in this category), that is
~600 paying users/mo, ~$20k/mo run-rate by month 3 before retention compounding.

## 6. Distribution plan (starts before the app is approved)

See `playbook/03-distribution.md` for hooks, formats and the creator brief. Short version:

1. **Week 0–1:** study 20 winning videos from Opal, Brick, one sec, Jomo, "digital detox"
   creators. Save hook, first frame, time-to-product, CTA.
2. **Week 1–2:** post 3 videos/day across 2 accounts using the proven formats with Clam demos.
   Volume over cleverness. Track by the tier ladder (views → downloads → trials → paid).
3. **Week 3 (Duo launch week):** "first apps for the iPhone Duo" and "the iPhone Duo made my
   screen time worse, so I built this" angles. Seed 10 small creators (5k–50k followers, proven
   500k+ view videos).
4. **Week 4+:** put paid spend only behind the 3–5 organic concepts that produced trials.

## 7. Metrics that matter (instrument from day 1)

Events are already defined in `Clam/Services/Analytics.swift`. Funnel to watch weekly:

`app_open → onboarding_step(n) → screen_time_authorized → taste_session_completed → paywall_shown → trial_started → paid → session_started (D1, D7) → session_completed`

The ratio that decides everything: **taste_session_completed / onboarding_started.** If people
do the 60-second session, they convert. If they drop before it, fix the screens before it.

## 8. Risks and how we handle them

| Risk | Mitigation |
|---|---|
| **Family Controls entitlement** approval takes days to weeks in 2026 | Request it on day 1 (see `playbook/04-launch-checklist.md`). Build and TestFlight-test with the development entitlement in the meantime. |
| Apple rejects for "too similar" | Not a real rejection category for blockers; dozens exist. Keep the shield copy clean and non-manipulative. |
| Users bypass by deleting the app | Same for every competitor. The 10-second hold + streak loss is the friction; we don't promise "unbreakable". |
| Duo fold-state has no public API | We never depend on it. Live Activity on the outer screen is the feature. |
| Category is crowded | That's the validation. Win on simplicity, price, and the fold ritual. |

## 9. 30-day plan

| Days | Deliverable |
|---|---|
| 1 | Request Family Controls (distribution) entitlement. Create App Store Connect record, products, StoreKit config. |
| 1–5 | Build from this repo: onboarding, taste session, paywall, home, session, share card. TestFlight to 10 friends. |
| 5–10 | Fix the drop-off screen. Record 30 demo clips. Start posting. |
| 10–14 | Submit for review the moment the entitlement lands. Post daily. |
| 15–23 | Launch. Duo launch week content push. Seed creators. |
| 24–30 | Read every review and cancellation reason. Ship one fix per day. Put $20/day behind top organic concept. |
