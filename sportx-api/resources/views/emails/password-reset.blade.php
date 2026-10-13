@extends('emails.layout')

@section('subject', 'Reset your password')

@section('content')
    <h2 style="margin:0 0 16px;font-size:20px;font-weight:600;color:#111111;">Reset your password</h2>
    <p style="margin:0 0 24px;font-size:14px;line-height:1.6;color:#6b7280;">Hi {{ $name }},</p>
    <p style="margin:0 0 24px;font-size:14px;line-height:1.6;color:#6b7280;">We received a request to reset your password. Click the button below to set a new password. This link will expire in 60 minutes.</p>
    <p style="margin:0 0 32px;text-align:center;">
        <a href="{{ $resetUrl }}" style="display:inline-block;padding:14px 32px;background-color:#1677ff;color:#ffffff;font-size:14px;font-weight:600;text-decoration:none;border-radius:8px;">Reset Password</a>
    </p>
    <p style="margin:0 0 16px;font-size:13px;color:#6b7280;">Or copy and paste this link into your browser:</p>
    <p style="margin:0;font-size:12px;word-break:break-all;color:#1677ff;">{{ $resetUrl }}</p>
    <div style="margin-top:24px;padding:16px;background-color:#fef3c7;border-radius:8px;">
        <p style="margin:0;font-size:13px;color:#92400e;">If you didn't request a password reset, you can safely ignore this email. Your password won't change.</p>
    </div>
@endsection