<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EnquiryMessage extends Model
{
    protected $fillable = ['enquiry_id', 'sender_user_id', 'body', 'read_at'];

    protected $casts = ['read_at' => 'datetime'];

    protected $appends = ['sender_photo_url', 'sender_name'];

    public function getSenderPhotoUrlAttribute(): ?string
    {
        return $this->sender?->profile_photo_url;
    }

    public function getSenderNameAttribute(): ?string
    {
        return $this->sender?->name;
    }

    public function enquiry(): BelongsTo
    {
        return $this->belongsTo(Enquiry::class);
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_user_id');
    }
}
