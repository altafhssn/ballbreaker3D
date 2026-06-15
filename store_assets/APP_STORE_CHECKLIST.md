# Apple App Store Submission Checklist — Windows-only

Builds happen on Apple's macOS runners via GitHub Actions. You stay on
Windows the whole time. Detailed CI setup is in
`GITHUB_ACTIONS_IOS_SETUP.md` — this file is the higher-level flow.

---

## ✅ Already prepared (in this repo)

| Asset | Location |
|---|---|
| App Store icon 1024×1024 | `store_assets/appstore_icon_1024.png` (also baked in) |
| Privacy policy text | `store_assets/privacy_policy.md` (host the same URL as Play) |
| Bundle ID | `studio.strawhat.smashbreaker` (registered with Apple) |
| Apple Team ID | `3HXZ723KGD` (in export preset + CI workflow) |
| GitHub Actions workflow | `.github/workflows/ios-release.yml` |
| Fastlane configs | `SmashBreaker/fastlane/Fastfile`, `Matchfile`, `Appfile` |
| Release notes | `store_assets/RELEASE_NOTES.md` |

---

## 👤 One-time setup (~30 min, all in your browser + Windows shell)

Walk through `GITHUB_ACTIONS_IOS_SETUP.md`. Six steps:

1. Apple Developer Program active ($99/yr)
2. Empty private repo `SmashBreaker-Certs` for fastlane match
3. App Store Connect API key generated (3 values + .p8 file)
4. GitHub personal access token with `repo` scope
5. 7 secrets added to the ballbreaker3D repo
6. Click **Run workflow** → first build → TestFlight in ~10 min

---

## 👤 Per-release flow (~30 seconds of your time)

```bash
cd "C:\Users\altaf\OneDrive\Documents\Ball Breaker 3D"
git commit -am "v1.0.3 release"
git tag v1.0.3
git push origin v1.0.3
```

Watch the build in the Actions tab. ~7 min later it's in TestFlight.

---

## 👤 App Store Connect (browser, mostly one-time)

CI handles builds. You handle the listing:

1. **App Privacy** → "Do you collect data from this app?" → **No**
2. **App Information**
   - Category: Games → Arcade · Sub-category: Action
   - Content Rights: I do not own or have licensed third-party content
3. **Age Rating** questionnaire → all "None" → **4+**
4. **Pricing and Availability** → Free, all territories
5. **Version Info** (per release):
   - Description, keywords from `PLAY_STORE_CHECKLIST.md` (reusable)
   - Keywords field: `brick breaker,arkanoid,breakout,arcade,neon,space,offline,casual`
   - Privacy Policy URL (hosted privacy_policy.md)
   - Support URL (same)
   - "What's New" from `RELEASE_NOTES.md` (App Store variant)
   - **Screenshots** — required, 6.9" and 6.5" portrait, ≥ 2 each.
     Capture on a phone after installing from TestFlight, OR use a friend's
     iPhone. (Xcode Simulator screenshots also work but you need a Mac for
     that — easier to just use a real phone.)
6. **Submit for Review** — first review typically 1-3 days

---

## What rebuilds when

| Change | Action |
|---|---|
| Code, art, audio, scenes | `git push` a new tag → CI rebuilds + uploads to TestFlight |
| Listing copy, screenshots, metadata | Edit in App Store Connect web UI |
| Privacy policy text | Edit the hosted URL — same URL for Play and App Store |
| Bundle ID | Locked forever after the first submission |

## What's deliberately off in the build

Game Center, In-App Purchases, Push Notifications, iCloud, Sign in with
Apple. Nothing in the game uses them, and keeping them off shortens review.

## Common first-app rejection traps you're already clear of

- ✅ Privacy policy URL must load — host it before submitting
- ✅ Runs on iPad (Godot exports universal; portrait-locked, pillarboxed
  on iPad — Apple accepts this)
- ✅ No placeholder content, no broken links
- ✅ Public API usage only (Godot uses Metal via MoltenVK)
