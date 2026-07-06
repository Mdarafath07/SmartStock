<div align="center">
  <img src="assets/logo/SmartStock%20logo.jpg" alt="SmartStock Logo" width="120" height="120">
  <h1>SmartStock</h1>
  <p><strong>Electronics Retail Inventory Management System</strong></p>
  <p>
    <img src="https://img.shields.io/badge/Flutter-3.11+-blue?logo=flutter" alt="Flutter">
    <img src="https://img.shields.io/badge/Dart-3.11+-blue?logo=dart" alt="Dart">
    <img src="https://img.shields.io/badge/Firebase-FFCA28?logo=firebase" alt="Firebase">
    <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
  </p>
</div>

---

## Overview

SmartStock is a cross-platform inventory management application built with Flutter, designed specifically for **electronics retail businesses**. It provides complete control over product inventory, sales tracking, warranty management, customer relations, and business analytics — all backed by Firebase Firestore with integrated Google Sheets backup.

---

## Features

### Dashboard
- **Stats Overview** — Total categories, products, stock quantity, today's sales, low stock & out-of-stock counts
- **Sales & Profit Chart** — 7-day daily sales and profit visualization
- **Top-Selling Products** — Best performers ranked by sales volume
- **Recent Activity** — Recently added and sold products
- **Quick Search** — Cross-entity search bar for instant lookups

### Product Management
- **Full CRUD** — Add, edit, delete products with rich details
- **Fields** — Product name, brand, model number, category, purchase/selling price, warranty period, description
- **Image Upload** — Camera/gallery image upload via imgBB hosting
- **Barcode Scanning** — Scan product barcodes/QR codes using device camera
- **Serial Number Tracking** — Track individual units by serial number

### Category Management
- Customizable categories with Material icon picker and color coding

### Inventory
- **Stock Status** — Auto-calculated status (in stock, low stock, out of stock, overstock)
- **Filters** — Search, category filter, stock status filter
- **Summary Cards** — Aggregated stock metrics at a glance

### Sales Management
- **New Sale** — Create sales with serial number assignment, profit calculation, warranty tracking
- **Sale Types** — Normal sale, replacement, warranty claim
- **Sales History** — Paginated history with date range filtering
- **Today's Sales** — Quick view of current day transactions

### Customer Management
- **CRM** — Customer profiles with purchase history, lifetime value, total orders

### Warranty Management
- **Warranty Check** — Lookup by serial number; see active/expired status
- **Claim Processing** — Submit warranty claims with replacement tracking

### Product Issues & Replacements
- **Issue Tracking** — Log and resolve product issues per serial number
- **Replacement Workflow** — Track replacements with old/new serial numbers, status, and reason

### Daily Additions
- Track stock additions per product with quantity, pricing, notes, and reminders

### Reports & Analytics
- **Report Dashboard** — Sales, profit, inventory, warranty reports
- **Analytics Screen** — Charts and statistics
- **Download Reports** — Exportable report data

### Settings
- **Store Profile** — Owner name, store name, contact
- **Currency & Timezone** — 10 currencies, 20 timezones
- **Stock Thresholds** — Configurable low-stock and overstock limits
- **Google Sheets Backup** — Configure service account and spreadsheet ID

### Integrations
- **Google Sheets Backup** — Full Firestore collection backup to Google Sheets with:
  - Automatic sheet creation per collection
  - Two-way data sync
  - Daily auto-sync on data changes
  - Monthly report generation
  - Write verification & error tracking
  - Connection diagnostic tools

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.11+ (Dart 3.11+) |
| **State Management** | Provider (ChangeNotifier) |
| **Architecture** | Service + Repository + Provider |
| **Backend** | Firebase Firestore |
| **Image Hosting** | imgBB API |
| **Backup** | Google Sheets API v4 |
| **Barcode** | mobile_scanner |
| **Fonts** | Google Fonts (Hanken Grotesk, Inter, Geist) |
| **Animations** | flutter_animate, shimmer |

---

## Project Structure

```
lib/
  main.dart                             # App entry point
  firebase_options.dart                 # Firebase configuration
  core/
    constants/                          # Api keys, app config, colors, firestore refs
    routes/                             # Named routes & route generator
    services/                           # Firestore CRUD wrapper, imgBB upload
    theme/                              # Material 3 theme, colors, text styles
    utils/                              # Date utils, formatters, validators
    widgets/                            # Reusable components (shell, cards, search, etc.)
  features/
    categories/                         # Category CRUD with icon picker
    customers/                          # Customer profiles & purchase history
    daily_additions/                    # Daily stock addition tracking
    dashboard/                          # Stats, charts, overview widgets
    integrations/                       # Google Sheets backup & sync
    inventory/                          # Stock table, filters, drilldown
    product_issues/                     # Issue logging & resolution
    products/                           # Full product management
    replacements/                       # Replacement order workflow
    reports/                            # Analytics & report downloads
    sales/                              # POS-like sales entry & history
    search/                             # Global cross-entity search
    settings/                           # App configuration
    splash/                             # Splash screen
    warranty/                           # Warranty check & claims
```

---

## Firebase Collections

| Collection | Purpose |
|------------|---------|
| `categories` | Product categories with icons |
| `products` | Product master data |
| `serial_numbers` | Individual unit tracking |
| `sales` | Transaction records |
| `customers` | Customer profiles |
| `settings` | App configuration (single doc) |
| `daily_additions` | Daily stock intake |
| `product_issues` | Issue reports |
| `replacements` | Replacement orders |
| `warranty` | Warranty records & claims |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.11+
- Dart 3.11+
- Firebase project with Firestore enabled
- imgBB API key (free)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Mdarafath07/SmartStock.git
   cd smartstock
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and add your imgBB API key:
   ```env
   IMGBB_API_KEY=your_imgbb_api_key_here
   ```

3. **Firebase setup**
   - Create a Firebase project
   - Enable Firestore database
   - Register Android, iOS, and Web apps
   - Replace `lib/firebase_options.dart` by running:
     ```bash
     flutterfire configure
     ```

4. **Install dependencies**
   ```bash
   flutter pub get
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Google Sheets Backup (Optional)

1. Create a Google Cloud service account
2. Enable Google Sheets API
3. Share your target spreadsheet with the service account email
4. Configure in Settings > Google Sheets Backup

---

## Design

SmartStock follows a Material 3 inspired design system with a professional, systematic aesthetic:

- **Primary Color**: `#2563EB` (Blue)
- **Typography**: Hanken Grotesk (headings), Inter (body), Geist (labels)
- **Rounding**: 12px buttons, 16px cards, 20px dialogs
- **Navigation**: 5-tab bottom nav bar with pill-style indicator

---

## License

This project is licensed under the MIT License.

---

## Author

**MOHAMMAD ARAFATH UDDIN**

---

<p align="center">
  Built with Flutter & Firebase
</p>
