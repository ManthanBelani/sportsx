{{--
    Shared shell for every transactional SportX email.

    Table-based and inline-styled on purpose: Gmail, Outlook and Apple Mail all
    strip <style> blocks and ignore most modern CSS, so the layout has to survive
    being rendered by a 2007-era HTML engine.
--}}
@php
    $accent = $accent ?? '#1677ff';
    $accentDark = $accentDark ?? '#0d47a1';
    $footerNote = $footerNote ?? null;
@endphp
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="color-scheme" content="light">
    <title>@yield('subject', config('app.name'))</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f7f8fa;">
<table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background-color:#f7f8fa;padding:40px 20px;">
    <tr>
        <td align="center">
            <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="max-width:480px;background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
                <tr>
                    <td style="background:linear-gradient(135deg,{{ $accent }},{{ $accentDark }});padding:32px;text-align:center;">
                        <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:700;">SportX India</h1>
                    </td>
                </tr>
                <tr>
                    <td style="padding:32px;">
                        @yield('content')
                    </td>
                </tr>
                <tr>
                    <td style="padding:24px 32px;background-color:#f7f8fa;border-top:1px solid #e5e7eb;">
                        @if ($footerNote)
                            <p style="margin:0 0 8px;font-size:12px;color:#6b7280;text-align:center;">{{ $footerNote }}</p>
                        @endif
                        <p style="margin:0;font-size:12px;color:#6b7280;text-align:center;">© {{ now()->year }} SportX India. All rights reserved.</p>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>