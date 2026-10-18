<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$users = App\Models\User::all(['id', 'name', 'email', 'phone', 'role', 'status', 'password']);
foreach ($users as $u) {
    $hasDefaultPass = Illuminate\Support\Facades\Hash::check('password', $u->password) ? 'YES' : 'NO';
    $hasPass123 = Illuminate\Support\Facades\Hash::check('password123', $u->password) ? 'YES' : 'NO';
    $hasSecret = Illuminate\Support\Facades\Hash::check('secret', $u->password) ? 'YES' : 'NO';
    echo "ID: {$u->id} | Role: {$u->role} | Status: {$u->status} | Email: {$u->email} | Pass 'password': {$hasDefaultPass} | Pass 'password123': {$hasPass123}\n";
}
