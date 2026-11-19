class_name SimHash
extends RefCounted
## FNV-1a 32 бита поверх целых чисел и строк: хэш состояния забега для проверки детерминизма.

const OFFSET: int = 2166136261
const PRIME: int = 16777619
const MASK: int = 0xFFFFFFFF

var value: int = OFFSET


func add_int(v: int) -> void:
	for i: int in 8:
		_add_byte((v >> (8 * i)) & 0xFF)


func add_bool(v: bool) -> void:
	_add_byte(1 if v else 0)


func add_string(s: String) -> void:
	var bytes: PackedByteArray = s.to_utf8_buffer()
	add_int(bytes.size())
	for b: int in bytes:
		_add_byte(b)


func hex() -> String:
	return "%08x" % value


func _add_byte(b: int) -> void:
	value = ((value ^ b) * PRIME) & MASK
