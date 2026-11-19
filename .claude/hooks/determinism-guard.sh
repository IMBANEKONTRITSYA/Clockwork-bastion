#!/usr/bin/env bash
# PostToolUse (Edit|Write): следит, чтобы симуляция боя оставалась детерминированной.
# Срабатывает только для client/sim/**/*.gd. exit 2 => stderr уходит Claude как замечание.
# Требует jq.
file=$(jq -r '.tool_input.file_path // empty')
[ -z "$file" ] || [ ! -f "$file" ] && exit 0
[[ "$file" == *"client/sim/"*".gd" ]] || exit 0
# Генератор случайных чисел — единственное место, где разрешена работа с битами RNG.
[[ "$file" == *"client/sim/rng.gd" ]] && exit 0

# Запрещено в симуляции: дробные числа, системная случайность, время, ноды и сцены.
patterns='(:[[:space:]]*float\b|\bfloat\(|[0-9]+\.[0-9]+|\brandf\(|\brandi\(|\brandf_range\(|\brandi_range\(|RandomNumberGenerator|\bTime\.|OS\.get_ticks|get_tree\(|extends[[:space:]]+Node|\bpow\(|\bsqrt\()'
hits=$(grep -nE "$patterns" "$file" | grep -vE '^\s*[0-9]+:\s*#' )
if [ -n "$hits" ]; then
  echo "Нарушение детерминизма в $file (см. CLAUDE.md и .claude/rules/simulation.md):" >&2
  echo "$hits" | head -20 >&2
  echo "Используй целые числа (фиксированная точка ×1000), таблицы степеней и SimRng. Исправь эти строки." >&2
  exit 2
fi
exit 0
