<?php

namespace App\Http\Controllers;

use App\Models\Academy;
use App\Models\CoachProfile;
use App\Models\Scholarship;
use App\Models\Sponsorship;
use App\Models\SportsVenue;
use App\Models\Tournament;
use App\Models\Trial;
use App\Models\RecentSearch;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    public function search(Request $request)
    {
        $request->validate(['q' => 'required|string|max:120']);
        $q = $request->q;
        $limit = (int) ($request->per_page ?? 5);

        // Save search for logged-in user
        if ($request->user()) {
            RecentSearch::updateOrCreate(
                ['user_id' => $request->user()->id, 'query' => $q],
                ['created_at' => now()]
            );
        }

        $data = [
            'academies' => Academy::published()->where(fn ($s) => $s->where('name', 'like', "%{$q}%")->orWhere('description', 'like', "%{$q}%"))->with('city')->limit($limit)->get(),
            'coaches' => CoachProfile::where('listing_status', 'published')->where(fn ($s) => $s->where('full_name', 'like', "%{$q}%")->orWhere('bio', 'like', "%{$q}%"))->with(['sport', 'city'])->limit($limit)->get(),
            'trials' => Trial::published()->where(fn ($s) => $s->where('name', 'like', "%{$q}%")->orWhere('organization_name', 'like', "%{$q}%"))->with(['sport', 'city'])->limit($limit)->get(),
            'tournaments' => Tournament::published()->where('name', 'like', "%{$q}%")->with(['sport', 'city'])->limit($limit)->get(),
            'scholarships' => Scholarship::published()->where(fn ($s) => $s->where('name', 'like', "%{$q}%")->orWhere('organization_name', 'like', "%{$q}%"))->with('sport')->limit($limit)->get(),
            'sponsorships' => Sponsorship::published()->where(fn ($s) => $s->where('title', 'like', "%{$q}%")->orWhere('organization_name', 'like', "%{$q}%"))->with('sport')->limit($limit)->get(),
            'sports_venues' => SportsVenue::published()->where(fn ($s) => $s->where('name', 'like', "%{$q}%")->orWhere('address', 'like', "%{$q}%"))->with(['sport', 'city'])->limit($limit)->get(),
        ];

        return response()->json([
            'data' => $data,
            'meta' => ['query' => $q],
        ]);
    }

    public function recentSearches(Request $request)
    {
        $searches = RecentSearch::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->pluck('query');

        return response()->json([
            'data' => $searches
        ]);
    }
}
