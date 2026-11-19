class_name BattleView
extends Node2D
## Рисует бой серыми фигурами по состоянию симуляции. Состояние только читает;
## жесты отдаёт в BattleInput. Между тиками монстры двигаются плавно (интерполяция).

const EFFECT_CAPACITY: int = 64
const HIT_FLASH_SECONDS: float = 0.12
const MONSTER_RADIUS: float = 26.0
const GEAR_RADIUS: float = 52.0

var controller: BattleController
var input: BattleInput
var effects: EffectPool = EffectPool.new(EFFECT_CAPACITY)

var _prev_positions: Dictionary = {}
var _cur_positions: Dictionary = {}
var _font: Font = ThemeDB.fallback_font


func bind(battle: BattleController) -> void:
	controller = battle
	input = BattleInput.new(battle)
	_prev_positions.clear()
	_cur_positions.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if controller == null:
		return
	var before: Dictionary = _snapshot()
	var steps: int = controller.update(delta)
	if steps > 0:
		_prev_positions = before if steps == 1 else _snapshot()
		_cur_positions = _snapshot()
		_spawn_hit_effects()
	effects.update(delta)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if input == null:
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
	draw_rect(Rect2(Vector2.ZERO, BattleLayout.SCREEN), BattlePalette.BACKGROUND)
	_draw_field(sim)
	_draw_grid(sim)
	_draw_conveyor(sim)
	_draw_effects()
	_draw_drag(sim)


func _draw_field(sim: BattleSim) -> void:
	var top: float = BattleLayout.FIELD_TOP
	var field_rect: Rect2 = Rect2(0.0, top, BattleLayout.SCREEN.x, BattleLayout.WALL_TOP - top)
	draw_rect(field_rect, BattlePalette.FIELD)
	var wall_ratio: float = float(sim.wall) / maxf(1.0, float(sim.data.run_value("wall_hp")))
	var wall_color: Color = BattlePalette.WALL_DAMAGED.lerp(BattlePalette.WALL, wall_ratio)
	var wall_h: float = BattleLayout.WALL_BOTTOM - BattleLayout.WALL_TOP
	draw_rect(Rect2(0.0, BattleLayout.WALL_TOP, BattleLayout.SCREEN.x, wall_h), wall_color)
	var field_len: int = sim.data.run_value("field_length_x1000")
	var t: float = controller.alpha()
	for m: SimMonster in sim.monsters:
		if not m.is_alive():
			continue
		var cur: Vector2 = BattleLayout.field_pos(m.x, m.y, field_len)
		var pos: Vector2 = cur
		if _prev_positions.has(m.id):
			var prev: Vector2i = _prev_positions[m.id]
			pos = BattleLayout.field_pos(prev.x, prev.y, field_len).lerp(cur, t)
		var fast: bool = sim.data.monster(m.type).zigzag_amp_x1000 > 0
		var radius: float = MONSTER_RADIUS * (0.75 if fast else 1.0)
		draw_circle(pos, radius, BattlePalette.MONSTER_FAST if fast else BattlePalette.MONSTER)
		var hp_ratio: float = float(m.hp) / maxf(1.0, float(m.max_hp))
		var bar: Rect2 = Rect2(pos + Vector2(-radius, -radius - 12.0), Vector2(radius * 2.0, 6.0))
		draw_rect(bar, BattlePalette.HP_BACK)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * hp_ratio, bar.size.y)), BattlePalette.HP)


func _draw_grid(sim: BattleSim) -> void:
	var hover: Vector2i = BattleLayout.cell_at(input.pointer)
	var dragging: bool = input.drag != BattleInput.Drag.NONE
	for y: int in SimGrid.HEIGHT:
		for x: int in SimGrid.WIDTH:
			var rect: Rect2 = BattleLayout.cell_rect(x, y).grow(-4.0)
			var cw: bool = PowerSystem.is_clockwise_cell(x, y, sim.reversed)
			var fill: Color = BattlePalette.CELL
			if dragging and hover == Vector2i(x, y):
				fill = BattlePalette.direction(cw).darkened(0.35)
			draw_rect(rect, fill)
			draw_rect(rect, BattlePalette.direction(cw).darkened(0.55), false, 2.0)
	var heart: Vector2 = BattleLayout.cell_center(SimGrid.HEART_X, SimGrid.HEART_Y)
	draw_circle(heart, GEAR_RADIUS, BattlePalette.HEART)
	_draw_arrow(heart, not sim.reversed, BattlePalette.TEXT)
	if sim.reverse_cooldown > 0:
		var ready: float = (
			1.0 - float(sim.reverse_cooldown) / float(sim.data.run_value("reverse_cooldown_ticks"))
		)
		draw_arc(
			heart,
			GEAR_RADIUS + 8.0,
			-PI / 2.0,
			-PI / 2.0 + TAU * ready,
			32,
			BattlePalette.TEXT,
			4.0
		)
	for g: SimGear in sim.grid.gears:
		_draw_gear(BattleLayout.cell_center(g.x, g.y), g.type, g.level, g.connected, g.clockwise)


func _draw_gear(center: Vector2, type: String, level: int, powered: bool, clockwise: bool) -> void:
	var body: Color = BattlePalette.GEAR if powered else BattlePalette.GEAR_OFF
	var radius: float = GEAR_RADIUS * (0.8 + 0.05 * level)
	draw_circle(center, radius, body)
	draw_arc(
		center, radius, 0.0, TAU, 24, BattlePalette.direction(clockwise) if powered else body, 5.0
	)
	if powered:
		_draw_arrow(center, clockwise, BattlePalette.direction(clockwise))
	var label: String = "%s%d" % [type.substr(0, 2).to_upper(), level]
	draw_string(
		_font,
		center + Vector2(-radius, radius * 0.9),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		radius * 2.0,
		26,
		BattlePalette.HP_BACK
	)


## Стрелка направления вращения (для дальтоников направление видно не только цветом).
func _draw_arrow(center: Vector2, clockwise: bool, color: Color) -> void:
	var r: float = 24.0
	var start: float = -PI * 0.75
	var end: float = PI * 0.5
	if not clockwise:
		start = PI * 0.25 + PI
		end = -PI * 0.5 + PI
	draw_arc(center, r, start, end, 16, color, 5.0)
	var tip: Vector2 = center + Vector2(cos(end), sin(end)) * r
	var tangent: Vector2 = Vector2(-sin(end), cos(end)) * (1.0 if clockwise else -1.0)
	var normal: Vector2 = Vector2(cos(end), sin(end))
	var head: PackedVector2Array = PackedVector2Array(
		[tip + tangent * 12.0, tip - normal * 9.0, tip + normal * 9.0]
	)
	draw_colored_polygon(head, color)


func _draw_conveyor(sim: BattleSim) -> void:
	for i: int in BattleLayout.SLOTS_SHOWN:
		var rect: Rect2 = BattleLayout.slot_rect(i)
		var enabled: bool = i < sim.data.run_value("conveyor_slots")
		draw_rect(rect, BattlePalette.SLOT if enabled else BattlePalette.BACKGROUND)
		if (
			i < sim.conveyor.size()
			and not (input.drag == BattleInput.Drag.SLOT and input.drag_slot == i)
		):
			var item: BattleSim.ConveyorItem = sim.conveyor[i]
			_draw_gear(rect.get_center(), item.type, item.level, true, true)


func _draw_effects() -> void:
	for e: EffectPool.Effect in effects.items:
		if e.active:
			var a: float = e.time_left / maxf(0.001, e.duration)
			draw_line(e.from, e.to, Color(BattlePalette.HIT, a), 4.0)


func _draw_drag(sim: BattleSim) -> void:
	var type: String = input.dragged_type()
	if type == "":
		return
	var cell: Vector2i = BattleLayout.cell_at(input.pointer)
	var cw: bool = true
	if cell.x >= 0:
		cw = PowerSystem.is_clockwise_cell(cell.x, cell.y, sim.reversed)
	_draw_gear(input.pointer, type, input.dragged_level(), cell.x >= 0, cw)


func _snapshot() -> Dictionary:
	var out: Dictionary = {}
	for m: SimMonster in controller.sim.monsters:
		out[m.id] = Vector2i(m.x, m.y)
	return out


func _spawn_hit_effects() -> void:
	var field_len: int = controller.sim.data.run_value("field_length_x1000")
	for a: Vector4i in controller.sim.last_attacks:
		var from: Vector2 = BattleLayout.cell_center(a.x, a.y)
		var to: Vector2 = BattleLayout.field_pos(a.z, a.w, field_len)
		effects.spawn(from, to, HIT_FLASH_SECONDS)
