#!/usr/bin/env python3
"""
Add the UI Screen Spec §2 blocks that the existing Home screen is missing:

  · Leaderboard card  — sport chips + 5-column ranked strip
  · Feed section      — underline tabs + a post card with photo collage

Applies to both copies of the athlete home (flat + role folder).
"""
import os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

LEADERBOARD = """
<div class="sect" style="margin-bottom:18px">
<div class="sect-h"><h2><i data-lucide="crown"></i>Leaderboard</h2><a class="seeall" href="{p}leaderboard.html">View All <i data-lucide="chevron-right"></i></a></div>
<div class="chiprow" style="margin-bottom:10px"><span class="chip soft">All Sports</span><span class="chip">Cricket</span><span class="chip">Football</span><span class="chip">Throwball</span><span class="chip">Badminton</span></div>
<div class="lb-strip">
<div class="lb-col"><div class="lb-av"><img src="https://i.pravatar.cc/160?img=12" alt="Arjun Patel" loading="lazy" onerror="this.remove()"><span class="lb-rank r1">1</span></div><b>Arjun Patel</b><span>2,450 pts</span></div>
<div class="lb-col"><div class="lb-av"><img src="https://i.pravatar.cc/160?img=47" alt="Priya Sharma" loading="lazy" onerror="this.remove()"><span class="lb-rank r2">2</span></div><b>Priya Sharma</b><span>2,180 pts</span></div>
<div class="lb-col"><div class="lb-av"><img src="https://i.pravatar.cc/160?img=68" alt="Karan Joshi" loading="lazy" onerror="this.remove()"><span class="lb-rank r3">3</span></div><b>Karan Joshi</b><span>1,960 pts</span></div>
<div class="lb-col"><div class="lb-av"><img src="https://i.pravatar.cc/160?img=32" alt="Sneha Verma" loading="lazy" onerror="this.remove()"><span class="lb-rank rn">4</span></div><b>Sneha Verma</b><span>1,820 pts</span></div>
<div class="lb-col"><div class="lb-av"><img src="https://i.pravatar.cc/160?img=11" alt="Dev Mehta" loading="lazy" onerror="this.remove()"><span class="lb-rank rn">5</span></div><b>Dev Mehta</b><span>1,650 pts</span></div>
</div></div>
"""

FEED = """
<div class="sect">
<div class="sect-h" style="margin-bottom:6px"><h2 style="font-size:17px">Community Feed</h2><a class="iconbtn" href="{p}discover.html" style="width:34px;height:34px"><i data-lucide="sliders-horizontal" style="width:16px;height:16px"></i></a></div>
<div class="utabs"><a class="on" href="#">For You</a><a href="#">Following</a><a href="#">Athletes</a><a href="#">Coaches</a><a href="#">Academies</a><a href="#">Events</a></div>
<article class="post">
<div class="post-h"><div class="av-wrap"><div class="avatar av40">P<img src="https://i.pravatar.cc/120?img=47" alt="Priya Sharma" loading="lazy" onerror="this.remove()"></div></div>
<div style="flex:1"><b style="font-size:14px;font-weight:700;color:var(--navy)">Priya Sharma<i data-lucide="badge-check" class="verified"></i></b><div class="pmeta">State Level Athlete &middot; Throwball &middot; Gujarat &middot; 2h ago</div></div>
<a class="iconbtn" href="#" style="width:30px;height:30px;box-shadow:none;border:none"><i data-lucide="more-vertical" style="width:17px;height:17px"></i></a></div>
<p class="post-txt">Another great practice session today! Consistency creates progress &#128170;<br><span class="tag">#Throwball</span> <span class="tag">#Training</span> <span class="tag">#NeverGiveUp</span></p>
<div class="collage">
<div><img src="https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=600&q=60" alt="Training" loading="lazy" onerror="this.remove()"></div>
<div><img src="https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=400&q=60" alt="Team huddle" loading="lazy" onerror="this.remove()"></div>
<div><img src="https://images.unsplash.com/photo-1579952363873-27f3bade9f55?auto=format&fit=crop&w=400&q=60" alt="Match" loading="lazy" onerror="this.remove()"></div>
<div><img src="https://images.unsplash.com/photo-1526232761682-d26e03ac148e?auto=format&fit=crop&w=400&q=60" alt="Practice" loading="lazy" onerror="this.remove()"></div>
<div><img src="https://images.unsplash.com/photo-1547347298-4074fc3086f0?auto=format&fit=crop&w=400&q=60" alt="Court" loading="lazy" onerror="this.remove()"></div>
</div>
<div class="post-acts"><a class="liked" href="#"><i data-lucide="heart"></i>256</a><a href="#"><i data-lucide="message-circle"></i>18</a><a href="#"><i data-lucide="send"></i>12</a><a class="bmk" href="#"><i data-lucide="bookmark"></i></a></div>
</article></div>
"""


def build(prefix):
    return LEADERBOARD.format(p=prefix), FEED.format(p=prefix)


def process(path, prefix):
    s = open(path, encoding="utf-8").read()
    if 'class="lb-strip"' in s:
        print("  already has feed, skip", path)
        return
    lb, feed = build(prefix)

    # 1) leaderboard card right after the profile-completion banner
    m = re.search(r'<div class="greet">.*?<div class="pbar"><i style="width:68%"></i></div></div>\n',
                  s, re.S)
    if not m:
        print("  !! greet block not found in", path)
        return
    s = s[:m.end()] + lb + s[m.end():]

    # 2) feed section before the "Recommended Athletes" section
    m = re.search(r'<div class="sect"><div class="sect-h"><h2>Recommended Athletes</h2>', s)
    if not m:
        print("  !! recommended section not found in", path)
        return
    s = s[:m.start()] + feed.strip() + "\n" + s[m.start():]

    open(path, "w", encoding="utf-8").write(s)
    print("  + leaderboard + feed ->", path)


if __name__ == "__main__":
    process(os.path.join(ROOT, "home.html"), "")
    process(os.path.join(ROOT, "01-athlete", "home.html"), "../")
