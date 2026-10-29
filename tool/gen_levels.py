#!/usr/bin/env python3
"""Arrowdrift level generator + independent verifier.

Levels are generated *backwards from a solution*: arrows are placed one at a
time and a new arrow is only accepted if its exit ray is free of every arrow
already on the board. The reverse of the placement order is therefore a valid
removal order, so every level is solvable by construction. `verify()` re-checks
that with a separate greedy solver that mirrors the Dart engine
(lib/game/board.dart).

Output: assets/levels/chunk_NNN.json (100 levels each) + meta.json.
Level format: [w, h, [[dir, c0, c1, ..., cHead], ...]]
  dir: 0=up 1=right 2=down 3=left   (direction the head leaves the board)
  cells: y*w + x, ordered tail -> head
"""
import json
import os
import random
import sys

DX = [0, 1, 0, -1]
DY = [-1, 0, 1, 0]
TOTAL = 5100
CHUNK = 100

# (first_level, last_level, name, w_start, w_end, minlen, maxlen_start, maxlen_end, turn)
TIERS = [
    (1, 1000, "easy", 4, 8, 1, 3, 5, 0.35),
    (1001, 2500, "medium", 8, 11, 2, 5, 8, 0.45),
    (2501, 4000, "hard", 10, 14, 2, 7, 11, 0.55),
    (4001, 5100, "expert", 12, 16, 3, 9, 14, 0.62),
]


def tier_of(n):
    for t in TIERS:
        if t[0] <= n <= t[1]:
            return t
    raise ValueError(n)


def params(n):
    first, last, _name, w0, w1, minlen, ml0, ml1, turn = tier_of(n)
    p = (n - first) / max(1, last - first)
    # tutorial ramp for the very first levels
    w = round(w0 + (w1 - w0) * p)
    if n <= 3:
        w = 4
    elif n <= 8:
        w = 5
    ml = round(ml0 + (ml1 - ml0) * p)
    if n <= 3:
        ml = 2
    h = w if w <= 5 else round(w * 1.25)
    return w, h, minlen, ml, turn


def build(n):
    rng = random.Random(0xA770 * 100003 + n * 7919)
    w, h, minlen, maxlen, turn = params(n)
    occ = [-1] * (w * h)
    raycount = [0] * (w * h)  # how many placed arrows' exit rays cross a cell
    arrows = []  # (dir, cells)
    tries = {"easy": 1, "medium": 3, "hard": 5, "expert": 8}[tier_of(n)[2]]
    if n <= 20:
        tries = 1

    cx, cy = (w - 1) / 2, (h - 1) / 2

    def ray_free(x, y, d, own):
        x += DX[d]
        y += DY[d]
        while 0 <= x < w and 0 <= y < h:
            c = y * w + x
            if occ[c] != -1 or c in own:
                return False
            x += DX[d]
            y += DY[d]
        return True

    def walk(start, length):
        cells = [start]
        seen = {start}
        last_d = None
        while len(cells) < length:
            c = cells[-1]
            x, y = c % w, c // w
            opts = []
            for d in range(4):
                nx, ny = x + DX[d], y + DY[d]
                if 0 <= nx < w and 0 <= ny < h:
                    nc = ny * w + nx
                    if occ[nc] == -1 and nc not in seen:
                        opts.append((d, nc))
            if not opts:
                break
            if last_d is not None and rng.random() < turn:
                turning = [o for o in opts if o[0] != last_d]
                if turning:
                    opts = turning
            d, nc = rng.choice(opts)
            cells.append(nc)
            seen.add(nc)
            last_d = d
        return cells

    def try_place(cells):
        """Try both ends as head, shrinking from the head side if blocked."""
        ends = [list(cells), list(reversed(cells))]
        rng.shuffle(ends)
        for seq in ends:
            for cut in range(len(seq), 0, -1):
                part = seq[:cut]
                head = part[-1]
                hx, hy = head % w, head // w
                own = set(part)
                if len(part) >= 2:
                    p = part[-2]
                    d = None
                    for dd in range(4):
                        if (p % w) + DX[dd] == hx and (p // w) + DY[dd] == hy:
                            d = dd
                    dirs = [d]
                else:
                    dirs = list(range(4))
                    rng.shuffle(dirs)
                for d in dirs:
                    if ray_free(hx, hy, d, own):
                        return d, part
        return None

    order = list(range(w * h))
    # centre-out with noise: central arrows are placed first (removed last).
    order.sort(key=lambda c: ((c % w - cx) ** 2 + (c // w - cy) ** 2) ** 0.5
               + rng.random() * (0.35 * max(w, h)))
    for _pass in range(3):
        placed_any = False
        for c in order:
            if occ[c] != -1:
                continue
            best = None
            for _t in range(tries):
                length = rng.randint(minlen, maxlen)
                cells = walk(c, length)
                if len(cells) < min(minlen, 2) and _pass == 0:
                    continue
                res = try_place(cells)
                if res is None:
                    continue
                d, part = res
                # prefer arrows that sit in many existing exit rays (deeper chains)
                score = sum(raycount[pc] for pc in part) + 0.01 * len(part)
                if best is None or score > best[0]:
                    best = (score, d, part)
            if best is None:
                continue
            _score, d, part = best
            idx = len(arrows)
            for pc in part:
                occ[pc] = idx
            arrows.append((d, part))
            hx, hy = part[-1] % w, part[-1] // w
            hx += DX[d]
            hy += DY[d]
            while 0 <= hx < w and 0 <= hy < h:
                raycount[hy * w + hx] += 1
                hx += DX[d]
                hy += DY[d]
            placed_any = True
        if not placed_any:
            break
    return w, h, arrows


def removable_layers(w, h, arrows):
    """Greedy peeling. Returns number of parallel rounds, or None if stuck."""
    occ = {}
    for i, (_d, cells) in enumerate(arrows):
        for c in cells:
            occ[c] = i
    alive = set(range(len(arrows)))
    rounds = 0
    while alive:
        free = []
        for i in alive:
            d, cells = arrows[i]
            head = cells[-1]
            x, y = head % w, head // w
            ok = True
            x += DX[d]
            y += DY[d]
            while 0 <= x < w and 0 <= y < h:
                o = occ.get(y * w + x)
                if o is not None and o in alive and o != i:
                    ok = False
                    break
                x += DX[d]
                y += DY[d]
            if ok:
                free.append(i)
        if not free:
            return None
        for i in free:
            alive.discard(i)
        rounds += 1
    return rounds


def verify(level):
    """Independent structural + solvability check on the *serialized* form."""
    w, h, arrs = level
    seen = set()
    parsed = []
    for a in arrs:
        d, cells = a[0], a[1:]
        assert 0 <= d < 4
        assert cells, "empty arrow"
        for c in cells:
            assert 0 <= c < w * h and c not in seen, "overlap/out of range"
            seen.add(c)
        for p, q in zip(cells, cells[1:]):
            assert abs(p % w - q % w) + abs(p // w - q // w) == 1, "non-adjacent"
        if len(cells) >= 2:
            p, q = cells[-2], cells[-1]
            assert (q % w - p % w, q // w - p // w) == (DX[d], DY[d]), "head dir"
        parsed.append((d, cells))
    return removable_layers(w, h, parsed)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.path.dirname(__file__), "..", "assets", "levels")
    os.makedirs(out, exist_ok=True)
    stats = {t[2]: {"n": 0, "arrows": 0, "rounds": 0, "cover": 0.0} for t in TIERS}
    for ci in range(0, (TOTAL + CHUNK - 1) // CHUNK):
        chunk = []
        for n in range(ci * CHUNK + 1, min(TOTAL, (ci + 1) * CHUNK) + 1):
            w, h, arrows = build(n)
            level = [w, h, [[d] + cells for d, cells in arrows]]
            rounds = verify(level)
            if rounds is None or len(arrows) < 2:
                raise SystemExit(f"level {n} invalid (rounds={rounds}, arrows={len(arrows)})")
            chunk.append(level)
            s = stats[tier_of(n)[2]]
            s["n"] += 1
            s["arrows"] += len(arrows)
            s["rounds"] += rounds
            s["cover"] += sum(len(a) - 1 for a in level[2]) / (w * h)
        with open(os.path.join(out, "chunk_%03d.json" % ci), "w") as f:
            json.dump(chunk, f, separators=(",", ":"))
    meta = {"total": TOTAL, "chunk": CHUNK,
            "tiers": [{"name": t[2], "first": t[0], "last": t[1]} for t in TIERS]}
    with open(os.path.join(out, "meta.json"), "w") as f:
        json.dump(meta, f, separators=(",", ":"))
    for name, s in stats.items():
        n = s["n"]
        print(f"{name:7s} levels={n:5d} avg_arrows={s['arrows']/n:6.1f} "
              f"avg_rounds={s['rounds']/n:5.1f} avg_cover={100*s['cover']/n:4.1f}%")


if __name__ == "__main__":
    main()
