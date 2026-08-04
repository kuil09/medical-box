# Storage Surface Design QA

## Evidence

- Source visual truth: `public/assets/prototype/selected-storage-surface.png`
- Implementation screenshot: `qa-storage-surface-pass2.png`
- Readiness-map implementation: `public/qa/readiness-map-implementation.png`
- Full browser screenshot: `qa-storage-surface-pass2-whole.png`
- Combined comparison: `qa-storage-surface-comparison.png`
- Readiness-map comparison: `qa-readiness-comparison.png`
- Readiness-area source: `public/qa/readiness-area-picker-before.png`
- Readiness-area implementation:
  `public/qa/readiness-area-picker-after.png`
- Readiness-area comparison: `qa-readiness-area-comparison.png`
- Target viewport: 393 × 852 CSS px, iPhone runtime
- Source pixels: 853 × 1844
- Implementation capture pixels: 273 × 591 at runtime scale 0.694215
- Density normalization: both images are rendered at 393 × 852 in
  `public/qa-storage-surface-comparison.html`
- State: signed-in home, shared chest open, four stored items, two review
  states, and fourteen household readiness spaces
- Scoped user directives: replace the Korean user-facing term `약장` with
  `구급상자`; show a broad, real-life set of empty household medicine and
  first-aid categories as visible spaces
- Category grounding: current Korean Ministry of Health and Welfare
  safety-medicine classifications plus public-health household kit guidance
  from NHS England and MedlinePlus

## Full-view Comparison

The selected visual and implementation use the same hierarchy: centered title,
family scope rail inside the lid, visible hinges, horizontal compartment rows,
one contextual add action, a close control, and three-item bottom navigation.
The app-owned content preserves the source's warm off-white background, white
cabinet surfaces, near-black text, red review state, and green normal state.
The prototype's status bar, device bezel, and home indicator are runtime-owned
chrome and are excluded from fidelity findings.

The readiness refinement intentionally changes the source's title and inserts a
compact compartment map before the stored-item rows. The map separates ten
medicine categories from four first-aid-supply categories, marks registered and
empty spaces without inventing products, and preserves the selected physical
lid, hinge, rim, and storage-surface structure.

## Focused Comparison

The cabinet lid and compartment body are readable in
`qa-storage-surface-comparison.png`, so a separate crop was not needed. The
comparison confirms the selected tab underline, two-row pain compartment,
single-row digestion and wound compartments, item chevrons, add row, and
physical rim/hinge depth.

## Findings

- No actionable P0, P1, or P2 mismatch remains.
- [P3] The prototype uses the closest available Radix icons rather than the
  exact generated pictograms. This preserves a consistent production icon
  family and does not change meaning or hierarchy.
- [P3] The prototype uses slightly tighter cabinet spacing so the full
  interaction and persistent navigation remain reachable in the calibrated
  mobile runtime.
- [P3] Household categories are broad non-personalized preparation references,
  not a diagnosis, dosage, brand, or treatment recommendation. Country-specific
  medical and legal copy review remains a release requirement.

## Interaction Verification

- Mandatory account flow reaches the home screen.
- Opening the cabinet reveals only the current container's stored items.
- Closing the cabinet conceals all items.
- Shared and personal family scopes switch in place.
- The family-management affordance opens add or edit controls.
- Selecting a medicine opens a read-only detail screen.
- The explicit edit action opens the editor.
- The contextual add action opens the add flow.
- Selecting an empty readiness space opens the add flow with that category
  already selected.
- Registered readiness spaces remain non-actionable; the stored item rows below
  remain the item-selection surface.
- Bottom navigation opens reminders and settings.
- Browser logs contain no runtime errors.
- `npm run check:runtime` and `npm run build` pass.

## Comparison History

### Pass 1

- [P2] The closed cabinet exposed two competing open actions: the door and a
  separate bottom toggle.
- Fix: removed the redundant bottom toggle from the closed state. The whole
  cabinet door is now the only open affordance; the bottom control appears only
  as `닫기` after content is revealed.

### Pass 2

- Post-fix evidence: `qa-storage-surface-pass2.png` and
  `qa-storage-surface-comparison.png`.
- No actionable P0, P1, or P2 finding remains.

### Pass 3

- Scoped terminology refinement replaces every active prototype instance of
  `약장` with `구급상자`, while the compact bottom navigation now reads `홈`.
- Added a fourteen-space readiness map: ten medicine spaces and four first-aid
  spaces. Empty spaces are visibly inset and lead to preselected registration.
- [P2] Initial 8–9 px readiness labels were too small at the calibrated mobile
  viewport.
- Fix: raised status labels to 10 px, category labels to 11 px, and each touch
  surface to at least 58 px high.
- Post-fix evidence: `public/qa/readiness-map-implementation.png` and
  `qa-readiness-comparison.png`.
- No actionable P0, P1, or P2 finding remains.

### Pass 4

- [P1] Eleven category labels were compressed into a single non-wrapping row,
  causing Korean labels to break into vertical fragments and obscuring the
  selected value.
- [P2] The label `보관 분류` described symptom and use categories as physical
  storage locations.
- Fix: replaced the chip rail with one compact `준비 영역` field and a
  keyboard-accessible two-column bottom-sheet picker. Medicine and first-aid
  choices are now filtered by item type, and changing item type resets an
  incompatible previous choice.
- Additional consistency fixes: the route title now uses the neutral
  `물품 추가`, the name example follows the selected item type, and the primary
  action distinguishes medicine from first-aid supplies.
- Verified at the calibrated iPhone and Pixel 10 widths. Every option remains
  on one line, selected state is explicit, and selection closes the sheet and
  updates the compact field.
- Post-fix evidence: `qa-readiness-area-comparison.png`.
- No actionable P0, P1, or P2 finding remains.

## Implementation Checklist

- [x] Match selected information hierarchy.
- [x] Preserve meaningful open/close disclosure.
- [x] Keep family management and item CRUD reachable.
- [x] Separate item detail from editing.
- [x] Preserve accessible labels and reduced-motion behavior.
- [x] Remove duplicate settings, review-card, full-list, and external add
  actions from the home screen.
- [x] Show broad medicine and first-aid readiness spaces without inventing
  specific products.
- [x] Open preselected registration from every empty readiness space.
- [x] Keep the existing stored-item detail interaction separate from the
  readiness map.
- [x] Keep the full readiness-area taxonomy out of the compact edit form.
- [x] Filter readiness-area choices by medicine or first-aid item type.

## Follow-up Polish

- Revisit exact category pictograms only if the production icon set adds
  semantically closer symbols.

final result: passed
