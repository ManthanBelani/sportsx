<?php

namespace App\Http\Controllers;

use App\Models\Academy;
use App\Models\CoachProfile;
use App\Models\Scholarship;
use App\Models\SavedItem;
use App\Models\Sponsorship;
use App\Models\SportsVenue;
use App\Models\Trial;
use App\Models\Tournament;
use Illuminate\Http\Request;

class SavedItemController extends Controller
{
    public function index(Request $request)
    {
        $query = SavedItem::where('user_id', $request->user()->id);

        $query->when($request->item_type, fn ($q2) => $q2->where('item_type', $request->item_type));

        $items = $query->latest()->paginate(min((int) ($request->per_page ?? 20), 50))->withQueryString();

        $items->getCollection()->transform(fn ($item) => $this->enrich($item));

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

        return response()->json(['data' => $this->enrich($saved)], 201);
    }

    public function destroy(Request $request)
    {
        $request->validate([
            'item_type' => 'required|string',
            'item_id' => 'required|integer',
        ]);

        SavedItem::where('user_id', $request->user()->id)
            ->where('item_type', $request['item_type'])
            ->where('item_id', $request['item_id'])
            ->delete();

        return response()->json(['data' => ['message' => 'Unsaved']]);
    }

    /**
     * Attach display fields (title, subtitle, meta, image) resolved from the
     * related model so the mobile app can render the Saved list.
     */
    private function enrich(SavedItem $item): array
    {
        $base = [
            'id' => $item->id,
            'item_type' => $item->item_type,
            'item_id' => $item->item_id,
            'title' => 'Untitled',
            'subtitle' => '',
            'meta' => null,
            'image_url' => null,
        ];

        $resolved = match ($item->item_type) {
            'trial' => function () use ($item) {
                $t = Trial::with('sport', 'city')->find($item->item_id);
                if (! $t) return null;
                return [
                    'title' => $t->name,
                    'subtitle' => collect([$t->sport?->name, $t->city?->name, $t->venue])->filter()->implode(' · '),
                    'meta' => $t->event_datetime?->format('d M Y'),
                ];
            },
            'tournament' => function () use ($item) {
                $t = Tournament::with('sport', 'city')->find($item->item_id);
                if (! $t) return null;
                return [
                    'title' => $t->name,
                    'subtitle' => collect([$t->sport?->name, $t->city?->name, $t->venue])->filter()->implode(' · '),
                    'meta' => $t->start_date?->format('d M Y'),
                ];
            },
            'academy' => function () use ($item) {
                $a = Academy::with('city')->find($item->item_id);
                if (! $a) return null;
                return [
                    'title' => $a->name,
                    'subtitle' => collect([$a->city?->name, $a->address])->filter()->implode(' · '),
                    'meta' => $a->fee_range,
                ];
            },
            'coach_profile' => function () use ($item) {
                $c = CoachProfile::with('sport', 'city')->find($item->item_id);
                if (! $c) return null;
                return [
                    'title' => $c->full_name,
                    'subtitle' => collect([$c->sport?->name, $c->city?->name])->filter()->implode(' · '),
                    'meta' => $c->fee_structure,
                ];
            },
            'scholarship' => function () use ($item) {
                $s = Scholarship::with('sport')->find($item->item_id);
                if (! $s) return null;
                return [
                    'title' => $s->name,
                    'subtitle' => $s->organization_name,
                    'meta' => $s->amount ? '₹' . number_format((float) $s->amount) : null,
                ];
            },
            'sponsorship' => function () use ($item) {
                $s = Sponsorship::with('sport')->find($item->item_id);
                if (! $s) return null;
                return [
                    'title' => $s->title,
                    'subtitle' => $s->organization_name,
                    'meta' => $s->deadline?->format('d M Y'),
                ];
            },
            'sports_venue' => function () use ($item) {
                $v = SportsVenue::with('sport', 'city')->find($item->item_id);
                if (! $v) return null;
                return [
                    'title' => $v->name,
                    'subtitle' => collect([$v->sport?->name, $v->city?->name, $v->address])->filter()->implode(' · '),
                    'meta' => $v->pricing,
                ];
            },
            default => null,
        };

        $extra = $resolved ? $resolved() : null;

        return array_merge($base, $extra ?? []);
    }
}
