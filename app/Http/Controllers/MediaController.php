<?php

namespace App\Http\Controllers;

use App\Models\MediaItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class MediaController extends Controller
{
    public function upload(Request $request)
    {
        $validated = $request->validate([
            'file' => 'required|file|max:'.(config('sportx.media.max_upload_mb', 10) * 1024),
            'owner_type' => 'nullable|string',
            'owner_id' => 'nullable|integer',
            'media_type' => 'required|in:photo,video,document',
        ]);

        $file = $request->file('file');
        $ext = strtolower($file->getClientOriginalExtension());

        // Authoritative check against the REAL content-derived MIME type (not the
        // client-supplied extension, which is trivially spoofable). guessExtension()
        // falls back to the client extension when the sniffer is unsure, so we use
        // getMimeType() directly against an allow-list per media type.
        $allowedMimes = match ($validated['media_type']) {
            'photo' => ['image/jpeg', 'image/png', 'image/webp'],
            'video' => ['video/mp4', 'video/quicktime'],
            'document' => ['application/pdf', 'image/jpeg', 'image/png'],
        };
        $allowedExts = match ($validated['media_type']) {
            'photo' => config('sportx.media.allowed_image_types', ['jpg', 'jpeg', 'png', 'webp']),
            'video' => config('sportx.media.allowed_video_types', ['mp4']),
            'document' => config('sportx.media.allowed_document_types', ['pdf', 'jpg', 'jpeg', 'png']),
        };

        abort_unless(
            in_array($file->getMimeType(), $allowedMimes) && in_array($ext, $allowedExts),
            422,
            'File type not allowed for '.$validated['media_type']
        );

        // Ownership: prefer an explicit owner, otherwise infer from the authenticated
        // athlete profile so mobile clients can upload without knowing their profile id.
        $ownerType = $validated['owner_type'] ?? null;
        $ownerId = $validated['owner_id'] ?? null;
        if (! $ownerType || ! $ownerId) {
            $profile = $request->user()->athleteProfile;
            abort_unless($profile, 422, 'No owner specified and no athlete profile found for this user');
            $ownerType = 'athlete_profile';
            $ownerId = $profile->id;
        }

        $path = $file->store("media/{$ownerType}/{$ownerId}", 'public');

        $media = MediaItem::create([
            'owner_type' => $ownerType,
            'owner_id' => $ownerId,
            'media_type' => $validated['media_type'],
            'disk' => 'public',
            'path' => $path,
            'original_name' => $file->getClientOriginalName(),
            'mime_type' => $file->getMimeType(),
            'size_bytes' => $file->getSize(),
        ]);

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

        $allowed = match ($media->owner_type) {
            'athlete_profile' => $request->user()->athleteProfile?->id === $media->owner_id,
            default => false,
        };

        abort_unless($allowed || $request->user()->isAdmin(), 403);

        Storage::disk($media->disk)->delete($media->path);
        $media->delete();

        return response()->json(['data' => ['message' => 'Deleted']]);
    }

    public function reorder(Request $request)
    {
        $validated = $request->validate([
            'items' => 'required|array',
            'items.*.id' => 'required|exists:media_items,id',
            'items.*.sort_order' => 'required|integer|min:0',
        ]);

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
}
