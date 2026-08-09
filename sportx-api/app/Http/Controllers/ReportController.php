<?php

namespace App\Http\Controllers;

use App\Models\ListingReport;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'reportable_type' => 'required|string|in:academy,coach_profile,trial,tournament,scholarship,sponsorship,sports_venue,athlete_profile',
            'reportable_id' => 'required|integer',
            'reason' => 'required|in:fake,outdated,inappropriate,other',
            'comment' => 'nullable|string|max:1000',
        ]);

        $report = ListingReport::create([
            'reporter_user_id' => $request->user()->id,
            ...$validated,
        ]);

        return response()->json(['data' => ['id' => $report->id, 'status' => 'pending']], 201);
    }
}
