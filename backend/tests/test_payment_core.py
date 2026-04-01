"""Ядро оплаты: create из каталога, webhook — подпись, идемпотентность, одна выдача."""

from __future__ import annotations

import json

from models import Order, PaymentStatus
from payment_gateway import StubGateway, build_stub_signature
from price_catalog import get_price

from tests.test_helpers import assert_single_entitlement_for_order, paid_order_status, refresh_state


def test_create_order_amount_from_catalog_only(client, db_session):
    sku = "dev_starter_pack_small"
    catalog = get_price(sku)
    r = client.post("/payments/create", json={"sku": sku}, headers={"X-User-Id": "buyer-1"})
    assert r.status_code == 200
    data = r.json()
    order_id = data["order_id"]
    refresh_state(db_session)

    row = db_session.get(Order, order_id)
    assert row is not None
    assert row.sku == catalog.sku
    assert row.amount_minor == catalog.amount_minor
    assert row.currency == catalog.currency
    assert row.status == PaymentStatus.PENDING


def test_webhook_paid_happy_path_grants_once(client, db_session):
    r = client.post(
        "/payments/create",
        json={"sku": "dev_starter_pack_small"},
        headers={"X-User-Id": "u-happy"},
    )
    assert r.status_code == 200
    order_id = r.json()["order_id"]
    ext_pay = f"stub-{order_id}-9900"

    body = {
        "external_payment_id": ext_pay,
        "external_event_id": "evt-happy-1",
        "event_type": "paid",
    }
    wr = client.post(
        "/payments/webhook/stub",
        content=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    assert wr.status_code == 200
    assert wr.json().get("duplicate") is False

    refresh_state(db_session)
    status, granted = paid_order_status(db_session, order_id)
    assert status == "paid"
    assert granted is True
    assert_single_entitlement_for_order(db_session, order_id)

    st = client.get(f"/payments/{order_id}/status", headers={"X-User-Id": "u-happy"})
    assert st.status_code == 200
    assert st.json() == {
        "order_id": order_id,
        "payment_status": "paid",
        "granted": True,
    }


def test_webhook_duplicate_external_event_id_is_idempotent(client, db_session):
    r = client.post(
        "/payments/create",
        json={"sku": "dev_starter_pack_small"},
        headers={"X-User-Id": "u-dup"},
    )
    assert r.status_code == 200
    order_id = r.json()["order_id"]
    ext_pay = f"stub-{order_id}-9900"
    body = {
        "external_payment_id": ext_pay,
        "external_event_id": "evt-same-duplicate",
        "event_type": "paid",
    }
    raw = json.dumps(body).encode("utf-8")

    w1 = client.post("/payments/webhook/stub", content=raw, headers={"Content-Type": "application/json"})
    assert w1.status_code == 200
    assert w1.json().get("duplicate") is False

    w2 = client.post("/payments/webhook/stub", content=raw, headers={"Content-Type": "application/json"})
    assert w2.status_code == 200
    assert w2.json().get("duplicate") is True

    refresh_state(db_session)
    assert_single_entitlement_for_order(db_session, order_id)
    status, granted = paid_order_status(db_session, order_id)
    assert status == "paid"
    assert granted is True


def test_webhook_rejects_invalid_signature(client, db_session, monkeypatch):
    import main

    r = client.post(
        "/payments/create",
        json={"sku": "dev_starter_pack_small"},
        headers={"X-User-Id": "u-sec"},
    )
    assert r.status_code == 200
    order_id = r.json()["order_id"]
    ext_pay = f"stub-{order_id}-9900"

    monkeypatch.setattr(
        main,
        "payment_gateway",
        StubGateway(allow_insecure_webhook=False, webhook_secret="test-secret"),
    )
    body = {
        "external_payment_id": ext_pay,
        "external_event_id": "evt-sec-1",
        "event_type": "paid",
    }
    raw = json.dumps(body).encode("utf-8")
    bad_sig = build_stub_signature(raw, "wrong-key")

    wr = client.post(
        "/payments/webhook/stub",
        content=raw,
        headers={"Content-Type": "application/json", "X-Stub-Signature": bad_sig},
    )
    assert wr.status_code == 403
    assert wr.json()["detail"]["error"] == "invalid_webhook_signature"

    refresh_state(db_session)
    status, granted = paid_order_status(db_session, order_id)
    assert status != "paid"
    assert granted is False


def test_webhook_accepts_valid_hmac_when_required(client, db_session, monkeypatch):
    import main

    secret = "test-secret"
    r = client.post(
        "/payments/create",
        json={"sku": "dev_starter_pack_small"},
        headers={"X-User-Id": "u-ok"},
    )
    assert r.status_code == 200
    order_id = r.json()["order_id"]
    ext_pay = f"stub-{order_id}-9900"

    monkeypatch.setattr(
        main,
        "payment_gateway",
        StubGateway(allow_insecure_webhook=False, webhook_secret=secret),
    )
    body = {
        "external_payment_id": ext_pay,
        "external_event_id": "evt-sec-ok",
        "event_type": "paid",
    }
    raw = json.dumps(body).encode("utf-8")
    sig = build_stub_signature(raw, secret)

    wr = client.post(
        "/payments/webhook/stub",
        content=raw,
        headers={"Content-Type": "application/json", "X-Stub-Signature": sig},
    )
    assert wr.status_code == 200
    refresh_state(db_session)
    assert_single_entitlement_for_order(db_session, order_id)
