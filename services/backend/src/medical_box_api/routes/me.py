from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..config import Settings, get_settings
from ..db import get_db
from ..models import User
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
    db.delete(user)
    db.commit()
