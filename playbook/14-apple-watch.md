# Apple Watch: what fits Clam, what doesn't

Not for v1. This is the shortlist for v1.2, written now so the decision is on record and the
free parts get verified on device rather than assumed.

Every item below names the funnel metric it moves, per the rule in `CLAUDE.md`.

## The strategic argument

Clam's premise is that picking up the phone is the failure. So the phone is the worst place to
put the "start focusing" button, and the wrist is the best one. A watch app is not a companion
here, it is the one surface that does not contradict the product.

The same logic caps the scope: the watch should make a session **easy to start and impossible to
quit**. Quitting stays a 10-second hold on the phone. That asymmetry is the whole thesis, and it
is also why this is not a port of the iPhone app.

## Probably free, verify first

The Live Activity we already ship is mirrored into the Apple Watch Smart Stack by the system.
If that works for `ClamActivityAttributes` with no extra code, the countdown is already on the
wrist and we can say so in the App Store listing.

- [ ] On a real iPhone + Watch: start a session, lock the phone, raise the wrist. Does the
      countdown appear in the Smart Stack? Screenshot it.
- [ ] Check how `ClamLiveActivity`'s compact layout renders there; the 96pt and 80pt fixed
      frames in `ClamWidgets/ClamLiveActivity.swift` may be wrong for that width.

Costs nothing, may already be a feature. Do this before writing a line of watchOS code.

## The three that earn their build

**1. Start a session from the wrist.** A watchOS app with three buttons: 25, 50, 90. Tapping one
asks the iPhone to start the session. Moves *sessions per user per week*, and therefore D7
retention, by removing the contradiction at the moment of commitment.

**2. A watch face complication.** Streak when idle, time remaining during a session. Moves *D7
retention*: the streak is the retention mechanic and a complication is the cheapest place to
keep it in view. Also the closest thing to free advertising Clam has.

**3. End-of-session haptic on the wrist.** Today the session ends with a phone notification,
which hands the phone back to the user at the exact moment they were succeeding. A wrist tap
ends the session without that. Moves *completion rate*.

## What not to build

- **Blocking from the watch.** FamilyControls and ManagedSettings are iOS-only. The watch can
  ask the phone to act; it cannot shield anything itself.
- **Giving up from the watch.** Deliberately absent. Friction is the product.
- **A standalone watch app.** Without the phone there is nothing to lock. Requiring the phone in
  range is correct, not a limitation to engineer around.
- **Activity rings, workouts, mindfulness sessions.** Different product. This is feature creep
  wearing a health halo.

## What it actually costs

| Piece | Work |
|---|---|
| watchOS app target in `project.yml`, shared models | Small |
| WCSession both ways: watch asks to start, phone reports state | The real work. App Groups do not span devices |
| Complication (WidgetKit, `accessoryCircular` / `accessoryCorner`) | Small once state is shared |
| Reachability: phone locked, out of range, app not running | Where the bugs live |
| Handling the start when the phone is unreachable | Queue it, or fail honestly. Do not pretend |

Realistically one to two weeks, most of it in WatchConnectivity edge cases rather than UI.

## The call

Ship v1 without it. The watch does not fix the two things that decide whether Clam works:
whether people finish sessions, and whether they come back on day 7. Once PostHog has a month
of data, if completion rate is high but sessions per week are low, the wrist start is the right
next build. If completion rate is the weak number, the fix is in the phone app, not on a watch.

Verify the free Smart Stack mirroring during device testing either way.
