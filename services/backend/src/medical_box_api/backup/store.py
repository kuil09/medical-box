from __future__ import annotations

import shutil
from collections.abc import Iterable
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import TYPE_CHECKING, Literal, Protocol

import boto3
from botocore.config import Config

if TYPE_CHECKING:
    from mypy_boto3_s3.client import S3Client
    from mypy_boto3_s3.type_defs import ObjectIdentifierTypeDef


@dataclass(frozen=True)
class StoredObject:
    key: str
    size: int
    last_modified: datetime


class BackupStore(Protocol):
    def put_file(
        self,
        key: str,
        source: Path,
        *,
        content_type: str,
        metadata: dict[str, str],
    ) -> None: ...

    def put_bytes(
        self,
        key: str,
        content: bytes,
        *,
        content_type: str,
        metadata: dict[str, str],
    ) -> None: ...

    def get_file(self, key: str, destination: Path) -> None: ...

    def get_bytes(self, key: str) -> bytes: ...

    def list_objects(self, prefix: str) -> list[StoredObject]: ...

    def delete_objects(self, keys: Iterable[str]) -> None: ...


class LocalBackupStore:
    def __init__(self, root: Path) -> None:
        self.root = root.resolve()
        self.root.mkdir(parents=True, exist_ok=True, mode=0o700)

    def _path(self, key: str) -> Path:
        path = (self.root / key).resolve()
        if not path.is_relative_to(self.root):
            raise ValueError("Backup object key escapes the local store root.")
        return path

    def put_file(
        self,
        key: str,
        source: Path,
        *,
        content_type: str,
        metadata: dict[str, str],
    ) -> None:
        del content_type, metadata
        destination = self._path(key)
        destination.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        shutil.copyfile(source, destination)

    def put_bytes(
        self,
        key: str,
        content: bytes,
        *,
        content_type: str,
        metadata: dict[str, str],
    ) -> None:
        del content_type, metadata
        destination = self._path(key)
        destination.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        destination.write_bytes(content)

    def get_file(self, key: str, destination: Path) -> None:
        shutil.copyfile(self._path(key), destination)

    def get_bytes(self, key: str) -> bytes:
        return self._path(key).read_bytes()

    def list_objects(self, prefix: str) -> list[StoredObject]:
        directory = self._path(prefix)
        if not directory.exists():
            return []
        objects: list[StoredObject] = []
        for path in directory.rglob("*"):
            if not path.is_file():
                continue
            stat = path.stat()
            objects.append(
                StoredObject(
                    key=path.relative_to(self.root).as_posix(),
                    size=stat.st_size,
                    last_modified=datetime.fromtimestamp(stat.st_mtime, tz=UTC),
                )
            )
        return sorted(objects, key=lambda item: item.key)

    def delete_objects(self, keys: Iterable[str]) -> None:
        for key in keys:
            path = self._path(key)
            if path.exists():
                path.unlink()


class S3BackupStore:
    def __init__(
        self,
        *,
        endpoint_url: str,
        access_key_id: str,
        secret_access_key: str,
        bucket_name: str,
        region: str,
        addressing_style: Literal["auto", "path", "virtual"],
    ) -> None:
        self.bucket_name = bucket_name
        self.client: S3Client = boto3.client(
            "s3",
            endpoint_url=endpoint_url,
            aws_access_key_id=access_key_id,
            aws_secret_access_key=secret_access_key,
            region_name=region,
            config=Config(
                signature_version="s3v4",
                s3={"addressing_style": addressing_style},
                retries={"max_attempts": 5, "mode": "standard"},
            ),
        )

    def put_file(
        self,
        key: str,
        source: Path,
        *,
        content_type: str,
        metadata: dict[str, str],
    ) -> None:
        self.client.upload_file(
            str(source),
            self.bucket_name,
            key,
            ExtraArgs={"ContentType": content_type, "Metadata": metadata},
        )

    def put_bytes(
        self,
        key: str,
        content: bytes,
        *,
        content_type: str,
        metadata: dict[str, str],
    ) -> None:
        self.client.put_object(
            Bucket=self.bucket_name,
            Key=key,
            Body=content,
            ContentType=content_type,
            Metadata=metadata,
        )

    def get_file(self, key: str, destination: Path) -> None:
        self.client.download_file(self.bucket_name, key, str(destination))

    def get_bytes(self, key: str) -> bytes:
        response = self.client.get_object(Bucket=self.bucket_name, Key=key)
        return response["Body"].read()

    def list_objects(self, prefix: str) -> list[StoredObject]:
        objects: list[StoredObject] = []
        paginator = self.client.get_paginator("list_objects_v2")
        for page in paginator.paginate(Bucket=self.bucket_name, Prefix=prefix):
            for item in page.get("Contents", []):
                objects.append(
                    StoredObject(
                        key=str(item["Key"]),
                        size=int(item["Size"]),
                        last_modified=item["LastModified"],
                    )
                )
        return sorted(objects, key=lambda item: item.key)

    def delete_objects(self, keys: Iterable[str]) -> None:
        pending: list[ObjectIdentifierTypeDef] = [{"Key": key} for key in keys]
        for offset in range(0, len(pending), 1000):
            batch = pending[offset : offset + 1000]
            if batch:
                response = self.client.delete_objects(
                    Bucket=self.bucket_name,
                    Delete={"Objects": batch, "Quiet": True},
                )
                errors = response.get("Errors", [])
                if errors:
                    raise RuntimeError(
                        f"Failed to delete {len(errors)} backup objects."
                    )
