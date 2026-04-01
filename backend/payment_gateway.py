from __future__ import annotations

import hashlib
import hmac
import os
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Protocol

from models import PaymentStatus


@dataclass(frozen=True)
class PaymentCreateRequest:
    order_id: int
    amount_minor: int
    currency: str
    description: str | None = None


@dataclass(frozen=True)
class PaymentCreateResult:
    payment_url: str
    external_payment_id: str
    expires_at: datetime | None = None


@dataclass(frozen=True)
class RefundResult:
    success: bool
    external_refund_id: str | None = None
    reason: str | None = None


@dataclass(frozen=True)
class StubWebhookEvent:
    """Поля из JSON тела webhook заглушки (TASK-07)."""

    external_payment_id: str
    external_event_id: str
    event_type: str
    target_status: PaymentStatus


_STUB_EVENT_TO_STATUS: dict[str, PaymentStatus] = {
    "paid": PaymentStatus.PAID,
    "failed": PaymentStatus.FAILED,
    "cancelled": PaymentStatus.CANCELLED,
    "refunded": PaymentStatus.REFUNDED,
    "partially_refunded": PaymentStatus.PARTIALLY_REFUNDED,
}


def parse_stub_webhook_body(data: dict) -> StubWebhookEvent:
    """Разбор тела POST /payments/webhook/stub; при ошибке — ValueError."""
    ext_pay = data.get("external_payment_id")
    ext_evt = data.get("external_event_id")
    evt_type = data.get("event_type")
    if not isinstance(ext_pay, str) or not ext_pay.strip():
        raise ValueError("invalid_external_payment_id")
    if not isinstance(ext_evt, str) or not ext_evt.strip():
        raise ValueError("invalid_external_event_id")
    if not isinstance(evt_type, str) or not evt_type.strip():
        raise ValueError("invalid_event_type")
    key = evt_type.strip().lower()
    status = _STUB_EVENT_TO_STATUS.get(key)
    if status is None:
        raise ValueError("unknown_event_type")
    return StubWebhookEvent(
        external_payment_id=ext_pay.strip()[:128],
        external_event_id=ext_evt.strip()[:128],
        event_type=key,
        target_status=status,
    )


class PaymentGateway(Protocol):
    provider_name: str

    def create_payment(self, order: PaymentCreateRequest) -> PaymentCreateResult:
        """Create a provider payment and return redirect data."""

    def get_payment_status(self, external_payment_id: str) -> PaymentStatus:
        """Fetch payment status from provider."""

    def refund(self, payment_id: str, amount_minor: int) -> RefundResult:
        """Run refund operation for a successful payment."""

    def verify_webhook_signature(self, payload: bytes, headers: dict[str, str]) -> bool:
        """Verify provider webhook signature."""


class StubGateway:
    provider_name = "stub"

    def __init__(self, allow_insecure_webhook: bool = True, webhook_secret: str | None = None) -> None:
        self.allow_insecure_webhook = allow_insecure_webhook
        self.webhook_secret = webhook_secret

    def create_payment(self, order: PaymentCreateRequest) -> PaymentCreateResult:
        external_payment_id = f"stub-{order.order_id}-{order.amount_minor}"
        payment_url = f"https://stub-payments.local/redirect/{external_payment_id}"
        return PaymentCreateResult(payment_url=payment_url, external_payment_id=external_payment_id)

    def get_payment_status(self, external_payment_id: str) -> PaymentStatus:
        normalized = external_payment_id.lower()
        if "paid" in normalized:
            return PaymentStatus.PAID
        if "fail" in normalized:
            return PaymentStatus.FAILED
        return PaymentStatus.PENDING

    def refund(self, payment_id: str, amount_minor: int) -> RefundResult:
        if amount_minor <= 0:
            return RefundResult(success=False, reason="amount must be greater than zero")
        if "fail" in payment_id.lower():
            return RefundResult(success=False, reason="stub payment is configured to fail")
        external_refund_id = f"stub-refund-{payment_id}-{amount_minor}"
        return RefundResult(success=True, external_refund_id=external_refund_id)

    def verify_webhook_signature(self, payload: bytes, headers: dict[str, str]) -> bool:
        if self.allow_insecure_webhook:
            return True
        if not self.webhook_secret:
            return False
        signature = headers.get("x-stub-signature", "")
        digest = hmac.new(self.webhook_secret.encode("utf-8"), payload, hashlib.sha256).hexdigest()
        return hmac.compare_digest(signature, digest)


def build_payment_gateway_from_env() -> PaymentGateway:
    provider = os.getenv("PAYMENT_PROVIDER", "stub").strip().lower()
    if provider != "stub":
        raise ValueError(f"Unsupported PAYMENT_PROVIDER: {provider}")

    allow_insecure = os.getenv("STUB_ALLOW_INSECURE_WEBHOOK", "true").strip().lower() == "true"
    webhook_secret = os.getenv("STUB_WEBHOOK_SECRET")
    return StubGateway(allow_insecure_webhook=allow_insecure, webhook_secret=webhook_secret)


def build_stub_signature(payload: bytes, secret: str) -> str:
    return hmac.new(secret.encode("utf-8"), payload, hashlib.sha256).hexdigest()


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()
