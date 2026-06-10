#!/usr/bin/env python3
"""Reduce an xctrace metal-gpu-intervals XML export to per-process GPU busy.

xctrace XML compresses repeated values via id/ref attributes; raw values are
element text (durations in ns). Process attribution rides in the event-label
("( Test Demos (123) )" / "( WindowServer (594) )").

Output: busy ms/s per channel for the app and for WindowServer, over the
middle of the recording (first 2s skipped).
"""
import sys
import re
import xml.etree.ElementTree as ET

SKIP_NS = 2_000_000_000

def main(path):
    root = ET.parse(path).getroot()
    node = root.find('node')
    if node is None:
        print('NO DATA')
        return
    cols = [c.findtext('mnemonic') for c in node.find('schema').findall('col')]
    i_start = cols.index('start')
    i_dur = cols.index('duration')
    i_chan = cols.index('channel-name')
    i_label = cols.index('event-label')

    memo = {}

    def reg(el):
        """Register ids depth-first and return resolved (text, fmt)."""
        ref = el.get('ref')
        if ref is not None:
            return memo.get(ref, (None, None))
        out = (el.text, el.get('fmt'))
        eid = el.get('id')
        if eid is not None:
            memo[eid] = out
        return out

    rows = node.findall('row')
    busy = {}
    t_lo, t_hi = None, None
    for row in rows:
        children = list(row)
        if len(children) < len(cols):
            continue
        # register every element (incl. nested) so refs resolve later
        resolved = []
        for ch in children:
            resolved.append(reg(ch))
            for sub in ch.iter():
                if sub is not ch:
                    reg(sub)
        try:
            start = int(resolved[i_start][0] or 0)
            dur = int(resolved[i_dur][0] or 0)
        except (TypeError, ValueError):
            continue
        chan = resolved[i_chan][1] or resolved[i_chan][0] or '?'
        label = resolved[i_label][1] or resolved[i_label][0] or ''
        m = re.search(r'\(\s*([^()]+?)\s*\(\d+\)\s*\)', label)
        proc = m.group(1) if m else 'unattributed'
        if start < SKIP_NS:
            continue
        t_lo = start if t_lo is None else min(t_lo, start)
        t_hi = max(t_hi or 0, start + dur)
        key = (proc, chan)
        busy[key] = busy.get(key, 0) + dur

    if not busy or not t_hi or t_hi <= t_lo:
        print('NO FRAMES')
        return
    window_s = (t_hi - t_lo) / 1e9
    parts = []
    for (proc, chan), ns in sorted(busy.items(), key=lambda kv: -kv[1]):
        ms_per_s = ns / 1e6 / window_s
        if ms_per_s < 1:
            continue
        parts.append(f'{proc}/{chan}={ms_per_s:.1f}ms/s')
    print(f'window={window_s:.1f}s ' + ' '.join(parts))

if __name__ == '__main__':
    main(sys.argv[1])
