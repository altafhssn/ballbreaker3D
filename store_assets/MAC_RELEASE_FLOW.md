# Mac Release Flow — Coordinating Hermes from Windows

Your side (Windows) is short: prep the repo, push to GitHub, message Hermes.
This file is the short version.

---

## Phase 1 — One-time (Windows side)

```bash
cd "C:\Users\altaf\OneDrive\Documents\Ball Breaker 3D"
git init
git add .
git commit -m "Initial: ready for Mac/Hermes"
# Create empty private repo on github.com, then:
git remote add origin https://github.com/<your-user>/SmashBreaker.git
git branch -M main
git push -u origin main
```

The `.gitignore` already excludes `keystore/`, `.godot/`, `builds/`, etc.,
so the push is safe.

---

## Phase 2 — Hand off to Hermes

In your Hermes session on the Mac, paste this:

> Read the file `store_assets/HERMES_BRIEFING.md` in the SmashBreaker repo
> at `https://github.com/<your-user>/SmashBreaker.git` and execute it.
> Ask me for the Apple developer credentials when you need them. Goal:
> a build in TestFlight tonight.

Hermes will then:
1. Bootstrap the Mac (Xcode CLI tools, Homebrew, Godot, templates)
2. Pause and ask you to install Xcode from the App Store if needed (the
   only step that requires a GUI on the Mac)
3. Pause and ask for your App Store Connect API key details (you generate
   that in your browser — instructions in the briefing)
4. Build, sign, and upload to TestFlight

Expected total wall time: **30-90 minutes** the first time, mostly waiting
for Xcode to download.

---

## Phase 3 — Subsequent releases

After the Mac is set up, each new release is just:

**Windows:**
```bash
git commit -am "v1.0.3 — your changes"
git push
```

**Hermes:** message it "ship the latest" and it runs:
```bash
cd ~/work/SmashBreaker && ./mac/release_ios.sh
```

That's ~5 minutes of Mac time per release. The script auto-pulls latest,
auto-bumps version, signs, uploads.

---

## When you need the Mac for something else later

The Mac is also where you'd:
- Capture iPhone screenshots for App Store Connect (use Xcode's Simulator
  → File → Save Screen → captures at the correct resolution per device)
- Test on an iPad simulator (Apple reviews on iPad even for iPhone-only apps)
- Submit the version for Production review (App Store Connect web UI; can
  also be done from Windows once the build is in TestFlight)

---

## What's in the repo for the Mac

```
mac/
├── bootstrap.sh         # First-time Mac setup, idempotent
├── release_ios.sh       # Per-release build + sign + upload
└── export_options.plist # xcodebuild signing config

store_assets/
└── HERMES_BRIEFING.md   # The full prompt for Hermes
```
