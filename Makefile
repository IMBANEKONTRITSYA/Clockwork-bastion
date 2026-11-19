# Заводной Бастион — команды разработки. Запускать из корня репозитория.
GODOT ?= godot
GUT   := $(GODOT) --headless --path client -s addons/gut/gut_cmdln.gd -gexit
RUNS  ?= 1000

.PHONY: help test test-client test-server test-one lint determinism fixtures sim data \
        server-up server-down build-debug build-rustore build-gplay

help:            ## Список команд
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-15s %s\n", $$1, $$2}'

test: test-client test-server  ## Все тесты

test-client:     ## Тесты клиента (GUT, headless)
	$(GUT) -gdir=res://tests -ginclude_subdirs

test-server:     ## Тесты сервера (Jest)
	cd server && npm test

test-one:        ## Один тест клиента: make test-one T=res://tests/sim/test_power.gd
	@test -n "$(T)" || (echo "Укажи T=res://tests/..." && exit 1)
	$(GUT) -gtest=$(T)

lint:            ## gdlint + gdformat --check + eslint + tsc
	gdlint client/sim client/game client/meta client/services
	gdformat --check client/sim client/game client/meta client/services
	cd server && npm run lint && npx tsc --noEmit

determinism:     ## Эталонные журналы: хэш клиента == хэш валидатора
	$(GODOT) --headless --path client --script res://tools/determinism_check.gd -- \
		--fixtures res://tests/fixtures/runs

fixtures:        ## Напечатать эталонные журналы бота: make fixtures SEEDS=101,202
	$(GODOT) --headless --path client --script res://tools/determinism_check.gd -- \
		--print-fixtures $(or $(SEEDS),101)

sim:             ## Симулятор баланса: make sim RUNS=10000 -> tools/out/
	mkdir -p tools/out
	$(GODOT) --headless --path client --script res://tools/balance_sim.gd -- \
		--runs $(RUNS) --out ../tools/out/sim-$$(date +%Y%m%d-%H%M%S).json

data:            ## CSV из data/balance -> ресурсы client/data/*.tres
	python3 tools/build_data.py data/balance client/data

server-up:       ## Поднять Nakama + PostgreSQL локально
	cd server && npm run build && docker compose up -d

server-down:     ## Остановить локальный сервер (данные сохраняются)
	cd server && docker compose down

build-debug:     ## Debug-APK для своего телефона (ключ отладки, без магазинов)
	mkdir -p build
	$(GODOT) --headless --path client --export-debug "Android Debug" ../build/clockwork-bastion-debug.apk

build-rustore:   ## Сборка для RuStore с оплатой (только у пользователя: ключи подписи)
	$(GODOT) --headless --path client --export-release "Android RuStore" ../build/clockwork-bastion-rustore.apk

build-gplay:     ## Сборка для Google Play без покупок (только у пользователя)
	$(GODOT) --headless --path client --export-release "Android Google Play" ../build/clockwork-bastion-gplay.aab
