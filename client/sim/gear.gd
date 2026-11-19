class_name SimGear
extends RefCounted
## Шестерня на сетке. Поля привода (connected, clockwise, rpm_x1000) заполняет PowerSystem.

var id: int = 0
var type: String = ""
var level: int = 1
var x: int = 0
var y: int = 0
## Накопленная фаза вращения; один оборот = PowerSystem.REV_UNITS.
var phase: int = 0
var connected: bool = false
var clockwise: bool = true
var rpm_x1000: int = 0


static func create(gear_id: int, gear_type: String, gear_level: int, gx: int, gy: int) -> SimGear:
	var g: SimGear = SimGear.new()
	g.id = gear_id
	g.type = gear_type
	g.level = gear_level
	g.x = gx
	g.y = gy
	return g
