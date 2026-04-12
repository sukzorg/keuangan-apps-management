<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Jalankan dengan: php artisan db:seed
     * Atau fresh migrate + seed: php artisan migrate:fresh --seed
     */
    public function run(): void
    {
        $this->command->info('🚀 Memulai seeding database keuangan-app...');
        $this->command->newLine();

        // URUTAN WAJIB — jangan diubah (ada foreign key dependency)
        $this->call([
            PaymentMethodSeeder::class,   // 1. Payment methods dulu (direferensikan banyak tabel)
            BusinessProfileSeeder::class, // 2. Business profiles + expense categories
            IncomeSourceSeeder::class,    // 3. Income sources (butuh business_id)
            MasterDataSeeder::class,      // 4. Debt categories + budget categories
        ]);

        $this->command->newLine();
        $this->command->info('🎉 Semua data master berhasil di-seed!');
        $this->command->info('👉 Selanjutnya: isi account_number di tabel payment_methods sesuai rekening kamu.');
    }
}