<?php

namespace App\Http\Controllers;

use App\Models\SavedItem;
use Illuminate\Http\Request;

class SavedItemController extends Controller
{
    public function index(Request $request)
    {
        $query = SavedItem::where('user_id', $request->user()->id);

        $query->when($request->item_type, fn ($q2) => $q2->where('item_type', $request->item_type));

        $items = $query->latest()->paginate(min((int) ($request->per_page ?? 20), 50))->withQueryString();

        return response()->json($items);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'item_type' => 'required|string|in:academy,coach_profile,trial,tournament,scholarship,sponsorship,sports_venue,athlete_profile',
            'item_id' => 'required|integer',
        ]);

        $exists = SavedItem::where('user_id', $request->user()->id)
            ->where('item_type', $validated['item_type'])
            ->where('item_id', $validated['item_id'])
            ->exists();

        abort_if($exists, 409, 'Item already saved');

        $saved = SavedItem::create($validated + ['user_id' => $request->user()->id]);

        return response()->json(['data' => $saved], 201);
    }

    public function destroy(Request $request)
    {
        $request->validate([
            'item_type' => 'required|string',
            'item_id' => 'required|integer',
        ]);

        SavedItem::where('user_id', $request->user()->id)
            ->where('item_type', $request->item_type)
            ->where('item_id', $request->item_id)
            ->delete();

        return response()->json(['data' => ['message' => 'Unsaved']]);
    }
}
