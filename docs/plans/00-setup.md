# 00. Каркас репозитория

Цель: пустой проект открывается в Godot, тесты и линтеры проходят локально и в CI, сервер поднимается одной командой.
Раздел плана: «Стек технологий», «Неделя 1» в `docs/plan/game-plan.md`.

## Шаги
- [ ] 1. `git init`, первый коммит с этим набором файлов — тест: `git status` чистый
- [ ] 2. Проект Godot 4.7.2 в `client/` (портрет 1080×1920, stretch canvas_items, renderer Mobile, предупреждения типизации = ошибка) — тест: `godot --headless --path client --quit` без ошибок
- [ ] 3. Установить GUT в `client/addons/gut/`, пустой тест `client/tests/test_smoke.gd` — тест: `make test-client`
- [ ] 4. Папки `client/sim`, `client/game`, `client/meta`, `client/services`, `client/data`, `client/i18n/strings.csv` (ru, en) — тест: проект открывается
- [ ] 5. `client/sim/rng.gd` (SimRng: 64-битный xorshift с маской, методы `next_int()`, `range(a, b)`, `chance_permille(p)`) и `client/sim/version.gd` (`SIM_VERSION := 1`) + тест: одинаковое зерно → одинаковые 1000 чисел; эталонные первые 10 чисел для зерна 123456789 записаны в тест — тест: `make test-one T=res://tests/sim/test_rng.gd`
- [ ] 6. `server/`: package.json (TypeScript strict, eslint, prettier, jest), `docker-compose.yml` (nakama + postgres), `src/main.ts` с RPC `healthcheck` — тест: `make test-server`, `make server-up`
- [ ] 7. `tools/build_data.py` + `data/balance/gears.csv` с одной строкой — тест: `make data` создаёт `client/data/gears.tres`
- [ ] 8. `pip install "gdtoolkit==4.*"`, `make lint` зелёный
- [ ] 9. GitHub-репозиторий, CI зелёный на первом PR

## Затрагиваемые файлы
`client/**`, `server/**`, `tools/build_data.py`, `data/balance/gears.csv`

## Риски
- Версия GUT должна поддерживать Godot 4.7 — бери последнюю 9.x.
- Docker на Windows: WSL2.

## Готово, когда
`make test`, `make lint`, `make data` проходят; CI зелёный; `make server-up` отвечает на `healthcheck`.
