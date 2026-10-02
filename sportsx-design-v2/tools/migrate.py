#!/usr/bin/env python3
"""
SportX — restyle migration.

Applies the blended design system (assets/css/sportx.css) to every screen in
sportsx-design-v2 in place:

  1. strips the per-file inline <style> block, links the shared stylesheet
  2. loads Plus Jakarta Sans (UI Screen Spec §1.2)
  3. injects the 9:41 status bar into the phone shell (Build Spec §3.1)
  4. adds the "LET'S DEFEAT HISTORY" tagline under the wordmark
  5. re-maps every hard-coded legacy hex to the new palette

Idempotent: re-running is a no-op for already-migrated files.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Files that are not phone screens / are indexes - handled separately
SKIP = {"index.html", "index.original.html", "index.v2-simple.html", "demo.html",
        "admin-web-layout.html"}

STATUSBAR = (
    '<div class="statusbar"><span class="sb-time">9:41</span>'
    '<span class="sb-right"><i data-lucide="signal"></i>'
    '<i data-lucide="wifi"></i><i data-lucide="battery-full"></i></span></div>'
)

FONTS = ('<link rel="preconnect" href="https://fonts.googleapis.com">'
         '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>'
         '<link href="https://fonts.googleapis.com/css2?'
         'family=Plus+Jakarta+Sans:wght@400;500;600;700;800&'
         'family=Sora:wght@500;600;700;800&display=swap" rel="stylesheet">')

# --------------------------------------------------------------------------
# Legacy palette -> blended palette (UI Screen Spec §1.1)
# --------------------------------------------------------------------------
COLOR_MAP = {
    # ink / navy scale
    "#111111": "#0F1B3D", "#111": "#0F1B3D", "#111827": "#0F1B3D",
    "#2B2B2B": "#1B2A52", "#161300": "#0F1B3D", "#191300": "#0F1B3D",
    # slate text
    "#6B7280": "#5B6785", "#9CA3AF": "#8A93AD", "#C9CDD3": "#B7BFD2",
    "#A7ACB5": "#A7AFBF",
    # neutrals
    "#101114": "#0B0F1E", "#0E0F12": "#0B0F1E", "#0B0C0F": "#0B0F1E",
    "#0C0D10": "#0B0F1E", "#14161A": "#10182E", "#17191D": "#182443",
    "#191B20": "#182443", "#26282E": "#26304F",
    "#E8EAED": "#E7EBF5", "#EFF1F4": "#EFF2F9", "#F1F3F5": "#F1F4FB",
    "#EDEFF2": "#E6EAF2", "#E9EBEF": "#E4E8F2", "#ECEEF1": "#E9EDF5",
    "#F4F5F7": "#F6F8FD", "#F5F7FA": "#F1F4FB", "#FAFBFC": "#FAFBFE",
    "#F8F9FA": "#F8FAFE",
    # gold
    "#FFC107": "#FFC72C", "#F5B400": "#F2B705", "#FFD54A": "#FFDA6B",
    "#F0AD00": "#E8AE00", "#8A6D00": "#8A6D00",
    "#FFF6DA": "#FFF8E5", "#FFF9E6": "#FFEFB8", "#FFFCF0": "#FFF8E5",
    "#F0E3B2": "#F7E3A6",
    # green
    "#22C55E": "#22A559", "#2BD56B": "#35C77E", "#16A34A": "#22A559",
    "#03B94C": "#22A559", "#059669": "#22A559", "#DCFCE7": "#E4F6EC",
    # red
    "#EF4444": "#E5334B", "#FEE2E2": "#FFE9EC",
    # blue
    "#3B82F6": "#1E6CF0", "#E3EFFF": "#E8F0FF",
    # purple / pink / orange
    "#8A6AEA": "#7B3FE4", "#ECE9FF": "#F0E9FE", "#6D4DE0": "#7B3FE4",
    "#F24C96": "#F43F5E", "#FB802E": "#F59E0B", "#FE9710": "#F59E0B",
}
# longest first so 6-digit wins over 3-digit
COLOR_KEYS = sorted(COLOR_MAP, key=len, reverse=True)

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fix_encoding import repair as repair_encoding


def migrate_colors(text):
    def sub(m):
        raw = m.group(0)
        up = raw.upper()
        return COLOR_MAP.get(up, raw)
    return re.sub(r'#(?:[0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})\b', sub, text)


def rel_prefix(path):
    depth = os.path.relpath(path, ROOT).count(os.sep)
    return "../" * depth


def process(path):
    src = open(path, encoding="utf-8").read()
    orig = src
    rel = rel_prefix(path)

    # 1 ── drop inline <style>, link the shared sheet
    if "<style>" in src:
        src = re.sub(r'<style>.*?</style>\s*', "", src, flags=re.S)
        src = src.replace(
            "</head>",
            f'<link rel="stylesheet" href="{rel}assets/css/sportx.css"></head>', 1)

    # 2 ── fonts
    if "Plus+Jakarta+Sans" not in src:
        src = re.sub(r'<link rel="preconnect" href="https://fonts\.googleapis\.com">.*?rel="stylesheet">',
                     FONTS, src, count=1, flags=re.S)

    # 3 ── status bar
    if 'class="statusbar"' not in src:
        src = re.sub(r'(<div class="phone"[^>]*>)',
                     r"\1\n" + STATUSBAR, src, count=1)

    # 4 ── tagline under the wordmark (UI Screen Spec §1.2)
    src = re.sub(
        r'(<div class="topbar">\s*)(<div class="brand">.*?</div>)',
        r'\1<div class="brand-wrap">\2<div class="brand-tagline">'
        r"Let&#39;s Defeat History</div></div>",
        src, count=1, flags=re.S)

    # 5 ── palette + text encoding
    src = migrate_colors(src)
    src = repair_encoding(src)
    src = src.replace('font-family="Sora"', 'font-family="Plus Jakarta Sans"')

    if src != orig:
        open(path, "w", encoding="utf-8").write(src)
        return True
    return False


def main():
    changed = 0
    total = 0
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in ("assets", "new_design_doc")]
        for fn in filenames:
            if not fn.endswith(".html") or fn in SKIP:
                continue
            total += 1
            if process(os.path.join(dirpath, fn)):
                changed += 1
    print(f"migrated {changed} of {total} screens")


if __name__ == "__main__":
    main()
