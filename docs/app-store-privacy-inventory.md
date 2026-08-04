# App Store privacy inventory

Evidence date: 2026-07-30

This inventory maps the current production code to App Store Connect privacy
labels. It is an engineering evidence document, not a legal approval. The final
questionnaire must remain unpublished until the unresolved processor and SDK
items below are reviewed.

## Data transmitted and retained

| Data | Destination | Retention and linkage | Purpose | Proposed App Store category |
| --- | --- | --- | --- | --- |
| Provider subject and provider name | Medical Box API | Retained until account deletion and linked to the account | Authentication and account management | Identifiers → User ID |
| Internal account ID | Medical Box API | Retained until account deletion and linked to the account | Authentication, authorization, and account management | Identifiers → User ID |
| Email address, when supplied by the provider | Medical Box API | Retained until account deletion and linked to the account | Authentication and account management | Contact Info → Email Address |
| Display name, when supplied by the provider | Medical Box API | Retained until account deletion and linked to the account | Account display | Contact Info → Name |
| Terms version and acceptance time | Medical Box API | Retained until account deletion and linked to the account | Compliance and account management | Review required; no exact first-party label is assumed |
| Refresh-token hash, session family, expiry, and operating-system label | Medical Box API | Retained for session lifecycle and linked to the account | Authentication and security | Identifiers → User ID; review whether the session metadata needs an additional label |

Raw provider tokens are validated but not stored. Refresh tokens are stored only
as hashes. The mobile client stores access and refresh tokens in platform secure
storage.

## Data transmitted but not retained by the application

Authenticated catalog requests transmit the search query or public `itemSeq` to
the Medical Box API. API access logging is disabled and the server application
does not persist query strings, request bodies, response bodies, or analytics
events. The query is used only to produce the requested catalog response.

The mobile client does not persist search queries. It stores bounded,
account-scoped copies of official detail and DUR responses, plus official image
binaries, in the encrypted local database to reduce repeated downloads.

The App Store definition of collection and the infrastructure provider's
short-lived network/security logs must be checked together before declaring
that search data is not collected.

## Data kept on the device

The following data stays in the encrypted local database or local platform
services and is not synchronized to the Medical Box API:

- household and member names;
- containers, medicines, first-aid supplies, notes, and use-by dates;
- user-captured photos and OCR input;
- bounded official medicine detail, DUR, and image caches;
- reminders, visit dates, and notification content;
- encrypted export archives unless the user explicitly shares them.

The official caches are excluded from `.medicalbox` exports and are removed
when device data is deleted. Account deletion removes entries scoped to that
account. The camera/OCR flow deletes its temporary capture after processing.
Sharing and export are explicit user actions to a destination selected by the
user.

## SDK and processor review

The current app contains Apple, Google, and Kakao authentication SDKs. It does
not contain an advertising, analytics, crash-reporting, or attribution SDK.
Advertising is disabled.

Before publishing the privacy questionnaire:

1. Verify the current Apple privacy manifests and data-use disclosures for each
   enabled authentication SDK version.
2. Confirm whether Railway edge, abuse-prevention, and security logs retain IP
   addresses or request metadata, and map any retained fields.
3. Confirm that no provider is enabled in a store build until its account
   deletion and reauthentication lifecycle has passed end-to-end testing.
4. Run a release-build proxy capture and verify that household data, medicine
   names, photos, notes, dates, and notification content never reach the API.
5. Re-run this inventory before enabling advertising, analytics, diagnostics,
   cloud backup, or family synchronization.

## Recommended unpublished draft

Based on current first-party storage, the minimum draft is:

- Data linked to the user:
  - Contact Info: Name, Email Address — App Functionality.
  - Identifiers: User ID — App Functionality.
- Tracking: No.

This recommendation must not be published until the SDK and processor review is
complete.
