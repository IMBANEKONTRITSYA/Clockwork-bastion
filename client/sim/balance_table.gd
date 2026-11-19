class_name BalanceTable
extends Resource
## Таблица баланса, собранная из data/balance/<name>.csv командой `make data`.
## Значения — int (дробные уже ×1000) или String-идентификаторы.
## Файлы client/data/*.tres руками не правим.

@export var table_name: String = ""
@export var columns: PackedStringArray = PackedStringArray()
## Строки в порядке CSV; каждая — Dictionary {колонка: int | String}.
@export var rows: Array = []


func has_row(id: String) -> bool:
	return _index_of(id) >= 0


## Строка по id. Отсутствующий id — ошибка данных, а не «тихий» ноль.
func get_row(id: String) -> Dictionary:
	var i: int = _index_of(id)
	assert(i >= 0, "BalanceTable %s: нет строки '%s'" % [table_name, id])
	return rows[i]


func get_int(id: String, column: String) -> int:
	var value: Variant = get_row(id).get(column)
	assert(value is int, "BalanceTable %s: %s.%s не целое" % [table_name, id, column])
	return value


func get_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for row: Dictionary in rows:
		ids.append(str(row["id"]))
	return ids


func _index_of(id: String) -> int:
	for i: int in rows.size():
		var row: Dictionary = rows[i]
		if str(row["id"]) == id:
			return i
	return -1
