import json

import typer

from .config import BackupSettings
from .service import create_backup, verify_backup

app = typer.Typer(no_args_is_help=True, add_completion=False)


@app.command("create")
def create() -> None:
    """Create, encrypt, upload, and prune a production backup."""
    result = create_backup(BackupSettings())
    typer.echo(
        json.dumps(
            {
                "status": "succeeded",
                "backup_id": result.manifest.backup_id,
                "manifest_key": result.manifest.manifest_key,
                "encrypted_size": result.manifest.encrypted_size,
                "encrypted_sha256": result.manifest.encrypted_sha256,
                "deleted_objects": len(result.deleted_object_keys),
            },
            separators=(",", ":"),
            sort_keys=True,
        )
    )


@app.command("verify")
def verify(
    manifest_key: str | None = typer.Option(default=None),
    restore: bool = typer.Option(
        default=False,
        help="Restore into the explicitly confirmed disposable target.",
    ),
) -> None:
    """Verify encryption, hashes, archive structure, and optional restore."""
    result = verify_backup(
        BackupSettings(),
        manifest_key=manifest_key,
        restore=restore,
    )
    typer.echo(
        json.dumps(
            {
                "status": "succeeded",
                "backup_id": result.manifest.backup_id,
                "archive_listed": result.archive_listed,
                "restored": result.restored,
            },
            separators=(",", ":"),
            sort_keys=True,
        )
    )
