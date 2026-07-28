from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel


class ApiModel(BaseModel):
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        from_attributes=True,
    )


class ProviderIdentity(ApiModel):
    subject: str
    email: str | None = None
    display_name: str | None = None


class AuthExchangeRequest(ApiModel):
    provider_token: str = Field(min_length=8)
    terms_version: str
    terms_accepted: Literal[True]
    device_label: str | None = Field(default=None, max_length=120)


class RefreshRequest(ApiModel):
    refresh_token: str = Field(min_length=32)


class LogoutRequest(ApiModel):
    refresh_token: str = Field(min_length=32)


class ReauthRequest(ApiModel):
    provider_token: str = Field(min_length=8)


class DeleteAccountRequest(ApiModel):
    reauth_grant: str
    apple_authorization_code: str | None = Field(
        default=None,
        min_length=8,
        max_length=4096,
    )


class AccountPatch(ApiModel):
    display_name: str | None = Field(default=None, max_length=80)


class AccountProfile(ApiModel):
    id: UUID
    display_name: str | None
    email: str | None
    providers: list[str]
    permissions: list[str]
    created_at: datetime


class AuthSession(ApiModel):
    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int = 900
    account: AccountProfile


class ReauthGrant(ApiModel):
    grant: str
    expires_in: int = 300


class DrugSourceAttribution(ApiModel):
    source: str
    source_url: str
    license_name: str | None = None
    attribution: str | None = None


class DrugSummary(ApiModel):
    item_seq: str
    item_name: str
    manufacturer: str | None
    status: str | None
    professional_category: str | None


class DrugAppearanceInfo(ApiModel):
    variant_key: str | None = None
    shape: str | None
    color: str | None
    imprint_front: str | None
    imprint_back: str | None
    image_url: str | None


class DrugSafetyCategory(ApiModel):
    rule_type: str
    count: int


class DrugSafetyOverview(ApiModel):
    total_count: int
    categories: list[DrugSafetyCategory]


class DrugSafetyRule(ApiModel):
    rule_type: str
    type_name: str | None
    ingredient_name: str | None
    counterpart_item_seq: str | None
    counterpart_item_name: str | None
    counterpart_ingredient_name: str | None
    prohibition_content: str | None
    remark: str | None
    notification_date: str | None
    source_code: str


class DrugDetail(DrugSummary):
    permit_date: str | None
    storage_method: str | None
    appearance: str | None
    image_url: str | None
    identification: DrugAppearanceInfo | None
    identification_variants: list[DrugAppearanceInfo]
    safety_overview: DrugSafetyOverview
    ingredients: list[str]
    efficacy: str | None
    use_method: str | None
    warning: str | None
    precautions: str | None
    interactions: str | None
    side_effects: str | None
    source_updated_at: str | None
    sources: list[DrugSourceAttribution]


class CatalogSource(ApiModel):
    code: str
    name: str
    portal_url: str
    license_name: str | None
    attribution: str | None
    last_successful_sync: datetime | None
    last_attempt_status: str | None
    last_attempt_at: datetime | None


class CatalogMeta(ApiModel):
    product_count: int
    last_successful_sync: datetime | None
    failed_sources: list[str]
    sources: list[CatalogSource]


class CursorPage[T](ApiModel):
    items: list[T]
    next_cursor: str | None
