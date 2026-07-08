<div align="center">
  <img src="assets/logo/SmartStock%20logo.jpg" alt="SmartStock Logo" width="120" height="120">
  <h1>SmartStock</h1>
  <p><strong>Complete Electronics Retail Inventory & POS Management System</strong></p>
  <p>
    <img src="https://img.shields.io/badge/Flutter-3.11+-blue?logo=flutter" alt="Flutter">
    <img src="https://img.shields.io/badge/Dart-3.11+-blue?logo=dart" alt="Dart">
    <img src="https://img.shields.io/badge/Firebase-FFCA28?logo=firebase" alt="Firebase">
    <img src="https://img.shields.io/badge/Provider-State%20Management-green" alt="Provider">
  </p>
</div>

---

## 📋 Complete Project Overview

**SmartStock** is a cross-platform (Android, iOS, Web, Windows) inventory management and point-of-sale (POS) application built with **Flutter & Firebase**. Designed specifically for **electronics retail businesses**, it provides end-to-end control over product inventory, sales transactions, serial number tracking, warranty management, customer relationships, replacement workflows, and business analytics — all powered by **Firebase Firestore** real-time database with **Google Sheets** automated backup.

**Developer:** Mohammad Arafath Uddin
**Platform:** Flutter 3.11+ | Dart 3.11+
**Backend:** Firebase Firestore (NoSQL, real-time)
**State Management:** Provider (ChangeNotifier pattern)
**Architecture Pattern:** Feature-based modular with Service + Repository + Provider layers

---

## 📱 Complete Features — Part by Part

### 1. DASHBOARD (Home Screen)

The dashboard is the central hub showing business performance at a glance.

**Stats Overview Cards (6 cards in 2-column grid):**
| Card | Data Source | What It Shows |
|------|-------------|---------------|
| **Total Products** | Firestore products collection count | Total number of product SKUs |
| **Total Stock** | Serial numbers with status="available" | Total individual units in stock |
| **Stock Value** | Sum of (sellingPrice × availableQuantity) | Total inventory value in currency |
| **Sold Today** | Today's sales query | Quantity of items sold today |
| **Low Stock** | Products where 0 < qty ≤ threshold | Items running low (threshold: 5) |
| **Out of Stock** | Products where availableQuantity = 0 | Items that need restocking |

Each card has:
- Animated gradient progress bar
- Color-coded icon with subtle background
- Tap navigation to related section

**Key Metrics Header:**
- Today's total revenue (formatted currency)
- Today's total profit
- Profit margin percentage

**Business Health Score:**
- Circular progress indicator (0-100%)
- Based on weighted calculation of: stock availability, sales velocity, inventory turnover, low stock ratio

**Charts & Trends:**
- **Sales Trend** — 7-day daily sales bar (blue bars)
- **Profit Trend** — 7-day daily profit bar (green bars)
- Auto-refreshes every 30 seconds

**Sections below the fold:**
- **Top Selling Products** — Top 5 products ranked by sales volume with rank badges (🥇🥈🥉)
- **Recent Activity** — Timeline of recently added & sold products
- **Quick Actions** — Grid of shortcut buttons: New Sale, Add Product, Inventory, Warranty Check
- **Business Stats** — Additional metrics like stock turnover rate

**Technical Implementation:**
- `DashboardProvider` calls `DashboardService.getDashboardStats()`
- Runs 11 Firestore queries in parallel via `Future.wait`
- Queries include: categories count, products count, available serials count, today's sales aggregation, low stock count, out of stock count, top selling products (last 100 sales), recently added products, recently sold products, 7-day daily sales, stock value computation

---

### 2. PRODUCT MANAGEMENT

Full product lifecycle management with serial number tracking.

**Product Fields (15 fields):**
```
id, categoryId, categoryName, brandName, productName, modelNumber,
imageUrl, description, purchasePrice, sellingPrice,
warrantyMonths, warrantyDays, availableQuantity, soldQuantity, createdAt
```

**Features:**
| Feature | Description |
|---------|-------------|
| **Add Product** | Form with image picker (camera/gallery → imgBB hosting), category selector, price inputs, warranty configuration, serial number batch entry |
| **Edit Product** | Full edit with pre-populated fields |
| **Delete Product** | Removes product + all associated serial numbers from Firestore |
| **View Details** | Full product info, serial number list with status indicators, edit/delete options |
| **List View** | Grid (2-column) or List toggle, sort by newest/oldest |
| **Search** | Client-side filtering by product name, brand, model number |
| **Category Filter** | Horizontal chip bar to filter by category |
| **Stock Stats Bar** | Mini stats: Total / In Stock / Low Stock / Out of Stock counts |
| **Barcode Scan** | Scan QR/barcode to look up product instantly |

**Serial Number System:**
- Each product can have multiple serial numbers
- Serial tracking: `serial_numbers/{id}` with fields: `productId, serialNumber, status`
- Statuses: `available`, `sold`, `defective`
- Duplicate serial prevention via `checkDuplicateSerial()`
- Real-time stock count via Firestore count queries
- Bulk serial addition in add/edit product screens

---

### 3. POINT OF SALE (POS) SYSTEM

Complete sales workflow with barcode scanning and cart management.

**Sale Flow (2-step wizard):**

**Step 1 — Customer Information:**
- Customer Name (optional, auto-generates if empty)
- Phone Number
- Clean form with validation

**Step 2 — Cart Review:**
- List of cart items grouped by product
- Each cart item shows: product name, serial numbers with individual prices
- **Per-serial delete** — Remove individual serials from cart
- **Bulk delete** — Remove entire product group
- Cart summary: total items count, total amount
- "Add" button to add more items

**Adding Items to Cart (2 methods):**

**Method A — Barcode Scan:**
1. Scan QR/barcode via device camera
2. Automatic lookup: `findProductBySerialNumber(code)`
3. Validates: serial exists, is available, not already in cart, stock remaining
4. Shows price/warranty confirmation dialog
5. Sale price & warranty editable per-item
6. Adds to cart with serial number

**Method B — Manual Selection (Bottom Sheet):**
1. Category chips for filtering
2. Product list with search
3. Select product → shows available serial numbers with checkboxes
4. Editable sale price & warranty
5. Multi-select serials → "Add to Cart"
6. Supports warranty unit: day/month/year

**Sale Submission:**
- Maps cart items to flat list of sale records
- Each sale record includes: serialNumberId, serialNumber, productId, productName, modelNumber, imageUrl, categoryId, categoryName, salePrice, purchasePrice, warrantyExpiryDate, warrantyMonths
- Bulk creates sales via `SaleProvider.bulkCreateSales()`
- Auto-generates customer ID if not provided
- Success → navigates to dashboard

**Sales History:**
- Paginated list with date sorting
- Each sale shows: product name, serial number, sale price, customer, date
- Sale details screen with full transaction info
- Option to view today's sales only

**Technical:**
- Cart state managed locally (not persisted) within `_SaleFormState`
- Prevents duplicate serials via `_scannedSerialNumbers` Set
- Stock availability check before adding
- `mounted` checks after all async gaps

---

### 4. NAVIGATION SYSTEM

**Bottom Navigation Bar (GNav):**
| Tab | Index | Icon | Screen |
|-----|-------|------|--------|
| Dashboard | 0 | `grid_view` | Dashboard |
| Products | 1 | `inventory_2` | Product List |
| Sale | 2 | `add_circle` | New Sale (POS) |
| Analytics | 3 | `analytics` | Analytics Reports |
| Profile | 4 | `person` | Settings |

**Technical Implementation:**
- Package: `google_nav_bar ^5.0.7`
- **IndexedStack** — All 5 tab screens stay alive in memory, instant switching with zero navigation
- **Glassmorphism** — `BackdropFilter` with `ImageFilter.blur(sigmaX: 20, sigmaY: 20)` for frosted glass effect
- **extendBody: true** — Page content extends behind the nav bar
- **Semi-transparent** — `surface.withAlpha(230)` so content is partially visible
- **Rounded corners** — 24px border radius on the nav bar container
- **Haptic feedback** on tab change
- **300ms easeOutCubic animation**
- **FAB (Floating Action Button)** — Only on Products tab, expandable with 3 quick actions:
  - Add Product → `/products/add`
  - Warranty → `/warranty`
  - Issue → `/product-issues`

**Routing System:**
- 32 named routes defined in `AppRoutes` class
- `RouteGenerator.onGenerateRoute()` with switch-case mapping
- Routes like `/products/add` push as independent screens (with slide animation)
- Tab routes (`/`, `/products`, `/sales/new`, `/reports/analytics`, `/settings`) use ModernAppShell

---

### 5. ANALYTICS & REPORTS

Comprehensive business analytics with 3 time-period views.

**Tab 1 — Daily Report:**
- Revenue for today with formatted currency
- Hero card with animated gradient background
- Stats displayed: **Stock Value** (current total inventory value), **Profit**, **Margin%**
- Stats row: Transactions count, Items Sold count, Average Sale value
- Date badge: month/day/year

**Tab 2 — Monthly Report:**
- Month picker with prev/next navigation (handles year boundary correctly)
- Hero card: revenue, stock value, profit, margin
- Stats row: transactions, items sold, average sale
- Proper year tracking — crossing December increments year, January decrements year

**Tab 3 — Yearly Report:**
- Year picker (prev/next)
- Aggregated from 12 months of data
- Hero card: total yearly revenue, stock value, profit, margin
- Stats row: total transactions, total items sold, average per month

**Additional Sections:**
- **All-Time Summary** — Total sales, total profit, total transactions, total items sold (with animated counters using `AnimationController`)
- **Sales by Category** — Progress bars for each category's sales contribution
- **Top Selling Products** — Ranked list with medal colors (gold/silver/bronze)
- **Sales Trend Chart** — Monthly bar chart using custom `SalesBarChart` widget

**Report Provider Data Sources (6 parallel queries):**
- Daily report: Firestore sales query for current date
- Monthly report: Firestore sales query for selected month/year
- Yearly report: 12 monthly queries for selected year
- Category sales: Aggregated sales grouped by category
- Top selling products: Top 10 by revenue
- All-time summary: Complete sales aggregation

---

### 6. INVENTORY MANAGEMENT

Complete stock visibility and control.

**Inventory List:**
- Each item shows: product image, name, model, available stock, sold stock, stock status badge
- **Stock Status Colors:**
  - 🟢 **In Stock** (> 5 units) — Green
  - 🟡 **Low Stock** (1-5 units) — Yellow
  - 🔴 **Out of Stock** (0 units) — Red
  - 🔵 **Overstock** (> 100 units) — Blue

**Filters:**
- Category dropdown filter
- Brand text search
- Stock status filter (all / in stock / low / out / overstock)

**Stock Details Screen (per product):**
- Full product info with image
- Purchase price & selling price display
- Available stock count, sold count, defective count
- Open issues count
- Serial numbers list with individual status indicators
- Total serials summary

**Summary Cards:**
- Total Products count
- Total Available stock units
- Low Stock count
- Out of Stock count

**Technical:**
- `InventoryProvider` holds `List<InventoryItem>` with computed `stockStatus`
- `InventoryService.getInventory()` queries products collection then enriches with serial counts
- `computeStockStatus()` static method with configurable thresholds (default: low=5, overstock=100)

---

### 7. WARRANTY SYSTEM

Complete warranty lifecycle management.

**Warranty Check:**
- Search by **serial number** or **model number**
- Real-time results as you type
- Results show: product name, serial number, purchase date, warranty expiry date, days remaining
- **Status badges:** Active (green), Expired (red), Claimed (orange)
- Days remaining counter (e.g., "245 days remaining")

**Warranty Claim Processing:**
- Submit claim against a warranty record
- Claim form with reason/details
- Claim status tracking
- Linked to replacement workflow

**Technical:**
- `WarrantyProvider` with methods: `searchWarranty()`, `loadActiveWarranties()`, `loadExpiredWarranties()`, `processClaim()`
- Warranty records created automatically during sale (warranty expiry = sale date + warranty months/days)
- Serial number picker dialog for selecting from available serials

---

### 8. CUSTOMER MANAGEMENT

**Customer List:**
- All customers with auto-generated IDs if name not provided
- Each customer tile shows: name, phone, total purchases count
- Search by name or phone

**Customer Details:**
- Profile section with name, phone, auto-generated ID
- Total spent amount (lifetime value)
- Total orders count
- Purchase history table: date, product name, serial number, amount
- Scrollable purchase history with pagination

**Technical:**
- `CustomerProvider` with Firestore real-time stream
- Customers created automatically during sales
- Purchase history aggregated from sales collection

---

### 9. PRODUCT ISSUES & REPLACEMENTS

**Product Issues:**
- Log issues against specific serial numbers
- Issue form: serial number lookup, description, date
- Issue list with status (open/resolved)
- Issue details screen with full information
- Resolve issues with notes

**Replacements:**
- Replacement workflow: initiate → approve/reject → complete
- Each replacement tracks: old serial number, new serial number, reason, date, status
- Replacement list with status badges
- Replacement details with full timeline
- Add replacement screen with serial lookup

**Technical:**
- `ProductIssueProvider` for issue CRUD
- `ReplacementProvider` for replacement workflow
- Both use Firestore real-time streams
- Linked to sales data for traceability

---

### 10. DAILY ADDITIONS

Track daily stock intake:
- Date picker for filtering
- List of products added on selected date
- Each entry: product name, quantity added, timestamp
- Integrated with product creation — each new product auto-creates a daily addition record

**Technical:**
- `DailyAdditionProvider` with date-filtered Firestore query
- `DailyAdditionModel` with fields: productId, productName, date, quantity

---

### 11. SETTINGS

**Shop Profile:**
- Owner name & email (editable)
- Store name (editable)

**Currency:**
- 10 currencies support: USD, EUR, GBP, BDT, INR, PKR, JPY, AUD, CAD, SGD
- Each with proper symbol ($, €, £, ৳, ₹, etc.)
- Persisted to Firestore

**Timezone:**
- 20+ timezone options
- Persisted to Firestore

**Stock Thresholds:**
- Low stock threshold (default: 5 units)
- Overstock threshold (default: 100 units)
- Editable via dialog with validation

**Data:**
- Download all data as CSV (placeholder)

**About:**
- App version display

**Technical:**
- `SettingsProvider` loads single document from Firestore `settings` collection
- All settings persisted across sessions
- Currency symbol helper in `SettingsService`

---

### 12. GOOGLE SHEETS BACKUP

Automated backup system for data redundancy.

**Features:**
- Auto-backup with Firestore real-time change listeners
- Debounced sync (2-second delay after last change)
- Manual sync with loading indicator
- Sync status tracking per collection
- Connection diagnostics

**Collections Synced (7):**
1. Categories
2. Products
3. Serial Numbers
4. Sales
5. Customers
6. Product Issues
7. Replacements

**Sync Dashboard:**
- Individual sync buttons per collection
- Last synced timestamp
- Sync status indicators
- Auto-sync toggle
- Spreadsheet configuration (service account email, spreadsheet ID)

**Technical:**
- `SyncProvider` with `ChangeNotifier`
- Uses `googleapis` package for Google Sheets API v4
- Service account authentication
- Sheet created automatically per collection
- Write verification with error tracking
- Auto-sync starts on app launch if configured

---

### 13. SEARCH

Global search across multiple entities:
- **Products** — Search by name, brand, model
- **Customers** — Search by name, phone
- **Sales** — Search by product name, serial number, customer

**Technical:**
- Client-side filtering with `where()` on already-loaded data
- Results displayed in tabs
- Tap result → navigate to detail screen

---

### 14. SPLASH SCREEN

- Animated splash with app logo
- Auto-navigates to dashboard after 2 seconds
- Firebase initialized before splash

---

### 15. UI/UX DESIGN SYSTEM

**Color Palette:**
| Color | Hex | Usage |
|-------|-----|-------|
| Primary Blue | `#2563EB` | Buttons, active states, links |
| Purple | `#7C3AED` | Analytics, tertiary actions |
| Green | `#10B981` | Success, in-stock status |
| Orange | `#F59E0B` | Warnings, low stock |
| Red | `#EF4444` | Errors, out of stock |
| Surface | `#FFFFFF` | Cards, backgrounds |
| Background | `#F8FAFC` | Scaffold background |

**Typography:**
- **Headings:** Hanken Grotesk (bold, clean)
- **Body:** Inter (readable, modern)
- **Labels/Mono:** Geist (technical data, serial numbers)

**Design Elements:**
- **Glassmorphism:** `BackdropFilter` with blur for nav bar and hero cards
- **Rounded corners:** 12px buttons, 16px cards, 20px dialogs, 24px nav bar
- **Shadows:** Subtle elevation with colored shadow accents
- **Gradients:** Linear gradients for cards, buttons, and hero sections
- **Animations:** `flutter_animate`, `AnimatedBuilder`, `AnimationController`
- **Loading:** Shimmer skeleton screens for dashboard, products, and analytics
- **Dark Mode:** Full dark theme support with proper color mapping

**Navigation Bar:**
- 5-tab GNav with pill-style indicators
- Frosted glass background (BackdropFilter blur)
- Floating design with 24px rounded corners
- 12px horizontal margin, bottom padding for safe area
- 300ms easeOutCubic animation on tab switch
- Haptic feedback on interaction
- Expandable FAB on Products tab

---

## 🏗️ Architecture Deep Dive

### State Management (Provider Pattern)

```
                  Widget Tree
                      ↓ (context.watch)
              ChangeNotifier Provider
                      ↓ (method call)
                  Repository
                      ↓
                  Service
                      ↓
              Firebase Firestore
                      ↓ (Future / Stream)
                  Service
                      ↓
                  Repository
                      ↓ (data)
              ChangeNotifier Provider
                      ↓ (notifyListeners)
                  Widget Tree (rebuild)
```

**14 Providers registered in main.dart via MultiProvider:**

| Provider | Purpose | Data Source |
|----------|---------|-------------|
| `DashboardProvider` | Home screen stats | Firestore count + aggregation queries |
| `CategoryProvider` | Category CRUD | Firestore real-time stream |
| `ProductProvider` | Product CRUD + serials | Firestore real-time stream |
| `InventoryProvider` | Stock view with filters | Firestore query |
| `SaleProvider` | Sales CRUD + history | Firestore real-time stream |
| `CustomerProvider` | Customer profiles | Firestore real-time stream |
| `SettingsProvider` | App configuration | Firestore single doc |
| `SyncProvider` | Google Sheets backup | Firestore listeners + Sheets API |
| `DailyAdditionProvider` | Daily stock additions | Firestore date-filtered query |
| `WarrantyProvider` | Warranty check + claims | Firestore query |
| `ReportProvider` | Analytics reports | Firestore aggregation queries |
| `ProductIssueProvider` | Issue tracking | Firestore real-time stream |
| `ReplacementProvider` | Replacement workflow | Firestore real-time stream |

### Firebase Data Model (10 Collections)

```
categories/{id}
  ├── name: String
  ├── icon: String
  └── color: int

products/{id}
  ├── categoryId: String
  ├── categoryName: String
  ├── brandName: String
  ├── productName: String
  ├── modelNumber: String
  ├── imageUrl: String
  ├── description: String
  ├── purchasePrice: double
  ├── sellingPrice: double
  ├── warrantyMonths: int
  ├── warrantyDays: int
  ├── availableQuantity: int
  ├── soldQuantity: int
  └── createdAt: Timestamp

serial_numbers/{id}
  ├── productId: String
  ├── serialNumber: String
  └── status: String ("available" | "sold" | "defective")

sales/{id}
  ├── serialNumberId: String
  ├── serialNumber: String
  ├── productId: String
  ├── productName: String
  ├── modelNumber: String
  ├── imageUrl: String
  ├── categoryId: String
  ├── categoryName: String
  ├── salePrice: double
  ├── purchasePrice: double
  ├── profit: double
  ├── saleDate: Timestamp
  ├── customerId: String
  ├── customerName: String
  ├── customerPhone: String
  ├── warrantyMonths: int
  ├── warrantyExpiryDate: Timestamp
  └── saleType: String ("normal" | "replacement" | "warranty_claim")

customers/{id}
  ├── name: String
  ├── phone: String
  ├── totalOrders: int
  ├── totalSpent: double
  └── createdAt: Timestamp

settings/{id}
  ├── storeName: String
  ├── ownerName: String
  ├── ownerEmail: String
  ├── currency: String
  ├── currencySymbol: String
  ├── timezone: String
  ├── lowStockThreshold: int
  ├── overstockThreshold: int
  ├── sheetsServiceAccount: String
  └── sheetsSpreadsheetId: String

daily_additions/{id}
  ├── productId: String
  ├── productName: String
  ├── quantity: int
  ├── date: Timestamp
  └── createdAt: Timestamp

product_issues/{id}
  ├── productId: String
  ├── serialNumber: String
  ├── description: String
  ├── status: String
  ├── date: Timestamp
  └── resolvedDate: Timestamp

replacements/{id}
  ├── oldSerialNumber: String
  ├── newSerialNumber: String
  ├── reason: String
  ├── status: String
  └── date: Timestamp

warranty/{id}
  ├── productId: String
  ├── serialNumber: String
  ├── productName: String
  ├── customerName: String
  ├── saleDate: Timestamp
  ├── expiryDate: Timestamp
  ├── warrantyMonths: int
  └── status: String ("active" | "expired" | "claimed")
```

---

## 🔧 Packages & Dependencies (27 total)

```yaml
dependencies:
  flutter: sdk (Material 3)
  cupertino_icons: ^1.0.8          # iOS icons
  firebase_core: ^3.13.0            # Firebase initialization
  cloud_firestore: ^5.6.6           # Firestore DB
  provider: ^6.1.2                  # State management
  intl: ^0.20.2                     # Date/currency formatting
  cached_network_image: ^3.4.1      # Image caching
  image_picker: ^1.1.2              # Camera/gallery
  http: ^1.3.0                      # HTTP client (imgBB)
  googleapis: ^13.2.0               # Google Sheets API
  googleapis_auth: ^1.6.0           # Google auth
  google_fonts: ^6.2.1              # Custom fonts
  flutter_animate: ^4.5.2           # UI animations
  shimmer: ^3.0.0                   # Loading skeletons
  mobile_scanner: ^6.0.7            # Barcode/QR scanner
  flutter_dotenv: ^5.2.1            # .env config
  google_nav_bar: ^5.0.7            # Bottom navigation
```

---

## 🚀 Performance Optimizations Implemented

1. **IndexedStack Navigation** — Tab screens stay alive, instant switching, no rebuild
2. **Local Search** — Client-side filtering instead of Firestore queries on every keystroke
3. **Parallel Firestore Queries** — Dashboard loads 11 queries via `Future.wait`
4. **Provider.value** — Reuses existing providers instead of creating duplicates
5. **State Mutation in setState** — All state changes properly wrapped
6. **mounted Checks** — After all async operations to prevent memory leaks
7. **Debounced Google Sheets Sync** — 2-second debounce to batch changes
8. **Limit Queries** — Top selling (100), recently added (5), recently sold (50)
9. **ShrinkWrap + NeverScrollableScrollPhysics** — Nested lists don't fight scrolling
10. **TextOverflow.ellipsis** — Prevents text breaking in constrained layouts

---

## 🐛 Bugs Fixed During Development

| Bug | Solution |
|-----|----------|
| Navigation bar shake on tab switch | Replaced `pushNamedAndRemoveUntil` with `IndexedStack` |
| White box behind nav bar blocking content | Removed container background + added `extendBody` + BackdropFilter |
| Analytics month/year overflow | Added `_year` field that increments/decrements at December/January boundaries |
| Text breaking in analytics cards | Changed `_HeroStat` layout from Row to Column |
| Hardcoded dark skeleton | Changed `final isDark = true` to `Theme.of(context).brightness` |
| Duplicate provider instances | Removed redundant `CategoryProvider`/`ProductProvider` creation |
| State mutation outside setState | Moved `_scannedSerialNumbers.add()` inside `setState` |
| Redundant callback calls | Removed duplicate `onPriceChanged`/`onWarrantyValueChanged` from dialog confirm |
| Missing mounted check | Added `if (!mounted) return;` in settings initState |
| Cart couldn't remove individual serials | Added per-serial delete button and `onRemoveSerial` callback |

---

## 📱 App Screens (Complete List)

**32 Screens with Navigation:**

| # | Screen | Route | Bottom Nav |
|---|--------|-------|------------|
| 1 | Splash Screen | `/splash` | ❌ |
| 2 | Dashboard | `/` | ✅ Tab 0 |
| 3 | Product List | `/products` | ✅ Tab 1 |
| 4 | Add Product | `/products/add` | ❌ |
| 5 | Edit Product | `/products/edit` | ❌ |
| 6 | Product Details | `/products/details` | ❌ |
| 7 | Category Management | `/categories` | ❌ |
| 8 | Add Category | `/categories/add` | ❌ |
| 9 | Inventory List | `/inventory` | ❌ |
| 10 | Stock Details | `/inventory/stock-details` | ❌ |
| 11 | New Sale (POS) | `/sales/new` | ✅ Tab 2 |
| 12 | Today's Sales | `/sales/today` | ❌ |
| 13 | Sales History | `/sales/history` | ❌ |
| 14 | Sale Details | `/sales/details` | ❌ |
| 15 | Customer List | `/customers` | ❌ |
| 16 | Customer Details | `/customers/details` | ❌ |
| 17 | Daily Additions | `/daily-additions` | ❌ |
| 18 | Warranty Check | `/warranty` | ❌ |
| 19 | Warranty Details | `/warranty/details` | ❌ |
| 20 | Reports | `/reports` | ❌ |
| 21 | Analytics | `/reports/analytics` | ✅ Tab 3 |
| 22 | Product Issues | `/product-issues` | ❌ |
| 23 | Issue Details | `/product-issues/details` | ❌ |
| 24 | Replacements | `/replacements` | ❌ |
| 25 | Replacement Details | `/replacements/details` | ❌ |
| 26 | Settings | `/settings` | ✅ Tab 4 |
| 27 | Global Search | `/search` | ❌ |
| 28 | Barcode Scanner | (pushed) | ❌ |
| 29 | Sync Dashboard | (pushed from settings) | ❌ |
| 30 | Warranty Claim | (pushed) | ❌ |
| 31 | Add Product Issue | (pushed) | ❌ |
| 32 | Add Replacement | (pushed) | ❌ |

---

## 📊 Data Flow Diagrams

### Real-time Stream (Products, Categories, Customers, Sales)
```
Firestore.snapshots() → Provider → notifyListeners() → Widget rebuild
```

### On-demand Query (Dashboard, Reports)
```
User action → Provider.loadData() → Service.getData() → Firestore.get()
    → Future completes → Provider._data = result → notifyListeners() → rebuild
```

### Sale Creation Flow
```
User fills cart → taps "Complete Sale"
    → SaleForm._submitSale()
    → Maps cart items to sale records
    → SaleProvider.bulkCreateSales()
    → Firestore batch write (all sales + serial status updates)
    → Success → Navigate to Dashboard
```

### Warranty Creation Flow
```
During sale: warrantyMonths × 30 days from sale date
    → Stored in sale document as warrantyExpiryDate
    → Separate warranty collection document created
    → WarrantyProvider loads active/expired queries
```

---

## 🔐 Environment & Security

- API keys stored in `.env` file (excluded from git via `.gitignore`)
- Firebase security rules for Firestore access
- imgBB API key managed via `flutter_dotenv`
- Google Sheets service account authentication
- No hardcoded secrets in source code

---

## 📁 Complete Project Structure (lib/)

```
lib/
├── main.dart                          # App entry, MultiProvider, MaterialApp
├── firebase_options.dart              # Firebase config (auto-generated)
│
├── core/
│   ├── constants/
│   │   ├── api_constants.dart         # imgBB API config
│   │   ├── app_constants.dart         # Thresholds, limits
│   │   ├── color_constants.dart       # Color definitions
│   │   └── firestore_constants.dart   # Collection names
│   │
│   ├── routes/
│   │   ├── app_routes.dart            # 32 route name constants
│   │   └── route_generator.dart       # Switch-case route mapping
│   │
│   ├── services/
│   │   ├── firestore_service.dart     # Generic Firestore CRUD
│   │   └── imgbb_service.dart         # Image upload to imgBB
│   │
│   ├── theme/
│   │   ├── app_colors.dart            # 100+ color constants
│   │   ├── app_theme.dart             # Material 3 ThemeData
│   │   └── text_styles.dart           # Typography scale
│   │
│   ├── utils/
│   │   ├── date_utils.dart            # Date formatting helpers
│   │   ├── formatters.dart            # Currency, number formatting
│   │   └── validators.dart            # Form validation rules
│   │
│   └── widgets/
│       ├── debounced.dart             # Debounced callback wrapper
│       ├── empty_state.dart           # Empty state placeholder
│       ├── error_widget.dart          # Error display component
│       ├── glass_card.dart            # Glassmorphism card
│       ├── global_search.dart         # Cross-entity search widget
│       ├── loading_skeleton.dart      # Shimmer skeleton loader
│       ├── modern_app_shell.dart      # Main app shell with GNav
│       ├── search_field.dart          # Reusable search input
│       ├── stat_card.dart             # Stats display card
│       └── status_badge.dart          # Color-coded status badge
│
├── features/
│   ├── categories/                    # Category CRUD
│   │   ├── models/category_model.dart
│   │   ├── providers/category_provider.dart
│   │   ├── repositories/category_repository.dart
│   │   ├── screens/add_category_screen.dart
│   │   ├── screens/category_management_screen.dart
│   │   ├── services/category_service.dart
│   │   └── widgets/ (4 files)
│   │
│   ├── customers/                     # Customer CRM
│   │   ├── models/customer_model.dart
│   │   ├── providers/customer_provider.dart
│   │   ├── repositories/customer_repository.dart
│   │   ├── screens/customer_details_screen.dart
│   │   ├── screens/customer_list_screen.dart
│   │   ├── services/customer_service.dart
│   │   └── widgets/ (3 files)
│   │
│   ├── daily_additions/              # Daily stock intake
│   │   ├── models/daily_addition_model.dart
│   │   ├── providers/daily_addition_provider.dart
│   │   └── screens/daily_additions_screen.dart
│   │
│   ├── dashboard/                     # Home screen
│   │   ├── models/dashboard_stats_model.dart
│   │   ├── providers/dashboard_provider.dart
│   │   ├── repositories/dashboard_repository.dart
│   │   ├── screens/dashboard_screen.dart
│   │   ├── services/dashboard_service.dart
│   │   └── widgets/ (5 files)
│   │
│   ├── integrations/                  # Google Sheets
│   │   ├── providers/sync_provider.dart
│   │   ├── screens/sync_dashboard_screen.dart
│   │   └── services/ (2 files)
│   │
│   ├── inventory/                     # Stock management
│   │   ├── models/inventory_model.dart
│   │   ├── providers/inventory_provider.dart
│   │   ├── repositories/inventory_repository.dart
│   │   ├── screens/inventory_screen.dart
│   │   ├── screens/stock_details_screen.dart
│   │   ├── services/inventory_service.dart
│   │   └── widgets/ (3 files)
│   │
│   ├── product_issues/               # Issue tracking
│   │   ├── models/product_issue_model.dart
│   │   ├── providers/product_issue_provider.dart
│   │   ├── screens/add_product_issue_screen.dart
│   │   ├── screens/product_issue_details_screen.dart
│   │   ├── screens/product_issue_list_screen.dart
│   │   └── services/product_issue_service.dart
│   │
│   ├── products/                      # Product management
│   │   ├── models/product_model.dart
│   │   ├── providers/product_provider.dart
│   │   ├── repositories/product_repository.dart
│   │   ├── screens/add_product_screen.dart
│   │   ├── screens/edit_product_screen.dart
│   │   ├── screens/product_details_screen.dart
│   │   ├── screens/product_list_screen.dart
│   │   ├── services/product_service.dart
│   │   └── widgets/ (4 files)
│   │
│   ├── replacements/                 # Replacement workflow
│   │   ├── models/replacement_model.dart
│   │   ├── providers/replacement_provider.dart
│   │   ├── screens/add_replacement_screen.dart
│   │   ├── screens/replacement_details_screen.dart
│   │   ├── screens/replacement_list_screen.dart
│   │   └── services/replacement_service.dart
│   │
│   ├── reports/                       # Analytics & reports
│   │   ├── models/report_model.dart
│   │   ├── providers/report_provider.dart
│   │   ├── repositories/report_repository.dart
│   │   ├── screens/analytics_screen.dart
│   │   ├── screens/reports_screen.dart
│   │   ├── services/report_service.dart
│   │   └── widgets/ (4 files)
│   │
│   ├── sales/                         # POS & sales
│   │   ├── models/sale_model.dart
│   │   ├── models/serial_number_model.dart
│   │   ├── providers/sale_provider.dart
│   │   ├── repositories/sale_repository.dart
│   │   ├── screens/new_sale_screen.dart
│   │   ├── screens/sale_details_screen.dart
│   │   ├── screens/sales_history_screen.dart
│   │   ├── screens/todays_sales_screen.dart
│   │   ├── services/sale_service.dart
│   │   └── widgets/ (4 files)
│   │
│   ├── search/                        # Global search
│   │   ├── screens/search_screen.dart
│   │   └── widgets/search_result_tile.dart
│   │
│   ├── settings/                      # App settings
│   │   ├── providers/settings_provider.dart
│   │   ├── screens/settings_screen.dart
│   │   ├── services/settings_service.dart
│   │   └── widgets/ (2 files)
│   │
│   ├── splash/                        # Splash screen
│   │   └── screens/splash_screen.dart
│   │
│   └── warranty/                      # Warranty management
│       ├── models/warranty_model.dart
│       ├── providers/warranty_provider.dart
│       ├── repositories/warranty_repository.dart
│       ├── screens/warranty_check_screen.dart
│       ├── screens/warranty_claim_screen.dart
│       ├── screens/warranty_details_screen.dart
│       ├── services/warranty_service.dart
│       └── widgets/ (4 files)
│
└── test/                              # Test files
```

---

## 📄 Total File Count: ~130 files in lib/
**Total Features: 14 feature modules**
**Language: Dart (100%)**
**Platforms: Android, iOS, Web, Windows**

---

<p align="center">
  <b>Built with Flutter & Firebase</b><br>
  <i>Developer: Mohammad Arafath Uddin</i>
</p>
