# Rekap Keuangan Mobile

Frontend aplikasi ini dibangun menggunakan Flutter dan terhubung ke backend Laravel melalui REST API.

## Fitur Aplikasi

- Dashboard ringkasan keuangan
- Pencatatan pemasukan
- Pencatatan pengeluaran
- Rekap bulanan
- Master data yang dapat diubah langsung dari aplikasi
- Dukungan akses server lokal dan Tailscale

## Struktur Penting

```text
frontend/
├── lib/models
├── lib/pages
├── lib/services
├── lib/theme
└── main.dart
```

## Setup Development

```bash
cd frontend
flutter pub get
flutter run
```

## Konfigurasi API

Koneksi API diatur pada:

```text
lib/services/api_service.dart
```

Aplikasi saat ini mendukung fallback otomatis ke dua endpoint:

- Lokal: `http://192.168.2.9:8000/api`
- Tailscale: `http://100.76.114.56:8000/api`

Saat jaringan lokal tidak tersedia, aplikasi akan mencoba endpoint Tailscale secara otomatis.

## Build APK Release

```bash
cd frontend
flutter build apk --release
```

Lokasi hasil build:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Launcher Icon

Logo aplikasi dihasilkan dari file:

```text
../assets/logo_aplikasi.png
```

Konfigurasi icon dikelola melalui `flutter_launcher_icons`.

Untuk generate ulang icon:

```bash
dart run flutter_launcher_icons
```

## Validasi

Untuk memastikan project frontend tetap bersih:

```bash
flutter analyze
```

## Catatan

- Android diatur agar dapat mengakses endpoint HTTP berbasis IP
- Build release akan menggunakan launcher icon yang sudah diperbarui
- Jika endpoint backend berubah, cukup sesuaikan daftar base URL di `ApiService`
