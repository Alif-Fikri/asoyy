# Shorebird — update code tanpa lewat review store

Shorebird sudah aktif untuk app ini. App ID: lihat `shorebird.yaml` (aman
di-commit, bukan rahasia). Login: `fikritestings@gmail.com`.

## Yang perlu dipahami

Shorebird mengirim **patch kode Dart** ke perangkat yang sudah terpasang,
tanpa lewat review Play Store/App Store lagi. Ini menggantikan siklus
"submit → tunggu review → user update manual" untuk perbaikan bug di sisi
Dart.

**Yang BISA di-patch** (perubahan murni Dart/Flutter):
- Logic, UI, bug fix, teks, warna, alur navigasi

**Yang TIDAK BISA di-patch** — wajib rilis baru lewat Play Store/App Store:
- Perubahan native (Kotlin/Swift), termasuk `MainActivity.kt`
- Permission baru di `AndroidManifest.xml` / `Info.plist`
- Dependency baru yang punya kode native (plugin baru)
- Aset yang didaftarkan lewat `pubspec.yaml` sebagai native resource

Kalau ragu, coba `shorebird patch` dulu — dia akan menolak dan bilang
alasannya kalau memang butuh rilis baru.

## Alur kerja

**Rilis baru** (versi dengan perubahan native, atau rilis pertama sebuah
versi) — ganti `flutter build` dengan:

```bash
shorebird release android   # menghasilkan app-release.aab, upload manual ke Play Console seperti biasa
shorebird release ios       # kalau nanti build iOS
```

**Patch** (perbaikan bug/UI cepat untuk versi yang SUDAH dirilis, tanpa
naik ke Play Console lagi):

```bash
shorebird patch android --release-version=1.0.0+1
```

`--release-version` harus cocok dengan versi yang sedang dipakai user
(lihat `pubspec.yaml` → `version:`). Patch menempel ke release itu; kalau
nanti naik ke `1.0.1+2`, buat `shorebird release` dulu untuk versi itu,
baru bisa di-patch.

## Kapan naik versi vs kapan cukup patch

- **Ubah kode Dart saja** (fix bug, ubah UI, tambah fitur yang tidak
  butuh permission/plugin baru) → `shorebird patch`, versi tidak perlu
  naik.
- **Nambah permission, plugin native, atau minSdk berubah** → naikkan
  `version:` di `pubspec.yaml`, jalankan `shorebird release android`,
  upload AAB baru ke Play Console seperti rilis biasa.

## Cek status

```bash
shorebird releases list          # semua release yang pernah dibuat
shorebird patches list --release-version=1.0.0+1   # patch yang sudah dikirim untuk versi itu
```

## Setup yang sudah dilakukan

- `shorebird.yaml` dibuat dan didaftarkan sebagai asset di `pubspec.yaml`
  (wajib, supaya Shorebird bisa membaca app_id-nya saat runtime)
- `shorebird doctor` bersih — tidak ada masalah konfigurasi
- Release pertama (`1.0.0+1`, android) sudah dipublikasikan ke Shorebird
  dan bisa langsung menerima patch begitu ada bug yang perlu diperbaiki
  cepat setelah app live

## Perintah `shorebird` vs `flutter`

Shorebird membawa Flutter SDK sendiri (fork resmi, sinkron dengan
upstream). Jangan campur: kalau sudah pakai `shorebird release`/`patch`
untuk suatu build, pakai `shorebird` juga untuk build berikutnya di
platform yang sama supaya versi Flutter/engine konsisten dengan yang
sudah dipasang di perangkat user.
