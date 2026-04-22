# Integrasi Backend Firebase — Rumah Jahit

Menghubungkan seluruh modul frontend (Inventory, POS, Payroll, Dashboard) ke Cloud Firestore berdasarkan skema di [database_schema.md](file:///e:/Code/Flutter/rumah_jahit/database_schema.md). Arsitektur mengikuti pola **Feature-First Clean Architecture** dengan Riverpod sebagai state management.

---

## User Review Required

> [!IMPORTANT]
> **Skala integrasi cukup besar (~40+ file baru).** Plan ini akan dikerjakan secara bertahap per-fitur. Setiap fitur mengikuti pola yang sama: **Model → Repository → Provider → UI Wiring.**

> [!WARNING]
> **Data dummy yang ada di semua screen akan digantikan** dengan `StreamProvider`/`FutureProvider` dari Firestore. Pastikan koneksi Firebase sudah berfungsi (sudah terverifikasi dari [firebase_options.dart](file:///e:/Code/Flutter/rumah_jahit/lib/firebase_options.dart) dan [main.dart](file:///e:/Code/Flutter/rumah_jahit/lib/main.dart)).

---

## Proposed Changes

### 1. Data Layer Foundation (Shared Models & Repositories)

Membuat fondasi data layer yang akan dipakai oleh semua fitur.

---

#### [NEW] [raw_material.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/inventory/domain/raw_material.dart)
Dart model class untuk koleksi `raw_materials` dengan field: `id`, `name`, `unit`, `selectedStock`, `lowStockThreshold`, `updatedAt`.

#### [NEW] [product.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/inventory/domain/product.dart)
Model untuk koleksi `products`: `id`, `name`, `schoolLevels`, `type`, `size`, `price`, `currentStock`, `imageUrl`, `updatedAt`.

#### [NEW] [production_order.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/inventory/domain/production_order.dart)
Model untuk koleksi `production_orders` (SPK): `id`, `title`, `targetProductId`, `targetQuantity`, `status`, `assignedTailors`, `pieceRate`, `materialsUsed`, `completedQuantity`, `createdAt`, `completedAt`.

#### [NEW] [transaction_model.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/pos/domain/transaction_model.dart)
Model untuk koleksi `transactions`: `id`, `cashierId`, `subtotal`, `discount`, `grandTotal`, `paymentMethod`, `amountPaid`, `status`, `createdAt`. Termasuk class `TransactionItem` untuk sub-collection `items`.

#### [NEW] [app_user.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/payroll/domain/app_user.dart)
Model untuk koleksi `users`: `id`, `name`, `role`, `phone`, `cashAdvanceBalance`, `createdAt`.

#### [NEW] [payroll_record.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/payroll/domain/payroll_record.dart)
Model untuk koleksi `payroll_records`.

---

### 2. Firestore Repositories

Setiap repository meng-encapsulate semua operasi CRUD ke Firestore.

---

#### [NEW] [raw_material_repository.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/inventory/data/raw_material_repository.dart)
- `watchAll()` → `Stream<List<RawMaterial>>` (real-time snapshots)
- `add(RawMaterial)`, `update(RawMaterial)`, `delete(String id)`
- `deductStock(String id, double qty)` — untuk pemotongan saat SPK

#### [NEW] [product_repository.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/inventory/data/product_repository.dart)
- `watchAll()` → `Stream<List<Product>>`
- `watchFiltered({schoolLevel, type})` — untuk filter POS
- `add()`, `update()`, `delete()`
- `deductStock(String id, int qty)` — untuk pemotongan saat transaksi POS

#### [NEW] [production_order_repository.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/inventory/data/production_order_repository.dart)
- `watchAll()`, `add()`, `update()`, `complete()`

#### [NEW] [transaction_repository.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/pos/data/transaction_repository.dart)
- `createTransaction()` — menggunakan `WriteBatch` untuk atomic write (transaksi + potong stok produk)
- `watchToday()` — untuk dashboard
- `watchAll()`

#### [NEW] [user_repository.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/payroll/data/user_repository.dart)
- `watchAll()`, `watchTailors()`, `add()`, `update()`

#### [NEW] [payroll_repository.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/payroll/data/payroll_repository.dart)
- `watchByUser(String userId)`, `generate()`, `markPaid()`

---

### 3. Riverpod Providers

---

#### [NEW] [inventory_providers.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/inventory/data/inventory_providers.dart)
- `rawMaterialRepositoryProvider` — Provider for repository instance
- `rawMaterialsStreamProvider` — `StreamProvider<List<RawMaterial>>`
- `productRepositoryProvider`, `productsStreamProvider`
- `productionOrderRepositoryProvider`, `productionOrdersStreamProvider`

#### [NEW] [pos_providers.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/pos/data/pos_providers.dart)
- `transactionRepositoryProvider`
- `cartProvider` — `StateNotifierProvider<CartNotifier, CartState>` untuk manage keranjang
- `filteredProductsProvider` — produk terfilter untuk POS grid

#### [NEW] [cart_notifier.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/pos/data/cart_notifier.dart)
- `CartState` (items, subtotal, discount, grandTotal)
- `CartNotifier` extends `StateNotifier` — `addItem()`, `removeItem()`, `updateQty()`, `clear()`

#### [NEW] [payroll_providers.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/payroll/data/payroll_providers.dart)
- `userRepositoryProvider`, `tailorsStreamProvider`
- `payrollRepositoryProvider`

#### [NEW] [dashboard_providers.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/dashboard/data/dashboard_providers.dart)
- `todayRevenueProvider`, `lowStockItemsProvider`, `recentSpkProvider`, `recentTransactionsProvider`

---

### 4. UI Wiring — Replace Dummy Data with Live Streams

---

#### [MODIFY] [bahan_mentah_tab_view.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/inventory/presentation/widgets/bahan_mentah_tab_view.dart)
- Convert ke `ConsumerWidget`, pakai `ref.watch(rawMaterialsStreamProvider)` — render `AsyncValue` (loading/error/data)

#### [MODIFY] [barang_jadi_tab_view.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/inventory/presentation/widgets/barang_jadi_tab_view.dart)
- Sama, pakai `productsStreamProvider`

#### [MODIFY] [spk_tab_view.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/inventory/presentation/widgets/spk_tab_view.dart)
- Pakai `productionOrdersStreamProvider`

#### [MODIFY] [pos_screen.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/pos/presentation/pos_screen.dart)
- Convert ke `ConsumerStatefulWidget`, pakai `filteredProductsProvider` untuk grid produk dan `cartProvider` untuk FAB badge/total

#### [MODIFY] [checkout_screen.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/pos/presentation/checkout_screen.dart)
- Pakai `cartProvider` untuk render items, dan panggil `transactionRepository.createTransaction()` saat "Bayar Sekarang"

#### [MODIFY] [payroll_screen.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/payroll/presentation/payroll_screen.dart)
- Convert ke `ConsumerWidget`, pakai `tailorsStreamProvider`

#### [MODIFY] [dashboard_screen.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/dashboard/presentation/dashboard_screen.dart)
- Convert ke `ConsumerWidget`, pakai dashboard providers

#### [NEW] [add_raw_material_dialog.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/inventory/presentation/widgets/add_raw_material_dialog.dart)
Form dialog untuk menambah bahan mentah baru.

#### [NEW] [add_product_form.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/inventory/presentation/widgets/add_product_form.dart)
Form untuk menambah produk baru (dengan multi-size auto-expand sesuai skema database).

---

## Verification Plan

### Automated Tests
```powershell
cd e:\Code\Flutter\rumah_jahit
flutter analyze
```
Memastikan tidak ada compilation error, type mismatch, atau import yang rusak.

### Manual Verification
1. **Jalankan app** dengan `flutter run` di device/emulator
2. **Buka tab Gudang → Bahan Mentah** — Harus menampilkan loading indicator, lalu data kosong (karena Firestore masih kosong)
3. **Tap tombol "+" atau "Add New Material"** — Form dialog muncul, isi data dan simpan → data tampil real-time
4. **Buka tab Barang Jadi** — Sama, data dari Firestore
5. **Buka tab Kasir** — Produk grid terisi dari Firestore, filter berjalan
6. **Tambah item ke keranjang → Checkout → Bayar** — Transaksi tersimpan di Firestore, stok produk berkurang
7. **Buka Dashboard** — Pendapatan hari ini, low stock alert, dan recent SPK/transactions ter-update
8. **Buka Karyawan** — Daftar karyawan dari Firestore

> [!NOTE]
> Karena ini integrasi backend pertama, data Firestore awalnya kosong. Uji coba dilakukan dengan menambah data dari aplikasi sendiri.
