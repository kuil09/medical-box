# Design QA

## Pass 1

- Source: `public/qa/reference.png` (`853 × 1844`, normalized to `393 × 852`).
- Implementation: `implementation-preview.png`, app viewport crop at `393 × 852`.
- CSS viewport: `393 × 852`.
- Device scale factor: `1`.
- Comparison: `public/qa-comparison.html`.

### Findings

1. **P1 · Layout / primary action** — The prototype repeats a large empty kit lid below the attention cards, which moves the primary inventory CTA below the initial viewport. The reference integrates attention content into the lid and keeps the CTA visible at the bottom. Crop the generated tray asset above its organizer compartments and reduce the vertical gaps so the primary action appears within the first viewport.
2. **P2 · Typography** — The heading hierarchy is directionally correct, but the prototype title is heavier and slightly smaller than the reference. Increase the title size and use a less compressed optical weight.
3. **P2 · Spacing** — The reference uses a tighter gap between the attention cards and the physical tray while retaining more air around the page title. Rebalance the top spacing and card-to-tray gap.
4. **P3 · Image content** — The generated tray is visually aligned in material and palette, but the plain lid is not useful once the attention cards are implemented as live UI. The planned crop is an intentional adaptation that preserves the source hierarchy.

### Required fidelity surfaces

- Fonts and typography: blocked by P2 title scale and weight.
- Spacing and layout rhythm: blocked by P1 CTA placement and P2 vertical rhythm.
- Colors and visual tokens: passed; warm ivory, muted blush, and vermilion match the target direction.
- Image quality and asset fidelity: passed with one intentional crop adaptation; the asset is sharp and consistent with the source material language.
- Copy and content: passed; Korean copy is coherent and preserves the target task.
- Icons: passed; all functional icons use one consistent Radix family.
- Interaction states: passed for the home-to-inventory path; additional flow checks remain.

Pass result: blocked

## Pass 2

- Evidence: `qa-comparison-pass-2.png`.
- Fixes applied:
  - Cropped the generated kit asset to the organizer and pouch area.
  - Restored the reference hierarchy: product name first, then “오늘의 점검”.
  - Reduced the tray height and vertical gaps so the primary CTA is visible in the initial viewport.
  - Kept the image asset sharp while preserving the ivory, blush, mint, and blue material palette.

### Post-fix verification

- Fonts and typography: passed; hierarchy and Korean optical weight now match the reference intent.
- Spacing and layout rhythm: passed; cards, tray, pouches, and CTA are visible in one `393 × 852` viewport.
- Colors and visual tokens: passed.
- Image quality and asset fidelity: passed; generated photography is used for the physical organizer and standard Radix icons are used for controls.
- Copy and content: passed.
- Icons: passed.
- Interaction states: passed for home → inventory → completed sheet → home, personal pouch → reminder toggle, and add item → save.
- Viewport resilience: passed at iPhone `393 × 852` and Pixel 10 `427 × 952`.
- Runtime: passed with no browser console warnings or errors.

### Remaining P3 follow-up

- The physical organizer is an intentionally simplified crop rather than a literal reconstruction of the source lid-and-tray hinge.

## Pass 3 — Interactive pouch and CRUD revision

- Source visual truth: private design-generation artifact (`853 × 1844`, normalized to `393 × 852`).
- Browser-rendered implementation: `public/qa/interactive-home.png` (`393 × 852`).
- Full browser capture: `interactive-home-full.png` (`1400 × 1200`).
- Combined comparison evidence: `qa-interactive-comparison.png`.
- CSS app viewport: `393 × 852`.
- Device scale factor: `1`.
- State: home screen with three interactive family pouches and the shared tray.

### Earlier finding and fix

- **P1 · Interaction / product model** — Personal pouches were represented by hotspots over a raster organizer image. This visually implied interaction without making each pouch a real product object.
- **Fix** — Cropped the source-derived organizer to the shared tray and rendered every family pouch as an accessible card with a visible open action, item count, and edit action. Added an interactive family-management sheet and shared state for member and medicine CRUD.
- **Post-fix evidence** — The combined comparison preserves the original ivory, mint, blush, blue, and vermilion hierarchy while making the pouch region visibly operable.

### Required fidelity surfaces

- Fonts and typography: passed; the title, section labels, card labels, and supporting text retain the selected hierarchy.
- Spacing and layout rhythm: passed; attention cards, shared tray, interactive pouch rail, and primary CTA remain visible in one `393 × 852` viewport.
- Colors and visual tokens: passed; the selected ivory, mint, blush, blue, and vermilion tokens remain intact.
- Image quality and asset fidelity: passed; the real organizer asset remains sharp and is limited to the shared tray, while interactive pouches are standard UI cards rather than image hotspots.
- Copy and content: passed; member and medicine actions use concise Korean labels and distinguish device-local storage.
- Icons: passed; all functional controls continue to use the Radix icon family.
- Accessibility and affordances: passed; pouch open/edit actions and form controls have distinct accessible names.

### Primary interactions tested

- Family member add, rename, two-step confirmed delete, and associated pouch removal.
- Personal pouch open, medicine add, edit, quantity update surface, and two-step confirmed delete.
- Shared tray open, medicine add, edit surface, and two-step confirmed delete.
- No browser console errors were observed; only Vite connection and React development messages were present.

No actionable P0, P1, or P2 findings remain. The physical pouch photography was intentionally translated into interactive cards to satisfy the product requirement without changing the selected color or hierarchy.

final result: passed

## Pass 4 — Interactive shared medicine tray revision

- Source visual truth: private design-generation artifact (`853 × 1844`, normalized to `393 × 852`).
- Browser-rendered implementation: `public/qa/interactive-tray-home.png` (`393 × 852`).
- Full browser capture: `interactive-tray-full.png` (`1400 × 1200`).
- Combined comparison evidence: `qa-interactive-tray-comparison.png`.
- CSS app viewport: `393 × 852`.
- Device scale factor: `1`.
- State: home screen with a fully UI-rendered shared tray and three interactive family pouches.

### Earlier finding and fix

- **P1 · Interaction / product model** — The shared medicine tray was still represented by organizer photography, while only the overlaid labels behaved as controls. This made the central product object look interactive without making its compartments actual UI components.
- **Fix** — Removed the tray photograph from the home experience and translated its physical structure into three accessible storage-category buttons: digestive care, wound care, and other. Each compartment exposes live inventory names and counts, opens the shared inventory, and sits beside a real add-medicine action.
- **Post-fix evidence** — The combined comparison preserves the selected physical organizer's compartment hierarchy, warm ivory material language, blush attention color, and vermilion primary action without relying on an image for product interaction.

### Required fidelity surfaces

- Fonts and typography: passed; the product title, section hierarchy, tray labels, and supporting text remain visually aligned with the selected direction.
- Spacing and layout rhythm: passed; attention cards, all shared-tray controls, family pouches, primary CTA, and safety copy remain visible in one `393 × 852` viewport.
- Colors and visual tokens: passed; ivory, blush, mint, blue, and vermilion remain consistent.
- Asset strategy: passed; the shared tray and personal pouches are now semantic controls rather than raster assets or hotspots.
- Copy and content: passed; each compartment states its category, current contents, and count through visible and accessible labels.
- Icons: passed; all controls use the Radix icon family in the prototype and the Phosphor icon family in Flutter.
- Accessibility and affordances: passed; all tray compartments and the add action are native buttons with distinct accessible names and target sizes.

### Primary interactions tested

- Digestive compartment → shared inventory, with the expected medicine items visible.
- Back navigation → shared tray home.
- Add medicine action → medicine editor with product-name and save controls.
- Browser console inspection showed no application warnings or errors; only Vite connection and React development messages were present.

No actionable P0, P1, or P2 findings remain. The source organizer was intentionally translated into semantic compartment controls to satisfy the product requirement while preserving the selected visual hierarchy.

final result: passed

## Pass 5 — Top-level personal pouch tabs

- Source visual truth: private design-generation artifact (`853 × 1844`, normalized to `393 × 852`).
- Browser-rendered shared state: `public/qa/top-tabs-shared.png` (`393 × 852`).
- Browser-rendered member state: `public/qa/top-tabs-member.png` (`393 × 852`).
- Full browser captures: `top-tabs-shared-full.png` and `top-tabs-member-full.png` (`1400 × 1200` each).
- Combined comparison evidence: `qa-top-tabs-comparison.png` (`1300 × 940`).
- CSS app viewport: `393 × 852`.
- Device scale factor: `1`.
- States: shared storage tab selected and Hajun personal pouch tab selected.
- Focused region evidence: not required; the combined `393 × 852` views keep tab labels, selected states, item rows, and actions legible at review scale.

### Earlier finding and fix

- **P1 · Information architecture / navigation** — Personal pouches lived in a separate card rail below the shared tray, forcing users to scan down the screen before switching storage context.
- **Fix** — Moved shared storage and every family member into a horizontally scrollable top-level tab rail directly below the home heading. The selected tab now changes the attention summary, storage component, medicine rows, edit action, add action, and primary CTA in place.
- **Post-fix evidence** — The combined comparison shows the shared and selected-member states using the same physical-organizer hierarchy, warm palette, and vermilion primary action while exposing storage context at the top of the screen.

### Required fidelity surfaces

- Fonts and typography: passed; tab labels use compact optical weights without competing with the product heading or section title.
- Spacing and layout rhythm: passed; the tab rail sits directly below the heading, preserves a clear selected state, and leaves all primary content and safety copy visible in one `393 × 852` viewport.
- Colors and visual tokens: passed; member tabs reuse the mint, blush, and blue pouch identity colors, while the selected underline uses the existing vermilion action token.
- Image quality and asset fidelity: passed; no storage or pouch interaction depends on raster imagery.
- Copy and content: passed; shared and member contexts update their labels, counts, attention copy, medicine list, and CTA consistently.
- Icons: passed; all prototype controls use the existing Radix icon family.
- Accessibility and affordances: passed; storage controls expose `tab` roles with selected state, the add-pouch action has a distinct name, and the selected pouch retains separate edit, add, and open actions.

### Primary interactions tested

- Shared tab → Hajun tab, with selected state, member-specific attention summary, and expected medicines rendered.
- Personal medicine row → medicine editor.
- Back navigation → selected pouch state.
- Add-pouch tab → family-member creation sheet.
- Browser console inspection showed no application warnings or errors.

No actionable P0, P1, or P2 findings remain. Partial visibility of the next tab is intentional horizontal-scroll affordance for households with more members.

final result: passed

## Pass 6 — Interactive 3D medicine chest, settings, sharing, and official data

- Source visual truth: `public/qa/interactive-reference.png` (`393 × 852`).
- Browser-rendered closed state: `public/qa/3d-closed-screen.png` (captured
  from the calibrated iPhone screen at the same aspect ratio).
- Browser-rendered open state: `public/qa/3d-open-home.png`.
- Official drug information state: `public/qa/official-drug-card.png`.
- Combined comparison evidence: `qa-3d-comparison.png`.
- Comparison surface: `public/qa-3d-comparison.html`.
- Browser viewport: `390 × 844` for interaction and screen capture.

### Earlier findings and fixes

- **P0 · Core object was visually flat** — The shared tray behaved like a set
  of cards rather than a physical medicine chest.
- **Fix** — Replaced the flat representation with a real Three.js WebGL scene
  containing a hinged lid, shell, dividers, three colored compartments,
  physically based materials, lighting, and live open/close animation. The
  scene is a native accessible button; category controls remain native buttons
  after opening.
- **P1 · Settings were mixed into incidental actions** — Privacy and sharing
  rules were not visible as their own product area.
- **Fix** — Added a separate settings screen with working privacy and local
  reminder toggles, backup rows, and a fixed preview-first sharing rule.
- **P1 · Sharing lacked field-level consent** — A single share action could not
  show which local fields would leave the device.
- **Fix** — Added an explicit selection sheet and live preview. Quantity,
  expiry, and official links default on; private notes default off.
- **P1 · Official source fields were not represented in the prototype** —
  Usage and identification data had no visible product-detail treatment.
- **Fix** — Added an attributed official information card for appearance,
  pill identification, use method, source set, and update date, with a safety
  disclaimer that prohibits dosage calculation and treatment recommendation.

### Required fidelity surfaces

- Physicality: passed; the WebGL shell, lid, hinge, shadow, and compartment
  geometry visibly preserve the selected organizer direction without using a
  medicine-box image.
- Typography and hierarchy: passed; the product heading, daily checks, physical
  chest, and vermilion primary action retain the selected visual order.
- Colors and material language: passed; ivory, blush, pale blue, mint, and
  vermilion remain consistent across the reference and implementation.
- Layout and cropping: passed; the closed state fits the calibrated screen
  without clipping the primary action or safety copy. Partial visibility of the
  next member tab remains an intentional carousel affordance.
- Accessibility and affordances: passed; the 3D chest exposes expanded state,
  category controls have distinct names, settings toggles use native checkboxes,
  and sharing fields are separately selectable.

### Primary interactions tested

- Closed 3D chest → open 3D chest → category compartment → shared inventory.
- Separate settings route → notification privacy toggle changed successfully.
- Share action → field selection sheet; private note was off by default and
  appeared in the preview only after explicit selection.
- Shared inventory → official example item → attributed usage and appearance
  information card.
- Browser console inspection showed no application errors. The Three.js shadow
  map deprecation warning found during the pass was removed.

No actionable P0, P1, or P2 findings remain.

final result: passed

## Pass 7 — Inventory-backed meaning of opening

- Open-state visual source: `public/qa/interactive-reference.png` (`393 × 852`).
- Earlier implementation evidence: `public/qa/meaningful-open-before.png`.
- Final closed-state evidence: `public/qa/meaningful-closed-after.png`
  (`393 × 852`).
- Final open-state evidence: `public/qa/meaningful-open-after.png`
  (`393 × 852`).
- Combined open-state comparison: `qa-meaningful-open-comparison.png`.
- Comparison surface: `public/qa-meaningful-open-comparison.html`.
- Browser viewport: `1400 × 1200`, with a measured `393 × 852` CSS app screen
  and device scale factor `1`.

### Earlier finding and fix

- **P0 · Opening did not disclose the inventory** — The lid animation exposed
  an empty set of compartments even though the shared inventory contained four
  items. The actual item names existed only in controls below the scene. This
  made the physical object contradict the product state.
- **Fix** — Rebuilt the open state around the current inventory. The closed
  chest conceals all items. Opening creates grouped Three.js item objects from
  the actual inventory records, including a medicine bottle, bandage package,
  gauze roll, and wipe package, with physical name and quantity labels. Empty
  inventory now produces an empty chest rather than decorative products.
- **P1 · The 3D contents were not actionable** — The scene did not connect a
  visible medicine object to its record.
- **Fix** — Added raycast hit testing for every revealed medicine object. A
  direct pointer selection on the 3D bandage package opened the matching
  `혼합형 밴드` editor with quantity `2`, proving that the object and record
  share the same identity. The accessible inventory list below the scene
  provides the same edit path for keyboard and assistive-technology users.
- **P1 · Flutter used the same empty-shell semantics** — The native component
  opened into category summaries while the shell itself remained empty.
- **Fix** — The Flutter component now starts closed, reveals widgets derived
  from the actual `InventoryItem` collection inside the physical shell, and
  opens the selected item's editor. Category summaries remain secondary
  navigation.

### Required fidelity surfaces

- Product meaning: passed; closed means private/concealed and open means actual
  inventory is visible and directly selectable.
- Physicality: passed; the shell, hinged lid, dividers, medicine geometries,
  lighting, shadows, and depth are WebGL objects rather than an image or
  decorative CSS illustration.
- Source comparison: passed; the implementation preserves the reference's
  ivory organizer, three horizontal storage zones, blush and blue content
  accents, open-lid hierarchy, and visible medicine packages.
- Typography and hierarchy: passed; item identity remains secondary to the
  physical object in the 3D scene and becomes fully legible in the accessible
  inventory controls below it.
- Interaction and accessibility: passed; open/close controls expose distinct
  labels, the open group announces the visible item count, and item editing is
  available through both 3D pointer selection and native buttons.
- Empty state integrity: passed by implementation review; no mock medicine is
  created when the actual inventory is empty.

### Verification

- Direct user-style tap on the closed WebGL chest preserved screen scroll
  position `0` and produced the open-state label
  `열린 공용 구급상자, 의약품 4개가 보임`.
- Direct coordinate selection on the rendered 3D bandage package opened the
  matching editor, with `혼합형 밴드` and quantity `2`.
- `npm run build` passed, including protected mobile-runtime integrity checks.
- Flutter `analyze` completed with no issues.
- All nine Flutter local-data, encryption, export, and inventory tests passed.
- Browser console inspection found no application warnings or errors.

No actionable P0, P1, or P2 findings remain.

final result: passed

## Pass 8 — Layered medicine chest UI component

- Product-correction evidence: the supplied `608 × 1120` screenshot showing
  the rough WebGL diorama and floating medicine labels.
- Physical organizer reference: `public/qa/interactive-reference.png`
  (`393 × 852`).
- Earlier implementation evidence: `public/qa/box-ui-before.png`
  (`393 × 852`).
- Final open-state evidence: `public/qa/box-ui-after.png` (`393 × 852`).
- Focused component evidence: `public/qa/box-ui-focused.png` (`393 × 852`).
- Combined comparison: `qa-box-ui-comparison.png`.
- Comparison surface: `public/qa-box-ui-comparison.html`.
- Browser viewport: `1400 × 1200`, with a measured `393 × 852` CSS app screen
  and device scale factor `1`.

### Findings and fixes

- **P1 · The box read as a miniature 3D prop, not a product component** — The
  WebGL implementation separated a rail-like physical scene from the real
  inventory controls below it. Primitive medicine shapes, billboard labels,
  and a large empty backdrop made the scene feel illustrative rather than
  operational.
- **Fix** — Rebuilt the chest as one semantic layered UI component. The lid,
  hinges, rim, tray, category compartments, item controls, and add action now
  form a single visual and interaction hierarchy. Depth comes from coordinated
  planes, borders, shadows, occlusion, and hinge motion rather than standalone
  medicine models.
- **P1 · The transformed base intercepted item input** — The initial layered
  prototype used a 3D transform on the base, causing its rim to win pointer hit
  testing over medicine controls in some positions.
- **Fix** — Removed the base transform while preserving visual depth through
  the lid perspective, layered borders, and shadows. Coordinate hit testing now
  resolves to the intended item control, and a direct tap opens its editor.
- **P2 · Initial item targets were too short** — The first tray layout produced
  item controls around `37 px` tall.
- **Fix** — Expanded the base and compartment grid. The measured final controls
  are `44–46 px` tall, long Korean names wrap without clipping, and an odd final
  wound-care item spans the full compartment width.
- **P2 · Closed contents remained in the accessibility tree** — Visually hidden
  controls could still expose inventory before the box was opened.
- **Fix** — The tray and actions are conditionally mounted only in the open
  state. Closed now means both visually and semantically concealed.

### Required fidelity surfaces

- Product meaning: passed; opening reveals the actual inventory within the
  object, and closing conceals it instead of playing an unrelated animation.
- Physicality: passed; lid, paired hinges, raised rim, recessed tray,
  compartment walls, press states, and shadow changes communicate one tactile
  box without relying on a raster box image or fake medicine assets.
- Source comparison: passed; the implementation preserves the ivory organizer,
  three horizontal storage zones, blush and sky-blue accents, open-lid
  hierarchy, and the reference's immediate relationship between container and
  contents.
- Typography and hierarchy: passed; real product names, metadata, quantities,
  category labels, and the add action remain legible inside the physical form.
- Interaction and accessibility: passed; open/close and medicine items are
  native buttons with explicit Korean labels, visible focus states, minimum
  touch targets, and a reduced-motion mode.
- Empty state integrity: passed by implementation review; an empty category
  explicitly shows `비어 있음`, and no decorative medicine is generated.

### Verification

- The closed DOM does not expose or focus inventory item controls.
- The open state measured item controls at `44–46 px` tall.
- A direct user-style tap on `혼합형 밴드` opened the matching medicine editor
  with quantity `2` and metadata `20매`.
- Browser back navigation restored the open chest state.
- `npm run build` passed, including protected mobile-runtime integrity checks.
- `npm run test:sites` passed all four route and deployment-surface checks.
- Browser console inspection found no application warnings or errors.

No actionable P0, P1, or P2 findings remain.

final result: passed
