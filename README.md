# Заводной Бастион (Clockwork Bastion)

Мобильная игра для Android: собери механизм из шестерней от Сердца, крути его в нужную сторону и защити Стену от волн Ржави.

## Быстрый старт
1. Установи: Godot 4.7.2, Node.js 22, Docker, Python 3.12, `pip install "gdtoolkit==4.*"`, `jq` (для хуков Claude Code).
2. `cp CLAUDE.local.md.example CLAUDE.local.md` и поправь под себя.
3. Открой папку в терминале и запусти `claude`. Первая задача: «выполни план docs/plans/00-setup.md».
4. `make help` — список команд.

## Где что лежит
| Путь | Что там |
|------|---------|
| `CLAUDE.md` | Главные правила для Claude Code (короткие) |
| `docs/design/core-rules.md` | Точные правила симуляции боя |
| `docs/design/mvp-scope.md` | Что входит в MVP |
| `docs/plan/game-plan.md` | Полный дизайн-документ |
| `docs/plans/` | Планы этапов, по одному на задачу |
| `docs/decisions/` | Архитектурные решения (ADR) |
| `.claude/rules/` | Правила, которые подгружаются только для своих папок |
| `.claude/agents/` | Субагенты: architect, code-reviewer, test-runner, economy-auditor, balance-analyst |
| `.claude/skills/` | Команды: /plan-feature, /add-gear, /add-monster, /server-rpc, /balance-check, /release-android, /commit |
| `.claude/hooks/` | Защита файлов, формат, проверка детерминизма, контекст сессии |

## Как работать с Claude Code
- Новая фича: `/plan-feature <что>` → проверь план → «делай по плану» → `code-reviewer` → `/commit`.
- Всё про валюту и покупки — через `/server-rpc`, затем `economy-auditor`.
- Изменил баланс — `/balance-check`.
- Сборку релиза и `git push` делаешь ты сам: у тебя ключи подписи.

## Поиграть на телефоне (debug-сборка)
1. GitHub → Actions → последний зелёный запуск **CI** → блок **Artifacts** → `clockwork-bastion-debug`.
2. Распакуй zip, перенеси `clockwork-bastion-debug.apk` на телефон, установи (разреши «установку из неизвестных источников»).
3. Локально собрать то же самое: `make build-debug` (нужны Godot 4.7.2 с шаблонами экспорта, Android SDK, JDK 17 и debug-ключ в настройках редактора).
