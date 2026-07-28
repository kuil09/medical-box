import base64
import os
import re
import subprocess
import textwrap
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
    assert "Restore script did not prove deterministic cleanup." in workflow
    assert "steps.restore.outputs.cleanup_verified == 'true'" in workflow
