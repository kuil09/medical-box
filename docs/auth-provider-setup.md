# Social login provider setup

The source supports Kakao, Apple, and Google identity-token exchange. Provider
console configuration is required before the flows can complete.

## Shared requirements

- Register the exact application identifier `com.medicalbox.app`.
- Configure production and staging OAuth/OIDC clients separately where the
  provider supports it.
- Register only `medicalbox.outoftokens.ai` and
  `staging.medicalbox.outoftokens.ai` callback/link origins.
- Never commit provider secrets, service files, signing keys, or certificate
  fingerprints.

## Apple

- Enable Sign in with Apple and Associated Domains for the app identifier.
- Set `APPLE_TEAM_ID` and keep `APPLE_CLIENT_ID=com.medicalbox.app`.
- Verify `/.well-known/apple-app-site-association` after deployment.

## Google

- Create iOS and Android OAuth clients for the exact bundle/application ID.
- Add the release signing certificate fingerprint.
- Add platform configuration files locally or through the protected CI secret
  workflow.
- Set the backend `GOOGLE_CLIENT_ID` to the audience accepted by the exchange
  endpoint.

## Kakao

- Enable OpenID Connect; the Flutter client requires an ID token.
- Register Android key hashes and the iOS bundle identifier.
- Inject `KAKAO_NATIVE_APP_KEY` with `--dart-define`.
- Set backend `KAKAO_APP_ID` to the expected OIDC audience.

Provider success, cancellation, expiry, forged signature, and wrong-audience
cases must all be tested on both platforms before external beta.

## Closed-beta catalog access

Authentication does not grant catalog access by itself. New accounts start
without permissions. Add verified beta emails to the environment-specific
`CATALOG_ACCESS_EMAIL_ALLOWLIST`, or grant one existing account by exact user
ID with `medical-box-access grant <user-id>`. The API returns `401` without a
valid access token and `403` when the authenticated account lacks
`catalog:read`.
