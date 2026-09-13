<?php

namespace App\Http\Controllers;

use App\Models\Enquiry;
use App\Models\SavedItem;
use App\Models\ShortlistEntry;
use App\Models\TrialRegistration;
use App\Models\TournamentRegistration;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class ActivityController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        // Correct schema: enquiries use athlete_id + subject_type/subject_id (morph), not sender_id/receiver_id
        $enquiriesSent = $user->athleteProfile
            ? Enquiry::where('athlete_id', $user->athleteProfile->id)->count()
            : 0;

        $enquiriesReceived = 0;
        if ($user->coachProfile) {
            $enquiriesReceived = Enquiry::where('subject_type', 'coach_profile')->where('subject_id', $user->coachProfile->id)->count();
        } elseif ($user->academies) {
            $enquiriesReceived = Enquiry::where('subject_type', 'academy')->where('subject_id', $user->academies->id)->count();
        } elseif ($user->organizerProfile) {
            $enquiriesReceived = Enquiry::where('subject_type', 'organizer_profile')->where('subject_id', $user->organizerProfile->id)->count();
        } elseif ($user->sponsorProfile) {
            $enquiriesReceived = Enquiry::where('subject_type', 'sponsor_profile')->where('subject_id', $user->sponsorProfile->id)->count();
        }

        return response()->json(['data' => [
            'enquiries_sent' => $enquiriesSent,
            'enquiries_received' => $enquiriesReceived,
            'trial_registrations' => $user->athleteProfile
                ? TrialRegistration::where('athlete_id', $user->athleteProfile->id)->count()
                : 0,
            'tournament_registrations' => $user->athleteProfile
                ? TournamentRegistration::where('athlete_id', $user->athleteProfile->id)->count()
                : 0,
            'shortlisted_athletes' => ($user->sponsorProfile && $request->boolean('for_sponsor'))
                ? ShortlistEntry::where('sponsor_id', $user->sponsorProfile->id)->count()
                : null,
            'saved_items' => SavedItem::where('user_id', $user->id)->count(),
            'recent_searches' => $this->getRecentSearches($user),
        ]]);
    }

    private function getRecentSearches($user)
    {
        // Unify with SearchController which persists to recent_searches table + short cache.
        // Prefer DB source so cache/frontend drift is not lost across devices.
        try {
            $db = \App\Models\RecentSearch::where('user_id', $user->id)->orderByDesc('updated_at')->limit(10)->pluck('query')->toArray();
            if (!empty($db)) return $db;
        } catch (\Throwable $e) {}
        $key = "recent_searches:{$user->id}";
        $searches = Cache::get($key, []);
        return array_slice($searches, 0, 10);
    }
}
