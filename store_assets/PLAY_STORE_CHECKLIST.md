# Google Play Store Submission Checklist — Smash Breaker

Everything below the "YOU DO" line requires your Google account / browser.
Everything above it is already prepared in this folder.

---

## ✅ PREPARED (in this repo)

| Asset | Location | Notes |
|---|---|---|
| Release AAB | `builds/SmashBreaker-release.aab` | Signed, target SDK 35, min SDK 24 |
| Play Store icon (512×512) | `store_assets/play_icon_512.png` | No transparency, as required |
| Feature graphic (1024×500) | `store_assets/feature_graphic_1024x500.png` | Required by Play |
| Privacy policy text | `store_assets/privacy_policy.md` | Host it (see step 2) |
| Launcher icons | baked into the AAB | Legacy + adaptive fg/bg |
| Upload keystore | `keystore/smashbreaker-release.keystore` | **BACK THIS UP.** Alias `smashbreaker` |

### Store listing copy (paste into Console)

**App name (30 chars max):**
`Smash Breaker: Galaxy Bricks`

**Short description (80 chars max):**
`Neon 3D brick breaker. Conquer 10 galaxies, smash bricks, dodge nothing.`

**Full description (4000 chars max):**

```
THE BRICK BREAKER, REBUILT FOR DEEP SPACE

Smash Breaker takes the formula you've loved for decades — paddle, ball,
bricks — and launches it into a neon 3D galaxy. Conquer sector after sector
across themed galaxies, each with its own look and its own twist on the rules.

🌌 CONQUER THE GALAXIES
• 90 sectors across 3 launch galaxies — with 7 more on the star chart
• Every galaxy changes the game: magma bricks that regenerate if you don't
  finish them, ice fields where your paddle slides with real momentum
• Boss fortresses, gauntlet sectors with no power-ups, and hand-crafted
  challenge layouts

⚡ POWER-UPS
• Wide Paddle, Multiball, and Fireball — catch them, chain them, clear faster

💎 EARN AND CUSTOMIZE
• Earn gems from every cleared sector — more stars, more gems
• Unlock 8 paddle skins in the hangar, from Ghost Runner to Void Walker

📅 DAILY CHALLENGE
• One seeded level per day — identical for every player on Earth
• One attempt. No retries. Make it count.

🎮 BUILT FOR FEEL
• Full 3D presentation with a TRON-style hangar, drifting starships and a
  living starfield
• Camera shake, particle bursts, combo chains and a synthwave soundtrack
• Offline — no internet needed, no account, no ads, no tracking

⭐ MASTER EVERY SECTOR
• 3-star ratings on every level
• Star gates unlock the next galaxy — skill opens the map

Free. No ads. No data collection. Just bricks.
```

**Category:** Games → Arcade
**Tags:** brick breaker, arcade, breakout, casual
**Contact email:** sameermacmini@gmail.com

### Data safety form answers (Console → App content → Data safety)

- Does your app collect or share user data? → **No**
- (That's it — the form collapses when you answer No. Truthful because the
  game has no analytics, ads, or network access.)

### Content rating questionnaire answers

- Category: **Game**
- Violence: No · Sexuality: No · Language: No · Controlled substances: No
- Gambling: No (gems are earned in-game only, no real-money purchase)
- User interaction / sharing: No · Location: No · Personal info: No
- Expected rating: **Everyone / PEGI 3**

---

## 👤 YOU DO (in order, ~1-2 hours + review wait)

1. **Developer account** — https://play.google.com/console
   One-time $25 fee. Identity verification can take 1-2 days. Use the
   account you want the studio attached to permanently.

2. **Host the privacy policy** — Play requires a public URL.
   Fastest free option: a GitHub repo with `privacy_policy.md` → enable
   GitHub Pages → URL like `https://<you>.github.io/smashbreaker/privacy`.
   (Google Sites also works.)

3. **Create the app** — Console → Create app
   - Name: Smash Breaker: Galaxy Bricks · Default language: en-US
   - App or game: **Game** · Free or paid: **Free**

4. **App content section** (left sidebar) — work through every item:
   - Privacy policy → paste your hosted URL
   - Ads → **No, my app does not contain ads**
   - Content rating → questionnaire (answers above)
   - Target audience → 13+ recommended (avoids Families policy overhead;
     you can broaden later)
   - News app → No · COVID app → No · Data safety → No collection
   - Government app → No

5. **Store listing** — paste the copy above, upload `play_icon_512.png`
   and `feature_graphic_1024x500.png`.
   **Screenshots: you must capture these** — minimum 2, phone, 16:9 or 9:16.
   Recommended set (capture on your phone, portrait):
   1. Mid-game in Cyanis with multiball active
   2. Ember Nebula with magma bricks glowing
   3. The star chart (galaxy map)
   4. The sector journey map
   5. Hangar / skins shop
   6. Sector Cleared screen with 3 stars

6. **Upload the AAB** — Release → Testing → **Internal testing** first:
   - Create release → upload `builds/SmashBreaker-release.aab`
   - When prompted, **opt in to Play App Signing** (Google holds the
     signing key; your keystore becomes the upload key — this is good)
   - Add your own Gmail as a tester → install from the opt-in link →
     sanity-check the build on a real device

7. **Promote to Production** — once internal testing looks good:
   - Production → Create release → reuse the same AAB
   - Staged rollout: start at 20%
   - Submit for review. First-app review typically takes 1-7 days.

---

## ⚠️ Before you upload — two warnings

1. **The package name `studio.strawhat.smashbreaker` is permanent** after
   the first upload. If you want a different one, change it in
   `export_presets.cfg` and rebuild NOW, not later.

2. **The keystore password is in plaintext** in `export_presets.cfg`
   (`smashbreaker2026`). Anyone with repo access can sign as you.
   Consider rotating the password and moving it to environment variables
   (`GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`) before sharing the repo.
   And again: **back up `keystore/smashbreaker-release.keystore`** — with
   Play App Signing it's recoverable, but don't test that.
