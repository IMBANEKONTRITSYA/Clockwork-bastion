extends Node2D
## Корень сцены боя: создаёт контроллер, вид и HUD, связывает сигналы и
## подстраивает раскладку под реальную высоту экрана (ширина всегда 1080).
## Пока сервера нет, зерно забега берётся локально (на этапе 07 его выдаёт сервер).

var controller: BattleController
var layout: BattleLayout = BattleLayout.new()

var _data: SimData
var _view: BattleView = BattleView.new()
var _hud: BattleHud = BattleHud.new()


func _ready() -> void:
	_data = SimData.load_default()
	add_child(_view)
	add_child(_hud)
	_hud.next_wave_pressed.connect(func() -> void: controller.submit("next_wave"))
	_hud.speed_pressed.connect(func() -> void: controller.toggle_speed())
	_hud.pause_pressed.connect(func() -> void: _view.paused = not _view.paused)
	_hud.buy_pressed.connect(func() -> void: controller.submit("buy"))
	_hud.restart_pressed.connect(start_run)
	get_viewport().size_changed.connect(_relayout)
	start_run()


func _process(_delta: float) -> void:
	if controller != null:
		var model: BattleHudModel = BattleHudModel.from_sim(controller.sim)
		_hud.apply(model, controller.speed, _view.paused)


func start_run(seed_value: int = 0) -> void:
	if seed_value == 0:
		seed_value = randi() | 1
	controller = BattleController.new(_data, seed_value)
	_view.paused = false
	_relayout()


func _relayout() -> void:
	layout = BattleLayout.new(get_viewport().get_visible_rect().size.y)
	_view.bind(controller, layout)
	_hud.place(layout)
