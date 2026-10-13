@extends('emails.layout')

@section('subject', 'Verify your SportX account')

@section('content')
    <h2 style="margin:0 0 16px;font-size:20px;font-weight:600;color:#111111;">Confirm your email address</h2>
    <p style="margin:0 0 24px;font-size:14px;line-height:1.6;color:#6b7280;">Hi {{ $name }},</p>
    <p style="margin:0 0 24px;font-size:14px;line-height:1.6;color:#6b7280;">One quick click and your SportX account is fully verified. Verified accounts can be discovered by scouts and sponsors.</p>
    <p style="margin:0 0 32px;text-align:center;">
        <a href="{{ $verifyUrl }}" style="display:inline-block;padding:14px 32px;background-color:#1677ff;color:#ffffff;font-size:14px;font-weight:600;text-decoration:none;border-radius:8px;">Verify Email</a>
    </p>
    <p style="margin:0 0 16px;font-size:13px;color:#6b7280;">Or copy and paste this link into your browser:</p>
    <p style="margin:0;font-size:12px;word-break:break-all;color:#1677ff;">{{ $verifyUrl }}</p>
    <div style="margin-top:24px;padding:16px;background-color:#fef3c7;border-radius:8px;">
        <p style="margin:0;font-size:13px;color:#92400e;">If you didn't create a SportX account, you can safely ignore this email.</p>
    </div>
@endsection