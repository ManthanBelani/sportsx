<?php

namespace App\Http\Controllers;

use App\Models\Trial;
use App\Services\ExpiryService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProviderTrialController extends Controller
{
    public function __construct(private ExpiryService $expiryService) {}

    public function index(Request $request)
    {
        $user = $request->user();

        $trials = Trial::where('posted_by_user_id', $user->id)
            ->with(['city', 'sport'])
            ->orderBy('event_datetime', 'desc')
            ->paginate(20);

        return response()->json([
            'data' => $trials->items(),
            'meta' => ['pagination' => [
                'total' => $trials->total(),
                'per_page' => $trials->perPage(),
                'current_page' => $trials->currentPage(),
                'last_page' => $trials->lastPage(),
            ]],
        ]);
    }

    public function store(Request $request)
    {
        $user = $request->user();
        abort_unless(in_array($user->role, ['organizer', 'academy', 'coach']), 403, 'Only providers can create trials');

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'sport_id' => 'required|integer|exists:sports,id',
            'city_id' => 'required|integer|exists:cities,id',
            'venue' => 'required|string|max:500',
            'event_datetime' => 'required|date|after:now',
            'registration_deadline' => 'nullable|date|before:event_datetime',
            'age_group_id' => 'nullable|integer|exists:age_groups,id',
            'skill_level' => 'nullable|in:beginner,intermediate,advanced,all',
            'max_participants' => 'nullable|integer|min:1',
            'fee' => 'nullable|numeric|min:0',
            'required_documents' => 'nullable|array',
            'required_documents.*' => 'string',
            'contact_name' => 'nullable|string|max:255',
            'contact_phone' => 'nullable|string|max:20',
            'contact_email' => 'nullable|email',
            'listing_status' => 'nullable|in:draft,published,closed',
        ]);

        $trial = Trial::create(array_merge($validated, [
            'posted_by_user_id' => $user->id,
            'registration_deadline' => $validated['registration_deadline'] ?? null,
            'required_documents' => $validated['required_documents'] ?? [],
        ]));

        return response()->json(['data' => $trial->load(['city', 'sport'])], 201);
    }

    public function update(Request $request, Trial $trial)
    {
        $this->authorizeOwner($request, $trial);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'sport_id' => 'sometimes|integer|exists:sports,id',
            'city_id' => 'sometimes|integer|exists:cities,id',
            'venue' => 'sometimes|string|max:500',
            'event_datetime' => 'sometimes|date|after:now',
            'registration_deadline' => 'nullable|date|before:event_datetime',
            'age_group_id' => 'nullable|integer|exists:age_groups,id',
            'skill_level' => 'nullable|in:beginner,intermediate,advanced,all',
            'max_participants' => 'nullable|integer|min:1',
            'fee' => 'nullable|numeric|min:0',
            'required_documents' => 'nullable|array',
            'required_documents.*' => 'string',
            'contact_name' => 'nullable|string|max:255',
            'contact_phone' => 'nullable|string|max:20',
            'contact_email' => 'nullable|email',
            'listing_status' => 'nullable|in:draft,published,closed',
        ]);

        $trial->update($validated);

        return response()->json(['data' => $trial->load(['city', 'sport'])]);
    }

    public function publish(Request $request, Trial $trial)
    {
        $this->authorizeOwner($request, $trial);

        $trial->update(['listing_status' => 'published']);
        $this->expiryService->onPublish($trial, 'trial');

        return response()->json(['data' => $trial]);
    }

    public function close(Request $request, Trial $trial)
    {
        $this->authorizeOwner($request, $trial);

        $trial->update(['listing_status' => 'closed']);

        return response()->json(['data' => $trial]);
    }

    private function authorizeOwner(Request $request, Trial $trial): void
    {
        $user = $request->user();
        abort_unless($trial->posted_by_user_id === $user->id || $user->isAdmin(), 403);
    }
}
