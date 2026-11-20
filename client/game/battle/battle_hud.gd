class_name BattleHud
extends CanvasLayer
## Интерфейс боя поверх поля: верхняя панель (волна, гайки, убийства, Реверс), колонка
## круглых кнопок слева (пауза, ×2), большая кнопка «В бой!» с автостартом между волнами,
## широкая кнопка «Купить» внизу и окно итога. Связь наверх — только сигналами.

signal next_wave_pressed
signal speed_pressed
signal pause_pressed
signal buy_pressed
signal restart_pressed

const FONT_TOP: int = 34

var _wave: Label = Label.new()
var _nuts: Label = Label.new()
var _kills: Label = Label.new()
var _reverse: Label = Label.new()
var _load: Label = Label.new()
var _pause: Button = Button.new()
var _speed: Button = Button.new()
var _buy: Button = Button.new()
var _fight: Button = Button.new()
var _fight_hint: Label = Label.new()
var _result: PanelContainer = PanelContainer.new()
var _result_title: Label = Label.new()
var _result_button: Button = Button.new()
var _paused_label: Label = Label.new()


func _ready() -> void:
	_wave.position = Vector2(24, 18)
	_nuts.position = Vector2(330, 18)
	_kills.position = Vector2(600, 18)
	_reverse.position = Vector2(820, 18)
	for label: Label in [_wave, _nuts, _kills, _reverse]:
		label.add_theme_font_size_override("font_size", FONT_TOP)
		label.add_theme_color_override("font_color", BattlePalette.TEXT)
		add_child(label)
	_load.position = Vector2(24, 86)
	_load.add_theme_font_size_override("font_size", 28)
	add_child(_load)
	_style_round(_pause, 55)
	_style_round(_speed, 55)
	_pause.pressed.connect(func() -> void: pause_pressed.emit())
	_speed.pressed.connect(func() -> void: speed_pressed.emit())
	_style_round(_buy, 24)
	_buy.add_theme_font_size_override("font_size", 46)
	_buy.pressed.connect(func() -> void: buy_pressed.emit())
	_style_round(_fight, 30)
	_fight.add_theme_font_size_override("font_size", 56)
	_fight.pressed.connect(func() -> void: next_wave_pressed.emit())
	_fight_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fight_hint.add_theme_font_size_override("font_size", 30)
	_fight_hint.add_theme_color_override("font_color", BattlePalette.TEXT)
	_paused_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_paused_label.add_theme_font_size_override("font_size", 64)
	_paused_label.add_theme_color_override("font_color", BattlePalette.TEXT)
	for node: Control in [_pause, _speed, _buy, _fight, _fight_hint, _paused_label]:
		add_child(node)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title.add_theme_font_size_override("font_size", 56)
	_style_round(_result_button, 24)
	_result_button.add_theme_font_size_override("font_size", 44)
	_result_button.custom_minimum_size = Vector2(420, 120)
	_result_button.pressed.connect(func() -> void: restart_pressed.emit())
	box.add_child(_result_title)
	box.add_child(_result_button)
	_result.add_child(box)
	_result.add_theme_stylebox_override("panel", _box(BattlePalette.TOP_BAR, 28, 6))
	_result.size = Vector2(640, 340)
	add_child(_result)


## Расставляет кнопки и окна по раскладке экрана.
func place(layout: BattleLayout) -> void:
	_put(_pause, layout.side_button_rect(0))
	_put(_speed, layout.side_button_rect(1))
	_put(_buy, layout.buy_rect())
	var fight: Rect2 = layout.fight_rect()
	_put(_fight, fight)
	_put(
		_fight_hint,
		Rect2(fight.position + Vector2(0, fight.size.y + 10), Vector2(fight.size.x, 50))
	)
	_result.position = layout.field_center() - _result.size * 0.5
	_put(_paused_label, Rect2(layout.field_center() - Vector2(300, 50), Vector2(600, 100)))


func apply(model: BattleHudModel, speed: int, paused: bool) -> void:
	_wave.text = _fmt("HUD_WAVE", [model.wave, model.waves_total])
	_nuts.text = _fmt("HUD_NUTS", [model.nuts])
	_kills.text = _fmt("HUD_KILLS", [model.kills])
	if model.reverse_ready >= 1000:
		_reverse.text = tr("HUD_REVERSE_READY")
	else:
		_reverse.text = _fmt("HUD_REVERSE_WAIT", [model.reverse_seconds_left])
	_load.text = _fmt("HUD_LOAD", [model.gear_load, model.power])
	var load_color: Color = Color(1.0, 0.4, 0.35) if model.overloaded else BattlePalette.TEXT
	_load.add_theme_color_override("font_color", load_color)
	_pause.text = tr("BTN_RESUME") if paused else tr("BTN_PAUSE")
	_speed.text = tr("BTN_SPEED_2") if speed == 2 else tr("BTN_SPEED_1")
	_buy.text = _fmt("BTN_BUY", [model.price])
	_buy.disabled = not model.can_buy or paused
	var between_waves: bool = model.overlay == BattleHudModel.Overlay.PAUSE and not paused
	_fight.visible = between_waves
	_fight_hint.visible = between_waves
	if between_waves:
		_fight.text = tr("BTN_FIGHT")
		var hint: String = _fmt("HUD_AUTOSTART", [model.pause_seconds_left])
		if model.next_boss_key != "":
			hint = _fmt("HUD_BOSS_AHEAD", [tr(model.next_boss_key)]) + "  ·  " + hint
		_fight_hint.text = hint
	_paused_label.visible = paused
	_paused_label.text = tr("TITLE_PAUSED")
	var finished: bool = model.overlay in [BattleHudModel.Overlay.WON, BattleHudModel.Overlay.LOST]
	_result.visible = finished
	if finished:
		var won: bool = model.overlay == BattleHudModel.Overlay.WON
		_result_title.text = tr("TITLE_WON") if won else tr("TITLE_LOST")
		_result_button.text = tr("BTN_RESTART")


## Перевод с подстановкой; если перевода нет (ключ вернулся как есть) — показываем ключ.
func _fmt(key: String, args: Array) -> String:
	var pattern: String = tr(key)
	if pattern == key:
		return key
	return pattern % args


static func _put(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size


## Латунная кнопка со скруглением: обычная, нажатая и неактивная.
static func _style_round(button: Button, radius: int) -> void:
	button.add_theme_font_size_override("font_size", 40)
	button.add_theme_color_override("font_color", BattlePalette.TEXT_DARK)
	button.add_theme_color_override("font_pressed_color", BattlePalette.TEXT_DARK)
	button.add_theme_color_override("font_hover_color", BattlePalette.TEXT_DARK)
	button.add_theme_color_override("font_disabled_color", BattlePalette.CELL_PLUS)
	button.add_theme_stylebox_override("normal", _box(BattlePalette.BRASS, radius, 5))
	button.add_theme_stylebox_override("hover", _box(BattlePalette.BRASS, radius, 5))
	button.add_theme_stylebox_override("pressed", _box(BattlePalette.COPPER, radius, 5))
	button.add_theme_stylebox_override("disabled", _box(BattlePalette.GEAR_OFF, radius, 5))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func _box(color: Color, radius: int, border: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border)
	box.border_color = BattlePalette.BRASS_DARK
	return box
