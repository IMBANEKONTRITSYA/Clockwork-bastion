extends GutTest
## Smoke-тест сцены боя: создаётся, крутит симуляцию и рисует без ошибок.

const SCENE: PackedScene = preload("res://game/battle/battle.tscn")


func test_scene_runs_300_ticks_without_errors() -> void:
	var root: Node2D = SCENE.instantiate() as Node2D
	add_child_autofree(root)
	var view: BattleView = null
	for child: Node in root.get_children():
		if child is BattleView:
			view = child
	assert_not_null(view)
	view.controller.submit("next_wave")
	for i: int in 40:
		view._process(0.25)
		root._process(0.25)
	assert_eq(view.controller.sim.tick, 300)
	await wait_physics_frames(2)
	assert_true(is_instance_valid(root))
