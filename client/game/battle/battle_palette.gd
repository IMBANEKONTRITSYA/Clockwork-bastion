class_name BattlePalette
extends RefCounted
## Палитра «лёгкого стимпанка»: тёплая латунь и медь на глубоком сине-зелёном (game-plan,
## «Визуальный стиль»). Направление — всегда цветом и стрелкой (доступность).

const BACKGROUND: Color = Color(0.07, 0.13, 0.15)
const TOP_BAR: Color = Color(0.05, 0.09, 0.11)
const FIELD: Color = Color(0.13, 0.2, 0.22)
const FIELD_STRIPE: Color = Color(0.15, 0.23, 0.25)
const BRASS: Color = Color(0.8, 0.6, 0.27)
const BRASS_DARK: Color = Color(0.45, 0.31, 0.12)
const COPPER: Color = Color(0.78, 0.45, 0.25)
const WALL: Color = Color(0.62, 0.47, 0.22)
const WALL_DAMAGED: Color = Color(0.75, 0.25, 0.2)
const CELL: Color = Color(0.1, 0.17, 0.19)
const CELL_PLUS: Color = Color(0.22, 0.32, 0.34)
const CLOCKWISE: Color = Color(1.0, 0.72, 0.2)
const COUNTER: Color = Color(0.25, 0.85, 0.8)
const GEAR_OFF: Color = Color(0.32, 0.35, 0.36)
const HEART: Color = Color(0.95, 0.7, 0.22)
const MONSTER: Color = Color(0.74, 0.36, 0.16)
const MONSTER_FAST: Color = Color(0.86, 0.52, 0.22)
const MONSTER_EYES: Color = Color(0.6, 1.0, 0.4)
const BOSS: Color = Color(0.55, 0.22, 0.12)
const HP_BACK: Color = Color(0.06, 0.06, 0.06)
const HP: Color = Color(0.4, 0.85, 0.35)
const BOSS_HP: Color = Color(0.9, 0.3, 0.22)
const HIT: Color = Color(1.0, 0.95, 0.7)
const TEXT: Color = Color(0.95, 0.93, 0.86)
const TEXT_DARK: Color = Color(0.12, 0.08, 0.04)
const SLOT: Color = Color(0.12, 0.19, 0.21)

## Цвет корпуса шестерни по типу: сталь, медь/пламя; неизвестный тип — латунь.
const GEAR_BODY: Dictionary = {
	"saw": Color(0.72, 0.76, 0.79),
	"steam": Color(0.85, 0.5, 0.28),
}


static func direction(clockwise: bool) -> Color:
	return CLOCKWISE if clockwise else COUNTER


static func gear_body(type: String) -> Color:
	if GEAR_BODY.has(type):
		var c: Color = GEAR_BODY[type]
		return c
	return BRASS
