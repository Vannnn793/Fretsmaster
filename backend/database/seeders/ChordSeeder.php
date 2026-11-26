<?php

namespace Database\Seeders;

use App\Models\Chord;
use Illuminate\Database\Seeder;

class ChordSeeder extends Seeder
{
    public function run(): void
    {
        $chords = [
            [
                'name' => 'C',
                'full_name' => 'C Major',
                'notes' => 'C – E – G',
                'frets' => [-1, 3, 2, 0, 1, 0],
                'fingers' => [0, 3, 2, 0, 1, 0],
                'difficulty' => 'Mudah',
                'tip' => 'Lengkungkan jari telunjuk di fret 1 senar B agar senar high E di bawahnya tetap berbunyi bersih.',
                'strum' => 'Petik 5 senar dari senar 5 (A) ke senar 1 (e).',
            ],
            [
                'name' => 'A',
                'full_name' => 'A Major',
                'notes' => 'A – C# – E',
                'frets' => [-1, 0, 2, 2, 2, 0],
                'fingers' => [0, 0, 1, 2, 3, 0],
                'difficulty' => 'Mudah',
                'tip' => 'Rapatkan ketiga jari (1, 2, 3) di kolom fret 2 sedekat mungkin ke fret wire.',
                'strum' => 'Petik senar 5–1 (senar 6 jangan dibunyikan).',
            ],
            [
                'name' => 'Am',
                'full_name' => 'A Minor',
                'notes' => 'A – C – E',
                'frets' => [-1, 0, 2, 2, 1, 0],
                'fingers' => [0, 0, 2, 3, 1, 0],
                'difficulty' => 'Mudah',
                'tip' => 'Bentuk mirip chord E, namun seluruh formasi digeser turun satu senar ke bawah.',
                'strum' => 'Petik senar 5–1.',
            ],
            [
                'name' => 'G',
                'full_name' => 'G Major',
                'notes' => 'G – B – D',
                'frets' => [3, 2, 0, 0, 0, 3],
                'fingers' => [2, 1, 0, 0, 0, 3],
                'difficulty' => 'Mudah',
                'tip' => 'Rentangkan jari tengah ke fret 3 senar 6 dan jari telunjuk di fret 2 senar 5.',
                'strum' => 'Petik seluruh 6 senar gitar dengan mantap.',
            ],
            [
                'name' => 'E',
                'full_name' => 'E Major',
                'notes' => 'E – G# – B',
                'frets' => [0, 2, 2, 1, 0, 0],
                'fingers' => [0, 2, 3, 1, 0, 0],
                'difficulty' => 'Mudah',
                'tip' => 'Tekan senar 3 dengan telunjuk, senar 5 dengan tengah, dan senar 4 dengan manis.',
                'strum' => 'Petik seluruh 6 senar gitar.',
            ],
            [
                'name' => 'Em',
                'full_name' => 'E Minor',
                'notes' => 'E – G – B',
                'frets' => [0, 2, 2, 0, 0, 0],
                'fingers' => [0, 2, 3, 0, 0, 0],
                'difficulty' => 'Sangat Mudah',
                'tip' => 'Hanya butuh 2 jari di fret 2 pada senar 5 dan senar 4. Chord paling ramah pemula!',
                'strum' => 'Petik seluruh 6 senar gitar.',
            ],
            [
                'name' => 'D',
                'full_name' => 'D Major',
                'notes' => 'D – F# – A',
                'frets' => [-1, -1, 0, 2, 3, 2],
                'fingers' => [0, 0, 0, 1, 3, 2],
                'difficulty' => 'Mudah',
                'tip' => 'Bentuk segitiga kecil di 3 senar bawah pada fret 2 dan 3.',
                'strum' => 'Petik 4 senar terbawah (senar 4 ke senar 1).',
            ],
            [
                'name' => 'Dm',
                'full_name' => 'D Minor',
                'notes' => 'D – F – A',
                'frets' => [-1, -1, 0, 2, 3, 1],
                'fingers' => [0, 0, 0, 2, 3, 1],
                'difficulty' => 'Menengah',
                'tip' => 'Jari telunjuk menekan senar 1 pada fret 1, jari tengah senar 3 fret 2.',
                'strum' => 'Petik 4 senar terbawah.',
            ],
            [
                'name' => 'F',
                'full_name' => 'F Major',
                'notes' => 'F – A – C',
                'frets' => [1, 3, 3, 2, 1, 1],
                'fingers' => [1, 3, 4, 2, 1, 1],
                'difficulty' => 'Menengah',
                'tip' => 'Jari telunjuk mem-barre fret 1, jari tengah di fret 2 senar 3, serta jari manis & kelingking di fret 3 senar 5 & 4.',
                'strum' => 'Petik seluruh 6 senar atau 4 senar terbawah.',
            ],
            [
                'name' => 'B',
                'full_name' => 'B Major',
                'notes' => 'B – D# – F#',
                'frets' => [-1, 2, 4, 4, 4, 2],
                'fingers' => [0, 1, 2, 3, 4, 1],
                'difficulty' => 'Lanjutan',
                'tip' => 'Telunjuk menekan fret 2 senar 5, tiga jari (tengah, manis, kelingking) berjejer rapat di kolom fret 4.',
                'strum' => 'Petik 5 senar dari senar 5 ke senar 1.',
            ],
        ];

        foreach ($chords as $chord) {
            Chord::updateOrCreate(['name' => $chord['name']], $chord);
        }
    }
}
