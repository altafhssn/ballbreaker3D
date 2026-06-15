# Apple App Store Submission Checklist — Smash Breaker (Windows-only)

Final builds for iOS go through GitHub Actions on Apple's macOS runners —
you never need a Mac. Detailed setup is in `GITHUB_ACTIONS_IOS_SETUP.md`;
this file is the high-level submission flow.

---

## ✅ PREPARED (in this repo)

| Asset | Location |
|---|---|
| Xcode project (offline copy, for reference) | `builds/ios/` |
| App Store icon 1024×1024 | `store_assets/appstore_icon_1024.png` (also baked into the project) |
| Privacy policy text | `store_assets/privacy_policy.md` (host the same URL as Play) |
| Bundle ID | `studio.strawhat.smashbreaker` (already registered with Apple) |
| Apple Team ID | `3HXZ723KGD` (baked into export preset) |
| GitHub Actions workflow | `.github/workflows/ios-release.yml` |
| Fastlane configs | `SmashBreaker/fastlane/Fastfile`, `Matchfile`, `Appfile` |
| Release notes | `store_assets/RELEASE_NOTES.md` |

---

## 👤 ONE-TIME SETUP (~30-45 minutes, all on Windows)

Follow `GITHUB_ACTIONS_IOS_SETUP.md`. Summary:

1. **Apple Developer Program** — $99/yr enrolment (1-2 day approval). Without
   this, the CI cannot sign anything.
2. **Two private GitHub repos:** one for this project, one empty for
   certificates (`SmashBreaker-Certs`)
3. **App Store Connect API key** — generated at appstoreconnect.apple.com,
   App Manager access
4. **GitHub personal access token** with `repo` scope, for fastlane match
5. **Repo secrets** — 7 values added to the SmashBreaker repo (the setup
   guide lists exactly which)
6. **Trigger the first workflow run** — GitHub generates certs, builds,
   uploads to TestFlight. ~10 min.

---

## 👤 PER-RELEASE FLOW (~5 min of your time)

```bash
# 1. Bump iOS build version in SmashBreaker/export_presets.cfg:
#    application/version (build number) — handled automatically by fastlane
#    application/short_version (display version: 1.0.2 etc)
#
# 2. Commit + tag + push:
git commit -am "v1.0.2 release"
git tag v1.0.2
git push origin v1.0.2

# 3. Watch the build in GitHub → Actions tab (~8 min)
# 4. Build appears in App Store Connect → TestFlight automatically.
```

---

## 👤 APP STORE CONNECT (browser, one-time per app)

These are the parts CI can't do — the store listing itself:

1. **My Apps → "+" → New App** — done if you've already filled the form
   (bundle ID, name, language, SKU)

2. **App Store Connect → your app → App Privacy**
   - "Do you collect data from this app?" → **No, we do not collect data**

3. **App Information**
   - Category: Games → Arcade · Sub-category: Action
   - Content Rights: I do not own or have licensed third-party content (true)

4. **Age Rating questionnaire** — all "None" → **4+**

5. **Pricing and Availability** — Free, all territories (or trim)

6. **Per-version "Prepare for Submission" page** (filled before each release):
   - Copy from `RELEASE_NOTES.md` (the App Store variant)
   - Description / keywords from `PLAY_STORE_CHECKLIST.md` (Apple's keyword
     field is 100 chars: `brick breaker,arkanoid,breakout,arcade,neon,space,offline,casual`)
   - Support URL: your hosted privacy-policy URL is fine for both
   - Privacy Policy URL: the hosted URL
   - **Screenshots** — 6.9" (iPhone 16 Pro Max) and 6.5" sets, portrait,
     ≥ 2 each. Capture on a real device after installing from TestFlight.

7. **Submit for review** — first-app reviews typically take 1-3 days.

---

## What rebuilds when

| Change | Action |
|---|---|
| Code, art, audio, scenes | Tag + push → CI rebuilds and uploads |
| Listing copy, screenshots, metadata | Edit in App Store Connect web UI |
| Privacy policy text | Edit the hosted URL — same URL works for both stores |
| Bundle ID | Locked permanently after first submission |

## What I deliberately turned off in the build

Game Center, In-App Purchases, Push Notifications, iCloud, Sign in with
Apple — all unchecked. Saves review scrutiny; nothing in the game uses them.

## Common rejection traps you're already clear of

- ✅ Privacy policy URL must load (host it before submitting)
- ✅ App must run on iPad — Godot exports universal by default; the game is
  portrait-locked so it shows pillarboxed on iPad. Apple accepts this.
- ✅ No placeholder content, no broken links
- ✅ No undocumented APIs (Godot uses public Metal via MoltenVK)
