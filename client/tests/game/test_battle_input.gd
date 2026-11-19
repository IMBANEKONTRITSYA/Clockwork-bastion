extends GutTest
## Жест → запись в журнале: с конвейера на сетку, по сетке, тап по Сердцу.


func _setup() -> BattleInput:
	return BattleInput.new(BattleController.new(SimData.load_default(), 9))


func _action(input: BattleInput, index: int) -> String:
	var entry: Array = input.controller.run_log.inputs[index]
	var action: String = entry[1]
	return action


func _args(input: BattleInput, index: int) -> Dictionary:
	var entry: Array = input.controller.run_log.inputs[index]
	var args: Dictionary = entry[2]
	return args


func test_drag_from_slot_to_cell_places_gear() -> void:
	var input: BattleInput = _setup()
	input.press(BattleLayout.slot_rect(0).get_center())
	assert_eq(input.drag, BattleInput.Drag.SLOT)
	assert_ne(input.dragged_type(), "")
	assert_true(input.release(BattleLayout.cell_center(3, 3)))
	assert_eq(_action(input, 0), "place")
	assert_eq(_args(input, 0), {"slot": 0, "x": 3, "y": 3})
	assert_eq(input.drag, BattleInput.Drag.NONE)


func test_drop_outside_grid_does_nothing() -> void:
	var input: BattleInput = _setup()
	input.press(BattleLayout.slot_rect(0).get_center())
	assert_false(input.release(Vector2(540, 500)))
	assert_eq(input.controller.run_log.inputs.size(), 0)


func test_empty_slot_does_not_start_drag() -> void:
	var input: BattleInput = _setup()
	input.press(BattleLayout.slot_rect(3).get_center())
	assert_eq(input.drag, BattleInput.Drag.NONE)


func test_drag_gear_on_grid_moves_it() -> void:
	var input: BattleInput = _setup()
	input.press(BattleLayout.slot_rect(0).get_center())
	input.release(BattleLayout.cell_center(2, 4))
	input.press(BattleLayout.cell_center(2, 4))
	assert_eq(input.drag, BattleInput.Drag.GEAR)
	assert_true(input.release(BattleLayout.cell_center(2, 3)))
	assert_eq(_action(input, 1), "move")
	assert_eq(_args(input, 1), {"from_x": 2, "from_y": 4, "x": 2, "y": 3})


func test_tap_on_heart_reverses() -> void:
	var input: BattleInput = _setup()
	input.press(BattleLayout.cell_center(SimGrid.HEART_X, SimGrid.HEART_Y))
	assert_true(input.controller.sim.reversed)
	assert_eq(_action(input, 0), "reverse")
