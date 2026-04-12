<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PaymentMethodSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('payment_methods')->insert([
            // ── Cash ──────────────────────────────────────────
            [
                'name'           => 'Cash',
                'type'           => 'cash',
                'account_number' => null,
                'account_name'   => null,
                'is_active'      => true,
                'created_at'     => now(),
                'updated_at'     => now(),
            ],

            // ── E-Wallet ──────────────────────────────────────
            [
                'name'           => 'GoPay',
                'type'           => 'e_wallet',
                'account_number' => null, // isi nomor HP kamu
                'account_name'   => null,
                'is_active'      => true,
                'created_at'     => now(),
                'updated_at'     => now(),
            ],
            [
                'name'           => 'OVO',
                'type'           => 'e_wallet',
                'account_number' => null,
                'account_name'   => null,
                'is_active'      => true,
                'created_at'     => now(),
                'updated_at'     => now(),
            ],
            [
                'name'           => 'Dana',
                'type'           => 'e_wallet',
                'account_number' => null,
                'account_name'   => null,
                'is_active'      => true,
                'created_at'     => now(),
                'updated_at'     => now(),
            ],

            // ── Bank Transfer ─────────────────────────────────
            [
                'name'           => 'BCA',
                'type'           => 'bank_transfer',
                'account_number' => null, // isi no rekening kamu
                'account_name'   => null,
                'is_active'      => true,
                'created_at'     => now(),
                'updated_at'     => now(),
            ],
            [
                'name'           => 'Mandiri',
                'type'           => 'bank_transfer',
                'account_number' => null,
                'account_name'   => null,
                'is_active'      => true,
                'created_at'     => now(),
                'updated_at'     => now(),
            ],
            [
                'name'           => 'BRI',
                'type'           => 'bank_transfer',
                'account_number' => null,
                'account_name'   => null,
                'is_active'      => true,
                'created_at'     => now(),
                'updated_at'     => now(),
            ],
            [
                'name'           => 'BNI',
                'type'           => 'bank_transfer',
                'account_number' => null,
                'account_name'   => null,
                'is_active'      => true,
                'created_at'     => now(),
                'updated_at'     => now(),
            ],
        ]);

        $this->command->info('✅ Payment methods seeded: Cash, GoPay, OVO, Dana, BCA, Mandiri, BRI, BNI');
    }
}