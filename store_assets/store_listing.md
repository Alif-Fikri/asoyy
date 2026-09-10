# Play Store Listing Draft — Beres

Bahasa utama listing: **Indonesia (id-ID)**. Aplikasi ini Indonesia-first —
format Rupiah, hari libur nasional, tanggal Hijriah, dan tanggal gajian —
jadi screenshot pun diambil dalam Bahasa Indonesia. Draft en-US ada di
bagian bawah untuk listing tambahan kalau nanti dibuka ke pasar lain.

## App name (max 30 char)
Beres: Catatan Harian & Uang

(27/30 karakter.)

## Short description (max 80 char)
Kalender, keuangan, alarm, dan password dalam satu app. Offline, tanpa akun.

(76/80 karakter.)

## Full description (max 4000 char)

Beres menggabungkan alat-alat yang biasanya tersebar di banyak aplikasi
menjadi satu: kalender, catatan keuangan, alarm, kalkulator, konversi
satuan dan mata uang, plus penyimpan password. Semuanya bekerja offline
dan tersimpan di perangkat Anda sendiri — tanpa akun, tanpa login.

💰 KEUANGAN YANG JUJUR
Catat pemasukan dan pengeluaran, lalu lihat ke mana uang Anda benar-benar
pergi lewat grafik enam bulan dan diagram per kategori. Filter per bulan
atau per jenis transaksi, dan tambah transaksi cepat lewat satu baris
teks.

🎯 BUDGET PER KATEGORI
Pasang limit bulanan untuk tiap kategori pengeluaran. Bar progresnya
berubah hijau, kuning, lalu merah seiring pemakaian, dan Anda langsung
diberi tahu saat sebuah kategori mendekati atau melewati limitnya.

🔁 TRANSAKSI BERULANG
Tagihan yang datang tiap bulan cukup dicatat sekali. Beres membuatkan
transaksinya otomatis pada tanggal yang Anda tentukan, dan mengingatkan
sehari sebelumnya lewat notifikasi.

📅 KALENDER YANG PAHAM KONTEKS LOKAL
Hari libur nasional dan cuti bersama sudah ada di dalam. Tanggal Hijriah
tampil berdampingan dengan tanggal Masehi, dan Anda bisa menandai tanggal
gajian agar muncul tiap bulan.

⏰ ALARM YANG BENAR-BENAR BUNYI
Alarm dijadwalkan lewat AlarmManager Android, jadi tetap berbunyi meski
aplikasi sudah ditutup dari daftar aplikasi terbaru. Saat berbunyi,
tampil layar penuh dengan tombol Matikan dan Tunda 5 Menit. Nada dering
bisa dipilih dari koleksi nada bawaan ponsel Anda sendiri.

🔐 PASSWORD DI PERANGKAT SENDIRI
Simpan akun dan password di balik sidik jari, pola, atau PIN. Semua data
tersimpan lokal — tidak ada server, tidak ada sinkronisasi cloud. Bisa
diekspor dan diimpor lewat CSV kalau Anda ingin memindahkannya sendiri.

🧮 KALKULATOR & KONVERSI
Kalkulator untuk hitungan cepat, plus konversi panjang, berat, suhu, dan
volume. Kurs mata uang diambil dari internet lalu disimpan, sehingga tetap
bisa dipakai saat offline dengan keterangan kapan terakhir diperbarui.

✨ LAINNYA
- Mode gelap dan terang, mengikuti selera Anda
- Bahasa Indonesia dan Inggris
- Pencarian global: cari transaksi, event, password, dan alarm sekaligus
- Halaman notifikasi berisi semua pengingat yang akan datang, lengkap
  dengan sakelar untuk mematikannya satu per satu
- Ekspor CSV untuk keuangan dan password
- Tanpa iklan, tanpa akun, tanpa langganan

Beres bekerja sepenuhnya offline. Satu-satunya koneksi internet yang
dipakai adalah untuk mengambil kurs mata uang, dan itu pun opsional.

Unduh Beres, dan biarkan urusan harian Anda beres di satu tempat.

---

## Release notes (Play Console — "What's new")

v1.0.0 (id-ID)
Rilis pertama Beres!
- Catatan keuangan dengan grafik enam bulan dan rincian per kategori
- Budget per kategori dengan peringatan saat mendekati dan melewati limit
- Transaksi berulang otomatis, plus pengingat H-1
- Kalender dengan libur nasional, tanggal Hijriah, dan tanggal gajian
- Alarm yang tetap berbunyi walau aplikasi ditutup, dengan nada dering
  dari koleksi ponsel Anda
- Password manager terkunci sidik jari, pola, atau PIN
- Kalkulator serta konversi satuan dan mata uang
- Mode gelap dan terang, Bahasa Indonesia dan Inggris

v1.0.0 (en-US)
First release of Beres!
- Finance tracking with a six-month chart and per-category breakdown
- Per-category budgets that warn as you approach and pass the limit
- Recurring transactions generated automatically, with a day-before reminder
- Calendar with Indonesian public holidays, Hijri dates and payday
- Alarms that keep ringing after the app is closed, with a ringtone picked
  from your phone's own collection
- Password manager locked behind fingerprint, pattern or PIN
- Calculator plus unit and currency conversion
- Dark and light themes, Indonesian and English

---

## Catatan pengisian Play Console

### App info
- Launcher label: `Beres`
- Version: `1.0.0+1` (`pubspec.yaml`) — naikkan build number tiap upload
- Icon listing 512x512: `store_assets/play_store_icon_512.png`
- Icon master 1024x1024: `store_assets/app_icon_1024.png`
- Feature graphic 1024x500: `store_assets/feature_graphic_1024x500.png`
  (PNG RGB tanpa alpha, sesuai syarat Play Console)
- Semua gambar di atas di-generate ulang dengan:
  `python3 scripts/generate_store_assets.py`

### Categorization
- App or game: **App**
- Category: **Productivity**
- Tag yang cocok: Personal finance, Budgeting, Calendar, Alarm clock,
  Password manager, Offline

### Data safety form
- Data yang dikumpulkan dan dikirim ke luar perangkat: **tidak ada**.
  Tidak ada backend, tidak ada akun, tidak ada analytics, tidak ada iklan.
- Data yang disimpan **di perangkat saja** (Hive + `settings_box`):
  transaksi keuangan, budget per kategori, transaksi berulang, event
  kalender, alarm, entri password, nama pengguna, tema, bahasa, dan PIN
  atau pola. Uninstall menghapus semuanya.
- Satu-satunya koneksi keluar: `GET https://open.er-api.com/v6/latest/USD`
  untuk kurs mata uang. Request ini tidak mengirim data pengguna apa pun —
  tidak ada parameter, tidak ada API key, tidak ada identifier.
- "Does your app contain ads?" → **No**
- Untuk pertanyaan enkripsi data saat transit: kurs diambil lewat HTTPS.
- Password disimpan di penyimpanan privat aplikasi. Deklarasikan sebagai
  data sensitif yang **tidak** dikumpulkan (tidak pernah meninggalkan
  perangkat), dan sebutkan penguncian biometrik/PIN sebagai kontrol akses.

### Content rating
- Perkiraan hasil: **Everyone / PEGI 3** — aplikasi utilitas, tanpa
  kekerasan, konten dewasa, atau pembelian
- Jawab "No" untuk semua kategori konten sensitif termasuk iklan

### Permissions declaration
Beberapa izin di `AndroidManifest.xml` akan ditanyakan Play Console:

- `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` — inti fitur alarm. Pada form
  "Exact alarm permission", pilih alasan **alarm clock app**: aplikasi ini
  memang menyediakan alarm yang dipasang pengguna dan harus berbunyi tepat
  waktu.
- `USE_FULL_SCREEN_INTENT` — layar alarm berbunyi. Alasannya sama: alarm
  yang dijadwalkan pengguna. Kalau ditolak reviewer, alarm masih berbunyi,
  tapi hanya lewat notifikasi biasa, bukan layar penuh.
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` — hanya diminta saat pengguna
  menekan tombolnya sendiri di halaman Profil, untuk menjaga alarm tetap
  akurat. Jangan pernah panggil otomatis saat app dibuka; Play melarangnya.
- `POST_NOTIFICATIONS`, `VIBRATE`, `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED`,
  `FOREGROUND_SERVICE*`, `USE_BIOMETRIC` — pendukung alarm dan penguncian
  password manager.

### PENTING sebelum submit ke production

1. **`applicationId` masih `com.example.asoyy`.** Play Console **menolak**
   package yang diawali `com.example`. Ini wajib diganti (mis.
   `id.co.alchemist.beres`) di `android/app/build.gradle.kts`
   (`namespace` + `applicationId`), direktori
   `android/app/src/main/kotlin/...`, dan `PRODUCT_BUNDLE_IDENTIFIER` iOS.
   **Package name tidak bisa diubah lagi setelah rilis pertama**, jadi
   pastikan final sebelum upload.
2. **Privacy Policy URL wajib diisi** untuk semua aplikasi. Draft ada di
   `store_assets/PRIVACY_POLICY.md` — publish ke URL publik (GitHub Pages
   atau hosting apa pun), lalu tempel URL-nya di Play Console
   (App content → Privacy policy) dan App Store Connect (App Privacy).
3. **Keystore upload** ada di `~/AndroidKeystores/`. Backup file `.jks` dan
   kredensialnya di tempat lain — kehilangan keystore berarti tidak bisa
   update app selamanya.
4. Build rilis pakai `flutter build appbundle --release`, lalu cek sekali
   di perangkat asli bahwa alarm tetap berbunyi setelah app ditutup dan
   konversi mata uang berhasil menarik kurs.

### Screenshots

Play Console minta minimal 2 screenshot phone, maksimal 8. App Store
Connect wajib satu set untuk layar 6.9".

Raw capture ada di `store_assets/screenshots/raw/` (lihat README di sana
untuk cara mengambil ulang, termasuk cara membersihkan status bar).
Setelah raw lengkap:

```bash
python3 scripts/generate_store_assets.py
```

Output-nya:
- `store_assets/screenshots/android-phone/promo_*.png` — 1080x1920
- `store_assets/screenshots/ios-6.9-inch/promo_*.png` — 1290x2796

Catatan ukuran: 1080x1920 diterima Play Store tapi **tidak** ada di daftar
ukuran App Store Connect. Karena itu set iOS dibuat 1290x2796, salah satu
ukuran yang memang Apple cantumkan untuk layar 6.9". Apple hanya
mewajibkan set untuk layar terbesar; ukuran lain di-generate otomatis.

Urutan slide disusun sebagai alur pitch: apa aplikasinya (home), masalah
terbesar yang dipecahkan (keuangan), pembedanya (budget per kategori),
konteks lokal (kalender), keandalan (alarm), kepercayaan (password), lalu
pelengkap (konversi).

---

## Draft en-US (kalau nanti dibuka ke pasar lain)

### App name
Beres: Daily & Money Tracker

### Short description
Calendar, money, alarms and passwords in one app. Offline, no account.

### Full description (ringkas)

Beres brings together the tools usually scattered across half a dozen
apps: a calendar, an expense tracker, alarms, a calculator, unit and
currency conversion, and a password vault. Everything works offline and
stays on your own device — no account, no sign-in, no ads.

Track income and expenses and see where your money actually goes through
a six-month chart and a per-category breakdown. Set a monthly limit for
each spending category and get told the moment one is close to the edge.
Log a recurring bill once and Beres creates the transaction for you every
month, with a reminder the day before.

Alarms are scheduled through Android's AlarmManager, so they still ring
after the app is closed, and you can pick a ringtone from your phone's own
collection. Passwords sit behind your fingerprint, pattern or PIN, stored
locally and never uploaded.

Download Beres and keep the day in one place.
