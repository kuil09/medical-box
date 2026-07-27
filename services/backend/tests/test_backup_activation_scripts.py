import base64
import os
import subprocess
from pathlib import Path


def test_wire_backup_secrets_uses_stdin_and_excludes_private_key(
    tmp_path: Path,
) -> None:
    key_directory = tmp_path / "keys"
    key_directory.mkdir()
    (key_directory / "backup-public.gpg").write_bytes(b"public-key")
    (key_directory / "backup-manifest-hmac.key").write_bytes(b"h" * 32)
    (key_directory / "backup-recipient-fingerprint.txt").write_text(
        "0123456789ABCDEF0123456789ABCDEF01234567\n"
    )
    (key_directory / "backup-private.gpg").write_bytes(b"must-not-be-read")

    binary_directory = tmp_path / "bin"
    binary_directory.mkdir()
    capture_file = tmp_path / "captured-variables"
    fake_railway = binary_directory / "railway"
    fake_railway.write_text(
        """#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "status" ]]; then
  status_json='{"name":"medical-box",'
  status_json+='"environments":{"edges":[{"node":{"name":"production"}}]},'
  status_json+='"services":{"edges":[{"node":{"name":"production-backup"}}]},'
  status_json+='"buckets":{"edges":[{"node":{"name":"production-backups"}}]}}'
  printf '%s\\n' "${status_json}"
elif [[ "$1" == "bucket" && "$2" == "credentials" ]]; then
  printf '%s\\n' '{"endpoint":"https://bucket.invalid","accessKeyId":"access-id","secretAccessKey":"secret-key","bucketName":"bucket-id","region":"sin","urlStyle":"path"}'
elif [[ "$1" == "variable" && "$2" == "set" ]]; then
  variable_name="${!#}"
  value="$(cat)"
  printf '%s=%s\\n' "${variable_name}" "${value}" >>"${CAPTURE_FILE}"
else
  exit 64
fi
"""
    )
    fake_railway.chmod(0o700)

    script = (
        Path(__file__).parents[1] / "scripts" / "wire_backup_secrets.sh"
    )
    result = subprocess.run(
        [str(script), str(key_directory)],
        check=False,
        capture_output=True,
        text=True,
        env={
            **os.environ,
            "PATH": f"{binary_directory}:{os.environ['PATH']}",
            "CAPTURE_FILE": str(capture_file),
        },
    )

    assert result.returncode == 0, result.stderr
    captured = dict(
        line.split("=", 1)
        for line in capture_file.read_text().splitlines()
    )
    assert captured == {
        "AWS_ENDPOINT_URL": "https://bucket.invalid",
        "AWS_ACCESS_KEY_ID": "access-id",
        "AWS_SECRET_ACCESS_KEY": "secret-key",
        "AWS_S3_BUCKET_NAME": "bucket-id",
        "AWS_DEFAULT_REGION": "sin",
        "AWS_S3_ADDRESSING_STYLE": "path",
        "BACKUP_GPG_PUBLIC_KEY_BASE64": base64.b64encode(b"public-key").decode(),
        "BACKUP_GPG_RECIPIENT": "0123456789ABCDEF0123456789ABCDEF01234567",
        "BACKUP_MANIFEST_HMAC_KEY_BASE64": base64.b64encode(b"h" * 32).decode(),
    }
    assert "must-not-be-read" not in capture_file.read_text()
