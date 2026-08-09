<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AdminWebController;

Route::get('/', function () {
    return view('welcome');
});

Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/login', [AdminWebController::class, 'login'])->name('login');
    Route::get('/dashboard', [AdminWebController::class, 'dashboard'])->name('dashboard');
    Route::get('/users', [AdminWebController::class, 'users'])->name('users');
    Route::get('/users/{id}', [AdminWebController::class, 'userDetail'])->name('users.detail');
    Route::get('/approvals', [AdminWebController::class, 'approvals'])->name('approvals');
    Route::get('/moderation', [AdminWebController::class, 'moderation'])->name('moderation');
    Route::get('/moderation/{id}', [AdminWebController::class, 'reportDetail'])->name('moderation.detail');
    Route::get('/notifications/compose', [AdminWebController::class, 'composeNotification'])->name('notifications.compose');
    Route::get('/opportunities', [AdminWebController::class, 'opportunities'])->name('opportunities');
    Route::get('/reports', [AdminWebController::class, 'reports'])->name('reports');
    Route::get('/analytics', [AdminWebController::class, 'analytics'])->name('analytics');
    Route::get('/sponsors', [AdminWebController::class, 'sponsors'])->name('sponsors');
    Route::get('/categories', [AdminWebController::class, 'categories'])->name('categories');
    Route::get('/settings', [AdminWebController::class, 'settings'])->name('settings');
});
