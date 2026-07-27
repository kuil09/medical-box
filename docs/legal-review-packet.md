# Medical Box legal review packet

## Review status

This document prepares the closed-beta product for external legal review. It is
not legal advice and does not record legal approval. A qualified Korean reviewer
must sign off on every item in the final decision table before external beta
distribution.

## Product boundary

Medical Box is a device-local household medicine organizer with an optional
account. Household members, containers, quantities, expiry dates, notes, visit
plans, and reminder content remain in the encrypted device database. The server
stores only account identities, refresh-session hashes, terms acceptances,
catalog permissions, and official public medicine catalog records.

Official catalog lookup requires an authenticated account with the explicit
`catalog:read` permission. The app does not diagnose, calculate a dose, recommend
treatment, evaluate an individual against DUR rules, or suggest substitute
medicines. Prescription-related features are limited to visit and renewal
preparation.

## User-facing medicine language

The reviewer should confirm that the following product rules are sufficient:

1. Official source text is labeled as reference information.
2. Efficacy and use-method fields are displayed without dose calculation or
   personalized interpretation.
3. DUR rules are shown by official category and source, without matching them to
   a household member, prescription, inventory item, or reminder.
4. Appearance and pill-identification images are not represented as a diagnosis
   or as proof of a medicine's identity.
5. Shared messages are created on device, require an explicit field selection,
   and show a preview before the operating-system share sheet opens.
6. Emergency sharing copy tells recipients to verify the medicine and seek
   professional help when needed.

## Personal information and cross-border processing

The optional account may contain provider subject, provider name, display name,
and email address. Railway hosts the account and public catalog database in
Singapore. The reviewer must confirm:

- the legal basis and required consent or notice for transferring this minimal
  account information to Singapore;
- the processor, destination country, transferred fields, purpose, retention
  period, and refusal consequences shown in the privacy notice;
- whether provider-specific disclosures are required for Kakao, Apple, and
  Google sign-in;
- whether the account deletion process and retention language match the actual
  immediate deletion behavior;
- whether terms acceptance versioning and re-consent rules are sufficient.

No household inventory field is intended to cross the device boundary. A proxy
capture remains required evidence for this implementation claim.

## Public data and image rights

The reviewer should confirm source-specific attribution and redistribution terms
for MFDS and HIRA records. Pill image binaries are not copied to owned storage.
The app renders source-provided URLs with a failure fallback. The review must
determine whether hotlinking and local encrypted storage of a selected image URL
and appearance summary are permitted.

## Store and account deletion disclosures

The support and account-deletion pages must explain:

- the difference between deleting only the optional server account and deleting
  both the account and device-local organizer data;
- that deleting device data alone does not delete the optional account;
- that uninstalling the app removes device-local data because backup and device
  transfer are disabled;
- that an account deletion requires recent provider reauthentication;
- how a user without app access can request help.

## Reviewer decision table

| Area | Required reviewer decision | Evidence |
| --- | --- | --- |
| Medicine wording | Approve or provide required edits | App screenshots and official detail views |
| Medical-device boundary | Confirm the organizer/reference positioning | Architecture and feature inventory |
| Singapore transfer | Approve notice, consent, and retention language | Privacy page and server schema |
| Social login | Approve provider disclosures and terms | Provider console configuration and login screens |
| Account deletion | Approve scope choices and support process | Reauthentication and deletion recordings |
| Public data | Approve attribution, reuse, and image-link behavior | Catalog metadata and source registry |
| Emergency sharing | Approve selected-field preview and safety copy | Share preview recordings |

External beta promotion remains blocked until the reviewer records a dated
decision, reviewer identity, jurisdiction, required edits, and final approval.
