extends GutTest
## Тесты SimRng: эталонные значения посчитаны независимой моделью xorshift32 на Python.

const SEED: int = 123456789
const EXPECTED_FIRST_10: Array[int] = [
	2714967881,
	2238813396,
	1250077441,
	3820100336,
	3177519686,
	3684138832,
	3151087790,
	3662508108,
	4242376622,
	3374601978,
]


func test_seed_123456789_gives_reference_sequence() -> void:
	var rng: SimRng = SimRng.new(SEED)
	for i: int in EXPECTED_FIRST_10.size():
		assert_eq(rng.next_int(), EXPECTED_FIRST_10[i], "число №%d" % i)


func test_same_seed_gives_same_1000_numbers() -> void:
	var a: SimRng = SimRng.new(42)
	var b: SimRng = SimRng.new(42)
	for i: int in 1000:
		assert_eq(a.next_int(), b.next_int())


func test_zero_seed_is_replaced_and_not_stuck_at_zero() -> void:
	var rng: SimRng = SimRng.new(0)
	assert_eq(rng.next_int(), 1359758873)
	assert_eq(rng.next_int(), 3761132862)


func test_seed_uses_only_low_32_bits() -> void:
	var rng: SimRng = SimRng.new(SEED + (1 << 32))
	assert_eq(rng.next_int(), EXPECTED_FIRST_10[0])


func test_numbers_stay_in_32_bit_range() -> void:
	var rng: SimRng = SimRng.new(7)
	for i: int in 10000:
		var x: int = rng.next_int()
		assert_true(x > 0 and x <= SimRng.MASK, "вне диапазона: %d" % x)


func test_next_range_stays_in_bounds() -> void:
	var rng: SimRng = SimRng.new(99)
	for i: int in 1000:
		var x: int = rng.next_range(-3, 4)
		assert_true(x >= -3 and x < 4, "вне диапазона: %d" % x)


func test_next_range_matches_reference_formula() -> void:
	var rng: SimRng = SimRng.new(SEED)
	assert_eq(rng.next_range(0, 100), EXPECTED_FIRST_10[0] % 100)


func test_chance_permille_bounds() -> void:
	var rng: SimRng = SimRng.new(5)
	for i: int in 200:
		assert_false(rng.chance_permille(0))
		assert_true(rng.chance_permille(1000))


func test_state_restores_sequence() -> void:
	var rng: SimRng = SimRng.new(SEED)
	rng.next_int()
	var copy: SimRng = SimRng.new(rng.get_state())
	assert_eq(copy.next_int(), EXPECTED_FIRST_10[1])
