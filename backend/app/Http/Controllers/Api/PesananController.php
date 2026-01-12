<?php

namespace App\Http\Controllers\Api;

use Illuminate\Support\Str;
use Illuminate\Http\Request;
use App\Models\PesananServis;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Storage;

class PesananController extends Controller
{
    /**
     * READ: Ambil semua data pesanan
     */
    public function index()
    {
        $pesanan = PesananServis::latest()->get();

        return response()->json([
            'success' => true,
            'total'   => $pesanan->count(),
            'data'    => $pesanan->map(function ($item) {
                return array_merge($item->toArray(), [
                    'foto_1_url' => $item->foto_1 ? asset('storage/' . $item->foto_1) : null,
                    'foto_2_url' => $item->foto_2 ? asset('storage/' . $item->foto_2) : null,
                    'foto_3_url' => $item->foto_3 ? asset('storage/' . $item->foto_3) : null,
                ]);
            }),
        ]);
    }

    /**
     * POSTING + UPLOAD FOTO
     */
    public function posting(Request $request)
    {
        $request->validate([
            'data' => 'required|string',

            'foto_1' => 'nullable|image|mimes:jpg,jpeg,png|max:2048',
            'foto_2' => 'nullable|image|mimes:jpg,jpeg,png|max:2048',
            'foto_3' => 'nullable|image|mimes:jpg,jpeg,png|max:2048',
        ]);

        // decode JSON string
        $data = json_decode($request->data, true);

        if (!$data || empty($data['kode_transaksi'])) {
            return response()->json([
                'success' => false,
                'message' => 'Format data tidak valid'
            ], 422);
        }

        // UPSERT DATA
        $pesanan = PesananServis::updateOrCreate(
            ['kode_transaksi' => $data['kode_transaksi']],
            [
                'tanggal' => $data['tanggal'] ?? null,
                'biaya' => $data['biaya'] ?? 0,
                'nama_teknisi' => $data['nama_teknisi'] ?? null,
                'nama_pelanggan' => $data['nama_pelanggan'] ?? null,
                'nomor_telp' => $data['nomor_telp'] ?? null,
            ]
        );

        $fotoFields = [
            'foto_1',
            'foto_2',
            'foto_3',
        ];

        foreach ($fotoFields as $field) {
            if ($request->hasFile($field)) {

                // hapus foto lama
                if ($pesanan->$field && Storage::disk('public')->exists($pesanan->$field)) {
                    Storage::disk('public')->delete($pesanan->$field);
                }

                $extension = $request->file($field)->extension();

                // nama file pakai kode transaksi
                $filename = $data['kode_transaksi']
                    . '_' . $field
                    . '_' . time()
                    . '.' . $extension;

                // simpan ke folder uploads
                $path = $request->file($field)->storeAs(
                    'uploads',
                    $filename,
                    'public'
                );

                $pesanan->$field = $path;
            }
        }

        $pesanan->save();

        return response()->json([
            'success' => true,
            'message' => 'Posting & upload foto berhasil',
            'data' => $pesanan
        ]);
    }
}
