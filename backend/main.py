import json
import logging
from datetime import datetime, timezone

from fastapi import Depends, FastAPI, Header, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from database import get_db
from models import Order, Payment, PaymentEvent, PaymentStatus, UserEntitlement
from payment_gateway import (
    PaymentCreateRequest,
    build_payment_gateway_from_env,
    parse_stub_webhook_body,
)
from price_catalog import UnknownSkuError, get_price, list_active_prices


app = FastAPI(title="Double Win Payments Backend")
payment_gateway = build_payment_gateway_from_env()
logger = logging.getLogger(__name__)


class CreatePaymentBody(BaseModel):
    sku: str = Field(..., min_length=1, max_length=128)


class CreatePaymentResponse(BaseModel):
    order_id: int
    payment_url: str
    expires_at: str | None = None


class PaymentOrderStatusResponse(BaseModel):
    """Контракт для опроса статуса без сырых payload провайдера (TASK-09)."""

    order_id: int
    payment_status: str
    granted: bool

# Тестовый SKU для debug: цена только из серверного каталога, не с клиента.
_DEV_DEBUG_SKU = "dev_starter_pack_small"


@app.exception_handler(UnknownSkuError)
async def unknown_sku_handler(_request: Request, exc: UnknownSkuError) -> JSONResponse:
    return JSONResponse(
        status_code=404,
        content={"error": "unknown_or_inactive_sku", "sku": exc.sku},
    )


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/catalog/prices")
def api_catalog_prices() -> dict[str, list[dict[str, int | str]]]:
    """Активные позиции и цены с сервера; клиент не передаёт сумму."""
    items = list_active_prices()
    return {
        "items": [
            {"sku": p.sku, "amount_minor": p.amount_minor, "currency": p.currency} for p in items
        ]
    }


@app.get("/api/catalog/prices/{sku}")
def api_catalog_price(sku: str) -> dict[str, int | str]:
    """Одна позиция по SKU; неизвестный/неактивный → 404 (см. UnknownSkuError)."""
    p = get_price(sku)
    return {"sku": p.sku, "amount_minor": p.amount_minor, "currency": p.currency}


@app.post("/payments/create", response_model=CreatePaymentResponse)
def payments_create(
    body: CreatePaymentBody,
    db: Session = Depends(get_db),
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
) -> CreatePaymentResponse:
    """
    Создаёт заказ и платёж: сумма только из серверного каталога по sku.
    Аутентификация: временно заголовок X-User-Id (TODO: session/JWT/device id).
    """
    user_id = (x_user_id or "").strip() or "dev-user"
    price = get_price(body.sku)

    order = Order(
        user_id=user_id[:64],
        sku=price.sku,
        amount_minor=price.amount_minor,
        currency=price.currency,
        status=PaymentStatus.PENDING,
    )
    db.add(order)
    try:
        db.commit()
        db.refresh(order)
    except Exception:
        db.rollback()
        raise

    gateway_req = PaymentCreateRequest(
        order_id=order.id,
        amount_minor=price.amount_minor,
        currency=price.currency,
        description=f"sku:{price.sku}",
    )
    try:
        created = payment_gateway.create_payment(gateway_req)
    except Exception:
        db.rollback()
        row = db.get(Order, order.id)
        if row is not None:
            row.status = PaymentStatus.FAILED
            db.commit()
        raise HTTPException(
            status_code=502,
            detail={"error": "payment_provider_error"},
        ) from None

    payment = Payment(
        order_id=order.id,
        provider=payment_gateway.provider_name,
        external_payment_id=created.external_payment_id,
        status=PaymentStatus.PROCESSING,
        amount_minor=price.amount_minor,
    )
    db.add(payment)
    try:
        db.commit()
    except Exception:
        db.rollback()
        row = db.get(Order, order.id)
        if row is not None:
            row.status = PaymentStatus.FAILED
            db.commit()
        raise HTTPException(
            status_code=500,
            detail={"error": "payment_persist_failed"},
        ) from None

    expires_iso = created.expires_at.isoformat() if created.expires_at else None
    return CreatePaymentResponse(
        order_id=order.id,
        payment_url=created.payment_url,
        expires_at=expires_iso,
    )


@app.get("/payments/{order_id}/status", response_model=PaymentOrderStatusResponse)
def payments_order_status(
    order_id: int,
    db: Session = Depends(get_db),
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
) -> PaymentOrderStatusResponse:
    """
    Статус оплаты и факт выдачи по заказу. Только владелец (тот же X-User-Id, что при create).
    Чужой или несуществующий order_id → 404 без утечки факта существования.
    """
    user_id = ((x_user_id or "").strip() or "dev-user")[:64]
    order = db.get(Order, order_id)
    if order is None or order.user_id != user_id:
        raise HTTPException(status_code=404, detail={"error": "order_not_found"})

    payment = db.scalars(
        select(Payment).where(Payment.order_id == order_id).order_by(Payment.id.desc()).limit(1)
    ).first()
    if payment is not None:
        status_str = payment.status.value
    else:
        status_str = order.status.value

    return PaymentOrderStatusResponse(
        order_id=order.id,
        payment_status=status_str,
        granted=order.granted_at is not None,
    )


def _webhook_headers_for_gateway(request: Request) -> dict[str, str]:
    return {k.lower(): v for k, v in request.headers.items()}


def _grant_entitlement_for_paid_order(db: Session, order_row: Order, now: datetime) -> None:
    """
    В той же внешней транзакции, что и webhook: одна строка user_entitlements на order_id.
    Повторный paid (другой external_event_id) — вложенный savepoint + UNIQUE(order_id) без второй выдачи.
    """
    try:
        with db.begin_nested():
            db.add(
                UserEntitlement(
                    user_id=order_row.user_id,
                    sku=order_row.sku,
                    order_id=order_row.id,
                    granted_at=now,
                )
            )
            db.flush()
        order_row.granted_at = now
    except IntegrityError:
        existing = db.scalars(
            select(UserEntitlement).where(UserEntitlement.order_id == order_row.id).limit(1)
        ).first()
        if existing is not None:
            order_row.granted_at = existing.granted_at
            logger.info("fulfillment idempotent order_id=%s (entitlement already present)", order_row.id)
        else:
            logger.warning(
                "paid order_id=%s: entitlement insert failed but no row found; repair manually (user_entitlements + orders.granted_at)",
                order_row.id,
            )


@app.post("/payments/webhook/{provider}")
async def payments_webhook(provider: str, request: Request, db: Session = Depends(get_db)) -> dict[str, str | bool]:
    """
    Webhook провайдера: подпись до обращения к БД; идемпотентность по payment_events.external_event_id.
    При event_type=paid в той же транзакции: запись события, статусы, выдача entitlements и orders.granted_at.
    """
    prov = provider.strip().lower()
    if prov != payment_gateway.provider_name.lower():
        raise HTTPException(status_code=404, detail={"error": "unknown_provider"})

    raw_body = await request.body()
    headers = _webhook_headers_for_gateway(request)
    if not payment_gateway.verify_webhook_signature(raw_body, headers):
        raise HTTPException(status_code=403, detail={"error": "invalid_webhook_signature"})

    try:
        payload = json.loads(raw_body.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        raise HTTPException(status_code=400, detail={"error": "invalid_json"}) from None

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail={"error": "invalid_json"})

    if payment_gateway.provider_name != "stub":
        raise HTTPException(status_code=501, detail={"error": "provider_webhook_not_implemented"})

    try:
        event = parse_stub_webhook_body(payload)
    except ValueError as e:
        raise HTTPException(status_code=400, detail={"error": str(e)}) from None

    dup = db.scalars(
        select(PaymentEvent).where(PaymentEvent.external_event_id == event.external_event_id).limit(1)
    ).first()
    if dup is not None:
        logger.info(
            "webhook duplicate event ignored provider=%s external_event_id=%s",
            prov,
            event.external_event_id[:32],
        )
        return {"status": "ok", "duplicate": True}

    payment = db.scalars(
        select(Payment).where(
            Payment.provider == payment_gateway.provider_name,
            Payment.external_payment_id == event.external_payment_id,
        )
    ).first()
    if payment is None:
        raise HTTPException(status_code=404, detail={"error": "payment_not_found"})

    order = db.get(Order, payment.order_id)
    if order is None:
        raise HTTPException(status_code=500, detail={"error": "order_missing"}) from None

    now = datetime.now(timezone.utc)
    payment_row = payment
    order_row = order

    pe = PaymentEvent(
        payment_id=payment_row.id,
        event_type=event.event_type,
        external_event_id=event.external_event_id,
        payload=payload,
        is_duplicate=False,
    )
    db.add(pe)
    payment_row.status = event.target_status
    order_row.status = event.target_status
    if event.target_status == PaymentStatus.PAID:
        payment_row.paid_at = now
        _grant_entitlement_for_paid_order(db, order_row, now)
    payment_row.raw_payload = payload

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        logger.info(
            "webhook race duplicate event provider=%s external_event_id=%s",
            prov,
            event.external_event_id[:32],
        )
        return {"status": "ok", "duplicate": True}

    logger.info(
        "webhook applied provider=%s payment_db_id=%s external_payment_id=%s event_type=%s",
        prov,
        payment_row.id,
        event.external_payment_id[:24],
        event.event_type,
    )
    return {"status": "ok", "duplicate": False}


@app.get("/debug/payment-gateway")
def debug_payment_gateway() -> dict[str, str]:
    price = get_price(_DEV_DEBUG_SKU)
    order = PaymentCreateRequest(order_id=1, amount_minor=price.amount_minor, currency=price.currency)
    created = payment_gateway.create_payment(order)
    return {
        "provider": payment_gateway.provider_name,
        "external_payment_id": created.external_payment_id,
        "payment_url": created.payment_url,
        "sku_used": price.sku,
        "amount_minor": str(price.amount_minor),
        "currency": price.currency,
    }
