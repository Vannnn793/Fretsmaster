<?php

namespace Database\Seeders;

use App\Models\PracticeDrill;
use Illuminate\Database\Seeder;

class PracticeDrillSeeder extends Seeder
{
    public function run(): void
    {
        $drills = [
            [
                'title' => 'Pondasi Transisi Pemula (Em ➔ G)',
                'description' => 'Latihan dasar dua chord paling populer untuk membangun memori otot jari tangan kiri.',
                'chords' => ['Em', 'G'],
                'target_bpm' => 60,
                'difficulty' => 'Pemula',
            ],
            [
                'title' => 'Progresi Pop Klasik (G ➔ D ➔ Em ➔ C)',
                'description' => 'Progresi 4 chord paling legendaris yang dipakai di ratusan lagu pop dunia.',
                'chords' => ['G', 'D', 'Em', 'C'],
                'target_bpm' => 75,
                'difficulty' => 'Menengah',
            ],
            [
                'title' => 'Folk & Balada Melankolis (C ➔ G ➔ Am ➔ Em)',
                'description' => 'Melatih transisi jari manis dan telunjuk antar senar atas dan bawah secara halus.',
                'chords' => ['C', 'G', 'Am', 'Em'],
                'target_bpm' => 70,
                'difficulty' => 'Menengah',
            ],
            [
                'title' => 'Campfire Rock Anthems (E ➔ A ➔ D)',
                'description' => 'Kombinasi klasik lagu rock akustik dengan pergantian tempo cepat.',
                'chords' => ['E', 'A', 'D'],
                'target_bpm' => 85,
                'difficulty' => 'Menengah',
            ],
        ];

        foreach ($drills as $drill) {
            PracticeDrill::updateOrCreate(['title' => $drill['title']], $drill);
        }
    }
}
