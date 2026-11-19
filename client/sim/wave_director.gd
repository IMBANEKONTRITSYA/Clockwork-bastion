class_name WaveDirector
extends RefCounted
## Состав волны по бюджету (core-rules §6): бюджет 10 + 4w, монстры выбираются
## через SimRng среди доступных на этой волне и по карману. Один вызов RNG на монстра.


## Список id монстров волны в порядке выхода.
static func compose(data: SimData, rng: SimRng, wave: int) -> Array[String]:
	var budget: int = (
		data.run_value("wave_budget_base") + data.run_value("wave_budget_per_wave") * wave
	)
	var result: Array[String] = []
	while budget > 0:
		var options: Array[SimSpecs.Monster] = []
		for m: SimSpecs.Monster in data.monsters:
			if m.first_wave <= wave and m.cost <= budget and m.cost > 0:
				options.append(m)
		if options.is_empty():
			break
		var pick: SimSpecs.Monster = options[rng.next_range(0, options.size())]
		result.append(pick.id)
		budget -= pick.cost
	return result


## Здоровье монстра на волне, ×1000.
static func monster_hp(data: SimData, spec: SimSpecs.Monster, wave: int) -> int:
	return spec.hp * data.wave_hp_mul(wave)
