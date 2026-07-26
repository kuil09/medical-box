import json
from pathlib import Path

from medical_box_api.main import app


def main() -> None:
    destination = Path(__file__).resolve().parents[1] / "openapi" / "openapi.json"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(
        json.dumps(app.openapi(), ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
