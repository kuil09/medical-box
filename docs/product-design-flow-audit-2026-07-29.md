# Product Design Flow Audit — 2026-07-29

## Scope and constraints

The audit covers mandatory account access, the home screen, the shared medicine chest, personal pouches, medicine search and editing, sharing, and settings navigation.

Target constraints:

- A user can reach a stored medicine with the fewest meaningful decisions.
- Opening the chest reveals the current medicine records and makes them directly selectable.
- Family and medicine create, edit, and confirmed-delete operations remain available.
- Exact stock counting is not part of the user experience.

Preservation constraints:

- Existing encrypted Drift databases remain readable.
- The unpublished `.medicalbox` v1 envelope may be replaced before the first
  TestFlight release; every format released to testers must remain readable.
- Family, medicine, expiry, notes, visits, and reminders remain device-local.
- Destructive actions retain confirmation.
- Official medicine information and safety disclosures remain neutral and free.

Evidence conditions:

- The Flutter project passes static analysis and all automated tests.
- The prototype builds with its protected mobile runtime intact.
- The primary iPhone prototype flow is exercised through visible controls.

## Critical findings and changes

### 1. Exact quantity controls created work without reliable value

The app exposed quantity fields and increment/decrement steppers in the editor, shared inventory, personal pouches, home cards, accessibility labels, and share output. This encouraged users to maintain a continuously accurate stock count even though household medicine use is irregular and the app cannot observe consumption.

Change:

- Removed exact quantity inputs, counters, steppers, accessibility copy, and share output.
- Kept the legacy database and export field internally so existing encrypted data remains compatible.
- Reframed remaining counts as the number of medicine types (`종`) rather than stock units.
- Reworded renewal readiness as checking whether the needed medicine is present.

### 2. Multiple controls performed the same navigation

The shared list exposed add actions in the app bar, empty state, and floating button. Personal pouch detail exposed add in the header and floating button. Home duplicated bottom-navigation destinations with settings, inventory, and reminder cards.

Change:

- Empty states now own the only add action when empty.
- Populated lists expose one floating add action.
- Pouch detail exposes one floating add action.
- Home relies on the persistent bottom navigation for inventory, reminders, and settings.
- The physical shared chest remains on home because opening it is the core product interaction, not an alternate navigation shortcut.
- Zero-count attention cards are omitted instead of asking the user to open a screen with nothing to resolve.

### 3. Prototype-only “inspection complete” actions made false promises

The prototype let users check every inventory row, complete an inspection, and claimed another inspection would be scheduled in a month. That state was not persisted or connected to a reminder.

Change:

- Removed row checkboxes, completion progress, the completion CTA, and the unimplemented scheduling claim.
- Made each medicine row one large edit target with clear metadata and a trailing disclosure icon.

### 4. The pushed-screen close action duplicated back and bypassed access intent

Every prototype header offered both Back and Close. On the mandatory-login screen, Close could also route directly to the home prototype.

Change:

- Removed the close action from pushed screens.
- Retained one Back action and a centered title.
- The login flow no longer exposes a direct home route before provider completion.

### 5. The share sheet asked users to configure routine information every time

The sheet asked for four independent field choices before sharing. Quantity was not useful, while product name, expiry/status, and official links are the expected payload.

Change:

- Product name, expiry/status, and official links are included by default.
- Private notes remain excluded by default and are the only optional switch in the prototype.
- Flutter retains a second optional switch for the selected official appearance.
- Preview remains mandatory before opening the operating-system share surface.

### 6. Prototype search looked interactive but was disconnected

The prototype search field did not change results or populate the editor.

Change:

- Connected the search field to realistic prototype catalog records.
- Selecting a result fills the editable fields and displays the official appearance, identification, use-method, source, and update metadata.
- OCR still requires explicit candidate selection before it changes the form.

## Resulting primary flow

1. Accept required documents and select a login provider.
2. Select a shared or personal top-level storage tab.
3. Open the physical chest or personal pouch.
4. Select an existing medicine, or use the single add action.
5. Search or scan, confirm a candidate, and edit only useful storage metadata.
6. Save, or use the separate confirmed-delete action.
7. Share from a preview that has safe defaults and one sensitive optional field.

## Verification

- Flutter 3.44.7 static analysis: passed with no issues.
- Flutter automated tests: 77 passed.
- Product Design mobile runtime integrity check: passed.
- React/TypeScript/Vite production build: passed.
- Sites packaging tests: 4 passed.
- Fresh iPhone prototype interaction checks:
  - mandatory login;
  - simplified home;
  - meaningful chest open state;
  - direct medicine selection;
  - editor without quantity;
  - connected search result selection;
  - preview-first sharing.

Captured artifacts:

- `01-welcome-after.jpg`
- `03-home-simplified.jpg`
- `04-open-chest-simplified.jpg`
- `05-item-editor-no-quantity.jpg`
- `06-share-simplified.jpg`
- `07-open-reference-comparison.jpg`
- `08-personal-pouch-simplified.jpg`
- `09-settings-separated.jpg`

## Accessibility and current limits

- Chest state, medicine types, medicine edit targets, and overflow navigation have explicit Korean accessible names.
- The chest keeps keyboard-accessible buttons and reduced-motion behavior.
- Destructive actions still require a second confirmation.
- This pass visually exercised the iPhone prototype. A fresh Android visual pass and an installed Flutter build inspection remain separate release checks.
