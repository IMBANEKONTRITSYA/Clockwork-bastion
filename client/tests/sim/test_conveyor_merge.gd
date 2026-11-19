extends GutTest
## Конвейер (каждые 150 тиков, 3 слота, переполнение → +1 гайка) и мерж (core-rules §4–5).


func _item(type: String, level: int = 1) -> BattleSim.ConveyorItem:
	var item: BattleSim.ConveyorItem = BattleSim.ConveyorItem.new()
	item.type = type
	item.level = level
	return item


func _set_conveyor(sim: BattleSim, items: Array[BattleSim.ConveyorItem]) -> void:
	sim.conveyor.clear()
	for item: BattleSim.ConveyorItem in items:
		sim.conveyor.append(item)


func test_run_starts_with_two_conveyor_items() -> void:
	assert_eq(SimTestHelpers.new_sim().conveyor.size(), 2)


func test_conveyor_delivers_every_150_ticks_during_wave() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	sim.apply_input("next_wave", {})
	SimTestHelpers.run_ticks(sim, 149)
	assert_eq(sim.conveyor.size(), 2)
	sim.advance()
	assert_eq(sim.conveyor.size(), 3)


func test_conveyor_overflow_melts_oldest_for_one_nut() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	_set_conveyor(sim, [_item("saw"), _item("steam"), _item("saw", 2)])
	sim.apply_input("next_wave", {})
	SimTestHelpers.run_ticks(sim, 150)
	assert_eq(sim.conveyor.size(), 3)
	assert_eq(sim.nuts, 1)
	assert_eq(sim.conveyor[0].type, "steam", "ушла самая старая")


func test_place_takes_item_from_slot() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	_set_conveyor(sim, [_item("saw"), _item("steam")])
	assert_true(sim.apply_input("place", {"slot": 1, "x": 3, "y": 3}))
	assert_eq(sim.grid.gear_at(3, 3).type, "steam")
	assert_eq(sim.conveyor.size(), 1)


func test_place_on_same_gear_merges() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	_set_conveyor(sim, [_item("saw"), _item("saw")])
	sim.apply_input("place", {"slot": 0, "x": 3, "y": 3})
	assert_true(sim.apply_input("place", {"slot": 0, "x": 3, "y": 3}))
	assert_eq(sim.grid.gear_at(3, 3).level, 2)
	assert_eq(sim.grid.gears.size(), 1)


func test_place_on_different_gear_is_rejected() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	_set_conveyor(sim, [_item("saw"), _item("steam")])
	sim.apply_input("place", {"slot": 0, "x": 3, "y": 3})
	assert_false(sim.apply_input("place", {"slot": 0, "x": 3, "y": 3}))
	assert_eq(sim.conveyor.size(), 1, "предмет остался на конвейере")


func test_merge_stops_at_level_5() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	_set_conveyor(sim, [_item("saw", 5), _item("saw", 5)])
	sim.apply_input("place", {"slot": 0, "x": 3, "y": 3})
	assert_false(sim.apply_input("place", {"slot": 0, "x": 3, "y": 3}))


func test_move_to_empty_cell_and_merge_by_move() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	_set_conveyor(sim, [_item("saw"), _item("saw")])
	sim.apply_input("place", {"slot": 0, "x": 3, "y": 3})
	sim.apply_input("place", {"slot": 0, "x": 2, "y": 4})
	assert_true(sim.apply_input("move", {"from_x": 2, "from_y": 4, "x": 2, "y": 3}))
	assert_true(sim.grid.is_free(2, 4))
	assert_true(sim.apply_input("move", {"from_x": 2, "from_y": 3, "x": 3, "y": 3}))
	assert_eq(sim.grid.gear_at(3, 3).level, 2)
	assert_true(sim.grid.is_free(2, 3))


func test_invalid_inputs_change_nothing() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	var before: String = sim.state_hash()
	assert_false(sim.apply_input("place", {"slot": 9, "x": 3, "y": 3}))
	assert_false(sim.apply_input("place", {"slot": 0, "x": 3, "y": 4}), "клетка Сердца")
	assert_false(sim.apply_input("place", {"slot": 0, "x": 7, "y": 0}), "вне сетки")
	assert_false(sim.apply_input("place", {"slot": "x", "x": 3, "y": 3}), "мусор в аргументах")
	assert_false(sim.apply_input("move", {"from_x": 0, "from_y": 0, "x": 1, "y": 0}))
	assert_false(sim.apply_input("fly", {}))
	assert_eq(sim.state_hash(), before)


func test_json_numbers_as_floats_are_accepted() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	var args: Dictionary = JSON.parse_string('{"slot": 0, "x": 3, "y": 3}')
	assert_true(sim.apply_input("place", args))
