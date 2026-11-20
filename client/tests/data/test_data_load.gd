extends GutTest
## Ресурсы из make data загружаются и содержат целые числа из CSV.

const GEARS_PATH: String = "res://data/gears.tres"


func test_gears_table_loads_saw_row() -> void:
	var table: BalanceTable = load(GEARS_PATH) as BalanceTable
	assert_not_null(table, "client/data/gears.tres не найден — запусти make data")
	assert_eq(table.table_name, "gears")
	assert_true(table.has_row("saw"))
	assert_eq(table.get_int("saw", "base_damage"), 10)
	assert_eq(table.get_int("saw", "hits_per_rev_x1000"), 1000)


func test_unknown_id_is_absent() -> void:
	var table: BalanceTable = load(GEARS_PATH) as BalanceTable
	assert_false(table.has_row("no_such_gear"))
