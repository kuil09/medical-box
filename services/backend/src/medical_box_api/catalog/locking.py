import hashlib
from collections.abc import Iterator
from contextlib import contextmanager

from sqlalchemy import func, select
from sqlalchemy.orm import Session

CATALOG_MUTATION_LOCK_KEY = int.from_bytes(
    hashlib.sha256(b"medical-box:catalog-mutation").digest()[:8],
    "big",
) & 0x7FFF_FFFF_FFFF_FFFF


@contextmanager
def catalog_mutation_lock(db: Session) -> Iterator[None]:
    if db.bind is None or db.bind.dialect.name != "postgresql":
        yield
        return
    acquired = db.scalar(select(func.pg_try_advisory_lock(CATALOG_MUTATION_LOCK_KEY)))
    if not acquired:
        raise RuntimeError("Another catalog mutation or production backup is active.")
    try:
        yield
    finally:
        if not db.is_active:
            db.rollback()
        db.scalar(select(func.pg_advisory_unlock(CATALOG_MUTATION_LOCK_KEY)))
