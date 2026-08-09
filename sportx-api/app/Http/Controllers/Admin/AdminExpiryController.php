<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\ExpiryRule;
use App\Models\ExpiryEvent;
use App\Models\Academy;
use App\Models\CoachProfile;
use App\Models\Trial;
use App\Models\Tournament;
use App\Models\Sponsorship;
use Carbon\Carbon;

class AdminExpiryController extends Controller
{
    public function getRules(): JsonResponse
    {
        $rules = ExpiryRule::all();

        return response()->json([
            'data' => $rules
        ]);
    }

    public function updateRules(Request $request): JsonResponse
    {
        $request->validate([
            'rules' => 'required|array',
            'rules.*.content_type' => 'required|string',
            'rules.*.duration_days' => 'required|integer|min:1',
            'rules.*.action' => 'required|in:expire,notify',
        ]);

        foreach ($request->rules as $ruleData) {
            ExpiryRule::updateOrCreate(
                ['content_type' => $ruleData['content_type']],
                [
                    'duration_days' => $ruleData['duration_days'],
                    'action' => $ruleData['action'],
                ]
            );
        }

        return response()->json([
            'data' => [
                'message' => 'Expiry rules updated.',
                'rules' => ExpiryRule::all(),
            ]
        ]);
    }

    public function monitor(Request $request): JsonResponse
    {
        $tab = $request->get('tab', 'pending'); // pending, expired, overridden

        $query = ExpiryEvent::with('content');

        switch ($tab) {
            case 'expired':
                $query->where('status', 'expired');
                break;
            case 'overridden':
                $query->where('status', 'overridden');
                break;
            default: // pending
                $query->where('status', 'pending');
        }

        $query->orderBy('scheduled_at', 'asc');

        $perPage = min($request->get('per_page', 20), 50);
        $events = $query->paginate($perPage);

        return response()->json([
            'data' => $events->items(),
            'meta' => [
                'current_page' => $events->currentPage(),
                'per_page' => $events->perPage(),
                'total' => $events->total(),
                'last_page' => $events->lastPage(),
            ]
        ]);
    }

    public function override(int $id): JsonResponse
    {
        $event = ExpiryEvent::find($id);

        if (!$event) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Expiry event not found.',
                ]
            ], 404);
        }

        // Update event status
        $event->update(['status' => 'overridden']);

        // Restore the listing
        $event->content->update(['status' => 'published']);

        return response()->json([
            'data' => [
                'message' => 'Expiry overridden. Listing restored.',
            ]
        ]);
    }

    public function restore(int $id): JsonResponse
    {
        $event = ExpiryEvent::find($id);

        if (!$event) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Expiry event not found.',
                ]
            ], 404);
        }

        // Update event status
        $event->update(['status' => 'overridden']);

        // Restore the listing
        $event->content->update(['status' => 'published']);

        return response()->json([
            'data' => [
                'message' => 'Listing restored.',
            ]
        ]);
    }
}
