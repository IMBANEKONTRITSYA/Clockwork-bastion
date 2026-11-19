class_name SimMonster
extends RefCounted
## Монстр на поле. Координаты ×1000: x — по горизонтали (0..6000, колонки сетки),
## y — расстояние до Стены (0 = у Стены). HP тоже ×1000.

var id: int = 0
var type: String = ""
var hp: int = 0
var max_hp: int = 0
var x: int = 0
var y: int = 0
var base_x: int = 0
var age: int = 0
var slow_pct: int = 0
var slow_ticks: int = 0
var at_wall: bool = false
var attack_timer: int = 0


func is_alive() -> bool:
	return hp > 0


## Сдвиг зигзага по треугольной волне: от -amp до +amp за период.
static func zigzag_offset(amp: int, period: int, age_ticks: int) -> int:
	if amp == 0 or period <= 1:
		return 0
	var half: int = period / 2
	var p: int = age_ticks % period
	var tri: int = 0
	if p < half:
		tri = -Fixed.ONE + 2 * Fixed.ONE * p / half
	else:
		tri = Fixed.ONE - 2 * Fixed.ONE * (p - half) / (period - half)
	return amp * tri / Fixed.ONE
