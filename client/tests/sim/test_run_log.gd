extends GutTest
## Журнал забега: формат (core-rules §8), повтор, детерминизм через JSON и бот.


func test_bot_run_finishes_and_replay_matches_client_result() -> void:
	var data: SimData = SimData.load_default()
	var run_log: RunLog = SimBot.new().play(data, 2024)
	assert_ne(run_log.client_result.get("outcome"), "running", "забег должен закончиться")
	var sim: BattleSim = RunLog.replay(run_log, data)
	assert_eq(sim.result(), run_log.client_result)


func test_replay_through_json_gives_same_hash() -> void:
	var data: SimData = SimData.load_default()
	var run_log: RunLog = SimBot.new().play(data, 77)
	var text: String = JSON.stringify(run_log.to_dict())
	var parsed: Dictionary = JSON.parse_string(text)
	var restored: RunLog = RunLog.from_dict(parsed)
	assert_not_null(restored)
	var a: BattleSim = RunLog.replay(run_log, data)
	var b: BattleSim = RunLog.replay(restored, data)
	assert_eq(b.state_hash(), a.state_hash())
	assert_eq(b.result(), a.result())


func test_different_seeds_give_different_runs() -> void:
	var data: SimData = SimData.load_default()
	var a: BattleSim = RunLog.replay(SimBot.new().play(data, 1), data)
	var b: BattleSim = RunLog.replay(SimBot.new().play(data, 2), data)
	assert_ne(a.state_hash(), b.state_hash())


func test_inputs_apply_before_tick_advance() -> void:
	var run_log: RunLog = RunLog.new()
	run_log.seed_value = 5
	run_log.record(0, "next_wave", {})
	run_log.record(0, "reverse", {})
	var data: SimData = SimData.load_default()
	var probe: BattleSim = BattleSim.new(data, 5)
	probe.apply_input("next_wave", {})
	probe.apply_input("reverse", {})
	probe.advance()
	var replayed: BattleSim = RunLog.replay(run_log, data)
	assert_eq(replayed.wave >= 1, true)
	assert_true(replayed.reversed)
	assert_eq(probe.wave, 1)


func test_malformed_log_is_rejected() -> void:
	assert_null(RunLog.from_dict({"inputs": []}), "нет зерна")
	assert_null(RunLog.from_dict({"seed": 1, "inputs": [[1, "place"]]}), "неполный вход")
	assert_null(RunLog.from_dict({"seed": 1, "inputs": "x"}))


func test_out_of_order_inputs_are_skipped() -> void:
	var data: SimData = SimData.load_default()
	var run_log: RunLog = RunLog.new()
	run_log.seed_value = 9
	run_log.record(10, "next_wave", {})
	run_log.record(5, "reverse", {})
	var sim: BattleSim = RunLog.replay(run_log, data)
	assert_false(sim.reversed, "вход с прошедшим тиком отброшен")
