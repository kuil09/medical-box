import hashlib
from collections.abc import Iterator
from contextlib import contextmanager

from sqlalchemy import func, select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

CATALOG_MUTATION_LOCK_KEY = int.from_bytes(
    hashlib.sha256(b"medical-box:catalog-mutation").digest()[:8],
    "big",
) & 0x7FFF_FFFF_FFFF_FFFF


@contextmanager
def catalog_mutation_lock(db: Session) -> Iterator[None]:
    bind = db.get_bind()
    if bind.dialect.name != "postgresql":
        yield
        return
    engine = bind.engine if isinstance(bind, Connection) else bind
    with engine.connect() as lock_connection:
        lock_connection = lock_connection.execution_options(
            isolation_level="AUTOCOMMIT"
        )
        acquired = lock_connection.scalar(
            select(func.pg_try_advisory_lock(CATALOG_MUTATION_LOCK_KEY))
        )
        if not acquired:
            raise RuntimeError("Another catalog mutation or production backup is active.")
        try:
            yield
        finally:
            lock_connection.scalar(
                select(func.pg_advisory_unlock(CATALOG_MUTATION_LOCK_KEY))
            )
