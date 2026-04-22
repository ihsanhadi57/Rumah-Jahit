# Implementasi Selesai: Pengaturan Upah Dinamis & Auto-Detect

Saya telah selesai mengimplementasikan fitur pengaturan upah dan auto-deteksi upah. Berikut bagian yang telah dikerjakan sesuai request Anda:

## 1. Modul Pengaturan Upah (`lib/features/settings`)
- Membuat koleksi `wage_categories` di Firestore agar setiap perangkat dapat tersinkronisasi.
- Membuat UI `SettingsDialog` yang memiliki fungsi *CRUD (Create, Read, Update, Delete)*. Anda dapat menambah kategori upah baru dengan tipe yang Anda tentukan sendiri (contoh: "Baju", "Gamis", "Celana") tanpa dibatasi.
- Menyimpan State dengan Riverpod (`settingsStreamProvider`) agar perubahannya *real-time*.

## 2. Pembaruan Inventory Screen
- Mengganti `IconButton` logout yang berada di sudut kanan atas `InventoryScreen` menjadi icon settings (Gear).
- Apabila diklik, aplikasi akan memunculkan menu `SettingsDialog`.

## 3. Pembaruan Form Tambah SPK (`add_spk_form.dart`)
- **Auto-Detection**: Menambahkan fungsi deteksi nama produk otomatis pada Step 3. Apabila nama produk yang Anda ketik/pilih (misal: "Baju Osis") mengandung kata kunci dari kategori upah yang telah Anda buat di pengaturan (misal: "Baju"), form akan **secara otomatis memilih kategori tersebut** dan mengisi `_wageController` beserta menjadikan field-nya *read-only*.
- **Opsi Manual**: Tersedia Dropdown di mana Anda tetap bisa mengubah opsi kembali ke **Input Manual** atau mengubah ke kategori upah lain jika auto-deteksi kurang tepat.
- Form ini bekerja baik di mode *Tambah Stok Gudang (RESTOCK)* maupun *Pesanan Produksi (CUSTOM)*.

> [!TIP]
> **Cara Kerja Auto-Detect**:  
> Deteksi bersifat *case-insensitive* (tidak memedulikan huruf besar/kecil). Jika Anda memiliki kategori bernama `"baju"`, dan produk bernama `"BAJU LENGAN PANJANG"`, aplikasi akan secara cerdas mencocokkannya.

Anda sekarang bisa mengetes langsung di dalam aplikasinya:
1. Buka halaman Inventory, klik logo Setting di pojok kanan atas.
2. Tambahkan kategori Baju, Celana, dll beserta nominalnya.
3. Buat SPK baru dan pilih produk Baju. Anda akan melihat upahnya terisi otomatis di tahap ketiga!
