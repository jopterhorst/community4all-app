# Community4All app

This fork of [humhub/app](https://github.com/humhub/app) is the Victory4All Community4All app for Android and iOS. It opens one site only, the Community4All HumHub, and adds push notifications, share-into and downloads on top of the website.

HumHub's app runs as a single-site ("flavored") app whenever its package name is not `com.humhub.app`. It reads the site from `assets/.env`. The Dart code (`lib/`) therefore stays exactly as upstream, and this fork only changes the brand files:

| What | Where |
| --- | --- |
| Site URL, name and colours | `assets/.env`, written by `scripts/set-domain` |
| Package / bundle ID `com.victory4all.community` | `android/app/build.gradle` (`applicationId`), `ios/Runner.xcodeproj/project.pbxproj` |
| App name "Community4All" | `AndroidManifest.xml`, `ios/Runner/Info.plist`, `project.pbxproj` |
| iOS app group `group.com.victory4all.community` (shared with the Share Extension) | `project.pbxproj` (`CUSTOM_GROUP_ID`), the three `.entitlements` files |
| Deep-link host | `AndroidManifest.xml` (App Links), `ios/Runner/*.entitlements` (`applinks:`), written by `scripts/set-domain` |
| Icon and splash | `branding/mark.svg`, rendered by `branding/render-icons.sh` into the Android `mipmap-*` folders and the iOS asset catalog |
| Android push banner and status-bar icon | `android/app/src/main/kotlin/com/victory4all/community/Community4AllApplication.kt`, `AndroidManifest.xml`, `drawable-*/ic_notification.png` |
| Test builds | `.github/workflows/community4all-build.yml` |

## Keeping up with HumHub

On GitHub, use "Sync fork" (or `git pull upstream master`). Upstream changes to `lib/`, `assets/` and `pubspec.*` merge cleanly because we don't touch them. If upstream edits one of the files in the table above, keep our values.

Upstream's own workflows (`version-release`, `scheduled-release`, `sync-to-flavored-repos`) are disabled in this fork's Actions settings, because they publish HumHub's app.

## Changing the site

```bash
scripts/set-domain community.example.org
```

Commit and push the change; CI then builds a new app. An installed app keeps opening the old site until it is updated.

## Push notifications

Push goes through Victory4All's own Firebase project:

1. **Create the project.** Create a Firebase project and add an Android app and an iOS app, both with ID `com.victory4all.community`.
2. **Add the config to CI.** Store `google-services.json` and `GoogleService-Info.plist` base64-encoded as the repository secrets `FIREBASE_GOOGLE_SERVICES_JSON_BASE64` and `FIREBASE_GOOGLE_SERVICE_INFO_PLIST_BASE64`, e.g. `base64 -i google-services.json | gh secret set FIREBASE_GOOGLE_SERVICES_JSON_BASE64`. Without these secrets CI uses the placeholders in `.github/firebase-placeholder/`: the app works, but no push.
3. **Configure the site.** In HumHub, open Administration → Modules → Push Notifications (`fcm-push`) and paste a Firebase service-account key. Get it from Project settings → Service accounts → Generate new private key.
4. **iPhone only.** Push also needs an APNs key from the Apple Developer account, uploaded under Firebase → Project settings → Cloud Messaging.

The app tells HumHub its package name, and HumHub then sends through the Firebase project configured in step 3.

On Android, pushes arrive in the app's own high-importance "Notifications" channel, so they pop up as a banner. That channel is created in `Community4AllApplication.kt` and set in `AndroidManifest.xml`. The status bar shows the white mark `ic_notification`, rendered by `branding/render-icons.sh`.

### Testing push without Firebase

`scripts/simulate-push` delivers a notification to the app on the iOS Simulator or an Android emulator. It sends what HumHub would: the site name as the title, the notification text, and the page to open when the notification is tapped.

```bash
scripts/simulate-push ios 'Thandeka Nkosi sent you a new message' https://community4all.jopterhorst.nl/mail/mail/index
scripts/simulate-push android 'Thandeka Nkosi sent you a new message' https://community4all.jopterhorst.nl/mail/mail/index
```

Android needs an emulator image without Play Store (a "Google APIs" image), because the script uses `adb root`. The script tests how the app shows and opens notifications. It does not test whether HumHub sends them.

## Test builds

Every push to `master` builds:

- **`community4all-android`**: an APK to install on a phone. Allow "install unknown apps".
- **`community4all-ios-simulator`**: unzip it and drag `Runner.app` onto a running iOS Simulator.

Both are under the run's Artifacts in the Actions tab. The APK is signed with the upload key in the `PLAYSTORE_*` secrets if set, otherwise with a debug key.

The upload key (`keystore.jks` plus its passwords) must be backed up: Google Play only accepts updates signed with it.

## Before the stores (later)

- **Accounts.** Google Play developer account ($25 once). Apple Developer Program ($99 a year; an organisation account needs a D-U-N-S number).
- **Final domain.** Run `scripts/set-domain` with the permanent domain.
- **Version numbers.** `android/app/build.gradle` has a fixed `versionCode`/`versionName`. Upstream's `version-release.yml` sets them per release, so copy that approach.
- **Deep-link files.** The site must serve `/.well-known/assetlinks.json` and `/.well-known/apple-app-site-association` for this app before links open in it.
- **Store listings.** Name, screenshots, the privacy policy URL (the POPIA notice) and a test account for the reviewers.
- **Apple review.** Mention native push, share-into and downloads in the notes, so the app isn't rejected as a plain website wrapper (guideline 4.2).
- **License.** humhub/app has no LICENSE file. Confirm with HumHub that a branded build may be published.
