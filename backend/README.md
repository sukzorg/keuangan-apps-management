# Rekap Keuangan Backend

Backend aplikasi ini dibangun menggunakan Laravel dan berfungsi sebagai REST API untuk aplikasi mobile Flutter.

## Tanggung Jawab Backend

- Menyediakan API pemasukan dan pengeluaran
- Menyediakan API rekap bulanan
- Menyediakan API master data
- Menyimpan data hutang, alokasi budget, bisnis, dan metode pembayaran
- Menjadi sumber data utama untuk aplikasi mobile

## Struktur Penting

```text
backend/
├── app/Http/Controllers/Api
├── app/Models
├── database/migrations
├── database/seeders
└── routes/api.php
```

## Endpoint Utama

Beberapa kelompok endpoint yang digunakan aplikasi:

- `/api/incomes`
- `/api/expenses`
- `/api/categories`
- `/api/master-data/{resource}`
- `/api/payment-methods`
- `/api/income-sources`
- `/api/businesses`
- `/api/monthly-recaps`
- `/api/debts`

## Kebutuhan Sistem

- PHP 8.2 atau lebih baru
- Composer
- MySQL
- Laravel Artisan CLI

## Setup Lokal

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed
php artisan serve
```

## Konfigurasi Database

Sesuaikan file `.env` dengan koneksi database yang digunakan.

Contoh variabel penting:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=keuangan_db
DB_USERNAME=root
DB_PASSWORD=
```

## Seeder

Seeder utama yang tersedia antara lain:

- `PaymentMethodSeeder`
- `BusinessProfileSeeder`
- `IncomeSourceSeeder`
- `MasterDataSeeder`

Jalankan semua seeder:

```bash
php artisan db:seed
```

## Testing

Untuk menjalankan pengujian backend:

```bash
php artisan test
```

## Deploy ke Linux Docker

Jika backend dijalankan di Docker Linux, alur umumnya:

```bash
docker-compose up -d --build
php artisan migrate --force
php artisan optimize:clear
```

Jika terjadi error permission, pastikan folder berikut writable:

- `storage`
- `bootstrap/cache`

## Catatan

- File `.env` tidak ikut disimpan ke repository
- Migration terbaru harus dijalankan saat deploy
- API dipakai oleh frontend Flutter dengan fallback akses lokal dan Tailscale
