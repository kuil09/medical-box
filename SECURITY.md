# Security Policy

## Supported version

Security fixes are made on the default branch. Closed-beta builds should be
updated to the latest release before reporting a reproducibility problem.

## Report a vulnerability

Do not open a public issue for a suspected vulnerability, leaked credential, or
privacy problem. Use
[GitHub private vulnerability reporting](https://github.com/kuil09/medical-box/security/advisories/new)
instead.

Include:

- the affected commit, endpoint, or app version;
- a minimal reproduction that does not contain personal or production data;
- the expected and observed security boundary; and
- any evidence that a credential or user record was exposed.

Do not access another person's account, inventory, device data, or production
database while testing. Do not include tokens, medicine records, household
names, or signing material in the report.

The maintainers will acknowledge a report as soon as practical, validate the
affected boundary, and coordinate remediation and disclosure through the
private advisory.

## Medical safety

This project is an organizer and reference application. It does not provide
diagnosis, dose calculation, treatment selection, or emergency medical advice.
A medical emergency should be handled through the appropriate local emergency
service, not through a security report.
