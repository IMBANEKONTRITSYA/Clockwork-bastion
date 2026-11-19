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
# Текущее состояние из HANDOFF.md: только таблица «Сейчас в работе»
if [ -f HANDOFF.md ]; then
  echo "## Сейчас в работе (из HANDOFF.md)"
  awk '/^## Сейчас в работе/{f=1;next} /^## /{f=0} f && /^\|/' HANDOFF.md | head -n 10
fi
# Активный план: самый свежий файл в docs/plans/ (кроме README)
latest_plan=$(ls -t docs/plans/*.md 2>/dev/null | grep -v README | head -1)
if [ -n "$latest_plan" ]; then
  echo "- Активный план: $latest_plan (прочитай перед работой, если задача связана с ним)"
  open_tasks=$(grep -c '^- \[ \]' "$latest_plan" 2>/dev/null)
  echo "- Незакрытых пунктов в плане: ${open_tasks:-0}"
fi
exit 0
