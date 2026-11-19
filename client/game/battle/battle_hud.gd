class_name BattleHud
extends CanvasLayer
## Верхняя панель (волна, гайки, Стена, нагрузка, Реверс), кнопки «Купить» и ×2,
## оверлей паузы / итога. Связь наверх — только сигналами.

signal next_wave_pressed
signal speed_pressed
signal buy_pressed
signal restart_pressed

var _wave: Label = Label.new()
var _nuts: Label = Label.new()
var _wall: Label = Label.new()
var _load: Label = Label.new()
var _reverse: Label = Label.new()
var _buy: Button = Button.new()
var _speed: Button = Button.new()
var _overlay: PanelContainer = PanelContainer.new()
var _overlay_title: Label = Label.new()
var _overlay_button: Button = Button.new()
var _overlay_kind: BattleHudModel.Overlay = BattleHudModel.Overlay.NONE


func _ready() -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.position = Vector2(20, 20)
	bar.size = Vector2(1040, 80)
	bar.add_theme_constant_override("separation", 28)
	for label: Label in [_wave, _nuts, _wall, _load, _reverse]:
		label.add_theme_font_size_override("font_size", 30)
		bar.add_child(label)
	add_child(bar)
	_buy.add_theme_font_size_override("font_size", 34)
	_buy.pressed.connect(func() -> void: buy_pressed.emit())
	add_child(_buy)
	_speed.add_theme_font_size_override("font_size", 40)
	_speed.pressed.connect(func() -> void: speed_pressed.emit())
	add_child(_speed)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_title.add_theme_font_size_override("font_size", 52)
	_overlay_button.add_theme_font_size_override("font_size", 44)
	_overlay_button.custom_minimum_size = Vector2(420, 120)
	_overlay_button.pressed.connect(_on_overlay_button)
	box.add_child(_overlay_title)
	box.add_child(_overlay_button)
	_overlay.add_child(box)
	_overlay.size = Vector2(600, 320)
	add_child(_overlay)


## Расставляет кнопки и оверлей по раскладке экрана.
func place(layout: BattleLayout) -> void:
	var buy: Rect2 = layout.buy_rect()
	_buy.position = buy.position
	_buy.size = buy.size
	var speed: Rect2 = layout.speed_rect()
	_speed.position = speed.position
	_speed.size = speed.size
	_overlay.position = layout.field_center() - _overlay.size * 0.5


func apply(model: BattleHudModel, speed: int) -> void:
	_wave.text = _fmt("HUD_WAVE", [model.wave, model.waves_total])
	_nuts.text = _fmt("HUD_NUTS", [model.nuts])
	_wall.text = _fmt("HUD_WALL", [model.wall, model.wall_max])
	_load.text = _fmt("HUD_LOAD", [model.gear_load, model.power])
	_load.modulate = Color(1.0, 0.4, 0.35) if model.overloaded else Color.WHITE
	if model.reverse_ready >= 1000:
		_reverse.text = tr("HUD_REVERSE_READY")
	else:
		_reverse.text = _fmt("HUD_REVERSE_WAIT", [model.reverse_seconds_left])
	_buy.text = _fmt("BTN_BUY", [model.price])
	_buy.disabled = not model.can_buy
	_speed.text = tr("BTN_SPEED_2") if speed == 2 else tr("BTN_SPEED_1")
	_overlay_kind = model.overlay
	_overlay.visible = model.overlay != BattleHudModel.Overlay.NONE
	match model.overlay:
		BattleHudModel.Overlay.PAUSE:
			_overlay_title.text = _fmt("TITLE_PAUSE", [model.pause_seconds_left])
			_overlay_button.text = tr("BTN_NEXT_WAVE")
		BattleHudModel.Overlay.WON:
			_overlay_title.text = tr("TITLE_WON")
			_overlay_button.text = tr("BTN_RESTART")
		BattleHudModel.Overlay.LOST:
			_overlay_title.text = tr("TITLE_LOST")
			_overlay_button.text = tr("BTN_RESTART")


## Перевод с подстановкой; если перевода нет (ключ вернулся как есть) — показываем ключ.
func _fmt(key: String, args: Array) -> String:
	var pattern: String = tr(key)
	if pattern == key:
		return key
	return pattern % args


func _on_overlay_button() -> void:
	if _overlay_kind == BattleHudModel.Overlay.PAUSE:
		next_wave_pressed.emit()
	else:
		restart_pressed.emit()
