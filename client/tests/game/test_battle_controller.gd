extends GutTest
## Контроллер боя: 30 тиков в секунду, ×2, запись входов в журнал на нужный тик.


func _controller() -> BattleController:
	return BattleController.new(SimData.load_default(), 123)


func test_one_second_is_30_ticks() -> void:
	var c: BattleController = _controller()
	var steps: int = 0
	for i: int in 4:
		steps += c.update(0.25)
	assert_eq(steps, 30)
	assert_eq(c.sim.tick, 30)


func test_speed_x2_doubles_ticks() -> void:
	var c: BattleController = _controller()
	c.toggle_speed()
	for i: int in 4:
		c.update(0.25)
	assert_eq(c.sim.tick, 60)
	c.toggle_speed()
	assert_eq(c.speed, 1)


func test_long_frame_is_capped_and_backlog_dropped() -> void:
	var c: BattleController = _controller()
	assert_eq(c.update(10.0), BattleController.MAX_STEPS_PER_FRAME)
	assert_lte(c.alpha(), 1.0)


func test_submit_records_input_at_current_tick() -> void:
	var c: BattleController = _controller()
	c.update(0.25)
	assert_true(c.submit("place", {"slot": 0, "x": 2, "y": 2}))
	assert_eq(c.run_log.inputs.size(), 1)
	var entry: Array = c.run_log.inputs[0]
	var at: int = entry[0]
	var action: String = entry[1]
	assert_eq(at, 7)
	assert_eq(action, "place")


func test_rejected_input_is_not_recorded() -> void:
	var c: BattleController = _controller()
	assert_false(c.submit("place", {"slot": 0, "x": 2, "y": 3}))
	assert_eq(c.run_log.inputs.size(), 0)


func test_recorded_log_replays_to_same_state() -> void:
	var data: SimData = SimData.load_default()
	var c: BattleController = BattleController.new(data, 55)
	c.submit("place", {"slot": 0, "x": 2, "y": 2})
	c.update(0.25)
	c.submit("next_wave")
	for i: int in 40:
		c.update(0.25)
	var replay: BattleSim = BattleSim.new(data, 55)
	var i_input: int = 0
	while replay.tick < c.sim.tick:
		while i_input < c.run_log.inputs.size():
			var e: Array = c.run_log.inputs[i_input]
			var at: int = e[0]
			if at != replay.tick:
				break
			var action: String = e[1]
			var args: Dictionary = e[2]
			replay.apply_input(action, args)
			i_input += 1
		replay.advance()
	assert_eq(replay.state_hash(), c.sim.state_hash())


func test_finished_signal_carries_result() -> void:
	var c: BattleController = _controller()
	watch_signals(c)
	c.sim.wall = 1
	c.submit("next_wave")
	for i: int in 400:
		c.update(0.25)
		if c.sim.is_over():
			break
	assert_signal_emitted(c, "finished")
	var outcome: String = c.run_log.client_result.get("outcome", "")
	assert_eq(outcome, "lost")
