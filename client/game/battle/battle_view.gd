class_name BattleView
extends Node2D
## Рисует бой в стиле «латунь и медь» по состоянию симуляции: зубчатые шестерни с номером
## уровня, вращающиеся с настоящей скоростью; латунные ворота-Стена; монстры и боссы с
## полосами здоровья. Состояние только читает; жесты отдаёт в BattleInput.
## Между тиками монстры двигаются плавно (интерполяция).

const EFFECT_CAPACITY: int = 64
const HIT_FLASH_SECONDS: float = 0.12
const MONSTER_RADIUS: float = 26.0
const BOSS_RADIUS: float = 64.0
const GEAR_RADIUS: float = 74.0
const GEAR_TEETH: int = 10
const HEART_TEETH: int = 12
const LEVEL_FONT: int = 64
## Экранное вращение медленнее настоящего, чтобы зубья читались глазом.
const VISUAL_SPIN: float = 0.25

var controller: BattleController
var input: BattleInput
var layout: BattleLayout = BattleLayout.new()
var effects: EffectPool = EffectPool.new(EFFECT_CAPACITY)
## Пауза отображения: время боя стоит, в журнал ничего не пишется.
var paused: bool = false

var _prev_positions: Dictionary = {}
var _angles: Dictionary = {}
var _heart_angle: float = 0.0
var _font: Font = ThemeDB.fallback_font


func bind(battle: BattleController, screen_layout: BattleLayout) -> void:
	controller = battle
	layout = screen_layout
	input = BattleInput.new(battle, layout)
	_prev_positions.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if controller == null:
		return
	if not paused:
		var before: Dictionary = _snapshot()
		var steps: int = controller.update(delta)
		if steps > 0:
			_prev_positions = before if steps == 1 else _snapshot()
			_spawn_hit_effects()
		_spin_gears(delta * controller.speed)
		effects.update(delta)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if input == null or paused:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			input.press(mb.position)
		else:
			input.release(mb.position)
		get_viewport().set_input_as_handled()
		return
	var mm: InputEventMouseMotion = event as InputEventMouseMotion
	if mm != null:
		input.move(mm.position)


func _draw() -> void:
	if controller == null:
		return
	var sim: BattleSim = controller.sim
	draw_rect(Rect2(Vector2.ZERO, layout.screen_size()), BattlePalette.BACKGROUND)
	_draw_field()
	_draw_wall(sim)
	_draw_monsters(sim)
	_draw_boss_bar(sim)
	_draw_grid(sim)
	_draw_stock(sim)
	_draw_effects()
	_draw_drag(sim)
	_draw_top_bar(sim)


func _draw_field() -> void:
	var rect: Rect2 = layout.field_rect()
	draw_rect(rect, BattlePalette.FIELD)
	for x: int in SimGrid.WIDTH:
		if x % 2 == 0:
			var lane: float = layout.lane_x(x * 1000)
			var stripe: Rect2 = Rect2(
				Vector2(lane - BattleLayout.CELL * 0.5, rect.position.y),
				Vector2(BattleLayout.CELL, rect.size.y)
			)
			draw_rect(stripe, BattlePalette.FIELD_STRIPE)


## Латунные ворота: брусья и заклёпки; при уроне Стена краснеет.
func _draw_wall(sim: BattleSim) -> void:
	var ratio: float = _wall_ratio(sim)
	var color: Color = BattlePalette.WALL_DAMAGED.lerp(BattlePalette.WALL, ratio)
	var rect: Rect2 = Rect2(
		Vector2(0.0, layout.wall_top),
		Vector2(BattleLayout.WIDTH, layout.wall_bottom - layout.wall_top)
	)
	draw_rect(rect, color)
	draw_rect(rect, BattlePalette.BRASS_DARK, false, 6.0)
	var x: float = 30.0
	while x < BattleLayout.WIDTH:
		var beam: Rect2 = Rect2(Vector2(x, rect.position.y), Vector2(14.0, rect.size.y))
		draw_rect(beam, BattlePalette.BRASS_DARK)
		draw_circle(Vector2(x + 7.0, rect.position.y + 14.0), 6.0, BattlePalette.BRASS)
		draw_circle(Vector2(x + 7.0, rect.end.y - 14.0), 6.0, BattlePalette.BRASS)
		x += 120.0


func _draw_monsters(sim: BattleSim) -> void:
	var field_len: int = sim.data.run_value("field_length_x1000")
	var t: float = controller.alpha()
	for m: SimMonster in sim.monsters:
		if not m.is_alive():
			continue
		var spec: SimSpecs.Monster = sim.data.monster(m.type)
		var cur: Vector2 = layout.field_pos(m.x, m.y, field_len)
		var pos: Vector2 = cur
		if _prev_positions.has(m.id):
			var prev: Vector2i = _prev_positions[m.id]
			pos = layout.field_pos(prev.x, prev.y, field_len).lerp(cur, t)
		if spec.boss:
			_draw_boss(pos)
			continue
		var fast: bool = spec.zigzag_amp_x1000 > 0
		var radius: float = MONSTER_RADIUS * (0.78 if fast else 1.0)
		draw_circle(pos, radius, BattlePalette.MONSTER_FAST if fast else BattlePalette.MONSTER)
		_draw_eyes(pos, radius)
		var hp_ratio: float = float(m.hp) / maxf(1.0, float(m.max_hp))
		if hp_ratio < 1.0:
			var bar: Rect2 = Rect2(
				pos + Vector2(-radius, -radius - 12.0), Vector2(radius * 2.0, 6.0)
			)
			draw_rect(bar, BattlePalette.HP_BACK)
			var fill: Rect2 = Rect2(bar.position, Vector2(bar.size.x * hp_ratio, bar.size.y))
			draw_rect(fill, BattlePalette.HP)


func _draw_boss(pos: Vector2) -> void:
	var spikes: PackedVector2Array = _gear_polygon(pos, BOSS_RADIUS * 1.15, BOSS_RADIUS, 9, 0.0)
	draw_colored_polygon(spikes, BattlePalette.BOSS)
	draw_circle(pos, BOSS_RADIUS * 0.85, BattlePalette.MONSTER)
	_draw_eyes(pos, BOSS_RADIUS * 0.85)


func _draw_eyes(pos: Vector2, radius: float) -> void:
	var off: Vector2 = Vector2(radius * 0.35, -radius * 0.15)
	draw_circle(pos + Vector2(-off.x, off.y), radius * 0.16, BattlePalette.MONSTER_EYES)
	draw_circle(pos + off, radius * 0.16, BattlePalette.MONSTER_EYES)


## Полоса здоровья босса над воротами — пока босс жив.
func _draw_boss_bar(sim: BattleSim) -> void:
	var boss: SimMonster = sim.current_boss()
	if boss == null:
		return
	var rect: Rect2 = layout.boss_bar_rect()
	var ratio: float = clampf(float(boss.hp) / maxf(1.0, float(boss.max_hp)), 0.0, 1.0)
	draw_rect(rect.grow(4.0), BattlePalette.BRASS_DARK)
	draw_rect(rect, BattlePalette.HP_BACK)
	var fill: Rect2 = Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y))
	draw_rect(fill, BattlePalette.BOSS_HP)
	var label: String = (
		"%s  %d" % [tr(BattleHudModel.boss_name_key(boss.type)), maxi(0, boss.hp / 1000)]
	)
	var baseline: Vector2 = rect.position + Vector2(0.0, rect.size.y - 7.0)
	draw_string(
		_font, baseline, label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 26, BattlePalette.TEXT
	)


func _draw_grid(sim: BattleSim) -> void:
	var hover: Vector2i = layout.cell_at(input.pointer)
	var dragging: bool = input.drag != BattleInput.Drag.NONE
	for y: int in SimGrid.HEIGHT:
		for x: int in SimGrid.WIDTH:
			var rect: Rect2 = layout.cell_rect(x, y).grow(-6.0)
			var cw: bool = PowerSystem.is_clockwise_cell(x, y, sim.reversed)
			var fill: Color = BattlePalette.CELL
			if dragging and hover == Vector2i(x, y):
				fill = BattlePalette.direction(cw).darkened(0.45)
			_draw_round_rect(rect, fill, 18.0)
			_draw_round_rect_outline(rect, BattlePalette.direction(cw).darkened(0.6), 18.0, 3.0)
			if sim.grid.is_free(x, y):
				_draw_plus(rect.get_center(), BattlePalette.CELL_PLUS)
	_draw_heart(sim)
	for g: SimGear in sim.grid.gears:
		var angle: float = _angles.get(g.id, 0.0)
		_draw_gear(layout.cell_center(g.x, g.y), g.type, g.level, g.connected, g.clockwise, angle)


## Сердце — большая золотая шестерня; кольцо вокруг — перезарядка Реверса.
func _draw_heart(sim: BattleSim) -> void:
	var heart: Vector2 = layout.cell_center(SimGrid.HEART_X, SimGrid.HEART_Y)
	var poly: PackedVector2Array = _gear_polygon(
		heart, GEAR_RADIUS * 1.05, GEAR_RADIUS * 0.86, HEART_TEETH, _heart_angle
	)
	draw_colored_polygon(poly, BattlePalette.HEART)
	draw_circle(heart, GEAR_RADIUS * 0.55, BattlePalette.BRASS_DARK)
	_draw_arrow(heart, not sim.reversed, BattlePalette.TEXT, 30.0)
	if sim.reverse_cooldown > 0:
		var total: float = float(sim.data.run_value("reverse_cooldown_ticks"))
		var ready: float = 1.0 - float(sim.reverse_cooldown) / total
		var end_angle: float = -PI / 2.0 + TAU * ready
		draw_arc(heart, GEAR_RADIUS + 10.0, -PI / 2.0, end_angle, 48, BattlePalette.TEXT, 6.0)


## Шестерня: зубчатый корпус цвета типа, ободок и стрелка направления, крупный номер уровня.
func _draw_gear(
	center: Vector2, type: String, level: int, powered: bool, clockwise: bool, angle: float
) -> void:
	var body: Color = BattlePalette.gear_body(type) if powered else BattlePalette.GEAR_OFF
	var poly: PackedVector2Array = _gear_polygon(
		center, GEAR_RADIUS, GEAR_RADIUS * 0.82, GEAR_TEETH, angle
	)
	draw_colored_polygon(poly, body)
	var rim: Color = BattlePalette.direction(clockwise) if powered else body.darkened(0.3)
	draw_arc(center, GEAR_RADIUS * 0.66, 0.0, TAU, 32, rim, 7.0)
	draw_circle(center, GEAR_RADIUS * 0.58, body.darkened(0.35))
	var text_pos: Vector2 = center + Vector2(-GEAR_RADIUS, LEVEL_FONT * 0.36)
	var width: float = GEAR_RADIUS * 2.0
	draw_string_outline(
		_font,
		text_pos,
		str(level),
		HORIZONTAL_ALIGNMENT_CENTER,
		width,
		LEVEL_FONT,
		10,
		BattlePalette.TEXT_DARK
	)
	draw_string(
		_font,
		text_pos,
		str(level),
		HORIZONTAL_ALIGNMENT_CENTER,
		width,
		LEVEL_FONT,
		BattlePalette.TEXT
	)
	if powered:
		var badge: Vector2 = center + Vector2(GEAR_RADIUS * 0.72, GEAR_RADIUS * 0.72)
		draw_circle(badge, 22.0, BattlePalette.TEXT_DARK)
		_draw_arrow(badge, clockwise, BattlePalette.direction(clockwise), 13.0)


## Стрелка направления вращения (для дальтоников направление видно не только цветом).
func _draw_arrow(center: Vector2, clockwise: bool, color: Color, r: float) -> void:
	var start: float = -PI * 0.75
	var end: float = PI * 0.5
	if not clockwise:
		start = PI * 0.25 + PI
		end = -PI * 0.5 + PI
	draw_arc(center, r, start, end, 16, color, maxf(3.0, r * 0.22))
	var tip: Vector2 = center + Vector2(cos(end), sin(end)) * r
	var tangent: Vector2 = Vector2(-sin(end), cos(end)) * (1.0 if clockwise else -1.0)
	var normal: Vector2 = Vector2(cos(end), sin(end))
	var head: PackedVector2Array = PackedVector2Array(
		[tip + tangent * r * 0.5, tip - normal * r * 0.38, tip + normal * r * 0.38]
	)
	draw_colored_polygon(head, color)


func _draw_stock(sim: BattleSim) -> void:
	for i: int in BattleLayout.SLOTS_SHOWN:
		var rect: Rect2 = layout.slot_rect(i)
		var enabled: bool = i < sim.data.run_value("stock_slots")
		_draw_round_rect(rect, BattlePalette.SLOT if enabled else BattlePalette.BACKGROUND, 16.0)
		if enabled:
			_draw_round_rect_outline(rect, BattlePalette.BRASS_DARK, 16.0, 3.0)
		var dragged: bool = input.drag == BattleInput.Drag.SLOT and input.drag_slot == i
		if i < sim.stock.size() and not dragged:
			var item: BattleSim.StockItem = sim.stock[i]
			_draw_gear(rect.get_center(), item.type, item.level, true, true, 0.0)


func _draw_effects() -> void:
	for e: EffectPool.Effect in effects.items:
		if e.active:
			var a: float = e.time_left / maxf(0.001, e.duration)
			draw_line(e.from, e.to, Color(BattlePalette.HIT, a), 4.0)


func _draw_drag(sim: BattleSim) -> void:
	var type: String = input.dragged_type()
	if type == "":
		return
	var cell: Vector2i = layout.cell_at(input.pointer)
	var cw: bool = true
	if cell.x >= 0:
		cw = PowerSystem.is_clockwise_cell(cell.x, cell.y, sim.reversed)
	_draw_gear(input.pointer, type, input.dragged_level(), cell.x >= 0, cw, 0.0)


## Фон верхней панели и полоса прочности Стены; тексты рисует BattleHud.
func _draw_top_bar(sim: BattleSim) -> void:
	draw_rect(layout.top_bar_rect(), BattlePalette.TOP_BAR)
	var line_y: float = BattleLayout.TOP_BAR_HEIGHT
	draw_line(
		Vector2(0.0, line_y), Vector2(BattleLayout.WIDTH, line_y), BattlePalette.BRASS_DARK, 4.0
	)
	var bar: Rect2 = layout.wall_bar_rect()
	var ratio: float = _wall_ratio(sim)
	draw_rect(bar.grow(3.0), BattlePalette.BRASS_DARK)
	draw_rect(bar, BattlePalette.HP_BACK)
	var fill: Color = BattlePalette.WALL_DAMAGED.lerp(BattlePalette.HP, ratio)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), fill)


func _wall_ratio(sim: BattleSim) -> float:
	var full: float = maxf(1.0, float(sim.data.run_value("wall_hp")))
	return clampf(float(sim.wall) / full, 0.0, 1.0)


func _draw_plus(center: Vector2, color: Color) -> void:
	draw_line(center + Vector2(-18.0, 0.0), center + Vector2(18.0, 0.0), color, 8.0)
	draw_line(center + Vector2(0.0, -18.0), center + Vector2(0.0, 18.0), color, 8.0)


func _draw_round_rect(rect: Rect2, color: Color, radius: float) -> void:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	draw_rect(Rect2(rect.position + Vector2(r, 0.0), rect.size - Vector2(r * 2.0, 0.0)), color)
	draw_rect(Rect2(rect.position + Vector2(0.0, r), rect.size - Vector2(0.0, r * 2.0)), color)
	for corner: Vector2 in _corners(rect, r):
		draw_circle(corner, r, color)


func _draw_round_rect_outline(rect: Rect2, color: Color, radius: float, width: float) -> void:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var p: Vector2 = rect.position
	var e: Vector2 = rect.end
	draw_line(Vector2(p.x + r, p.y), Vector2(e.x - r, p.y), color, width)
	draw_line(Vector2(p.x + r, e.y), Vector2(e.x - r, e.y), color, width)
	draw_line(Vector2(p.x, p.y + r), Vector2(p.x, e.y - r), color, width)
	draw_line(Vector2(e.x, p.y + r), Vector2(e.x, e.y - r), color, width)
	var c: Array[Vector2] = _corners(rect, r)
	draw_arc(c[0], r, PI, PI * 1.5, 8, color, width)
	draw_arc(c[1], r, PI * 1.5, TAU, 8, color, width)
	draw_arc(c[2], r, 0.0, PI * 0.5, 8, color, width)
	draw_arc(c[3], r, PI * 0.5, PI, 8, color, width)


static func _corners(rect: Rect2, r: float) -> Array[Vector2]:
	var p: Vector2 = rect.position
	var e: Vector2 = rect.end
	return [
		Vector2(p.x + r, p.y + r),
		Vector2(e.x - r, p.y + r),
		Vector2(e.x - r, e.y - r),
		Vector2(p.x + r, e.y - r),
	]


## Многоугольник шестерни: teeth зубьев между радиусами inner и outer, поворот angle.
static func _gear_polygon(
	center: Vector2, outer: float, inner: float, teeth: int, angle: float
) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = teeth * 4
	for i: int in steps:
		var a: float = angle + TAU * i / steps
		var r: float = outer if (i % 4 == 1 or i % 4 == 2) else inner
		points.append(center + Vector2(cos(a), sin(a)) * r)
	return points


## Поворот шестерней на экране по их настоящей скорости (только отображение).
func _spin_gears(delta: float) -> void:
	var sim: BattleSim = controller.sim
	if sim.phase != BattleSim.Phase.WAVE:
		return
	var spin: float = sim.spin_factor() / 1000.0 * VISUAL_SPIN
	var heart_dir: float = -1.0 if sim.reversed else 1.0
	var heart_rpm: float = float(sim.data.run_value("heart_rpm"))
	_heart_angle = fmod(_heart_angle + heart_dir * heart_rpm / 60.0 * TAU * delta * spin, TAU)
	for g: SimGear in sim.grid.gears:
		if not g.connected:
			continue
		var dir: float = 1.0 if g.clockwise else -1.0
		var turns: float = g.rpm_x1000 / 1000.0 / 60.0 * delta * spin
		var current: float = _angles.get(g.id, 0.0)
		_angles[g.id] = fmod(current + dir * turns * TAU, TAU)


func _snapshot() -> Dictionary:
	var out: Dictionary = {}
	for m: SimMonster in controller.sim.monsters:
		out[m.id] = Vector2i(m.x, m.y)
	return out


func _spawn_hit_effects() -> void:
	var field_len: int = controller.sim.data.run_value("field_length_x1000")
	for a: Vector4i in controller.sim.last_attacks:
		var from: Vector2 = layout.cell_center(a.x, a.y)
		var to: Vector2 = layout.field_pos(a.z, a.w, field_len)
		effects.spawn(from, to, HIT_FLASH_SECONDS)
