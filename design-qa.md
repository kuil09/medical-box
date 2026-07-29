# Cabinet Index V2 Design QA

## Comparison target

- Source visual truth:
  - `design/stitch/references/home-closed.jpg`
  - `design/stitch/references/home-open.jpg`
- Rendered implementation:
  - `apps/mobile/test/golden/goldens/cabinet_home_closed.png`
  - `apps/mobile/test/golden/goldens/cabinet_home_open.png`
- Combined comparison evidence:
  - `design/stitch/qa-comparison.png`
  - `design/stitch/qa-comparison.html`
- Viewport: 390 × 884 CSS pixels
- Source pixels: 780 × 1768 at 2× density
- Implementation pixels: 390 × 884 at 1× density
- Density normalization: the source images are rendered at 390 × 884 CSS pixels
  beside the 1× Flutter captures. Both states therefore use the same visible
  crop, aspect ratio, content scale, and viewport.
- Theme: light
- States:
  - shared cabinet closed
  - shared cabinet open
- Fixture: four medicines, three personal pouches, and two medicines requiring
  review, matching the source screen's content density.

## Findings

No actionable P0, P1, or P2 findings remain after the second comparison.

The following deviations are intentional and acceptable:

- The redundant hamburger action is omitted because the three persistent
  destinations are already exposed by the bottom navigation, and family
  management has a dedicated action in the scope rail.
- The review row uses a row-level chevron instead of a separate `확인하기`
  label. The whole 64-pixel row remains one clear tap target.
- Product imagery is data-dependent. The production component renders an
  official HTTPS image when the catalog supplies one and uses the Phosphor pill
  icon only as an explicit fallback. The golden fixture exercises the fallback
  rather than embedding fake product imagery.

## Required fidelity surfaces

### Fonts and typography

- Noto Sans KR is bundled and used consistently for Korean display and body
  text.
- Title, section, item, supporting, and navigation weights preserve the source
  hierarchy without clipped or wrapped controls at 390 pixels.
- Long medicine names are capped at two lines with ellipsis inside a stable
  tile.

### Spacing and layout rhythm

- The 20-pixel screen margin, 52-pixel primary action, 64-pixel review row, and
  72-pixel bottom navigation align with the source system.
- The closed cabinet now occupies a physical 212-pixel door surface with a
  hinge rail, two hinge plates, internal divider, review status, and latch.
- The open cabinet uses a two-column medicine shelf and a bottom-mounted close
  latch. Opening changes the information available, rather than playing a
  decorative animation.
- The open and closed layouts keep all persistent actions above the bottom
  navigation without clipping.

### Colors and visual tokens

- Canvas `#F4F4F0`, ink `#17191C`, accent `#DF2C27`, white surface, muted text,
  and rail colors match the Stitch Cabinet Index V2 system.
- Warning red is reserved for review state and the primary add action.
- Surfaces remain flat with restrained border and shadow treatment; there are
  no gradients or decorative effects.

### Image quality and asset fidelity

- The source product photos represent dynamic official catalog images, not a
  static design asset.
- Production medicine tiles use the stored official image URL when available.
  The fallback is a real Phosphor outline icon, not an emoji, handcrafted SVG,
  text glyph, or fake product image.
- The UI uses no stretched screenshots, generated placeholder pills, or
  rasterized controls.

### Copy and content

- Copy is concise and task-oriented: review, open the cabinet, select a
  medicine, add a medicine, or open the full list.
- Quantity language is absent from the primary flow because inventory count is
  no longer a product goal.
- The closed state explains the purpose of opening; the open state exposes real
  selectable medicine records.

### Icons, behavior, and accessibility

- Visible icons use Phosphor outline icons with consistent optical weight.
- Open, close, medicine selection, family scope selection, review, add, full
  list, reminder, and settings actions are real controls.
- The cabinet exposes open/closed semantics and honors reduced-motion settings.
- Primary controls meet a minimum 48-pixel touch target.
- Automated interaction evidence covers closed → open → medicine selection →
  closed, and confirms medicine content is hidden while closed.
- The local comparison page reported zero console errors.

## Focused-region evidence

The cabinet and family/review regions remain legible at full 390-pixel size in
the combined comparison, so no additional crop was required. The individual
closed and open source and implementation files listed above were also
inspected at their native pixel dimensions to verify hinges, borders, icons,
labels, tile spacing, and the bottom latch.

## Comparison history

### Iteration 1 — blocked

- P1: the closed implementation collapsed the cabinet into an approximately
  82-pixel summary row, removing the physical cabinet meaning.
- P1: the open implementation stacked every category vertically and kept the
  close action in the header, making it behave like an accordion list.
- P1: the golden fixture used fewer family scopes and medicines than the source,
  so density and shelf behavior were not comparable.

Fixes:

- Rebuilt the closed cabinet as a 212-pixel hinged door with a real open action,
  internal divider, review summary, and persistent cabinet footprint.
- Moved the close latch below the exposed contents and arranged medicine
  compartments in a two-column shelf.
- Updated the comparison fixture to four medicines, three personal pouches, and
  two review items.

Post-fix evidence:

- `design/stitch/qa-comparison.png`
- `apps/mobile/test/golden/goldens/cabinet_home_closed.png`
- `apps/mobile/test/golden/goldens/cabinet_home_open.png`

### Iteration 2 — passed

- Closed-state hierarchy, physical cabinet meaning, open-state shelves, family
  density, review state, primary action, and bottom navigation now preserve the
  source design intent.
- No actionable P0, P1, or P2 visual differences remain.

## Implementation checklist

- [x] Apply Cabinet Index V2 tokens and Noto Sans KR.
- [x] Make the cabinet reveal actual stored medicines only when open.
- [x] Preserve real medicine selection and local CRUD routes.
- [x] Separate read-only detail from editing.
- [x] Use three persistent bottom-navigation destinations.
- [x] Apply flat section-list treatment to inventory, pouch, reminders,
  settings, login, detail, and editing screens.
- [x] Verify closed/open interaction and golden states.
- [x] Compare source and implementation together at a normalized viewport.

## Follow-up polish

- P3: capture an additional store-installed screenshot with real catalog
  product images after TestFlight processing to document the data-backed image
  state.

final result: passed
