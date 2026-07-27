# Social login provider setup

The source supports Kakao, Apple, and Google identity-token exchange. Provider
console configuration is required before the flows can complete.

## Shared requirements

- Register the exact application identifier `com.medicalbox.app`.
- Configure the production OAuth/OIDC clients.
- Register only `medicalbox.outoftokens.ai` as the callback/link origin.
- Never commit provider secrets, service files, signing keys, or certificate
  fingerprints.

## Apple

- Enable Sign in with Apple and Associated Domains for the app identifier.
- Set `APPLE_TEAM_ID` and keep `APPLE_CLIENT_ID=com.medicalbox.app`.
- Verify `/.well-known/apple-app-site-association` after deployment.

## Google

- Create one Web OAuth client for the backend audience and separate iOS and
  Android OAuth clients for the exact bundle/application ID.
- Add the release signing certificate fingerprint.
- Inject the Web client ID with
  `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
- Inject the iOS client ID in iOS builds with
  `--dart-define=GOOGLE_IOS_CLIENT_ID=...`.
- Set the backend `GOOGLE_CLIENT_ID` to the same Web client ID used as
  `GOOGLE_SERVER_CLIENT_ID`.

## Kakao

- Enable OpenID Connect; the Flutter client requires an ID token.
- Register Android key hashes and the iOS bundle identifier.
- Provide `KAKAO_NATIVE_APP_KEY` as a Gradle environment variable for the
  Android callback scheme and inject the same value with
  `--dart-define=KAKAO_NATIVE_APP_KEY=...`.
- Set backend `KAKAO_APP_ID` to the expected OIDC audience.

Provider success, cancellation, expiry, forged signature, and wrong-audience
cases must all be tested on both platforms before external beta.

After a provider console is configured, run the deployment probe with a
short-lived ID token from an operator-controlled beta account. Keep every token
in the process environment and never place one on the command line or in a
shell-history file:

```bash
MEDICAL_BOX_API_BASE_URL=https://medicalbox.outoftokens.ai/api \
MEDICAL_BOX_AUTH_PROVIDER=google \
MEDICAL_BOX_PROVIDER_TOKEN=... \
MEDICAL_BOX_EXPECT_CATALOG_ACCESS=true \
uv run python scripts/verify_deployed_auth.py
```

The probe exchanges the provider token, verifies the account profile and
catalog entitlement, rotates the refresh token, and logs out. It never prints
provider or session tokens.

## Closed-beta catalog access

Authentication does not grant catalog access by itself. New accounts start
without permissions. Add verified beta emails to the environment-specific
`CATALOG_ACCESS_EMAIL_ALLOWLIST`, or grant one existing account by exact user
ID with `medical-box-access grant <user-id>`. The API returns `401` without a
valid access token and `403` when the authenticated account lacks
`catalog:read`.
