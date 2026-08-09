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

        return response()->json(['data' => [
            'enquiries_sent' => Enquiry::where('sender_id', $user->id)->count(),
            'enquiries_received' => Enquiry::where('receiver_id', $user->id)->count(),
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
        $key = "recent_searches:{$user->id}";
        $searches = Cache::get($key, []);

        return array_slice($searches, 0, 10);
    }
}
