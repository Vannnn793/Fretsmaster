<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PracticeDrill extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'chords',
        'target_bpm',
        'difficulty',
    ];

    protected $casts = [
        'chords' => 'array',
        'target_bpm' => 'integer',
    ];

    public function practiceLogs()
    {
        return $this->hasMany(PracticeLog::class, 'drill_id');
    }
}
