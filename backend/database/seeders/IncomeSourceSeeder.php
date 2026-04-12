<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class IncomeSourceSeeder extends Seeder
{
    public function run(): void
    {
        // Ambil ID bisnis
        $photo   = DB::table('business_profiles')->where('type', 'photography')->first()?->id;
        $service = DB::table('business_profiles')->where('type', 'service_gadget')->first()?->id;
        $net     = DB::table('business_profiles')->where('type', 'internet_provider')->first()?->id;
        $kosan   = DB::table('business_profiles')->where('type', 'boarding_house')->first()?->id;
        $app     = DB::table('business_profiles')->where('type', 'app_development')->first()?->id;

        DB::table('income_sources')->insert([
            // ── Gaji ──────────────────────────────────────────────
            [
                'name'        => 'Gaji',
                'type'        => 'salary',
                'business_id' => null,
                'description' => 'Gaji bulanan (masuk tanggal 25)',
                'is_active'   => true,
                'created_at'  => now(),
                'updated_at'  => now(),
            ],

            // ── Bisnis ────────────────────────────────────────────
            [
                'name'        => 'Photography',
                'type'        => 'business',
                'business_id' => $photo,
                'description' => 'Pendapatan dari jasa foto & video',
                'is_active'   => true,
                'created_at'  => now(),
                'updated_at'  => now(),
            ],
            [
                'name'        => 'Service HP & Laptop',
                'type'        => 'business',
                'business_id' => $service,
                'description' => 'Pendapatan dari jasa service elektronik',
                'is_active'   => true,
                'created_at'  => now(),
                'updated_at'  => now(),
            ],
            [
                'name'        => 'Internet RT/RW',
                'type'        => 'business',
                'business_id' => $net,
                'description' => 'Iuran bulanan pelanggan internet',
                'is_active'   => true,
                'created_at'  => now(),
                'updated_at'  => now(),
            ],
            [
                'name'        => 'Kosan',
                'type'        => 'business',
                'business_id' => $kosan,
                'description' => 'Uang sewa kos per bulan',
                'is_active'   => true,
                'created_at'  => now(),
                'updated_at'  => now(),
            ],
            [
                'name'        => 'Jasa Penjualan Aplikasi',
                'type'        => 'business',
                'business_id' => $app,
                'description' => 'Pendapatan dari pembuatan & penjualan aplikasi',
                'is_active'   => true,
                'created_at'  => now(),
                'updated_at'  => now(),
            ],

            // ── Investasi ─────────────────────────────────────────
            [
                'name'        => 'Investasi',
                'type'        => 'investment',
                'business_id' => null,
                'description' => 'Return investasi (saham, reksa dana, deposito)',
                'is_active'   => true,
                'created_at'  => now(),
                'updated_at'  => now(),
            ],

            // ── Lain-lain ─────────────────────────────────────────
            [
                'name'        => 'Lain-lain',
                'type'        => 'other',
                'business_id' => null,
                'description' => 'Pendapatan luar biasa / tidak rutin',
                'is_active'   => true,
                'created_at'  => now(),
                'updated_at'  => now(),
            ],
        ]);

        $this->command->info('✅ Income sources seeded: Gaji, 5 Bisnis, Investasi, Lain-lain');
    }
}