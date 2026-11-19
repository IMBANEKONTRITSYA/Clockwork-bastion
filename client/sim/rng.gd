class_name SimRng
extends RefCounted
## Детерминированный генератор случайных чисел симуляции боя.
##
## Алгоритм — xorshift32 (сдвиги 13, 17, 5), посчитанный на 64-битных int
## с маской 0xFFFFFFFF: так нет переполнения и одинаковый результат
## на любом устройстве и на сервере. Порядок вызовов — часть протокола
## забега (см. docs/design/core-rules.md, раздел 1).

const MASK: int = 0xFFFFFFFF
## Замена нулевого зерна: xorshift из нуля всегда даёт ноль.
const ZERO_SEED_REPLACEMENT: int = 0x9E3779B9
const PERMILLE: int = 1000

var _state: int = ZERO_SEED_REPLACEMENT


func _init(seed_value: int = 0) -> void:
	set_seed(seed_value)


## Задаёт зерно. Берутся младшие 32 бита; ноль заменяется константой.
func set_seed(seed_value: int) -> void:
	_state = seed_value & MASK
	if _state == 0:
		_state = ZERO_SEED_REPLACEMENT


## Текущее состояние — для сохранения и хэша забега.
func get_state() -> int:
	return _state


## Следующее число в диапазоне [1, 2^32 - 1].
func next_int() -> int:
	var x: int = _state
	x ^= (x << 13) & MASK
	x ^= x >> 17
	x ^= (x << 5) & MASK
	_state = x
	return x


## Целое число в полуинтервале [lo, hi_exclusive). Всегда ровно один вызов next_int().
func next_range(lo: int, hi_exclusive: int) -> int:
	assert(hi_exclusive > lo, "SimRng.next_range: пустой диапазон")
	return lo + next_int() % (hi_exclusive - lo)


## true с вероятностью p/1000. Всегда ровно один вызов next_int().
func chance_permille(p: int) -> bool:
	return next_int() % PERMILLE < p
