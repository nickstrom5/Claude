# Onboarding + Paywall — screen by screen, with the reason each screen exists

Onboarding moves the user through a belief sequence:

> I have this problem → this app understands my problem → this might actually help me → I want the result → (pay)

Every screen below maps to one of those beliefs. If a screen doesn't move a belief, it gets cut.
This is hypothesis #1, not the final flow. The step enum lives in
`Clam/Views/Onboarding/OnboardingFlow.swift` so reordering is a one-line change.

| # | Screen | Belief it moves | What it does | Why |
|---|---|---|---|---|
| 1 | **Hook** | "I have this problem" | Full-bleed statement: "The average person will spend 17 years of their adult life on a screen." One button: "Not me." | No welcome, no feature list. The first screen is a claim that makes them feel the problem. |
| 2 | **Honesty quiz — hours/day** | "I have this problem" | Slider 1–12h. Defaults to 4.5h (real average). | Making them *state* the number is a small commitment and the input for the reveal. |
| 3 | **Worst apps** | "This app understands me" | Native FamilyActivityPicker: pick the apps that steal your time. | Doubles as the actual configuration step, so there is no separate setup later. |
| 4 | **Triggers** | "This app understands me" | Multi-select: bored, in bed, waiting, procrastinating, anxious, "just checking". | Personalizes copy later and signals we know the behaviour, not just the apps. |
| 5 | **Reveal** | "This might help" | Animated: "At 4.5h/day that's **68 days a year**. People who lock their apps cut it by about a third: that's 23 days back." | The aha. Big number, animated count-up, screenshot-able. |
| 6 | **Permission** | (gate) | Explains Screen Time permission in one sentence, then requests it. | Framed as "so Clam can actually lock the apps you chose", right after they chose them. |
| 7 | **Taste session** | "I want the result" | A live 60-second session. Shield is really on. Live Activity really appears. "Lock your phone. Try opening Instagram." | The product is used *before* the paywall. This is the screen that sells. |
| 8 | **Result** | "I want the result" | "You just clammed up your phone for 1 minute. That's 1 of 23 days you'll get back." Share card offered. | Immediate win + the first shareable artifact. |
| 9 | **Paywall** | (pay) | Hard paywall. Yearly w/ 7-day trial preselected, monthly + lifetime as alternates. | See below. |

## Paywall design decisions

- **Hard paywall, not soft.** The user has already used the product for real. Soft paywalls in
  this category train people that free is enough.
- **Trial-first framing.** Headline is "Try Clam free for 7 days", not "Subscribe". Timeline
  graphic: Today (full access) → Day 5 (reminder) → Day 7 (charged). The reminder toggle is on by
  default and actually schedules a local notification. This pattern consistently lifts trial
  starts because it removes the "I'll forget to cancel" fear.
- **Yearly preselected**, shown as "$1.67/mo, billed $19.99/yr". Monthly at $3.99 exists to make
  yearly obvious. Lifetime at $29.99 catches subscription-haters.
- **Social proof line** sits above the plans: real numbers once we have them; until then the
  Reveal's personalized number ("23 days back") is restated.
- **Close button** appears after 2 seconds, top-left, low contrast. Apple requires dismissal;
  the delay is standard.
- **Restore + Terms + Privacy** in the footer (App Review requires all three).

## What to A/B test first (in order)

1. Hook copy (17 years vs. "You checked your phone 96 times yesterday").
2. Reveal number (days/year vs. hours/week vs. "years of your life").
3. Taste session length (60s vs. 2 min).
4. Paywall: trial toggle on vs. off by default.
5. Price: $19.99 vs. $29.99 yearly.

Everything else waits until these five have a read.
