<?php

namespace App\Http\Controllers;

use App\Models\AthleteProfile;
use App\Models\Connection;
use App\Models\GuardianConsent;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class AthleteContactController extends Controller
{
    /**
     * POST /athletes/{id}/contact {purpose}
     * Creates (or reuses) a connection request. U-18 → guardian notified;
     * chat still requires guardian consent (enforced in ConversationController).
     */
    public function store(Request $request, string $id)
    {
        $validated = $request->validate(['purpose' => 'required|string|max:500']);
        $athlete = AthleteProfile::with('user')->findOrFail($id);

        abort_if($athlete->user_id === $request->user()->id, 422, 'You cannot contact yourself.');

        $connection = Connection::firstOrCreate(
            ['follower_user_id' => $request->user()->id, 'followee_user_id' => $athlete->user_id],
            ['status' => 'pending']
        );

        $isMinor = false;
        if ($athlete->date_of_birth) {
            try {
                $isMinor = Carbon::parse($athlete->date_of_birth)->age < 18;
            } catch (\Throwable) {
            }
        }

        if ($isMinor) {
            // Notify guardian (guardian phone is the contact point; in-app row for audit).
            NotificationService::createStatic([
                'user_id' => $athlete->user_id,
                'type' => 'status_update',
                'title' => 'Scout contact request (guardian review)',
                'body' => "{$request->user()->name} wants to connect: {$validated['purpose']}. Guardian approval required before chat.",
                'notifiable_type' => 'connection',
                'notifiable_id' => $connection->id,
                'action_url' => '/connection-requests',
            ]);
        } else {
            NotificationService::createStatic([
                'user_id' => $athlete->user_id,
                'type' => 'status_update',
                'title' => 'New contact request',
                'body' => "{$request->user()->name}: {$validated['purpose']}",
                'notifiable_type' => 'connection',
                'notifiable_id' => $connection->id,
                'action_url' => '/connection-requests',
            ]);
        }

        return response()->json([
            'data' => [
                'connection' => $connection,
                'is_minor' => $isMinor,
                'guardian_review' => $isMinor,
            ],
        ], $connection->wasRecentlyCreated ? 201 : 200);
    }
}
