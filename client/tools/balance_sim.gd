extends SceneTree
## Симулятор баланса (make sim RUNS=N): бот играет N забегов на зернах 1..N,
## отчёт JSON: на какой волне заканчиваются забеги, доля побед, средняя длина.


func _init() -> void:
	var runs: int = int(_arg_value("--runs", "100"))
	var out_path: String = _arg_value("--out", "../tools/out/sim.json")
	var data: SimData = SimData.load_default()
	var waves_hist: Dictionary = {}
	var wins: int = 0
	var total_ticks: int = 0
	var total_kills: int = 0
	for seed_value: int in range(1, runs + 1):
		var run_log: RunLog = SimBot.new().play(data, seed_value)
		var sim: BattleSim = RunLog.replay(run_log, data)
		var waves: int = sim.waves_cleared
		waves_hist[waves] = int(waves_hist.get(waves, 0)) + 1
		if sim.outcome() == "won":
			wins += 1
		total_ticks += sim.tick
		total_kills += sim.kills
	var hist_keys: Array = waves_hist.keys()
	hist_keys.sort()
	var hist: Dictionary = {}
	for k: Variant in hist_keys:
		hist[str(k)] = waves_hist[k]
	var report: Dictionary = {
		"runs": runs,
		"sim_version": SimVersion.SIM_VERSION,
		"wins": wins,
		"win_rate_permille": wins * 1000 / maxi(1, runs),
		"avg_ticks": total_ticks / maxi(1, runs),
		"avg_kills": total_kills / maxi(1, runs),
		"waves_cleared_histogram": hist,
	}
	var text: String = JSON.stringify(report, "  ")
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


func _arg_value(name: String, fallback: String) -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var i: int = args.find(name)
	if i >= 0 and i + 1 < args.size():
		return args[i + 1]
	return fallback
