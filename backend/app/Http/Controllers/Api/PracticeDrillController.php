<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PracticeDrill;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PracticeDrillController extends Controller
{
    /**
     * Mendapatkan daftar paket latihan transisi chord (drill sequences + target BPM).
     * GET /api/drills
     */
    public function index(Request $request): JsonResponse
    {
        $drills = PracticeDrill::orderBy('target_bpm', 'asc')->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar latihan transisi chord berhasil diambil',
            'count' => $drills->count(),
            'data' => $drills,
        ]);
    }

    /**
     * Detail satu paket latihan transisi.
     * GET /api/drills/{id}
     */
    public function show(int $id): JsonResponse
    {
        $drill = PracticeDrill::find($id);

        if (!$drill) {
            return response()->json([
                'success' => false,
                'message' => 'Paket latihan tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $drill,
        ]);
    }
}
