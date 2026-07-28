from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..apple_account import (
    AppleAuthorizationRevoker,
    get_apple_authorization_revoker,
)
from ..config import Settings, get_settings
from ..db import get_db
from ..models import AuthIdentity, User
from ..providers import ProviderValidator, get_provider_validator
from ..schemas import AccountPatch, AccountProfile, DeleteAccountRequest
from ..security import decode_token, get_current_user, permissions_for_user

router = APIRouter(prefix="/api/v1/me", tags=["account"])


def profile(user: User) -> AccountProfile:
    return AccountProfile(
        id=user.id,
        display_name=user.display_name,
        email=user.email,
        providers=sorted(identity.provider for identity in user.identities),
        permissions=permissions_for_user(user),
        created_at=user.created_at,
    )


@router.get("", response_model=AccountProfile)
def get_me(user: User = Depends(get_current_user)) -> AccountProfile:
    return profile(user)


@router.patch("", response_model=AccountProfile)
def update_me(
    payload: AccountPatch,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AccountProfile:
    user.display_name = payload.display_name.strip() if payload.display_name else None
    db.commit()
    return profile(user)


@router.delete("", status_code=204)
def delete_me(
    payload: DeleteAccountRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    validator: ProviderValidator = Depends(get_provider_validator),
    apple_revoker: AppleAuthorizationRevoker = Depends(
        get_apple_authorization_revoker
    ),
) -> None:
    claims = decode_token(payload.reauth_grant, "reauth", settings)
    try:
        grant_user_id = UUID(str(claims["sub"]))
    except (KeyError, ValueError) as exc:
        raise HTTPException(status_code=401, detail="Invalid reauthentication grant.") from exc
    if grant_user_id != user.id:
        raise HTTPException(
            status_code=403, detail="Reauthentication grant belongs to another account."
        )

    provider = claims.get("provider")
    if provider not in {"apple", "google", "kakao"}:
        raise HTTPException(status_code=401, detail="Invalid reauthentication grant.")
    identity = db.scalar(
        select(AuthIdentity).where(
            AuthIdentity.user_id == user.id,
            AuthIdentity.provider == provider,
        )
    )
    if identity is None:
        raise HTTPException(
            status_code=403,
            detail="Reauthenticated provider is not linked to this account.",
        )

    if provider == "apple":
        if payload.apple_authorization_code is None:
            raise HTTPException(
                status_code=400,
                detail="Apple authorization code is required for account deletion.",
            )
        apple_revoker.revoke(
            provider_subject=identity.provider_subject,
            authorization_code=payload.apple_authorization_code,
            validator=validator,
        )
    elif payload.apple_authorization_code is not None:
        raise HTTPException(
            status_code=400,
            detail="Apple authorization code is only valid for Apple accounts.",
        )

    db.delete(user)
    db.commit()
