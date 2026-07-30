# Store metadata

`metadata/ko-KR` contains the reviewed source copy for the first closed-beta
listing. Keep the store consoles synchronized with these files so wording
changes remain reviewable.

Run `.github/scripts/validate-store-metadata.sh` before editing a store console.
The validator checks required files, platform character limits, HTTPS URLs,
mandatory-account wording, account-deletion review notes, and stale
optional-login claims. Store-only pull requests run this small check without
starting backend, Flutter, or prototype jobs.

The publishable support URL is backed by the public contact address
`medicalbox@outoftokens.ai`. Keep that address synchronized with store-console
support contact fields. Store-installed screenshots, Play App Signing
fingerprints, privacy questionnaires, content ratings, tester groups, and review
decisions remain console evidence and must be recorded in
`docs/closed-beta-release-evidence.md`.

The copy intentionally avoids diagnosis, dosage, substitution, adherence, or
treatment claims. Legal approval is still required before external beta.
