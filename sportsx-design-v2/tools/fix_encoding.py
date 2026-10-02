#!/usr/bin/env python3
"""
Repair double-encoded UTF-8 in the SportX screens.

An earlier build step decoded UTF-8 bytes through cp1252, turning e.g.
"₹" (E2 82 B9) into "â" + "‚" + "¹". A naive latin-1 repair misses this
because cp1252 maps 0x82/0x91/0x9F onto printable Unicode punctuation.

Strategy: anchor on a mojibake lead byte, then consume the longest following
run that still decodes as valid UTF-8.
"""
import re

LEAD = re.compile(
    "[ÂÃÅÐáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ"
    "ĀāĂăĄąĆćĈĉĊċČčĎďĐđĂĕĖėĘęĚěĜĝĞğĠġĢģ"
    "ıĺļľŀŁłŃńŅņŇňŌōŎŏŐőŒœŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧ]"
    "[-￿]{0,8}"
)


def _to_bytes(txt):
    """cp1252 encode, falling back to the raw byte for C1 controls (undefined
    in cp1252) so 4-byte emoji sequences survive the round-trip."""
    out = bytearray()
    for ch in txt:
        try:
            out += ch.encode("cp1252")
        except UnicodeEncodeError:
            o = ord(ch)
            if o < 0x100:
                out.append(o)
            else:
                return None
    return bytes(out)


def _try(txt):
    raw = _to_bytes(txt)
    if raw is None:
        return None
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return None


def repair_once(text):
    out, i, n = [], 0, len(text)

    def flush(pos):
        """Consume the longest valid-UTF-8 prefix of text[pos:]."""
        m = LEAD.match(text, pos)
        if not m:
            return
        cand = m.group(0)
        for L in range(len(cand), 1, -1):
            fixed = _try(cand[:L])
            if fixed is not None:
                out.append(fixed)
                return m.end() if L == len(cand) else pos + L
        out.append(cand)
        return m.end()

    while i < n:
        j = flush(i)
        if j is None or j <= i:
            out.append(text[i])
            i += 1
        else:
            i = j
    return "".join(out)


def repair(text, passes=4):
    for _ in range(passes):
        fixed = repair_once(text)
        if fixed == text:
            break
        text = fixed
    return text


if __name__ == "__main__":
    tests = [
        "Up to â‚¹50,000",
        "Hi, Coach Rahul ðŸ‘‘",
        "Badminton Â· U-17",
        "2 Ã— 3 courts",
        "Profile â€” edit",
        "Raj â€“ Patel",
        "“quoted” text",
    ]
    for t in tests:
        print(repr(t), "->", repr(repair(t)))
