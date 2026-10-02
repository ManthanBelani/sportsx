#!/usr/bin/env python3
"""Render SportX screens to PNG for visual QA."""
import sys, os
from playwright.sync_api import sync_playwright

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, ".qa")
os.makedirs(OUT, exist_ok=True)


def shoot(paths, width=430, height=900, prefix=""):
    with sync_playwright() as p:
        b = p.chromium.launch(args=["--no-sandbox", "--font-render-hinting=none"])
        pg = b.new_page(viewport={"width": width, "height": height},
                        device_scale_factor=2)
        for rel in paths:
            f = os.path.join(ROOT, rel)
            name = (prefix + rel.replace("/", "_")).replace(".html", ".png")
            pg.goto("file://" + f)
            pg.wait_for_timeout(1400)
            pg.screenshot(path=os.path.join(OUT, name))
            print("  ok", rel)
        b.close()


if __name__ == "__main__":
    shoot(sys.argv[1:])
