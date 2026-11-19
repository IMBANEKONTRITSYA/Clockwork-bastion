class_name BattleInput
extends RefCounted
## Жесты игрока → входы журнала: перетащить с конвейера на сетку (поставить или слить),
## перетащить шестерню по сетке (переставить или слить), тап по Сердцу (Реверс).

enum Drag { NONE, SLOT, GEAR }

var controller: BattleController
var drag: Drag = Drag.NONE
var drag_slot: int = -1
var drag_cell: Vector2i = Vector2i(-1, -1)
var pointer: Vector2 = Vector2.ZERO


func _init(battle: BattleController) -> void:
	controller = battle


func press(pos: Vector2) -> void:
	pointer = pos
	var slot: int = BattleLayout.slot_at(pos)
	if slot >= 0 and slot < controller.sim.conveyor.size():
		drag = Drag.SLOT
		drag_slot = slot
		return
	var cell: Vector2i = BattleLayout.cell_at(pos)
	if cell.x < 0:
		return
	if SimGrid.is_heart(cell.x, cell.y):
		controller.submit("reverse")
		return
	if controller.sim.grid.gear_at(cell.x, cell.y) != null:
		drag = Drag.GEAR
		drag_cell = cell


func move(pos: Vector2) -> void:
	pointer = pos


## Отпускание: возвращает true, если действие принято симуляцией.
func release(pos: Vector2) -> bool:
	pointer = pos
	var cell: Vector2i = BattleLayout.cell_at(pos)
	var accepted: bool = false
	if cell.x >= 0:
		match drag:
			Drag.SLOT:
				accepted = controller.submit("place", {"slot": drag_slot, "x": cell.x, "y": cell.y})
			Drag.GEAR:
				if cell != drag_cell:
					accepted = controller.submit(
						"move",
						{"from_x": drag_cell.x, "from_y": drag_cell.y, "x": cell.x, "y": cell.y}
					)
	cancel()
	return accepted


func cancel() -> void:
	drag = Drag.NONE
	drag_slot = -1
	drag_cell = Vector2i(-1, -1)


## Тип и уровень перетаскиваемой шестерни (для «призрака» под пальцем); тип "" — ничего.
func dragged_type() -> String:
	match drag:
		Drag.SLOT:
			if drag_slot < controller.sim.conveyor.size():
				return controller.sim.conveyor[drag_slot].type
		Drag.GEAR:
			var g: SimGear = controller.sim.grid.gear_at(drag_cell.x, drag_cell.y)
			if g != null:
				return g.type
	return ""


func dragged_level() -> int:
	match drag:
		Drag.SLOT:
			if drag_slot < controller.sim.conveyor.size():
				return controller.sim.conveyor[drag_slot].level
		Drag.GEAR:
			var g: SimGear = controller.sim.grid.gear_at(drag_cell.x, drag_cell.y)
			if g != null:
				return g.level
	return 0
