<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PracticeLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class PracticeLogController extends Controller
{
    /**
     * Mendapatkan riwayat sesi latihan pengguna (Practice History).
     * GET /api/practice-logs
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user('sanctum');

        $query = PracticeLog::with('drill')->orderBy('created_at', 'desc');

        if ($user) {
            $query->where('user_id', $user->id);
        }

        $limit = $request->integer('limit', 20);
        $logs = $query->take($limit)->get();

        return response()->json([
            'success' => true,
            'message' => 'Riwayat latihan berhasil diambil',
            'count' => $logs->count(),
            'data' => $logs,
        ]);
    }

    /**
     * Menyimpan sesi latihan pengguna setelah menyelesaikan deteksi atau drill transisi.
     * POST /api/practice-logs
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'drill_id' => 'nullable|exists:practice_drills,id',
            'chord_name' => 'nullable|string|max:20',
            'accuracy' => 'required|numeric|min:0|max:100',
            'bpm' => 'nullable|integer|min:30|max:240',
            'duration_seconds' => 'required|integer|min:1',
            'notes' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi data sesi latihan gagal.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $userId = $request->user('sanctum')?->id;

        $log = PracticeLog::create([
            'user_id' => $userId,
            'drill_id' => $request->input('drill_id'),
            'chord_name' => $request->input('chord_name'),
            'accuracy' => (float) $request->input('accuracy'),
            'bpm' => $request->integer('bpm', 60),
            'duration_seconds' => $request->integer('duration_seconds', 0),
            'notes' => $request->input('notes'),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Sesi latihan berhasil dicatat!',
            'data' => $log->load('drill'),
        ], 201);
    }
}
