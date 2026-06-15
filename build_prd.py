"""Builds Smash Breaker PRD + GDD v3.0 as a polished PDF."""
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor, white, black
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle,
    KeepTogether, HRFlowable,
)

OUT = r"C:\Users\altaf\Downloads\Smash_Breaker_PRD_GDD_v3.pdf"

# Palette (from original GDD)
BG_DARK = HexColor("#0d1117")
ACCENT_BLUE = HexColor("#58a6ff")
ACCENT_GOLD = HexColor("#d29922")
ACCENT_GREEN = HexColor("#3fb950")
ACCENT_RED = HexColor("#f85149")
ACCENT_ORANGE = HexColor("#f0883e")
GREY = HexColor("#8b949e")
TEXT_DARK = HexColor("#1f2328")
TEXT_MUTED = HexColor("#57606a")
ROW_ALT = HexColor("#f6f8fa")
BORDER = HexColor("#d0d7de")

styles = getSampleStyleSheet()

H1 = ParagraphStyle(
    "H1", parent=styles["Heading1"], fontName="Helvetica-Bold",
    fontSize=22, textColor=TEXT_DARK, spaceAfter=4, spaceBefore=6, leading=26,
)
H2 = ParagraphStyle(
    "H2", parent=styles["Heading2"], fontName="Helvetica-Bold",
    fontSize=15, textColor=ACCENT_BLUE, spaceAfter=6, spaceBefore=14, leading=18,
)
H3 = ParagraphStyle(
    "H3", parent=styles["Heading3"], fontName="Helvetica-Bold",
    fontSize=12, textColor=TEXT_DARK, spaceAfter=4, spaceBefore=8, leading=15,
)
BODY = ParagraphStyle(
    "Body", parent=styles["BodyText"], fontName="Helvetica",
    fontSize=10, textColor=TEXT_DARK, leading=14, spaceAfter=4, alignment=TA_LEFT,
)
BODY_J = ParagraphStyle("BodyJ", parent=BODY, alignment=TA_JUSTIFY)
SMALL = ParagraphStyle(
    "Small", parent=BODY, fontSize=8.5, textColor=TEXT_MUTED, leading=11,
)
COVER_TITLE = ParagraphStyle(
    "CoverTitle", parent=H1, fontSize=34, textColor=white,
    alignment=TA_CENTER, leading=40,
)
COVER_SUB = ParagraphStyle(
    "CoverSub", parent=BODY, fontSize=13, textColor=ACCENT_BLUE,
    alignment=TA_CENTER, leading=18,
)
COVER_META = ParagraphStyle(
    "CoverMeta", parent=BODY, fontSize=10, textColor=GREY,
    alignment=TA_CENTER, leading=14,
)
SECTION_TAG = ParagraphStyle(
    "Tag", parent=BODY, fontName="Helvetica-Bold", fontSize=9,
    textColor=white, alignment=TA_CENTER,
)
CALLOUT = ParagraphStyle(
    "Callout", parent=BODY, fontSize=9.5, textColor=TEXT_DARK,
    leading=13, leftIndent=8, rightIndent=8, spaceBefore=2, spaceAfter=2,
)

def hr(color=BORDER, thickness=0.5, space=4):
    return HRFlowable(width="100%", thickness=thickness, color=color,
                      spaceBefore=space, spaceAfter=space)

def tag(text, color):
    """Small inline-ish coloured pill rendered as a single-cell table."""
    t = Table([[Paragraph(f"<b>{text}</b>", SECTION_TAG)]], colWidths=[35*mm])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,-1), color),
        ("BOX", (0,0), (-1,-1), 0, color),
        ("LEFTPADDING", (0,0), (-1,-1), 6),
        ("RIGHTPADDING", (0,0), (-1,-1), 6),
        ("TOPPADDING", (0,0), (-1,-1), 4),
        ("BOTTOMPADDING", (0,0), (-1,-1), 4),
    ]))
    return t

def make_table(data, col_widths, header_bg=ACCENT_BLUE, zebra=True, header_color=white):
    """Renders rows where each cell is either str or Paragraph."""
    rows = []
    for r, row in enumerate(data):
        wrapped = []
        for cell in row:
            if isinstance(cell, Paragraph):
                wrapped.append(cell)
            else:
                style = BODY if r > 0 else ParagraphStyle(
                    "th", parent=BODY, fontName="Helvetica-Bold",
                    textColor=header_color, fontSize=10
                )
                wrapped.append(Paragraph(str(cell), style))
        rows.append(wrapped)
    t = Table(rows, colWidths=col_widths, repeatRows=1)
    ts = [
        ("BACKGROUND", (0,0), (-1,0), header_bg),
        ("LINEBELOW", (0,0), (-1,0), 0.6, header_bg),
        ("VALIGN", (0,0), (-1,-1), "TOP"),
        ("LEFTPADDING", (0,0), (-1,-1), 6),
        ("RIGHTPADDING", (0,0), (-1,-1), 6),
        ("TOPPADDING", (0,0), (-1,-1), 5),
        ("BOTTOMPADDING", (0,0), (-1,-1), 5),
        ("BOX", (0,0), (-1,-1), 0.4, BORDER),
        ("INNERGRID", (0,0), (-1,-1), 0.3, BORDER),
    ]
    if zebra:
        for r in range(1, len(rows)):
            if r % 2 == 0:
                ts.append(("BACKGROUND", (0, r), (-1, r), ROW_ALT))
    t.setStyle(TableStyle(ts))
    return t

def callout_box(title, body_html, accent=ACCENT_GOLD):
    t = Table([
        [Paragraph(f"<b>{title}</b>", ParagraphStyle('ct', parent=BODY, fontName='Helvetica-Bold', fontSize=10, textColor=accent))],
        [Paragraph(body_html, CALLOUT)],
    ], colWidths=[170*mm])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,-1), HexColor("#fff8e1") if accent == ACCENT_GOLD else HexColor("#eef6ff")),
        ("BOX", (0,0), (-1,-1), 0.6, accent),
        ("LINEBEFORE", (0,0), (0,-1), 3, accent),
        ("LEFTPADDING", (0,0), (-1,-1), 10),
        ("RIGHTPADDING", (0,0), (-1,-1), 10),
        ("TOPPADDING", (0,0), (-1,-1), 6),
        ("BOTTOMPADDING", (0,0), (-1,-1), 6),
    ]))
    return t

# ---------- BUILD ----------
doc = SimpleDocTemplate(
    OUT, pagesize=A4,
    leftMargin=18*mm, rightMargin=18*mm,
    topMargin=18*mm, bottomMargin=18*mm,
    title="Smash Breaker — PRD + GDD v2.0",
    author="Straw Hat Studio",
)
story = []

# ========== COVER ==========
cover_card = Table([
    [Spacer(1, 30*mm)],
    [Paragraph("SMASH BREAKER", COVER_TITLE)],
    [Paragraph("Brick Breaker for Mobile", COVER_SUB)],
    [Spacer(1, 8*mm)],
    [Paragraph("Product Requirements + Game Design Document", COVER_META)],
    [Paragraph("Version 3.0 &nbsp;·&nbsp; June 8, 2026", COVER_META)],
    [Spacer(1, 30*mm)],
    [Paragraph("STRAW HAT STUDIO", ParagraphStyle('csh', parent=COVER_META, fontSize=11, textColor=ACCENT_GOLD, fontName='Helvetica-Bold'))],
    [Paragraph("Godot 4.6.2 &nbsp;·&nbsp; Android &nbsp;·&nbsp; Inspired by Lacoste Ace Breaker RG", COVER_META)],
    [Spacer(1, 18*mm)],
], colWidths=[170*mm])
cover_card.setStyle(TableStyle([
    ("BACKGROUND", (0,0), (-1,-1), BG_DARK),
    ("BOX", (0,0), (-1,-1), 0, BG_DARK),
    ("LEFTPADDING", (0,0), (-1,-1), 0),
    ("RIGHTPADDING", (0,0), (-1,-1), 0),
]))
story.append(cover_card)
story.append(Spacer(1, 8*mm))
story.append(Paragraph(
    "<i>A 6-week MVP of a proven genre. Shipped faster, cheaper, with our own visual identity.</i>",
    ParagraphStyle('tag', parent=BODY, alignment=TA_CENTER, fontSize=11, textColor=TEXT_MUTED)
))
story.append(PageBreak())

# ========== CHANGELOG ==========
story.append(Paragraph("What changed in v3.0", H1))
story.append(hr(ACCENT_BLUE, 1.2))
story.append(Paragraph(
    "v3.0 keeps the v2.0 product &amp; design content intact and adds <b>Part 3 — Launch Readiness</b>: "
    "everything needed to actually ship to the Play Store and run the first 90 days. "
    "If v1→v2 closed design gaps, v2→v3 closes execution gaps.", BODY_J
))
story.append(Spacer(1, 6))
story.append(Paragraph("<b>v2.0 changes (recap)</b> — design &amp; product gap fixes:", BODY))
story.append(Spacer(1, 4))
changelog = [
    ["Area", "v1.0", "v2.0"],
    ["Power-up drops", "Drop rate column on bricks (ambiguous)", "Explicit weighted drop table per brick type + rarity weights"],
    ["Star thresholds", "“Score ≥ threshold” (TBD)", "Tuning table: 50 levels with bronze/silver/gold score targets"],
    ["Mode unlocks", "Daily at L5, Endless L10, Timed L20", "Daily moved to L2 (retention hook); rest unchanged"],
    ["Anti-stuck", "Nudge after 3s", "Nudge after 1.2s; second nudge at 2.5s; auto-lose if 5s"],
    ["Min SDK", "API 26 (Android 8.0)", "API 24 (Android 7.0) — recovers ~5% reach"],
    ["Lives", "+1 per 10K points, cap unstated", "+1 per 10K, hard cap at 5"],
    ["Shield + Multiball", "Resolution unclear", "Shield only triggers on loss of last ball in play"],
    ["FTUE / tutorial", "Not specified", "3-step gated tutorial (move, hit, power-up) on first run"],
    ["Haptics", "Not specified", "Full haptics spec per event (light/medium/heavy)"],
    ["Privacy / consent", "Not specified", "GDPR + DPDP + COPPA consent flow defined"],
    ["Audio assets", "₹0 budget, 7 SFX listed (conflict)", "Sourced from CC0 + self-recorded; budget reconciled"],
    ["Localization", "Not specified", "MVP: EN only. v1.1: HI, ES, PT-BR, ID"],
    ["Schedule risk", "Week 5-6 overloaded", "IAP shop + achievements pushed to v1.1 patch"],
]
story.append(make_table(changelog, [32*mm, 65*mm, 73*mm]))

story.append(Spacer(1, 10))
story.append(Paragraph("<b>v3.0 additions</b> — launch &amp; ops:", BODY))
v3_changelog = [
    ["Area", "v2.0", "v3.0"],
    ["Store listing / ASO", "Not specified", "Full title, short/long description, keywords, category"],
    ["Screenshots", "Not specified", "8-shot plan with copy + screen order"],
    ["Telemetry", "“PostHog free tier”", "20-event schema with properties and KPI mapping"],
    ["QA / device matrix", "Not specified", "Tier-A/B/C device list + manual test checklist"],
    ["Soft launch", "Not specified", "Geo plan (PH/ID first) + go/no-go thresholds"],
    ["Launch checklist", "Not specified", "T-14 / T-7 / T-1 / launch-day / D+7 checklists"],
    ["Live ops calendar", "Not specified", "90-day post-launch cadence (events, updates)"],
    ["Support / reviews", "Not specified", "1-2★ reply SLA + canned response bank"],
]
story.append(make_table(v3_changelog, [32*mm, 65*mm, 73*mm]))
story.append(PageBreak())

# ========== PART 1: PRD ==========
story.append(tag("PART 1 — PRD", ACCENT_BLUE))
story.append(Spacer(1, 6))
story.append(Paragraph("Product Requirements", H1))
story.append(hr(ACCENT_BLUE, 1.2))

# 1. Executive Summary
story.append(Paragraph("1. Executive Summary", H2))
story.append(Paragraph(
    "Smash Breaker is a mobile-first Brick Breaker (Breakout/Arkanoid lineage) for Android, "
    "built in Godot 4.6.2. The thesis: the genre has been satisfying for 50 years; we adapt it "
    "for a 2026 mobile audience with tight feel, power-ups, a meta-progression loop, and a "
    "distinct neon-on-dark visual identity. Hyper-casual scope, mid-core polish.", BODY_J
))
story.append(Spacer(1, 4))
exec_table = [
    ["Timeline to MVP", "Platform", "Monetization", "Asset Budget", "Engine"],
    ["4-6 weeks", "Android (Play Store)", "IAA + IAP", "₹0 cash · CC0 + self-made", "Godot 4.6.2"],
]
story.append(make_table(exec_table, [33*mm]*5, header_bg=BG_DARK))

# 2. Core Gameplay
story.append(Paragraph("2. Core Gameplay", H2))
gameplay = [
    ["Element", "Detail"],
    ["Controls", "Touch &amp; drag — paddle follows finger 1:1, no inertia"],
    ["Ball launch", "Auto-launch 2s after spawn, 15° from vertical (randomised L/R)"],
    ["Paddle width", "30% of screen width (default); shrinks 1% per 10 levels (floor 22%)"],
    ["Levels", "50 handcrafted (Classic) + procedural (Endless)"],
    ["Brick types", "Normal, Hard, Steel, Explosive, Gold (see GDD §3)"],
    ["Lives", "3 per game, +1 every 10K points, <b>cap 5</b>"],
    ["Difficulty curve", "Ball speed +5% per level (cap +60% at L12); paddle shrink as above"],
    ["Pause", "Tap top-right pause icon; auto-pause on focus loss"],
]
story.append(make_table(gameplay, [38*mm, 132*mm]))

# 3. Power-ups
story.append(Paragraph("3. Power-Ups (6 total)", H2))
story.append(Paragraph(
    "Power-ups drop from broken bricks based on a weighted roll (see GDD §4). At most one "
    "power-up of each <i>category</i> can be active at a time — collecting the same category "
    "refreshes its timer.", BODY_J
))
powerups = [
    ["Power-Up", "Effect", "Duration", "Category", "Rarity"],
    ["Wide Paddle", "Paddle ×2 width", "20s", "Paddle", "Common"],
    ["Multiball", "Ball splits into 3", "15s active", "Ball", "Rare"],
    ["Fireball", "One-hit any brick, ignores reflection on bricks", "10s", "Ball", "Uncommon"],
    ["Slow Motion", "Ball speed ×0.5", "15s", "Ball", "Uncommon"],
    ["Shield", "Absorbs loss of <b>last</b> ball in play", "Until used", "Defensive", "Rare"],
    ["Smash", "Paddle fires projectiles every 0.4s", "12s", "Paddle", "Rare"],
]
story.append(make_table(powerups, [28*mm, 60*mm, 25*mm, 28*mm, 25*mm]))

# 4. Game Modes
story.append(Paragraph("4. Game Modes", H2))
modes = [
    ["Mode", "Description", "Unlock", "Retention Role"],
    ["Classic", "50 handcrafted levels, increasing difficulty", "Default", "Core progression"],
    ["Daily Challenge", "Same seed for all players, one attempt/day", "<b>Level 2</b>", "Daily return hook"],
    ["Endless", "Procedurally generated, infinite bricks", "Level 10", "Mastery / score chase"],
    ["Timed", "60 seconds, max score", "Level 20", "Quick session"],
]
story.append(make_table(modes, [25*mm, 70*mm, 25*mm, 50*mm]))
story.append(callout_box(
    "Why Daily moved to Level 2",
    "v1.0 unlocked Daily at L5 — too late for a hook that drives <b>D1 → D2</b> retention. "
    "Most casuals churn before L5; Daily must be visible early enough to anchor the next-day return.",
    ACCENT_GOLD
))
story.append(PageBreak())

# 5. Monetization
story.append(Paragraph("5. Monetization", H2))
mon = [
    ["Type", "Placement", "Frequency / Cap", "Expected RPM"],
    ["Rewarded Video", "Continue after game over", "1/game, optional", "$8-12"],
    ["Rewarded Video", "Double score at level end", "1/level, optional", "$8-12"],
    ["Interstitial", "Between levels", "Every 5 levels, 60s cooldown", "$2-4"],
    ["Banner", "Main menu only — <b>not</b> in gameplay", "Always", "$0.30-0.80"],
    ["IAP — Remove Ads", "Settings + first interstitial", "₹149 one-time", "n/a"],
    ["IAP — Gem packs", "Shop (paddle skins)", "₹49 / ₹199 / ₹499", "n/a"],
]
story.append(make_table(mon, [32*mm, 50*mm, 50*mm, 38*mm]))
story.append(callout_box(
    "Banner rule",
    "No banner during gameplay. Banners on the playfield hurt session length (we've seen "
    "8-12% drops in benchmarks) and increase 1-star reviews. Menu-only.",
    ACCENT_RED
))

# 6. Retention
story.append(Paragraph("6. Retention &amp; KPI Targets", H2))
kpi = [
    ["Metric", "Target", "Stretch", "Notes"],
    ["D1 Retention", "≥30%", "40%", "Strong FTUE + Daily at L2 are the two levers"],
    ["D7 Retention", "≥15%", "22%", "Meta loop (skins, stars) carries this"],
    ["D30 Retention", "≥5%", "8%", "Soft target; not a launch gate"],
    ["Avg session length", "4-7 min", "—", "Limit interstitials if &lt;3 min"],
    ["Sessions / DAU", "2-3", "4", "Daily + push notifications"],
    ["CPI (India geo)", "≤₹6", "≤₹4", "Stretch is aggressive — flagged as ambitious"],
    ["Ad ARPDAU", "$0.05", "$0.10", "—"],
    ["IAP conversion", "1%", "3%", "Remove-ads + first gem pack drive this"],
    ["Play Store rating", "≥4.0", "≥4.5", "Reply to 1-2★ reviews within 48h"],
]
story.append(make_table(kpi, [38*mm, 22*mm, 22*mm, 88*mm]))

# 7. Visual Direction
story.append(Paragraph("7. Visual Direction", H2))
story.append(Paragraph(
    "<b>Dark neon</b>. Background <font color='#0d1117'>#0d1117</font>, glowing bricks, "
    "subtle bloom on the ball and paddle. The visual identity is the differentiator — "
    "no skeuomorphic bricks, no cartoony palette.", BODY_J
))
palette = [
    ["Element", "Hex", "Use"],
    ["Background", "#0d1117", "App background, level frames"],
    ["Normal brick", "#58a6ff (blue)", "1-hit bricks"],
    ["Hard brick", "#d29922 (gold)", "2-hit bricks"],
    ["Steel brick", "#8b949e (grey)", "3-hit bricks"],
    ["Explosive brick", "#f85149 (red)", "Chain destruction"],
    ["Gold brick", "#f0883e (orange)", "Bonus points"],
    ["Paddle", "#3fb950 (green)", "Player paddle with glow edge"],
    ["UI accent", "#58a6ff", "Buttons, score, links"],
]
story.append(make_table(palette, [35*mm, 35*mm, 100*mm]))
story.append(Spacer(1, 4))
story.append(Paragraph(
    "<b>Feel cues:</b> particle burst on brick break matching brick colour. Light screen shake "
    "on paddle hit (2px, 80ms), heavy on Explosive chain (6px, 180ms). Slow-motion power-up "
    "tints the screen 6% blue.", BODY_J
))
story.append(PageBreak())

# 8. Tech Stack
story.append(Paragraph("8. Tech Stack", H2))
tech = [
    ["Requirement", "Detail"],
    ["Engine", "Godot 4.6.2 (stable, mobile-tested)"],
    ["Platform", "Android — Google Play Store"],
    ["Min SDK", "<b>API 24 (Android 7.0)</b> — covers ~99% of active devices"],
    ["Target SDK", "API 34 (Play Store 2026 requirement)"],
    ["Orientation", "Portrait locked"],
    ["Target FPS", "60 FPS; 30 FPS fallback on devices with &lt;2GB RAM"],
    ["Ad SDK", "Godot AdMob Plugin (poing-studios fork)"],
    ["IAP", "Godot Google Play Billing plugin"],
    ["Analytics", "PostHog (free tier, EU region for DPDP/GDPR safety)"],
    ["Leaderboards", "Google Play Games Services"],
    ["Crash reporting", "Firebase Crashlytics"],
    ["CI/CD", "GitHub Actions → signed AAB → internal track"],
]
story.append(make_table(tech, [38*mm, 132*mm]))

# 9. Privacy & Compliance — NEW
story.append(Paragraph("9. Privacy &amp; Compliance (new in v2.0)", H2))
story.append(Paragraph(
    "Required for Play Store approval and to avoid Play Console policy strikes. Consent is "
    "<b>blocking</b> on first run.", BODY_J
))
compliance = [
    ["Requirement", "Implementation"],
    ["GDPR (EU users)", "Google UMP SDK consent dialog, EEA-targeted"],
    ["DPDP (India)", "Explicit opt-in for analytics + ads (DPDP Act 2023)"],
    ["COPPA / Families Policy", "Age gate; under-13 path disables personalised ads"],
    ["Play Data Safety form", "Declares: device ID, ads ID, crash data; no PII"],
    ["IDFA / GAID", "Only collected post-consent"],
    ["Privacy Policy URL", "Hosted on strawhat.studio/smash-breaker/privacy"],
    ["Account deletion", "In-app link to deletion request (Play 2024+ requirement)"],
]
story.append(make_table(compliance, [55*mm, 115*mm]))

# 10. FTUE
story.append(Paragraph("10. First-Time User Experience (new in v2.0)", H2))
story.append(Paragraph(
    "Three gated tutorial moments on the first session — no skip on the first two. Each "
    "blocks gameplay with a finger-pointer animation and a 1-line caption. The whole flow "
    "must complete in under 45 seconds; we measure FTUE completion as a KPI.", BODY_J
))
ftue = [
    ["Step", "Trigger", "Caption", "Success criterion"],
    ["1. Move", "First level loads", "Drag to move the paddle", "Paddle moves &gt;100px"],
    ["2. Hit", "After step 1", "Bounce the ball off the paddle", "1 successful bounce"],
    ["3. Power-up", "First power-up drops (forced on L1)", "Catch the bonus!", "Power-up collected OR missed"],
]
story.append(make_table(ftue, [25*mm, 45*mm, 55*mm, 45*mm]))

# 11. Development Phases (revised)
story.append(Paragraph("11. Development Phases (revised)", H2))
phases = [
    ["Phase", "Week", "Deliverable"],
    ["1. Core MVP", "1-2", "Paddle, ball, bricks, 10 levels, 3 power-ups (Wide, Multiball, Fireball), score, game over, FTUE"],
    ["2. Content", "3-4", "40 more levels, remaining 3 power-ups, star rating, particles, screen shake, haptics, SFX"],
    ["3. Launch prep", "5-6", "AdMob, consent flow, Endless + Timed + Daily, leaderboards, Crashlytics, Play Console setup"],
    ["4. Post-launch v1.1", "Week 7+", "IAP shop, paddle skins, achievements, push notifications, localization (HI/ES/PT-BR/ID)"],
]
story.append(make_table(phases, [33*mm, 18*mm, 119*mm]))
story.append(callout_box(
    "Why we pushed IAP + shop to v1.1",
    "v1.0 weeks 5-6 bundled AdMob + IAP + leaderboards + achievements + shop + 3 modes — "
    "every one of these has external integration risk (Play Billing test accounts, store "
    "review for IAP products, achievement registration). Shipping IAP empty-handed in MVP "
    "loses nothing — we monetize on IAA at launch and add IAP in v1.1 with real data on "
    "which skins to build first.",
    ACCENT_GREEN
))
story.append(PageBreak())

# ========== PART 2: GDD ==========
story.append(tag("PART 2 — GDD", ACCENT_GREEN))
story.append(Spacer(1, 6))
story.append(Paragraph("Game Design", H1))
story.append(hr(ACCENT_GREEN, 1.2))

# 1. Paddle Mechanics
story.append(Paragraph("1. Paddle Mechanics", H2))
story.append(Paragraph(
    "<b>Width:</b> 30% of screen width (shrinks 1% per 10 levels, floor 22%).<br/>"
    "<b>Position:</b> Fixed Y at 85% of screen height.<br/>"
    "<b>Movement:</b> Paddle follows the finger 1:1 (no smoothing, no inertia).<br/>"
    "<b>Reflection:</b> Hit position on the paddle controls the outgoing angle.", BODY
))
story.append(Spacer(1, 2))
story.append(Paragraph(
    "<font face='Courier'>reflect_angle = 90° − (hit_offset / paddle_half_width) × 60°</font>",
    ParagraphStyle('code', parent=BODY, fontName='Courier', fontSize=10, textColor=ACCENT_BLUE,
                   backColor=ROW_ALT, borderPadding=6, leftIndent=4, rightIndent=4)
))
story.append(Paragraph(
    "Centre hit → straight up. Edge hit → 60° from vertical (max). No spin physics in v1.0.", SMALL
))

# 2. Ball Physics
story.append(Paragraph("2. Ball Physics", H2))
ball = [
    ["Property", "Value"],
    ["Size", "24px diameter (1080p reference resolution)"],
    ["Base speed", "400 px/s"],
    ["Per-level speed gain", "+20 px/s, cap at +240 px/s (L12)"],
    ["Launch", "Auto-launch 2s after spawn, 15° from vertical, randomised L/R"],
    ["Reflection", "Bounces off walls (L/R/T) and bricks via surface normal"],
    ["Lose condition", "Ball crosses kill zone at bottom"],
    ["Anti-stuck (horizontal)", "If |vel.x| / |vel.y| &gt; 6 for 1.2s → nudge angle by 15°. Repeat at 2.5s. Auto-lose at 5s."],
    ["Anti-stuck (slow)", "If speed &lt; 80% of expected for 2s → restore"],
]
story.append(make_table(ball, [55*mm, 115*mm]))

# 3. Brick Types
story.append(Paragraph("3. Brick Types", H2))
bricks = [
    ["Type", "Hits", "Color", "Points", "Notes"],
    ["Normal", "1", "#58a6ff", "10", "Default brick"],
    ["Hard", "2", "#d29922", "25", "Colour shifts after 1st hit"],
    ["Steel", "3", "#8b949e", "50", "Visible crack overlay per hit"],
    ["Explosive", "1", "#f85149", "20", "On break, destroys all bricks in 3×3 around it (chains)"],
    ["Gold", "1", "#f0883e", "100", "Higher chance to drop a power-up (see §4)"],
]
story.append(make_table(bricks, [25*mm, 15*mm, 28*mm, 20*mm, 82*mm]))

# 4. Power-up Drop System — NEW EXPLICIT TABLE
story.append(Paragraph("4. Power-up Drop System (clarified in v2.0)", H2))
story.append(Paragraph(
    "When a brick is destroyed, roll a single d100. If it falls in the drop range, a "
    "power-up spawns and falls at 200 px/s. The <i>which</i> power-up is then selected by "
    "rarity weights.", BODY_J
))
story.append(Paragraph("<b>Step 1 — does a power-up drop?</b>", BODY))
drop1 = [
    ["Brick destroyed", "Drop chance"],
    ["Normal", "5%"],
    ["Hard", "8%"],
    ["Steel", "10%"],
    ["Gold", "20%"],
    ["Explosive (direct hit)", "0% — but chained bricks roll their own"],
]
story.append(make_table(drop1, [60*mm, 110*mm]))
story.append(Spacer(1, 4))
story.append(Paragraph("<b>Step 2 — which power-up? (weighted)</b>", BODY))
drop2 = [
    ["Power-Up", "Weight", "Effective % (within drop)"],
    ["Wide Paddle (Common)", "30", "30%"],
    ["Fireball (Uncommon)", "20", "20%"],
    ["Slow Motion (Uncommon)", "20", "20%"],
    ["Multiball (Rare)", "10", "10%"],
    ["Shield (Rare)", "10", "10%"],
    ["Smash (Rare)", "10", "10%"],
]
story.append(make_table(drop2, [60*mm, 30*mm, 80*mm]))
story.append(callout_box(
    "Active-power-up rule",
    "Only one power-up <i>per category</i> can be active at once (Paddle / Ball / Defensive). "
    "Collecting the same category refreshes the timer; collecting a different category in the "
    "same slot replaces it. Shield is a one-shot — it persists until consumed.",
    ACCENT_BLUE
))
story.append(PageBreak())

# 5. Scoring
story.append(Paragraph("5. Scoring", H2))
scoring = [
    ["Action", "Points"],
    ["Normal brick", "10"],
    ["Hard brick", "25"],
    ["Steel brick", "50"],
    ["Explosive brick", "20 + chain bonuses"],
    ["Gold brick", "100"],
    ["Power-up collected", "50"],
    ["No lives lost in level", "+200 bonus"],
    ["Combo chain (within 0.5s)", "+5 per brick"],
    ["Level cleared with all 3 stars", "+500"],
]
story.append(make_table(scoring, [80*mm, 90*mm]))

# 6. Star Tuning Table — NEW
story.append(Paragraph("6. Star Tuning Thresholds (new in v2.0)", H2))
story.append(Paragraph(
    "Stars are awarded by score thresholds. The table below is the launch curve — values "
    "are derived from the score floor (sum of all brick points × 1.1) and tuned per group "
    "of 10 levels. Designer should override individual values as needed; this is the default.",
    BODY_J
))
stars = [
    ["Level range", "1★ (complete)", "2★ score", "3★ score + no death"],
    ["1-10", "Any clear", "≥ 1.3 × base", "≥ 1.6 × base"],
    ["11-20", "Any clear", "≥ 1.4 × base", "≥ 1.7 × base"],
    ["21-30", "Any clear", "≥ 1.5 × base", "≥ 1.8 × base"],
    ["31-40", "Any clear", "≥ 1.55 × base", "≥ 1.9 × base"],
    ["41-50", "Any clear", "≥ 1.6 × base", "≥ 2.0 × base"],
]
story.append(make_table(stars, [35*mm, 40*mm, 40*mm, 55*mm]))
story.append(Paragraph(
    "<i>base</i> = sum of all brick point values in the level layout (computed at level load).", SMALL
))

# 7. Scene Structure
story.append(Paragraph("7. Scene Structure (Godot)", H2))
scene_text = (
    "res://<br/>"
    "├── main.tscn              # Main menu<br/>"
    "├── game.tscn              # Core gameplay<br/>"
    "│   ├── Paddle.tscn        # Player paddle<br/>"
    "│   ├── Ball.tscn          # Ball instance<br/>"
    "│   ├── BrickGrid.tscn     # Brick container<br/>"
    "│   ├── PowerUp.tscn       # Falling power-up<br/>"
    "│   ├── HUD.tscn           # Score + lives + level<br/>"
    "│   └── Effects.tscn       # Particles + shake + haptics<br/>"
    "├── ftue_overlay.tscn      # Tutorial gating (new)<br/>"
    "├── consent_dialog.tscn    # GDPR/DPDP consent (new)<br/>"
    "├── game_over.tscn         # Game over overlay<br/>"
    "├── level_select.tscn      # Level select<br/>"
    "├── shop.tscn              # IAP / skins (v1.1)<br/>"
    "├── settings.tscn          # Audio, haptics, privacy<br/>"
    "└── daily_challenge.tscn   # Daily"
)
story.append(Paragraph(scene_text, ParagraphStyle(
    'tree', parent=BODY, fontName='Courier', fontSize=9, textColor=TEXT_DARK,
    backColor=ROW_ALT, borderPadding=8, leading=12
)))

# 8. Collision Layers
story.append(Paragraph("8. Godot Collision Layers", H2))
layers = [
    ["Layer", "Objects", "Mask (collides with)"],
    ["1", "Ball", "2, 3, 4, 6"],
    ["2", "Paddle", "1, 5"],
    ["3", "Walls", "1"],
    ["4", "Bricks", "1"],
    ["5", "Power-ups", "2, 6"],
    ["6", "Kill zone (bottom)", "1, 5"],
]
story.append(make_table(layers, [20*mm, 80*mm, 70*mm]))

# 9. Save Data
story.append(Paragraph("9. Player Save Data (user://save.cfg)", H2))
save_text = (
    "[player]<br/>"
    "high_score = 12340<br/>"
    "total_bricks_broken = 4520<br/>"
    "games_played = 89<br/>"
    "level_unlocked = 18<br/>"
    'stars = {"1": 3, "2": 2, "3": 1, ...}<br/><br/>'
    "[shop]<br/>"
    'selected_paddle = "default"<br/>'
    'owned_paddles = ["default", "neon", "croc"]<br/>'
    "gems = 250<br/><br/>"
    "[settings]<br/>"
    "sfx_volume = 0.8<br/>"
    "music_volume = 0.6<br/>"
    "haptics_enabled = true<br/>"
    "consent_ads = true<br/>"
    "consent_analytics = true<br/>"
    "ftue_completed = true"
)
story.append(Paragraph(save_text, ParagraphStyle(
    'save', parent=BODY, fontName='Courier', fontSize=9, textColor=TEXT_DARK,
    backColor=ROW_ALT, borderPadding=8, leading=12
)))
story.append(PageBreak())

# 10. Edge Cases
story.append(Paragraph("10. Edge Cases", H2))
edges = [
    ["Issue", "Resolution"],
    ["Ball stuck horizontal", "Nudge by 15° after 1.2s; second nudge at 2.5s; auto-lose at 5s"],
    ["Ball stuck slow", "If speed &lt;80% of expected for 2s, restore to expected speed"],
    ["Double touch on revive", "1s cooldown on revive button after game over screen"],
    ["Multiball + Shield", "Shield only triggers on loss of <b>last</b> ball in play"],
    ["Multiball + Multiball pickup", "If &gt;1 ball already in play, refresh duration; do not split further"],
    ["Explosive at grid edge", "3×3 destruction ignores empty cells; no out-of-bounds spawns"],
    ["Explosive chain reaction", "Cap at 12 bricks per chain to prevent frame drops"],
    ["Ad fail to load", "Graceful fallback — no ad, button still works, retry once after 30s"],
    ["Low-end devices", "If RAM &lt; 2GB or sustained FPS &lt; 45 for 5s → disable particles + bloom"],
    ["Focus loss (call, notification)", "Auto-pause; resume on tap"],
    ["Power-up while paused", "Pause halts duration timer"],
    ["Last brick is Explosive", "Level completes after chain resolves"],
]
story.append(make_table(edges, [60*mm, 110*mm]))

# 11. Audio SFX
story.append(Paragraph("11. Audio SFX", H2))
audio = [
    ["Sound", "Duration", "Style", "Source"],
    ["brick_hit", "0.1s", "Short pop", "freesound.org CC0"],
    ["brick_break", "0.15s", "Satisfying crack", "Self-recorded + edit"],
    ["paddle_hit", "0.1s", "Thwack", "Self-recorded"],
    ["powerup_collect", "0.2s", "Ascending chime", "Generated (sfxr)"],
    ["powerup_active", "loop", "Subtle pulse", "Generated"],
    ["life_lost", "0.3s", "Descending tone", "Generated"],
    ["level_complete", "0.5s", "Ascending arpeggio", "Generated"],
    ["game_over", "0.8s", "Epic finish", "Self-composed"],
    ["explosion (chain)", "0.25s", "Sub-bass thump", "freesound.org CC0"],
]
story.append(make_table(audio, [35*mm, 25*mm, 50*mm, 60*mm]))

# 12. Haptics — NEW
story.append(Paragraph("12. Haptics (new in v2.0)", H2))
story.append(Paragraph(
    "Mobile breakers live or die by feel. All haptics gated behind a Settings toggle (default ON). "
    "Implementation: Godot 4.6 <font face='Courier'>Input.vibrate_handheld()</font> with millisecond durations. "
    "Skip haptics on focus loss or low battery (&lt;15%).", BODY_J
))
haptics = [
    ["Event", "Strength", "Duration"],
    ["Paddle hit", "Light", "10ms"],
    ["Brick break (normal)", "—", "(no haptic, sound only)"],
    ["Brick break (Hard final hit)", "Light", "15ms"],
    ["Brick break (Steel final hit)", "Medium", "25ms"],
    ["Explosive chain", "Heavy", "40ms (+ 20ms tail)"],
    ["Power-up collected", "Light", "15ms"],
    ["Life lost", "Medium", "30ms"],
    ["Level complete", "—", "Sound only (haptic feels excessive after a win)"],
    ["Game over", "Heavy", "60ms"],
]
story.append(make_table(haptics, [60*mm, 30*mm, 80*mm]))

# 13. Push & Localization — NEW
story.append(Paragraph("13. Push Notifications &amp; Localization (post-launch)", H2))
push = [
    ["Notification", "Trigger", "Schedule"],
    ["Daily Challenge available", "After daily reset", "00:05 local time"],
    ["You're missing out", "User inactive 2 days", "19:00 local"],
    ["New high score in your country", "Optional, opt-in", "Weekly"],
    ["New skin unlocked", "On unlock event", "Immediate"],
]
story.append(make_table(push, [50*mm, 65*mm, 55*mm]))
story.append(Spacer(1, 4))
story.append(Paragraph(
    "<b>Localization plan:</b> MVP ships English only. v1.1 adds Hindi (HI), Spanish (ES), "
    "Brazilian Portuguese (PT-BR), Indonesian (ID) — chosen by CPI/scale potential. All UI "
    "strings stored in <font face='Courier'>res://locale/*.csv</font> from day one to avoid retrofit.",
    BODY_J
))

# 14. Risks & Mitigations
story.append(Paragraph("14. Risks &amp; Mitigations", H2))
risks = [
    ["Risk", "Likelihood", "Impact", "Mitigation"],
    ["Play Console policy rejection", "Med", "High", "Submit to internal track week 4 for early feedback"],
    ["AdMob fill rate low in India", "Med", "Med", "Add waterfall: AppLovin MAX as v1.1 fallback"],
    ["Stretch CPI ₹4 unachievable", "High", "Low", "Acceptable — ₹6 base target is realistic"],
    ["Godot AdMob plugin breakage on SDK update", "Med", "High", "Pin plugin version; smoke-test before each release"],
    ["Schedule slip on weeks 5-6", "Med", "Med", "v1.1 contains IAP shop as overflow buffer"],
    ["FTUE drop-off &gt; 30%", "Med", "High", "Track per-step funnel in PostHog; iterate weekly post-launch"],
]
story.append(make_table(risks, [55*mm, 22*mm, 22*mm, 71*mm]))

# ========== PART 3: LAUNCH READINESS (new in v3.0) ==========
story.append(PageBreak())
story.append(tag("PART 3 — LAUNCH", ACCENT_GOLD))
story.append(Spacer(1, 6))
story.append(Paragraph("Launch Readiness", H1))
story.append(hr(ACCENT_GOLD, 1.2))
story.append(Paragraph(
    "Part 1 said <i>what</i> we're building. Part 2 said <i>how</i> it plays. Part 3 says "
    "<i>how it ships and survives the first 90 days.</i> Everything here is execution — "
    "no new product decisions, only the artefacts and checklists needed to launch on Play "
    "and operate the title to the retention targets in §6.", BODY_J
))

# 1. Store Listing / ASO
story.append(Paragraph("1. Store Listing &amp; ASO", H2))
story.append(Paragraph(
    "Play Store listing copy. Title and short description are the two highest-leverage ASO "
    "fields — both contain the primary keyword <b>brick breaker</b>. Long description "
    "follows the Play algorithm's keyword-density preference (target keyword 4-6× in body).",
    BODY_J
))
aso = [
    ["Field", "Limit", "Value"],
    ["App title", "30 chars", "Smash Breaker: Brick Crusher"],
    ["Short description", "80 chars", "Neon brick breaker. Smash, chain, climb the leaderboard. 50 levels free."],
    ["Category (primary)", "—", "Arcade"],
    ["Category (secondary)", "—", "Casual"],
    ["Content rating", "—", "Everyone (ESRB E / IARC 3+)"],
    ["Contains ads", "—", "Yes"],
    ["In-app purchases", "—", "₹49 – ₹499 per item"],
    ["Target audience", "—", "13+ (Families Policy compliant)"],
]
story.append(make_table(aso, [40*mm, 22*mm, 108*mm]))
story.append(Spacer(1, 4))
story.append(Paragraph("<b>Long description (4000 char limit) — draft outline:</b>", BODY))
ldesc = [
    ["Section", "Content"],
    ["Hook (1 line)", "The brick breaker reinvented for 2026 — neon, satisfying, addictive."],
    ["Core loop (3 bullets)", "Drag to move · Smash bricks · Catch power-ups"],
    ["Feature list (6-8 bullets)", "50 hand-crafted levels · 6 power-ups · Endless mode · Daily Challenge · Global leaderboards · Paddle skins · Offline play · No ads in gameplay"],
    ["Power-up callouts", "1 line each, with emoji marker"],
    ["Modes section", "Classic · Endless · Timed · Daily — what each is for"],
    ["Why we built it", "1 paragraph studio voice, Lacoste reference"],
    ["Closer", "Free to play. No paywall. Made by Straw Hat Studio."],
]
story.append(make_table(ldesc, [45*mm, 125*mm]))
story.append(Spacer(1, 4))
story.append(Paragraph("<b>Keywords (for ASO tracking — Play has no keyword field, these guide title/desc):</b>", BODY))
story.append(Paragraph(
    "brick breaker · breakout · arkanoid · brick crusher · ball breaker · smash bricks · "
    "neon arcade · offline arcade · daily challenge · paddle game",
    ParagraphStyle('kw', parent=BODY, fontName='Courier', fontSize=9, backColor=ROW_ALT, borderPadding=6)
))

# 2. Screenshot Plan
story.append(Paragraph("2. Screenshot Plan (8 shots)", H2))
story.append(Paragraph(
    "Play Store shows up to 8 phone screenshots. Order matters — the first 3 are visible "
    "without scrolling and carry 80% of the install decision. Each screenshot has a 1-line "
    "headline overlay; do not rely on the gameplay reading well at thumbnail size.", BODY_J
))
shots = [
    ["#", "Subject", "Headline copy", "Why this shot"],
    ["1", "Hero — mid-game with Multiball + Fireball active", "Smash. Chain. Repeat.", "Strongest single frame of the product"],
    ["2", "Explosive chain mid-detonation, particles", "Chain explosions everywhere.", "Showcases the most viral moment"],
    ["3", "Level 25 layout — dense, varied bricks", "50 hand-crafted levels.", "Conveys content depth"],
    ["4", "Power-up grid (all 6 with descriptions)", "6 power-ups to master.", "Sells variety"],
    ["5", "Endless mode HUD with high score", "Endless mode. How far can you go?", "Sells replayability"],
    ["6", "Daily Challenge screen with leaderboard preview", "New challenge every day.", "Sells the retention hook"],
    ["7", "Paddle skin shop", "Style your paddle.", "Sells the meta"],
    ["8", "Global leaderboard with top-100 names", "Climb the global leaderboard.", "Social proof"],
]
story.append(make_table(shots, [8*mm, 50*mm, 50*mm, 60*mm]))
story.append(callout_box(
    "Feature graphic (1024×500)",
    "Required by Play. Brief: hero ball mid-chain on dark background, logo right-aligned, "
    "tagline “Brick Breaker, Reinvented”. No screenshot overlays — Play deprecates these.",
    ACCENT_BLUE
))
story.append(PageBreak())

# 3. Telemetry / Analytics Events
story.append(Paragraph("3. Telemetry &amp; Analytics Events (PostHog)", H2))
story.append(Paragraph(
    "20 events. Every KPI in §6 maps to a query over these events. Property naming is "
    "<font face='Courier'>snake_case</font>; values are typed (no stringified numbers). All "
    "events include implicit properties: <font face='Courier'>device_tier, app_version, "
    "session_id, country</font>.", BODY_J
))
events = [
    ["Event name", "When fired", "Key properties", "Powers which KPI"],
    ["app_open", "Cold start", "is_first_session, days_since_install", "DAU, D1/D7/D30"],
    ["consent_shown", "First run after install", "—", "Consent funnel"],
    ["consent_response", "User taps accept/decline", "ads, analytics", "Consent rate"],
    ["ftue_step_start", "Tutorial step begins", "step (1/2/3)", "FTUE funnel"],
    ["ftue_step_complete", "Tutorial step ends", "step, ms_to_complete", "FTUE drop-off"],
    ["ftue_complete", "All 3 steps done", "total_ms", "FTUE completion rate"],
    ["level_start", "Level loads (any mode)", "mode, level, attempt_n", "Per-level engagement"],
    ["level_complete", "Level cleared", "level, stars, score, ms, deaths", "Difficulty tuning"],
    ["level_fail", "All lives lost", "level, score, last_brick_pct", "Difficulty hotspots"],
    ["level_quit", "User exits mid-level", "level, score, ms", "Frustration signal"],
    ["powerup_drop", "Power-up spawns", "type, brick_type", "Drop tuning"],
    ["powerup_collect", "Power-up caught", "type, level", "Collection rate"],
    ["powerup_miss", "Power-up reaches floor", "type, level", "—"],
    ["ad_request", "Ad call initiated", "format, placement", "Fill rate"],
    ["ad_show", "Ad rendered", "format, placement", "Impressions"],
    ["ad_reward", "Rewarded video completed", "placement, reward", "Reward opt-in"],
    ["iap_view", "Shop opened", "source_screen", "IAP funnel"],
    ["iap_purchase", "Purchase confirmed", "sku, price_inr, currency", "IAP revenue"],
    ["daily_attempt", "Daily Challenge played", "seed_date, score", "Daily DAU"],
    ["leaderboard_view", "Leaderboard opened", "scope (global/country)", "Social engagement"],
]
story.append(make_table(events, [38*mm, 38*mm, 50*mm, 44*mm]))

# 4. QA & Device Matrix
story.append(Paragraph("4. QA Device Matrix &amp; Test Plan", H2))
story.append(Paragraph(
    "Tier-A is must-pass before launch. Tier-B is sampled. Tier-C is smoke-tested only. "
    "Device list reflects the Indian + SEA market mix (Xiaomi, Realme, Samsung lower-mid).",
    BODY_J
))
devices = [
    ["Tier", "Device", "RAM", "SDK", "Notes"],
    ["A", "Pixel 6a (test rig)", "6 GB", "34", "Reference device — 60 FPS gate"],
    ["A", "Samsung A14", "4 GB", "33", "Largest mid-range install base in IN"],
    ["A", "Xiaomi Redmi Note 11", "4 GB", "31", "MIUI quirks (notification overlay)"],
    ["A", "Realme Narzo 50", "4 GB", "31", "Indian market staple"],
    ["B", "Samsung A05", "4 GB", "33", "Low-end Samsung"],
    ["B", "Moto G14", "4 GB", "33", "Stock Android baseline"],
    ["B", "OnePlus Nord CE 3", "8 GB", "33", "High-refresh display test"],
    ["C", "Samsung Tab A9 (tablet)", "4 GB", "33", "Portrait-locked sanity check"],
    ["C", "Pixel 4a (old)", "6 GB", "30", "Min-SDK boundary"],
    ["C", "Generic 2GB RAM device", "2 GB", "30", "Particle-disable path"],
]
story.append(make_table(devices, [12*mm, 50*mm, 18*mm, 15*mm, 75*mm]))
story.append(Spacer(1, 4))
story.append(Paragraph("<b>Manual smoke test (per build, ~15 min):</b>", BODY))
smoke = [
    ["#", "Test", "Pass criterion"],
    ["1", "Cold start &lt; 3s to menu", "Stopwatch on Tier-A device"],
    ["2", "Consent dialog appears on first run", "Decline path also works"],
    ["3", "FTUE completes in &lt;60s", "All 3 steps trigger"],
    ["4", "Play Level 1, 5, 25, 50", "No crashes, no stuck balls"],
    ["5", "Trigger each power-up once", "All 6 fire correctly"],
    ["6", "Force ball into corner — anti-stuck nudges", "Resolves within 5s"],
    ["7", "Background app mid-game → resume", "Pauses cleanly"],
    ["8", "Lose all lives → rewarded video offered", "Ad shows OR graceful fallback"],
    ["9", "Settings: toggle haptics + audio", "Persists across restart"],
    ["10", "Pull internet, replay", "Offline play works; no crash on ad call"],
]
story.append(make_table(smoke, [8*mm, 85*mm, 77*mm]))
story.append(PageBreak())

# 5. Soft Launch Plan
story.append(Paragraph("5. Soft Launch Plan", H2))
story.append(Paragraph(
    "Soft launch in <b>Philippines + Indonesia</b> 14 days before India + global. Cheap "
    "user acquisition geos with similar device profiles to India, lets us measure D1/D7/CPI "
    "before committing marketing budget. Hard gate on going global.", BODY_J
))
soft = [
    ["Phase", "Days", "Geos", "Spend", "Go/No-go gate"],
    ["Internal track", "T-21 to T-14", "Internal testers (20)", "₹0", "Zero crashes; FTUE works"],
    ["Closed beta", "T-14 to T-10", "PH only (500 users)", "₹2k UA", "D1 ≥25%; crash-free ≥99%"],
    ["Open beta", "T-10 to T-3", "PH + ID (2-5k users)", "₹10k UA", "D1 ≥28%; rating ≥4.0"],
    ["Global launch", "T-0", "IN + worldwide", "₹50k UA", "—"],
    ["Post-launch", "T+0 to T+30", "All", "Scale based on ROAS", "—"],
]
story.append(make_table(soft, [30*mm, 25*mm, 40*mm, 22*mm, 53*mm]))
story.append(callout_box(
    "No-go conditions",
    "If after open beta any of: D1 &lt; 25%, crash-free &lt; 99%, rating &lt; 3.8, or CPI &gt; ₹10 — "
    "<b>delay global launch</b> by one sprint and fix. Cheaper than burning UA budget on a "
    "leaky funnel.",
    ACCENT_RED
))

# 6. Launch Checklists
story.append(Paragraph("6. Launch Checklists", H2))

story.append(Paragraph("<b>T-14 (two weeks before global launch)</b>", BODY))
t14 = [
    ["Item", "Owner"],
    ["Play Console listing 100% complete (all assets uploaded)", "Producer"],
    ["Privacy Policy live at strawhat.studio/smash-breaker/privacy", "Producer"],
    ["Data Safety form submitted", "Producer"],
    ["Internal testing track passed Tier-A device matrix", "QA"],
    ["AdMob ad units created + linked in app", "Eng"],
    ["PostHog project live, all 20 events firing on staging build", "Eng"],
    ["Crashlytics dSYM/symbols upload working", "Eng"],
    ["Soft-launch UA campaigns drafted in Google Ads", "Marketing"],
]
story.append(make_table(t14, [130*mm, 40*mm]))

story.append(Spacer(1, 4))
story.append(Paragraph("<b>T-7 (one week)</b>", BODY))
t7 = [
    ["Item", "Owner"],
    ["Soft-launch metrics reviewed; no-go check passed", "Producer"],
    ["Release notes drafted for launch build", "Producer"],
    ["8 screenshots + feature graphic + 30s trailer uploaded", "Design"],
    ["Press kit posted to studio site (one-pager + PNGs)", "Marketing"],
    ["Support email smashbreaker@strawhat.studio monitored", "Producer"],
]
story.append(make_table(t7, [130*mm, 40*mm]))

story.append(Spacer(1, 4))
story.append(Paragraph("<b>T-1 / launch day</b>", BODY))
t1 = [
    ["Item", "Owner"],
    ["Production AAB signed, uploaded, in review", "Eng"],
    ["Staged rollout set to 20% (not 100%) for first 24h", "Producer"],
    ["Crashlytics + PostHog dashboards pinned, monitored hourly", "Eng + Producer"],
    ["Social posts queued (Twitter/X, Reddit r/AndroidGaming, LinkedIn)", "Marketing"],
    ["Reddit AMA scheduled for T+3", "Marketing"],
    ["Reply-to-review SLA in effect (24h on 1-2★)", "Producer"],
]
story.append(make_table(t1, [130*mm, 40*mm]))

story.append(Spacer(1, 4))
story.append(Paragraph("<b>T+7 (one week post-launch)</b>", BODY))
t7p = [
    ["Item", "Owner"],
    ["D1 and D3 retention numbers vs target", "Producer"],
    ["Top crash-free issues triaged", "Eng"],
    ["1-2★ reviews replied to, common themes identified", "Producer"],
    ["Hotfix patch decision (v1.0.1) — go or wait for v1.1", "Producer"],
    ["UA spend ROAS analysis; scale up or cut", "Marketing"],
]
story.append(make_table(t7p, [130*mm, 40*mm]))
story.append(PageBreak())

# 7. Live Ops Calendar
story.append(Paragraph("7. Live Ops Calendar (first 90 days)", H2))
story.append(Paragraph(
    "Cadence matters more than scope. A small predictable update every two weeks beats a "
    "huge surprise. All dates relative to launch (T+0).", BODY_J
))
liveops = [
    ["When", "Release", "Contents"],
    ["T+0", "v1.0", "Launch build (Classic 50 + 3 modes + IAA)"],
    ["T+7", "v1.0.1 hotfix", "Top 3 crashes + most-reported bugs"],
    ["T+14", "v1.1", "IAP shop, paddle skins (3 free + 4 paid), achievements"],
    ["T+21", "Content drop", "Weekend Tournament — top-100 leaderboard, theme: Neon Heat"],
    ["T+30", "v1.2", "Localization: HI, ES, PT-BR, ID"],
    ["T+45", "Content drop", "10 new Classic levels (51-60)"],
    ["T+60", "v1.3", "Push notifications, achievement rework, new power-up: Magnet"],
    ["T+75", "Content drop", "Halloween / festival re-skin (neon pumpkin bricks)"],
    ["T+90", "v1.4", "iOS port begins (out of scope for this doc)"],
]
story.append(make_table(liveops, [22*mm, 28*mm, 120*mm]))

# 8. Support & Review Response
story.append(Paragraph("8. Support &amp; Review Response", H2))
story.append(Paragraph(
    "Reviews are a leading indicator and a public artefact — replying within 48h to 1-2★ "
    "reviews pulls our rating up measurably (we've seen +0.2★ average from this discipline "
    "in past titles). Below is the canned response bank — adapt, don't paste verbatim.",
    BODY_J
))
support = [
    ["Complaint pattern", "Canned starter"],
    ["Crashes on launch", "“Sorry about the crash! Could you DM us your device model + Android version? We're already chasing two crash signatures — your info helps us narrow it down.”"],
    ["Too many ads", "“We hear you. Ads only show between levels (every 5) and rewarded ads are always optional. If you'd like an ad-free run, the Remove Ads IAP is ₹149 one-time.”"],
    ["Too hard", "“The difficulty ramps every 10 levels — but if a specific level feels off, tell us which one and we'll review the tuning in the next patch.”"],
    ["Pay to win", "“Smash Breaker has no pay-to-win mechanics. Power-ups drop from bricks, IAP is cosmetic (paddle skins) or ad-removal only.”"],
    ["Boring / same as Arkanoid", "“Fair — the genre is 50 years old. We added Daily Challenges, power-up chains, and Endless mode. Try the Daily — it's a different layout every 24h.”"],
    ["Battery drain", "“We cap at 60 FPS and drop to 30 on lower-end devices. If you're seeing heavy drain on a recent flagship, please DM your device + Android version.”"],
]
story.append(make_table(support, [45*mm, 125*mm]))

# 9. KPI Dashboard Spec
story.append(Paragraph("9. KPI Dashboard Spec", H2))
story.append(Paragraph(
    "Single PostHog dashboard, pinned, reviewed every morning for the first 30 days. "
    "Nine tiles, no more — anything else is noise.", BODY_J
))
dash = [
    ["Tile", "Definition", "Alert threshold"],
    ["DAU", "Unique users with app_open, last 24h", "—"],
    ["D1 retention", "% of installs from 1 day ago who returned", "&lt; 25% = red"],
    ["D7 retention", "% of installs from 7 days ago who returned", "&lt; 12% = red"],
    ["FTUE completion", "% of installs that fire ftue_complete", "&lt; 70% = red"],
    ["Crash-free users (24h)", "From Crashlytics", "&lt; 99% = red"],
    ["Ad fill rate", "ad_show / ad_request", "&lt; 80% = red"],
    ["Ad ARPDAU", "ad revenue / DAU", "—"],
    ["Avg session length", "Median ms between app_open and app_background", "&lt; 3min = yellow"],
    ["Top fail level", "level with most level_fail events", "—"],
]
story.append(make_table(dash, [35*mm, 90*mm, 45*mm]))

# Bottom line
story.append(Spacer(1, 10))
story.append(hr(ACCENT_BLUE, 1.2))
story.append(Paragraph(
    "<b>Bottom line.</b> A 6-week build of a proven genre, with the design (v2) and the "
    "launch playbook (v3) both written down before week 1. The same formula Lacoste used "
    "for Roland Garros — paddle, ball, bricks, power-ups — shipped faster, cheaper, and "
    "with our own neon identity. v3.0 adds the artefacts that turn a built game into a "
    "shipped one: ASO copy, screenshots, telemetry events, QA matrix, soft-launch gates, "
    "and a 90-day live-ops cadence.",
    ParagraphStyle('bl', parent=BODY_J, fontSize=10.5, textColor=TEXT_DARK,
                   backColor=HexColor('#eef6ff'), borderPadding=10, leading=15)
))
story.append(Spacer(1, 6))
story.append(Paragraph(
    "Smash Breaker · Straw Hat Studio · PRD + GDD v3.0 · June 8, 2026",
    ParagraphStyle('foot', parent=SMALL, alignment=TA_CENTER)
))

doc.build(story)
print(f"OK: {OUT}")
