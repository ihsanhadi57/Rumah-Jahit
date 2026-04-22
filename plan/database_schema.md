# Skema Database Firestore (Rumah Jahit)

Karena aplikasi ini memiliki keterkaitan data yang kompleks (Stok Bahan -> SPK -> Stok Barang Jadi -> Kasir -> Payroll), mendesain **Database Schema terlebih dahulu** adalah langkah yang tepat sebelum menyentuh UI.

Berikut adalah usulan struktur **Koleksi (Collections)** dan **Dokumen (Documents)** menggunakan arsitektur NoSQL Cloud Firestore.

---

## 1. Koleksi: `users` (Karyawan & Pengguna)

Koleksi ini menyimpan data akses (Admin/Kasir) maupun data pekerja lapangan (Penjahit).

- **Dokumen ID:** `user_id` (String - UID Firebase Auth)
- **Field:**
  - `name` (String) - Nama lengkap
  - `role` (String) - `admin`, `cashier`, `tailor`
  - `phone` (String)
  - `cash_advance_balance` (Number/Double) - Sisa utang kasbon berjalan
  - `created_at` (Timestamp)

## 2. Koleksi: `raw_materials` (Bahan Mentah Gudang)

- **Dokumen ID:** `material_id` (Auto-ID)
- **Field:**
  - `name` (String) - Misal: "Kain Seragam SD Merah"
  - `unit` (String) - "meter", "roll", "pcs" (untuk resleting/kancing)
  - `selected_stock` (Double) - Saldo stok saat ini
  - `low_stock_threshold` (Double) - Batas peringatan stok menipis
  - `updated_at` (Timestamp)

## 3. Koleksi: `products` (Barang Jadi / Katalog Toko)

Barang yang siap dijual di POS Kasir. Memiliki variasi atribut (jenjang, tipe, dll) agar filter kasir lebih mudah.

- **Dokumen ID:** `product_id` (Auto-ID)
- **Field:**
  - `name` (String) - Nama dasar, misal: "Baju OSIS", "Kemeja Pramuka", "Celana Merah"
  - `school_levels` (Array of Strings) - Jenjang sekolah, misal: `["SD", "MIN"]` atau `["SMP", "MTs"]`. _Array digunakan karena ada produk yang sama persis dipakai oleh SD maupun MIN._
  - `type` (String) - Misal: "Lengan Panjang", "Lengan Pendek", "Celana Panjang", "Rok Rempel"
  - `size` (String) - Varian ukuran: "S", "M", "L", "XL", "No.1", "No.2"
  - `price` (Double) - Harga jual
  - `current_stock` (Integer) - Saldo stok barang jadi
  - `image_url` (String/Nullable) - Foto produk
  - `updated_at` (Timestamp)

## 4. Koleksi: `production_orders` (SPK / Surat Perintah Kerja)

Koleksi sentral yang mengubah Bahan Mentah menjadi Barang Jadi dan menjadi dasar penggajian Penjahit.

- **Dokumen ID:** `order_id` (String - Misal: "SPK-2310-001")
- **Field:**
  - `title` (String) - "Jahit Baju Pramuka 100pcs"
  - `target_product_id` (String) - Relasi ke ID barang jadi yang diproduksi
  - `target_quantity` (Integer) - Berapa banyak mau dibuat
  - `status` (String) - `PENDING`, `IN_PROGRESS`, `COMPLETED`
  - `assigned_tailors` (Array of Strings) - List `user_id` Penjahit
  - `piece_rate` (Double) - Upah per _pieces baju_ bagi penjahit
  - `materials_used` (Array of Maps) - Bahan yang dipotong:
    - `material_id` (String)
    - `quantity` (Double)
  - `completed_quantity` (Integer) - Diisi saat verifikasi selesai
  - `created_at` (Timestamp)
  - `completed_at` (Timestamp/Nullable)

## 5. Koleksi: `transactions` (Penjualan POS Kasir)

- **Dokumen ID:** `transaction_id` (Auto-ID / Timestamp string)
- **Field:**
  - `cashier_id` (String) - `user_id` kasir yang shift
  - `subtotal` (Double)
  - `discount` (Double)
  - `grand_total` (Double)
  - `payment_method` (String) - "CASH", "TRANSFER", "QRIS"
  - `amount_paid` (Double) - Uang yang diterima (untuk kalkulasi kembalian)
  - `status` (String) - `SUCCESS`, `CANCELLED`
  - `created_at` (Timestamp)
- **Sub-Collection:** `items` (Item yang dibeli)
  - **Field:** `product_id` (String), `product_name`, `size`, `quantity` (Integer), `unit_price`, `total_price`.

## 6. Koleksi: `payroll_records` (Slip Gaji & Riwayat)

Dibuat (Generate) oleh admin setiap periode penggajian mingguan/bulanan.

- **Dokumen ID:** `payroll_id` (Auto-ID)
- **Field:**
  - `user_id` (String)
  - `period_start` (Timestamp)
  - `period_end` (Timestamp)
  - `base_salary` (Double) - Gaji pokok (jika kasir/admin)
  - `total_pieces_completed` (Integer) - Total potong (diakumulasi dari SPK `COMPLETED` di rentang waktu ini)
  - `piece_rate_earnings` (Double) - Upah borongan kotor
  - `cash_advance_deduction` (Double) - Potongan Utang Kasbon
  - `net_salary` (Double) - Gaji Bersih yang ditransfer
  - `status` (String) - `PAID`
  - `created_at` (Timestamp)

---

_Dengan skema relasional non-SQL secara logika seperti ini, saat SPK di-submit, Firebase Cloud Functions (ATAU langsung dari client via Firestore Batch Transaction) dapat sekaligus melakukan pemotongan saldo di koleksi `raw_materials`. Begitu pula POS Transaksi akan memotong saldo `products`._

1. Bagaimana Anda Menginput Data (Menu Gudang / Master Data)
   Sebagai Admin (Pemilik), Anda hanya menginput data keragaman ini satu kali sewaktu mendaftarkan katalog barang baru ke gudang. Formulirnya bisa kita buat sesimpel mungkin dengan Dropdown atau Checkbox.

Contoh yang Anda input di aplikasi:

Nama Dasar: Baju OSIS
Pilih Jenjang (Bisa > 1): [x] SMP [x] MTs [ ] SD
Tipe Potongan: [Dropdown: Lengan Panjang]
Gender: [Dropdown: Putri]
Varian Ukuran & Harga: (Bisa ditambahkan banyak sekaligus)
Ukuran: S, Harga: Rp 60.000, Stok Awal: 10
Ukuran: M, Harga: Rp 65.000, Stok Awal: 15
Ukuran: L, Harga: Rp 70.000, Stok Awal: 5
Ketika tombol "Simpan" ditekan, aplikasi akan otomatis memecah dan membuat 3 dokumen di database products (S, M, dan L). Jadi Anda tidak perlu capek mengetik ulang "Baju OSIS SMP Putri..." untuk setiap ukuran.

2. Bagaimana Kasir Memilih di Layar POS (Tanpa Mengetik)
   Agar kasir bisa melayani pembeli dengan sangat cepat (tanpa perlu mengetik apapun), layar POS (Tablet/Mobile) akan dirancang dengan kombinasi Tombol Filter (Chips) dan Dialog Pilihan.

Kasir TIDAK perlu mengetik spesifikasi. Alurnya seperti ini:

Pelanggan bilang: "Mbak, cari Baju OSIS SMP buat anak perempuan lengan panjang ukuran M"
Di layar tablet bagian atas, kasir cukup mengetuk tombol filter cepat secara berurutan: [Filter: SMP] [Filter: Putri] [Filter: L. Panjang]
Layar langsung hanya menampilkan gambar/tombol produk yang relevan: "Baju OSIS", "Celana/Rok".
Kasir menekan tombol gambar "Baju OSIS".
Akan muncul Popup/BottomSheet kecil dari bawah: "Pilih Ukuran". Terlihat tombol [S: Rp60rb] [M: Rp65rb] [L: Rp70rb]. Jika stok kosong, tombolnya abu-abu.
Kasir menekan angka [M], dan otomatis masuk ke Keranjang Belanja.
Inti desainnya: Skema database yang sangat detail di balik layar justru bertujuan agar di layar antarmuka depan (UI) kasir hanya perlu "Tap-Tap" (mengetuk tombol filter/ukuran), bukan mengetik pencarian yang melelahkan dan rawan typo.

Apakah alur kerja UI/UX (baik untuk input admin maupun tap kasir) ini masuk akal dan praktis untuk operasional toko Anda sehari-hari? Jika ya, kita bisa langsung lanjut ke penyusunan kode layout/routing aplikasinya!
