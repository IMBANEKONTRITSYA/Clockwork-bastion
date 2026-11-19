class_name EffectPool
extends RefCounted
## Пул коротких эффектов (вспышки ударов): объекты создаются один раз,
## во время боя память не выделяется. При переполнении новый эффект пропускается.


class Effect:
	extends RefCounted
	var active: bool = false
	var from: Vector2 = Vector2.ZERO
	var to: Vector2 = Vector2.ZERO
	var time_left: float = 0.0
	var duration: float = 0.0


var items: Array[Effect] = []


func _init(capacity: int) -> void:
	for i: int in capacity:
		items.append(Effect.new())


## Свободный эффект или null, если все заняты.
func spawn(from: Vector2, to: Vector2, duration: float) -> Effect:
	for e: Effect in items:
		if not e.active:
			e.active = true
			e.from = from
			e.to = to
			e.duration = duration
			e.time_left = duration
			return e
	return null


func update(delta: float) -> void:
	for e: Effect in items:
		if e.active:
			e.time_left -= delta
			if e.time_left <= 0.0:
				e.active = false


func active_count() -> int:
	var n: int = 0
	for e: Effect in items:
		if e.active:
			n += 1
	return n
