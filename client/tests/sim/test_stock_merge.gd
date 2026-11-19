extends GutTest
## Запас и покупка (1–3 случайные шестерни за гайки, цена растёт) и мерж (core-rules §4–5).


func _item(type: String, level: int = 1) -> BattleSim.StockItem:
	var item: BattleSim.StockItem = BattleSim.StockItem.new()
	item.type = type
	item.level = level
	return item


func _set_stock(sim: BattleSim, items: Array[BattleSim.StockItem]) -> void:
	sim.stock.clear()
	for item: BattleSim.StockItem in items:
		sim.stock.append(item)


func test_run_starts_with_two_gears_and_ten_nuts() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	assert_eq(sim.stock.size(), 2)
	assert_eq(sim.nuts, 10)
	assert_eq(sim.price, 8)


func test_no_gears_arrive_by_themselves() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	sim.apply_input("next_wave", {})
	SimTestHelpers.run_ticks(sim, 600)
	assert_eq(sim.stock.size(), 2)


func test_buy_spends_price_raises_it_and_adds_1_to_3_gears() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	_set_stock(sim, [])
	assert_true(sim.apply_input("buy", {}))
	assert_eq(sim.nuts, 2)
	assert_eq(sim.price, 12)
	assert_between(sim.last_buy_count, 1, 3)
	assert_eq(sim.stock.size(), sim.last_buy_count)


func test_buy_is_deterministic_for_seed() -> void:
	var a: BattleSim = SimTestHelpers.new_sim(77)
	var b: BattleSim = SimTestHelpers.new_sim(77)
	a.apply_input("buy", {})
	b.apply_input("buy", {})
	assert_eq(a.last_buy_count, b.last_buy_count)
	assert_eq(a.state_hash(), b.state_hash())


func test_buy_counts_cover_1_2_and_3() -> void:
	var seen: Dictionary = {}
	for seed_value: int in range(1, 200):
		var sim: BattleSim = SimTestHelpers.new_sim(seed_value)
		_set_stock(sim, [])
		sim.apply_input("buy", {})
		seen[sim.last_buy_count] = true
	assert_true(seen.has(1) and seen.has(2) and seen.has(3), "выпадают 1, 2 и 3: %s" % [seen])


func test_buy_without_enough_nuts_is_rejected() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	sim.nuts = 5
	var before: String = sim.state_hash()
	assert_false(sim.apply_input("buy", {}))
	assert_eq(sim.state_hash(), before)


func test_buy_with_full_stock_is_rejected() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	_set_stock(sim, [_item("saw"), _item("saw"), _item("saw"), _item("saw")])
	assert_false(sim.can_buy())
	assert_false(sim.apply_input("buy", {}))


func test_gears_beyond_free_slots_melt_into_nuts() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	_set_stock(sim, [_item("saw"), _item("saw"), _item("saw"), _item("saw")])
	sim.nuts = 0
	sim.call("_add_to_stock", "steam")
	assert_eq(sim.stock.size(), 4)
	assert_eq(sim.nuts, 1)


func test_place_takes_item_from_slot() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	_set_stock(sim, [_item("saw"), _item("steam")])
	assert_true(sim.apply_input("place", {"slot": 1, "x": 2, "y": 2}))
	assert_eq(sim.grid.gear_at(2, 2).type, "steam")
	assert_eq(sim.stock.size(), 1)


func test_place_on_same_gear_merges() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	_set_stock(sim, [_item("saw"), _item("saw")])
	sim.apply_input("place", {"slot": 0, "x": 2, "y": 2})
	assert_true(sim.apply_input("place", {"slot": 0, "x": 2, "y": 2}))
	assert_eq(sim.grid.gear_at(2, 2).level, 2)
	assert_eq(sim.grid.gears.size(), 1)


func test_place_on_different_gear_is_rejected() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	_set_stock(sim, [_item("saw"), _item("steam")])
	sim.apply_input("place", {"slot": 0, "x": 2, "y": 2})
	assert_false(sim.apply_input("place", {"slot": 0, "x": 2, "y": 2}))
	assert_eq(sim.stock.size(), 1, "шестерня осталась в запасе")


func test_merge_stops_at_level_5() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	_set_stock(sim, [_item("saw", 5), _item("saw", 5)])
	sim.apply_input("place", {"slot": 0, "x": 2, "y": 2})
	assert_false(sim.apply_input("place", {"slot": 0, "x": 2, "y": 2}))


func test_move_to_empty_cell_and_merge_by_move() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	_set_stock(sim, [_item("saw"), _item("saw")])
	sim.apply_input("place", {"slot": 0, "x": 2, "y": 2})
	sim.apply_input("place", {"slot": 0, "x": 1, "y": 3})
	assert_true(sim.apply_input("move", {"from_x": 1, "from_y": 3, "x": 1, "y": 2}))
	assert_true(sim.grid.is_free(1, 3))
	assert_true(sim.apply_input("move", {"from_x": 1, "from_y": 2, "x": 2, "y": 2}))
	assert_eq(sim.grid.gear_at(2, 2).level, 2)
	assert_true(sim.grid.is_free(1, 2))


func test_invalid_inputs_change_nothing() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	var before: String = sim.state_hash()
	assert_false(sim.apply_input("place", {"slot": 9, "x": 2, "y": 2}))
	assert_false(sim.apply_input("place", {"slot": 0, "x": 2, "y": 3}), "клетка Сердца")
	assert_false(sim.apply_input("place", {"slot": 0, "x": 5, "y": 0}), "вне сетки")
	assert_false(sim.apply_input("place", {"slot": "x", "x": 2, "y": 2}), "мусор в аргументах")
	assert_false(sim.apply_input("move", {"from_x": 0, "from_y": 0, "x": 1, "y": 0}))
	assert_false(sim.apply_input("fly", {}))
	assert_eq(sim.state_hash(), before)


func test_json_numbers_as_floats_are_accepted() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	var args: Dictionary = JSON.parse_string('{"slot": 0, "x": 2, "y": 2}')
	assert_true(sim.apply_input("place", args))
