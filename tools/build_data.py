#!/usr/bin/env python3
"""Сборка данных баланса: data/balance/*.csv -> client/data/*.tres.

Каждый CSV превращается в ресурс BalanceTable (client/sim/balance_table.gd):
  - первая строка — имена колонок, первая колонка — `id` (уникальный);
  - значения — целые числа (дробные уже ×1000, см. .claude/rules/data-balance.md)
    или строки-идентификаторы; числа с точкой запрещены;
  - пустые строки и строки, начинающиеся с `#`, пропускаются.

Запуск: python3 tools/build_data.py data/balance client/data
"""

from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path

SCRIPT_PATH = "res://sim/balance_table.gd"
INT_RE = re.compile(r"^-?\d+$")
DECIMAL_RE = re.compile(r"^-?\d*[.,]\d+$")
NAME_RE = re.compile(r"^[a-z][a-z0-9_]*$")


class DataError(Exception):
    pass


def parse_value(raw: str, where: str) -> int | str:
    value = raw.strip()
    if INT_RE.match(value):
        return int(value)
    if DECIMAL_RE.match(value):
        raise DataError(f"{where}: дробное число '{value}' — пиши ×1000 целым")
    return value


def read_table(path: Path) -> tuple[list[str], list[dict[str, int | str]]]:
    with path.open(encoding="utf-8", newline="") as f:
        lines = [ln for ln in f if ln.strip() and not ln.lstrip().startswith("#")]
    reader = csv.reader(lines)
    try:
        header = [h.strip() for h in next(reader)]
    except StopIteration as exc:
        raise DataError(f"{path.name}: пустой файл") from exc
    if not header or header[0] != "id":
        raise DataError(f"{path.name}: первая колонка должна называться 'id'")
    for name in header:
        if not NAME_RE.match(name):
            raise DataError(f"{path.name}: плохое имя колонки '{name}' (snake_case)")
    if len(set(header)) != len(header):
        raise DataError(f"{path.name}: повторяются имена колонок")

    rows: list[dict[str, int | str]] = []
    seen: set[str] = set()
    for line_no, cells in enumerate(reader, start=2):
        if len(cells) != len(header):
            raise DataError(
                f"{path.name}:{line_no}: {len(cells)} значений, а колонок {len(header)}"
            )
        row = {
            name: parse_value(cell, f"{path.name}:{line_no}:{name}")
            for name, cell in zip(header, cells)
        }
        row_id = str(row["id"])
        if row_id in seen:
            raise DataError(f"{path.name}:{line_no}: повтор id '{row_id}'")
        seen.add(row_id)
        rows.append(row)
    return header, rows


def gd_value(value: int | str) -> str:
    if isinstance(value, int):
        return str(value)
    return json.dumps(value, ensure_ascii=False)


def to_tres(table_name: str, header: list[str], rows: list[dict[str, int | str]]) -> str:
    columns = ", ".join(json.dumps(h) for h in header)
    row_texts = []
    for row in rows:
        fields = ",\n".join(f"{json.dumps(k)}: {gd_value(v)}" for k, v in row.items())
        row_texts.append("{\n" + fields + "\n}")
    rows_text = "[" + ", ".join(row_texts) + "]"
    return (
        '[gd_resource type="Resource" script_class="BalanceTable" load_steps=2 format=3]\n\n'
        f'[ext_resource type="Script" path="{SCRIPT_PATH}" id="1_table"]\n\n'
        "[resource]\n"
        'script = ExtResource("1_table")\n'
        f"table_name = {json.dumps(table_name)}\n"
        f"columns = PackedStringArray({columns})\n"
        f"rows = {rows_text}\n"
    )


def build(src: Path, dst: Path) -> list[Path]:
    csv_files = sorted(src.glob("*.csv"))
    if not csv_files:
        raise DataError(f"в {src} нет CSV-файлов")
    dst.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    for path in csv_files:
        header, rows = read_table(path)
        out = dst / f"{path.stem}.tres"
        out.write_text(to_tres(path.stem, header, rows), encoding="utf-8")
        written.append(out)
    return written


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("Использование: build_data.py <папка CSV> <папка .tres>", file=sys.stderr)
        return 2
    try:
        written = build(Path(argv[1]), Path(argv[2]))
    except DataError as err:
        print(f"Ошибка данных: {err}", file=sys.stderr)
        return 1
    for out in written:
        print(f"  {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
