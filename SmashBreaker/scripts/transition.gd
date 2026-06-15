extends CanvasLayer
## Transition — autoload. Fade-to-black between scene changes so navigation
## feels deliberate instead of an instant snap.

var _rect: ColorRect = null
var _busy := false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)

func go(path: String) -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	var tw := create_tween()
	tw.tween_property(_rect, "color:a", 1.0, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): get_tree().change_scene_to_file(path))
	tw.tween_property(_rect, "color:a", 0.0, 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): _busy = false)
