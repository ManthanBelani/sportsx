<?php

namespace App\Http\Controllers;

use App\Models\AnalyticsEvent;
use Illuminate\Http\Request;

/**
 * Product analytics funnel (Phase 9): signup, registration, enquiry,
 * shortlist. Fire-and-forget from the app; never blocks the UX.
 */
class AnalyticsController extends Controller
{
    public const FUNNEL = ['signup', 'registration', 'enquiry', 'shortlist'];

    public function store(Request $request)
    {
        $validated = $request->validate([
            'event' => 'required|string|max:60',
            'props' => 'nullable|array',
        ]);

        $row = AnalyticsEvent::create([
            'user_id' => $request->user()?->id,
            'event' => strtolower($validated['event']),
            'props' => $validated['props'] ?? null,
        ]);

        return response()->json(['data' => ['id' => $row->id]], 201);
    }
}
