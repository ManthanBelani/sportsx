#!/usr/bin/env python3
"""
SportX — full-corpus QA sweep.

Loads every screen and reports, per file:
  * JS / page errors
  * failed requests (missing stylesheet, bad asset path)
  * horizontal overflow past the phone shell
  * text that spills out of its container
"""
import os, sys, json
from playwright.sync_api import sync_playwright

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_DIRS = {"assets", "new_design_doc", "tools", ".qa", ".git"}


def collect():
    out = []
    for dp, dn, fs in os.walk(ROOT):
        dn[:] = [d for d in dn if d not in SKIP_DIRS]
        for fn in sorted(fs):
            if fn.endswith(".html"):
                out.append(os.path.relpath(os.path.join(dp, fn), ROOT))
    return sorted(out)


AUDIT = """() => {
  const shell = document.querySelector('.phone');
  const problems = [];
  const CLIPS = new Set(['auto','scroll','hidden','clip']);
  if (shell) {
    const sr = shell.getBoundingClientRect();
    const vw = document.documentElement.clientWidth;
    if (sr.width > vw + 2) problems.push('shell overflows viewport');
    for (const el of document.querySelectorAll('.phone *')) {
      const r = el.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) continue;
      if (getComputedStyle(el).position === 'fixed') continue;
      if (r.right <= sr.right + 2) continue;
      // only a real problem if no ancestor between el and the shell clips it
      let p = el.parentElement, clipped = false;
      while (p && p !== shell) {
        if (CLIPS.has(getComputedStyle(p).overflowX)) { clipped = true; break; }
        p = p.parentElement;
      }
      if (!clipped) {
        const cn = typeof el.className === 'string' ? el.className : el.tagName;
        problems.push('overflow: ' + (cn || el.tagName));
        break;
      }
    }
  }
  // unstyled marker: did the shared stylesheet actually apply?
  const body = getComputedStyle(document.body);
  if (!body.fontFamily.includes('Jakarta')) problems.push('stylesheet not applied');
  return problems;
}"""


def main():
    files = collect()
    if len(sys.argv) > 1:
        files = [f for f in files if any(a in f for a in sys.argv[1:])]
    report, bad = [], 0
    with sync_playwright() as p:
        b = p.chromium.launch(args=["--no-sandbox"])
        pg = b.new_page(viewport={"width": 430, "height": 900})
        for rel in files:
            errs, fails = [], []
            pg.on("pageerror", lambda e: errs.append(str(e)))
            pg.on("console", lambda m: errs.append(m.text) if m.type == "error" else None)
            pg.on("requestfailed", lambda r: fails.append(r.url.split("/")[-1]))
            pg.on("response", lambda r: fails.append(f"{r.status} {r.url.split('/')[-1]}")
                  if r.status >= 400 else None)
            try:
                pg.goto("file://" + os.path.join(ROOT, rel), timeout=15000)
                pg.wait_for_timeout(260)
                probs = pg.evaluate(AUDIT)
            except Exception as e:
                probs = [f"LOAD FAILED: {e}"]
            real = [x for x in fails if "pravatar" not in x and "unsplash" not in x
                    and "unpkg" not in x and "fonts.g" not in x]
            if errs or probs or real:
                bad += 1
                report.append((rel, errs[:2], probs[:3], real[:3]))
        b.close()

    print(f"checked {len(files)} screens · {bad} with findings\n")
    for rel, errs, probs, fails in report:
        print(f"  {rel}")
        if errs:  print("     js   :", errs)
        if probs: print("     dom  :", probs)
        if fails: print("     asset:", fails)
    if not report:
        print("  clean — no errors, no overflow, stylesheet applied everywhere")


if __name__ == "__main__":
    main()
