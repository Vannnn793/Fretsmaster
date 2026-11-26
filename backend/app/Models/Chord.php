<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Chord extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'full_name',
        'notes',
        'frets',
        'fingers',
        'difficulty',
        'tip',
        'strum',
    ];

    protected $casts = [
        'frets' => 'array',
        'fingers' => 'array',
    ];
}
