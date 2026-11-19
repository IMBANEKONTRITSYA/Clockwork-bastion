extends GutTest
## Локализация: у каждого ключа есть ru и en; все ключи из кода есть в strings.csv.

const STRINGS: String = "res://i18n/strings.csv"
const CODE_DIRS: Array[String] = ["res://game", "res://meta"]


func _table() -> Dictionary:
	var out: Dictionary = {}
	var f: FileAccess = FileAccess.open(STRINGS, FileAccess.READ)
	var header: PackedStringArray = f.get_csv_line()
	assert_eq(Array(header), ["keys", "ru", "en"])
	while not f.eof_reached():
		var row: PackedStringArray = f.get_csv_line()
		if row.size() < 3 or row[0] == "":
			continue
		out[row[0]] = row
	return out


func test_every_key_has_ru_and_en() -> void:
	var table: Dictionary = _table()
	assert_gt(table.size(), 0)
	for key: Variant in table:
		var row: PackedStringArray = table[key]
		assert_ne(row[1].strip_edges(), "", "%s: нет ru" % key)
		assert_ne(row[2].strip_edges(), "", "%s: нет en" % key)


func test_keys_used_in_code_exist() -> void:
	var table: Dictionary = _table()
	var re: RegEx = RegEx.create_from_string('(?:tr|_fmt)\\("([A-Z0-9_]+)"')
	for dir_path: String in CODE_DIRS:
		for path: String in _gd_files(dir_path):
			for m: RegExMatch in re.search_all(FileAccess.get_file_as_string(path)):
				assert_true(
					table.has(m.get_string(1)), "%s: нет ключа %s" % [path, m.get_string(1)]
				)


func _gd_files(dir_path: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if not DirAccess.dir_exists_absolute(dir_path):
		return out
	for name: String in DirAccess.get_files_at(dir_path):
		if name.ends_with(".gd"):
			out.append(dir_path.path_join(name))
	for sub: String in DirAccess.get_directories_at(dir_path):
		out.append_array(_gd_files(dir_path.path_join(sub)))
	return out
