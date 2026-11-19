extends GutTest
## SimData собирает типизированные описания из таблиц баланса.


func test_gears_and_monsters_keep_csv_order() -> void:
	var data: SimData = SimData.load_default()
	assert_eq(data.gears[0].id, "saw")
	assert_eq(data.gears[1].id, "steam")
	assert_eq(data.monsters[0].id, "rustling")
	assert_eq(data.monsters[1].id, "squeaker")


func test_gear_modes_are_read_from_prefixed_columns() -> void:
	var steam: SimSpecs.Gear = SimData.load_default().gear("steam")
	assert_eq(steam.hits_per_rev_x1000, 4000)
	assert_eq(steam.mode(true).knockback_x1000, 300)
	assert_eq(steam.mode(false).slow_pct, 350)
	assert_eq(steam.mode(false).slow_ticks, 60)


func test_run_values() -> void:
	var data: SimData = SimData.load_default()
	assert_eq(data.run_value("heart_power"), 8)
	assert_eq(data.run_value("wall_hp"), 100)
	assert_eq(data.max_level(), 5)
