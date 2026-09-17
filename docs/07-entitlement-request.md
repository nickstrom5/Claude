# Family Controls (Distribution) entitlement request

Form: https://developer.apple.com/contact/request/family-controls-distribution

Submit **three** requests: the app bundle ID, the shield extension and the monitor extension.
The widget extension does not need it. Do this before anything else; in 2026 approvals are
taking from four business days to several weeks, and TestFlight is blocked until it lands.

Apple is checking three things: the core purpose genuinely needs Screen Time, the use case is
personal digital wellbeing or parental control, and you are not harvesting usage data. Say
all three plainly.

## Fields

**App name:** Clam

**Bundle ID:** `com.clamapp.ios` (then `com.clamapp.ios.shield`, then `com.clamapp.ios.monitor`)

**Website:** https://nickstrom5.github.io/Claude/ (or the marketing site once it exists)

**Describe your app and how it uses Family Controls:**

```
Clam is a personal digital-wellbeing app for individual users (not parental control). The user
chooses the apps they find distracting, then starts a timed focus session of 25, 50 or 90
minutes. For the duration of that session the chosen apps are shielded so the user cannot open
them. When the timer ends, the shield is removed automatically.

The app uses:
- FamilyControls: AuthorizationCenter.requestAuthorization(for: .individual) and
  FamilyActivityPicker so the user selects their own apps. Authorization is always individual;
  the app never requests .child.
- ManagedSettings: ManagedSettingsStore.shield to restrict the selected applications and
  categories only while a session the user started is running.
- ManagedSettingsUI (extension bundle com.clamapp.ios.shield): a ShieldConfigurationDataSource
  that customises the appearance and text of the shield so the user understands why the app is
  blocked and how long remains.
- DeviceActivity (extension bundle com.clamapp.ios.monitor): a DeviceActivityMonitor whose only
  job is to remove the shield when the session's scheduled end time is reached, so restrictions
  never outlive the timer even if the app is not running. It does not observe or report usage.

The app does not use DeviceActivity reports, does not read or record which apps the user opens,
and does not collect, transmit or sell any usage data. All state is stored locally in an App
Group container on the device. There is no account and no server.

The Family Controls capability is the core of the product: without the ability to shield apps,
the app has no function.
```

**Is your app a parental control app?** No. Individual use only.

**Will your app be distributed on the App Store?** Yes.

## After you submit

- You get an email with a case number. Save it.
- Meanwhile, add the Family Controls capability to the App ID in the developer portal and to
  the targets in Xcode. Development builds on your own device work immediately.
- If nothing arrives in 10 business days, reply to the case email once, politely, with the
  bundle IDs. Forum reports show follow-ups do get answered.
- Once approved, the distribution profile regenerates automatically. Archive and upload to
  TestFlight the same day.
