from dataclasses import dataclass
from typing import Protocol, cast

import jwt
from fastapi import HTTPException, Request

from .config import Settings, get_settings


@dataclass(frozen=True)
class VerifiedProviderIdentity:
    subject: str
    email: str | None
    display_name: str | None


class ProviderValidator(Protocol):
    def validate(self, provider: str, token: str) -> VerifiedProviderIdentity: ...


class OfficialProviderValidator:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    def validate(self, provider: str, token: str) -> VerifiedProviderIdentity:
        if provider == "google":
            return self._validate_oidc(
                token=token,
                jwks_url="https://www.googleapis.com/oauth2/v3/certs",
                audience=self._required(self.settings.google_client_id, "GOOGLE_CLIENT_ID"),
                issuers={"accounts.google.com", "https://accounts.google.com"},
            )
        if provider == "apple":
            return self._validate_oidc(
                token=token,
                jwks_url="https://appleid.apple.com/auth/keys",
                audience=self.settings.apple_client_id,
                issuers={"https://appleid.apple.com"},
            )
        if provider == "kakao":
            return self._validate_oidc(
                token=token,
                jwks_url="https://kauth.kakao.com/.well-known/jwks.json",
                audience=self._required(self.settings.kakao_app_id, "KAKAO_APP_ID"),
                issuers={"https://kauth.kakao.com"},
            )
        raise HTTPException(status_code=404, detail="Unsupported identity provider.")

    def _validate_oidc(
        self,
        *,
        token: str,
        jwks_url: str,
        audience: str,
        issuers: set[str],
    ) -> VerifiedProviderIdentity:
        try:
            signing_key = jwt.PyJWKClient(jwks_url, cache_keys=True).get_signing_key_from_jwt(token)
            claims = jwt.decode(
                token,
                signing_key.key,
                algorithms=["RS256"],
                audience=audience,
                options={"require": ["exp", "iat", "sub", "iss"]},
            )
        except jwt.PyJWTError as exc:
            raise HTTPException(
                status_code=401, detail="Provider token verification failed."
            ) from exc
        if claims.get("iss") not in issuers:
            raise HTTPException(status_code=401, detail="Provider token issuer is invalid.")
        return VerifiedProviderIdentity(
            subject=str(claims["sub"]),
            email=claims.get("email"),
            display_name=claims.get("name") or claims.get("nickname"),
        )

    @staticmethod
    def _required(value: str | None, name: str) -> str:
        if not value:
            raise HTTPException(status_code=503, detail=f"{name} is not configured.")
        return value


def get_provider_validator(request: Request) -> ProviderValidator:
    validator = getattr(request.app.state, "provider_validator", None)
    if validator is not None:
        return cast(ProviderValidator, validator)
    return OfficialProviderValidator(get_settings())
