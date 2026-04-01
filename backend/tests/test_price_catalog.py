"""Серверный каталог SKU: цена только из get_price, неизвестный SKU — ошибка."""

import pytest

from price_catalog import UnknownSkuError, get_price


def test_get_price_dev_starter_small():
    p = get_price("dev_starter_pack_small")
    assert p.sku == "dev_starter_pack_small"
    assert p.amount_minor == 9900
    assert p.currency == "RUB"


def test_get_price_unknown_sku_raises():
    with pytest.raises(UnknownSkuError) as exc:
        get_price("no_such_sku_ever")
    assert exc.value.sku == "no_such_sku_ever"


def test_inactive_sku_raises():
    with pytest.raises(UnknownSkuError):
        get_price("dev_inactive_example")
