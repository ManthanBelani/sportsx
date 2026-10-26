<?php

namespace App\Http\Controllers;

use App\Jobs\CompressPhoto;
use App\Models\MediaItem;
use App\Support\PlatformSettings;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;

class MediaController extends Controller
{
    /**
     * owner_type → profile table, used to maintain gallery_photo_count.
     */
    private const PROFILE_TABLES = [
        'athlete_profile' => 'athlete_profiles',
        'coach_profile' => 'coach_profiles',
        'academy' => 'academies',
        'organizer_profile' => 'organizer_profiles',
        'sponsor_profile' => 'sponsor_profiles',
        'talent_scout_profile' => 'talent_scout_profiles',
    ];

    /**
     * Resolves the caller's profile row [type, id, table] used as the gallery
     * owner; null when the user has no profile yet (uploads then fall back to
     * the user row and are not counter-tracked).
     */
    private static function resolveProfile($user): ?array
    {
        $resolved = match ($user->role) {
            'athlete' => $user->athleteProfile ? ['athlete_profile', $user->athleteProfile->id] : null,
            'coach' => $user->coachProfile ? ['coach_profile', $user->coachProfile->id] : null,
            'academy' => $user->academies ? ['academy', $user->academies->id] : null,
            'organizer' => $user->organizerProfile ? ['organizer_profile', $user->organizerProfile->id] : null,
            'sponsor' => $user->sponsorProfile ? ['sponsor_profile', $user->sponsorProfile->id] : null,
            'talent_scout' => $user->talentScoutProfile ? ['talent_scout_profile', $user->talentScoutProfile->id] : null,
            default => null,
        };

        if (! $resolved) {
            return null;
        }

        $table = self::PROFILE_TABLES[$resolved[0]] ?? null;

        return $table ? [$resolved[0], $resolved[1], $table] : null;
    }

    /** Current gallery-photo usage [used, limit] for the caller's role. */
    private static function galleryQuota($user): array
    {
        $profile = self::resolveProfile($user);

        // Maintained counter when a profile owns the gallery; otherwise (no
        // profile yet — onboarding fallback) recount the real rows so quota
        // still holds from day one.
        if ($profile) {
            $used = (int) (DB::table($profile[2])->where('id', $profile[1])->value('gallery_photo_count') ?? 0);
        } else {
            $used = (int) MediaItem::where('owner_type', 'user')
                ->where('owner_id', $user->id)
                ->where('media_type', 'photo')
                ->where('context', 'gallery')
                ->count();
        }

        return [$used, PlatformSettings::galleryPhotoLimit((string) $user->role)];
    }

    /**
     * GET /me/media — the caller's own gallery, newest order first.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $owners = array_filter([
            $user->athleteProfile ? ['athlete_profile', $user->athleteProfile->id] : null,
            $user->coachProfile ? ['coach_profile', $user->coachProfile->id] : null,
            $user->academies ? ['academy', $user->academies->id] : null,
            $user->organizerProfile ? ['organizer_profile', $user->organizerProfile->id] : null,
            $user->sponsorProfile ? ['sponsor_profile', $user->sponsorProfile->id] : null,
            $user->talentScoutProfile ? ['talent_scout_profile', $user->talentScoutProfile->id] : null,
            ['user', $user->id],
        ]);

        $query = MediaItem::query()->orderBy('sort_order')->latest('id');
        $query->where(function ($q) use ($owners) {
            foreach (array_values($owners) as $i => [$type, $id]) {
                if ($i === 0) {
                    $q->where(fn ($w) => $w->where('owner_type', $type)->where('owner_id', $id));
                } else {
                    $q->orWhere(fn ($w) => $w->where('owner_type', $type)->where('owner_id', $id));
                }
            }
        });

        $page = $query->paginate(min((int) ($request->per_page ?? 24), 50));

        return response()->json([
            'data' => $page,
            'photo_quota' => $request->has('with_quota') ? self::quotaPayloadFor($user) : null,
        ]);
    }

    /**
     * GET /me/media/quota — dedicated endpoint so the gallery can refresh
     * usage without re-paging media.
     */
    public function quota(Request $request)
    {
        return response()->json(['data' => self::quotaPayloadFor($request->user())]);
    }

    /**
     * GEOMETRIC quota payload for the media gallery UI (Step 3F): usage for
     * the caller's role against the per-role admin limit.
     */
    public static function quotaPayloadFor($user): array
    {
        [$used, $limit] = self::galleryQuota($user);

        return [
            'used' => $used,
            'limit' => $limit,
            'remaining' => $limit >= 0 ? max(0, $limit - $used) : null,
        ];
    }

    public function upload(Request $request)
    {
        // Videos are no longer accepted platform-wide (photos only). A clear
        // message instead of a generic validation failure helps older client
        // versions surface the change.
        if (($request->input('media_type')) === 'video') {
            abort(422, 'Video uploads are no longer supported. Please upload a photo.');
        }

        $validated = $request->validate([
            'file' => 'required|file|max:'.(config('sportx.media.max_upload_mb', 10) * 1024),
            'owner_type' => 'nullable|string',
            'owner_id' => 'nullable|integer',
            'media_type' => 'required|in:photo,document',
            'context' => 'nullable|in:'.implode(',', config('sportx.media.upload_contexts')),
            'caption' => 'nullable|string|max:280',
            'sport_id' => 'nullable|exists:sports,id',
        ]);

        // Default context: gallery (counted against quota per plan Step 3E).
        $context = $validated['context'] ?? 'gallery';

        $user = $request->user();

        // Quota enforcement — runs BEFORE any file is stored (Step 3D).
        // Only context=gallery photos count; profile/cover/logo/post/
        // achievement/credential photos are always free.
        $shouldCount = $validated['media_type'] === 'photo'
            && $context === 'gallery'
            && ! $user->isAdmin();
        if ($shouldCount) {
            [$used, $limit] = self::galleryQuota($user);
            if ($used >= $limit) {
                abort(422, "Upload limit reached: {$limit} photos allowed for your role (profile & cover photos are free).");
            }
        }

        $file = $request->file('file');
        $ext = strtolower($file->getClientOriginalExtension());

        // Authoritative check against the REAL content-derived MIME type (not the
        // client-supplied extension, which is trivially spoofable). guessExtension()
        // falls back to the client extension when the sniffer is unsure, so we use
        // getMimeType() directly against an allow-list per media type.
        $allowedMimes = match ($validated['media_type']) {
            'photo' => ['image/jpeg', 'image/png', 'image/webp'],
            'document' => ['application/pdf', 'image/jpeg', 'image/png'],
        };
        $allowedExts = match ($validated['media_type']) {
            'photo' => config('sportx.media.allowed_image_types', ['jpg', 'jpeg', 'png', 'webp']),
            'document' => config('sportx.media.allowed_document_types', ['pdf', 'jpg', 'jpeg', 'png']),
        };

        abort_unless(
            in_array($file->getMimeType(), $allowedMimes) && in_array($ext, $allowedExts),
            422,
            'File type not allowed for '.$validated['media_type']
        );

        // Ownership: prefer an explicit owner, otherwise infer from the authenticated
        // user's role so every role (athlete, coach, academy, organizer, sponsor,
        // talent_scout) can upload without knowing their profile id. Falls back to
        // the user itself when no profile exists yet (e.g. onboarding).
        $ownerType = $validated['owner_type'] ?? null;
        $ownerId = $validated['owner_id'] ?? null;
        if (! $ownerType || ! $ownerId) {
            $profile = self::resolveProfile($user);
            if ($profile) {
                [$ownerType, $ownerId] = [$profile[0], $profile[1]];
            } else {
                // No profile yet (onboarding) or admin — store under the user itself
                // so the upload still succeeds and can be linked later via photo_media_id.
                $ownerType = 'user';
                $ownerId = $user->id;
            }
        }

        $path = $file->store("media/{$ownerType}/{$ownerId}", 'public');

        $attributes = [
            'owner_type' => $ownerType,
            'owner_id' => $ownerId,
            'media_type' => $validated['media_type'],
            'disk' => 'public',
            'path' => $path,
            'original_name' => $file->getClientOriginalName(),
            'mime_type' => $file->getMimeType(),
            'size_bytes' => $file->getSize(),
        ];

        // Caption + sport tag arrive with the Phase-2 migration; accept them
        // now, persist only when the columns exist.
        if (isset($validated['caption']) && Schema::hasColumn('media_items', 'caption')) {
            $attributes['caption'] = $validated['caption'];
        }
        if (isset($validated['sport_id']) && Schema::hasColumn('media_items', 'sport_id')) {
            $attributes['sport_id'] = $validated['sport_id'];
        }

        // Context tagging (Step 3E).
        if (Schema::hasColumn('media_items', 'context')) {
            $attributes['context'] = $context;
        }

        $media = DB::transaction(function () use ($attributes, $shouldCount, $ownerType, $ownerId) {
            $media = MediaItem::create($attributes);

            // Counter maintenance (Step 3C) — inside the same transaction as
            // the insert so concurrent uploads can never overshoot the limit.
            if ($shouldCount && ($table = self::PROFILE_TABLES[$ownerType] ?? null)) {
                DB::table($table)->where('id', $ownerId)->increment('gallery_photo_count');
            }

            return $media;
        });

        // Server-side compression runs off the request (Step 2C / 2D). With
        // the database queue the job drains via queue:listen / Horizon.
        CompressPhoto::dispatch($media->id);

        return response()->json([
            'data' => [
                'id' => $media->id,
                'url' => $media->url(),
                'media_type' => $media->media_type,
            ],
        ], 201);
    }

    public function destroy(Request $request, string $id)
    {
        $media = MediaItem::findOrFail($id);

        $user = $request->user();
        $allowed = match ($media->owner_type) {
            'athlete_profile' => $user->athleteProfile?->id === $media->owner_id,
            'coach_profile' => $user->coachProfile?->id === $media->owner_id,
            'academy' => $user->academies?->id === $media->owner_id,
            'organizer_profile' => $user->organizerProfile?->id === $media->owner_id,
            'sponsor_profile' => $user->sponsorProfile?->id === $media->owner_id,
            'talent_scout_profile' => $user->talentScoutProfile?->id === $media->owner_id,
            'user' => $user->id === $media->owner_id,
            default => false,
        };

        abort_unless($allowed || $user->isAdmin(), 403);

        // Freed quota: deleting a gallery photo releases the counter slot
        // (Step 3C). Profile/cover etc. photos never consumed quota.
        DB::transaction(function () use ($media) {
            if ($media->media_type === 'photo'
                && $media->context === 'gallery'
                && ($table = self::PROFILE_TABLES[$media->owner_type] ?? null)) {
                DB::table($table)->where('id', $media->owner_id)
                    ->where('gallery_photo_count', '>', 0)
                    ->decrement('gallery_photo_count');
            }

            Storage::disk($media->disk)->delete($media->path);
            $media->delete();
        });

        return response()->json(['data' => ['message' => 'Deleted']]);
    }

    public function reorder(Request $request)
    {
        $validated = $request->validate([
            'items' => 'required|array',
            'items.*.id' => 'required|exists:media_items,id',
            'items.*.sort_order' => 'required|integer|min:0',
        ]);

        $user = $request->user();
        $ids = collect($validated['items'])->pluck('id')->all();
        $owned = MediaItem::whereIn('id', $ids)->get();
        abort_if($owned->count() !== count($ids), 404);
        foreach ($owned as $media) {
            $allowed = match ($media->owner_type) {
                'athlete_profile' => $user->athleteProfile?->id === $media->owner_id,
                'coach_profile' => $user->coachProfile?->id === $media->owner_id,
                'academy' => $user->academies?->id === $media->owner_id,
                'organizer_profile' => $user->organizerProfile?->id === $media->owner_id,
                'sponsor_profile' => $user->sponsorProfile?->id === $media->owner_id,
                'talent_scout_profile' => $user->talentScoutProfile?->id === $media->owner_id,
                'user' => $user->id === $media->owner_id,
                default => false,
            };
            abort_unless($allowed || $user->isAdmin(), 403);
        }

        foreach ($validated['items'] as $item) {
            MediaItem::where('id', $item['id'])->update(['sort_order' => $item['sort_order']]);
        }

        return response()->json(['data' => ['message' => 'Reordered']]);
    }

    public function download(Request $request, string $id)
    {
        if (! $request->hasValidSignature()) {
            abort(401, 'Invalid or expired URL.');
        }

        $media = MediaItem::findOrFail($id);
        return Storage::disk($media->disk)->download($media->path, $media->original_name);
    }

    public function signedUrl(Request $request, string $id)
    {
        $media = MediaItem::findOrFail($id);
        $user = $request->user();
        $allowed = match ($media->owner_type) {
            'athlete_profile' => $user->athleteProfile?->id === $media->owner_id,
            'coach_profile' => $user->coachProfile?->id === $media->owner_id,
            'academy' => $user->academies?->id === $media->owner_id,
            'organizer_profile' => $user->organizerProfile?->id === $media->owner_id,
            'sponsor_profile' => $user->sponsorProfile?->id === $media->owner_id,
            'talent_scout_profile' => $user->talentScoutProfile?->id === $media->owner_id,
            'user' => $user->id === $media->owner_id,
            default => false,
        };
        abort_unless($allowed || $user->isAdmin(), 403);
        // Phase 10: 60-minute signed URLs for private docs (was 15).
        $url = \Illuminate\Support\Facades\URL::temporarySignedRoute('media.download', now()->addMinutes(60), ['id' => $media->id]);
        return response()->json(['data' => ['url' => $url, 'expires_at' => now()->addMinutes(60)->toISOString()]]);
    }
}

