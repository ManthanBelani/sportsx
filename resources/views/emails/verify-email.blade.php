<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Verify your email</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f7f8fa;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f7f8fa;padding:40px 20px;">
        <tr>
            <td align="center">
                <table width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
                    <!-- Header -->
                    <tr>
                        <td style="background:linear-gradient(135deg,#1677ff,#0d47a1);padding:32px;text-align:center;">
                            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:700;">SportX India</h1>
                        </td>
                    </tr>
                    <!-- Content -->
                    <tr>
                        <td style="padding:32px;">
                            <h2 style="margin:0 0 16px;font-size:20px;font-weight:600;color:#111111;">Verify your email address</h2>
                            <p style="margin:0 0 24px;font-size:14px;line-height:1.6;color:#6b7280;">Hi {{ $name }},</p>
                            <p style="margin:0 0 24px;font-size:14px;line-height:1.6;color:#6b7280;">Thanks for joining SportX India! Please click the button below to verify your email address and activate your account.</p>
                            <p style="margin:0 0 32px;text-align:center;">
                                <a href="{{ $verifyUrl }}" style="display:inline-block;padding:14px 32px;background-color:#1677ff;color:#ffffff;font-size:14px;font-weight:600;text-decoration:none;border-radius:8px;">Verify Email Address</a>
                            </p>
                            <p style="margin:0 0 16px;font-size:13px;color:#6b7280;">Or copy and paste this link into your browser:</p>
                            <p style="margin:0;font-size:12px;word-break:break-all;color:#1677ff;">{{ $verifyUrl }}</p>
                        </td>
                    </tr>
                    <!-- Footer -->
                    <tr>
                        <td style="padding:24px 32px;background-color:#f7f8fa;border-top:1px solid #e5e7eb;">
                            <p style="margin:0 0 8px;font-size:12px;color:#6b7280;text-align:center;">If you didn't create an account with SportX, you can ignore this email.</p>
                            <p style="margin:0;font-size:12px;color:#6b7280;text-align:center;">© 2026 SportX India. All rights reserved.</p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
