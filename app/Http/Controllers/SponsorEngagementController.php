<?php

namespace App\Http\Controllers;

use App\Models\AthleteProfile;
use App\Models\ShortlistEntry;
use App\Models\Sponsorship;
use App\Models\SponsorshipApplication;
use App\Services\ExpiryService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SponsorEngagementController extends Controller
{
    public function __construct(private ExpiryService $expiryService) {}

    // ── Sponsor: My Sponsorships ──────────────────────────────────────────────

    public function mySponsorships(Request $request)
    {
        $user = $request->user();
        $sponsor = $user->sponsorProfile;
        abort_unless($sponsor, 403);

        $sponsorships = Sponsorship::where('sponsor_id', $sponsor->id)
            ->with(['sport', 'logo'])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'data' => $sponsorships->items(),
            'meta' => ['pagination' => [
                'total' => $sponsorships->total(),
                'per_page' => $sponsorships->perPage(),
                'current_page' => $sponsorships->currentPage(),
                'last_page' => $sponsorships->lastPage(),
            ]],
        ]);
    }

    public function storeSponsorship(Request $request)
    {
        $user = $request->user();
        $sponsor = $user->sponsorProfile;
        abort_unless($sponsor, 403);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'sport_id' => 'required|integer|exists:sports,id',
            'eligibility_criteria' => 'nullable|string',
            'deadline' => 'required|date|after:now',
            'application_link' => 'nullable|url|max:500',
            'contact_email' => 'nullable|email',
            'contact_phone' => 'nullable|string|max:20',
            'benefits_offered' => 'nullable|string',
            'amount' => 'nullable|numeric|min:0',
            'documents_required' => 'nullable|array',
            'documents_required.*' => 'string',
            'description' => 'nullable|string',
            'logo_media_id' => 'nullable|integer|exists:media_items,id',
            'status' => 'nullable|in:draft,published,closed',
        ]);

        $sponsorship = Sponsorship::create(array_merge($validated, [
            'sponsor_id' => $sponsor->id,
            'organization_name' => $sponsor->organization_name,
        ]));

        return response()->json(['data' => $sponsorship->load(['sport', 'logo'])], 201);
    }

    public function updateSponsorship(Request $request, Sponsorship $sponsorship)
    {
        $this->authorizeSponsorshipOwner($request, $sponsorship);

        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'sport_id' => 'sometimes|integer|exists:sports,id',
            'eligibility_criteria' => 'nullable|string',
            'deadline' => 'sometimes|date|after:now',
            'application_link' => 'nullable|url|max:500',
            'contact_email' => 'nullable|email',
            'contact_phone' => 'nullable|string|max:20',
            'benefits_offered' => 'nullable|string',
            'amount' => 'nullable|numeric|min:0',
            'documents_required' => 'nullable|array',
            'documents_required.*' => 'string',
            'description' => 'nullable|string',
            'logo_media_id' => 'nullable|integer|exists:media_items,id',
            'status' => 'nullable|in:draft,published,closed',
        ]);

        $sponsorship->update($validated);

        return response()->json(['data' => $sponsorship->load(['sport', 'logo'])]);
    }

    public function publishSponsorship(Request $request, Sponsorship $sponsorship)
    {
        $this->authorizeSponsorshipOwner($request, $sponsorship);

        $sponsorship->update(['status' => 'published']);
        $this->expiryService->onPublish($sponsorship, 'sponsorship');

        return response()->json(['data' => $sponsorship]);
    }

    public function closeSponsorship(Request $request, Sponsorship $sponsorship)
    {
        $this->authorizeSponsorshipOwner($request, $sponsorship);

        $sponsorship->update(['status' => 'closed']);

        return response()->json(['data' => $sponsorship]);
    }

    // ── Athlete: Apply for Sponsorship ────────────────────────────────────────

    public function apply(Request $request, Sponsorship $sponsorship)
    {
        abort_unless($sponsorship->status === 'published', 422, 'Sponsorship is not open for applications');
        abort_if($sponsorship->deadline->isPast(), 422, 'Application deadline has passed');

        $athlete = $request->user()->athleteProfile;
        abort_unless($athlete, 403, 'Athlete profile required');

        $validated = $request->validate([
            'pitch_note' => 'required|string|max:1000',
        ]);

        abort_if(
            SponsorshipApplication::where('sponsorship_id', $sponsorship->id)
                ->where('athlete_id', $athlete->id)->exists(),
            409, 'Already applied'
        );

        $application = SponsorshipApplication::create([
            'sponsorship_id' => $sponsorship->id,
            'athlete_id' => $athlete->id,
            'pitch_note' => $validated['pitch_note'],
            'status' => 'pending',
        ]);

        return response()->json(['data' => $application], 201);
    }

    public function myApplications(Request $request)
    {
        $athlete = $request->user()->athleteProfile;
        abort_unless($athlete, 403);

        $applications = SponsorshipApplication::with(['sponsorship.sport', 'sponsorship.logo'])
            ->where('athlete_id', $athlete->id)
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'data' => $applications->items(),
            'meta' => ['pagination' => [
                'total' => $applications->total(),
                'per_page' => $applications->perPage(),
                'current_page' => $applications->currentPage(),
                'last_page' => $applications->lastPage(),
            ]],
        ]);
    }

    // ── Sponsor: Applications Management ─────────────────────────────────────────

    public function applications(Request $request, Sponsorship $sponsorship)
    {
        $this->authorizeSponsorshipOwner($request, $sponsorship);

        $applications = SponsorshipApplication::with(['athlete.user', 'athlete.sports'])
            ->where('sponsorship_id', $sponsorship->id)
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'data' => $applications->items(),
            'meta' => ['pagination' => [
                'total' => $applications->total(),
                'per_page' => $applications->perPage(),
                'current_page' => $applications->currentPage(),
                'last_page' => $applications->lastPage(),
            ]],
        ]);
    }

    public function updateApplication(Request $request, Sponsorship $sponsorship, SponsorshipApplication $application)
    {
        $this->authorizeSponsorshipOwner($request, $sponsorship);
        abort_if($application->sponsorship_id !== $sponsorship->id, 403);

        $validated = $request->validate([
            'status' => 'required|in:pending,reviewed,shortlisted,rejected',
        ]);

        $application->update(array_merge($validated, ['replied_at' => now()]));

        return response()->json(['data' => $application->load(['athlete.user'])]);
    }

    // ── Sponsor: Shortlist ─────────────────────────────────────────────────────

    public function shortlist(Request $request)
    {
        $user = $request->user();
        $sponsor = $user->sponsorProfile;
        abort_unless($sponsor, 403);

        $entries = ShortlistEntry::with(['athlete.user', 'athlete.sports'])
            ->where('sponsor_id', $sponsor->id)
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'data' => $entries->items(),
            'meta' => ['pagination' => [
                'total' => $entries->total(),
                'per_page' => $entries->perPage(),
                'current_page' => $entries->currentPage(),
                'last_page' => $entries->lastPage(),
            ]],
        ]);
    }

    public function addToShortlist(Request $request)
    {
        $user = $request->user();
        $sponsor = $user->sponsorProfile;
        abort_unless($sponsor, 403);

        $validated = $request->validate([
            'athlete_id' => 'required|integer|exists:athlete_profiles,id',
            'note' => 'nullable|string|max:500',
        ]);

        $entry = ShortlistEntry::firstOrCreate(
            ['sponsor_id' => $sponsor->id, 'athlete_id' => $validated['athlete_id']],
            ['note' => $validated['note'] ?? null]
        );

        return response()->json(['data' => $entry->load(['athlete.user'])], 201);
    }

    public function removeFromShortlist(Request $request, ShortlistEntry $entry)
    {
        $user = $request->user();
        $sponsor = $user->sponsorProfile;
        abort_unless($sponsor && $entry->sponsor_id === $sponsor->id, 403);

        $entry->delete();

        return response()->json(['data' => ['message' => 'Removed from shortlist']]);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private function authorizeSponsorshipOwner(Request $request, Sponsorship $sponsorship): void
    {
        $user = $request->user();
        abort_unless($sponsorship->sponsor_id === $user->sponsorProfile?->id || $user->isAdmin(), 403);
    }
}
