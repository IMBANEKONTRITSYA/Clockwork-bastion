---
name: release-android
description: Готовит релиз Android-сборок для RuStore и Google Play — проверки, версия, заметки о выпуске, чек-листы. Используй, когда просят «собрать релиз», «выложить в тест» или «подготовить к публикации».
argument-hint: <магазин и трек: rustore | gplay-internal | gplay-closed | gplay-production>
disable-model-invocation: true
---

# Release Android

Трек: $ARGUMENTS

1. `make lint`, `make test`, `make determinism` — всё зелёное, иначе стоп.
2. Подними `version/code` в `client/export_presets.cfg` и `SIM_VERSION`, если менялась симуляция; сервер должен поддерживать и старую, и новую версию симуляции.
3. Проверь: targetSdk 36; для `gplay` — Play App Signing и ОТСУТСТВИЕ покупок и ссылок на оплату (`grep` по `client/services/shop/`, флаг `Store.has_payments()` = false); для `rustore` — боевые ID RuStore Pay и рекламных блоков Яндекса только в production.
4. Сборку (`make build-rustore` / `make build-gplay`) запускает пользователь — у него ключи подписи. Ты ключи не читаешь.
5. Напиши заметки о выпуске на русском (и английском для Google Play) (до 500 символов) по коммитам с прошлого тега.
6. Пройди нужную часть раздела «Чек-лист публикации: RuStore и Google Play» из `docs/plan/game-plan.md` и выведи незакрытые пункты.
7. Предложи тег `vX.Y.Z` и команду, но `git push` и загрузку в консоль делает пользователь.
