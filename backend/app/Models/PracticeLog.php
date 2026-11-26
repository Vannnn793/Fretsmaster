<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PracticeLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'drill_id',
        'chord_name',
        'accuracy',
        'bpm',
        'duration_seconds',
        'notes',
    ];

    protected $casts = [
        'accuracy' => 'float',
        'bpm' => 'integer',
        'duration_seconds' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function drill()
    {
        return $this->belongsTo(PracticeDrill::class, 'drill_id');
    }
}
