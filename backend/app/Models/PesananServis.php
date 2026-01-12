<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PesananServis extends Model
{
    use HasFactory;

    protected $table = 'pesanan_servis';

    protected $fillable = [
        'kode_transaksi',
        'tanggal',
        'biaya',
        'nama_teknisi',
        'nama_pelanggan',
        'nomor_telp',
        'foto_1',
        'foto_2',
        'foto_3',
    ];
}
