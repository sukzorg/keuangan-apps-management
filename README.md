# Rekap Keuangan

Repositori ini berisi aplikasi pengelolaan keuangan berbasis:

- Laravel untuk backend API
- Flutter untuk aplikasi mobile

Aplikasi ini digunakan untuk mencatat pemasukan, pengeluaran, rekap bulanan, hutang, alokasi budget, dan pengelolaan master data yang fleksibel.

## Fitur Utama

- Manajemen pemasukan dan pengeluaran
- Rekap bulanan keuangan
- Master data yang dapat ditambah, diubah, dan diaktifkan/nonaktifkan
- Kategori budget, hutang, sumber pemasukan, metode pembayaran, dan profil bisnis
- Dukungan akses server lokal dan Tailscale pada aplikasi mobile

## Struktur Project

```text
keuangan-apps-management/
├── assets/      # asset umum project seperti logo aplikasi
├── backend/     # Laravel API
└── frontend/    # Flutter mobile app
```

## Backend

Folder backend menggunakan Laravel sebagai REST API untuk aplikasi mobile.

Lokasi:

```text
backend/
```

Hal utama di backend:

- `app/Http/Controllers/Api` untuk controller API
- `app/Models` untuk model Eloquent
- `database/migrations` untuk struktur tabel
- `database/seeders` untuk data awal
- `routes/api.php` untuk route API

### Setup Backend

1. Masuk ke folder backend
2. Install dependency Composer
3. Salin file `.env`
4. Generate app key
5. Jalankan migration
6. Jalankan seeder bila diperlukan
7. Jalankan server Laravel

Contoh:

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed
php artisan serve
```

## Frontend

Folder frontend menggunakan Flutter untuk aplikasi mobile.

Lokasi:

```text
frontend/
```

Hal utama di frontend:

- `lib/pages` untuk halaman aplikasi
- `lib/models` untuk model data
- `lib/services/api_service.dart` untuk koneksi API
- `lib/theme` untuk tema aplikasi

### Setup Frontend

1. Masuk ke folder frontend
2. Ambil dependency Flutter
3. Jalankan aplikasi

Contoh:

```bash
cd frontend
flutter pub get
flutter run
```

## Konfigurasi API Mobile

Aplikasi Flutter mendukung dua kemungkinan akses server:

- Jaringan lokal: `http://192.168.2.9:8000/api`
- Tailscale: `http://100.76.114.56:8000/api`

`ApiService` akan mencoba endpoint lokal lebih dulu, lalu fallback ke Tailscale bila server lokal tidak dapat dijangkau.

## Build APK

Untuk membuat APK release:

```bash
cd frontend
flutter build apk --release
```

Hasil build:

```text
frontend/build/app/outputs/flutter-apk/app-release.apk
```

## Deploy Backend ke Server Linux Docker

Ringkasan alur deploy:

1. Upload source terbaru ke folder Laravel di server
2. Jalankan container Docker
3. Jalankan migration
4. Pastikan permission `storage` dan `bootstrap/cache` benar
5. Bersihkan cache Laravel

Contoh command umum:

```bash
docker-compose up -d --build
php artisan migrate --force
php artisan optimize:clear
```

Jika muncul error permission di Laravel, pastikan folder berikut writable:

- `storage`
- `bootstrap/cache`

## Catatan

- File `.env` backend tidak disimpan ke repository
- Folder build dan dependency lokal di-ignore dari Git
- Logo aplikasi berada di `assets/logo_aplikasi.png`

## Repository

GitHub:

[https://github.com/sukzorg/keuangan-apps-management](https://github.com/sukzorg/keuangan-apps-management)
