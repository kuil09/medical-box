import uuid
from datetime import UTC, date, datetime
from decimal import Decimal

from sqlalchemy import (
    JSON,
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .db import Base


def utc_now() -> datetime:
    return datetime.now(UTC)


json_type = JSON().with_variant(JSONB, "postgresql")


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    display_name: Mapped[str | None] = mapped_column(String(80))
    email: Mapped[str | None] = mapped_column(String(320))
    catalog_read_enabled: Mapped[bool] = mapped_column(
        Boolean, default=True, server_default="true"
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )

    identities: Mapped[list["AuthIdentity"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    sessions: Mapped[list["RefreshSession"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    terms: Mapped[list["TermsAcceptance"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )


class AuthIdentity(Base):
    __tablename__ = "auth_identities"
    __table_args__ = (UniqueConstraint("provider", "provider_subject"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    provider: Mapped[str] = mapped_column(String(20))
    provider_subject: Mapped[str] = mapped_column(String(255))
    email_at_link: Mapped[str | None] = mapped_column(String(320))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    user: Mapped[User] = relationship(back_populates="identities")


class RefreshSession(Base):
    __tablename__ = "refresh_sessions"
    __table_args__ = (Index("ix_refresh_sessions_token_hash", "token_hash", unique=True),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    family_id: Mapped[uuid.UUID] = mapped_column(default=uuid.uuid4, index=True)
    token_hash: Mapped[str] = mapped_column(String(64))
    device_label: Mapped[str | None] = mapped_column(String(120))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    replaced_by_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("refresh_sessions.id", ondelete="SET NULL")
    )

    user: Mapped[User] = relationship(back_populates="sessions", foreign_keys=[user_id])


class TermsAcceptance(Base):
    __tablename__ = "terms_acceptances"
    __table_args__ = (UniqueConstraint("user_id", "version"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    version: Mapped[str] = mapped_column(String(40))
    accepted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    user: Mapped[User] = relationship(back_populates="terms")


class SourceRegistry(Base):
    __tablename__ = "source_registry"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    code: Mapped[str] = mapped_column(String(80), unique=True)
    name: Mapped[str] = mapped_column(String(180))
    portal_url: Mapped[str] = mapped_column(String(500))
    api_url: Mapped[str | None] = mapped_column(String(500))
    license_name: Mapped[str | None] = mapped_column(String(160))
    attribution: Mapped[str | None] = mapped_column(Text)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )


class SyncRun(Base):
    __tablename__ = "sync_runs"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    source_code: Mapped[str] = mapped_column(String(80), index=True)
    status: Mapped[str] = mapped_column(String(20), default="running")
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    record_count: Mapped[int] = mapped_column(Integer, default=0)
    page_count: Mapped[int] = mapped_column(Integer, default=0)
    error: Mapped[str | None] = mapped_column(Text)


class SyncCheckpoint(Base):
    __tablename__ = "sync_checkpoints"

    source_code: Mapped[str] = mapped_column(String(80), primary_key=True)
    page: Mapped[int] = mapped_column(Integer, default=0)
    source_updated_at: Mapped[str | None] = mapped_column(String(80))
    content_hash: Mapped[str | None] = mapped_column(String(64))
    normalization_version: Mapped[int] = mapped_column(Integer, default=1)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )


class SourceRecord(Base):
    __tablename__ = "source_records"
    __table_args__ = (
        UniqueConstraint("source_code", "record_key"),
        Index("ix_source_records_active", "source_code", "active"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    source_code: Mapped[str] = mapped_column(String(80))
    record_key: Mapped[str] = mapped_column(String(255))
    content_hash: Mapped[str] = mapped_column(String(64))
    public_data: Mapped[dict[str, object]] = mapped_column(
        "payload",
        json_type,
    )
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_seen_run_id: Mapped[uuid.UUID] = mapped_column(index=True)
    first_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)


class DrugProduct(Base):
    __tablename__ = "drug_products"
    __table_args__ = (
        Index("ix_drug_products_name", "item_name"),
        Index("ix_drug_products_manufacturer", "manufacturer"),
    )

    item_seq: Mapped[str] = mapped_column(String(40), primary_key=True)
    item_name: Mapped[str] = mapped_column(String(500))
    manufacturer: Mapped[str | None] = mapped_column(String(300))
    permit_date: Mapped[date | None] = mapped_column(Date)
    status: Mapped[str | None] = mapped_column(String(120))
    storage_method: Mapped[str | None] = mapped_column(Text)
    appearance: Mapped[str | None] = mapped_column(Text)
    professional_category: Mapped[str | None] = mapped_column(String(80))
    image_url: Mapped[str | None] = mapped_column(String(1000))
    source_updated_at: Mapped[str | None] = mapped_column(String(80))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )

    ingredients: Mapped[list["DrugIngredient"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )
    consumer_info: Mapped["DrugConsumerInfo | None"] = relationship(
        back_populates="product", cascade="all, delete-orphan", uselist=False
    )


class DrugIngredient(Base):
    __tablename__ = "drug_ingredients"
    __table_args__ = (UniqueConstraint("item_seq", "name"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    item_seq: Mapped[str] = mapped_column(
        ForeignKey("drug_products.item_seq", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(500))
    amount: Mapped[str | None] = mapped_column(String(180))
    unit: Mapped[str | None] = mapped_column(String(80))

    product: Mapped[DrugProduct] = relationship(back_populates="ingredients")


class DrugConsumerInfo(Base):
    __tablename__ = "drug_consumer_info"

    item_seq: Mapped[str] = mapped_column(
        ForeignKey("drug_products.item_seq", ondelete="CASCADE"), primary_key=True
    )
    efficacy: Mapped[str | None] = mapped_column(Text)
    use_method: Mapped[str | None] = mapped_column(Text)
    warning: Mapped[str | None] = mapped_column(Text)
    precautions: Mapped[str | None] = mapped_column(Text)
    interactions: Mapped[str | None] = mapped_column(Text)
    side_effects: Mapped[str | None] = mapped_column(Text)
    storage: Mapped[str | None] = mapped_column(Text)
    source_updated_at: Mapped[str | None] = mapped_column(String(80))

    product: Mapped[DrugProduct] = relationship(back_populates="consumer_info")


class DrugIdentification(Base):
    __tablename__ = "drug_identification"

    item_seq: Mapped[str] = mapped_column(String(40), primary_key=True)
    source_record_id: Mapped[int] = mapped_column(
        ForeignKey(
            "source_records.id",
            name="fk_drug_identification_source_record",
            ondelete="CASCADE",
        ),
        index=True,
    )
    shape: Mapped[str | None] = mapped_column(String(120))
    color: Mapped[str | None] = mapped_column(String(120))
    imprint_front: Mapped[str | None] = mapped_column(String(180))
    imprint_back: Mapped[str | None] = mapped_column(String(180))
    image_url: Mapped[str | None] = mapped_column(String(1000))

    source_record: Mapped[SourceRecord] = relationship()


class DrugIdentificationVariant(Base):
    __tablename__ = "drug_identification_variants"
    __table_args__ = (
        UniqueConstraint("source_code", "variant_key"),
        Index("ix_drug_identification_variants_item_seq", "item_seq"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    source_record_id: Mapped[int] = mapped_column(
        ForeignKey(
            "source_records.id",
            name="fk_drug_identification_variants_source_record",
            ondelete="CASCADE",
        ),
        index=True,
    )
    item_seq: Mapped[str] = mapped_column(String(40))
    source_code: Mapped[str] = mapped_column(String(80))
    variant_key: Mapped[str] = mapped_column(String(255))
    shape: Mapped[str | None] = mapped_column(String(120))
    color: Mapped[str | None] = mapped_column(String(120))
    imprint_front: Mapped[str | None] = mapped_column(String(180))
    imprint_back: Mapped[str | None] = mapped_column(String(180))
    image_url: Mapped[str | None] = mapped_column(String(1000))

    source_record: Mapped[SourceRecord] = relationship()


class DrugCode(Base):
    __tablename__ = "drug_codes"
    __table_args__ = (UniqueConstraint("code_type", "code"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    source_record_id: Mapped[int] = mapped_column(
        ForeignKey(
            "source_records.id",
            name="fk_drug_codes_source_record",
            ondelete="CASCADE",
        ),
        index=True,
    )
    item_seq: Mapped[str | None] = mapped_column(String(40), index=True)
    code_type: Mapped[str] = mapped_column(String(80))
    code: Mapped[str] = mapped_column(String(120))
    valid_from: Mapped[date | None] = mapped_column(Date)
    valid_to: Mapped[date | None] = mapped_column(Date)

    source_record: Mapped[SourceRecord] = relationship()


class DrugPrice(Base):
    __tablename__ = "drug_prices"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    source_record_id: Mapped[int] = mapped_column(
        ForeignKey(
            "source_records.id",
            name="fk_drug_prices_source_record",
            ondelete="CASCADE",
        ),
        index=True,
    )
    item_seq: Mapped[str | None] = mapped_column(String(40), index=True)
    insurance_code: Mapped[str | None] = mapped_column(String(120), index=True)
    amount: Mapped[Decimal | None] = mapped_column(Numeric(14, 2))
    effective_date: Mapped[date | None] = mapped_column(Date)

    source_record: Mapped[SourceRecord] = relationship()


class DurRule(Base):
    __tablename__ = "dur_rules"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    source_record_id: Mapped[int] = mapped_column(
        ForeignKey(
            "source_records.id",
            name="fk_dur_rules_source_record",
            ondelete="CASCADE",
        ),
        index=True,
        unique=True,
    )
    item_seq: Mapped[str | None] = mapped_column(String(40), index=True)
    counterpart_item_seq: Mapped[str | None] = mapped_column(String(40), index=True)
    rule_type: Mapped[str | None] = mapped_column(String(120))

    source_record: Mapped[SourceRecord] = relationship()


class DrugStatusEvent(Base):
    __tablename__ = "drug_status_events"
    __table_args__ = (UniqueConstraint("source_code", "event_key"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    source_record_id: Mapped[int] = mapped_column(
        ForeignKey(
            "source_records.id",
            name="fk_drug_status_events_source_record",
            ondelete="CASCADE",
        ),
        index=True,
    )
    item_seq: Mapped[str | None] = mapped_column(String(40), index=True)
    source_code: Mapped[str] = mapped_column(String(80))
    event_key: Mapped[str] = mapped_column(String(255))
    event_type: Mapped[str] = mapped_column(String(120))
    started_on: Mapped[date | None] = mapped_column(Date)
    ended_on: Mapped[date | None] = mapped_column(Date)

    source_record: Mapped[SourceRecord] = relationship()
