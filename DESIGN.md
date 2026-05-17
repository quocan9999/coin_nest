# The Design System: Editorial Precision in Personal Finance

## 1. Overview & Creative North Star: "The Financial Architect"

This design system moves beyond the standard "utility app" aesthetic to embrace the role of **The Financial Architect**. It rejects the cluttered, line-heavy interface of traditional banking in favor of a high-end editorial experience.

The "North Star" for this system is **Structural Purity**. We achieve premium quality not through decoration, but through the intentional use of negative space, sophisticated tonal layering, and a relentless commitment to typography as the primary UI element. By removing traditional borders and 3D effects, we allow the user’s data to become the visual hero, framed by a layout that feels as deliberate as a custom-built home.

---

## 2. Colors & Tonal Depth

While the palette is grounded in high-clarity financial signaling, its application must be sophisticated. We avoid "loud" interfaces by using a hierarchy of surfaces rather than lines.

### The "No-Line" Rule

**Explicit Instruction:** Designers are prohibited from using 1px solid borders to section off content. Content blocks must be defined solely through background color shifts. A `surface-container-low` section sitting on a `surface` background provides enough contrast to guide the eye without adding visual noise.

### Surface Hierarchy & Nesting

Treat the UI as a series of physical layers. Use the following tiers to create depth:

- **Base Layer:** `surface` (#f9f9f9) - The canvas.
- **Secondary Layer:** `surface-container-low` (#f3f3f3) - For grouped content areas.
- **Top Layer (Cards):** `surface-container-lowest` (#ffffff) - For the most important interactive elements.

### Signal Colors (Intentional Utility)

- **Primary (Brand/Transfer):** `primary` (#00668a) for high-importance actions.
- **Success (Income):** `secondary` (#006e1c) for positive cash flow.
- **Error (Expense):** `tertiary` (#bb1614) for outflows.
- **Warning (Debt):** `on-tertiary-container` (#750003) for critical debt alerts.

---

## 3. Typography: The Editorial Voice

We use **Be Vietnam Pro** to create an authoritative yet approachable voice. The scale is designed to create a clear "Information Scent."

- **Display (Large Figures):** `display-md` (2.75rem). Use this for total account balances. It should feel like a headline in a premium financial magazine.
- **Headline (Section Entrances):** `headline-sm` (1.5rem). Used for major dashboard sections (e.g., "Monthly Spending").
- **Title (Context):** `title-md` (1.125rem). Used for card headers and navigation titles.
- **Body (Data Details):** `body-md` (0.875rem). The workhorse for transaction descriptions.
- **Label (Metadata):** `label-md` (0.75rem). Used for timestamps and micro-data.

**Editorial Rule:** Always pair a `display` value with a `label-md` to create high-contrast hierarchy. Large numbers should never be crowded; give them at least `spacing-8` of breathing room.

---

## 4. Elevation & Depth: Tonal Layering

In a flat design system, "elevation" is a measure of contrast, not shadow.

- **The Layering Principle:** To lift a card, do not use a drop shadow. Instead, place a `surface-container-lowest` (#ffffff) card on a `surface-container` (#eeeeee) background.
- **The "Ghost Border" Fallback:** If a layout requires a boundary for accessibility (e.g., input fields), use the `outline-variant` token at **20% opacity**. Never use a 100% opaque border.
- **Interaction States:** When an element is pressed, shift its background color one step down in the hierarchy (e.g., from `surface-container-lowest` to `surface-container-high`) rather than adding a glow or shadow.

---

## 5. Components: Principles of Flat Sophistication

### Buttons

- **Primary:** Background: `primary` (#00668a), Text: `on-primary` (#ffffff). Shape: `rounded-lg` (0.5rem). Use for the main action (e.g., "Add Transaction").
- **Secondary:** Background: `primary-fixed-dim`, Text: `on-primary-fixed`. Use for supportive actions.
- **Tertiary:** No background, `primary` text. Use for "Cancel" or "Back."

### Cards & Lists (The "No-Divider" Rule)

- **Rule:** Forbid the use of divider lines between list items.
- **Execution:** Use `spacing-4` (1rem) of vertical white space to separate transaction items. For grouped lists, use a `surface-container-low` background for the entire group and individual `surface-container-lowest` "tiles" for each item if high emphasis is needed.

### Input Fields

- **Style:** Minimalist. Background: `surface-container-highest` (#e2e2e2), no border, `rounded-md`.
- **Focus State:** A 2px solid bottom-bar using the `primary` color. This maintains the "flat" aesthetic while providing clear interaction feedback.

### Financial Health Chips

- **Context:** Selection or status indicators.
- **Visual:** Low-saturation backgrounds with high-saturation text (e.g., `secondary-container` background with `on-secondary-container` text). This ensures they are readable but don't compete with the main CTA.

---

## 6. Do’s and Don’ts

### Do

- **Do** use asymmetrical spacing. A larger top-margin than bottom-margin on headlines creates a premium, editorial feel.
- **Do** lean on `primary-container` for large background areas to create brand immersion without the aggression of pure primary blue.
- **Do** use `label-sm` for "all caps" eyebrow text to categorize data sections.

### Don’t

- **Don’t** use 3D effects, inner shadows, or bevels. The depth must remain purely tonal.
- **Don’t** use pure black (#000000) for text. Use `on-surface` (#1a1c1c) to maintain a sophisticated, soft-ink look.
- **Don’t** use icons as the only way to communicate status. Always pair with typography to maintain the architectual, information-first intent.

### Accessibility Note

Ensure that all signal colors (Income/Expense) maintain a 4.5:1 contrast ratio against their respective surface containers. When in doubt, use the `on-container` token variants for text.
