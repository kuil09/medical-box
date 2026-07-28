# Official Korean Drug Information Review

## Decision

Medical Box should include official product usage and appearance information by
joining three MFDS public-data sources on `itemSeq`. The application must present
the source and source update date, keep household inventory data device-local,
and avoid converting source text into dosage calculations, diagnosis, substitute
drug suggestions, or treatment recommendations.

## Approved source roles

| Source | Portal | Product fields used |
| --- | --- | --- |
| MFDS pharmaceutical product authorization | https://www.data.go.kr/data/15095677/openapi.do | Product name, manufacturer, permit status, ingredient, dosage form appearance, storage method, product image URL |
| MFDS e약은요 consumer information | https://www.data.go.kr/data/15075057/openapi.do | Efficacy, use method, warnings, precautions, interactions, side effects, storage, source update date |
| MFDS medicine identification information | https://www.data.go.kr/data/15057639/openapi.do | Shape, color, front/back imprint, official identification image URL |

The catalog ingestion pipeline normalizes each upstream response in memory,
retains its canonical content hash, and stores only the small allowlist of
source fields required by public API responses. The complete upstream payload
is discarded after a successful normalization. `itemSeq` remains the primary
join key.
As of the 2026-07-26 acquisition checkpoint, the product authorization and
e약은요 services are approved and fully acquired. The e약은요 snapshot contains
4,757 source records for 4,740 unique products. Pill identification is approved and
fully acquired from the provider-published HTTP `Service03` endpoint: 25,349
source rows normalized to 25,349 variants across 25,332 products. The HTTPS route
still returns HTTP 500, so production synchronization must treat the HTTP-only
provider route as a documented transport-security exception and keep the public
data key strictly server-side.

The product-level and ingredient-level DUR applications are also approved and
fully acquired. Sixteen operations returned 863,771 official rows, which
normalized to 863,599 current rules after removing 172 byte-identical duplicate
rows. The normalized snapshot has no missing source-to-rule mappings. DUR remains
reference data: a product detail may show the applicable official caution or
contraindication text, rule category, source, and update date, but the backend
must not evaluate a household member, inventory item, prescription, or reminder
against these rules.

## API shape

`GET /api/v1/drugs/{itemSeq}` exposes:

- authorization appearance text through `appearance`;
- the best available official image URL through `imageUrl`;
- structured identification through `identification.shape`,
  `identification.color`, `identification.imprintFront`,
  `identification.imprintBack`, and `identification.imageUrl`;
- every current pill presentation through `identificationVariants`, preserving
  distinct colors, imprints, dimensions, strengths, and images that share one
  `itemSeq`;
- consumer information without paraphrasing or calculating a dose;
- a category-count safety summary through `safetyOverview`, excluding the
  generic product stream that does not represent a user-facing caution;
- source attribution and update date.

`GET /api/v1/drugs/{itemSeq}/dur-rules` exposes the official DUR rules for one
product. `ruleType` narrows the response to a category and the opaque `cursor`
continues a page. Product detail deliberately returns counts rather than every
rule because a single product can have more than 2,000 current rules. The
Flutter client fetches a category only when the user expands it and presents
the original fields as reference material without evaluating the current
household, member, inventory, prescription, or reminder.

When both authorization and identification sources provide an image, the
compatibility representative identification is preferred because it is intended
for visual pill identification. The product-authorization image remains the
fallback. A client that lets a user identify a physical pill must display all
`identificationVariants` instead of assuming the representative is the only
presentation.

## Image and redistribution policy

The beta application may render an HTTPS URL returned by the official source,
with a visible failure fallback. It must not copy the image into Medical Box
object storage until image redistribution and hotlinking terms are confirmed for
the exact endpoint. When a user selects a pill presentation, its variant key,
appearance summary, and official image URL are stored in the encrypted local
inventory and therefore included in an encrypted `.medicalbox` export. The
binary image is never embedded in the export.

## Privacy and safety constraints

- Drug search, detail, catalog metadata, and DUR routes require an authenticated
  account with the database-backed `catalog:read` entitlement.
- Search terms, request bodies, and response bodies are excluded from
  application logs and analytics.
- Family names, quantities, expiry dates, private notes, appointments, and
  reminder text are never added to catalog requests.
- The application shows official source text as product-reference material only.
- Product detail lists only sources that contributed fields or rules to that
  product, rather than the entire catalog source registry.
- DUR data is stored and may be displayed as official reference material, but it
  must not be combined with household data to generate personalized warnings,
  recommendations, substitute suggestions, or dose decisions.
- Price data may be stored in the catalog after acquisition but must follow the
  same non-personalization boundary.
- Shared messages are assembled on device, require an explicit field selection,
  and show a preview before the operating-system share sheet opens.

## Validation gates

1. Reject a source run when `itemSeq` is missing from a required record.
2. Quarantine only the changed source when field names or response structure
   drift.
3. Preserve the last successful catalog until the complete replacement run
   passes page-count, duplicate-key, required-field, and content-hash checks.
4. Test records with authorization-only images, identification-only images,
   both images, and no images.
5. Verify that the Flutter client renders appearance text and structured
   identification, lets a user select among multiple variants, persists the
   selected variant through encrypted export/import, and tolerates a failed
   remote image.
6. Verify through a proxy that sharing and local inventory CRUD do not contact
   the backend.
7. Verify that expanding a DUR category performs one public paginated lookup
   and that no local member, quantity, expiry, note, appointment, or reminder
   field appears in the request.
