import base64
import subprocess
from contextlib import contextmanager
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import pytest

from medical_box_api.backup import service
from medical_box_api.backup.config import BackupSettings
from medical_box_api.backup.manifest import BackupManifest, EncryptionMetadata
from medical_box_api.backup.service import (
    DatabaseSnapshot,
    create_backup,
    parse_manifest,
    prune_backups,
    require_disposable_restore_target,
    require_expected_backup_tables,
    retention_backup_ids,
)
from medical_box_api.backup.store import LocalBackupStore, S3BackupStore

HMAC_KEY = b"manifest-test-key-with-at-least-32-bytes"
HMAC_KEY_BASE64 = base64.b64encode(HMAC_KEY).decode()
FINGERPRINT = "0123456789ABCDEF0123456789ABCDEF01234567"


def backup_settings(tmp_path: Path) -> BackupSettings:
    return BackupSettings(
        app_env="test",
        database_url="postgresql://backup:secret@source:5432/medical_box",
        backup_store="local",
        backup_local_directory=tmp_path,
        backup_manifest_hmac_key_base64=HMAC_KEY_BASE64,
        backup_gpg_public_key_base64=base64.b64encode(b"public-key").decode(),
        backup_gpg_recipient=FINGERPRINT,
    )


def manifest_for(created_at: datetime, suffix: str) -> BackupManifest:
    backup_id = f"{created_at:%Y%m%dT%H%M%SZ}-{suffix:0>12}"
    root = f"medical-box/production/{backup_id}"
    manifest = BackupManifest(
        backup_id=backup_id,
        created_at=created_at,
        completed_at=created_at,
        object_key=f"{root}.dump.gpg",
        manifest_key=f"{root}.manifest.json",
        source_database_name="medical_box",
        postgres_server_version="18.4",
        pg_dump_version="pg_dump (PostgreSQL) 18.4",
        alembic_version="20260726_0004",
        table_counts={"users": 1},
        plaintext_size=100,
        plaintext_sha256="a" * 64,
        encrypted_size=120,
        encrypted_sha256="b" * 64,
        encryption=EncryptionMetadata(recipient_fingerprint=FINGERPRINT),
    )
    manifest.sign(HMAC_KEY)
    return manifest


def test_production_requires_durable_store(tmp_path: Path) -> None:
    with pytest.raises(ValueError, match="Production backups must use"):
        BackupSettings(
            app_env="production",
            database_url="postgresql://backup:secret@source:5432/medical_box",
            backup_store="local",
            backup_local_directory=tmp_path,
            backup_manifest_hmac_key_base64=HMAC_KEY_BASE64,
        )


def test_manifest_signature_detects_tampering() -> None:
    manifest = manifest_for(datetime(2026, 7, 28, tzinfo=UTC), "1")
    parsed = parse_manifest(manifest.signed_bytes(), hmac_key=HMAC_KEY)
    assert parsed.backup_id == manifest.backup_id

    tampered = parsed.model_copy(update={"encrypted_size": 121})
    with pytest.raises(ValueError, match="HMAC verification failed"):
        parse_manifest(tampered.signed_bytes(), hmac_key=HMAC_KEY)


def test_retention_is_union_of_daily_weekly_and_monthly_points() -> None:
    manifests = [
        manifest_for(datetime(2026, 7, 28, tzinfo=UTC), "1"),
        manifest_for(datetime(2026, 7, 27, tzinfo=UTC), "2"),
        manifest_for(datetime(2026, 7, 20, tzinfo=UTC), "3"),
        manifest_for(datetime(2026, 7, 13, tzinfo=UTC), "4"),
        manifest_for(datetime(2026, 6, 30, tzinfo=UTC), "5"),
        manifest_for(datetime(2026, 5, 31, tzinfo=UTC), "6"),
    ]

    kept = retention_backup_ids(manifests, daily=2, weekly=2, monthly=2)

    assert kept == {
        manifests[0].backup_id,
        manifests[1].backup_id,
        manifests[2].backup_id,
        manifests[4].backup_id,
    }


def test_daily_retention_uses_distinct_utc_dates() -> None:
    newest = manifest_for(datetime(2026, 7, 28, 20, tzinfo=UTC), "1")
    earlier_manual = manifest_for(datetime(2026, 7, 28, 8, tzinfo=UTC), "2")
    previous_day = manifest_for(datetime(2026, 7, 27, 20, tzinfo=UTC), "3")

    kept = retention_backup_ids(
        [earlier_manual, previous_day, newest],
        daily=2,
        weekly=1,
        monthly=1,
    )

    assert newest.backup_id in kept
    assert previous_day.backup_id in kept
    assert earlier_manual.backup_id not in kept


def test_prune_backups_deletes_expired_object_and_manifest_pairs(
    tmp_path: Path,
) -> None:
    store = LocalBackupStore(tmp_path)
    newest = manifest_for(datetime(2026, 7, 28, 20, tzinfo=UTC), "1")
    earlier_manual = manifest_for(datetime(2026, 7, 28, 8, tzinfo=UTC), "2")
    previous_day = manifest_for(datetime(2026, 7, 27, 20, tzinfo=UTC), "3")
    for manifest in (newest, earlier_manual, previous_day):
        store.put_bytes(
            manifest.object_key,
            b"encrypted",
            content_type="application/octet-stream",
            metadata={},
        )
        store.put_bytes(
            manifest.manifest_key,
            manifest.signed_bytes(),
            content_type="application/json",
            metadata={},
        )

    deleted = prune_backups(
        store,
        prefix="medical-box/production",
        hmac_key=HMAC_KEY,
        daily=2,
        weekly=1,
        monthly=1,
    )

    assert deleted == tuple(
        sorted([earlier_manual.object_key, earlier_manual.manifest_key])
    )
    remaining = {item.key for item in store.list_objects("medical-box/production")}
    assert remaining == {
        newest.object_key,
        newest.manifest_key,
        previous_day.object_key,
        previous_day.manifest_key,
    }


def test_s3_store_rejects_partial_delete_success(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    class PartialDeleteClient:
        def delete_objects(self, **kwargs: Any) -> dict[str, Any]:
            del kwargs
            return {
                "Deleted": [{"Key": "medical-box/production/first"}],
                "Errors": [
                    {
                        "Key": "medical-box/production/second",
                        "Code": "AccessDenied",
                        "Message": "denied",
                    }
                ],
            }

    client = PartialDeleteClient()
    monkeypatch.setattr(
        "medical_box_api.backup.store.boto3.client",
        lambda *args, **kwargs: client,
    )
    store = S3BackupStore(
        endpoint_url="https://storage.example.test",
        access_key_id="access",
        secret_access_key="secret",
        bucket_name="backups",
        region="auto",
        addressing_style="path",
    )

    with pytest.raises(
        RuntimeError,
        match=r"medical-box/production/second \(AccessDenied\)",
    ):
        store.delete_objects(
            [
                "medical-box/production/first",
                "medical-box/production/second",
            ]
        )


def test_local_store_rejects_path_escape(tmp_path: Path) -> None:
    store = LocalBackupStore(tmp_path)
    with pytest.raises(ValueError, match="escapes"):
        store.put_bytes(
            "../outside",
            b"unsafe",
            content_type="application/octet-stream",
            metadata={},
        )


def test_restore_requires_explicit_disposable_target() -> None:
    source = "postgresql://backup:secret@source:5432/medical_box"
    target = "postgresql://backup:secret@restore:5432/medical_box"

    with pytest.raises(RuntimeError, match="requires BACKUP_RESTORE_CONFIRMATION"):
        require_disposable_restore_target(
            source_database_url=source,
            target_database_url=target,
            confirmation=None,
        )
    with pytest.raises(RuntimeError, match="production backup source"):
        require_disposable_restore_target(
            source_database_url=source,
            target_database_url=source,
            confirmation=service.RESTORE_CONFIRMATION,
        )


def test_backup_table_inventory_fails_closed_on_schema_drift() -> None:
    expected = set(service.BACKUP_TABLES) | {"alembic_version"}
    require_expected_backup_tables(expected)

    with pytest.raises(RuntimeError, match="unexpected=future_table"):
        require_expected_backup_tables(expected | {"future_table"})
    with pytest.raises(RuntimeError, match="missing=users"):
        require_expected_backup_tables(expected - {"users"})


def test_gpg_key_import_uses_stdin_without_plaintext_file(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    calls: list[dict[str, Any]] = []

    def fake_run(command: list[str], **kwargs: Any) -> subprocess.CompletedProcess[bytes]:
        calls.append({"command": command, **kwargs})
        return subprocess.CompletedProcess(command, 0, stdout=b"", stderr=b"")

    monkeypatch.setattr(service.subprocess, "run", fake_run)
    gpg_home = tmp_path / "gpg"

    service.import_gpg_key(
        executable="gpg",
        home=gpg_home,
        encoded_key=base64.b64encode(b"private-key").decode(),
        expected_fingerprint=None,
    )

    assert calls[0]["input"] == b"private-key"
    assert calls[0]["command"][-1] == "--import"
    assert not (gpg_home / "key.asc").exists()


def test_gpg_passphrase_uses_stdin_without_plaintext_file(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    calls: list[dict[str, Any]] = []

    def fake_run(command: list[str], **kwargs: Any) -> subprocess.CompletedProcess[bytes]:
        calls.append({"command": command, **kwargs})
        return subprocess.CompletedProcess(command, 0, stdout=b"", stderr=b"")

    monkeypatch.setattr(service, "import_gpg_key", lambda **kwargs: None)
    monkeypatch.setattr(service.subprocess, "run", fake_run)
    gpg_home = tmp_path / "gpg"
    gpg_home.mkdir()

    service.decrypt_dump(
        executable="gpg",
        private_key_base64=base64.b64encode(b"private-key").decode(),
        passphrase="test-passphrase",
        source=tmp_path / "backup.dump.gpg",
        destination=tmp_path / "backup.dump",
        gpg_home=gpg_home,
        expected_fingerprint=FINGERPRINT,
    )

    assert calls[0]["input"] == b"test-passphrase\n"
    assert "--passphrase-fd" in calls[0]["command"]
    assert "--passphrase-file" not in calls[0]["command"]
    assert not (gpg_home / "passphrase").exists()


def test_create_backup_uploads_signed_pair_and_prunes_after_success(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    settings = backup_settings(tmp_path)
    store = LocalBackupStore(tmp_path)
    snapshot = DatabaseSnapshot(
        snapshot_id="00000003-0000001B-1",
        database_name="medical_box",
        postgres_version="18.4",
        alembic_version="20260726_0004",
        table_counts={"users": 1},
    )

    @contextmanager
    def fake_context(*args: Any, **kwargs: Any) -> Any:
        del args, kwargs
        yield

    @contextmanager
    def fake_snapshot(*args: Any, **kwargs: Any) -> Any:
        del args, kwargs
        yield snapshot

    def fake_dump(**kwargs: Any) -> None:
        kwargs["destination"].write_bytes(b"plain-dump")

    def fake_encrypt(**kwargs: Any) -> None:
        kwargs["destination"].write_bytes(b"encrypted-dump")

    monkeypatch.setattr(service, "backup_advisory_lock", fake_context)
    monkeypatch.setattr(service, "exported_database_snapshot", fake_snapshot)
    monkeypatch.setattr(service, "run_pg_dump", fake_dump)
    monkeypatch.setattr(service, "encrypt_dump", fake_encrypt)
    monkeypatch.setattr(service, "command_version", lambda executable: f"{executable} 18.4")

    result = create_backup(
        settings,
        store=store,
        now=datetime(2026, 7, 28, 20, 30, tzinfo=UTC),
    )

    assert store.get_bytes(result.manifest.object_key) == b"encrypted-dump"
    parsed = parse_manifest(
        store.get_bytes(result.manifest.manifest_key),
        hmac_key=HMAC_KEY,
    )
    assert parsed.backup_id == result.manifest.backup_id
    assert parsed.table_counts == {"users": 1}


def test_create_backup_removes_uploaded_pair_when_manifest_publish_fails(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    settings = backup_settings(tmp_path)
    store = LocalBackupStore(tmp_path)
    snapshot = DatabaseSnapshot(
        snapshot_id="00000003-0000001B-1",
        database_name="medical_box",
        postgres_version="18.4",
        alembic_version="20260726_0004",
        table_counts={"users": 1},
    )

    @contextmanager
    def fake_context(*args: Any, **kwargs: Any) -> Any:
        del args, kwargs
        yield

    @contextmanager
    def fake_snapshot(*args: Any, **kwargs: Any) -> Any:
        del args, kwargs
        yield snapshot

    def fake_dump(**kwargs: Any) -> None:
        kwargs["destination"].write_bytes(b"plain-dump")

    def fake_encrypt(**kwargs: Any) -> None:
        kwargs["destination"].write_bytes(b"encrypted-dump")

    original_put_bytes = store.put_bytes

    def fail_manifest_publish(
        key: str,
        content: bytes,
        *,
        content_type: str,
        metadata: dict[str, str],
    ) -> None:
        original_put_bytes(
            key,
            content,
            content_type=content_type,
            metadata=metadata,
        )
        raise RuntimeError("manifest publish failed")

    monkeypatch.setattr(service, "backup_advisory_lock", fake_context)
    monkeypatch.setattr(service, "exported_database_snapshot", fake_snapshot)
    monkeypatch.setattr(service, "run_pg_dump", fake_dump)
    monkeypatch.setattr(service, "encrypt_dump", fake_encrypt)
    monkeypatch.setattr(service, "command_version", lambda executable: f"{executable} 18.4")
    monkeypatch.setattr(store, "put_bytes", fail_manifest_publish)

    with pytest.raises(RuntimeError, match="manifest publish failed"):
        create_backup(
            settings,
            store=store,
            now=datetime(2026, 7, 28, 20, 30, tzinfo=UTC),
        )

    assert store.list_objects("medical-box/production") == []
