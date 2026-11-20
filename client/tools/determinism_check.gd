extends SceneTree
## Проверка детерминизма (make determinism):
## 1) каждый эталонный журнал из --fixtures пересчитывается, хэш и итог сравниваются с expected;
## 2) самопроверка: журналы бота для нескольких зерен дают одинаковый хэш при повторе и через JSON.
## С флагом --print-fixtures <seed,seed,...> печатает новые эталонные журналы бота
## (для обновления фикстур).

const FIXTURE_SUFFIX: String = ".json"
const SELF_CHECK_SEEDS: Array[int] = [11, 22, 33]


func _init() -> void:
	var data: SimData = SimData.load_default()
	var to_print: String = _arg_value("--print-fixtures", "")
	if to_print != "":
		_print_fixtures(data, to_print)
		quit(0)
		return
	var failed: int = 0
	failed += _check_fixtures(data, _arg_value("--fixtures", "res://tests/fixtures/runs"))
	failed += _self_check(data)
	if failed > 0:
		printerr("determinism: ПРОВАЛ, ошибок: %d" % failed)
	else:
		print("determinism: ок")
	quit(1 if failed > 0 else 0)


func _check_fixtures(data: SimData, dir_path: String) -> int:
	var failed: int = 0
	var files: PackedStringArray = _fixture_files(dir_path)
	if files.is_empty():
		print("determinism: эталонных журналов в %s нет" % dir_path)
	for file_name: String in files:
		var path: String = dir_path.path_join(file_name)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary:
			printerr("determinism: %s — не JSON-объект" % path)
			failed += 1
			continue
		var fixture: Dictionary = parsed
		var run_log: RunLog = RunLog.from_dict(fixture)
		var expected: Dictionary = fixture.get("expected", {})
		if run_log == null or expected.is_empty():
			printerr("determinism: %s — нет журнала или expected" % path)
			failed += 1
			continue
		var sim: BattleSim = RunLog.replay(run_log, data)
		var got_hash: String = sim.state_hash()
		var exp_hash: String = str(expected.get("hash", ""))
		var exp_result: Dictionary = expected.get("result", {})
		if got_hash != exp_hash or not _same_result(sim.result(), exp_result):
			printerr(
				(
					"determinism: %s — хэш %s (ждали %s), итог %s (ждали %s)"
					% [path, got_hash, exp_hash, sim.result(), exp_result]
				)
			)
			failed += 1
		else:
			print("determinism: %s — ок (%s)" % [file_name, got_hash])
	return failed


func _self_check(data: SimData) -> int:
	var failed: int = 0
	for seed_value: int in SELF_CHECK_SEEDS:
		var run_log: RunLog = SimBot.new().play(data, seed_value)
		var a: BattleSim = RunLog.replay(run_log, data)
		var b: BattleSim = RunLog.replay(run_log, data)
		var parsed: Dictionary = JSON.parse_string(JSON.stringify(run_log.to_dict()))
		var c: BattleSim = RunLog.replay(RunLog.from_dict(parsed), data)
		if a.state_hash() != b.state_hash() or a.state_hash() != c.state_hash():
			printerr("determinism: зерно %d — повтор дал разные хэши" % seed_value)
			failed += 1
		elif not _same_result(a.result(), run_log.client_result):
			printerr("determinism: зерно %d — итог повтора не совпал с игрой" % seed_value)
			failed += 1
	return failed


func _print_fixtures(data: SimData, seeds_arg: String) -> void:
	for part: String in seeds_arg.split(","):
		var seed_value: int = int(part)
		var run_log: RunLog = SimBot.new().play(data, seed_value)
		var sim: BattleSim = RunLog.replay(run_log, data)
		var d: Dictionary = run_log.to_dict()
		d["expected"] = {"hash": sim.state_hash(), "result": sim.result()}
		print("FIXTURE %d %s" % [seed_value, JSON.stringify(d)])


## Сравнение итогов без учёта типа чисел (после JSON целые становятся дробными).
static func _same_result(a: Dictionary, b: Dictionary) -> bool:
	return JSON.stringify(_normalized(a)) == JSON.stringify(_normalized(b))


static func _normalized(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var keys: Array = d.keys()
	keys.sort()
	for k: Variant in keys:
		var v: Variant = d[k]
		out[str(k)] = Fixed.int_of(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else v
	return out


func _fixture_files(dir_path: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(FIXTURE_SUFFIX):
			result.append(file_name)
	result.sort()
	return result


func _arg_value(name: String, fallback: String) -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var i: int = args.find(name)
	if i >= 0 and i + 1 < args.size():
		return args[i + 1]
	return fallback
