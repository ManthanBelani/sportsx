<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$scholarships = Illuminate\Support\Facades\DB::select('SELECT name, sport_id FROM scholarships');
foreach ($scholarships as $s) {
    echo $s->name . " - " . $s->sport_id . "\n";
}
