# Design System Specification: Rumah Jahit

## 1. Overview & Creative North Star
**Creative North Star: "The Modern Atelier"**

The design system for Rumah Jahit moves away from the sterile, "spreadsheet" aesthetic common in management tools. Instead, it adopts the philosophy of a high-end tailoring studio: **Precision through Softness.** By blending the structural logic of Material Design 3 with an editorial, high-fashion layout, we create a space that feels authoritative yet bespoke.

We break the "template" look by utilizing **Intentional Asymmetry**. Inventory cards aren't just boxes; they are weighted compositions. Work orders (SPK) aren't just rows; they are layered "fabric swatches" of data. We prioritize breathing room and tonal depth over rigid lines, ensuring the tailor's digital workspace is as clean and professional as their physical cutting table.

---

## 2. Color & Tonal Surface Strategy
The palette is anchored in **Deep Teal (`#004d4c`)**, conveying the heritage and trust of a master craftsman, paired with **Soft Mint (`#136964`)** for modern fluidity.

### The "No-Line" Rule
To maintain a premium, editorial feel, **1px solid borders are strictly prohibited** for sectioning. Structural boundaries must be defined solely through background color shifts.
*   **Primary Surface:** Use `surface` (`#f8fafa`) for the main background.
*   **Sectioning:** Use `surface-container-low` (`#f2f4f4`) to define separate functional areas.
*   **Nesting:** Place a `surface-container-lowest` (`#ffffff`) card inside a `surface-container-low` section to create natural, soft definition.

### The Glass & Signature Texture Rule
*   **Signature Textures:** Use a subtle linear gradient for main Action Buttons or Hero headers, transitioning from `primary` (`#004d4c`) to `primary_container` (`#006766`) at a 135-degree angle. This adds "soul" and depth that flat color cannot.
*   **Glassmorphism:** Floating Action Buttons (FABs) or Top App Bars should use a semi-transparent `surface_bright` with a `backdrop-blur` of 20px. This allows the "fabrics" (content) underneath to bleed through, creating a sense of layered transparency.

---

## 3. Typography
We utilize a dual-font pairing to balance brand character with high-utility readability.

*   **Display & Headlines (Manrope):** Chosen for its geometric precision and modern flair. Use `headline-lg` (`2rem`) for dashboard summaries and `display-sm` (`2.25rem`) for key financial metrics in the POS.
*   **Body & Labels (Inter):** The workhorse of the system. Inter’s tall x-height ensures that "Work Order" details and "Inventory" counts remain legible even at `body-sm` (`0.75rem`) on small mobile screens.
*   **The Editorial Shift:** Increase the tracking (letter-spacing) on `label-md` by 5% and set them in all-caps when used for category headers to provide an authoritative, "catalog" feel.

---

## 4. Elevation & Depth
In this system, depth is a result of **Tonal Layering**, not heavy dropshadows.

*   **The Layering Principle:** Stack `surface_container` tokens to create hierarchy. 
    *   *Level 0:* `surface` (Base)
    *   *Level 1:* `surface_container_low` (In-page grouping)
    *   *Level 2:* `surface_container_highest` (Active state or high-priority Card)
*   **Ambient Shadows:** For floating elements like Modals or Bottom Sheets, use a tinted shadow: `color: on-surface` at 6% opacity, with a blur radius of `24px` and a `Y-offset` of `8px`. Never use pure black shadows.
*   **The Ghost Border Fallback:** If a container requires extra definition (e.g., a white card on a white background), use the `outline_variant` (`#bec9c8`) at **15% opacity**. It should be felt, not seen.

---

## 5. Components

### Cards (Inventory & SPK)
*   **Layout:** Forbid divider lines. Use `spacing-5` (`1.1rem`) to separate content blocks.
*   **Status Badges:** Use `secondary_container` (`#a4f0e9`) with `on_secondary_container` text for "In Progress" states. Use `tertiary_fixed` (`#cbe7f5`) for "Scheduled."
*   **Corners:** Apply `xl` (`0.75rem`) roundedness to all inventory cards to soften the visual impact of dense data.

### Large Touch-Friendly POS Buttons
*   **Primary:** High-contrast `primary` background with `on_primary` text. Minimum height: `56px` (`spacing-16`).
*   **Visual Treatment:** Use a subtle inner-glow (1px white overlay at 10% opacity on the top edge) to make buttons feel tactile and pressable.

### Bottom Navigation Bar
*   **Style:** A "Floating Dock" style. Use `surface_container_highest` with a 20px backdrop blur. 
*   **Indicator:** The active state should use a pill-shaped container (`rounded-full`) in `primary_fixed_dim`.

### Input Fields
*   **Style:** Filled containers using `surface_container_high`. 
*   **Interaction:** On focus, the background transitions to `surface_container_lowest` with a 2px `primary` bottom-only stroke. No full-box outlines.

---

## 6. Do’s and Don’ts

### Do
*   **Do** use `spacing-8` (`1.75rem`) as the standard "Breath" between major sections.
*   **Do** use `secondary_fixed_dim` for icons to create a sophisticated, muted look that doesn't compete with primary text.
*   **Do** favor vertical white space over horizontal lines to separate list items in a Work Order.

### Don't
*   **Don't** use `error` (`#ba1a1a`) for anything other than critical destructive actions or failed payments. For "Delayed" orders, use `tertiary`.
*   **Don't** use standard Material shadows. Always use the Ambient Shadow spec defined in Section 4.
*   **Don't** center-align long blocks of text. Stick to left-aligned editorial layouts for better readability in a management context.

---

## 7. Spacing & Scaling Reference
*   **Standard Padding:** `spacing-4` (`0.9rem`)
*   **Component Gap:** `spacing-2` (`0.4rem`)
*   **Touch Target Min:** `48dp`
*   **Roundedness:**
    *   Buttons/Chips: `full`
    *   Cards: `xl` (`0.75rem`)
    *   Modals: `xl` (`0.75rem`) with top-only rounding for Bottom Sheets.