# Rumah Jahit - Tailoring Management System

A production and sales management application for tailoring businesses, built with **Flutter**, **Firebase**, and **Riverpod**.

## 🚀 Overview

**Rumah Jahit** is designed to streamline the workflow of a tailoring shop, from receiving custom orders and managing raw materials to tracking production in real-time (SPK) and processing sales through a dedicated POS system.

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (v3.11.0+)
- **State Management:** [Riverpod](https://riverpod.dev) (Provider-based architecture)
- **Database & Auth:** [Firebase](https://firebase.google.com) (Firestore & Auth)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router)
- **Styling:** Material 3 with [Google Fonts (Inter)](https://fonts.google.com/specimen/Inter)
- **Utilities:** `intl` (Currency/Date), `url_launcher` (WhatsApp receipts), `image_picker` (Product photos).

## 🏗 Architecture & Project Structure

The project follows a **Feature-First Architecture** (Clean-inspired), where each functional area is encapsulated within its own directory under `lib/features/`.

```text
lib/
├── core/               # Shared logic, utilities, and widgets
│   ├── config/         # App constants and configuration
│   ├── routing/        # GoRouter navigation setup
│   ├── services/       # Global services (Firebase, local storage)
│   ├── utils/          # Extensions, formatters, and helpers
│   └── widgets/        # Reusable UI components
├── features/           # Domain-specific modules
│   ├── auth/           # Login, Session management, and Pin Security
│   ├── dashboard/      # Statistics, charts, and summary
│   ├── inventory/      # Raw materials, Finished Goods, and SPK (Production Orders)
│   ├── payroll/        # Tailor wage calculations and history
│   ├── pos/            # Point of Sale, Cart, and Checkout
│   └── settings/       # App-wide settings and backups
├── firebase_options.dart # Generated Firebase configuration
└── main.dart           # Application entry point
```

## ✨ Key Features

### 1. Production Orders (SPK)
Manage the production lifecycle from raw materials to finished products.
- Multi-size support for production.
- Real-time progress tracking for tailors.
- Automatic inventory deduction for components.

### 2. Point Of Sale (POS)
Streamlined checkout process for finished garments.
- Integrated discount system.
- Digital receipts with sharing capabilities (WhatsApp/PDF).
- Multiple payment method support.

### 3. Payroll & Tailor Management
Automated wage calculation based on production output.
- Accumulated real-time earnings tracking.
- Annual production statistics.
- Bonus and deduction management.

### 4. Inventory Control
Dual-layer inventory management for both raw fabrics/components and finished inventory.

### 5. Quick Production (Setoran Cepat)
Directly record tailor outputs and calculate payroll in a unified flow without requiring an active SPK.
- **Card-based Product Picker:** Dynamic card layout displaying stock level and sizes matching the main finished inventory interface.
- **Advanced Local Filtering:** Filter by school level (SD, MIN, SMP, etc.) or garment type, with keyword search.
- **Auto-detected Wages:** Auto-populate labor rates by matching product type/name with wage categories.
- **Direct Launch UX:** Instant picker popups directly from employee list views and product detail pages to minimize click fatigue.

## 🔧 Setup & Installation

### Prerequisites
- Flutter SDK `^3.11.0`
- Firebase CLI installed and configured.

### Local Development
1. Clone the repository:
   ```bash
   git clone https://github.com/ihsanhadi57/Rumah-Jahit.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. (Optional) Rebuild Firebase options if needed:
   ```bash
   flutterfire configure
   ```
4. Run the application:
   ```bash
   flutter run
   ```

## 📜 Development Guidelines

- **State Management:** Use `Notifier` or `AsyncNotifier` (Riverpod 2.0+) for feature state.
- **Navigation:** All routes must be defined in `lib/core/routing/app_router.dart`.
- **UI Consistency:** Use curated color tokens from `ThemeData` and custom widgets in `core/widgets`.
- **Currency:** Use the centralized `formatCurrency()` utility in `core/utils/currency_utils.dart`.

---

Developed by [Ihsan Hadi](https://github.com/ihsanhadi57).
