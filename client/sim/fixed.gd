class_name Fixed
extends RefCounted
## Арифметика фиксированной точки ×1000 (core-rules §1).
## Целочисленное деление GDScript отбрасывает дробную часть к нулю — как в C.

const ONE: int = 1000


## a * b в ×1000: mul(1500, 2000) == 3000.
static func mul(a: int, b: int) -> int:
	return a * b / ONE


## a / b в ×1000: div(3000, 2000) == 1500. Деление на ноль — ошибка вызывающего.
static func div(a: int, b: int) -> int:
	assert(b != 0, "Fixed.div: деление на ноль")
	return a * ONE / b


## Процент в промилле от значения: pct(200, 350) == 70.
static func pct(value: int, permille: int) -> int:
	return value * permille / ONE


static func clamp_int(value: int, lo: int, hi: int) -> int:
	if value < lo:
		return lo
	if value > hi:
		return hi
	return value
