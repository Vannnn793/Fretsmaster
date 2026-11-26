<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChordController;
use App\Http\Controllers\Api\PracticeDrillController;
use App\Http\Controllers\Api\PracticeLogController;
use Illuminate\Support\Facades\Route;

// Health check / API status endpoint
Route::get('/', function () {
    return response()->json([
        'success' => true,
        'app' => 'FretMaster AI Guitar Chord Trainer',
        'message' => 'FretMaster REST API Server aktif dan siap melayani aplikasi!',
        'version' => '1.0.0',
        'endpoints' => [
            'POST /api/register' => 'Registrasi musisi baru',
            'POST /api/login' => 'Login musisi & dapatkan token Sanctum',
            'GET /api/user' => 'Profil musisi terautentikasi (Bearer Token)',
            'POST /api/logout' => 'Logout & cabut token (Bearer Token)',
            'GET /api/chords' => 'Daftar open chord dasar & diagram titik jari',
            'GET /api/chords/{name}' => 'Detail satu chord',
            'GET /api/drills' => 'Daftar paket latihan transisi chord & target BPM',
            'GET /api/drills/{id}' => 'Detail satu paket latihan transisi',
            'GET /api/practice-logs' => 'Riwayat sesi latihan',
            'POST /api/practice-logs' => 'Simpan hasil sesi latihan baru',
        ],
    ]);
});

// Authentication routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Chords Library & Guides
Route::get('/chords', [ChordController::class, 'index']);
Route::get('/chords/{name}', [ChordController::class, 'show']);

// Practice Drills
Route::get('/drills', [PracticeDrillController::class, 'index']);
Route::get('/drills/{id}', [PracticeDrillController::class, 'show']);

// Practice Logs (Guest or Authenticated)
Route::get('/practice-logs', [PracticeLogController::class, 'index']);
Route::post('/practice-logs', [PracticeLogController::class, 'store']);

// Authenticated routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'profile']);
    Route::post('/logout', [AuthController::class, 'logout']);
});
