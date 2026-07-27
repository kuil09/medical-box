import base64
import hashlib
import hmac
import json
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class EncryptionMetadata(BaseModel):
    model_config = ConfigDict(extra="forbid")

    format: str = "openpgp"
    recipient_fingerprint: str


class BackupManifest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    format_version: int = 1
    backup_id: str
    created_at: datetime
    completed_at: datetime
    object_key: str
    manifest_key: str
    source_database_name: str
    postgres_server_version: str
    pg_dump_version: str
    alembic_version: str
    table_counts: dict[str, int]
    plaintext_size: int = Field(ge=1)
    plaintext_sha256: str = Field(pattern=r"^[0-9a-f]{64}$")
    encrypted_size: int = Field(ge=1)
    encrypted_sha256: str = Field(pattern=r"^[0-9a-f]{64}$")
    encryption: EncryptionMetadata
    signature_hmac_sha256: str = Field(default="", pattern=r"^$|^[0-9a-f]{64}$")

    def unsigned_bytes(self) -> bytes:
        payload = self.model_dump(mode="json", exclude={"signature_hmac_sha256"})
        return json.dumps(
            payload,
            ensure_ascii=False,
            separators=(",", ":"),
            sort_keys=True,
        ).encode()

    def signed_bytes(self) -> bytes:
        return (
            json.dumps(
                self.model_dump(mode="json"),
                ensure_ascii=False,
                separators=(",", ":"),
                sort_keys=True,
            ).encode()
            + b"\n"
        )

    def sign(self, key: bytes) -> None:
        self.signature_hmac_sha256 = hmac.new(
            key,
            self.unsigned_bytes(),
            hashlib.sha256,
        ).hexdigest()

    def verify_signature(self, key: bytes) -> None:
        expected = hmac.new(key, self.unsigned_bytes(), hashlib.sha256).hexdigest()
        if not hmac.compare_digest(expected, self.signature_hmac_sha256):
            raise ValueError("Backup manifest HMAC verification failed.")


def decode_manifest_hmac_key(encoded: str) -> bytes:
    try:
        key = base64.b64decode(encoded, validate=True)
    except ValueError as exc:
        raise ValueError("BACKUP_MANIFEST_HMAC_KEY_BASE64 is not valid Base64.") from exc
    if len(key) < 32:
        raise ValueError("Backup manifest HMAC key must contain at least 32 bytes.")
    return key

