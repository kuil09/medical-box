# Cabinet Index V2

## Product Definition

Medical Box is a Korean household medicine organizer. It is not a dose tracker,
pharmacy storefront, or generic health dashboard.

The interface must help a person answer three questions quickly:

1. What medicine is available?
2. Where is it stored?
3. Does anything require review?

The primary product object is a household medicine cabinet. Shared storage and
personal pouches are scopes of the same storage system.

## Design Thesis

Cabinet Index V2 translates a precise household appliance and a labeled
organizer into native mobile UI.

The interface should feel:

- precise rather than cute;
- tangible rather than illustrative;
- calm rather than clinical;
- domestic rather than institutional;
- trustworthy rather than promotional;
- dense enough to scan, but never crowded.

Physical depth is permitted only when it communicates structure or state.
Hinges explain open and closed states. Rails explain grouping. Latches explain
the primary cabinet action. Dividers explain physical location.

Never use a large decorative 3D render as the interface. The medicine cabinet
itself is the interaction surface.

## Non-Goals

Do not introduce:

- stock quantities or plus/minus controls;
- dose schedules, dose calculations, or adherence streaks;
- treatment or substitution recommendations;
- gamification, progress rings, or health scores;
- pharmacy commerce or promoted medicine products;
- card piles, cards inside cards, or dashboard widgets;
- cartoon pills, emoji, or mascot-led interactions;
- generic hospital blue as the brand;
- beige, sky-blue, and pink pastel combinations;
- glassmorphism, translucent sheets, or soft gradient blobs;
- photorealistic product mockups that obstruct interaction.

## Color System

### Core

| Token | Value | Use |
| --- | --- | --- |
| `canvas` | `#F4F4F0` | App background |
| `surface` | `#FFFFFF` | Lists, forms, cabinet interior |
| `surface-raised` | `#FAFAF7` | Cabinet lid and subtle raised controls |
| `ink` | `#17191C` | Primary text and icons |
| `ink-muted` | `#62676C` | Supporting text |
| `ink-faint` | `#8A8F93` | Tertiary metadata |
| `rail` | `#D6D7D2` | Dividers, cabinet rails, keylines |
| `rail-strong` | `#A9ACA8` | Cabinet shell and selected structural edges |
| `accent` | `#DF2C27` | Primary action and active structural marker |
| `accent-pressed` | `#B91F1B` | Pressed primary state |
| `accent-soft` | `#FFF0EE` | Review row background |
| `official` | `#2F6B52` | Official-source and connected state |
| `official-soft` | `#EDF6F1` | Official-source background |
| `warning` | `#A84416` | Expiry or status review text |
| `warning-soft` | `#FFF2E9` | Review marker background |
| `focus` | `#005FCC` | Keyboard focus ring only |
| `disabled` | `#C6C8C5` | Disabled border and icon |

### Color Rules

- Use `accent` on no more than 10% of a normal screen.
- Do not use red as a full-page background.
- Use `official` only for source provenance and completed catalog connections.
- Use `warning` only for actions that require review, not for neutral metadata.
- Never communicate a state using color alone. Pair color with an icon, label,
  border pattern, or structural change.
- Keep medicine product photography color-accurate. Do not tint official images.

## Typography

Use Noto Sans KR for all Korean and Latin product UI.

| Style | Size | Weight | Line Height | Tracking |
| --- | --- | --- | --- | --- |
| `display` | 30 px | 700 | 38 px | -0.6 px |
| `screen-title` | 24 px | 700 | 32 px | -0.4 px |
| `section-title` | 19 px | 700 | 26 px | -0.2 px |
| `item-title` | 16 px | 700 | 22 px | -0.1 px |
| `body` | 16 px | 400 | 24 px | 0 |
| `body-strong` | 16 px | 600 | 24 px | 0 |
| `label` | 14 px | 600 | 20 px | 0 |
| `metadata` | 13 px | 500 | 18 px | 0 |
| `caption` | 12 px | 500 | 17 px | 0.1 px |

Typography carries hierarchy before color or containers.

- Never use a light font weight for medicine names, expiry dates, or safety text.
- Clamp medicine names to two lines in cabinet tiles and list rows.
- Allow multiline expansion in detail and edit screens.
- Support dynamic type without clipping primary actions or safety information.

## Spacing and Layout

Use a 4 px base grid.

| Token | Value |
| --- | --- |
| `space-1` | 4 px |
| `space-2` | 8 px |
| `space-3` | 12 px |
| `space-4` | 16 px |
| `space-5` | 20 px |
| `space-6` | 24 px |
| `space-8` | 32 px |
| `space-10` | 40 px |

- Mobile screen margin: 20 px.
- Compact app-bar horizontal padding: 16 px.
- Major section gap: 28 px.
- Label-to-field gap: 8 px.
- Row horizontal padding: 16 px.
- Row minimum height: 64 px.
- Touch target minimum: 48 x 48 px.
- Primary button height: 52 px.
- Bottom navigation height: 72 px plus safe area.

Use one content column on mobile. Do not center the app inside a large outer card.

## Shape

| Component | Radius |
| --- | --- |
| Cabinet outer shell | 16 px |
| Cabinet compartment | 10 px |
| Input and button | 8 px |
| List group | 10 px |
| Small status marker | 6 px |
| Icon button | 8 px |

Avoid pill-shaped containers unless the control is naturally a compact filter
or segmented option.

## Lines, Materials, and Depth

### Keylines

- Default divider: 1 px `rail`.
- Cabinet outer keyline: 1.5 px `rail-strong`.
- Active structural edge: 2 px `accent`.
- Focus ring: 2 px `focus` plus 2 px offset.

### Shadows

Use shadows only to explain cabinet depth or sticky layers.

- `shadow-cabinet`: `0 6px 18px rgba(23, 25, 28, 0.10)`.
- `shadow-inner`: `inset 0 2px 5px rgba(23, 25, 28, 0.08)`.
- `shadow-sticky`: `0 -4px 12px rgba(23, 25, 28, 0.06)`.

Do not apply shadows to normal list rows, filters, or every button.

### Surface Language

Use four functional material cues:

1. `shell`: outer cabinet boundary;
2. `rail`: structural divider and group boundary;
3. `label`: text-first category and provenance marker;
4. `latch`: a control that changes the physical cabinet state.

These cues must be implemented as reusable components, not one-off decoration.

## Iconography

Use one outline icon family with a 2 px stroke.

- Default icon size: 22 px.
- Small metadata icon: 16 px.
- Primary action icon: 20 px.
- Do not mix filled, outlined, hand-drawn, and emoji icons.
- Use familiar platform icons for back, search, share, settings, calendar,
  delete, and disclosure.
- A red cross may identify the cabinet but must not imply emergency medical
  certification.

## Component System

### AppBar

- Height: 56 px.
- Back or navigation action on the left.
- Screen title aligned to the text grid.
- No more than two trailing actions.
- Text action `수정` is preferred over an ambiguous pencil icon on detail.

### FamilyScopeRail

- Appears only on cabinet home.
- Tabs: `공용`, `나`, and named profiles.
- Selected state uses weight, a 2 px underline, and a shallow notched boundary.
- Selection must remain understandable without color.
- Family management is a separate trailing icon button.
- Do not represent “add family” as a fake family tab.

### ReviewRow

- A single grouped row, not a dashboard card.
- Structure: icon, concise title, metadata, chevron or one text action.
- Use `accent-soft` or `warning-soft` only when review is required.
- Example: `8월에 확인할 약 2개`.
- Avoid alarming words when a calm review action is sufficient.

### CabinetShell

The cabinet has a closed and open state.

#### Closed

- Medicines and compartments are not visible.
- Show cabinet name, concise review state, hinge seam, and one latch labeled
  `열기`.
- Height should not exceed 35% of the normal mobile viewport.
- The rest of the screen remains usable.

#### Open

- Lid moves around a visible hinge.
- Contents become visible and selectable.
- Categories are physical compartment labels, such as `해열·진통`, `소화`,
  `상처`, and `기타`.
- `닫기` is integrated into the lid or latch.
- Do not show a floating close button unrelated to the cabinet.

#### Motion

- Open duration: 260 ms.
- Close duration: 220 ms.
- Curve: ease-out for open, ease-in-out for close.
- Medicine tiles fade and translate 6 px only after the compartment becomes
  visible.
- Reduced motion: switch states immediately with no transform animation.

### CabinetCompartment

- White or `surface-raised` interior.
- Label sits on the structural rail, not in a floating badge.
- Use 12 px internal gap.
- Do not nest a card around the entire compartment and cards around every tile.

### MedicineTile

- Minimum target: 88 x 72 px.
- Structure: official product or identification thumbnail, medicine name, and
  optional review marker.
- No quantity.
- A review marker uses an icon plus text such as `8월 확인`.
- Selection opens read-only detail.
- Official images retain source attribution in detail, not inside every tile.

### SectionList

- One group surface with 1 px row dividers.
- Rows are not individual cards.
- Use for search, inventory, alerts, settings, and family management.
- Row disclosure uses a chevron only when navigation is available.

### OfficialSourceLabel

- Outlined or soft-filled, visually quiet.
- Icon plus `공식 정보`.
- Use green only for official provenance or a completed connection.
- Never use it as a product recommendation.

### InputField

- Label sits above the field.
- Height: 52 px, multiline as needed.
- White background, 1 px `rail-strong`, 8 px radius.
- Focus uses `focus`, not `accent`.
- Error uses icon, text, and `accent`.
- Read-only values must not reuse input styling.

### PrimaryButton

- Height: 52 px.
- Background: `accent`.
- Pressed: `accent-pressed`.
- White 16 px semibold label.
- Radius: 8 px.
- One primary button per screen.

### SecondaryButton

- White or transparent.
- 1 px graphite keyline or text-only style.
- Never compete with the primary action.

### DestructiveAction

- Red text and delete icon.
- Never a filled primary button in normal state.
- Requires confirmation that names the affected local data.

### BannerAdSlot

- Fixed reserved height before loading.
- Label `광고` and `비개인화 광고`.
- Neutral boundary distinct from medicine and official-source components.
- Do not use product imagery or medicine names for ad targeting.

## Screen Responsibility Rules

### Required Sign-In

- Required before app use.
- Provider actions: Apple, Google, and Kakao.
- No guest mode.
- No ads.
- Explain account value in one concise paragraph.
- Explain that family, medicine, and memo data remain in encrypted local storage
  during the local-only phase.

### Cabinet Home

- Family scope rail.
- One review row.
- One cabinet component.
- One primary action: `약 추가`.
- One supporting navigation action: `전체 목록`.
- Bottom navigation: `약장`, `알림`, `설정`.
- No stock quantity.
- No banner inside or adjacent to the open cabinet.

### Catalog Search

- Signed-in and authorized users only.
- Search field with official catalog autocomplete.
- OCR entry may be offered as a secondary action.
- Results use one grouped list with separators.
- Each row shows name, manufacturer, dosage form or identification summary,
  provenance, and disclosure.

### Registration

- Creation only.
- OCR and photo recognition belong here.
- Fields: official product link, expiry date, physical location, and optional
  private note.
- No quantity.
- No official monograph.
- Primary action: `등록`.

### Read-Only Detail

- App-bar title: `의약품 상세`.
- Top-right action: `수정`.
- Secondary action: `공유`.
- Values use definition lists and content sections, never input styling.
- Sections: identity, local cabinet information, appearance, ingredients,
  consumer information, storage, source attribution, and safety/DUR.
- No ads.

### Edit

- App-bar title: `의약품 수정`.
- Fields: product connection, manufacturer when manual, expiry, physical
  location, and private note.
- No OCR, official monograph, appearance viewer, DUR, or share.
- Primary action: `변경사항 저장`.
- Delete remains visually secondary.
- Save returns to read-only detail.

### Family Management

- Distinguish login users from managed profiles.
- Show limits separately.
- Each managed profile owns one personal pouch.
- Add, rename, reorder, and remove profiles.
- Removal requires a confirmation that explains local pouch-data effects.

### Alerts

- Show only actionable safety or readiness events.
- Examples: expiry review, recall or sales stop, authorization change, and
  renewal preparation.
- Do not include marketing notifications.
- Every row includes what changed, affected medicine, date, and next action.

### Settings

- Sections: account, family, notifications, purchases, privacy and local data,
  support, and legal.
- Account deletion and device-data deletion are separate actions.
- Purchase restore remains available.
- Do not place ads near privacy, deletion, import/export, or purchase restore.

### Share Preview

- The user chooses included information.
- Private notes are excluded by default.
- Show a plain-text preview before the OS share sheet.
- Do not upload contacts or choose a recipient automatically.
- No ads.

## Advertising Boundaries

Only non-personalized banner ads are allowed.

Allowed:

- below the home review summary and outside the cabinet component;
- middle or end of the full inventory list;
- bottom of the general information area in Settings.

Forbidden:

- sign-in and reauthentication;
- open-cabinet interaction;
- add, edit, delete, and confirmation flows;
- official detail, consumer information, and DUR;
- safety alerts;
- sharing;
- account or device-data deletion;
- backup, import, export, and restore;
- error and urgent-information screens.

## Accessibility

- Body text contrast: minimum 4.5:1.
- Large text and active controls: minimum 3:1.
- Touch targets: minimum 48 x 48 px.
- Support dynamic type and screen zoom.
- All state information includes text or icon beyond color.
- Provide semantic labels for cabinet state, compartment, medicine name,
  official image, expiry state, and source provenance.
- Focus order follows visual order.
- Reduced motion switches cabinet state without transforms.
- Do not place critical text over medicine imagery.

## Content Style

Use plain, calm, specific Korean.

Prefer:

- `8월에 확인할 약 2개`
- `공용 약장 · 상처 칸`
- `공식 정보 연결됨`
- `이 메모는 이 기기에만 저장됩니다`

Avoid:

- fear-based urgency;
- medical promises;
- treatment advice;
- vague labels such as `관리`;
- technical privacy explanations on primary task screens.

## Definition of Done

A screen satisfies Cabinet Index V2 only when:

1. the primary user task is clear without reading helper copy;
2. cabinet depth explains state or structure;
3. no stock quantity or dose-tracking control appears;
4. detail and edit remain visually and functionally distinct;
5. color is not the only status signal;
6. there is no nested card pile;
7. one primary action dominates;
8. all critical controls meet 48 px touch targets;
9. ads stay outside medical and safety interactions;
10. the screen can be implemented as reusable Flutter components.
