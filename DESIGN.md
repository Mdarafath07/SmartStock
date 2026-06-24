# Smart Stock — Design System

> **Project:** Professional Electronics Inventory UI  
> **ID:** `6484600446757262687`  
> **Type:** Inventory Management System (Electronics Retail)  
> **Brand Personality:** Professional, Systematic, Precise  
> **Aesthetic:** Modern Corporate with Material 3 influence

---

## 1. Brand & Style

The design system is engineered for high-efficiency inventory management in the electronics retail sector. It follows a **"Flat-Plus"** approach where depth is communicated through subtle tonal changes and soft elevation rather than gradients or heavy textures.

- **Emotional response:** Organized calm and operational reliability
- **Visual language:** Spacious layout, high-quality typography, structural hierarchy
- **Key influence:** Material 3

---

## 2. Color Palette

### 2.1 Primary Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#000666` | Primary text, high-emphasis elements |
| `primary-container` | `#1a237e` | Solid Indigo — primary buttons, active states |
| `on-primary` | `#ffffff` | Text on primary backgrounds |
| `on-primary-container` | `#8690ee` | Text on primary-container |
| `primary-fixed` | `#e0e0ff` | Primary surface tint |
| `primary-fixed-dim` | `#bdc2ff` | Dim variant of primary |
| `inverse-primary` | `#bdc2ff` | Primary in inverse contexts |

### 2.2 Surface & Background

| Token | Hex | Usage |
|-------|-----|-------|
| `surface` / `background` | `#fbf8ff` | Soft off-white canvas |
| `surface-dim` | `#dbd9e1` | Dimmed surface |
| `surface-bright` | `#fbf8ff` | Bright surface |
| `surface-container-lowest` | `#ffffff` | Pure white — interactive surfaces, cards |
| `surface-container-low` | `#f5f2fb` | Container level 1 |
| `surface-container` | `#efecf5` | Container level 2 |
| `surface-container-high` | `#eae7ef` | Container level 3 |
| `surface-container-highest` | `#e4e1ea` | Container level 4 |
| `on-surface` | `#1b1b21` | Primary text on surface |
| `on-surface-variant` | `#454652` | Secondary text |
| `inverse-surface` | `#303036` | Dark surface for inverse areas |
| `inverse-on-surface` | `#f2eff8` | Text on inverse surface |

### 2.3 Secondary & Tertiary

| Token | Hex | Usage |
|-------|-----|-------|
| `secondary` | `#4c616c` | Secondary text/elements |
| `secondary-container` | `#cfe6f2` | Secondary background |
| `tertiary` | `#380b00` | Accent color |
| `tertiary-container` | `#5c1800` | Tertiary background |

### 2.4 Functional Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `error` | `#ba1a1a` | Error states, destructive actions |
| `error-container` | `#ffdad6` | Error background |
| `on-error` | `#ffffff` | Text on error |
| `on-error-container` | `#93000a` | Error text |

### 2.5 Outline & Border

| Token | Hex | Usage |
|-------|-----|-------|
| `outline` | `#767683` | Borders, dividers |
| `outline-variant` | `#c6c5d4` | Subtle borders |

### 2.6 Status Indicator Colors (from screens)

| Status | Indicator |
|--------|-----------|
| In Stock | Green check circle (`check_circle` icon) |
| Low Stock | Amber/warning (`warning` icon) |
| Out of Stock | Red error (`error` icon) |
| Overstock | Neutral inventory icon |

---

## 3. Typography

A **three-font strategy** balancing character with utility:

### 3.1 Font Families

| Role | Font | Usage |
|------|------|-------|
| **Headings** | **Hanken Grotesk** | Sharp, contemporary professional headings |
| **Body** | **Inter** | Legibility in data-dense environments |
| **Labels & Code** | **Geist** | Technical, precise — SKU/Serial numbers |

### 3.2 Type Scale

| Level | Font | Size | Weight | Line Height | Letter Spacing |
|-------|------|------|--------|-------------|----------------|
| `display-lg` | Hanken Grotesk | 48px | 700 | 56px | -0.02em |
| `headline-lg` | Hanken Grotesk | 32px | 600 | 40px | -0.01em |
| `headline-lg-mobile` | Hanken Grotesk | 24px | 600 | 32px | — |
| `title-md` | Hanken Grotesk | 20px | 600 | 28px | — |
| `body-lg` | Inter | 16px | 400 | 24px | — |
| `body-md` | Inter | 14px | 400 | 20px | — |
| `label-md` | Geist | 12px | 500 | 16px | 0.05em |
| `code-sm` | Geist | 13px | 400 | 18px | — |

### 3.3 Usage Patterns (from screens)

- **Screen titles:** `title-md` or `headline-lg` (e.g., "Inventory", "Dashboard")
- **Stat values:** Large numbers in bold (e.g., "1,240" for Total Products)
- **Labels:** `label-md` with uppercase-like letter-spacing
- **SKU/Product codes:** Tight, technical feel using Geist
- **Body text in tables:** `body-md` or `body-lg` in Inter
- **Navigation labels:** Compact, clean (e.g., Dashboard, Inventory, Sales, Reports, Settings)

---

## 4. Spacing & Grid

### 4.1 Baseline Grid

- **Unit:** 4px
- All spatial relationships follow the 4px baseline

### 4.2 Fluid Grid

| Breakpoint | Columns | Margin | Gutter |
|------------|---------|--------|--------|
| Desktop (1240px+) | 12 | 32px | 24px |
| Tablet (768–1239px) | 8 | 24px | 16px |
| Mobile (0–767px) | 4 | 16px | 12px |

### 4.3 Spacing Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `unit` | 4px | Baseline unit |
| `container-padding-sm` | 16px | Tight containers, compact tables |
| `container-padding-md` | 24px | Standard containers, inventory lists |
| `gutter` | 24px | Column gutters |
| `margin-desktop` | 32px | Desktop safe margins |
| `max-width` | 1440px | Maximum content width |

### 4.4 Layout Patterns (from screens)

- **Dashboard:** Stat cards in a 2×2 or 4-column grid, followed by Recent Sales table and Top Selling section
- **Inventory:** Search bar + filter chips + paginated data table
- **Settings:** Menu list → expandable detail sections with forms
- **Customer Details:** Profile header → stat badges → purchase history table → warranty cards
- **Navigation:** Persistent bottom navigation bar (5 items: Dashboard, Inventory, Sales, Reports, Settings)
- **Top app bar:** Search + action icons (settings, notifications)

---

## 5. Elevation & Depth

Depth through **tonal layers** and soft ambient shadows:

| Level | Style | Usage |
|-------|-------|-------|
| **Level 0** | `#F8F9FA` | Background |
| **Level 1** | White + 1px border `#ECEFF1` or shadow (blur 8px, Y 2px, 4% black) | Cards, surfaces |
| **Level 2** | White + ambient shadow (blur 20px, Y 10px, 8% black) | Dropdowns, modals |

Shadows are soft — never harsh or pure black.

---

## 6. Shapes & Roundness

| Token | Value | Usage |
|-------|-------|-------|
| `sm` | 4px (0.25rem) | Minor elements |
| `DEFAULT` / `md` | 8px (0.5rem) | Buttons, inputs, standard interactive elements |
| `md` | 12px (0.75rem) | Cards |
| `lg` | 16px (1rem) | Dashboard cards, modals, major containers |
| `xl` | 24px (1.5rem) | Signature large containers |
| `full` | 9999px | Chips, tags, pill-shaped elements |

---

## 7. Components

### 7.1 Buttons

| Variant | Style | Usage |
|---------|-------|-------|
| **Primary** | Solid `#1A237E` bg, white text, 8px radius | High-emphasis actions (New Sale, Add Item, Save Changes) |
| **Secondary** | Outlined 1px `#1A237E`, indigo text | Secondary actions (Edit Profile, Contact Customer) |
| **Ghost** | No bg/border, indigo text | Table row actions, low emphasis |
| **Icon buttons** | Icon-only (e.g., `search`, `settings`, `more_vert`) | Utility actions in headers |

### 7.2 Input Fields

- Filled style with light grey background (`#F1F3F4`)
- Bottom-only border that transforms to full 1px indigo border on focus
- Labels use `label-md` in `#454652` (on-surface-variant)
- Common fields: Search bars, form inputs, dropdown selectors

### 7.3 Cards

- White background (`#ffffff`)
- 20px border radius (approximating `rounded-lg`)
- Subtle 1px border (`#ECEFF1`) instead of heavy shadows
- Used for: Dashboard stat widgets, product items, warranty info

### 7.4 Chips & Tags

- High-pill roundedness (full/32px)
- Used for: Stock status indicators, filter chips, category pills
- **In Stock:** Light green bg, dark green text + `check_circle` icon
- **Low Stock:** Amber bg, dark amber text + `warning` icon
- **Out of Stock:** Light red bg, dark red text + `error` icon
- **Overstock:** Neutral bg + `inventory_2` icon
- **Category filter chips:** Outlined, toggleable state (e.g., All Items, Laptops, Smartphones)

### 7.5 Inventory List / Data Table

- Row-based layout with subtle dividers
- **No alternating row colors** — hover state (`#F8F9FA`) indicates focus
- Columns: Product (image + name + description), SKU, Category, Stock, Status, Price, Actions
- Pagination at bottom (e.g., "Showing 1 to 4 of 420 entries" with page numbers)

### 7.6 Navigation

- **Bottom navigation bar:** 5 persistent tabs
  - Dashboard (`dashboard` icon)
  - Inventory (`inventory` icon)
  - Sales (`receipt_long` icon)
  - Reports (`bar_chart` icon)
  - Settings (`settings` icon)
- Active tab highlighted with primary color

### 7.7 Stat Cards (Dashboard)

- Icon + label + value layout
- 4-card grid: Total Products, Available Stock, Today's Sales, Low Stock
- Each card has a distinct icon and color accent

### 7.8 Quick Action Buttons (Dashboard)

- 3 horizontal action buttons: New Sale (`point_of_sale`), Scan (`qr_code_scanner`), Add Stock (`add_box`)
- Full-width row with icons and labels

### 7.9 Settings Menu

- List of setting categories with icons: Profile, Shop Information, Inventory Settings, Notifications, Data Backup, Support
- Each item expands to a detail section with form fields or info rows
- Info rows show label on left, value on right with `chevron_right` indicator

### 7.10 Profile / Customer Header

- Avatar/icon + name + badge (e.g., "Premium Retail Partner" with `verified` icon)
- Contact info: Email, phone, shipping address
- Stat badges: Total Orders, Lifetime Value

### 7.11 Warranty Cards

- Card with icon, status badge ("Active" / "Expiring Soon"), product info, serial number, expiry date, and download action

### 7.12 Splash Screen

- App logo/name centered ("Smart Stock")
- Clean, minimal layout on splash

---

## 8. Iconography

- **Icon set:** Material Icons (filled style)
- **Common icons:** `search`, `settings`, `dashboard`, `inventory`, `receipt_long`, `bar_chart`, `add`, `more_vert`, `chevron_left`, `chevron_right`, `check_circle`, `warning`, `error`, `inventory_2`, `smartphone`, `laptop_mac`, `headphones`, `cable`, `point_of_sale`, `qr_code_scanner`, `add_box`, `person`, `storefront`, `notifications`, `backup`, `help`, `mail`, `phone`, `location_on`, `verified`, `arrow_back`, `arrow_forward`
- Icons used in: Navigation, stat cards, table rows, action buttons, settings menu, contact info, status indicators

---

## 9. Screen Inventory

| Screen Title | Width × Height | Key Content |
|-------------|----------------|-------------|
| Splash Screen | 780 × 1768 | App logo + name |
| Dashboard | 940 × 2842 | Stats, quick actions, recent sales, top selling |
| Inventory | 940 × 2660 | Search, filters, product data table with pagination |
| Add Product | 780 × 3084 | Product form fields |
| Product List | 940 × 3846 | Product catalog listing |
| Product Details | 780 × 3832 | Full product info |
| Category Management | 940 × 3112 | Category CRUD |
| New Sale | 940 × 2904 | Sale creation form |
| Sales History | 940 × 2640 | Past transactions table |
| Today's Sales | 780 × 1978 | Current day sales |
| Customer Details | 940 × 4126 | Profile, purchase history, warranties |
| Warranty Check | 940 × 2898 | Warranty lookup |
| Reports & Analytics | 944 × 3822 | Charts and data reports |
| Settings | 940 × 2292 | Profile, shop info, preferences |

---

## 10. Responsive Behavior

- Screens designed primarily for mobile (390px canvas width in instances)
- Fluid grid adapts from 12 columns (desktop) → 8 columns (tablet) → 4 columns (mobile)
- Padding scales: desktop 32px → tablet 24px → mobile 16px
- Gutter scales: 24px → 16px → 12px
- Inventory tables: compact mode on mobile reverts to 8px internal padding
