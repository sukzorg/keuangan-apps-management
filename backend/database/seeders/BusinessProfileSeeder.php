<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class BusinessProfileSeeder extends Seeder
{
    public function run(): void
    {
        // ── 1. Insert Business Profiles ───────────────────────────────
        $businesses = [
            [
                'name'        => 'Photography',
                'type'        => 'photography',
                'description' => 'Jasa foto & video (wedding, event, portrait)',
                'is_active'   => true,
                'created_at'  => now(),
                'updated_at'  => now(),
            ],
            [
                'name'        => 'Service HP & Laptop',
                'type'        => 'service_gadget',
                'description' => 'Service & repair perangkat elektronik',
                'is_active'   => true,
                'created_at'  => now(),
                'updated_at'  => now(),
            ],
            [
                'name'        => 'Internet RT/RW',
                'type'        => 'internet_provider',
                'description' => 'Jasa penyedia internet lingkungan',
                'is_active'   => true,
                'created_at'  => now(),
                'updated_at'  => now(),
            ],
            [
                'name'        => 'Kosan',
                'type'        => 'boarding_house',
                'description' => 'Properti kos-kosan',
                'is_active'   => true,
                'created_at'  => now(),
                'updated_at'  => now(),
            ],
            [
                'name'        => 'Jasa Penjualan Aplikasi',
                'type'        => 'app_development',
                'description' => 'Pembuatan & penjualan aplikasi',
                'is_active'   => true,
                'created_at'  => now(),
                'updated_at'  => now(),
            ],
        ];

        DB::table('business_profiles')->insert($businesses);

        // Ambil ID yang baru dibuat
        $photo   = DB::table('business_profiles')->where('type', 'photography')->first()->id;
        $service = DB::table('business_profiles')->where('type', 'service_gadget')->first()->id;
        $net     = DB::table('business_profiles')->where('type', 'internet_provider')->first()->id;
        $kosan   = DB::table('business_profiles')->where('type', 'boarding_house')->first()->id;
        $app     = DB::table('business_profiles')->where('type', 'app_development')->first()->id;

        // ── 2. Insert Business Expense Categories ─────────────────────
        // Sesuai jawaban: Photography (semua 4), Service (sparepart + alat + gaji)
        $categories = [
            // Photography — semua 4 kategori dipilih
            [$photo,   'Beli Alat/Equipment',   'Kamera, lensa, drone, lighting, tripod, dll'],
            [$photo,   'Transport',              'Bensin, tol, parkir ke lokasi pemotretan'],
            [$photo,   'Editing & Software',     'Lisensi Lightroom, Photoshop, Premiere Pro'],
            [$photo,   'Bayar Asisten/Model',    'Honor asisten fotografer & model'],

            // Service HP & Laptop — sparepart + alat + gaji teknisi
            [$service, 'Beli Sparepart',         'LCD, baterai, IC, komponen HP & laptop'],
            [$service, 'Alat Servis',             'Solder, hot air gun, obeng, tools repair'],
            [$service, 'Gaji Teknisi',            'Upah teknisi harian/bulanan'],

            // Internet RT/RW — semua operasional
            [$net,     'Bayar ISP/Provider',     'Tagihan internet upstream ke provider utama'],
            [$net,     'Maintenance Perangkat',  'Router, switch, kabel fiber, ODP, splitter'],
            [$net,     'Bayar Teknisi Lapangan', 'Upah teknisi instalasi & troubleshoot'],
            [$net,     'Listrik Perangkat',       'Biaya listrik tower & perangkat jaringan'],

            // Kosan — semua operasional
            [$kosan,   'Listrik & Air',           'Tagihan PLN & PDAM kosan'],
            [$kosan,   'Perbaikan/Renovasi',      'Cat, keramik, genteng, sanitasi, dll'],
            [$kosan,   'Kebersihan',               'Biaya cleaning service & kebersihan'],
            [$kosan,   'Cicilan Properti/KPR',    'Angsuran kredit properti kosan'],

            // Jasa Aplikasi — operasional digital
            [$app,     'Server & Hosting',        'VPS, cloud server, domain, SSL'],
            [$app,     'Lisensi Software',         'Tools development & software berbayar'],
            [$app,     'Marketing & Iklan',        'Meta Ads, Google Ads, promosi digital'],
            [$app,     'Bayar Developer',          'Honor freelancer & developer'],
        ];

        foreach ($categories as [$bizId, $name, $desc]) {
            DB::table('business_expense_categories')->insert([
                'business_id' => $bizId,
                'name'        => $name,
                'description' => $desc,
                'is_active'   => true,
                'created_at'  => now(),
                'updated_at'  => now(),
            ]);
        }

        $this->command->info('✅ Business profiles seeded: 5 bisnis dengan total ' . count($categories) . ' kategori pengeluaran');
    }
}