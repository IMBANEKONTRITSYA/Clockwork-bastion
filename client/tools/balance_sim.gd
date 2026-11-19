extends SceneTree
## Симулятор баланса (make sim RUNS=N): бот играет N забегов на зернах 1..N,
## отчёт JSON: на какой волне заканчиваются забеги, доля побед, сколько Стены осталось.
## --variants "k=v,k=v|k=v" — перебрать несколько наборов параметров run.csv за один запуск.


func _init() -> void:
	var runs: int = int(_arg_value("--runs", "100"))
	var out_path: String = _arg_value("--out", "../tools/out/sim.json")
	var base: SimData = SimData.load_default()
	var variants: Array[Dictionary] = _parse_variants(_arg_value("--variants", ""))
	var reports: Array = []
	for overrides: Dictionary in variants:
		var data: SimData = base
		if not overrides.is_empty():
			data = base.with_run_overrides(overrides)
		var report: Dictionary = _run_batch(data, runs)
		report["overrides"] = overrides
		reports.append(report)
	var text: String = JSON.stringify(reports[0] if reports.size() == 1 else reports, "  ")
	print(text)
	var path: String = out_path
	if not path.is_absolute_path():
		path = ProjectSettings.globalize_path("res://").path_join(out_path).simplify_path()
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		printerr("balance_sim: не удалось записать %s" % path)
		quit(1)
		return
	f.store_string(text + "\n")
	print("balance_sim: отчёт %s" % path)
	quit(0)


func _run_batch(data: SimData, runs: int) -> Dictionary:
	var waves_hist: Dictionary = {}
	var wins: int = 0
	var total_ticks: int = 0
	var total_kills: int = 0
	var total_wall: int = 0
	var min_wall: int = 1 << 30
	var total_buys: int = 0
	for seed_value: int in range(1, runs + 1):
		var run_log: RunLog = SimBot.new().play(data, seed_value)
		var sim: BattleSim = RunLog.replay(run_log, data)
		var waves: int = sim.waves_cleared
		waves_hist[waves] = Fixed.int_of(waves_hist.get(waves, 0), 0) + 1
		if sim.outcome() == "won":
			wins += 1
		total_ticks += sim.tick
		total_kills += sim.kills
		total_wall += sim.wall
		min_wall = mini(min_wall, sim.wall)
		for entry: Array in run_log.inputs:
			var action: String = entry[1]
			if action == "buy":
				total_buys += 1
	var hist_keys: Array = waves_hist.keys()
	hist_keys.sort()
	var hist: Dictionary = {}
	for k: Variant in hist_keys:
		hist[str(k)] = waves_hist[k]
	var n: int = maxi(1, runs)
	return {
		"runs": runs,
		"sim_version": SimVersion.SIM_VERSION,
		"wins": wins,
		"win_rate_permille": wins * 1000 / n,
		"avg_wall_left": total_wall / n,
		"min_wall_left": min_wall,
		"avg_buys": total_buys / n,
		"avg_ticks": total_ticks / n,
		"avg_kills": total_kills / n,
		"waves_cleared_histogram": hist,
	}


## "a=1,b=2|c=3" → [{a:1,b:2},{c:3}]; пустая строка → один вариант без подмен.
func _parse_variants(arg: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if arg.strip_edges() == "":
		out.append({})
		return out
	for chunk: String in arg.split("|"):
		var overrides: Dictionary = {}
		for pair: String in chunk.split(",", false):
			var kv: PackedStringArray = pair.split("=")
			if kv.size() == 2:
				overrides[kv[0].strip_edges()] = int(kv[1])
		out.append(overrides)
	return out


func _arg_value(name: String, fallback: String) -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var i: int = args.find(name)
	if i >= 0 and i + 1 < args.size():
		return args[i + 1]
	return fallback
