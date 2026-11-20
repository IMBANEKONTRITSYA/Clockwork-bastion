extends GutTest
## Сетка 5×4: занятость клеток, Сердце (2, 3), перестановка, препятствия.


func test_heart_cell_is_not_free() -> void:
	var grid: SimGrid = SimGrid.new()
	assert_eq(grid.cell(2, 3), SimGrid.HEART)
	assert_false(grid.is_free(2, 3))


func test_out_of_bounds_is_blocked() -> void:
	var grid: SimGrid = SimGrid.new()
	assert_eq(grid.cell(-1, 0), SimGrid.BLOCKED)
	assert_eq(grid.cell(5, 0), SimGrid.BLOCKED)
	assert_eq(grid.cell(0, 4), SimGrid.BLOCKED)


func test_place_and_find_gear() -> void:
	var grid: SimGrid = SimGrid.new()
	assert_true(grid.place(SimGear.create(1, "saw", 1, 2, 2)))
	assert_eq(grid.gear_at(2, 2).id, 1)
	assert_false(grid.place(SimGear.create(2, "saw", 1, 2, 2)), "клетка занята")
	assert_false(grid.place(SimGear.create(3, "saw", 1, 2, 3)), "клетка Сердца")


func test_gears_stay_sorted_by_id() -> void:
	var grid: SimGrid = SimGrid.new()
	grid.place(SimGear.create(5, "saw", 1, 0, 0))
	grid.place(SimGear.create(2, "saw", 1, 1, 0))
	grid.place(SimGear.create(9, "saw", 1, 2, 0))
	var ids: Array[int] = []
	for g: SimGear in grid.gears:
		ids.append(g.id)
	assert_eq(ids, [2, 5, 9])


func test_move_frees_old_cell() -> void:
	var grid: SimGrid = SimGrid.new()
	grid.place(SimGear.create(1, "saw", 1, 2, 2))
	assert_true(grid.move(1, 1, 2))
	assert_true(grid.is_free(2, 2))
	assert_eq(grid.gear_at(1, 2).id, 1)


func test_remove_frees_cell() -> void:
	var grid: SimGrid = SimGrid.new()
	grid.place(SimGear.create(1, "saw", 1, 2, 2))
	grid.remove(1)
	assert_true(grid.is_free(2, 2))
	assert_eq(grid.gears.size(), 0)


func test_blocked_cell_rejects_gears_until_unblocked() -> void:
	var grid: SimGrid = SimGrid.new()
	assert_true(grid.block(0, 0))
	assert_false(grid.place(SimGear.create(1, "saw", 1, 0, 0)))
	grid.unblock(0, 0)
	assert_true(grid.place(SimGear.create(1, "saw", 1, 0, 0)))
