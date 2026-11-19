extends GutTest
## Раскладка экрана: клетки, слоты конвейера и поле совпадают по колонкам.


func test_cell_at_is_inverse_of_cell_center() -> void:
	for y: int in SimGrid.HEIGHT:
		for x: int in SimGrid.WIDTH:
			assert_eq(BattleLayout.cell_at(BattleLayout.cell_center(x, y)), Vector2i(x, y))


func test_points_outside_grid_give_no_cell() -> void:
	assert_eq(BattleLayout.cell_at(Vector2(10, 1100)), Vector2i(-1, -1))
	assert_eq(BattleLayout.cell_at(Vector2(500, 500)), Vector2i(-1, -1))


func test_slots_do_not_overlap_grid_and_are_found() -> void:
	for i: int in BattleLayout.SLOTS_SHOWN:
		var center: Vector2 = BattleLayout.slot_rect(i).get_center()
		assert_eq(BattleLayout.slot_at(center), i)
		assert_eq(BattleLayout.cell_at(center), Vector2i(-1, -1))


func test_field_lanes_line_up_with_grid_columns() -> void:
	for x: int in SimGrid.WIDTH:
		assert_almost_eq(BattleLayout.lane_x(x * 1000), BattleLayout.cell_center(x, 0).x, 0.01)


func test_wall_is_at_zero_distance_and_spawn_at_top() -> void:
	assert_almost_eq(BattleLayout.field_y(0, 12000), BattleLayout.WALL_TOP, 0.01)
	assert_almost_eq(BattleLayout.field_y(12000, 12000), BattleLayout.FIELD_TOP, 0.01)
