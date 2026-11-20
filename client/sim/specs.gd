class_name SimSpecs
extends RefCounted
## Типизированные описания шестерней и монстров, собранные из таблиц баланса.


class GearMode:
	extends RefCounted
	var range_x1000: int = 0
	var reach_x1000: int = 0
	var targets: int = 0
	var dmg_pct: int = 0
	var knockback_x1000: int = 0
	var slow_pct: int = 0
	var slow_ticks: int = 0


class Gear:
	extends RefCounted
	var id: String = ""
	var element: String = ""
	var base_damage: int = 0
	var hits_per_rev_x1000: int = 0
	var shop_weight: int = 0
	var cw: GearMode = GearMode.new()
	var ccw: GearMode = GearMode.new()

	func mode(clockwise: bool) -> GearMode:
		return cw if clockwise else ccw


class Monster:
	extends RefCounted
	var id: String = ""
	var hp: int = 0
	var speed_x1000: int = 0
	var wall_damage: int = 0
	var nuts: int = 0
	var first_wave: int = 0
	var zigzag_amp_x1000: int = 0
	var zigzag_period_ticks: int = 0
	var boss: bool = false
