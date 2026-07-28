import base64
import json
import os
import re
import subprocess
import textwrap
from pathlib import Path

import pytest


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


def _worker_status(
    *,
    project: str = "medical-box",
    environments: list[str] | None = None,
    services: list[str] | None = None,
    buckets: list[str] | None = None,
) -> dict[str, object]:
    return {
        "name": project,
        "environments": {
            "edges": [
                {"node": {"name": name}}
                for name in (environments or ["production"])
            ]
        },
        "services": {
            "edges": [
                {"node": {"name": name}}
                for name in (services or ["production-backup"])
            ]
        },
        "buckets": {
            "edges": [
                {"node": {"name": name}}
                for name in (buckets or ["production-backups"])
            ]
        },
    }


def _write_worker_secret_fake_railway(binary_directory: Path) -> None:
    fake_railway = binary_directory / "railway"
    fake_railway.write_text(
        """#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "status" ]]; then
  printf '%s\\n' "${FAKE_WORKER_STATUS_JSON}"
elif [[ "$1" == "bucket" && "$2" == "credentials" ]]; then
  printf '%s\\n' "${FAKE_WORKER_CREDENTIALS_JSON}"
elif [[ "$1" == "variable" && "$2" == "set" ]]; then
  variable_name="${!#}"
  value="$(cat)"
  printf '%s\\t%s\\n' "${variable_name}" "${value}" >>"${WORKER_VALUE_CAPTURE_FILE}"
  printf '%q ' "$@" >>"${WORKER_ARGV_CAPTURE_FILE}"
  printf '\\n' >>"${WORKER_ARGV_CAPTURE_FILE}"
else
  exit 64
fi
"""
    )
    fake_railway.chmod(0o700)


def _run_worker_secret_wiring(
    tmp_path: Path,
    *,
    local_files: dict[str, bytes | None] | None = None,
    credentials: dict[str, object] | None = None,
    status: dict[str, object] | None = None,
    fail_cleanup: bool = False,
    key_directory: Path | None = None,
) -> tuple[subprocess.CompletedProcess[str], Path, Path, Path]:
    if key_directory is None:
        key_directory = tmp_path / "external-worker-keys"
        key_directory.mkdir()
        default_files: dict[str, bytes | None] = {
            "backup-public.gpg": b"worker-public-key",
            "backup-manifest-hmac.key": b"h" * 32,
            "backup-recipient-fingerprint.txt": (
                b"0123456789abcdef0123456789abcdef01234567\n"
            ),
            "backup-private.gpg": b"private-key-must-never-be-read",
        }
        default_files.update(local_files or {})
        for file_name, content in default_files.items():
            if content is not None:
                (key_directory / file_name).write_bytes(content)

    default_credentials: dict[str, object] = {
        "endpoint": "https://bucket.invalid",
        "accessKeyId": "access-id",
        "secretAccessKey": "secret-key",
        "bucketName": "production-backups-id",
        "region": "sin",
        "urlStyle": "path",
    }
    default_credentials.update(credentials or {})
    binary_directory = tmp_path / "bin"
    binary_directory.mkdir()
    _write_worker_secret_fake_railway(binary_directory)
    if fail_cleanup:
        fake_rm = binary_directory / "rm"
        fake_rm.write_text(
            "#!/usr/bin/env bash\n/bin/rm \"$@\"\nexit 1\n"
        )
        fake_rm.chmod(0o700)

    value_capture_file = tmp_path / "worker-values"
    argv_capture_file = tmp_path / "worker-argv"
    script = Path(__file__).parents[1] / "scripts" / "wire_backup_secrets.sh"
    result = subprocess.run(
        [str(script), str(key_directory)],
        check=False,
        capture_output=True,
        text=True,
        env={
            **os.environ,
            "PATH": f"{binary_directory}:{os.environ['PATH']}",
            "FAKE_WORKER_STATUS_JSON": json.dumps(status or _worker_status()),
            "FAKE_WORKER_CREDENTIALS_JSON": json.dumps(default_credentials),
            "WORKER_VALUE_CAPTURE_FILE": str(value_capture_file),
            "WORKER_ARGV_CAPTURE_FILE": str(argv_capture_file),
        },
    )
    return result, value_capture_file, argv_capture_file


def test_wire_backup_secrets_preflights_and_writes_exact_worker_values(
    tmp_path: Path,
) -> None:
    result, value_capture_file, argv_capture_file = _run_worker_secret_wiring(
        tmp_path
    )

    assert result.returncode == 0, result.stderr
    captured_pairs = [
        line.split("\t", 1)
        for line in value_capture_file.read_text().splitlines()
    ]
    assert dict(captured_pairs) == {
        "AWS_ENDPOINT_URL": "https://bucket.invalid",
        "AWS_ACCESS_KEY_ID": "access-id",
        "AWS_SECRET_ACCESS_KEY": "secret-key",
        "AWS_S3_BUCKET_NAME": "production-backups-id",
        "AWS_DEFAULT_REGION": "sin",
        "AWS_S3_ADDRESSING_STYLE": "path",
        "BACKUP_GPG_PUBLIC_KEY_BASE64": base64.b64encode(
            b"worker-public-key"
        ).decode(),
        "BACKUP_GPG_RECIPIENT": "0123456789ABCDEF0123456789ABCDEF01234567",
        "BACKUP_MANIFEST_HMAC_KEY_BASE64": base64.b64encode(
            b"h" * 32
        ).decode(),
    }
    assert len(captured_pairs) == 9
    command_arguments = argv_capture_file.read_text()
    assert command_arguments.count("--service production-backup") == 9
    assert command_arguments.count("--environment production") == 9
    assert command_arguments.count("--skip-deploys") == 9
    assert command_arguments.count("--stdin") == 9
    for _, secret_value in captured_pairs:
        assert secret_value not in command_arguments
    assert "private-key-must-never-be-read" not in command_arguments
    assert "private-key-must-never-be-read" not in value_capture_file.read_text()


def test_wire_backup_secrets_accepts_binary_hmac_key_material(
    tmp_path: Path,
) -> None:
    binary_hmac_key = b"h" * 31 + b"\x00"
    result, value_capture_file, _ = _run_worker_secret_wiring(
        tmp_path,
        local_files={"backup-manifest-hmac.key": binary_hmac_key},
    )

    assert result.returncode == 0, result.stderr
    captured = dict(
        line.split("\t", 1)
        for line in value_capture_file.read_text().splitlines()
    )
    assert captured["BACKUP_MANIFEST_HMAC_KEY_BASE64"] == base64.b64encode(
        binary_hmac_key
    ).decode()


@pytest.mark.parametrize(
    ("file_name", "invalid_value"),
    [
        ("backup-public.gpg", None),
        ("backup-public.gpg", b""),
        ("backup-public.gpg", b" null\n"),
        ("backup-manifest-hmac.key", None),
        ("backup-manifest-hmac.key", b""),
        ("backup-manifest-hmac.key", b"null"),
        ("backup-manifest-hmac.key", b"h" * 31),
        ("backup-recipient-fingerprint.txt", None),
        ("backup-recipient-fingerprint.txt", b""),
        ("backup-recipient-fingerprint.txt", b"NULL\\n"),
        ("backup-recipient-fingerprint.txt", b"not-a-fingerprint"),
    ],
)
def test_wire_backup_secrets_rejects_invalid_public_material_before_mutation(
    tmp_path: Path,
    file_name: str,
    invalid_value: bytes | None,
) -> None:
    result, value_capture_file, argv_capture_file = _run_worker_secret_wiring(
        tmp_path,
        local_files={file_name: invalid_value},
    )

    assert result.returncode != 0
    assert not value_capture_file.exists()
    assert not argv_capture_file.exists()


@pytest.mark.parametrize(
    ("credential_name", "invalid_value"),
    [
        (field_name, invalid_value)
        for field_name in (
            "endpoint",
            "accessKeyId",
            "secretAccessKey",
            "bucketName",
            "region",
            "urlStyle",
        )
        for invalid_value in ("", " null ", None)
    ],
)
def test_wire_backup_secrets_rejects_invalid_credentials_before_mutation(
    tmp_path: Path,
    credential_name: str,
    invalid_value: object,
) -> None:
    result, value_capture_file, argv_capture_file = _run_worker_secret_wiring(
        tmp_path,
        credentials={credential_name: invalid_value},
    )

    assert result.returncode != 0
    assert not value_capture_file.exists()
    assert not argv_capture_file.exists()


def test_wire_backup_secrets_rejects_unsupported_bucket_url_style_before_mutation(
    tmp_path: Path,
) -> None:
    result, value_capture_file, argv_capture_file = _run_worker_secret_wiring(
        tmp_path,
        credentials={"urlStyle": "subdomain"},
    )

    assert result.returncode != 0
    assert not value_capture_file.exists()
    assert not argv_capture_file.exists()


@pytest.mark.parametrize(
    "status",
    [
        _worker_status(project="other-project"),
        _worker_status(environments=["production", "staging"]),
        _worker_status(services=["api"]),
        _worker_status(services=["production-backup", "production-backup"]),
        _worker_status(buckets=["other-bucket"]),
        _worker_status(buckets=["production-backups", "production-backups"]),
    ],
)
def test_wire_backup_secrets_requires_exact_railway_target_before_mutation(
    tmp_path: Path,
    status: dict[str, object],
) -> None:
    result, value_capture_file, argv_capture_file = _run_worker_secret_wiring(
        tmp_path,
        status=status,
    )

    assert result.returncode != 0
    assert not value_capture_file.exists()
    assert not argv_capture_file.exists()


def test_wire_backup_secrets_rejects_key_directory_inside_repository(
    tmp_path: Path,
) -> None:
    script = Path(__file__).parents[1] / "scripts" / "wire_backup_secrets.sh"
    repository_root = script.parents[3]
    result, value_capture_file, argv_capture_file = _run_worker_secret_wiring(
        tmp_path,
        key_directory=repository_root,
    )

    assert result.returncode != 0
    assert not value_capture_file.exists()
    assert not argv_capture_file.exists()


def test_wire_backup_secrets_fails_when_temporary_cleanup_cannot_be_confirmed(
    tmp_path: Path,
) -> None:
    result, value_capture_file, _ = _run_worker_secret_wiring(
        tmp_path,
        fail_cleanup=True,
    )

    assert result.returncode != 0
    assert "Temporary backup-secret material cleanup failed." in result.stderr
    assert len(value_capture_file.read_text().splitlines()) == 9


def _write_backup_restore_secret_fakes(
    binary_directory: Path,
) -> None:
    fake_railway = binary_directory / "railway"
    fake_railway.write_text(
        """#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "status" ]]; then
  status_json='{"name":"medical-box",'
  status_json+='"environments":{"edges":[{"node":{"name":"production"}}]},'
  status_json+='"services":{"edges":[]},'
  status_json+='"buckets":{"edges":[{"node":{"name":"production-backups"}}]}}'
  printf '%s\\n' "${status_json}"
elif [[ "$1" == "bucket" && "$2" == "credentials" ]]; then
  printf '%s\\n' "${FAKE_BUCKET_CREDENTIALS_JSON}"
else
  exit 64
fi
"""
    )
    fake_railway.chmod(0o700)

    fake_gh = binary_directory / "gh"
    fake_gh.write_text(
        """#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "auth" && "$2" == "status" ]]; then
  exit 0
fi
if [[ "$1" == "repo" && "$2" == "view" ]]; then
  printf '{"nameWithOwner":"%s"}\\n' "${FAKE_GITHUB_REPOSITORY}"
  exit 0
fi
if [[ "$1" == "api" ]]; then
  case "$2" in
    user)
      if [[ "${3:-}" != "--jq" ]] || [[ "${4:-}" != ".login" ]]; then
        exit 64
      fi
      printf '%s\\n' "${FAKE_GITHUB_LOGIN}"
      exit 0
      ;;
    repos/kuil09/medical-box/environments/backup-restore)
      printf '%s\\n' "${FAKE_GITHUB_ENVIRONMENT_PROTECTION_JSON}"
      exit 0
      ;;
    "repos/kuil09/medical-box/environments/backup-restore/deployment-branch-policies?per_page=100")
      printf '%s\\n' "${FAKE_GITHUB_BRANCH_POLICIES_JSON}"
      exit 0
      ;;
  esac
  exit 64
fi
if [[ "$1" == "secret" && "$2" == "set" ]]; then
  secret_name="$3"
  shift 3
  if [[ "$#" -ne 4 ]] ||
    [[ "$1" != "--env" ]] ||
    [[ "$2" != "backup-restore" ]] ||
    [[ "$3" != "--repo" ]] ||
    [[ "$4" != "kuil09/medical-box" ]]; then
    exit 64
  fi
  secret_value="$(cat)"
  printf '%s\\t%s\\n' "${secret_name}" "${secret_value}" \
    >>"${SECRET_CAPTURE_FILE}"
  printf '%s --env %s --repo %s\\n' "${secret_name}" "$2" "$4" \
    >>"${ARGV_CAPTURE_FILE}"
  exit 0
fi
if [[ "$1" == "variable" && "$2" == "set" ]]; then
  variable_name="$3"
  shift 3
  if [[ "$#" -ne 4 ]] ||
    [[ "$1" != "--env" ]] ||
    [[ "$2" != "backup-restore" ]] ||
    [[ "$3" != "--repo" ]] ||
    [[ "$4" != "kuil09/medical-box" ]]; then
    exit 64
  fi
  variable_value="$(cat)"
  printf '%s\\t%s\\n' "${variable_name}" "${variable_value}" \
    >>"${VARIABLE_CAPTURE_FILE}"
  printf '%s --env %s --repo %s\\n' "${variable_name}" "$2" "$4" \
    >>"${ARGV_CAPTURE_FILE}"
  exit 0
fi
exit 64
"""
    )
    fake_gh.chmod(0o700)


def _run_backup_restore_secret_wiring(
    tmp_path: Path,
    *,
    credentials: dict[str, object] | None = None,
    local_files: dict[str, bytes] | None = None,
    github_repository: str = "kuil09/medical-box",
    github_login: str = "backup-admin",
    environment_protection: dict[str, object] | None = None,
    branch_policies: dict[str, object] | None = None,
) -> tuple[subprocess.CompletedProcess[str], Path, Path]:
    key_directory = tmp_path / "keys"
    key_directory.mkdir()
    default_local_files = {
        "backup-private.gpg": b"private-key-that-must-stay-private",
        "backup-passphrase.txt": b"restore-passphrase\n",
        "backup-manifest-hmac.key": b"h" * 32,
        "backup-public.gpg": b"worker-public-key-must-not-be-sent",
    }
    default_local_files.update(local_files or {})
    for file_name, value in default_local_files.items():
        (key_directory / file_name).write_bytes(value)

    default_credentials: dict[str, object] = {
        "endpoint": "https://bucket.invalid",
        "accessKeyId": "restore-access-id",
        "secretAccessKey": "restore-secret-key",
        "bucketName": "production-backups-id",
        "region": "sin",
        "urlStyle": "path",
    }
    default_credentials.update(credentials or {})

    default_environment_protection: dict[str, object] = {
        "protection_rules": [
            {
                "type": "required_reviewers",
                "prevent_self_review": True,
                "reviewers": [
                    {
                        "type": "User",
                        "reviewer": {"login": "independent-reviewer"},
                    }
                ],
            }
        ],
        "deployment_branch_policy": {
            "protected_branches": False,
            "custom_branch_policies": True,
        },
    }
    if environment_protection is not None:
        default_environment_protection = environment_protection
    default_branch_policies: dict[str, object] = {
        "total_count": 1,
        "branch_policies": [{"name": "main", "type": "branch"}],
    }
    if branch_policies is not None:
        default_branch_policies = branch_policies

    binary_directory = tmp_path / "bin"
    binary_directory.mkdir()
    _write_backup_restore_secret_fakes(binary_directory)
    secret_capture_file = tmp_path / "secret-capture"
    argv_capture_file = tmp_path / "argv-capture"
    variable_capture_file = tmp_path / "variable-capture"
    script = (
        Path(__file__).parents[1]
        / "scripts"
        / "wire_backup_restore_secrets.sh"
    )
    result = subprocess.run(
        [str(script), str(key_directory)],
        check=False,
        capture_output=True,
        text=True,
        env={
            **os.environ,
            "PATH": f"{binary_directory}:{os.environ['PATH']}",
            "FAKE_BUCKET_CREDENTIALS_JSON": json.dumps(default_credentials),
            "FAKE_GITHUB_REPOSITORY": github_repository,
            "FAKE_GITHUB_LOGIN": github_login,
            "FAKE_GITHUB_ENVIRONMENT_PROTECTION_JSON": json.dumps(
                default_environment_protection
            ),
            "FAKE_GITHUB_BRANCH_POLICIES_JSON": json.dumps(
                default_branch_policies
            ),
            "SECRET_CAPTURE_FILE": str(secret_capture_file),
            "VARIABLE_CAPTURE_FILE": str(variable_capture_file),
            "ARGV_CAPTURE_FILE": str(argv_capture_file),
        },
    )
    return result, secret_capture_file, variable_capture_file, argv_capture_file


def test_wire_backup_restore_secrets_sets_exact_environment_secret_set(
    tmp_path: Path,
) -> None:
    result, secret_capture_file, variable_capture_file, argv_capture_file = (
        _run_backup_restore_secret_wiring(tmp_path)
    )

    assert result.returncode == 0, result.stderr
    captured_pairs = [
        line.split("\t", 1)
        for line in secret_capture_file.read_text().splitlines()
    ]
    assert dict(captured_pairs) == {
        "AWS_ENDPOINT_URL": "https://bucket.invalid",
        "AWS_ACCESS_KEY_ID": "restore-access-id",
        "AWS_SECRET_ACCESS_KEY": "restore-secret-key",
        "AWS_S3_BUCKET_NAME": "production-backups-id",
        "BACKUP_GPG_PRIVATE_KEY_BASE64": base64.b64encode(
            b"private-key-that-must-stay-private"
        ).decode(),
        "BACKUP_GPG_PASSPHRASE": "restore-passphrase",
        "BACKUP_MANIFEST_HMAC_KEY_BASE64": base64.b64encode(
            b"h" * 32
        ).decode(),
    }
    assert len(captured_pairs) == 7
    captured_names = [name for name, _ in captured_pairs]
    assert len(captured_names) == len(set(captured_names))
    assert "BACKUP_GPG_PUBLIC_KEY_BASE64" not in captured_names
    assert "worker-public-key-must-not-be-sent" not in (
        secret_capture_file.read_text()
    )
    captured_variables = [
        line.split("\t", 1)
        for line in variable_capture_file.read_text().splitlines()
    ]
    assert captured_variables == [
        ["AWS_DEFAULT_REGION", "sin"],
        ["AWS_S3_ADDRESSING_STYLE", "path"],
    ]

    command_arguments = argv_capture_file.read_text()
    assert command_arguments.count("--env backup-restore") == 9
    assert command_arguments.count("--repo kuil09/medical-box") == 9
    for _, secret_value in captured_pairs:
        assert secret_value not in command_arguments
        assert secret_value not in result.stdout
        assert secret_value not in result.stderr


def test_wire_backup_restore_secrets_rejects_unexpected_repository_before_mutation(
    tmp_path: Path,
) -> None:
    result, secret_capture_file, variable_capture_file, argv_capture_file = (
        _run_backup_restore_secret_wiring(
            tmp_path,
            github_repository="someone-else/medical-box",
        )
    )

    assert result.returncode != 0
    assert not secret_capture_file.exists()
    assert not variable_capture_file.exists()
    assert not argv_capture_file.exists()


def _valid_backup_restore_environment_protection() -> dict[str, object]:
    return {
        "protection_rules": [
            {
                "type": "required_reviewers",
                "prevent_self_review": True,
                "reviewers": [
                    {
                        "type": "User",
                        "reviewer": {"login": "independent-reviewer"},
                    }
                ],
            }
        ],
        "deployment_branch_policy": {
            "protected_branches": False,
            "custom_branch_policies": True,
        },
    }


@pytest.mark.parametrize(
    ("environment_protection", "branch_policies"),
    [
        (
            {
                **_valid_backup_restore_environment_protection(),
                "protection_rules": [],
            },
            None,
        ),
        (
            {
                **_valid_backup_restore_environment_protection(),
                "protection_rules": [
                    {
                        "type": "required_reviewers",
                        "prevent_self_review": False,
                        "reviewers": [
                            {
                                "type": "User",
                                "reviewer": {"login": "independent-reviewer"},
                            }
                        ],
                    }
                ],
            },
            None,
        ),
        (
            {
                **_valid_backup_restore_environment_protection(),
                "protection_rules": [
                    {
                        "type": "required_reviewers",
                        "prevent_self_review": True,
                        "reviewers": [],
                    }
                ],
            },
            None,
        ),
        (
            {
                **_valid_backup_restore_environment_protection(),
                "protection_rules": [
                    {
                        "type": "required_reviewers",
                        "prevent_self_review": True,
                        "reviewers": [
                            {
                                "type": "User",
                                "reviewer": {"login": "backup-admin"},
                            }
                        ],
                    }
                ],
            },
            None,
        ),
        (
            {
                **_valid_backup_restore_environment_protection(),
                "deployment_branch_policy": {
                    "protected_branches": True,
                    "custom_branch_policies": True,
                },
            },
            None,
        ),
        (
            {
                **_valid_backup_restore_environment_protection(),
                "deployment_branch_policy": {
                    "protected_branches": False,
                    "custom_branch_policies": False,
                },
            },
            None,
        ),
        (
            _valid_backup_restore_environment_protection(),
            {"total_count": 0, "branch_policies": []},
        ),
        (
            _valid_backup_restore_environment_protection(),
            {
                "total_count": 2,
                "branch_policies": [
                    {"name": "main", "type": "branch"},
                    {"name": "release", "type": "branch"},
                ],
            },
        ),
    ],
)
def test_wire_backup_restore_secrets_rejects_insufficient_environment_protection(
    tmp_path: Path,
    environment_protection: dict[str, object],
    branch_policies: dict[str, object] | None,
) -> None:
    result, secret_capture_file, variable_capture_file, argv_capture_file = (
        _run_backup_restore_secret_wiring(
            tmp_path,
            environment_protection=environment_protection,
            branch_policies=branch_policies,
        )
    )

    assert result.returncode != 0
    assert not secret_capture_file.exists()
    assert not variable_capture_file.exists()
    assert not argv_capture_file.exists()


@pytest.mark.parametrize("url_style", ["auto", "path", "virtual"])
def test_wire_backup_restore_secrets_accepts_independent_team_reviewer(
    tmp_path: Path,
    url_style: str,
) -> None:
    environment_protection = _valid_backup_restore_environment_protection()
    environment_protection["protection_rules"] = [
        {
            "type": "required_reviewers",
            "prevent_self_review": True,
            "reviewers": [
                {"type": "Team", "reviewer": {"slug": "operations"}}
            ],
        }
    ]

    result, secret_capture_file, variable_capture_file, _ = (
        _run_backup_restore_secret_wiring(
            tmp_path,
            credentials={"urlStyle": url_style},
            environment_protection=environment_protection,
        )
    )

    assert result.returncode == 0, result.stderr
    assert len(secret_capture_file.read_text().splitlines()) == 7
    assert variable_capture_file.read_text().splitlines() == [
        "AWS_DEFAULT_REGION\tsin",
        f"AWS_S3_ADDRESSING_STYLE\t{url_style}",
    ]


@pytest.mark.parametrize(
    ("credential_name", "invalid_value"),
    [
        ("endpoint", ""),
        ("endpoint", None),
        ("endpoint", " null "),
        ("accessKeyId", ""),
        ("accessKeyId", None),
        ("secretAccessKey", ""),
        ("secretAccessKey", None),
        ("bucketName", ""),
        ("bucketName", None),
        ("region", ""),
        ("region", None),
        ("region", " null "),
        ("urlStyle", ""),
        ("urlStyle", None),
        ("urlStyle", " null "),
        ("urlStyle", "unsupported"),
    ],
)
def test_wire_backup_restore_secrets_rejects_incomplete_bucket_credentials(
    tmp_path: Path,
    credential_name: str,
    invalid_value: object,
) -> None:
    result, secret_capture_file, variable_capture_file, argv_capture_file = (
        _run_backup_restore_secret_wiring(
            tmp_path,
            credentials={credential_name: invalid_value},
        )
    )

    assert result.returncode != 0
    assert not secret_capture_file.exists()
    assert not variable_capture_file.exists()
    assert not argv_capture_file.exists()


@pytest.mark.parametrize(
    ("file_name", "invalid_value"),
    [
        ("backup-private.gpg", b""),
        ("backup-private.gpg", b"null\n"),
        ("backup-passphrase.txt", b""),
        ("backup-passphrase.txt", b"NULL\n"),
        ("backup-manifest-hmac.key", b""),
        ("backup-manifest-hmac.key", b"null"),
    ],
)
def test_wire_backup_restore_secrets_rejects_empty_or_null_local_material(
    tmp_path: Path,
    file_name: str,
    invalid_value: bytes,
) -> None:
    result, secret_capture_file, variable_capture_file, _ = (
        _run_backup_restore_secret_wiring(
            tmp_path,
            local_files={file_name: invalid_value},
        )
    )

    assert result.returncode != 0
    assert not secret_capture_file.exists()
    assert not variable_capture_file.exists()


def _write_fake_docker(binary_directory: Path) -> None:
    fake_docker = binary_directory / "docker"
    fake_docker.write_text(
        textwrap.dedent(
            """\
            #!/usr/bin/env bash
            set -euo pipefail

            command_name="$1"
            shift
            case "${command_name}" in
              build)
                exit 0
                ;;
              container)
                [[ "$1" == "ls" ]]
                for path in "${STATE_DIR}/containers/"*; do
                  [[ -e "${path}" ]] || continue
                  basename "${path}"
                done
                ;;
              exec)
                exit 0
                ;;
              network)
                network_command="$1"
                shift
                case "${network_command}" in
                  create)
                    touch "${STATE_DIR}/networks/$1"
                    ;;
                  ls)
                    for path in "${STATE_DIR}/networks/"*; do
                      [[ -e "${path}" ]] || continue
                      basename "${path}"
                    done
                    ;;
                  rm)
                    if [[ "${FAKE_DOCKER_FAIL_NETWORK_RM:-0}" == "1" ]]; then
                      echo "injected network removal failure" >&2
                      exit 1
                    fi
                    rm -f "${STATE_DIR}/networks/$1"
                    ;;
                  *)
                    exit 64
                    ;;
                esac
                ;;
              rm)
                [[ "${1:-}" == "--force" ]] && shift
                for container_name in "$@"; do
                  rm -f "${STATE_DIR}/containers/${container_name}"
                done
                ;;
              run)
                detached=false
                remove_after=false
                container_name=""
                while [[ "$#" -gt 0 ]]; do
                  case "$1" in
                    --detach)
                      detached=true
                      shift
                      ;;
                    --rm)
                      remove_after=true
                      shift
                      ;;
                    --name)
                      container_name="$2"
                      shift 2
                      ;;
                    --env|--file|--network|--tag|--user|--volume)
                      shift 2
                      ;;
                    *)
                      shift
                      ;;
                  esac
                done
                if [[ -n "${container_name}" ]]; then
                  touch "${STATE_DIR}/containers/${container_name}"
                fi
                if [[ "${detached}" == true ]]; then
                  printf 'fake-container-id\\n'
                elif [[ "${remove_after}" == true && -n "${container_name}" ]]; then
                  rm -f "${STATE_DIR}/containers/${container_name}"
                fi
                ;;
              *)
                exit 64
                ;;
            esac
            """
        )
    )
    fake_docker.chmod(0o700)


def _production_restore_environment(
    binary_directory: Path,
    state_directory: Path,
) -> dict[str, str]:
    return {
        **os.environ,
        "PATH": f"{binary_directory}:{os.environ['PATH']}",
        "STATE_DIR": str(state_directory),
        "BACKUP_STORE": "s3",
        "BACKUP_PREFIX": "medical-box/production",
        "AWS_ENDPOINT_URL": "https://bucket.invalid",
        "AWS_ACCESS_KEY_ID": "access-id",
        "AWS_SECRET_ACCESS_KEY": "secret-key",
        "AWS_S3_BUCKET_NAME": "bucket-id",
        "AWS_DEFAULT_REGION": "sin",
        "AWS_S3_ADDRESSING_STYLE": "path",
        "BACKUP_MANIFEST_HMAC_KEY_BASE64": base64.b64encode(b"h" * 32).decode(),
    }


def _run_production_restore_script(
    tmp_path: Path,
    *,
    fail_network_removal: bool = False,
) -> tuple[subprocess.CompletedProcess[str], Path]:
    key_directory = tmp_path / "keys"
    key_directory.mkdir()
    (key_directory / "backup-private.gpg").write_bytes(b"private-key")
    (key_directory / "backup-passphrase.txt").write_text("passphrase")

    state_directory = tmp_path / "docker-state"
    (state_directory / "containers").mkdir(parents=True)
    (state_directory / "networks").mkdir()
    binary_directory = tmp_path / "bin"
    binary_directory.mkdir()
    _write_fake_docker(binary_directory)

    environment = _production_restore_environment(
        binary_directory,
        state_directory,
    )
    if fail_network_removal:
        environment["FAKE_DOCKER_FAIL_NETWORK_RM"] = "1"

    script = (
        Path(__file__).parents[1]
        / "scripts"
        / "verify_production_backup_restore.sh"
    )
    result = subprocess.run(
        [str(script), str(key_directory)],
        check=False,
        capture_output=True,
        text=True,
        env=environment,
    )
    return result, state_directory


def test_production_restore_script_verifies_deterministic_cleanup(
    tmp_path: Path,
) -> None:
    result, state_directory = _run_production_restore_script(tmp_path)

    assert result.returncode == 0, result.stderr
    assert "cleanup_verified=true" in result.stdout.splitlines()
    assert list((state_directory / "containers").iterdir()) == []
    assert list((state_directory / "networks").iterdir()) == []


def test_production_restore_script_fails_when_cleanup_cannot_be_verified(
    tmp_path: Path,
) -> None:
    result, state_directory = _run_production_restore_script(
        tmp_path,
        fail_network_removal=True,
    )

    assert result.returncode != 0
    assert "cleanup_verified=true" not in result.stdout
    assert "deterministic cleanup verification failed" in result.stderr
    assert list((state_directory / "networks").iterdir()) != []


def test_backup_roundtrip_and_workflow_require_cleanup_proof() -> None:
    repository_root = Path(__file__).parents[3]
    roundtrip_script = (
        repository_root
        / "services"
        / "backend"
        / "scripts"
        / "test_backup_roundtrip.sh"
    ).read_text()
    production_restore_script = (
        repository_root
        / "services"
        / "backend"
        / "scripts"
        / "verify_production_backup_restore.sh"
    ).read_text()
    workflow = (
        repository_root
        / ".github"
        / "workflows"
        / "production-backup-restore.yml"
    ).read_text()
    mobile_release_workflow = (
        repository_root
        / ".github"
        / "workflows"
        / "mobile-release-build.yml"
    ).read_text()
    mobile_cleanup_script = (
        repository_root
        / ".github"
        / "scripts"
        / "cleanup-mobile-signing-material.sh"
    ).read_text()

    assert "if ! cleanup_resources; then" in roundtrip_script
    assert 'printf \'cleanup_verified=true\\n\'' in roundtrip_script
    assert "|| true" not in roundtrip_script
    run_following_lines = re.findall(
        r"docker run --rm \\\n([^\n]+)",
        roundtrip_script,
    )
    assert run_following_lines
    assert all(line.strip().startswith("--name ") for line in run_following_lines)
    assert 'docker_arguments=(--rm --name "${verify_name}"' in production_restore_script
    assert "verify_production_backup_restore.sh" in workflow
    assert "schedule:" not in workflow
    assert "workflow_dispatch:" in workflow
    assert "if: github.ref == 'refs/heads/main'" in workflow
    assert "AWS_DEFAULT_REGION: ${{ vars.AWS_DEFAULT_REGION }}" in workflow
    assert "AWS_S3_ADDRESSING_STYLE: ${{ vars.AWS_S3_ADDRESSING_STYLE }}" in workflow
    assert "Restore script did not prove deterministic cleanup." in workflow
    assert "steps.restore.outputs.cleanup_verified == 'true'" in workflow
    assert mobile_release_workflow.count(
        "github.ref == 'refs/heads/main'"
    ) == 2
    assert (
        "vars.APPLE_SIGN_IN_ENABLED == 'true'"
        in mobile_release_workflow
    )
    assert (
        "vars.APPLE_ACCOUNT_REVOCATION_READY == 'true'"
        in mobile_release_workflow
    )
    assert (
        '--dart-define="APPLE_SIGN_IN_ENABLED=${APPLE_SIGN_IN_ENABLED}"'
        in mobile_release_workflow
    )
    assert "APPLE_SIGN_IN_PRIVATE_KEY_BASE64" not in mobile_release_workflow
    assert "actions/upload-artifact" not in mobile_release_workflow
    assert "retention-days:" not in mobile_release_workflow
    android_cleanup = mobile_release_workflow.split(
        "      - name: Remove Android signed output and signing material\n",
        maxsplit=1,
    )[1].split("\n\n  ios:", maxsplit=1)[0]
    ios_cleanup = mobile_release_workflow.split(
        "      - name: Remove iOS signed output and signing material\n",
        maxsplit=1,
    )[1]
    assert "if: always()" in android_cleanup
    assert "if: always()" in ios_cleanup
    assert "cleanup-mobile-signing-material.sh android" in android_cleanup
    assert "cleanup-mobile-signing-material.sh ios" in ios_cleanup
    assert "set -e" not in mobile_cleanup_script
    assert "set -u -o pipefail" in mobile_cleanup_script
    assert "cleanup_failed=1" in mobile_cleanup_script
    assert "remove_release_directory" in mobile_cleanup_script
    assert "remove_release_file" in mobile_cleanup_script
    assert "verify_release_target_absent" in mobile_cleanup_script
    assert '((cleanup_failed == 0))' in mobile_cleanup_script
    assert '! security delete-keychain "${keychain}"' in mobile_cleanup_script


def test_no_cost_railway_graph_disables_scheduled_and_automatic_workers() -> None:
    railway_config = (
        Path(__file__).parents[3] / ".railway" / "railway.ts"
    ).read_text()

    assert railway_config.count('"services/backend/**"') == 1
    assert railway_config.count('".railway/railway.ts"') == 1
    assert railway_config.count('".railway/catalog-sync-activation"') == 1
    assert "cronSchedule" not in railway_config
    assert "production-backups" not in railway_config
    assert 'fn("production-backup"' not in railway_config
    assert "APPLE_SIGN_IN_ENABLED: preserve()" in railway_config


def _backup_plan_guard_allowed_changes() -> list[dict[str, object]]:
    return [
        {
            "kind": "variable.set",
            "summary": "Update variable medical-box.CATALOG_MIN_FREE_BYTES",
            "severity": "safe",
            "details": [
                "medical-box.CATALOG_MIN_FREE_BYTES "
                "(preserve() → «hidden»)"
            ],
        },
        {
            "kind": "variable.set",
            "summary": "Set variable medical-box.TERMS_VERSION",
            "severity": "safe",
            "details": [
                "medical-box.TERMS_VERSION (unset → «hidden»)"
            ],
        },
        {
            "kind": "variable.set",
            "summary": "Update variable catalog-sync.CATALOG_MIN_FREE_BYTES",
            "severity": "safe",
            "details": [
                "catalog-sync.CATALOG_MIN_FREE_BYTES "
                "(preserve() → «hidden»)"
            ],
        },
        {
            "kind": "resource.update",
            "summary": "Update catalog-sync build.watchPatterns",
            "severity": "safe",
            "details": [
                'build.watchPatterns (["services/backend/**",'
                '".railway/railway.ts"] → '
                '[".railway/catalog-sync-activation"])'
            ],
        },
        {
            "kind": "resource.update",
            "summary": "Update catalog-sync deploy.cronSchedule",
            "severity": "safe",
            "details": ['deploy.cronSchedule ("10 18 * * *" → unset)'],
        },
    ]


def _backup_plan_guard_payload(
    *,
    project_name: str = "medical-box",
    environment_name: str = "production",
    changes: list[dict[str, object]] | None = None,
    diagnostics: list[dict[str, object]] | None = None,
    catalog_start: str = (
        "/bin/sh -c 'echo \"Catalog sync temporarily paused while "
        "normalization safety is repaired\"'"
    ),
    catalog_cron: str | None = None,
    api_catalog_min_free_bytes: str = "1200000000",
    catalog_sync_min_free_bytes: str = "1200000000",
    terms_version: str = "2026-07-25",
    extra_resources: list[dict[str, object]] | None = None,
) -> dict[str, object]:
    allowed_changes = _backup_plan_guard_allowed_changes()
    catalog_deploy: dict[str, object] = {"startCommand": catalog_start}
    if catalog_cron is not None:
        catalog_deploy["cronSchedule"] = catalog_cron
    return {
        "ok": True,
        "currentEnvironment": {
            "projectId": "project-id",
            "projectName": project_name,
            "environmentId": "production-id",
            "environmentName": environment_name,
        },
        "diagnostics": diagnostics if diagnostics is not None else [],
        "changeSet": {"changes": changes if changes is not None else allowed_changes},
        "desiredGraph": {
            "project": {"name": project_name},
            "resources": [
                {
                    "address": "group.Backend",
                    "name": "Backend",
                },
                {
                    "address": "database.Postgres",
                    "name": "Postgres",
                },
                {
                    "address": "service.medical-box",
                    "name": "medical-box",
                    "variables": {
                        "CATALOG_MIN_FREE_BYTES": {
                            "type": "literal",
                            "value": api_catalog_min_free_bytes,
                        },
                        "TERMS_VERSION": {
                            "type": "literal",
                            "value": terms_version,
                        },
                    },
                },
                {
                    "address": "service.catalog-sync",
                    "name": "catalog-sync",
                    "deploy": catalog_deploy,
                    "variables": {
                        "CATALOG_MIN_FREE_BYTES": {
                            "type": "literal",
                            "value": catalog_sync_min_free_bytes,
                        },
                    },
                },
                *(extra_resources or []),
            ],
        },
    }


def _run_backup_railway_plan_guard(
    tmp_path: Path,
    *,
    status_project: str = "medical-box",
    status_environment: str = "production",
    plan: dict[str, object] | None = None,
) -> tuple[subprocess.CompletedProcess[str], Path]:
    binary_directory = tmp_path / "bin"
    binary_directory.mkdir()
    command_capture_file = tmp_path / "railway-commands"
    fake_railway = binary_directory / "railway"
    fake_railway.write_text(
        """#!/usr/bin/env bash
set -euo pipefail
printf '%s\\n' "$*" >>"${RAILWAY_COMMAND_CAPTURE_FILE}"
if [[ "$1" == "status" ]]; then
  printf '%s\\n' "${FAKE_RAILWAY_STATUS_JSON}"
  exit 0
fi
if [[ "$1" == "config" && "$2" == "plan" ]]; then
  printf '%s\\n' "${FAKE_RAILWAY_PLAN_JSON}"
  exit 0
fi
exit 64
"""
    )
    fake_railway.chmod(0o700)
    status = {
        "id": "project-id",
        "name": status_project,
        "environments": {
            "edges": [
                {
                    "node": {
                        "id": "production-id",
                        "name": status_environment,
                    }
                }
            ]
        },
    }
    script = (
        Path(__file__).parents[1] / "scripts" / "check_backup_railway_plan.sh"
    )
    result = subprocess.run(
        [str(script)],
        check=False,
        capture_output=True,
        text=True,
        cwd=Path(__file__).parents[3],
        env={
            **os.environ,
            "PATH": f"{binary_directory}:{os.environ['PATH']}",
            "RAILWAY_COMMAND_CAPTURE_FILE": str(command_capture_file),
            "FAKE_RAILWAY_STATUS_JSON": json.dumps(status),
            "FAKE_RAILWAY_PLAN_JSON": json.dumps(
                plan if plan is not None else _backup_plan_guard_payload()
            ),
        },
    )
    return result, command_capture_file


def test_backup_railway_plan_guard_accepts_only_no_cost_allowlist(
    tmp_path: Path,
) -> None:
    result, command_capture_file = _run_backup_railway_plan_guard(tmp_path)

    assert result.returncode == 0, result.stderr
    assert result.stdout == "no_cost_railway_plan_guard=passed\n"
    commands = command_capture_file.read_text().splitlines()
    assert commands[0] == "status --project medical-box --environment production --json"
    assert commands[1].startswith("config plan --file ")
    assert commands[1].endswith("/.railway/railway.ts --json")
    assert not any("apply" in command for command in commands)


def test_backup_railway_plan_guard_accepts_terms_preserve_transition(
    tmp_path: Path,
) -> None:
    changes = _backup_plan_guard_allowed_changes()
    changes[1] = {
        **changes[1],
        "details": [
            "medical-box.TERMS_VERSION (preserve() → «hidden»)"
        ],
    }

    result, _ = _run_backup_railway_plan_guard(
        tmp_path,
        plan=_backup_plan_guard_payload(changes=changes),
    )

    assert result.returncode == 0, result.stderr


@pytest.mark.parametrize(
    ("status_project", "status_environment", "message"),
    [
        ("other-project", "production", "Railway status is not exactly"),
        ("medical-box", "staging", "Railway status is not exactly"),
    ],
)
def test_backup_railway_plan_guard_rejects_wrong_status_target(
    tmp_path: Path,
    status_project: str,
    status_environment: str,
    message: str,
) -> None:
    result, command_capture_file = _run_backup_railway_plan_guard(
        tmp_path,
        status_project=status_project,
        status_environment=status_environment,
    )

    assert result.returncode != 0
    assert message in result.stderr
    assert command_capture_file.read_text().splitlines() == [
        "status --project medical-box --environment production --json"
    ]


@pytest.mark.parametrize(
    "plan",
    [
        _backup_plan_guard_payload(
            changes=[
                *_backup_plan_guard_allowed_changes(),
                {
                    "kind": "variable.set",
                    "summary": "Update medical-box.UNRELATED",
                    "severity": "safe",
                },
            ]
        ),
        _backup_plan_guard_payload(
            changes=[
                {
                    **_backup_plan_guard_allowed_changes()[0],
                    "details": [
                        "medical-box.UNRELATED "
                        "(preserve() → «hidden»)"
                    ],
                },
                *_backup_plan_guard_allowed_changes()[1:],
            ]
        ),
        _backup_plan_guard_payload(api_catalog_min_free_bytes="0"),
        _backup_plan_guard_payload(catalog_sync_min_free_bytes="0"),
        _backup_plan_guard_payload(terms_version="2099-01-01"),
        _backup_plan_guard_payload(
            changes=[
                {
                    "kind": "resource.delete",
                    "summary": "Delete service medical-box",
                    "severity": "destructive",
                }
            ]
        ),
        _backup_plan_guard_payload(catalog_cron="10 18 * * *"),
        _backup_plan_guard_payload(
            extra_resources=[
                {
                    "address": "service.production-backup",
                    "name": "production-backup",
                    "deploy": {},
                }
            ]
        ),
        _backup_plan_guard_payload(
            extra_resources=[
                {
                    "address": "service.unrelated",
                    "name": "unrelated",
                    "deploy": {},
                }
            ]
        ),
        _backup_plan_guard_payload(
            catalog_start="uv run --no-sync medical-box-sync all-sources"
        ),
        _backup_plan_guard_payload(
            diagnostics=[
                {
                    "severity": "warning",
                    "path": ".railway/railway.ts",
                    "message": "Unexpected configuration warning",
                }
            ]
        ),
    ],
    ids=[
        "unexpected-change",
        "unexpected-variable-change-details",
        "unexpected-api-catalog-reserve",
        "unexpected-sync-catalog-reserve",
        "unexpected-terms-version",
        "delete",
        "active-catalog-cron",
        "backup-resource",
        "unrelated-resource",
        "active-catalog-command",
        "diagnostic",
    ],
)
def test_backup_railway_plan_guard_rejects_unsafe_plan(
    tmp_path: Path,
    plan: dict[str, object],
) -> None:
    result, command_capture_file = _run_backup_railway_plan_guard(
        tmp_path,
        plan=plan,
    )

    assert result.returncode != 0
    assert "no_cost_railway_plan_guard=passed" not in result.stdout
    assert not any(
        "apply" in command
        for command in command_capture_file.read_text().splitlines()
    )
