@extends('emails.layout')

@section('subject', 'Your SportX verification code')

@section('content')
    <h2 style="margin:0 0 16px;font-size:20px;font-weight:600;color:#111111;">
        {{ ['login' => 'Your login code', 'verify_email' => 'Confirm your email', 'reset_password' => 'Password reset code'][$purpose] ?? 'Your verification code' }}
    </h2>
    <p style="margin:0 0 24px;font-size:14px;line-height:1.6;color:#6b7280;">Enter this code in the SportX app to continue.</p>

    <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="margin:0 0 24px;">
        <tr>
            <td align="center" style="padding:24px;background-color:#f7f8fa;border-radius:12px;border:1px dashed #d1d5db;">
                <span style="font-size:36px;font-weight:700;letter-spacing:10px;color:#111111;font-family:'SFMono-Regular',Consolas,monospace;">{{ $code }}</span>
            </td>
        </tr>
    </table>

    <p style="margin:0 0 8px;font-size:13px;color:#6b7280;">This code expires in {{ $expiresInMinutes }} minutes and can only be used once.</p>
    <div style="margin-top:16px;padding:16px;background-color:#fef3c7;border-radius:8px;">
        <p style="margin:0;font-size:13px;color:#92400e;">SportX will never ask you for this code by phone, chat or email. If you did not request it, you can ignore this message.</p>
    </div>
@endsection