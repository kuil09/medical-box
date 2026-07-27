# Medical Box

Medical Box is a privacy-first Flutter application and access-controlled Korean
medicine catalog service for a closed beta. The Korean product name is
“우리집 구급키트.”

## Repository layout

| Path | Purpose |
| --- | --- |
| `apps/mobile` | iOS and Android Flutter application |
| `services/backend` | FastAPI account and permission-gated catalog API |
| `design/prototype` | Product Design mobile interaction prototype and QA evidence |
| `.railway` | Railway project-level Infrastructure as Code |
| `docs` | Architecture, security, catalog, and release runbooks |

## Privacy boundary

Household names, member profiles, containers, inventory quantities, expiry
dates, private notes, visit plans, and reminder bodies are stored only in the
encrypted on-device Drift database. The backend has no tables or endpoints for
those entities. The organizer remains usable without an account, while official
catalog search, detail, and DUR requests require an authenticated account with
the server-side `catalog:read` permission.

The product does not diagnose, calculate doses, recommend treatment, or suggest
replacement medicines. Prescription functionality is limited to visit and
renewal preparation.

## Local development

### Backend

```bash
cd services/backend
uv sync --extra dev
uv run alembic upgrade head
uv run uvicorn medical_box_api.main:app --reload
```

### Flutter

Install FVM, then use the pinned Flutter SDK:

```bash
cd apps/mobile
fvm install
fvm flutter pub get
fvm dart run build_runner build
fvm flutter run
```

Production builds use `https://medicalbox.outoftokens.ai/api`. Internal builds
must inject both the staging API URL and access key:

```bash
fvm flutter run \
  --dart-define=MEDICAL_BOX_API_BASE_URL=https://staging.medicalbox.outoftokens.ai/api \
  --dart-define=MEDICAL_BOX_STAGING_ACCESS_KEY=replace-me
```

Provider console credentials and platform files are intentionally not committed.
Follow `docs/auth-provider-setup.md` before testing social login.

Closed-beta evidence and the external legal-review checklist are maintained in
`docs/closed-beta-release-evidence.md` and `docs/legal-review-packet.md`.

## Verification

```bash
make backend-check
make flutter-check
make prototype-check
```

Railway apply, DNS mutation, public-data API key provisioning, `pg_trgm`
activation, backup policy changes, and legal approval remain explicit
approval-gated release actions.
