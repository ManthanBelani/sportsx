@extends('emails.layout', ['footerNote' => 'You are receiving this because push notifications are unavailable on your device.'])

@section('subject', $title)

@section('content')
    <h2 style="margin:0 0 16px;font-size:20px;font-weight:600;color:#111111;">{{ $title }}</h2>
    <p style="margin:0 0 24px;font-size:14px;line-height:1.6;color:#6b7280;">{{ $body }}</p>

    <p style="margin:0 0 8px;text-align:center;">
        <a href="{{ $actionUrl }}" style="display:inline-block;padding:14px 32px;background-color:#1677ff;color:#ffffff;font-size:14px;font-weight:600;text-decoration:none;border-radius:8px;">Open in SportX</a>
    </p>

    <div style="margin-top:24px;padding:16px;background-color:#eff6ff;border-radius:8px;">
        <p style="margin:0;font-size:13px;line-height:1.6;color:#1e40af;">To stop receiving these by email, open SportX → Settings → Notifications and switch off the matching category.</p>
    </div>
@endsection