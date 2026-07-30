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
- Keep the backend `APPLE_SIGN_IN_ENABLED` unset or `false` until the complete
  account-deletion path passes production E2E. Set it to `true` only together
  with the revocation credentials below; an enabled mobile artifact cannot
  bypass this independent API gate.
- Create a Sign in with Apple private key, then configure its identifier as
  `APPLE_SIGN_IN_KEY_ID` and the base64-encoded `.p8` contents as the secret
  `APPLE_SIGN_IN_PRIVATE_KEY_BASE64`. The API uses this key only to exchange
  the deletion-time authorization code and revoke the resulting Apple token.
  It never stores the authorization code or provider token.
- Verify `/.well-known/apple-app-site-association` after deployment.
- The mobile implementation can offer native Apple sign-in only on iOS, and
  hides it there by default. The signed iOS workflow enables it only after the
  protected feature request and account-revocation readiness attestation are
  both true. The production API independently requires its
  `APPLE_SIGN_IN_ENABLED=true` gate and complete revocation configuration.
  Android always hides and rejects Apple sign-in because there
  is no Apple Service ID web-authentication flow. Do not reuse the iOS app
  identifier as an Android web client.
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
flow with `Prompt.login` and then calls `unlink()`. After reauthentication, the
client deletes the server account first, clears its local session second, and
then attempts Google or Kakao provider cleanup on a best-effort basis. A
provider-cleanup failure cannot resurrect the deleted server account and is
returned as an explicit result so the UI can direct the user to the provider's
account settings.

Apple returns both an ID token and a short-lived authorization code. The client
sends the ID token to the reauthentication endpoint and sends the code as
`appleAuthorizationCode` in the `DELETE /api/v1/me` JSON body so the server can
perform Apple revocation as part of deletion. The client rejects a missing
authorization code before any server mutation.

Once the server confirms deletion, the app reports server deletion as complete
even if secure local-token cleanup fails, and shows a separate device-session
warning. Ordinary logout clears local tokens first, then treats server logout
and provider logout as best-effort; Kakao uses `logout()` rather than `unlink()`.

`services/backend/scripts/verify_well_known_metadata.py` validates downloaded
production metadata without making a network request. It rejects the
`UNCONFIGURED` Apple app ID, an absent app target, empty Android fingerprint
lists, malformed SHA-256 fingerprints, wildcard Apple paths, and values that do
not exactly match the expected production identifiers. A manual production
monitor dispatch requires the exact Apple app ID and Play App Signing SHA-256
fingerprint as workflow inputs and runs the semantic release gate.
Verified app links are limited to `/app`, `/app/inventory`, `/app/reminders`,
`/app/settings`, and `/app/login`; privacy, terms, support, account deletion,
and API paths always remain web routes. The production monitor downloads both
well-known documents. It is manual-only until the external Apple and Play
identifiers exist, so no unconfigured scheduled job can appear green without
running the exact semantic gate. After both identifiers are confirmed, add a
schedule only in the same reviewed change that stores the fixed expected values
and proves one exact manual run.

The protected `Mobile signed-build verification` workflow injects provider
configuration into ephemeral signed store outputs and fails before compilation
when any required provider value is absent. It persists no signed AAB or IPA as
a GitHub Actions artifact. See `docs/mobile-release-runbook.md` for the signing
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

Every registered account starts with `catalog:read` because official catalog
search is a free member feature. Operators can revoke one exact account with
`medical-box-access revoke <user-id>` and restore it with
`medical-box-access grant <user-id>`. A later provider sign-in does not undo an
explicit revocation. The API returns `401` without a valid access token and
`403` for an explicitly revoked account.
