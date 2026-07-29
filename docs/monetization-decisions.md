# Monetization decisions

Decision date: 2026-07-29

This document supersedes earlier product language that described accounts as
optional or the organizer as anonymously usable.

## Confirmed product policy

- Account creation and sign-in are required before the application can be used.
- Core household medicine management and official medicine safety information
  remain free.
- Medicine counts are never capped and safety information is never paywalled.
- Free accounts may see non-personalized banner ads only.
- Interstitial and rewarded ads are prohibited.
- Health information, catalog queries, household data, and account identifiers
  must not be used for ad targeting.
- The first paid product will be a lifetime ad-removal purchase with store
  restoration. The final price is not yet decided.
- Family Plus may be sold only after opt-in end-to-end encrypted sync and real
  recurring family services exist.

The initial household boundary is one owner, up to five invited sign-in users,
up to ten managed member profiles, one shared medicine box, and one personal
pouch per managed profile. Medicine counts remain unlimited. These numeric
limits may change after observing real use.

## Access tiers

The client domain uses three provider-independent access tiers:

- `free_with_ads`
- `ad_free_lifetime`
- `family_plus`

No store receipt endpoint or purchase UI is active until the store products,
final price, verification provider, offline grace period, and restoration
behavior are approved.

## Ad placement boundary

Banner ads may appear only:

- after the home summary;
- at the end of the inventory list; or
- at the bottom of the general settings area.

Ads are prohibited in onboarding, account, reauthentication, medicine-box
interaction, mutation forms, quantity controls, official medicine detail,
usage and DUR information, renewal preparation, sharing, deletion, backup,
restore, and error surfaces. Every visible banner must have an `광고` label and
reserve its layout height before provider content appears.

The application isolates any future advertising SDK behind a banner adapter.
The adapter receives only an allowlisted placement enum. It has no parameter
for a user, account, household, medicine, search term, member, reminder, share
content, or local behavior segment. A build-time kill switch defaults to off,
and the disabled adapter makes advertising failure independent of app startup
and core features.

## Privacy and safety

An advertising request must never include:

- an email, provider identity, internal user identifier, or family identity;
- household members, inventory, medicine names, search terms, quantities,
  expiry dates, notes, visits, reminders, selected appearance, or shared text;
  or
- a segment inferred from health-related behavior inside the app.

Initial advertising must be non-personalized. If a future provider links app
data with other companies' apps or websites, the iOS build must request ATT
authorization without restricting free features when authorization is denied.
Proxy validation must demonstrate zero health or account identifiers in ad
requests before advertising is enabled.

The ad platform must block medicine and supplement, weight-loss, sexual and
reproductive health, consumer lending, gambling, alcohol, dating, political,
sexualized, shock, fear, and misleading health categories. Automated blocking
does not replace recurring creative review.

## Local-data boundary and Family Plus

Account identity is currently used for app access, catalog authorization, and
future purchase restoration. Household, inventory, notes, visits, and reminders
remain encrypted and device-local.

Family Plus sync is not implemented or sold. It requires a separate explicit
decision and user consent. Any future server copy must be end-to-end encrypted
so the operator cannot read household or inventory content. Plaintext sync is
not an acceptable intermediate implementation.

## Unresolved decisions

- Advertising provider
- Final lifetime ad-removal price
- Family Plus price and release date
- Free trial
- End-to-end encrypted sync design
- Whether advertising launches on iOS and Android simultaneously

## Release gates

Before enabling real ads or purchases:

1. Complete legal and store-policy review of mandatory account use.
2. Select the provider and document its exact data collection and processors.
3. Update the privacy policy and store privacy disclosures.
4. Validate test ad identifiers in development and production identifiers only
   in protected release configuration.
5. Proxy-test every allowed placement and prove that prohibited data is absent.
6. Configure sensitive-category blocks and establish creative review ownership.
7. Add server-side store receipt verification, purchase restoration, and an
   evidence-backed offline entitlement grace period.
