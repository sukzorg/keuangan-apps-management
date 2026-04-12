<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MasterDataSeeder extends Seeder
{
    public function run(): void
    {
        // ── Debt Categories ───────────────────────────────────────────
        DB::table('debt_categories')->insert([
            ['name' => 'KPR',              'description' => 'Kredit Pemilikan Rumah',      'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Kendaraan',        'description' => 'Kredit motor / mobil',        'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Kartu Kredit',     'description' => 'Tagihan kartu kredit',        'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Pinjaman Pribadi', 'description' => 'Hutang ke orang / keluarga', 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Pinjaman Online',  'description' => 'Pinjol / fintech lending',   'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Modal Bisnis',     'description' => 'Pinjaman untuk modal usaha',  'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
        ]);

        // ── Budget Categories (50/30/20 rule) ────────────────────────
        // wajib = kebutuhan utama (50%)
        // penting = kebutuhan sekunder (30%)
        // keinginan = lifestyle & planning (20%)
        DB::table('budget_categories')->insert([
            // WAJIB
            ['name' => 'Makan & Minum',      'priority' => 'wajib',     'description' => 'Kebutuhan pangan harian',          'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Transport',           'priority' => 'wajib',     'description' => 'BBM, parkir, ojek online',          'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Listrik & Air',       'priority' => 'wajib',     'description' => 'Tagihan utilitas rumah tinggal',    'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Internet & Pulsa',    'priority' => 'wajib',     'description' => 'Kebutuhan komunikasi pribadi',      'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Kebutuhan Rumah',     'priority' => 'wajib',     'description' => 'Sabun, deterjen, keperluan harian', 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],

            // PENTING
            ['name' => 'Kesehatan',           'priority' => 'penting',   'description' => 'Obat, dokter, BPJS Kesehatan',     'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Pendidikan',          'priority' => 'penting',   'description' => 'Kursus, buku, pelatihan',          'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Tabungan',            'priority' => 'penting',   'description' => 'Dana darurat (target 3-6x gaji)',   'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Investasi',           'priority' => 'penting',   'description' => 'Saham, reksa dana, emas',          'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Asuransi',            'priority' => 'penting',   'description' => 'Premi asuransi jiwa / jiwa',       'is_active' => true, 'created_at' => now(), 'updated_at' => now()],

            // KEINGINAN
            ['name' => 'Hiburan',             'priority' => 'keinginan', 'description' => 'Nonton, game, streaming',          'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Makan di Luar',       'priority' => 'keinginan', 'description' => 'Restoran, kafe, hangout',          'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Belanja Pakaian',     'priority' => 'keinginan', 'description' => 'Pakaian, sepatu, aksesoris',       'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Gadget & Elektronik', 'priority' => 'keinginan', 'description' => 'HP, laptop, aksesoris digital',   'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Planning / Wishlist', 'priority' => 'keinginan', 'description' => 'Target & keinginan bulan depan',   'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Liburan',             'priority' => 'keinginan', 'description' => 'Dana liburan & perjalanan',        'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
        ]);

        $this->command->info('✅ Master data seeded: 6 debt categories, 16 budget categories');
    }
}