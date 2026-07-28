from __future__ import annotations

import base64
import binascii
from datetime import UTC, datetime, timedelta
from typing import Protocol, cast

import httpx
import jwt
from fastapi import HTTPException, Request

from .config import Settings, get_settings
from .providers import ProviderValidator, VerifiedProviderIdentity

APPLE_AUDIENCE = "https://appleid.apple.com"
APPLE_TOKEN_URL = f"{APPLE_AUDIENCE}/auth/token"
APPLE_REVOKE_URL = f"{APPLE_AUDIENCE}/auth/revoke"


def _try_apple_client_secret(settings: Settings) -> str | None:
    team_id = settings.apple_team_id
    key_id = settings.apple_sign_in_key_id
    encoded_private_key = settings.apple_sign_in_private_key_base64
    if not team_id or not key_id or encoded_private_key is None:
        return None
    try:
        private_key = base64.b64decode(
            "".join(encoded_private_key.get_secret_value().split()),
            validate=True,
        )
        now = datetime.now(UTC)
        return jwt.encode(
            {
                "iss": team_id,
                "iat": now,
                "exp": now + timedelta(minutes=5),
                "aud": APPLE_AUDIENCE,
                "sub": settings.apple_client_id,
            },
            private_key,
            algorithm="ES256",
            headers={"kid": key_id},
        )
    except (binascii.Error, jwt.PyJWTError, TypeError, ValueError):
        return None


def _apple_client_secret(settings: Settings) -> str:
    if not settings.apple_account_revocation_configured:
        raise HTTPException(
            status_code=503,
            detail="Apple account revocation is not configured.",
        )
    client_secret = _try_apple_client_secret(settings)
    if client_secret is None:
        raise HTTPException(
            status_code=503,
            detail="Apple account revocation key is invalid.",
        )
    return client_secret


def validate_apple_revocation_configuration(settings: Settings) -> None:
    _apple_client_secret(settings)


def _json_object(response: httpx.Response) -> dict[str, object] | None:
    try:
        payload = response.json()
    except ValueError:
        return None
    return cast(dict[str, object], payload) if isinstance(payload, dict) else None


def _validate_apple_identity(
    validator: ProviderValidator,
    id_token: str,
) -> VerifiedProviderIdentity | None:
    try:
        return validator.validate("apple", id_token)
    except HTTPException:
        return None


class AppleAuthorizationRevoker(Protocol):
    def revoke(
        self,
        *,
        provider_subject: str,
        authorization_code: str,
        validator: ProviderValidator,
    ) -> None: ...


class OfficialAppleAuthorizationRevoker:
    def __init__(
        self,
        settings: Settings,
        *,
        client: httpx.Client | None = None,
    ) -> None:
        self.settings = settings
        self.client = client

    def revoke(
        self,
        *,
        provider_subject: str,
        authorization_code: str,
        validator: ProviderValidator,
    ) -> None:
        client_secret = self._client_secret()
        token_response = self._post(
            APPLE_TOKEN_URL,
            data={
                "client_id": self.settings.apple_client_id,
                "client_secret": client_secret,
                "code": authorization_code,
                "grant_type": "authorization_code",
            },
        )
        token_payload = _json_object(token_response)
        if token_payload is None:
            token_response.close()
            del token_response
            raise HTTPException(
                status_code=502,
                detail="Apple returned an invalid token response.",
            )

        id_token = token_payload.get("id_token")
        refresh_token = token_payload.get("refresh_token")
        access_token = token_payload.get("access_token")
        if not isinstance(id_token, str) or not id_token:
            raise HTTPException(
                status_code=502,
                detail="Apple did not return an identity token.",
            )
        verified = _validate_apple_identity(validator, id_token)
        if verified is None:
            raise HTTPException(
                status_code=502,
                detail="Apple returned an unverifiable identity token.",
            )
        if verified.subject != provider_subject:
            raise HTTPException(
                status_code=403,
                detail="Apple authorization belongs to another account.",
            )

        if isinstance(refresh_token, str) and refresh_token:
            revocation_token = refresh_token
            token_type_hint = "refresh_token"
        elif isinstance(access_token, str) and access_token:
            revocation_token = access_token
            token_type_hint = "access_token"
        else:
            raise HTTPException(
                status_code=502,
                detail="Apple did not return a revocable token.",
            )

        self._post(
            APPLE_REVOKE_URL,
            data={
                "client_id": self.settings.apple_client_id,
                "client_secret": client_secret,
                "token": revocation_token,
                "token_type_hint": token_type_hint,
            },
        )

    def _client_secret(self) -> str:
        return _apple_client_secret(self.settings)

    def _post(self, url: str, *, data: dict[str, str]) -> httpx.Response:
        response: httpx.Response | None = None
        try:
            if self.client is not None:
                response = self.client.post(url, data=data)
            else:
                with httpx.Client(timeout=10.0) as client:
                    response = client.post(url, data=data)
        except httpx.HTTPError:
            # Raise only after leaving the exception handler. HTTPX exceptions
            # retain their request body, which contains Apple credentials.
            pass
        if response is None or not 200 <= response.status_code < 300:
            raise HTTPException(
                status_code=502,
                detail="Apple account revocation failed.",
            )
        return response


def get_apple_authorization_revoker(request: Request) -> AppleAuthorizationRevoker:
    revoker = getattr(request.app.state, "apple_authorization_revoker", None)
    if revoker is not None:
        return cast(AppleAuthorizationRevoker, revoker)
    return OfficialAppleAuthorizationRevoker(get_settings())
