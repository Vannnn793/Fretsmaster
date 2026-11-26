<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Chord;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChordController extends Controller
{
    /**
     * Mendapatkan daftar seluruh open chord dasar beserta koordinat dan panduan penjarian.
     * GET /api/chords
     */
    public function index(Request $request): JsonResponse
    {
        $query = Chord::query();

        if ($request->has('difficulty')) {
            $query->where('difficulty', $request->query('difficulty'));
        }

        $chords = $query->orderBy('name')->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar chord berhasil diambil',
            'count' => $chords->count(),
            'data' => $chords,
        ]);
    }

    /**
     * Mendapatkan detail satu chord berdasarkan nama chord (misal: "C", "Am").
     * GET /api/chords/{name}
     */
    public function show(string $name): JsonResponse
    {
        $chord = Chord::where('name', $name)->orWhere('id', $name)->first();

        if (!$chord) {
            return response()->json([
                'success' => false,
                'message' => "Chord '{$name}' tidak ditemukan.",
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $chord,
        ]);
    }
}
