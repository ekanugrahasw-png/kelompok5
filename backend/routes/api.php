<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PesananController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:api')->group(function () {
    Route::get('/cek-token', function () {
        return response()->json([
            'valid' => true,
            'user' => auth()->user(),
        ]);
    });

    Route::get('/pesanan', [PesananController::class, 'index']);
    Route::post('/posting-pesanan', [PesananController::class, 'posting']);
});
