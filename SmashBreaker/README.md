# Smash Breaker — Phase 2 (3D, portrait, sci-fi, premium polish)

Brick-breaker built in Godot 4.6. Gameplay is single-plane (XZ), all visuals
are 3D meshes with emissive materials and a TRON-style hangar dressing.

**Phase 2 additions:** gem economy + paddle-skin shop (8 skins), synthesized
SFX (12 sounds, zero external assets), camera shake, brick-break particle
bursts, ball comet trail, floating score popups, paddle squash-on-hit, HUD
score count-up, pause menu, sector-cleared screen with star ratings + gem
rewards, starfield backdrop, shared UI theme (`UiTheme` autoload).

## Run it

1. Install Godot **4.6.x**.
2. Open Godot → **Import** → pick this folder's `project.godot`.
3. Press **F5**.

## Controls

- **Mouse** (desktop): paddle follows the cursor X on any mouse motion.
- **Arrow keys**: also move the paddle.
- **Touch** (mobile): paddle follows your finger.
- **Escape** *or* tap the `‖` button top-right: pause / resume.

The ball auto-launches 2 seconds after spawn.

## Coordinate system

| Axis | Meaning |
|---|---|
| **X** | Horizontal. Field spans X ∈ [−5.4, +5.4]. |
| **Y** | World-up. Gameplay all happens at Y ≈ 0; meshes have visible height. |
| **Z** | Depth. **+Z is toward the camera** (= "down" on screen). Paddle at Z = +8, bricks live in Z ∈ [−6.5, +0]. |

Camera at `(0, 6, 16)` with `keep_aspect = KEEP_WIDTH` and `fov = 75°` horizontal — derived vertical FOV ≈ 42°.

## What's implemented (vs PRD/GDD)

| PRD/GDD section | Status |
|---|---|
| Touch & drag paddle (1:1 follow on screen X) | Yes |
| Reflection formula `90° − norm × 60°` in XZ | Yes |
| 5 brick types (Normal, Hard, Steel, Explosive, Gold) | Yes |
| Explosive 3×3 chain with 12-brick cap, **chain propagation (depth 4)** | Yes |
| 10 hand-crafted levels (loops after 10) | Yes |
| Power-ups: Wide, Multiball, Fireball | Yes |
| Auto-launch after 2 s | Yes |
| Anti-stuck nudge (1.2 s / 2.5 s / 5 s auto-lose) | Yes |
| Out-of-bounds safety net (force-lose if ball tunnels) | Yes |
| Lives = 3, +1 per 10K points (cap 5) | Yes |
| Combo chain bonus (+5/brick within 0.5 s) | Yes |
| No-death bonus (+200) | Yes |
| Save: high_score, level_unlocked, bricks broken | Yes |
| Main menu, Game Over (Retry / Menu) | Yes |
| In-game pause button on the HUD | Yes |
| 3D rendering with emissive bricks + glow post-process | Yes |

## Visual identity

- **Floor**: procedural grid shader (`shaders/court.gdshader`) — dark brushed metal + cyan grid + magenta service bands.
- **Side walls**: ship-hangar panels — dark hull alternating with thin glowing cyan light strips.
- **Back bulkhead**: dim slab with a cyan seam at the top.
- **Perimeter trim**: emissive cyan rails (left, right, front, back).
- **Environment**: deep-space background, blue ambient + magenta fill light, fog + bloom.
- **Ball**: cyan plasma (magenta when fireball is active). Carries its own omni light so it stays visible everywhere.
- **Paddle**: navy hull capsule with cyan glow, omni-light puddle on the floor so you always know where it is.

## Out of scope (Phase 2+)

- Remaining power-ups: Slow Motion, Shield, Smash
- Particle effects on brick destruction
- Screen shake (camera shake)
- SFX, haptics, music
- Star rating screen
- Endless / Timed / Daily Challenge modes
- AdMob, IAP, leaderboards, achievements
- FTUE overlay
- Consent dialog (GDPR / DPDP)

## Orientation

The game is configured for **portrait Android**: `project.godot` uses a 1080×1920 viewport with sensor-portrait handheld orientation, the Android export preset is sensor-portrait, and the custom Android manifest locks the activity to portrait.

## File layout

```
SmashBreaker/
├── project.godot                  # Engine config, autoloads, input, layers
├── icon.svg
├── shaders/
│   └── court.gdshader             # Grid floor shader (hangar metal + cyan grid)
├── scenes/
│   ├── main.tscn                  # Main menu
│   ├── game.tscn                  # Gameplay root (camera, env, lights)
│   ├── paddle.tscn                # CharacterBody3D shell
│   ├── ball.tscn                  # CharacterBody3D shell
│   ├── brick.tscn                 # StaticBody3D shell
│   ├── powerup.tscn               # Area3D shell
│   ├── hud.tscn                   # CanvasLayer overlay (Lives, Score, LV, Pause)
│   └── game_over.tscn             # Overlay
└── scripts/
    ├── game_state.gd              # Autoload — score, lives, save/load
    ├── level_data.gd              # Autoload — 10 level layouts
    ├── game.gd                    # Node3D orchestrator + hangar dressing
    ├── paddle.gd                  # Capsule paddle + screen→world-X mapping
    ├── ball.gd                    # XZ-plane reflection + anti-stuck + safety bounds
    ├── brick.gd                   # Brick type/HP/colour with double-hit guard
    ├── powerup.gd                 # Area3D falling pickup
    ├── hud.gd
    ├── main.gd
    └── game_over.gd
```

## Architecture notes

- **No imported textures.** Everything is procedural meshes (`BoxMesh`, `SphereMesh`, `CapsuleMesh`, `PlaneMesh`) with `StandardMaterial3D` / `ShaderMaterial`. Self-contained, easy to recolour.
- **Code-driven scenes.** `.tscn` files are minimal shells; meshes and collision shapes are built in `_ready()`. Easier to edit outside the Godot editor.
- **Stretch**: `canvas_items` + `keep` aspect → 3D scales with the window, HUD stays sharp.
- **Renderer**: `gl_compatibility` by default — switch to `mobile` or `forward_plus` (Project Settings → Rendering) for nicer glow at the cost of mobile-device fps headroom.
- **Collision layers**: Ball=1, Paddle=2, Walls=3, Bricks=4, PowerUps=5, KillZone=6 (named in `project.godot` for both 2D and 3D pickers).

## Building for Android

1. **Project → Export → Add → Android**.
2. **Project → Install Android Build Template**.
3. Package name: e.g. `studio.strawhat.smashbreaker`.
4. Min SDK 24, Target SDK 34.
5. Rendering Method (Mobile): `mobile` recommended on-device.
6. Export Debug AAB → install on device.

For Play Store, produce a signed release AAB with a keystore via Export settings.
