extends SceneTree
## Проверка детерминизма: каждый эталонный журнал из --fixtures прогоняется
## симуляцией, хэш итогового состояния сравнивается с ожидаемым.
## Запуск: make determinism. Пока симуляции нет (этап 01, шаг 12),
## скрипт проверяет только наличие и формат эталонных журналов.

const FIXTURE_SUFFIX: String = ".json"


func _init() -> void:
	var dir_path: String = _arg_value("--fixtures", "res://tests/fixtures/runs")
	var files: PackedStringArray = _fixture_files(dir_path)
	if files.is_empty():
		print("determinism: эталонных журналов в %s пока нет — проверять нечего" % dir_path)
		quit(0)
		return
	var failed: int = 0
	for file_name: String in files:
		var path: String = dir_path.path_join(file_name)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary:
			printerr("determinism: %s — не JSON-объект" % path)
			failed += 1
			continue
		print("determinism: %s — формат ок (пересчёт появится на этапе 01)" % path)
	quit(1 if failed > 0 else 0)


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
