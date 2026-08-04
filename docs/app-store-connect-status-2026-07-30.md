# App Store Connect release status

Evidence date: 2026-07-30

## Saved in App Store Connect

- App name: `우리집 구급키트`
- App version: `1.0`
- Subtitle: `가족 약과 구급용품을 기기 안에서 정리`
- Primary category: Medical
- Secondary category: Lifestyle
- Age rating questionnaire: completed with a calculated `16+` rating
  - Medical or treatment information: Frequent
  - Advertising: No
  - Messaging, social, user-generated content, gambling, sexual content,
    violence, alcohol, tobacco, and drug-use depictions: No or None
- Privacy policy URL:
  `https://medicalbox.outoftokens.ai/privacy`
- TestFlight build 5 export-compliance questionnaire:
  - Standard encryption in addition to Apple operating-system encryption
  - France distribution excluded from that build declaration
- TestFlight build 5 beta description, feedback email, marketing URL, privacy
  URL, review contact name/email, review notes, and Korean test instructions
- Internal Testers group contains builds 3, 4, and 5

## Prepared but not saved

The version 1.0 page is populated in the active App Store Connect browser
session with:

- promotional text;
- full Korean description;
- keywords;
- support and marketing URLs;
- copyright;
- review contact name and email;
- review notes;
- build 5 selection.

App Store Connect rejects the page-wide save until a valid review contact phone
number is supplied. No number was guessed or substituted.

## External evidence still required

1. Provide a valid App Review contact phone number and a disposable review
   account that can complete the mandatory login flow.
2. Capture current release-build iPhone and iPad screenshots. Build 5 declares
   device family `1,2`, so the iPad product-page requirement must not be ignored.
3. Review and publish the privacy questionnaire using
   `docs/app-store-privacy-inventory.md`.
4. Make the content-rights declaration after official-data and image
   redistribution review.
5. Make the regulated-medical-device declaration required by the Medical
   category and age questionnaire.
6. Complete the EU Digital Services Act trader-status declaration, or explicitly
   remove EU distribution.
7. Decide App Store availability and release behavior. Public review submission
   remains intentionally untouched.
8. Add the free starting price and select the intended countries or regions.
   App Store Connect currently has neither a starting price nor availability
   configured.
9. Complete real Apple sign-in, reauthentication, and disposable-account
   deletion testing before exposing Apple sign-in.
10. Make the final export-classification decision for the app-level
   `ITSAppUsesNonExemptEncryption` declaration. Build 5's beta questionnaire is
   complete, but the app-level documentation choice must not be guessed.

## Tester boundary

`cloud2365@naver.com` is not currently selectable in the Internal Testers group.
App Store Connect shows only the account owner as an eligible internal tester.
The invited address must first accept the App Store Connect team invitation and
become an eligible team user before it can be added to the internal group.
