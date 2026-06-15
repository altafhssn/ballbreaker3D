extends Node
## UiTheme — autoload. Fonts + styling helpers so every screen speaks the
## same sci-fi visual language. Orbitron for display text, Rajdhani for body.

const TEXT_PRIMARY := Color("#e8f2ff")
const TEXT_SECONDARY := Color("#6a7da0")
const ACCENT := Color("#4ad0ff")
const ACCENT_BRIGHT := Color("#7ee6ff")
const WARN := Color("#ff4ad0")
const GOLD := Color("#ffb84a")
const PANEL_BG := Color(0.03, 0.055, 0.10, 0.92)

var font_display: FontVariation = null   # Orbitron — titles, buttons
var font_display_heavy: FontVariation = null
var font_body: Font = null               # Rajdhani Medium — body text
var font_body_bold: Font = null

func _ready() -> void:
	if ResourceLoader.exists("res://fonts/Orbitron.ttf"):
		var orbitron: FontFile = load("res://fonts/Orbitron.ttf")
		font_display = FontVariation.new()
		font_display.base_font = orbitron
		font_display.variation_opentype = {"wght": 600}
		font_display.spacing_glyph = 2
		font_display_heavy = FontVariation.new()
		font_display_heavy.base_font = orbitron
		font_display_heavy.variation_opentype = {"wght": 800}
		font_display_heavy.spacing_glyph = 4
	if ResourceLoader.exists("res://fonts/Rajdhani-Medium.ttf"):
		font_body = load("res://fonts/Rajdhani-Medium.ttf")
	if ResourceLoader.exists("res://fonts/Rajdhani-Bold.ttf"):
		font_body_bold = load("res://fonts/Rajdhani-Bold.ttf")

# --- Font application --------------------------------------------------------

func display(l: Control) -> void:
	if font_display:
		l.add_theme_font_override("font", font_display)

func display_heavy(l: Control) -> void:
	if font_display_heavy:
		l.add_theme_font_override("font", font_display_heavy)

func body(l: Control) -> void:
	if font_body:
		l.add_theme_font_override("font", font_body)

func body_bold(l: Control) -> void:
	if font_body_bold:
		l.add_theme_font_override("font", font_body_bold)

# --- Boxes -------------------------------------------------------------------

func _flat_box(bg: Color, border: Color, border_w: int = 0, glow: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	if border_w > 0:
		sb.border_color = border
		sb.border_width_left = border_w
		sb.border_width_right = border_w
		sb.border_width_top = border_w
		sb.border_width_bottom = border_w
	if glow.a > 0.0:
		sb.shadow_color = glow
		sb.shadow_size = 14
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb

func glass_panel(border: Color = ACCENT) -> StyleBoxFlat:
	## Dark translucent panel with a neon border + soft outer glow.
	var sb := _flat_box(PANEL_BG, border, 1,
		Color(border.r, border.g, border.b, 0.20))
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 56
	sb.content_margin_right = 56
	sb.content_margin_top = 40
	sb.content_margin_bottom = 44
	return sb

func chip(accent: Color) -> StyleBoxFlat:
	## Small pill for HUD elements / power-up timers.
	var sb := _flat_box(Color(0.02, 0.04, 0.08, 0.78), accent, 1)
	sb.corner_radius_top_left = 22
	sb.corner_radius_top_right = 22
	sb.corner_radius_bottom_left = 22
	sb.corner_radius_bottom_right = 22
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

# --- Widgets -----------------------------------------------------------------

func style_button(b: Button, color: Color, font_size: int = 38) -> void:
	## Filled button — primary actions. Glow shadow + hover lift.
	b.custom_minimum_size = Vector2(440, 86)
	display(b)
	b.add_theme_font_size_override("font_size", font_size)
	var dark_text := Color(0.01, 0.03, 0.06)
	b.add_theme_color_override("font_color", dark_text)
	b.add_theme_color_override("font_hover_color", dark_text)
	b.add_theme_color_override("font_pressed_color", dark_text)
	b.add_theme_color_override("font_disabled_color", Color(dark_text.r, dark_text.g, dark_text.b, 0.6))
	var glow := Color(color.r, color.g, color.b, 0.35)
	b.add_theme_stylebox_override("normal", _flat_box(color, color, 0, glow))
	b.add_theme_stylebox_override("hover", _flat_box(color.lightened(0.18), color, 0,
		Color(color.r, color.g, color.b, 0.55)))
	b.add_theme_stylebox_override("pressed", _flat_box(color.darkened(0.25), color))
	b.add_theme_stylebox_override("focus", _flat_box(color, color.lightened(0.5), 2, glow))
	b.add_theme_stylebox_override("disabled", _flat_box(Color(color.r, color.g, color.b, 0.35), color))
	_add_hover_pop(b)

func style_button_ghost(b: Button, color: Color, font_size: int = 34) -> void:
	## Outline-only button — secondary / destructive actions.
	b.custom_minimum_size = Vector2(440, 78)
	display(b)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", color)
	b.add_theme_color_override("font_hover_color", color.lightened(0.3))
	b.add_theme_color_override("font_pressed_color", color.darkened(0.2))
	b.add_theme_color_override("font_disabled_color", Color(color.r, color.g, color.b, 0.5))
	var faint := Color(color.r, color.g, color.b, 0.05)
	b.add_theme_stylebox_override("normal", _flat_box(faint, Color(color.r, color.g, color.b, 0.55), 1))
	b.add_theme_stylebox_override("hover", _flat_box(Color(color.r, color.g, color.b, 0.12), color, 1,
		Color(color.r, color.g, color.b, 0.30)))
	b.add_theme_stylebox_override("pressed", _flat_box(Color(color.r, color.g, color.b, 0.22), color, 1))
	b.add_theme_stylebox_override("focus", _flat_box(faint, color.lightened(0.4), 2))
	b.add_theme_stylebox_override("disabled", _flat_box(faint, Color(color.r, color.g, color.b, 0.30), 1))
	_add_hover_pop(b)

func _add_hover_pop(b: Button) -> void:
	## Subtle scale lift on hover. Pivot from centre.
	b.mouse_entered.connect(func():
		b.pivot_offset = b.size * 0.5
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2(1.03, 1.03), 0.08) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))
	b.mouse_exited.connect(func():
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2.ONE, 0.12) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))

func style_title(l: Label, color: Color, font_size: int = 88) -> void:
	display_heavy(l)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)

func style_label(l: Label, color: Color, font_size: int = 30, bold: bool = false) -> void:
	if bold:
		body_bold(l)
	else:
		body(l)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)

func accent_rule(width: float = 280.0, color: Color = ACCENT) -> Control:
	## Thin horizontal neon line, used as a separator under titles.
	var holder := CenterContainer.new()
	var rect := ColorRect.new()
	rect.color = color
	rect.custom_minimum_size = Vector2(width, 3)
	holder.add_child(rect)
	return holder
