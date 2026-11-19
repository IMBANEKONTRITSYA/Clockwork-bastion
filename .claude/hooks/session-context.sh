#!/usr/bin/env bash
# SessionStart: stdout добавляется в контекст Claude в начале сессии.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "## Состояние репозитория"
  echo "- Ветка: $(git branch --show-current)"
  changed=$(git status --porcelain | wc -l | tr -d ' ')
  echo "- Незакоммиченных файлов: $changed"
  echo "- Последние коммиты:"
  git log --oneline -5 2>/dev/null | sed 's/^/  - /'
fi
# Активный план: первый по номеру план в docs/plans/ с незакрытыми пунктами (кроме README)
latest_plan=""
for f in $(ls docs/plans/[0-9]*.md 2>/dev/null | sort); do
  if grep -q '^- \[ \]' "$f"; then latest_plan="$f"; break; fi
done
if [ -n "$latest_plan" ]; then
  echo "- Активный план: $latest_plan (прочитай перед работой, если задача связана с ним)"
  open_tasks=$(grep -c '^- \[ \]' "$latest_plan" 2>/dev/null)
  echo "- Незакрытых пунктов в плане: ${open_tasks:-0}"
fi
exit 0
