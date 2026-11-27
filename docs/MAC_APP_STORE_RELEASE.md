# Mac App Store Release Guide — FocusBar

## 1. Automated Pre-Flight Status

The codebase and Xcode project have been prepared for Mac App Store submission:

- **External Updater Stripped for App Store (`-DMAC_APP_STORE`)**: `Makefile` `archive` / `export-appstore` passes `-DMAC_APP_STORE`, compiling out `UpdateCheckService` and the "Check for Updates" UI in `SettingsView` / `SettingsViewModel` (required by App Review Guideline 2.4.5(vii)). Direct/GitHub `make release` builds retain update checking.
- **App Store Entitlements (`FocusBar/FocusBar-AppStore.entitlements`)**: App Sandbox, User-Selected Files (read/write), Calendars, and Reminders. `com.apple.security.network.client` is omitted in App Store builds since no network requests are made.
- **Privacy Manifest (`FocusBar/PrivacyInfo.xcprivacy`)**: Declares `NSPrivacyAccessedAPICategoryUserDefaults` (`CA92.1`), `NSPrivacyTracking = false`, and `NSPrivacyCollectedDataTypes = []`.
- **Export Compliance (`Info.plist` build settings)**: `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` and `INFOPLIST_KEY_NSHumanReadableCopyright` set in `FocusBar.xcodeproj/project.pbxproj`.
- **Category & Usage Descriptions**: `public.app-category.productivity`, `LSUIElement = YES`, and EventKit usage descriptions (`NSCalendars*`, `NSReminders*`) configured.
- **Privacy Policy & Support**: `docs/privacy.html` (published at `https://aungmyokyaw.github.io/FocusBar/privacy.html` once pushed).
- **App Store Screenshots**: `docs/appstore-screenshots/` (`2880x1800` opaque 16:10 PNGs, no alpha channel).

---

## 2. App Store Connect Metadata (Ready to Paste)

- **Platform**: macOS
- **Name**: `FocusBar`
- **Subtitle** (≤30 chars): `Menu Bar Pomodoro Timer`
- **Bundle ID**: `aungmyokyaw.com.FocusBar`
- **SKU**: `focusbar-macos`
- **Primary Category**: `Productivity`
- **Secondary Category**: `Utilities`
- **Privacy Policy URL**: `https://aungmyokyaw.github.io/FocusBar/privacy.html`
- **Support URL**: `https://github.com/AungMyoKyaw/FocusBar/issues`
- **Marketing URL**: `https://aungmyokyaw.github.io/FocusBar/`
- **Keywords** (≤100 chars): `pomodoro,timer,focus,menubar,productivity,time tracking,reminders,calendar,deep work,study`
- **Age Rating**: `4+` (All "None" in questionnaire)
- **App Privacy**: `Data Not Collected` (`NSPrivacyTracking = false`)
- **Export Compliance**: `No` (`ITSAppUsesNonExemptEncryption = NO` already embedded)
- **Pricing**: Free (`$0.00`)

### Description

> FocusBar is a native macOS menu bar Pomodoro timer designed for distraction-free deep work.
>
> **Menu Bar & Floating Timer**
> - Live countdown and progress right in your macOS menu bar (`LSUIElement`, no Dock clutter).
> - Optional draggable floating timer widget for always-visible focus sessions.
> - Global keyboard shortcuts (`Ctrl+Opt+Cmd+S/R/N`) to start, pause, reset, or skip from anywhere.
>
> **Tasks, Calendar & Focus Guard**
> - Connect Apple Reminders to pick tasks, log focus time, and mark reminders complete.
> - Optional Apple Calendar sync to log completed focus blocks.
> - Distraction Guard notifies you when you switch to blocked apps during a focus session.
> - Idle detection detects when you step away and lets you trim idle time.
>
> **Offline Soundscapes & Analytics**
> - Built-in offline ambient soundscapes (rain, brown noise, lo-fi hum) and completion chimes.
> - SwiftData-powered daily, weekly, and monthly charts, heatmaps, XP levels, streaks, and achievements.
> - Export and import your focus history as JSON or CSV anytime.
> - 100% local-first: zero accounts, zero tracking, zero ads.

### App Review Notes

> FocusBar is a macOS menu bar utility (`LSUIElement = YES`), so it appears in the top-right macOS menu bar rather than the Dock. On first launch, an onboarding window opens automatically to introduce the app and optional permissions.
>
> - **Apple Reminders & Calendar**: Requested lazily only when the user enables Reminders or Calendar Sync in onboarding or Settings. All data stays strictly on-device.
> - **No account required**: FocusBar works completely offline with no sign-in.

---

## 3. Build, Archive & Upload Commands

```bash
# Run unit tests
make test

# Build & archive for Mac App Store
make archive

# Export .pkg for App Store Connect
make export-appstore
```

If `make export-appstore` reports a missing **Apple Distribution** or **Mac Installer Distribution** certificate, open **Xcode → Settings → Accounts → Manage Certificates → `+`** and create both **Apple Distribution** and **Mac Installer Distribution** for team `ZSQUH7GKC5`, then re-run `make export-appstore` and upload via **Xcode Organizer** or **Transporter**.
