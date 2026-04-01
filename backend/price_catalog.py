"""Серверный каталог цен по SKU. Источник правды — JSON в репозитории (без секретов)."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

_CATALOG_PATH = Path(__file__).resolve().parent / "price_catalog.json"
_catalog_cache: dict[str, "_ProductRow"] | None = None


@dataclass(frozen=True)
class CatalogPrice:
    sku: str
    amount_minor: int
    currency: str


class UnknownSkuError(Exception):
    """SKU отсутствует в каталоге или неактивен."""

    def __init__(self, sku: str) -> None:
        self.sku = sku
        super().__init__(sku)


@dataclass(frozen=True)
class _ProductRow:
    sku: str
    amount_minor: int
    currency: str
    active: bool


def _load_raw() -> dict[str, _ProductRow]:
    global _catalog_cache
    if _catalog_cache is not None:
        return _catalog_cache
    with open(_CATALOG_PATH, encoding="utf-8") as f:
        data = json.load(f)
    rows: dict[str, _ProductRow] = {}
    for item in data.get("products", []):
        row = _ProductRow(
            sku=item["sku"],
            amount_minor=int(item["amount_minor"]),
            currency=str(item["currency"]).upper(),
            active=bool(item.get("active", True)),
        )
        rows[row.sku] = row
    _catalog_cache = rows
    return rows


def reload_catalog_for_tests() -> None:
    """Сброс кэша (только тесты / перезагрузка без рестарта процесса)."""
    global _catalog_cache
    _catalog_cache = None
    _load_raw()


def get_price(sku: str) -> CatalogPrice:
    """
    Возвращает цену и валюту для активного SKU.
    Неизвестный или неактивный SKU → UnknownSkuError.
    """
    rows = _load_raw()
    row = rows.get(sku)
    if row is None or not row.active:
        raise UnknownSkuError(sku)
    return CatalogPrice(sku=row.sku, amount_minor=row.amount_minor, currency=row.currency)


def list_active_prices() -> list[CatalogPrice]:
    """Все активные позиции каталога (для отображения в клиенте; суммы только с сервера)."""
    rows = _load_raw()
    out: list[CatalogPrice] = []
    for row in rows.values():
        if not row.active:
            continue
        out.append(CatalogPrice(sku=row.sku, amount_minor=row.amount_minor, currency=row.currency))
    return sorted(out, key=lambda p: p.sku)
