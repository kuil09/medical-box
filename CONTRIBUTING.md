# Contributing

Thank you for helping improve Medical Box.

## Before opening a pull request

1. Create a focused branch from `main`.
2. Keep code, comments, commit messages, and repository documentation in
   English. User-facing application copy remains Korean.
3. Do not commit credentials, signing files, environment files, production
   exports, medicine database dumps, or personal health information.
4. Preserve the privacy boundary: household, member, inventory, reminder, and
   visit data remain encrypted and device-local.
5. Preserve the medical-safety boundary: do not add diagnosis, dose
   calculation, treatment recommendations, or replacement-medicine
   suggestions.
6. Add or update tests for behavior changes.

## Verification

Run the checks relevant to the changed area:

```bash
make backend-check
make flutter-check
make prototype-check
```

Changes to `.github/workflows`, `.railway`, authentication, authorization,
encryption, account deletion, catalog ingestion, or data attribution require
maintainer review.

## Security and privacy reports

Follow `SECURITY.md`. Never place vulnerability details or sensitive values in
a public issue or pull request.

## Licensing

Contributions intentionally submitted for inclusion are licensed under the
Apache License 2.0. Third-party assets and public data remain subject to their
own terms as described in `THIRD_PARTY_NOTICES.md`.
