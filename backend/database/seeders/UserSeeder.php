<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Pastikan akun demo tersedia untuk kemudahan pengujian & login
        User::updateOrCreate(
            ['email' => 'demo@fretmaster.com'],
            [
                'name' => 'Gitaris FretMaster',
                'password' => Hash::make('password123'),
            ]
        );

        User::updateOrCreate(
            ['email' => 'admin@fretmaster.com'],
            [
                'name' => 'FretMaster Admin',
                'password' => Hash::make('password123'),
            ]
        );
    }
}
