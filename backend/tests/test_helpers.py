"""Общие проверки БД для тестов оплаты (без импорта из conftest)."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from models import Order, Payment, UserEntitlement


def refresh_state(db: Session) -> None:
    db.expire_all()


def assert_single_entitlement_for_order(db: Session, order_id: int) -> None:
    rows = list(db.scalars(select(UserEntitlement).where(UserEntitlement.order_id == order_id)))
    assert len(rows) == 1


def paid_order_status(db: Session, order_id: int) -> tuple[str, bool]:
    o = db.get(Order, order_id)
    assert o is not None
    p = db.scalars(select(Payment).where(Payment.order_id == order_id).order_by(Payment.id.desc())).first()
    status = p.status.value if p is not None else o.status.value
    granted = o.granted_at is not None
    return status, granted
