# Double Win Payments Backend (skeleton)

Минимальный backend-каркас для интеграции оплаты в игру.

## Stack

- Python 3.11+
- FastAPI
- Uvicorn

## Quick start (dev)

1. Создай и активируй виртуальное окружение:
   - Windows (PowerShell):
     - `python -m venv .venv`
     - `.\.venv\Scripts\Activate.ps1`
2. Установи зависимости:
   - `pip install -r requirements.txt`
3. Запусти сервер:
   - `uvicorn main:app --reload --host 127.0.0.1 --port 8000`

## Автотесты (TASK-12)

- Из каталога `backend/`, одна команда: `python -m pytest tests/ -v`.
- Покрытие: `get_price` / неизвестный SKU; `POST /payments/create` — сумма из каталога; webhook stub — дубликат по `external_event_id`, отказ при неверной подписи (HMAC), успешный `paid` → одна строка `user_entitlements`.
- In-memory SQLite с `StaticPool` (одна БД на все соединения тестового клиента).
- CI: в репозитории пока нет workflow — при появлении `.github/workflows` добавить job с `pytest`.

## Environment variables template (TASK-11)

- Безопасный шаблон для git: `backend/env.example`.
- Локально копируй шаблон в `.env` (или экспортируй переменные в shell), значения секретов не коммить.
- Текущий список переменных backend:
  - `DATABASE_URL`
  - `PAYMENT_PROVIDER`
  - `STUB_ALLOW_INSECURE_WEBHOOK`
  - `STUB_WEBHOOK_SECRET`

## Database migrations (TASK-03)

- По умолчанию используется `DATABASE_URL=sqlite:///./app.db`.
- Применить миграции:
  - `alembic upgrade head`
- Откатить последнюю миграцию:
  - `alembic downgrade -1`

## Health check

- `GET http://127.0.0.1:8000/health`
- Ожидаемый ответ: `{"status":"ok"}`

## Scope

В этом шаге добавлены базовая схема БД и миграции платежного домена (`orders`, `payments`, `payment_events`, `refunds`).
API оплаты, webhook, идемпотентность и выдача товара добавляются в следующих задачах (`TASK-04+`).

## Payment provider abstraction (TASK-04)

- Добавлен модуль `payment_gateway.py` с интерфейсом `PaymentGateway`.
- Реализован `StubGateway` для локальной разработки без реального провайдера.
- Конфиг провайдера:
  - `PAYMENT_PROVIDER=stub` (по умолчанию)
  - `STUB_ALLOW_INSECURE_WEBHOOK=true|false` (в dev можно оставить `true`)
  - `STUB_WEBHOOK_SECRET=...` (нужен, если `STUB_ALLOW_INSECURE_WEBHOOK=false`)

Проверка:
- `GET http://127.0.0.1:8000/debug/payment-gateway` возвращает данные, полученные через абстракцию `PaymentGateway`.

## Серверный каталог цен (TASK-05)

- Каталог без секретов: `price_catalog.json` (поля: `sku`, `amount_minor`, `currency`, `active`).
- Модуль `price_catalog.py`: `get_price(sku)` → сумма и валюта с сервера; неизвестный или неактивный SKU → `UnknownSkuError` (в HTTP — **404** с телом `{"error":"unknown_or_inactive_sku","sku":"..."}`).
- **Тестовые SKU для dev:** `dev_starter_pack_small` (99.00 RUB), `dev_starter_pack_large` (499.00 RUB); для четырёх паков лавки в Godot: `premium_ore_adventurer` (299.00 RUB), `premium_ore_commander` (599.00 RUB), `premium_ore_warlord` (1199.00 RUB). Пример отключённой позиции: `dev_inactive_example` (не продаётся).
- **Клиент Godot (TASK-10):** сцена `honor-of-aurora/ui/casle_minu/pay_shop/` — `POST /payments/create` → `OS.shell_open(payment_url)` → опрос `GET /payments/{order_id}/status` до `paid`+`granted` или таймаут; заголовок `X-User-Id` — стабильный id в `user://payment_x_user_id.txt`; база API: export `payment_api_base_url` на корне `PayShopMenu` (пустая строка = мгновенная покупка без сервера).
- Read-only API (цены не принимаются от клиента):
  - `GET /api/catalog/prices` — список активных позиций.
  - `GET /api/catalog/prices/{sku}` — одна позиция или 404.

## Создание платежа (TASK-06)

- `POST /payments/create` — тело `{"sku": "<string>"}`. Сумма и валюта берутся **только** из `get_price(sku)` / каталога.
- Заголовок **`X-User-Id`** — временная идентификация пользователя (если пусто — `dev-user`); дальше: session/JWT/device id (TODO).
- Ответ `200`: `order_id`, `payment_url`, опционально `expires_at` (ISO-8601), если провайдер вернул срок.
- Ошибки: неизвестный SKU — **404** (`unknown_or_inactive_sku`); сбой провайдера — **502** (`payment_provider_error`), заказ помечается `failed`; сбой записи платежа — **500** (`payment_persist_failed`), заказ также `failed`.

Перед вызовом: `alembic upgrade head`, переменные провайдера как в разделе TASK-04 выше.

## Webhook провайдера (TASK-07)

- `POST /payments/webhook/{provider}` — для `PAYMENT_PROVIDER=stub` путь **`/payments/webhook/stub`**.
- **Подпись:** при `STUB_ALLOW_INSECURE_WEBHOOK=false` заголовок **`X-Stub-Signature`** = hex HMAC-SHA256 тела запроса (сырые байты JSON) с ключом `STUB_WEBHOOK_SECRET`; при `true` подпись не проверяется (только dev).
- **Тело (JSON):** `external_payment_id` (как у `StubGateway.create_payment`), `external_event_id` (уникальный id события от провайдера), `event_type` — одно из: `paid`, `failed`, `cancelled`, `refunded`, `partially_refunded`.
- **Идемпотентность:** повтор с тем же `external_event_id` → **200** и `{"status":"ok","duplicate":true}` без повторного изменения статусов.
- **Ошибки:** неверная подпись — **403** (`invalid_webhook_signature`); неизвестный `provider` в пути — **404**; платёж не найден — **404**; неверное тело — **400**.
- **Выдача при `paid` (TASK-08):** в той же транзакции, что и запись `payment_events` и смена статусов, создаётся строка в `user_entitlements` с **уникальным** `order_id`; `orders.granted_at` выставляется. Повторный `paid` с другим `external_event_id` не дублирует выдачу (конфликт по `order_id` обрабатывается в savepoint).

Миграция `20260401_0002`: колонка `orders.granted_at`, таблица `user_entitlements`. Если заказ в статусе `paid`, а выдачи нет (аномалия), в журнале см. операционную заметку — правка вручную по строкам `user_entitlements` и `orders.granted_at`.

Для ручной проверки подписи в Python: `from payment_gateway import build_stub_signature` — передать те же байты тела, что уходят в POST.

## Статус заказа / оплаты (TASK-09)

- `GET /payments/{order_id}/status` — заголовок **`X-User-Id`** как у `POST /payments/create` (если пусто — `dev-user`).
- Ответ **200:** `order_id`, `payment_status` (строка enum: `pending`, `processing`, `paid`, `failed`, а также при webhook — `cancelled`, `refunded`, `partially_refunded`), `granted` (bool: выставлено `orders.granted_at` после успешной выдачи при `paid`).
- Источник `payment_status`: последний по `id` платёж по заказу, если есть; иначе статус заказа. Сырые payload провайдера не отдаются.
- **404** `order_not_found` — нет такого заказа или заказ принадлежит другому пользователю (единый ответ).
