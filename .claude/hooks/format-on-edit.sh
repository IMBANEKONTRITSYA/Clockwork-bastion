#!/usr/bin/env bash
# PostToolUse (Edit|Write): форматирует изменённый файл. Требует jq.
# GDScript — gdformat из gdtoolkit (pip install "gdtoolkit==4.*"), остальное — prettier.
file=$(jq -r '.tool_input.file_path // empty')
[ -z "$file" ] || [ ! -f "$file" ] && exit 0

case "$file" in
  *.gd)
    command -v gdformat >/dev/null && gdformat "$file" >/dev/null 2>&1 ;;
  *.ts|*.js|*.mjs|*.json|*.yml|*.yaml)
    if [ -d "${CLAUDE_PROJECT_DIR:-.}/server/node_modules" ]; then
      (cd "${CLAUDE_PROJECT_DIR:-.}/server" && npx --no-install prettier --write "$file" >/dev/null 2>&1)
    fi ;;
esac
exit 0
