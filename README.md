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
those entities. Account creation and sign-in are required before entering the
organizer. Official catalog search, detail, and DUR requests additionally
require the server-side `catalog:read` permission.

Free accounts may eventually show non-personalized banner ads only in explicitly
allowlisted locations. The advertising adapter cannot receive account,
household, medicine, search, reminder, or sharing data and is disabled until an
advertising provider and its disclosures are approved. See
`docs/monetization-decisions.md`.

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

All distributed builds use `https://medicalbox.outoftokens.ai/api`. Override
the base URL only for a locally running backend:

```bash
fvm flutter run \
  --dart-define=MEDICAL_BOX_API_BASE_URL=http://127.0.0.1:8000/api
```

Provider console credentials and platform files are intentionally not committed.
Follow `docs/auth-provider-setup.md` before testing social login.

Closed-beta evidence and the external legal-review checklist are maintained in
`docs/closed-beta-release-evidence.md` and `docs/legal-review-packet.md`.

## Security

Report vulnerabilities through GitHub private vulnerability reporting as
described in `SECURITY.md`. Never place credentials, production data, household
records, or signing material in a public issue.

Runtime secrets belong in Railway variables, GitHub environment secrets, or a
local ignored `.env` file. The repository intentionally contains public client
identifiers, API contracts, domains, and source attribution, but no production
database or private signing material.

## Contributing

See `CONTRIBUTING.md` for the privacy, medical-safety, testing, and language
requirements that apply to contributions.

## License and data

Original source code and documentation are available under the Apache License
2.0. Product Design template assets, software dependencies, and official Korean
medicine data retain separate terms described in `THIRD_PARTY_NOTICES.md`.
Production catalog records and medicine image binaries are not distributed in
this repository.

## Verification

```bash
make backend-check
make flutter-check
make prototype-check
```

Railway apply, DNS mutation, public-data API key provisioning, `pg_trgm`
activation, backup policy changes, and legal approval remain explicit
approval-gated release actions.
