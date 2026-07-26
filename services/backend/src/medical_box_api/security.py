import hashlib
import secrets
import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from .config import Settings, get_settings
from .db import get_db
from .models import User

bearer = HTTPBearer(auto_error=False)
CATALOG_READ_PERMISSION = "catalog:read"


def hash_secret(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def create_refresh_token() -> str:
    return secrets.token_urlsafe(48)


def _encode_token(
    *,
    subject: str,
    token_type: str,
    lifetime: timedelta,
    settings: Settings,
    extra: dict[str, Any] | None = None,
) -> str:
    now = datetime.now(UTC)
    claims: dict[str, Any] = {
        "sub": subject,
        "typ": token_type,
        "iss": settings.jwt_issuer,
        "aud": settings.jwt_audience,
        "iat": now,
        "exp": now + lifetime,
        "jti": str(uuid.uuid4()),
    }
    if extra:
        claims.update(extra)
    return jwt.encode(claims, settings.jwt_secret, algorithm="HS256")


def create_access_token(user_id: uuid.UUID, settings: Settings) -> str:
    return _encode_token(
        subject=str(user_id),
        token_type="access",
        lifetime=timedelta(minutes=15),
        settings=settings,
    )


def create_reauth_grant(user_id: uuid.UUID, provider: str, settings: Settings) -> str:
    return _encode_token(
        subject=str(user_id),
        token_type="reauth",
        lifetime=timedelta(minutes=5),
        settings=settings,
        extra={"provider": provider},
    )


def decode_token(token: str, expected_type: str, settings: Settings) -> dict[str, Any]:
    try:
        claims = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=["HS256"],
            audience=settings.jwt_audience,
            issuer=settings.jwt_issuer,
        )
    except jwt.PyJWTError as exc:
        raise HTTPException(status_code=401, detail="Invalid authentication token.") from exc
    if claims.get("typ") != expected_type:
        raise HTTPException(status_code=401, detail="Unexpected authentication token type.")
    return claims


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> User:
    if credentials is None:
        raise HTTPException(status_code=401, detail="Authentication required.")
    claims = decode_token(credentials.credentials, "access", settings)
    try:
        user_id = uuid.UUID(str(claims["sub"]))
    except (KeyError, ValueError) as exc:
        raise HTTPException(status_code=401, detail="Invalid token subject.") from exc
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=401, detail="Account no longer exists.")
    return user


def permissions_for_user(user: User) -> list[str]:
    return [CATALOG_READ_PERMISSION] if user.catalog_read_enabled else []


def require_catalog_read(user: User = Depends(get_current_user)) -> User:
    if not user.catalog_read_enabled:
        raise HTTPException(status_code=403, detail="Catalog access is not granted.")
    return user
