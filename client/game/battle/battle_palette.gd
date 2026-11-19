class_name BattlePalette
extends RefCounted
## Серая палитра прототипа. Направление — всегда цветом и стрелкой (доступность).

const BACKGROUND: Color = Color(0.11, 0.16, 0.18)
const FIELD: Color = Color(0.16, 0.21, 0.23)
const WALL: Color = Color(0.55, 0.45, 0.32)
const WALL_DAMAGED: Color = Color(0.75, 0.25, 0.2)
const CELL: Color = Color(0.2, 0.25, 0.27)
const CELL_BORDER: Color = Color(0.3, 0.36, 0.38)
const CLOCKWISE: Color = Color(1.0, 0.72, 0.2)
const COUNTER: Color = Color(0.25, 0.85, 0.8)
const GEAR: Color = Color(0.7, 0.72, 0.72)
const GEAR_OFF: Color = Color(0.38, 0.4, 0.4)
const HEART: Color = Color(0.85, 0.55, 0.25)
const MONSTER: Color = Color(0.82, 0.45, 0.2)
const MONSTER_FAST: Color = Color(0.9, 0.62, 0.3)
const HP_BACK: Color = Color(0.1, 0.1, 0.1)
const HP: Color = Color(0.4, 0.85, 0.35)
const HIT: Color = Color(1.0, 0.95, 0.7)
const TEXT: Color = Color(0.92, 0.92, 0.9)
const SLOT: Color = Color(0.22, 0.27, 0.3)


static func direction(clockwise: bool) -> Color:
	return CLOCKWISE if clockwise else COUNTER
