<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

// Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
//     return $request->user();
// });

Route::get('/getData', function () {
    // Path to your JSON file (adjust if needed)
    $path = storage_path('app/users_orders.json');

    if (!file_exists($path)) {
        return response()->json(['error' => 'Data file not found'], 404);
    } 

    // Read the file contents
    $json = file_get_contents($path);

    // Decode JSON to PHP array (optional)
    $data = json_decode($json, true);

    // Return as JSON response
    return response()->json($data);
});
