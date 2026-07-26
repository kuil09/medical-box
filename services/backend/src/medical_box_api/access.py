import uuid

import typer

from .db import SessionLocal
from .models import User
from .security import CATALOG_READ_PERMISSION

app = typer.Typer(help="Manage explicit server-side account permissions.")


def _set_catalog_access(user_id: uuid.UUID, *, enabled: bool) -> None:
    with SessionLocal() as db:
        user = db.get(User, user_id)
        if user is None:
            raise typer.BadParameter(f"User {user_id} does not exist.", param_hint="user_id")
        user.catalog_read_enabled = enabled
        db.commit()
    state = "granted" if enabled else "revoked"
    typer.echo(f"{CATALOG_READ_PERMISSION} {state} for user {user_id}.")


@app.command()
def grant(user_id: uuid.UUID) -> None:
    """Grant catalog read access to one exact account ID."""
    _set_catalog_access(user_id, enabled=True)


@app.command()
def revoke(user_id: uuid.UUID) -> None:
    """Revoke catalog read access from one exact account ID."""
    _set_catalog_access(user_id, enabled=False)
