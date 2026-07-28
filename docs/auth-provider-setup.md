# Social login provider setup

The source supports Kakao, Apple, and Google identity-token exchange. Provider
console configuration is required before the flows can complete.

## Shared requirements

- Register the exact application identifier `com.medicalbox.app`.
- Configure the production OAuth/OIDC clients.
- Register only `medicalbox.outoftokens.ai` as the callback/link origin.
- Keep the app `currentTermsVersion`, backend `TERMS_VERSION`, and published
  `/terms` document version synchronized. The login buttons remain disabled
  until the user explicitly confirms the current terms and privacy notice, and
  the API rejects a missing, false, or stale acceptance before account creation.
- Never commit provider secrets, service files, signing keys, or certificate
  fingerprints.

## Apple

- Enable Sign in with Apple and Associated Domains for the app identifier.
- Set `APPLE_TEAM_ID` and keep `APPLE_CLIENT_ID=com.medicalbox.app`.
- Create a Sign in with Apple private key, then configure its identifier as
  `APPLE_SIGN_IN_KEY_ID` and the base64-encoded `.p8` contents as the secret
  `APPLE_SIGN_IN_PRIVATE_KEY_BASE64`. The API uses this key only to exchange
  the deletion-time authorization code and revoke the resulting Apple token.
  It never stores the authorization code or provider token.
- Verify `/.well-known/apple-app-site-association` after deployment.
- The current mobile implementation offers native Apple sign-in only on iOS.
  Android hides and rejects Apple sign-in because there is no Apple Service ID
  web-authentication flow. Do not reuse the iOS app identifier as an Android
  web client.
- Enabling Apple sign-in on Android requires a registered Apple Service ID,
  verified web domain and return URL, state and nonce validation, an explicit
  `WebAuthenticationOptions` implementation, and Android integration tests.
  The platform capability gate must remain closed until that complete flow
  exists.

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

## Provider lifecycle during account deletion

The mobile client obtains a fresh provider proof before requesting the
five-minute server reauthentication grant. Google uses an interactive
`authenticate()` call and then `disconnect()`. Kakao always uses the account
flow with `Prompt.login` and then calls `unlink()`. Provider cleanup occurs
before deleting the server account so a cleanup failure leaves the server
account and app session available for a safe retry.

Apple returns both an ID token and a short-lived authorization code. The client
sends the ID token to the reauthentication endpoint and sends the code as
`appleAuthorizationCode` in the `DELETE /api/v1/me` JSON body so the server can
perform Apple revocation as part of deletion. The client rejects a missing
authorization code before any server mutation.

The app clears its access and refresh tokens only after every required provider
and server step succeeds. Ordinary logout is intentionally different: server
logout and provider logout are best-effort, Kakao uses `logout()` rather than
`unlink()`, and local tokens are always cleared.

`services/backend/scripts/verify_well_known_metadata.py` validates downloaded
production metadata without making a network request. It rejects the
`UNCONFIGURED` Apple app ID, an absent app target, empty Android fingerprint
lists, malformed SHA-256 fingerprints, and wildcard Apple paths. Verified app
links are limited to `/app`, `/app/inventory`, `/app/reminders`,
`/app/settings`, and `/app/login`; privacy, terms, support, account deletion,
and API paths always remain web routes. The production monitor downloads both
well-known documents and runs this semantic gate after the HTTP probes.

The protected `Mobile release build` workflow injects provider configuration
into signed store artifacts and fails before compilation when any required
provider value is absent. See `docs/mobile-release-runbook.md` for the signing
and artifact boundary.

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
