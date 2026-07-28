# DryckesRanken – Agent Instructions

## Project Overview
Flutter web app for rating and ranking beverages. Deployed via **Vercel** with auto-deploy from GitHub.

## Tech Stack
- **Framework**: Flutter (Web)
- **Database**: Firebase Firestore
- **Auth**: Firebase Authentication (Google Sign-In)
- **Hosting**: Vercel (auto-deploys from `main` branch on GitHub)
- **Repo**: https://github.com/Bjornelmers/dryckesranken

## How to Deploy
**DO NOT use `firebase deploy`** — Firebase Hosting is NOT used for this app.
The `firebase.json` file only contains Flutter SDK config, not hosting config.

### Deployment steps:
1. Make code changes
2. Build: `/Users/sofiaelmers/development/flutter/bin/flutter build web --release`
3. Commit and push to GitHub:
   ```bash
   git add <changed files>
   git commit -m "your message"
   git push origin main
   ```
4. Vercel automatically detects the push and redeploys (takes ~2–3 minutes)

### Flutter binary location
```
/Users/sofiaelmers/development/flutter/bin/flutter
```
(Not on PATH by default — use full path)

### Git remote
```
https://github.com/Bjornelmers/dryckesranken.git
```
Credentials are embedded in the remote URL in `.git/config`.

## Key Files
- `lib/ui/features/dashboard/views/dashboard_view.dart` — Main screen with FAB
- `lib/ui/features/ranking/views/add_drink_view.dart` — Add/scan drink form
- `lib/ui/features/ranking/views/batch_add_drink_view.dart` — Bulk add
- `lib/ui/features/social/views/user_profile_view.dart` — User profile
- `lib/ui/core/theme.dart` — App theme/colors
- `vercel.json` — Vercel routing config (SPA rewrites)

## Language
The app UI is in **Swedish**. All user-facing text, error messages, labels etc. should be in Swedish.

## Notes
- The app is a Flutter **web** app, not native iOS/Android
- It runs in a browser on mobile (iOS Safari / Android Chrome)
- `dart:html` is used for web-specific file input handling
- The `flutter/` folder in the repo root is a local Flutter SDK copy used by Vercel's build script (`build.sh`)
