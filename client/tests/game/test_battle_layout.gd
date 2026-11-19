extends GutTest
## Раскладка экрана: клетки, слоты запаса и поле совпадают по колонкам;
## на любом телефоне нижняя панель прижата к низу, пустых полос нет.

const HEIGHTS: Array[float] = [1920.0, 2400.0]


func test_cell_at_is_inverse_of_cell_center() -> void:
	var layout: BattleLayout = BattleLayout.new()
	for y: int in SimGrid.HEIGHT:
		for x: int in SimGrid.WIDTH:
			assert_eq(layout.cell_at(layout.cell_center(x, y)), Vector2i(x, y))


func test_points_outside_grid_give_no_cell() -> void:
	var layout: BattleLayout = BattleLayout.new()
	assert_eq(layout.cell_at(Vector2(10, layout.grid_origin.y + 10)), Vector2i(-1, -1))
	assert_eq(layout.cell_at(Vector2(500, 500)), Vector2i(-1, -1))


func test_slots_and_buttons_do_not_overlap_grid_or_each_other() -> void:
	for h: float in HEIGHTS:
		var layout: BattleLayout = BattleLayout.new(h)
		var rects: Array[Rect2] = [layout.buy_rect(), layout.speed_rect()]
		for i: int in BattleLayout.SLOTS_SHOWN:
			var center: Vector2 = layout.slot_rect(i).get_center()
			assert_eq(layout.slot_at(center), i)
			assert_eq(layout.cell_at(center), Vector2i(-1, -1))
			rects.append(layout.slot_rect(i))
		for a: int in rects.size():
			assert_lte(rects[a].end.x, BattleLayout.WIDTH, "в ширину экрана")
			for b: int in range(a + 1, rects.size()):
				assert_false(rects[a].intersects(rects[b]), "кнопки %d и %d перекрываются" % [a, b])


func test_bottom_panel_is_pinned_to_bottom_on_any_height() -> void:
	for h: float in HEIGHTS:
		var layout: BattleLayout = BattleLayout.new(h)
		assert_almost_eq(layout.slot_rect(0).end.y, h - BattleLayout.BOTTOM_MARGIN, 0.01)
		var grid_bottom: float = layout.cell_rect(0, SimGrid.HEIGHT - 1).end.y
		assert_lt(grid_bottom, layout.slot_y, "сетка над панелью")
		assert_lt(layout.wall_bottom, layout.grid_origin.y, "Стена над сеткой")


func test_taller_screen_gives_taller_field() -> void:
	var short: BattleLayout = BattleLayout.new(1920.0)
	var tall: BattleLayout = BattleLayout.new(2400.0)
	assert_almost_eq(tall.wall_top - short.wall_top, 480.0, 0.01)


func test_field_lanes_line_up_with_grid_columns() -> void:
	var layout: BattleLayout = BattleLayout.new()
	for x: int in SimGrid.WIDTH:
		assert_almost_eq(layout.lane_x(x * 1000), layout.cell_center(x, 0).x, 0.01)


func test_wall_is_at_zero_distance_and_spawn_at_top() -> void:
	var layout: BattleLayout = BattleLayout.new()
	assert_almost_eq(layout.field_y(0, 12000), layout.wall_top, 0.01)
	assert_almost_eq(layout.field_y(12000, 12000), layout.field_top, 0.01)
