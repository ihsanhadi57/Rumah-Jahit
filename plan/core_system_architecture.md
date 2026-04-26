# Rumah Jahit Alya - Core System Architecture

Dokumen ini menjelaskan detail teknis, alur aplikasi, dan arsitektur kode yang digunakan dalam proyek **Rumah Jahit Alya**.

---

## 1. Tech Stack Utama

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (Functional & Class-based Providers)
- **Database**: Cloud Firestore (NoSQL, Real-time)
- **Authentication**: Firebase Auth
- **Navigation**: GoRouter (Stateful Shell Routing)
- **Assets/Images**: Firebase Storage

---

## 2. Arsitektur Kode (Feature-First)

Aplikasi menggunakan pendekatan modular per-fitur. Setiap fitur memiliki folder sendiri yang biasanya terbagi menjadi:

- `domain/`: Model data dan entitas bisnis.
- `data/`: Repositori dan provider data (Firestore).
- `presentation/`: UI (Screens & Widgets).

### Daftar Fitur:

1.  **Auth**: Manajemen user (Login, Regis, Aktivasi Admin).
2.  **Dashboard**: Statistik ringkasan (Omzet harian, status produksi).
3.  **Inventory**: Manajemen stok barang jadi, bahan baku, dan SPK.
4.  **POS (Point of Sale)**: Sistem kasir, keranjang belanja, dan cetak/share struk.
5.  **Payroll**: Pencatatan hasil jahit karyawan dan perhitungan gaji otomatis.

---

## 3. Sistem Inti (Core Logic)

### A. Point of Sale (POS) & Checkout

Alur paling kritikal ada di `lib/features/pos/data/transaction_repository.dart`. Saat user melakukan checkout:

- **Atomic Write (Batch)**: Menggunakan `WriteBatch` Firestore untuk memastikan semua operasi sukses atau gagal sekaligus.
- **Deduction Logic**: Jika item adalah barang stok (`isCustom: false`), stok di tabel `products` dikurangi otomatis.
- **Auto-SPK**: Jika item adalah pesanan jahitan (`isCustom: true`), sistem otomatis membuat dokumen di koleksi `production_orders` (SPK) agar tampil di daftar kerja penjahit.

### B. State Management (Riverpod)

- **`StreamProvider`**: Digunakan untuk sinkronisasi data real-time dari Firestore (misal: daftar produk, riwayat transaksi).
- **`StateNotifier` & `Notifier`**: Mengelola _logic_ lokal seperti keranjang belanja (`cart_notifier.dart`) yang menghitung subtotal, diskon, dan grand total secara dinamis.

### C. Alur Navigasi (GoRouter)

Navigasi dikelola di `lib/core/routing/app_router.dart`:

- **`StatefulShellRoute`**: Menjaga _state_ dari setiap tab di bawah (Bottom Nav). Jika Anda sedang di tab POS lalu pindah ke Inventory dan kembali lagi, posisi scroll dan data di POS tetap terjaga.
- **Auth Guard**: Secara otomatis mengalihkan user ke halaman login jika mendeteksi session Firebase Auth kosong.

### D. Fitur Berbagi Struk (WhatsApp Share)

Logika di `lib/features/pos/presentation/receipt_screen.dart`:

1.  **Rendering**: Menggunakan `RepaintBoundary` untuk menangkap tampilan widget struk.
2.  **Image Conversion**: Mengonversi widget menjadi data bit (PNG).
3.  **Sharing**: Menggunakan package `share_plus` untuk mengirim gambar beserta teks ringkasan transaksi ke API sharing WhatsApp.

---

## 4. Struktur Database Firestore

Koleksi utama yang digunakan:

- `users`: Data karyawan, role, dan status aktif.
- `products`: Katalog barang jadi (beserta stok).
- `raw_materials`: Daftar kain dan aksesoris jahit.
- `transactions`: Log penjualan global.
- `production_orders`: SPK (Surat Perintah Kerja) untuk memantau proses jahit.
- `wage_categories`: Konfigurasi upah jahit per kategori barang.

---

## 5. Tips Belajar Codebase Ini

1.  **Pahami Model**: Lihat file-file di folder `domain/` untuk mengerti struktur data.
2.  **Tracking Data**: Lihat folder `data/` untuk melihat bagaimana aplikasi berinteraksi dengan API/Firestore.
3.  **UI/UX**: Lihat `lib/core/widgets/` untuk melihat komponen UI standar yang digunakan berulang kali agar desain konsisten.

---

_Terakhir diperbarui: 01 April 2026_

Berikut adalah versi 3 poin yang padat, teknis, dan **ATS-friendly**:

- **Integrated ERP & POS System**: Developed a full-stack mobile application using **Flutter** and **Firebase** that unifies Point of Sale (POS), Inventory management, and Payroll into a single modular ecosystem.
- **Advanced Real-time Architecture**: Implemented **Riverpod** for reactive state management and **GoRouter (Stateful Navigation)** to maintain persistent UI states and independent navigation stacks across business modules.
- **Automated Production Workflow**: Engineered a high-integrity transaction engine using **Firestore Write Batches (Atomic Writes)** to synchronize stock deduction, automated **Production Order (SPK)** generation, and real-time wage calculation.
