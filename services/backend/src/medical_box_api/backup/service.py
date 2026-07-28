import base64
import hashlib
import os
import re
import secrets
import subprocess
import tempfile
from collections.abc import Iterator
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, unquote, urlsplit

import psycopg
from psycopg import sql

from ..catalog.locking import CATALOG_MUTATION_LOCK_KEY
from .config import BackupSettings
from .manifest import (
    BackupManifest,
    EncryptionMetadata,
    decode_manifest_hmac_key,
)
from .store import BackupStore, LocalBackupStore, S3BackupStore

BACKUP_TABLES = (
    "users",
    "auth_identities",
    "refresh_sessions",
    "terms_acceptances",
    "source_registry",
    "sync_runs",
    "sync_checkpoints",
    "source_records",
    "drug_products",
    "drug_ingredients",
    "drug_consumer_info",
    "drug_identification",
    "drug_identification_variants",
    "drug_codes",
    "drug_prices",
    "dur_rules",
    "drug_status_events",
)
BACKUP_LOCK_KEY = int.from_bytes(
    hashlib.sha256(b"medical-box:production-backup").digest()[:8],
    "big",
) & 0x7FFF_FFFF_FFFF_FFFF
BACKUP_ID_PATTERN = re.compile(r"^\d{8}T\d{6}Z-[0-9a-f]{12}$")
ORPHAN_OBJECT_GRACE = timedelta(hours=6)
RESTORE_CONFIRMATION = "restore-disposable-database"


@dataclass(frozen=True)
class DatabaseSnapshot:
    snapshot_id: str
    database_name: str
    postgres_version: str
    alembic_version: str
    table_counts: dict[str, int]


@dataclass(frozen=True)
class BackupResult:
    manifest: BackupManifest
    deleted_object_keys: tuple[str, ...]


@dataclass(frozen=True)
class VerificationResult:
    manifest: BackupManifest
    archive_listed: bool
    restored: bool


def require_expected_backup_tables(table_names: set[str]) -> None:
    expected = set(BACKUP_TABLES) | {"alembic_version"}
    missing = sorted(expected - table_names)
    unexpected = sorted(table_names - expected)
    if missing or unexpected:
        details = []
        if missing:
            details.append(f"missing={','.join(missing)}")
        if unexpected:
            details.append(f"unexpected={','.join(unexpected)}")
        raise RuntimeError(
            "Production backup table inventory does not match the declared schema: "
            + "; ".join(details)
        )


def sha256_file(path: Path, *, chunk_size: int = 1024 * 1024) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        while chunk := source.read(chunk_size):
            digest.update(chunk)
    return digest.hexdigest()


def _secret_value(value: Any) -> str:
    return str(value.get_secret_value())


def build_store(settings: BackupSettings) -> BackupStore:
    if settings.backup_store == "local":
        assert settings.backup_local_directory is not None
        return LocalBackupStore(settings.backup_local_directory)
    assert settings.aws_endpoint_url is not None
    assert settings.aws_access_key_id is not None
    assert settings.aws_secret_access_key is not None
    assert settings.aws_s3_bucket_name is not None
    return S3BackupStore(
        endpoint_url=settings.aws_endpoint_url,
        access_key_id=_secret_value(settings.aws_access_key_id),
        secret_access_key=_secret_value(settings.aws_secret_access_key),
        bucket_name=settings.aws_s3_bucket_name,
        region=settings.aws_default_region,
        addressing_style=settings.aws_s3_addressing_style,
    )


def _database_url(value: Any) -> str:
    url = _secret_value(value)
    if url.startswith("postgresql+psycopg://"):
        return url.replace("postgresql+psycopg://", "postgresql://", 1)
    if url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql://", 1)
    return url


def libpq_environment(database_url: str) -> dict[str, str]:
    parsed = urlsplit(database_url)
    if parsed.scheme not in {"postgres", "postgresql"}:
        raise ValueError("Backup database URL must use PostgreSQL.")
    if parsed.hostname is None or parsed.username is None:
        raise ValueError("Backup database URL must include a host and user.")
    database_name = unquote(parsed.path.removeprefix("/"))
    if not database_name:
        raise ValueError("Backup database URL must include a database name.")
    environment = dict(os.environ)
    environment.update(
        {
            "PGHOST": parsed.hostname,
            "PGPORT": str(parsed.port or 5432),
            "PGUSER": unquote(parsed.username),
            "PGDATABASE": database_name,
        }
    )
    if parsed.password is not None:
        environment["PGPASSWORD"] = unquote(parsed.password)
    query = parse_qs(parsed.query)
    if ssl_mode := query.get("sslmode"):
        environment["PGSSLMODE"] = ssl_mode[-1]
    return environment


@contextmanager
def backup_advisory_lock(database_url: str) -> Iterator[None]:
    with psycopg.connect(database_url, autocommit=True) as connection:
        backup_acquired = connection.execute(
            "SELECT pg_try_advisory_lock(%s)",
            (BACKUP_LOCK_KEY,),
        ).fetchone()
        if backup_acquired is None or not backup_acquired[0]:
            raise RuntimeError("Another production backup already owns the advisory lock.")
        catalog_acquired = False
        try:
            catalog_row = connection.execute(
                "SELECT pg_try_advisory_lock(%s)",
                (CATALOG_MUTATION_LOCK_KEY,),
            ).fetchone()
            catalog_acquired = catalog_row is not None and bool(catalog_row[0])
            if not catalog_acquired:
                raise RuntimeError(
                    "Catalog synchronization is active; production backup was not started."
                )
            yield
        finally:
            if catalog_acquired:
                connection.execute(
                    "SELECT pg_advisory_unlock(%s)",
                    (CATALOG_MUTATION_LOCK_KEY,),
                )
            connection.execute("SELECT pg_advisory_unlock(%s)", (BACKUP_LOCK_KEY,))


@contextmanager
def exported_database_snapshot(database_url: str) -> Iterator[DatabaseSnapshot]:
    with psycopg.connect(database_url, autocommit=True) as connection:
        transaction_started = False
        try:
            connection.execute(
                "BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY"
            )
            transaction_started = True
            snapshot_row = connection.execute("SELECT pg_export_snapshot()").fetchone()
            identity_row = connection.execute(
                "SELECT current_database(), current_setting('server_version')"
            ).fetchone()
            alembic_row = connection.execute(
                "SELECT version_num FROM alembic_version"
            ).fetchone()
            if snapshot_row is None or identity_row is None or alembic_row is None:
                raise RuntimeError("Production database snapshot metadata is incomplete.")
            table_rows = connection.execute(
                """
                SELECT tablename
                FROM pg_catalog.pg_tables
                WHERE schemaname = 'public'
                """
            ).fetchall()
            require_expected_backup_tables({str(row[0]) for row in table_rows})
            table_counts: dict[str, int] = {}
            for table_name in BACKUP_TABLES:
                count_row = connection.execute(
                    sql.SQL("SELECT count(*) FROM {}").format(sql.Identifier(table_name))
                ).fetchone()
                if count_row is None:
                    raise RuntimeError(f"Could not count backup table {table_name}.")
                table_counts[table_name] = int(count_row[0])
            yield DatabaseSnapshot(
                snapshot_id=str(snapshot_row[0]),
                database_name=str(identity_row[0]),
                postgres_version=str(identity_row[1]),
                alembic_version=str(alembic_row[0]),
                table_counts=table_counts,
            )
        finally:
            if transaction_started:
                connection.execute("ROLLBACK")


def command_version(executable: str) -> str:
    result = subprocess.run(
        [executable, "--version"],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def run_pg_dump(
    *,
    executable: str,
    database_url: str,
    snapshot_id: str,
    destination: Path,
) -> None:
    result = subprocess.run(
        [
            executable,
            "--format=custom",
            "--compress=zstd:6",
            "--no-owner",
            "--no-privileges",
            f"--snapshot={snapshot_id}",
            f"--file={destination}",
        ],
        env=libpq_environment(database_url),
        check=False,
        capture_output=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"pg_dump failed with exit code {result.returncode}.")


def _decode_key(encoded: str) -> bytes:
    try:
        return base64.b64decode(encoded, validate=True)
    except ValueError as exc:
        raise ValueError("The configured GPG key is not valid Base64.") from exc


def _gpg_fingerprints(executable: str, home: Path) -> set[str]:
    result = subprocess.run(
        [
            executable,
            "--homedir",
            str(home),
            "--batch",
            "--with-colons",
            "--fingerprint",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return {
        fields[9].upper()
        for line in result.stdout.splitlines()
        if (fields := line.split(":"))[0] == "fpr" and len(fields) > 9
    }


def import_gpg_key(
    *,
    executable: str,
    home: Path,
    encoded_key: str,
    expected_fingerprint: str | None,
) -> None:
    home.mkdir(mode=0o700)
    result = subprocess.run(
        [
            executable,
            "--homedir",
            str(home),
            "--batch",
            "--import",
        ],
        input=_decode_key(encoded_key),
        check=False,
        capture_output=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"GPG key import failed with exit code {result.returncode}.")
    if expected_fingerprint is not None and expected_fingerprint not in _gpg_fingerprints(
        executable, home
    ):
        raise RuntimeError("Imported GPG key does not match BACKUP_GPG_RECIPIENT.")


def encrypt_dump(
    *,
    executable: str,
    public_key_base64: str,
    recipient_fingerprint: str,
    source: Path,
    destination: Path,
    gpg_home: Path,
) -> None:
    import_gpg_key(
        executable=executable,
        home=gpg_home,
        encoded_key=public_key_base64,
        expected_fingerprint=recipient_fingerprint,
    )
    result = subprocess.run(
        [
            executable,
            "--homedir",
            str(gpg_home),
            "--batch",
            "--yes",
            "--trust-model",
            "always",
            "--compress-algo",
            "none",
            "--recipient",
            recipient_fingerprint,
            "--output",
            str(destination),
            "--encrypt",
            str(source),
        ],
        check=False,
        capture_output=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"GPG encryption failed with exit code {result.returncode}.")


def decrypt_dump(
    *,
    executable: str,
    private_key_base64: str,
    passphrase: str | None,
    source: Path,
    destination: Path,
    gpg_home: Path,
    expected_fingerprint: str,
) -> None:
    import_gpg_key(
        executable=executable,
        home=gpg_home,
        encoded_key=private_key_base64,
        expected_fingerprint=expected_fingerprint,
    )
    command = [
        executable,
        "--homedir",
        str(gpg_home),
        "--batch",
        "--yes",
        "--output",
        str(destination),
    ]
    passphrase_input: bytes | None = None
    if passphrase is not None:
        command.extend(
            [
                "--pinentry-mode",
                "loopback",
                "--passphrase-fd",
                "0",
            ]
        )
        passphrase_input = f"{passphrase}\n".encode()
    command.extend(["--decrypt", str(source)])
    result = subprocess.run(
        command,
        input=passphrase_input,
        check=False,
        capture_output=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"GPG decryption failed with exit code {result.returncode}.")


def _backup_keys(prefix: str, backup_id: str) -> tuple[str, str]:
    if not BACKUP_ID_PATTERN.fullmatch(backup_id):
        raise ValueError("Backup ID has an invalid format.")
    root = f"{prefix}/{backup_id}"
    return f"{root}.dump.gpg", f"{root}.manifest.json"


def _manifest_hmac_key(settings: BackupSettings) -> bytes:
    return decode_manifest_hmac_key(
        _secret_value(settings.backup_manifest_hmac_key_base64)
    )


def parse_manifest(content: bytes, *, hmac_key: bytes) -> BackupManifest:
    manifest = BackupManifest.model_validate_json(content)
    manifest.verify_signature(hmac_key)
    expected_object_key, expected_manifest_key = _backup_keys(
        manifest.manifest_key.rsplit("/", 1)[0],
        manifest.backup_id,
    )
    if manifest.object_key != expected_object_key:
        raise ValueError("Backup manifest object key does not match its backup ID.")
    if manifest.manifest_key != expected_manifest_key:
        raise ValueError("Backup manifest key does not match its backup ID.")
    return manifest


def retention_backup_ids(
    manifests: list[BackupManifest],
    *,
    daily: int,
    weekly: int,
    monthly: int,
) -> set[str]:
    ordered = sorted(manifests, key=lambda item: item.created_at, reverse=True)
    keep: set[str] = set()

    seen_days: set[date] = set()
    for manifest in ordered:
        created_at = manifest.created_at.astimezone(UTC)
        day = created_at.date()
        if day in seen_days:
            continue
        seen_days.add(day)
        if len(seen_days) <= daily:
            keep.add(manifest.backup_id)

    seen_weeks: set[tuple[int, int]] = set()
    for manifest in ordered:
        created_at = manifest.created_at.astimezone(UTC)
        calendar = created_at.isocalendar()
        week = (calendar.year, calendar.week)
        if week in seen_weeks:
            continue
        seen_weeks.add(week)
        if len(seen_weeks) <= weekly:
            keep.add(manifest.backup_id)

    seen_months: set[tuple[int, int]] = set()
    for manifest in ordered:
        created_at = manifest.created_at.astimezone(UTC)
        month = (created_at.year, created_at.month)
        if month in seen_months:
            continue
        seen_months.add(month)
        if len(seen_months) <= monthly:
            keep.add(manifest.backup_id)
    return keep


def load_valid_manifests(
    store: BackupStore,
    *,
    prefix: str,
    hmac_key: bytes,
) -> list[BackupManifest]:
    objects = store.list_objects(prefix)
    objects_by_key = {item.key: item for item in objects}
    manifests: list[BackupManifest] = []
    for item in objects:
        if not item.key.endswith(".manifest.json"):
            continue
        try:
            manifest = parse_manifest(store.get_bytes(item.key), hmac_key=hmac_key)
        except (ValueError, OSError):
            continue
        encrypted_object = objects_by_key.get(manifest.object_key)
        if (
            manifest.manifest_key != item.key
            or not manifest.manifest_key.startswith(f"{prefix}/")
            or encrypted_object is None
            or encrypted_object.size != manifest.encrypted_size
            or store.object_sha256(manifest.object_key)
            != manifest.encrypted_sha256
        ):
            continue
        manifests.append(manifest)
    return manifests


def prune_backups(
    store: BackupStore,
    *,
    prefix: str,
    hmac_key: bytes,
    daily: int,
    weekly: int,
    monthly: int,
    now: datetime | None = None,
) -> tuple[str, ...]:
    manifests = load_valid_manifests(store, prefix=prefix, hmac_key=hmac_key)
    keep = retention_backup_ids(
        manifests,
        daily=daily,
        weekly=weekly,
        monthly=monthly,
    )
    deleted: set[str] = set()
    for manifest in manifests:
        if manifest.backup_id in keep:
            continue
        deleted.update([manifest.object_key, manifest.manifest_key])

    valid_object_keys = {manifest.object_key for manifest in manifests}
    cutoff = (now or datetime.now(UTC)).astimezone(UTC) - ORPHAN_OBJECT_GRACE
    object_prefix = f"{prefix}/"
    object_suffix = ".dump.gpg"
    for item in store.list_objects(prefix):
        if (
            item.key in valid_object_keys
            or not item.key.startswith(object_prefix)
            or not item.key.endswith(object_suffix)
            or item.last_modified.astimezone(UTC) > cutoff
        ):
            continue
        backup_id = item.key[len(object_prefix) : -len(object_suffix)]
        if BACKUP_ID_PATTERN.fullmatch(backup_id):
            deleted.add(item.key)

    ordered_deleted = tuple(sorted(deleted))
    store.delete_objects(ordered_deleted)
    return ordered_deleted


def create_backup(
    settings: BackupSettings,
    *,
    store: BackupStore | None = None,
    now: datetime | None = None,
) -> BackupResult:
    store = store or build_store(settings)
    created_at = (now or datetime.now(UTC)).astimezone(UTC)
    backup_id = f"{created_at:%Y%m%dT%H%M%SZ}-{secrets.token_hex(6)}"
    object_key, manifest_key = _backup_keys(settings.backup_prefix, backup_id)
    database_url = _database_url(settings.database_url)
    hmac_key = _manifest_hmac_key(settings)
    if settings.backup_gpg_public_key_base64 is None:
        raise ValueError("BACKUP_GPG_PUBLIC_KEY_BASE64 is required to create a backup.")
    if settings.backup_gpg_recipient is None:
        raise ValueError("BACKUP_GPG_RECIPIENT is required to create a backup.")

    with backup_advisory_lock(database_url):
        with tempfile.TemporaryDirectory(prefix="medical-box-backup-") as directory:
            working = Path(directory)
            working.chmod(0o700)
            plain_dump = working / f"{backup_id}.dump"
            encrypted_dump = working / f"{backup_id}.dump.gpg"
            gpg_home = working / "gnupg"
            with exported_database_snapshot(database_url) as snapshot:
                run_pg_dump(
                    executable=settings.backup_pg_dump_path,
                    database_url=database_url,
                    snapshot_id=snapshot.snapshot_id,
                    destination=plain_dump,
                )
            plaintext_size = plain_dump.stat().st_size
            plaintext_sha256 = sha256_file(plain_dump)
            encrypt_dump(
                executable=settings.backup_gpg_path,
                public_key_base64=_secret_value(
                    settings.backup_gpg_public_key_base64
                ),
                recipient_fingerprint=settings.backup_gpg_recipient,
                source=plain_dump,
                destination=encrypted_dump,
                gpg_home=gpg_home,
            )
            plain_dump.unlink(missing_ok=True)
            encrypted_size = encrypted_dump.stat().st_size
            encrypted_sha256 = sha256_file(encrypted_dump)
            manifest = BackupManifest(
                backup_id=backup_id,
                created_at=created_at,
                completed_at=datetime.now(UTC),
                object_key=object_key,
                manifest_key=manifest_key,
                source_database_name=snapshot.database_name,
                postgres_server_version=snapshot.postgres_version,
                pg_dump_version=command_version(settings.backup_pg_dump_path),
                alembic_version=snapshot.alembic_version,
                table_counts=snapshot.table_counts,
                plaintext_size=plaintext_size,
                plaintext_sha256=plaintext_sha256,
                encrypted_size=encrypted_size,
                encrypted_sha256=encrypted_sha256,
                encryption=EncryptionMetadata(
                    recipient_fingerprint=settings.backup_gpg_recipient,
                ),
            )
            manifest.sign(hmac_key)
            store.put_file(
                object_key,
                encrypted_dump,
                content_type="application/octet-stream",
                metadata={
                    "backup-id": backup_id,
                    "sha256": encrypted_sha256,
                    "format": "openpgp",
                },
            )
            try:
                uploaded_copy = working / f"{backup_id}.uploaded.dump.gpg"
                store.get_file(object_key, uploaded_copy)
                if (
                    uploaded_copy.stat().st_size != encrypted_size
                    or sha256_file(uploaded_copy) != encrypted_sha256
                ):
                    raise RuntimeError(
                        "Uploaded encrypted backup failed remote read-after-write "
                        "verification."
                    )
                uploaded_copy.unlink()
                store.put_bytes(
                    manifest_key,
                    manifest.signed_bytes(),
                    content_type="application/json",
                    metadata={"backup-id": backup_id, "format-version": "1"},
                )
            except Exception:
                store.delete_objects([object_key, manifest_key])
                raise

        deleted = prune_backups(
            store,
            prefix=settings.backup_prefix,
            hmac_key=hmac_key,
            daily=settings.backup_daily_retention,
            weekly=settings.backup_weekly_retention,
            monthly=settings.backup_monthly_retention,
            now=datetime.now(UTC),
        )
    return BackupResult(manifest=manifest, deleted_object_keys=deleted)


def latest_manifest(
    store: BackupStore,
    *,
    prefix: str,
    hmac_key: bytes,
) -> BackupManifest:
    manifests = load_valid_manifests(store, prefix=prefix, hmac_key=hmac_key)
    if not manifests:
        raise RuntimeError("No valid backup manifest is available.")
    return max(manifests, key=lambda item: item.created_at)


def _database_identity(database_url: str) -> tuple[str, int, str]:
    parsed = urlsplit(database_url)
    host = (parsed.hostname or "").casefold()
    if host in {"127.0.0.1", "::1", "localhost"}:
        host = "loopback"
    return (
        host,
        parsed.port or 5432,
        unquote(parsed.path.removeprefix("/")),
    )


def require_disposable_restore_target(
    *,
    source_database_url: str,
    target_database_url: str,
    confirmation: str | None,
    app_env: str,
    app_role: str,
) -> None:
    if confirmation != RESTORE_CONFIRMATION:
        raise RuntimeError(
            f"Restore requires BACKUP_RESTORE_CONFIRMATION={RESTORE_CONFIRMATION}."
        )
    if app_env != "test" or app_role != "backup_verify":
        raise RuntimeError(
            "Restore verification requires APP_ENV=test and APP_ROLE=backup_verify."
        )
    if _database_identity(source_database_url) == _database_identity(target_database_url):
        raise RuntimeError("Restore target is the production backup source.")
    target_host = urlsplit(target_database_url).hostname or ""
    disposable_host = target_host in {"127.0.0.1", "::1", "localhost"} or bool(
        re.fullmatch(
            r"medical-box-(?:backup-restore|production-restore-db)-\d+-\d+",
            target_host,
        )
    )
    if not disposable_host:
        raise RuntimeError("Restore target is not an approved disposable host.")
    if os.getenv("RAILWAY_ENVIRONMENT_NAME", "").casefold() == "production":
        raise RuntimeError("Restore verification may not run in the production environment.")


def _target_is_empty(database_url: str) -> bool:
    with psycopg.connect(database_url) as connection:
        row = connection.execute(
            """
            SELECT count(*)
            FROM pg_catalog.pg_class AS relation
            JOIN pg_catalog.pg_namespace AS namespace
              ON namespace.oid = relation.relnamespace
            WHERE namespace.nspname NOT LIKE 'pg_%'
              AND namespace.nspname <> 'information_schema'
              AND relation.relkind IN ('r', 'p', 'v', 'm', 'S', 'f')
            """
        ).fetchone()
        return row is not None and int(row[0]) == 0


def run_pg_restore(
    *,
    executable: str,
    database_url: str,
    source: Path,
    jobs: int,
) -> None:
    if not _target_is_empty(database_url):
        raise RuntimeError("Disposable restore target must have an empty public schema.")
    result = subprocess.run(
        [
            executable,
            "--exit-on-error",
            "--no-owner",
            "--no-privileges",
            f"--jobs={jobs}",
            "--dbname",
            urlsplit(database_url).path.removeprefix("/"),
            str(source),
        ],
        env=libpq_environment(database_url),
        check=False,
        capture_output=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"pg_restore failed with exit code {result.returncode}.")


def verify_restored_counts(database_url: str, manifest: BackupManifest) -> None:
    with psycopg.connect(database_url) as connection:
        version_row = connection.execute(
            "SELECT version_num FROM alembic_version"
        ).fetchone()
        if version_row is None or str(version_row[0]) != manifest.alembic_version:
            raise RuntimeError("Restored Alembic version does not match the manifest.")
        for table_name, expected_count in manifest.table_counts.items():
            count_row = connection.execute(
                sql.SQL("SELECT count(*) FROM {}").format(sql.Identifier(table_name))
            ).fetchone()
            if count_row is None or int(count_row[0]) != expected_count:
                raise RuntimeError(
                    f"Restored table count mismatch for {table_name}."
                )


def verify_backup(
    settings: BackupSettings,
    *,
    store: BackupStore | None = None,
    manifest_key: str | None = None,
    restore: bool = False,
) -> VerificationResult:
    store = store or build_store(settings)
    hmac_key = _manifest_hmac_key(settings)
    if manifest_key is None:
        manifest = latest_manifest(
            store,
            prefix=settings.backup_prefix,
            hmac_key=hmac_key,
        )
    else:
        manifest = parse_manifest(store.get_bytes(manifest_key), hmac_key=hmac_key)
    if settings.backup_gpg_private_key_base64 is None:
        raise ValueError("BACKUP_GPG_PRIVATE_KEY_BASE64 is required for verification.")

    with tempfile.TemporaryDirectory(prefix="medical-box-verify-") as directory:
        working = Path(directory)
        working.chmod(0o700)
        encrypted_dump = working / f"{manifest.backup_id}.dump.gpg"
        plain_dump = working / f"{manifest.backup_id}.dump"
        gpg_home = working / "gnupg"
        store.get_file(manifest.object_key, encrypted_dump)
        if encrypted_dump.stat().st_size != manifest.encrypted_size:
            raise RuntimeError("Encrypted backup size does not match the manifest.")
        if sha256_file(encrypted_dump) != manifest.encrypted_sha256:
            raise RuntimeError("Encrypted backup SHA-256 does not match the manifest.")
        decrypt_dump(
            executable=settings.backup_gpg_path,
            private_key_base64=_secret_value(
                settings.backup_gpg_private_key_base64
            ),
            passphrase=(
                _secret_value(settings.backup_gpg_passphrase)
                if settings.backup_gpg_passphrase is not None
                else None
            ),
            source=encrypted_dump,
            destination=plain_dump,
            gpg_home=gpg_home,
            expected_fingerprint=manifest.encryption.recipient_fingerprint,
        )
        if plain_dump.stat().st_size != manifest.plaintext_size:
            raise RuntimeError("Decrypted backup size does not match the manifest.")
        if sha256_file(plain_dump) != manifest.plaintext_sha256:
            raise RuntimeError("Decrypted backup SHA-256 does not match the manifest.")
        list_result = subprocess.run(
            [settings.backup_pg_restore_path, "--list", str(plain_dump)],
            check=False,
            capture_output=True,
        )
        if list_result.returncode != 0:
            raise RuntimeError(
                f"pg_restore archive listing failed with exit code {list_result.returncode}."
            )
        restored = False
        if restore:
            if settings.backup_restore_database_url is None:
                raise ValueError(
                    "BACKUP_RESTORE_DATABASE_URL is required for a full restore."
                )
            source_url = _database_url(settings.database_url)
            target_url = _database_url(settings.backup_restore_database_url)
            require_disposable_restore_target(
                source_database_url=source_url,
                target_database_url=target_url,
                confirmation=settings.backup_restore_confirmation,
                app_env=settings.app_env,
                app_role=settings.app_role,
            )
            run_pg_restore(
                executable=settings.backup_pg_restore_path,
                database_url=target_url,
                source=plain_dump,
                jobs=settings.backup_restore_jobs,
            )
            verify_restored_counts(target_url, manifest)
            restored = True
    return VerificationResult(
        manifest=manifest,
        archive_listed=True,
        restored=restored,
    )
