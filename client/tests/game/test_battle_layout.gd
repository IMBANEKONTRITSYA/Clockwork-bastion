extends GutTest
## Раскладка экрана: клетки, слоты запаса и поле совпадают по колонкам;
## на любом телефоне «Купить» прижата к низу, кнопки не перекрываются, пустых полос нет.

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


func test_bottom_controls_do_not_overlap_each_other_or_grid() -> void:
	for h: float in HEIGHTS:
		var layout: BattleLayout = BattleLayout.new(h)
		var grid: Rect2 = Rect2(
			layout.grid_origin,
			Vector2(BattleLayout.CELL * SimGrid.WIDTH, BattleLayout.CELL * SimGrid.HEIGHT)
		)
		var rects: Array[Rect2] = [layout.buy_rect(), grid]
		for i: int in BattleLayout.SLOTS_SHOWN:
			var center: Vector2 = layout.slot_rect(i).get_center()
			assert_eq(layout.slot_at(center), i)
			rects.append(layout.slot_rect(i))
		for a: int in rects.size():
			assert_true(rects[a].position.x >= 0.0 and rects[a].end.x <= BattleLayout.WIDTH)
			for b: int in range(a + 1, rects.size()):
				assert_false(
					rects[a].intersects(rects[b]), "h=%d: %d и %d перекрываются" % [int(h), a, b]
				)


func test_buy_button_is_pinned_to_bottom_on_any_height() -> void:
	for h: float in HEIGHTS:
		var layout: BattleLayout = BattleLayout.new(h)
		assert_almost_eq(layout.buy_rect().end.y, h - BattleLayout.BOTTOM_MARGIN, 0.01)
		assert_lt(layout.slot_rect(0).end.y, layout.buy_rect().position.y)
		assert_lt(layout.wall_bottom, layout.grid_origin.y, "Стена над сеткой")


func test_side_buttons_and_fight_are_inside_field_and_apart() -> void:
	for h: float in HEIGHTS:
		var layout: BattleLayout = BattleLayout.new(h)
		var field: Rect2 = layout.field_rect()
		var pause: Rect2 = layout.side_button_rect(0)
		var speed: Rect2 = layout.side_button_rect(1)
		var fight: Rect2 = layout.fight_rect()
		for r: Rect2 in [pause, speed, fight]:
			assert_true(field.encloses(r), "кнопка внутри поля при h=%d" % int(h))
		assert_false(pause.intersects(speed))
		assert_false(fight.intersects(pause) or fight.intersects(speed))
		assert_lt(layout.boss_bar_rect().end.y, layout.wall_top, "полоса босса над воротами")


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
