import hashlib
from collections.abc import Collection
from typing import Any, cast

from sqlalchemy import ColumnElement, func, true
from sqlalchemy.orm import Session


def catalog_identity_hash(namespace: str, record_key: str) -> int:
    """Return the signed 64-bit catalog identity digest used by PostgreSQL."""
    material = f"{len(namespace)}:{namespace}{record_key}".encode()
    digest = hashlib.md5(material, usedforsecurity=False).digest()
    return int.from_bytes(digest[:8], "big", signed=True)


def catalog_identity_hash_sql(
    namespace: Any,
    record_key: Any,
) -> ColumnElement[int]:
    """Build the PostgreSQL expression backed by the compact identity index."""
    return cast(
        ColumnElement[int],
        func.catalog_identity_hash(namespace, record_key),
    )


def catalog_identity_in(
    db: Session,
    stored_namespace: Any,
    stored_record_key: Any,
    namespace: str,
    record_keys: Collection[str],
) -> ColumnElement[bool]:
    """Use the compact PostgreSQL index while preserving exact caller filters."""
    if db.get_bind().dialect.name != "postgresql":
        return true()
    return catalog_identity_hash_sql(
        stored_namespace,
        stored_record_key,
    ).in_(
        catalog_identity_hash(namespace, record_key)
        for record_key in record_keys
    )


def catalog_identity_matches(
    db: Session,
    stored_namespace: Any,
    stored_record_key: Any,
    lookup_namespace: Any,
    lookup_record_key: Any,
) -> ColumnElement[bool]:
    """Match two identities through the compact PostgreSQL index expression."""
    if db.get_bind().dialect.name != "postgresql":
        return true()
    return catalog_identity_hash_sql(
        stored_namespace,
        stored_record_key,
    ) == catalog_identity_hash_sql(
        lookup_namespace,
        lookup_record_key,
    )
