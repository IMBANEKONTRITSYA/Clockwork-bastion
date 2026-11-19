extends Node2D
## Корень сцены боя: создаёт контроллер, вид и HUD, связывает сигналы.
## Пока сервера нет, зерно забега берётся локально (на этапе 07 его выдаёт сервер).

var controller: BattleController

var _data: SimData
var _view: BattleView = BattleView.new()
var _hud: BattleHud = BattleHud.new()


func _ready() -> void:
	_data = SimData.load_default()
	add_child(_view)
	add_child(_hud)
	_hud.next_wave_pressed.connect(func() -> void: controller.submit("next_wave"))
	_hud.speed_pressed.connect(func() -> void: controller.toggle_speed())
	_hud.restart_pressed.connect(start_run)
	start_run()


func _process(_delta: float) -> void:
	if controller != null:
		_hud.apply(BattleHudModel.from_sim(controller.sim), controller.speed)


func start_run(seed_value: int = 0) -> void:
	if seed_value == 0:
		seed_value = randi() | 1
	controller = BattleController.new(_data, seed_value)
	_view.bind(controller)
