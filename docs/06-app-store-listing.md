# App Store listing

Everything below is written to the same belief sequence as onboarding. The listing is the
first onboarding screen.

## Title (30 chars max)

`Clam: Fold to Focus Blocker`

Keyword order matters: the title carries the most weight. "Blocker" and "Focus" are the two
highest-volume category terms.

## Subtitle (30 chars max)

`Close your phone, close apps`

## Promotional text (170 chars, editable without review)

`New for iPhone Duo: fold your phone and your apps stay locked. Timer on the outer screen. One tap, no setup, no willpower needed.`

## Keywords (100 chars, comma-separated, no spaces, don't repeat title words)

`screen time,app blocker,block apps,distraction,digital detox,doomscroll,instagram,tiktok,productivity`

## Description

The first three lines show before "more". They have to carry everything.

```
Fold your phone shut. Your distracting apps stay shut.

Clam locks the apps that steal your time, for exactly as long as you choose. One tap to start.
Close your phone. The timer stays on your lock screen. Open Instagram? Clammed up. Not a feed in sight.

WHY CLAM
• One button. Pick your apps once, then every session is one tap.
• Real blocking. Uses Apple's Screen Time, not a Shortcut you can skip.
• The fold is the ritual. Close the phone, the timer shows on the outer display. Unfolding to
  scroll means seeing the block screen.
• Giving up costs something. Quitting early takes a 10-second hold and resets your streak.
• Nothing leaves your phone. No account. No cloud. No data collection.

HOW IT WORKS
1. Choose the apps that steal your time.
2. Tap Clam up and pick 25, 50 or 90 minutes.
3. Fold or lock your phone. That's it.

WHAT YOU GET BACK
At the average 4.5 hours a day, you spend 68 full days a year on your phone. People who lock
their apps consistently cut that by around 40%. That's 27 days. Every year.

BUILT FOR IPHONE DUO. WORKS ON EVERY IPHONE.
On iPhone Duo the countdown sits on the outer screen while the phone is closed. On every other
iPhone it's on the lock screen and in the Dynamic Island. Same app, same ritual.

Say "Clam up my phone" to Siri, or put Clam on your Action Button.

PRICING
Clam is free to try for 7 days, then $39.99/year, $7.99/month, or $69.99 once for life.
Subscriptions renew automatically unless cancelled at least 24 hours before the end of the
current period. Manage or cancel in Settings > Apple ID > Subscriptions.

Privacy policy: https://getclam.app/privacy.html
Terms of use: https://getclam.app/terms.html
```

## Screenshots (6.9-inch, in this order)

| # | Screen | Caption (top of image, 5 words max) |
|---|---|---|
| 1 | iPhone Duo folded, Live Activity on outer screen | Fold it. It's locked. |
| 2 | Block screen ("Instagram is clammed up · 23 min left") | Open Instagram? Nope. |
| 3 | Home: the one button | One button. That's the app. |
| 4 | Reveal: "68 days every year" → "27 days back" | Get 27 days back a year. |
| 5 | Result card + streak | Streaks you'll want to keep. |
| 6 | Active session ring | Fold. Focus. Unfold. Done. |

Take real screenshots from the simulator for 2 through 6. Screenshot 1 needs a device mockup
of the Duo; Apple's design resources ship one after launch.

## App preview video (15–30s)

Screen recording of the demo in `docs/08-launch-videos.md` video #1, no voiceover, captions on.

## App Review notes

```
Clam is an individual digital-wellbeing app. It uses the Family Controls entitlement in
"individual" mode only: the user picks apps for themselves via FamilyActivityPicker, and
ManagedSettings shields them for the duration of a timer the user starts. No parental
supervision, no accounts, no data leaves the device.

To test: complete onboarding, pick any apps in the picker, and start the 1-minute session on
step 7. The Live Activity appears on the lock screen; opening a picked app shows the shield.
Purchases can be tested with the yearly plan; the 7-day trial is configured in App Store Connect.

The shield extension (app.getclam.clam.shield) only customises the block screen's appearance.
```

## Category

Primary: Productivity. Secondary: Health & Fitness. (Opal and Jomo are both in Productivity.)

## Age rating

4+. No objectionable content.
