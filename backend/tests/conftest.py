"""Фикстуры: in-memory SQLite, override get_db, стабильный StubGateway."""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from database import Base, get_db
from payment_gateway import StubGateway


@pytest.fixture
def engine():
    # StaticPool: одна in-memory БД на все соединения (TestClient может открывать второй поток).
    eng = create_engine(
        "sqlite://",
        future=True,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=eng)
    return eng


@pytest.fixture
def db_session(engine) -> Session:
    SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
def client(db_session: Session, monkeypatch):
    import main

    gw = StubGateway(allow_insecure_webhook=True)
    monkeypatch.setattr(main, "payment_gateway", gw)

    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    main.app.dependency_overrides[get_db] = override_get_db
    with TestClient(main.app) as tc:
        yield tc
    main.app.dependency_overrides.clear()
