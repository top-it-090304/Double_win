# Android build handoff (without payment secrets)

This file is for the person who builds APK/AAB from this repository.
Do not commit any real secrets or private keys.

## 1) Required toolchain

- Godot: open `honor-of-aurora/project.godot` in your installed Godot 4.x.
- JDK and Android SDK: use the versions compatible with your Godot 4.x setup.
- Android export template for your Godot version must be installed locally.

## 2) Backend setup for dev build

1. Open `backend/`.
2. Copy `env.example` to local env file/shell vars (example: `.env`).
3. Fill local values if needed (never commit them).
4. Run backend:
   - `python -m venv .venv`
   - Windows PowerShell: `.\.venv\Scripts\Activate.ps1`
   - `pip install -r requirements.txt`
   - `alembic upgrade head`
   - `uvicorn main:app --reload --host 127.0.0.1 --port 8000`

## 3) Godot client payment config

- In scene `PayShopMenu`, set export variable `payment_api_base_url`:
  - Dev local backend: `http://127.0.0.1:8000`
  - Empty value means fallback "instant purchase" flow (without server payment API).
- Do not hardcode provider secrets in game scripts/scenes.

## 4) What must be provided out-of-band

Receive these only via private channel (not git):

- Android signing artifacts:
  - release keystore file
  - keystore alias/passwords
- Production backend URL for `payment_api_base_url`
- Production webhook/provider secrets (`STUB_WEBHOOK_SECRET` or real provider secrets)
- Any merchant identifiers that are not public by provider policy

## 5) Pre-release safety checklist

- No `.env` with real values is committed.
- No secrets in `export_presets.cfg`, scripts, or scene files.
- `PAYMENTS_LOCAL/` remains local only.
