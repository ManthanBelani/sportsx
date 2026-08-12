<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AdminPanelController;

Route::get('/', function () {
    return view('welcome');
});

// ── Admin panel (server-rendered Blade, session auth) ──────────────────────────
Route::prefix('panel')->name('admin.')->group(function () {

    // Public auth routes
    Route::get('/login', [AdminPanelController::class, 'showLogin'])->name('login');
    Route::post('/login', [AdminPanelController::class, 'login']);
    Route::get('/2fa', [AdminPanelController::class, 'show2fa'])->name('2fa');
    Route::post('/2fa', [AdminPanelController::class, 'verify2fa']);
    Route::post('/logout', [AdminPanelController::class, 'logout'])->name('logout');

    // Protected routes
    Route::middleware(['auth', 'admin.panel'])->group(function () {
        Route::get('/dashboard', [AdminPanelController::class, 'dashboard'])->name('dashboard');

        // Users
        Route::get('/users', [AdminPanelController::class, 'users'])->name('users');
        Route::get('/users/{id}', [AdminPanelController::class, 'userDetail'])->name('users.detail');
        Route::post('/users/{id}/status', [AdminPanelController::class, 'updateUserStatus'])->name('users.status');
        Route::delete('/users/{id}', [AdminPanelController::class, 'destroyUser'])->name('users.destroy');

        // Content
        Route::get('/content', [AdminPanelController::class, 'content'])->name('content');
        Route::get('/content/{type}/create', [AdminPanelController::class, 'contentCreate'])->name('content.create');
        Route::post('/content/{type}', [AdminPanelController::class, 'contentStore'])->name('content.store');
        Route::get('/content/{type}/{id}/edit', [AdminPanelController::class, 'contentEdit'])->name('content.edit');
        Route::put('/content/{type}/{id}', [AdminPanelController::class, 'contentUpdate'])->name('content.update');
        Route::get('/content/{type}', [AdminPanelController::class, 'contentList'])->name('content.list');
        Route::delete('/content/{type}/{id}', [AdminPanelController::class, 'contentDestroy'])->name('content.destroy');
        Route::post('/content/{type}/{id}/publish', [AdminPanelController::class, 'contentPublish'])->name('content.publish');

        // Expiry monitor + rules (GET /expiry/monitor, override, restore, rules)
        Route::get('/expiry', [AdminPanelController::class, 'expiry'])->name('expiry');
        Route::post('/expiry/{id}/override', [AdminPanelController::class, 'expiryOverride'])->name('expiry.override');
        Route::post('/expiry/{id}/restore', [AdminPanelController::class, 'expiryRestore'])->name('expiry.restore');
        Route::post('/expiry-rules', [AdminPanelController::class, 'expiryRulesUpdate'])->name('expiry.rules');

        // Moderation
        Route::get('/moderation', [AdminPanelController::class, 'moderation'])->name('moderation');
        Route::post('/moderation/{id}', [AdminPanelController::class, 'moderationAction'])->name('moderation.action');

        // Report Center
        Route::get('/reports', [AdminPanelController::class, 'reports'])->name('reports');
        Route::post('/reports/{id}', [AdminPanelController::class, 'reportAction'])->name('reports.action');

        // Content Flags
        Route::get('/flags', [AdminPanelController::class, 'flags'])->name('flags');
        Route::post('/flags/{id}', [AdminPanelController::class, 'flagAction'])->name('flags.action');

        // Sponsor Verification
        Route::get('/sponsors', [AdminPanelController::class, 'sponsors'])->name('sponsors');
        Route::post('/sponsors/{id}', [AdminPanelController::class, 'sponsorAction'])->name('sponsors.action');

        // Analytics
        Route::get('/analytics', [AdminPanelController::class, 'analytics'])->name('analytics');

        // Notifications
        Route::get('/notifications', [AdminPanelController::class, 'notifications'])->name('notifications');
        Route::post('/notifications/broadcast', [AdminPanelController::class, 'broadcast'])->name('notifications.broadcast');

        // System Settings
        Route::get('/settings', [AdminPanelController::class, 'settings'])->name('settings');
        Route::post('/settings', [AdminPanelController::class, 'updateSettings'])->name('settings.update');

        // Categories
        Route::get('/categories', [AdminPanelController::class, 'categories'])->name('categories');
        Route::post('/categories/{type}', [AdminPanelController::class, 'categoryStore'])->name('categories.store');
        Route::put('/categories/{type}/{id}', [AdminPanelController::class, 'categoryUpdate'])->name('categories.update');
        Route::post('/categories/{type}/{id}/toggle', [AdminPanelController::class, 'categoryToggle'])->name('categories.toggle');
        Route::delete('/categories/{type}/{id}', [AdminPanelController::class, 'categoryDestroy'])->name('categories.destroy');
    });
});
