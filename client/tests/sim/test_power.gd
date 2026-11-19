extends GutTest
## Привод: подключение, направление по шахматке, нагрузка и rpm (core-rules §3).

var _data: SimData


func before_all() -> void:
	_data = SimData.load_default()


func _grid_with(cells: Array[Vector2i]) -> SimGrid:
	var grid: SimGrid = SimGrid.new()
	var next_id: int = 1
	for c: Vector2i in cells:
		grid.place(SimGear.create(next_id, "saw", 1, c.x, c.y))
		next_id += 1
	return grid


func test_heart_parity_cells_are_clockwise() -> void:
	assert_true(PowerSystem.is_clockwise_cell(3, 4, false))
	assert_false(PowerSystem.is_clockwise_cell(3, 3, false))
	assert_true(PowerSystem.is_clockwise_cell(3, 2, false))
	assert_false(PowerSystem.is_clockwise_cell(2, 4, false))


func test_reverse_flips_every_cell() -> void:
	assert_false(PowerSystem.is_clockwise_cell(3, 4, true))
	assert_true(PowerSystem.is_clockwise_cell(3, 3, true))


func test_chain_from_heart_is_connected_with_alternating_directions() -> void:
	var grid: SimGrid = _grid_with([Vector2i(3, 3), Vector2i(3, 2), Vector2i(3, 1)])
	var load: int = PowerSystem.recompute(grid, _data, 8, false)
	assert_eq(load, 3)
	assert_true(grid.gear_at(3, 3).connected)
	assert_false(grid.gear_at(3, 3).clockwise)
	assert_true(grid.gear_at(3, 2).clockwise)
	assert_false(grid.gear_at(3, 1).clockwise)


func test_gap_disconnects_the_rest() -> void:
	var grid: SimGrid = _grid_with([Vector2i(3, 3), Vector2i(3, 1), Vector2i(3, 0)])
	var load: int = PowerSystem.recompute(grid, _data, 8, false)
	assert_eq(load, 1)
	assert_false(grid.gear_at(3, 1).connected)
	assert_eq(grid.gear_at(3, 1).rpm_x1000, 0)
	assert_false(grid.gear_at(3, 0).connected)


func test_diagonal_does_not_connect() -> void:
	var grid: SimGrid = _grid_with([Vector2i(2, 3)])
	assert_eq(PowerSystem.recompute(grid, _data, 8, false), 0)
	assert_false(grid.gear_at(2, 3).connected)


func test_side_neighbours_of_heart_connect() -> void:
	var grid: SimGrid = _grid_with([Vector2i(2, 4), Vector2i(4, 4)])
	assert_eq(PowerSystem.recompute(grid, _data, 8, false), 2)


func test_full_speed_when_load_within_power() -> void:
	var grid: SimGrid = _grid_with([Vector2i(3, 3)])
	PowerSystem.recompute(grid, _data, 8, false)
	assert_eq(grid.gear_at(3, 3).rpm_x1000, 60000)


func test_overload_slows_proportionally() -> void:
	var cells: Array[Vector2i] = []
	for x: int in 7:
		cells.append(Vector2i(x, 3))
	cells.append(Vector2i(2, 4))
	cells.append(Vector2i(4, 4))
	cells.append(Vector2i(3, 2))
	var grid: SimGrid = _grid_with(cells)
	var load: int = PowerSystem.recompute(grid, _data, 8, false)
	assert_eq(load, 10)
	assert_eq(PowerSystem.power_factor(8, 10), 800)
	assert_eq(grid.gear_at(0, 3).rpm_x1000, 48000)


func test_bigger_level_spins_slower() -> void:
	var grid: SimGrid = SimGrid.new()
	grid.place(SimGear.create(1, "saw", 3, 3, 3))
	PowerSystem.recompute(grid, _data, 8, false)
	assert_eq(grid.gear_at(3, 3).rpm_x1000, 38400)


func test_bonus_speeds_up() -> void:
	var grid: SimGrid = _grid_with([Vector2i(3, 3)])
	PowerSystem.recompute(grid, _data, 8, false, 150)
	assert_eq(grid.gear_at(3, 3).rpm_x1000, 69000)


func test_power_factor_without_load_is_one() -> void:
	assert_eq(PowerSystem.power_factor(8, 0), 1000)


func test_branch_through_loop_counts_each_gear_once() -> void:
	var grid: SimGrid = _grid_with(
		[Vector2i(3, 3), Vector2i(2, 3), Vector2i(2, 4), Vector2i(4, 3), Vector2i(4, 4)]
	)
	assert_eq(PowerSystem.recompute(grid, _data, 8, false), 5)
