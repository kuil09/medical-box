# Medical Box legal review packet

## Review status

This document prepares the closed-beta product for external legal review. It is
not legal advice and does not record legal approval. A qualified Korean reviewer
must sign off on every item in the final decision table before external beta
distribution.

The legal-source check was refreshed on 2026-07-27 against:

- Personal Information Protection Act Article 28-8, effective 2025-10-02;
- Medical Devices Act Article 2, effective 2026-07-01;
- Railway's Privacy Policy, effective 2026-04-20; and
- Railway's current Data Processing Addendum.

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
Singapore, while Railway states that its primary processing operations take
place in the United States. Railway Corporation is the processor named in its
DPA, at 548 Market St PMB 68956, San Francisco, California 94104, reachable at
`privacy@railway.com`.

Article 28-8 permits overseas processing necessary to perform a contract when
the prescribed facts are disclosed in the privacy policy or notified to the
data subject. The final notice must identify:

- the transferred account fields;
- Singapore and any additional country in which Railway or an authorized
  subprocessor processes the data;
- transfer timing and method;
- Railway Corporation's name and contact details;
- processing purpose and retention period; and
- the refusal method, procedure, and consequence.

The reviewer must confirm:

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

The HIRA standard-code file is licensed under Korea Open Government License Type
1 and requires attribution. The current file is annual and the portal states
that deleted reimbursement entries remain in the mapping, so the product must
not describe the mapping as proof of current reimbursement eligibility.

## Medical-product classification boundary

The Medical Devices Act definition expressly includes software used for
diagnosis, treatment, mitigation, management, or prevention. The reviewer should
confirm that the implemented organizer and unmodified official-reference
surfaces remain outside that intended-use boundary. Any future feature that
evaluates a person against DUR rules, calculates a dose, identifies a pill with
diagnostic certainty, recommends treatment, or predicts a medical outcome must
trigger a new classification review before implementation.

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
