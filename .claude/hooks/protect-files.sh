#!/usr/bin/env bash
# PreToolUse (Edit|Write): блокирует изменение защищённых файлов. Требует jq.
# exit 2 => вызов инструмента отменяется, stderr передаётся Claude.
file=$(jq -r '.tool_input.file_path // empty')
[ -z "$file" ] && exit 0

protected=(
  ".env"
  ".git/"
  "secrets/"
  ".keystore"
  ".jks"
  "export_credentials.cfg"
  "service-account"
  "package-lock.json"
  "server/migrations/"
  "client/addons/"
  "data/balance/archive/"
)
for p in "${protected[@]}"; do
  if [[ "$file" == *"$p"* ]]; then
    echo "Файл '$file' защищён (совпадение с '$p'). Не изменяй его; если это действительно нужно — попроси пользователя." >&2
    exit 2
  fi
done
exit 0
