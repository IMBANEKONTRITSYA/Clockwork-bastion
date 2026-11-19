extends GutTest
## Фиксированная точка и таблицы степеней (значения посчитаны Decimal-моделью на Python).

const SIZE: Array[int] = [1000, 800, 640, 512, 410]
const DMG_MUL: Array[int] = [1000, 2400, 5760, 13824, 33178]


func test_mul_and_div_are_inverse_on_round_numbers() -> void:
	assert_eq(Fixed.mul(1500, 2000), 3000)
	assert_eq(Fixed.div(3000, 2000), 1500)


func test_mul_truncates_toward_zero() -> void:
	assert_eq(Fixed.mul(999, 999), 998)
	assert_eq(Fixed.mul(-999, 999), -998)


func test_pct_takes_permille() -> void:
	assert_eq(Fixed.pct(200, 350), 70)


func test_level_tables_match_powers_of_08_and_24() -> void:
	var data: SimData = SimData.load_default()
	for level: int in range(1, 6):
		assert_eq(data.level_size(level), SIZE[level - 1], "size L%d" % level)
		assert_eq(data.level_dmg_mul(level), DMG_MUL[level - 1], "dmg L%d" % level)


func test_wave_hp_table_matches_powers_of_113() -> void:
	var data: SimData = SimData.load_default()
	assert_eq(data.wave_hp_mul(1), 1000)
	assert_eq(data.wave_hp_mul(2), 1130)
	assert_eq(data.wave_hp_mul(10), 3004)
	assert_eq(data.wave_hp_mul(20), 10197)
	assert_eq(data.wave_hp_mul(40), 117506)


func test_wave_hp_table_clamps_after_last_wave() -> void:
	var data: SimData = SimData.load_default()
	assert_eq(data.wave_hp_mul(41), 117506)
	assert_eq(data.wave_hp_mul(0), 1000)
