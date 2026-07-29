# Security and privacy controls

## On-device storage

- SQLite uses the `sqlite3mc` native source selected through Dart build hooks.
- A random 256-bit database key is stored with Android Keystore-backed secure
  storage and iOS Keychain `first_unlock_this_device` accessibility.
- The database is marked as excluded from iOS backup.
- Android Auto Backup and device-transfer extraction are disabled.
- Foreign keys and secure delete are enabled.
- Local notification content is generic by default and does not expose medicine
  names on the lock screen.

## Portable backups

`.medicalbox` files are versioned JSON envelopes. Version 2 encrypts the private
snapshot with AES-256-GCM using a key derived by Argon2id with 19 MiB of memory,
two iterations, and one lane. Authentication tokens are not part of the database
snapshot. Imports authenticate and validate the full envelope before a
transaction replaces local data.

Exports are first created as `medical-box-*.medicalbox` files in the app
temporary directory so the operating-system share sheet can receive them.
Deleting device data also deletes those app-created temporary files. Copies
that the user saves or shares outside the app temporary directory are outside
the app's control and must be deleted separately by the user.

## Server account security

- Account creation and sign-in are required before entering organizer routes.
- Signing out locks the app while preserving encrypted device-local data.
- Identities are keyed by provider and provider subject.
- Email addresses never trigger automatic identity merging.
- Provider tokens are verified and never persisted.
- Access tokens live for 15 minutes.
- Refresh tokens rotate, live for 30 days, and are stored only as hashes.
- Reuse revokes the refresh-token family.
- Account deletion requires a provider reauthentication grant valid for five
  minutes.
- Catalog search, detail, metadata, and DUR endpoints require both a valid
  access token and the database-backed `catalog:read` entitlement.
- Entitlements are checked from the user row on every request, so revocation
  takes effect immediately even when an access token has not expired.
- Production is the only persistent Railway environment. Local and CI tests do
  not receive production database credentials or signing keys.

## Logging boundary

The production container disables Uvicorn access logs. Application code does
not log catalog search query strings, request bodies, or response bodies.
Proxy-level verification before release must still demonstrate that private
household fields never leave the device.

## Advertising boundary

- Only non-personalized banner advertising is permitted.
- The provider-independent adapter receives only an allowlisted placement enum.
- Account identifiers, household data, medicine data, search terms, reminders,
  sharing content, and health-related behavior segments are not valid adapter
  inputs.
- Advertising is disabled by default and cannot block startup or core features.
- Real provider integration is blocked on legal review, disclosure updates,
  sensitive-category configuration, test identifiers, and proxy evidence.
