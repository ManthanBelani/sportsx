@extends('emails.layout', ['accent' => '#16a34a', 'accentDark' => '#15803d'])

@section('subject', 'Your SportX account is approved')

@section('content')
    <h2 style="margin:0 0 16px;font-size:20px;font-weight:600;color:#111111;">Good news, {{ $name }}!</h2>
    <p style="margin:0 0 24px;font-size:14px;line-height:1.6;color:#6b7280;">Your SportX {{ $role }} registration has been reviewed and approved. Your profile is now visible to athletes, scouts and sponsors.</p>

    <p style="margin:0 0 32px;text-align:center;">
        <a href="{{ $appUrl }}" style="display:inline-block;padding:14px 32px;background-color:#16a34a;color:#ffffff;font-size:14px;font-weight:600;text-decoration:none;border-radius:8px;">Complete your profile</a>
    </p>

    <div style="padding:16px;background-color:#eff6ff;border-radius:8px;">
        <p style="margin:0;font-size:13px;line-height:1.6;color:#1e40af;">A complete profile with photos, sport categories and certifications gets roughly 4x more views from scouts.</p>
    </div>
@endsection