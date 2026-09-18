# Roadmap after v1

Rule from the research: ship the core loop, then let reviews, cancellations and the funnel tell
you what to build. Everything here is sequenced by the metric it moves and by what it costs to
keep the "no account, nothing leaves your phone" promise.

## 1.1 Records and badges (built, local only)

- Personal bests: longest session, longest streak, best day.
- Ten badges: first session, 3/7/30/100-day streaks, 10 and 100 hours, 2-hour and 4-hour
  sessions, 100 sessions.
- Surfaces: a "New record" / "Badge unlocked" chip on the result screen, and a Records section
  with the badge grid in Settings. Unearned badges stay visible so the next goal is obvious.
- Metric: D7/D30 retention and share rate.
- Next: a badge-specific share card ("7 days. Clammed up.") once we see which badges people
  screenshot.

## 1.2 Friends, leaderboards, challenges: Game Center, not a backend

The question is not whether social features help retention (they do) but how to add them
without an account system, a server, and a privacy policy rewrite. Apple already runs one:

| Want | Game Center gives | Cost to us |
|---|---|---|
| Badges that sync | Achievements (GKAchievement) | Map our ten badges 1:1. A day. |
| Weekly leaderboard | Leaderboards, recurring weekly (GKLeaderboard) | Report "minutes clammed up" per session. A day. |
| Friend list | Game Center friends (GKLocalPlayer.loadFriends) | Free. Users manage friends in Settings → Game Center. |
| Daily/weekly challenge with friends | Game Center Challenges (iOS 26+): a player challenges friends on a leaderboard score over a window | Requires iOS 26 for challengers; older users still see leaderboards. A few days. |
| Identity, privacy, moderation | Apple's | Zero. Nothing about a user touches our infrastructure. |

Design constraints:
- Opt-in. Game Center sign-in appears only when the user opens Records → "Compare with friends".
  Never during onboarding; the core loop stays one button.
- Report minutes, never which apps were locked. Scores are integers, no metadata.
- App Review: Game Center in a non-game is allowed; keep the leaderboard framed as "time
  reclaimed", not points.
- Metric: K-factor (challenge invites per active user) and D30.

Fallback if Game Center proves too game-flavoured for the brand: CloudKit shared records with
the user's iCloud identity, still no server of ours. Only if the Game Center version measurably
underperforms.

## 1.3 Candidates that depend on evidence

Only if reviews or cancellation reasons ask for them, in this order:
1. Scheduled sessions (e.g. every weeknight 9pm). Most-requested feature in the category.
2. Website blocking picker (the Screen Time API already supports it; UI is the work).
3. Apple Watch: start a session from the wrist, countdown complication.
4. Family plan pricing.

## Not planned

- AI anything. Stats dashboards beyond the week chart. A Mac app. Android until iOS is profitable.
