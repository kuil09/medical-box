.PHONY: backend-check flutter-check prototype-check store-check openapi

backend-check:
	cd services/backend && .venv/bin/ruff check . && .venv/bin/mypy && .venv/bin/pytest

flutter-check:
	cd apps/mobile && fvm flutter analyze && fvm flutter test

prototype-check:
	cd design/prototype && npm run check:runtime && npm run build

store-check:
	.github/scripts/validate-store-metadata.sh

openapi:
	cd services/backend && PYTHONPATH=src .venv/bin/python scripts/export_openapi.py
