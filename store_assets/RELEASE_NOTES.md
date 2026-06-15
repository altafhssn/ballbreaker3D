# Release Notes — Smash Breaker

## v1.0.1 (code 2) — launch release

### Google Play (paste into "Release notes", 500 char limit)

Play Console accepts plain text; the `<en-US>` tags are added automatically
when you paste into the en-US field.

```
🚀 Welcome to Smash Breaker — launch release!

• 90 sectors across 3 galaxies: Cyanis, Ember Nebula and Frost Reach
• Galaxy mechanics: regenerating magma bricks, ice fields with sliding paddle physics
• Daily Challenge — one seeded level per day, same for every player, one attempt
• Earn gems, unlock 8 paddle skins in the Hangar
• First-contact codex: every new brick type is introduced when you first meet it
• Synthwave soundtrack, volume controls, full offline play — no ads, no tracking
```
(~470 chars — fits the 500 limit.)

### Short variant (if you prefer punchy)

```
Launch release! Conquer 90 sectors across 3 galaxies, beat the one-attempt
Daily Challenge, earn gems and unlock paddle skins. Offline, no ads, no
tracking. New brick types are introduced as you meet them. Good hunting.
```

### App Store — "What's New in This Version"

Apple doesn't show this field for an app's very first version — you'll only
need it from your second submission onward. When asked, use:

```
Welcome to Smash Breaker — the launch release.

• 90 sectors across 3 themed galaxies, each with its own mechanic
• Daily Challenge: one seeded level per day, one attempt, same for everyone
• Gem economy with 8 unlockable paddle skins
• First-contact codex introduces every new brick type
• Fully offline. No ads. No data collection.
```

---

## Template for future updates

Keep notes user-facing: lead with content, then fixes. Players skim the
first two lines — put the most exciting thing first. Avoid internal jargon
("refactored", "preset", "shader") — describe what changed in their hands.

```
🌌 NEW: [headline feature — e.g. "Verdant Cluster galaxy — 30 new sectors"]

• [secondary feature]
• [secondary feature]
• Fixed: [user-visible bug, plain words — "ball no longer escapes the arena"]
• [balance change — "magma bricks regenerate slower"]
```

Versioning reminder before each release:
- Android: bump `version/code` (+1 every upload) and `version/name` in
  `export_presets.cfg` [preset.0]
- iOS: bump `application/version` (build number) and `application/short_version`
  in [preset.1]
- Keep both `*version names* `in sync so store listings match.
