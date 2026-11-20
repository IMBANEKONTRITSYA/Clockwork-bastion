class_name WaveDirector
extends RefCounted
## Состав волны по таблице waves.csv (core-rules §6): count монстров вместе с боссом
## (не больше 15). Обычные монстры выбираются через SimRng среди доступных на этой волне,
## один вызов RNG на монстра; босс волны выходит последним и RNG не тратит.

const MAX_MONSTERS_PER_WAVE: int = 15


## Список id монстров волны в порядке выхода.
static func compose(data: SimData, rng: SimRng, wave: int) -> Array[String]:
	var boss: String = data.wave_boss(wave)
	var total: int = mini(data.wave_count(wave), MAX_MONSTERS_PER_WAVE)
	var regulars: int = total - (1 if boss != "" else 0)
	var options: Array[SimSpecs.Monster] = []
	for m: SimSpecs.Monster in data.monsters:
		if not m.boss and m.first_wave <= wave:
			options.append(m)
	var result: Array[String] = []
	if not options.is_empty():
		for i: int in regulars:
			result.append(options[rng.next_range(0, options.size())].id)
	if boss != "":
		result.append(boss)
	return result


## Здоровье монстра на волне, ×1000: hp · множитель волны · общий множитель сложности.
static func monster_hp(data: SimData, spec: SimSpecs.Monster, wave: int) -> int:
	return spec.hp * data.wave_hp_mul(wave) * data.run_value("monster_hp_scale") / Fixed.ONE
