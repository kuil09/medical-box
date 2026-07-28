import uuid
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from ..apple_account import validate_apple_revocation_configuration
from ..config import Settings, get_settings
from ..db import get_db
from ..models import AuthIdentity, RefreshSession, TermsAcceptance, User
from ..providers import ProviderValidator, get_provider_validator
from ..schemas import (
    AccountProfile,
    AuthExchangeRequest,
    AuthSession,
    LogoutRequest,
    ReauthGrant,
    ReauthRequest,
    RefreshRequest,
)
from ..security import (
    create_access_token,
    create_reauth_grant,
    create_refresh_token,
    get_current_user,
    hash_secret,
    permissions_for_user,
)

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])

REAUTH_PROVIDER_PROOF_MAX_AGE = timedelta(minutes=5)
REAUTH_PROVIDER_PROOF_CLOCK_SKEW = timedelta(seconds=30)


def _profile(user: User) -> AccountProfile:
    return AccountProfile(
        id=user.id,
        display_name=user.display_name,
        email=user.email,
        providers=sorted(identity.provider for identity in user.identities),
        permissions=permissions_for_user(user),
        created_at=user.created_at,
    )


def _issue_session(
    db: Session,
    user: User,
    settings: Settings,
    *,
    device_label: str | None = None,
    family_id: uuid.UUID | None = None,
) -> tuple[AuthSession, RefreshSession]:
    raw_refresh = create_refresh_token()
    refresh_session = RefreshSession(
        user_id=user.id,
        family_id=family_id or uuid.uuid4(),
        token_hash=hash_secret(raw_refresh),
        device_label=device_label,
        expires_at=datetime.now(UTC) + timedelta(days=30),
    )
    db.add(refresh_session)
    db.flush()
    return (
        AuthSession(
            access_token=create_access_token(user.id, settings),
            refresh_token=raw_refresh,
            account=_profile(user),
        ),
        refresh_session,
    )


def _require_fresh_provider_proof(
    issued_at: datetime | None,
    authenticated_at: datetime | None,
) -> None:
    proof_time = authenticated_at or issued_at
    if proof_time is None:
        raise HTTPException(
            status_code=401,
            detail="A recent provider proof is required for reauthentication.",
        )
    if proof_time.tzinfo is None:
        proof_time = proof_time.replace(tzinfo=UTC)
    else:
        proof_time = proof_time.astimezone(UTC)
    now = datetime.now(UTC)
    if (
        proof_time > now + REAUTH_PROVIDER_PROOF_CLOCK_SKEW
        or now - proof_time > REAUTH_PROVIDER_PROOF_MAX_AGE
    ):
        raise HTTPException(
            status_code=401,
            detail="A recent provider proof is required for reauthentication.",
        )


def _lock_refresh_family_for_token(
    db: Session,
    token_hash: str,
) -> RefreshSession | None:
    family_id = db.scalar(
        select(RefreshSession.family_id).where(RefreshSession.token_hash == token_hash)
    )
    if family_id is None:
        return None
    family_anchor = db.scalar(
        select(RefreshSession)
        .where(RefreshSession.family_id == family_id)
        .order_by(RefreshSession.created_at, RefreshSession.id)
        .limit(1)
        .with_for_update()
    )
    if family_anchor is None:
        return None
    return db.scalar(
        select(RefreshSession)
        .where(RefreshSession.token_hash == token_hash)
        .with_for_update()
        .execution_options(populate_existing=True)
    )


@router.post("/exchange/{provider}", response_model=AuthSession)
def exchange_provider_token(
    provider: str,
    payload: AuthExchangeRequest,
    db: Session = Depends(get_db),
    validator: ProviderValidator = Depends(get_provider_validator),
    settings: Settings = Depends(get_settings),
) -> AuthSession:
    provider = provider.lower()
    if payload.terms_version != settings.terms_version:
        raise HTTPException(
            status_code=409,
            detail="The current terms must be accepted before sign-in.",
        )
    if provider == "apple" and (
        not settings.apple_sign_in_enabled or not settings.apple_account_revocation_configured
    ):
        raise HTTPException(
            status_code=503,
            detail="Apple sign-in is unavailable until account deletion is configured.",
        )
    if provider == "apple":
        validate_apple_revocation_configuration(settings)
    verified = validator.validate(provider, payload.provider_token)
    identity = db.scalar(
        select(AuthIdentity).where(
            AuthIdentity.provider == provider,
            AuthIdentity.provider_subject == verified.subject,
        )
    )
    if identity is None:
        user = User(display_name=verified.display_name, email=verified.email)
        db.add(user)
        db.flush()
        identity = AuthIdentity(
            user_id=user.id,
            provider=provider,
            provider_subject=verified.subject,
            email_at_link=verified.email,
        )
        db.add(identity)
    else:
        user = identity.user

    if (
        verified.email is not None
        and verified.email_verified
        and verified.email.casefold() in settings.catalog_access_email_allowlist_set
    ):
        user.catalog_read_enabled = True

    accepted = db.scalar(
        select(TermsAcceptance).where(
            TermsAcceptance.user_id == user.id,
            TermsAcceptance.version == payload.terms_version,
        )
    )
    if accepted is None:
        db.add(TermsAcceptance(user_id=user.id, version=payload.terms_version))

    response, _ = _issue_session(db, user, settings, device_label=payload.device_label)
    db.commit()
    return response


@router.post("/refresh", response_model=AuthSession)
def refresh_session(
    payload: RefreshRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> AuthSession:
    token_hash = hash_secret(payload.refresh_token)
    current = _lock_refresh_family_for_token(db, token_hash)
    if current is None:
        raise HTTPException(status_code=401, detail="Refresh token is invalid.")
    now = datetime.now(UTC)
    if current.revoked_at is not None:
        db.execute(
            update(RefreshSession)
            .where(
                RefreshSession.family_id == current.family_id,
                RefreshSession.revoked_at.is_(None),
            )
            .values(revoked_at=now)
        )
        db.commit()
        raise HTTPException(status_code=401, detail="Refresh token reuse detected.")
    expires_at = (
        current.expires_at.replace(tzinfo=UTC)
        if current.expires_at.tzinfo is None
        else current.expires_at
    )
    if expires_at < now:
        current.revoked_at = now
        db.commit()
        raise HTTPException(status_code=401, detail="Refresh token has expired.")

    current.revoked_at = now
    response, replacement = _issue_session(
        db,
        current.user,
        settings,
        device_label=current.device_label,
        family_id=current.family_id,
    )
    current.replaced_by_id = replacement.id
    db.commit()
    return response


@router.post("/logout", status_code=204)
def logout(payload: LogoutRequest, db: Session = Depends(get_db)) -> None:
    current = _lock_refresh_family_for_token(
        db,
        hash_secret(payload.refresh_token),
    )
    if current is None:
        return
    db.execute(
        update(RefreshSession)
        .where(
            RefreshSession.family_id == current.family_id,
            RefreshSession.revoked_at.is_(None),
        )
        .values(revoked_at=datetime.now(UTC))
    )
    db.commit()


@router.post("/reauth/{provider}", response_model=ReauthGrant)
def reauthenticate(
    provider: str,
    payload: ReauthRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    validator: ProviderValidator = Depends(get_provider_validator),
    settings: Settings = Depends(get_settings),
) -> ReauthGrant:
    provider = provider.lower()
    verified = validator.validate(provider, payload.provider_token)
    _require_fresh_provider_proof(
        verified.issued_at,
        verified.authenticated_at,
    )
    linked = db.scalar(
        select(AuthIdentity).where(
            AuthIdentity.user_id == user.id,
            AuthIdentity.provider == provider,
            AuthIdentity.provider_subject == verified.subject,
        )
    )
    if linked is None:
        raise HTTPException(
            status_code=403, detail="Provider identity is not linked to this account."
        )
    return ReauthGrant(grant=create_reauth_grant(user.id, provider, settings))
