.pragma library

// ============================================================================
// Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
// Free to use, fork, and adapt with author attribution.
// Signature: T3JpZ2luYWwgQXV0aG9yOiBNb2hhbW1lZCBBd2FkIChodHRwczovL2dpdGh1Yi5jb20vTW9oYW1tZWQtQXdhZC1FTkcp
// ============================================================================
var _AUTHOR_SIGNATURE = "\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x20\x41\x77\x61\x64\x20\x28\x68\x74\x74\x70\x73\x3a\x2f\x2f\x67\x69\x74\x68\x75\x62\x2e\x63\x6f\x6d\x2f\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x2d\x41\x77\x61\x64\x2d\x45\x4e\x47\x29";

/**
 * SpatialCanvas.js — 2D spatial canvas & PaperWM scrollable strip engine.
 *
 * Implements:
 * 1. PaperWM scrollable strip (horizontal row or vertical column of windows next to each other).
 * 2. Custom 2D Spatial Tree: original window in center, branching UP, DOWN, LEFT, RIGHT,
 *    and each node recursively branching in all 4 directions (matching user diagram).
 * 3. Camera panning / travel mechanics: active window is centered or brought into view,
 *    other windows are placed at relative spatial offsets.
 * 4. Minimap graph & arrow calculation.
 */


var APP_COLORS = [
    "#4CAF50", "#2196F3", "#FF9800", "#9C27B0", "#F44336",
    "#00BCD4", "#FF5722", "#3F51B5", "#E91E63", "#009688",
    "#FFC107", "#607D8B", "#8BC34A", "#03A9F4", "#673AB7"
];
var _colorMap = {};
var _colorIdx = 0;

function colorForClass(cls) {
    if (!cls) return APP_COLORS[0];
    if (!_colorMap[cls]) {
        _colorMap[cls] = APP_COLORS[_colorIdx % APP_COLORS.length];
        _colorIdx++;
    }
    return _colorMap[cls];
}

/**
 * Directional unit vectors.
 */
var DIRS = {
    "up":    { dx:  0, dy: -1 },
    "down":  { dx:  0, dy:  1 },
    "left":  { dx: -1, dy:  0 },
    "right": { dx:  1, dy:  0 }
};

/**
 * Opposite directions.
 */
var OPPOSITE = {
    "up": "down",
    "down": "up",
    "left": "right",
    "right": "left"
};

/**
 * Initialize a PaperWM-style horizontal or vertical strip of windows.
 * Windows are placed sequentially next to each other:
 * Window 0 -> Window 1 -> Window 2 -> ...
 */
function initPaperStrip(addresses, orientation) {
    var coords = {};
    var connections = [];
    var isCol = (orientation === "col");

    for (var i = 0; i < addresses.length; i++) {
        var addr = addresses[i];
        if (isCol) {
            coords[addr] = { x: 0, y: i };
        } else {
            coords[addr] = { x: i, y: 0 };
        }
        if (i > 0) {
            connections.push({
                from: addresses[i - 1],
                to: addr,
                dir: isCol ? "down" : "right"
            });
        }
    }
    return {
        rootAddr: addresses[0] || null,
        coords: coords,
        connections: connections
    };
}

/**
 * Initialize Custom 2D Spatial Tree matching the user's diagram:
 *
 *               [ UP (0,-1) ]       [ RIGHT-UP (1,-1) ]
 *                     ↑                    ↑
 * [ LEFT (-1,0) ] ← [ CENTER (0,0) ] → [ RIGHT (1,0) ]
 *         ↓                 ↓                    ↓
 * [ LEFT-DOWN (-1,1) ] [ DOWN (0,1) ]  [ RIGHT-DOWN (1,1) ]
 */
function initCustom2D(addresses) {
    var coords = {};
    var connections = [];

    if (!addresses || addresses.length === 0) {
        return { rootAddr: null, coords: coords, connections: connections };
    }

    var root = addresses[0];
    coords[root] = { x: 0, y: 0 };

    // Standard pattern positions following the user's diagram
    var pattern = [
        { dir: "up",    from: 0, pos: { x:  0, y: -1 } }, // 1: new window UP
        { dir: "right", from: 0, pos: { x:  1, y:  0 } }, // 2: RIGHT window
        { dir: "left",  from: 0, pos: { x: -1, y:  0 } }, // 3: LEFT window
        { dir: "down",  from: 0, pos: { x:  0, y:  1 } }, // 4: DOWN window
        { dir: "up",    from: 3, pos: { x: -1, y: -1 } }, // 5: LEFT -> UP
        { dir: "down",  from: 3, pos: { x: -1, y:  1 } }, // 6: LEFT -> DOWN
        { dir: "up",    from: 2, pos: { x:  1, y: -1 } }, // 7: RIGHT -> UP
        { dir: "down",  from: 2, pos: { x:  1, y:  1 } }, // 8: RIGHT -> DOWN
        { dir: "right", from: 2, pos: { x:  2, y:  0 } }, // 9: Far right
        { dir: "left",  from: 3, pos: { x: -2, y:  0 } }  // 10: Far left
    ];

    for (var i = 1; i < addresses.length; i++) {
        var addr = addresses[i];
        if (i - 1 < pattern.length) {
            var step = pattern[i - 1];
            var fromAddr = addresses[step.from] || root;
            coords[addr] = { x: step.pos.x, y: step.pos.y };
            connections.push({
                from: fromAddr,
                to: addr,
                dir: step.dir
            });
        } else {
            // Additional windows extend horizontally to the right
            var lastAddr = addresses[i - 1];
            var lastPos = coords[lastAddr] || { x: i - 1, y: 0 };
            coords[addr] = { x: lastPos.x + 1, y: lastPos.y };
            connections.push({
                from: lastAddr,
                to: addr,
                dir: "right"
            });
        }
    }

    return {
        rootAddr: root,
        coords: coords,
        connections: connections
    };
}

/**
 * Attach a window in a specific direction relative to an anchor window.
 * Supports: "up", "down", "left", "right", "same" (same window slot).
 */
function attachWindow(coords, connections, fromAddr, toAddr, direction) {
    if (!coords[fromAddr]) {
        coords[fromAddr] = { x: 0, y: 0 };
    }
    var fromPos = coords[fromAddr];

    // If opening in the same window normally (same slot)
    if (direction === "same" || direction === "center") {
        coords[toAddr] = { x: fromPos.x, y: fromPos.y };
        var filteredSame = connections.filter(function(c) { return c.to !== toAddr; });
        filteredSame.push({ from: fromAddr, to: toAddr, dir: "same" });
        return { coords: coords, connections: filteredSame };
    }

    var d = DIRS[direction] || DIRS["right"];
    var targetX = fromPos.x + d.dx;
    var targetY = fromPos.y + d.dy;

    // Check if slot already occupied; if so, push in that direction
    var occupiedAddr = findAtCoord(coords, targetX, targetY);
    if (occupiedAddr && occupiedAddr !== toAddr) {
        shiftInDirection(coords, targetX, targetY, direction);
    }

    coords[toAddr] = { x: targetX, y: targetY };

    // Remove any existing connection to toAddr
    var filtered = connections.filter(function(c) { return c.to !== toAddr; });
    filtered.push({ from: fromAddr, to: toAddr, dir: direction });

    return { coords: coords, connections: filtered };
}

function findAtCoord(coords, x, y) {
    for (var addr in coords) {
        if (coords[addr].x === x && coords[addr].y === y) {
            return addr;
        }
    }
    return null;
}

function shiftInDirection(coords, startX, startY, dir) {
    var d = DIRS[dir] || DIRS["right"];
    for (var addr in coords) {
        var p = coords[addr];
        if (dir === "right" && p.y === startY && p.x >= startX) {
            p.x += 1;
        } else if (dir === "left" && p.y === startY && p.x <= startX) {
            p.x -= 1;
        } else if (dir === "down" && p.x === startX && p.y >= startY) {
            p.y += 1;
        } else if (dir === "up" && p.x === startX && p.y <= startY) {
            p.y -= 1;
        }
    }
}

/**
 * Normalizes a PaperWM strip to ensure contiguous 0, 1, 2... coordinates with zero gaps.
 */
function normalizePaperStrip(coords, connections, orientation, liveAddrs) {
    var isCol = (orientation === "col");
    var wins = [];
    for (var i = 0; i < liveAddrs.length; i++) {
        var addr = liveAddrs[i];
        var pos = coords[addr];
        wins.push({
            addr: addr,
            posVal: pos ? (isCol ? pos.y : pos.x) : 999999
        });
    }
    // Sort preserving their existing relative order, breaking ties by liveAddrs index
    wins.sort(function(a, b) {
        if (a.posVal !== b.posVal) return a.posVal - b.posVal;
        return liveAddrs.indexOf(a.addr) - liveAddrs.indexOf(b.addr);
    });

    var newCoords = {};
    var newConns = [];
    for (var idx = 0; idx < wins.length; idx++) {
        var a = wins[idx].addr;
        newCoords[a] = {
            x: isCol ? 0 : idx,
            y: isCol ? idx : 0
        };
        if (idx > 0) {
            newConns.push({
                from: wins[idx - 1].addr,
                to: a,
                dir: isCol ? "down" : "right"
            });
        }
    }
    return { coords: newCoords, connections: newConns };
}

/**
 * Re-stitches connections and compacts 2D coordinate gaps when windows are removed.
 */
function compact2D(coords, connections, removedAddrs, floatSlots) {
    if (!coords) return { coords: coords, connections: connections };
    if (!connections) connections = [];

    // 1. Re-stitch connections across each removed window
    if (removedAddrs && removedAddrs.length) {
        for (var rIdx = 0; rIdx < removedAddrs.length; rIdx++) {
            var rem = removedAddrs[rIdx];
            var inConns = connections.filter(function(c) { return c.to === rem; });
            var outConns = connections.filter(function(c) { return c.from === rem; });

            // Connect parents directly to children
            for (var o = 0; o < outConns.length; o++) {
                var outC = outConns[o];
                if (inConns.length > 0) {
                    var inC = inConns[0];
                    connections.push({
                        from: inC.from,
                        to: outC.to,
                        dir: outC.dir
                    });
                }
            }

            // Remove all connections to/from the deleted window
            connections = connections.filter(function(c) {
                return c.from !== rem && c.to !== rem;
            });
            delete coords[rem];
        }
    }

    // 2. Compact gaps along each axis towards origin (0, 0)
    var addrs = Object.keys(coords);
    if (addrs.length === 0) return { coords: coords, connections: connections };

    // 2a. Sanitize all coordinates: ensure finite numbers, no null/undefined/NaN
    for (var sa in coords) {
        var sp = coords[sa];
        if (!sp || typeof sp.x !== "number" || typeof sp.y !== "number" || isNaN(sp.x) || isNaN(sp.y)) {
            var safeX = 0, safeY = 0;
            while (findAtCoord(coords, safeX, safeY)) {
                safeX += 1;
            }
            coords[sa] = { x: safeX, y: safeY };
        }
    }

    // If root (0, 0) was removed and slot is empty, shift all windows towards (0, 0)
    if (!findAtCoord(coords, 0, 0)) {
        var closestAddr = addrs[0];
        var minD = 999999;
        for (var a = 0; a < addrs.length; a++) {
            var p = coords[addrs[a]];
            var d = Math.abs(p.x) + Math.abs(p.y);
            if (d < minD) { minD = d; closestAddr = addrs[a]; }
        }
        var shiftX = coords[closestAddr].x;
        var shiftY = coords[closestAddr].y;
        for (var b = 0; b < addrs.length; b++) {
            coords[addrs[b]].x -= shiftX;
            coords[addrs[b]].y -= shiftY;
        }
    }

    // Axis gap compaction: loop until no empty intermediate coordinate slots exist
    var changed = true;
    var maxPasses = 20;
    while (changed && maxPasses-- > 0) {
        changed = false;
        var bb = boundingBox(coords);
        if (isNaN(bb.minX) || isNaN(bb.maxX) || isNaN(bb.minY) || isNaN(bb.maxY)) break;

        // Positive X axis
        for (var kx = 1; kx < bb.maxX; kx++) {
            var hasCol = false;
            for (var cAddr in coords) {
                if (coords[cAddr].x === kx) { hasCol = true; break; }
            }
            if (!hasCol) {
                for (var cAddr2 in coords) {
                    if (coords[cAddr2].x > kx) {
                        coords[cAddr2].x -= 1;
                        changed = true;
                    }
                }
                break;
            }
        }

        // Negative X axis
        for (var nkx = -1; nkx > bb.minX; nkx--) {
            var hasColNeg = false;
            for (var cAddr3 in coords) {
                if (coords[cAddr3].x === nkx) { hasColNeg = true; break; }
            }
            if (!hasColNeg) {
                for (var cAddr4 in coords) {
                    if (coords[cAddr4].x < nkx) {
                        coords[cAddr4].x += 1;
                        changed = true;
                    }
                }
                break;
            }
        }

        // Positive Y axis
        for (var ky = 1; ky < bb.maxY; ky++) {
            var hasRow = false;
            for (var cAddr5 in coords) {
                if (coords[cAddr5].y === ky) { hasRow = true; break; }
            }
            if (!hasRow) {
                for (var cAddr6 in coords) {
                    if (coords[cAddr6].y > ky) {
                        coords[cAddr6].y -= 1;
                        changed = true;
                    }
                }
                break;
            }
        }

        // Negative Y axis
        for (var nky = -1; nky > bb.minY; nky--) {
            var hasRowNeg = false;
            for (var cAddr7 in coords) {
                if (coords[cAddr7].y === nky) { hasRowNeg = true; break; }
            }
            if (!hasRowNeg) {
                for (var cAddr8 in coords) {
                    if (coords[cAddr8].y < nky) {
                        coords[cAddr8].y += 1;
                        changed = true;
                    }
                }
                break;
            }
        }
    }

    // Ensure every window has a unique (x, y) coordinate,
    // UNLESS the slot is a Float Place or connected with dir: "same"
    var occupiedSlots = {};
    for (var u = 0; u < addrs.length; u++) {
        var uAddr = addrs[u];
        var uPos = coords[uAddr];
        if (!uPos) continue;
        var slotKey = uPos.x + "," + uPos.y;

        // Check if this window is in a Float Slot or grouped with dir: "same"
        var isFloatGrouped = false;
        if (floatSlots && floatSlots[slotKey]) {
            isFloatGrouped = true;
        } else {
            for (var sc = 0; sc < connections.length; sc++) {
                var conn = connections[sc];
                if (conn.dir === "same" && (conn.from === uAddr || conn.to === uAddr)) {
                    isFloatGrouped = true;
                    break;
                }
            }
        }

        if (!isFloatGrouped && occupiedSlots[slotKey]) {
            // Collision on regular slot: find first unoccupied slot to the right
            var safety = 100;
            while (occupiedSlots[uPos.x + "," + uPos.y] && safety-- > 0) {
                uPos.x += 1;
            }
            coords[uAddr] = { x: uPos.x, y: uPos.y };
            slotKey = uPos.x + "," + uPos.y;
        }
        occupiedSlots[slotKey] = uAddr;
    }

    // Filter connections to only remaining windows
    connections = connections.filter(function(c) {
        return coords[c.from] && coords[c.to];
    });

    // Ensure every node is connected in the graph
    var connected = {};
    for (var ci = 0; ci < connections.length; ci++) {
        connected[connections[ci].from] = true;
        connected[connections[ci].to] = true;
    }
    for (var ai = 0; ai < addrs.length; ai++) {
        var winA = addrs[ai];
        if (addrs.length > 1 && !connected[winA]) {
            var bestN = null, bestD = 999999, bDir = "right";
            var posA = coords[winA];
            for (var bi = 0; bi < addrs.length; bi++) {
                var winB = addrs[bi];
                if (winB === winA) continue;
                var posB = coords[winB];
                var dDist = Math.abs(posB.x - posA.x) + Math.abs(posB.y - posA.y);
                if (dDist < bestD) {
                    bestD = dDist;
                    bestN = winB;
                    if (posB.x < posA.x) bDir = "right";
                    else if (posB.x > posA.x) bDir = "left";
                    else if (posB.y < posA.y) bDir = "down";
                    else bDir = "up";
                }
            }
            if (bestN) {
                connections.push({ from: bestN, to: winA, dir: bDir });
                connected[winA] = true;
            }
        }
    }

    return { coords: coords, connections: connections };
}

function compactGaps(coords, connections) {
    return compact2D(coords, connections, []);
}

/**
 * Find the neighbor window address in a given direction from a source window.
 */
function getNeighbor(coords, connections, fromAddr, direction) {
    if (!coords || !coords[fromAddr]) return null;
    var d = DIRS[direction];
    if (!d) return null;
    var fromPos = coords[fromAddr];

    // 1. Immediate coordinate check (exactly 1 step away)
    var tx = fromPos.x + d.dx;
    var ty = fromPos.y + d.dy;
    var direct = findAtCoord(coords, tx, ty);
    if (direct) return direct;

    // 2. Direct connection check
    if (connections && connections.length) {
        for (var i = 0; i < connections.length; i++) {
            var c = connections[i];
            if (c.from === fromAddr && c.dir === direction && coords[c.to]) {
                return c.to;
            }
            if (c.to === fromAddr && OPPOSITE[c.dir] === direction && coords[c.from]) {
                return c.from;
            }
        }
    }

    // 3. Search closest window in this direction
    var bestAddr = null;
    var bestDist = 999999;

    for (var addr in coords) {
        if (addr === fromAddr) continue;
        var p = coords[addr];
        var dx = p.x - fromPos.x;
        var dy = p.y - fromPos.y;

        var isCorrectDir = false;
        if (direction === "right" && dx > 0) isCorrectDir = true;
        else if (direction === "left" && dx < 0) isCorrectDir = true;
        else if (direction === "down" && dy > 0) isCorrectDir = true;
        else if (direction === "up" && dy < 0) isCorrectDir = true;

        if (isCorrectDir) {
            var mainDist = (direction === "right" || direction === "left") ? Math.abs(dx) : Math.abs(dy);
            var perpDist = (direction === "right" || direction === "left") ? Math.abs(dy) : Math.abs(dx);
            var dist = mainDist * 10 + perpDist * 20;

            if (dist < bestDist) {
                bestDist = dist;
                bestAddr = addr;
            }
        }
    }

    return bestAddr;
}

/**
 * Compute the bounding box of a coordinates map.
 */
function boundingBox(coords) {
    var minX = 0, maxX = 0, minY = 0, maxY = 0;
    var first = true;
    for (var addr in coords) {
        var c = coords[addr];
        if (!c || typeof c.x !== "number" || typeof c.y !== "number" || isNaN(c.x) || isNaN(c.y)) continue;
        if (first) {
            minX = maxX = c.x;
            minY = maxY = c.y;
            first = false;
        } else {
            if (c.x < minX) minX = c.x;
            if (c.x > maxX) maxX = c.x;
            if (c.y < minY) minY = c.y;
            if (c.y > maxY) maxY = c.y;
        }
    }
    return { minX: minX, maxX: maxX, minY: minY, maxY: maxY };
}

/**
 * Compute dwindle / BSP auto-tiling rectangles for multiple windows inside a single slot box.
 * Matches Hyprland's native dwindle auto-tiling ("like Float (Native)").
 */
function computeDwindleRects(addresses, boxX, boxY, boxW, boxH, gap, gx, gy) {
    var rects = [];
    var n = addresses.length;
    if (n === 0) return rects;
    if (n === 1) {
        return [{
            address: addresses[0],
            x: Math.round(boxX),
            y: Math.round(boxY),
            width: Math.round(boxW),
            height: Math.round(boxH),
            gx: gx,
            gy: gy
        }];
    }

    var remaining = { x: boxX, y: boxY, w: boxW, h: boxH };

    for (var i = 0; i < n; i++) {
        var addr = addresses[i];
        if (i === n - 1) {
            rects.push({
                address: addr,
                x: Math.round(remaining.x),
                y: Math.round(remaining.y),
                width: Math.round(remaining.w),
                height: Math.round(remaining.h),
                gx: gx,
                gy: gy
            });
            break;
        }

        // Split vertically if wider than tall, otherwise horizontally
        var splitVert = (remaining.w >= remaining.h * 1.05);
        if (splitVert) {
            var w1 = Math.floor((remaining.w - gap) / 2);
            rects.push({
                address: addr,
                x: Math.round(remaining.x),
                y: Math.round(remaining.y),
                width: Math.round(w1),
                height: Math.round(remaining.h),
                gx: gx,
                gy: gy
            });
            remaining.x = remaining.x + w1 + gap;
            remaining.w = remaining.w - w1 - gap;
        } else {
            var h1 = Math.floor((remaining.h - gap) / 2);
            rects.push({
                address: addr,
                x: Math.round(remaining.x),
                y: Math.round(remaining.y),
                width: Math.round(remaining.w),
                height: Math.round(h1),
                gx: gx,
                gy: gy
            });
            remaining.y = remaining.y + h1 + gap;
            remaining.h = remaining.h - h1 - gap;
        }
    }
    return rects;
}

/**
 * Compute screen layout rectangles for all windows based on the active camera.
 *
 * The camera is centered or anchored on activeAddr:
 * - In PaperWM mode: windows appear side-by-side in a horizontal strip.
 * - In Custom mode: windows are spatially positioned in 2D around the active window.
 *   Slots with multiple windows or marked as floatSlots are tiled natively like Float mode.
 */
function computeScreenRects(mode, monitor, coords, activeAddr, settings, gaps) {
    var g = (gaps !== undefined) ? gaps : 10;
    var mw = (monitor && monitor.lastIpcObject && monitor.lastIpcObject.width)  ? monitor.lastIpcObject.width  : 1920;
    var mh = (monitor && monitor.lastIpcObject && monitor.lastIpcObject.height) ? monitor.lastIpcObject.height : 1080;

    // Available screen viewport (avoiding left bar)
    var barWidth = 82;
    var margin = 12;
    var screenX = barWidth + margin;
    var screenY = margin;
    var screenW = mw - barWidth - margin * 2;
    var screenH = mh - margin * 2;

    var activePos = (coords && activeAddr && coords[activeAddr]) ? coords[activeAddr] : { x: 0, y: 0 };
    var rects = [];

    if (mode === "paper") {
        var orientation = (settings && settings.orientation) ? settings.orientation : "row";
        var sizeRatio = (settings && settings.widthRatio) ? settings.widthRatio : 0.5;

        var winW, winH;
        if (orientation === "col") {
            winW = screenW;
            winH = Math.max(250, Math.round(screenH * sizeRatio) - g);
        } else {
            winW = Math.max(400, Math.round(screenW * sizeRatio) - g);
            winH = screenH;
        }

        // Camera offset: position active window on screen
        // In row mode: if visibleSlots >= 2 (e.g. ratio 0.5), both windows fit side-by-side next to each other
        if (orientation === "row") {
            var slotW = winW + g;
            var visibleSlots = Math.max(1, Math.floor((screenW + g) / slotW));
            var camSlot = Math.max(0, activePos.x - (visibleSlots - 1));
            var camX = camSlot * slotW;

            for (var addr in coords) {
                var p = coords[addr];
                var wx = screenX + (p.x * slotW - camX);
                var wy = screenY;
                rects.push({
                    address: addr,
                    x: Math.round(wx),
                    y: Math.round(wy),
                    width: winW,
                    height: winH,
                    gx: p.x,
                    gy: p.y
                });
            }
        } else {
            var slotH = winH + g;
            var visibleSlotsH = Math.max(1, Math.floor((screenH + g) / slotH));
            var camSlotY = Math.max(0, activePos.y - (visibleSlotsH - 1));
            var camY = camSlotY * slotH;

            for (var addr in coords) {
                var p = coords[addr];
                var wx = screenX;
                var wy = screenY + (p.y * slotH - camY);
                rects.push({
                    address: addr,
                    x: Math.round(wx),
                    y: Math.round(wy),
                    width: winW,
                    height: winH,
                    gx: p.x,
                    gy: p.y
                });
            }
        }
    } else {
        // Custom 2D Spatial Canvas
        // Windows size preset: cluster/half mode (880x500) so neighbors are partially or fully visible
        var isFull = (settings && settings.customPreset === "full");
        var winW = isFull ? screenW : Math.max(400, Math.round(screenW * 0.5) - g);
        var winH = isFull ? screenH : Math.max(260, Math.round(screenH * 0.5) - g);
        var floatSlots = (settings && settings.floatSlots) ? settings.floatSlots : {};

        // Center the active window on screen
        var centerX = screenX + (screenW - winW) / 2;
        var centerY = screenY + (screenH - winH) / 2;

        // Group windows by coordinate slot
        var slotWindows = {};
        for (var addr in coords) {
            var p = coords[addr];
            var key = p.x + "," + p.y;
            if (!slotWindows[key]) slotWindows[key] = [];
            slotWindows[key].push(addr);
        }

        for (var sKey in slotWindows) {
            var addrsInSlot = slotWindows[sKey];
            var parts = sKey.split(",");
            var sx = parseInt(parts[0], 10);
            var sy = parseInt(parts[1], 10);

            var diffX = sx - activePos.x;
            var diffY = sy - activePos.y;

            var slotBoxX = centerX + diffX * (winW + g);
            var slotBoxY = centerY + diffY * (winH + g);

            var isFloatSlot = (addrsInSlot.length > 1) || !!floatSlots[sKey];

            if (isFloatSlot && addrsInSlot.length > 1) {
                // Multi-app Float Place: layout windows using native dwindle auto-tiling
                var dwindleRects = computeDwindleRects(addrsInSlot, slotBoxX, slotBoxY, winW, winH, g, sx, sy);
                rects = rects.concat(dwindleRects);
            } else {
                var singleAddr = addrsInSlot[0];
                rects.push({
                    address: singleAddr,
                    x: Math.round(slotBoxX),
                    y: Math.round(slotBoxY),
                    width: winW,
                    height: winH,
                    gx: sx,
                    gy: sy
                });
            }
        }
    }

    return rects;
}

/**
 * Compute 2D Minimap coordinates for rendering in the popout.
 *
 * Scales the full spatial graph into mapWidth x mapHeight,
 * centers it, and computes connection arrows between adjacent windows.
 */
function computeMinimapData(coords, connections, activeAddr, mode, mapW, mapH, windows, floatSlots, monitor) {
    var winMap = {};
    if (windows) {
        for (var i = 0; i < windows.length; i++) {
            var w = windows[i];
            var addr = w.lastIpcObject ? w.lastIpcObject.address : null;
            if (addr) winMap[addr] = w;
        }
    }

    // ── Native Float Mode ────────────────────────────────────────────────────
    // Renders real on-screen window rectangles directly from Hyprland geometry.
    // Guarantees zero ghost/closed windows and accurate multi-window placement.
    if (mode === "float") {
        var monW = (monitor && monitor.lastIpcObject && monitor.lastIpcObject.width) ? monitor.lastIpcObject.width : 1920;
        var monH = (monitor && monitor.lastIpcObject && monitor.lastIpcObject.height) ? monitor.lastIpcObject.height : 1080;
        var monX = (monitor && monitor.lastIpcObject && monitor.lastIpcObject.x !== undefined) ? monitor.lastIpcObject.x : 0;
        var monY = (monitor && monitor.lastIpcObject && monitor.lastIpcObject.y !== undefined) ? monitor.lastIpcObject.y : 0;

        var pad = 12;
        var availW = mapW - pad * 2;
        var availH = mapH - pad * 2;

        var aspect = monW / monH;
        var boxW = availW;
        var boxH = Math.floor(boxW / aspect);
        if (boxH > availH) {
            boxH = availH;
            boxW = Math.floor(boxH * aspect);
        }

        var startX = Math.floor((mapW - boxW) / 2);
        var startY = Math.floor((mapH - boxH) / 2);

        var floatTiles = [];
        if (windows && windows.length > 0) {
            for (var wi = 0; wi < windows.length; wi++) {
                var win = windows[wi];
                if (!win || !win.lastIpcObject) continue;
                var ipc = win.lastIpcObject;
                var wAddr = ipc.address;
                if (!wAddr) continue;

                var wCls = ipc.class || "window";
                var wTitle = ipc.title || "";
                var at = ipc.at || [monX, monY];
                var sz = ipc.size || [monW, monH];

                var relX = Math.max(0, Math.min(1, (at[0] - monX) / monW));
                var relY = Math.max(0, Math.min(1, (at[1] - monY) / monH));
                var relW = Math.max(0.04, Math.min(1, sz[0] / monW));
                var relH = Math.max(0.04, Math.min(1, sz[1] / monH));

                var tx = Math.floor(startX + relX * boxW);
                var ty = Math.floor(startY + relY * boxH);
                var tw = Math.max(30, Math.floor(relW * boxW));
                var th = Math.max(22, Math.floor(relH * boxH));

                if (tx + tw > startX + boxW) tw = Math.max(20, (startX + boxW) - tx);
                if (ty + th > startY + boxH) th = Math.max(16, (startY + boxH) - ty);

                floatTiles.push({
                    address: wAddr,
                    x: tx,
                    y: ty,
                    width: tw,
                    height: th,
                    gx: 0,
                    gy: 0,
                    isActive: (wAddr === activeAddr),
                    appClass: wCls,
                    appTitle: wTitle,
                    color: colorForClass(wCls),
                    slotCount: 1,
                    slotIndex: 0,
                    isFloatSlot: false
                });
            }
        }

        return {
            tiles: floatTiles,
            arrows: [],
            cols: 1,
            rows: 1,
            totalW: boxW,
            totalH: boxH,
            startX: startX,
            startY: startY,
            tileW: 0,
            tileH: 0,
            gapX: 0,
            gapY: 0
        };
    }

    // ── PaperWM and Custom 2D Modes ──────────────────────────────────────────
    // Filter coords to ONLY living windows present on workspace to eliminate ghost/closed apps.
    var liveCoords = {};
    for (var a in coords) {
        if (!windows || windows.length === 0 || winMap[a]) {
            liveCoords[a] = coords[a];
        }
    }

    var bb = boundingBox(liveCoords);
    var cols = Math.max(1, bb.maxX - bb.minX + 1);
    var rows = Math.max(1, bb.maxY - bb.minY + 1);

    var pad = 16;
    var availW = mapW - pad * 2;
    var availH = mapH - pad * 2;

    // Determine tile aspect ratio based on mode
    var tileAspect = (mode === "paper") ? 0.65 : 1.4; // Paper: tall rectangles, Custom: wide landscape
    var tileW = Math.min(80, Math.max(34, Math.floor((availW - (cols - 1) * 8) / cols)));
    var tileH = Math.min(65, Math.max(28, Math.floor(tileW / tileAspect)));

    if (tileH * rows + (rows - 1) * 8 > availH) {
        tileH = Math.min(65, Math.max(24, Math.floor((availH - (rows - 1) * 8) / rows)));
        tileW = Math.min(80, Math.max(30, Math.floor(tileH * tileAspect)));
    }

    var gapX = cols > 1 ? Math.min(20, Math.floor((availW - cols * tileW) / (cols - 1))) : 0;
    var gapY = rows > 1 ? Math.min(16, Math.floor((availH - rows * tileH) / (rows - 1))) : 0;

    var totalW = cols * tileW + (cols - 1) * gapX;
    var totalH = rows * tileH + (rows - 1) * gapY;

    var startX = Math.floor((mapW - totalW) / 2);
    var startY = Math.floor((mapH - totalH) / 2);

    var tiles = [];
    var tileCoordMap = {};
    var slotStack = {};

    var slotCounts = {};
    for (var ca in liveCoords) {
        var cp = liveCoords[ca];
        var ck = cp.x + "," + cp.y;
        slotCounts[ck] = (slotCounts[ck] || 0) + 1;
    }

    for (var addr in liveCoords) {
        var p = liveCoords[addr];
        var colIdx = p.x - bb.minX;
        var rowIdx = p.y - bb.minY;
        var slotKey = p.x + "," + p.y;
        var sIdx = slotStack[slotKey] || 0;
        slotStack[slotKey] = sIdx + 1;

        var tx = startX + colIdx * (tileW + gapX) + sIdx * 5;
        var ty = startY + rowIdx * (tileH + gapY) + sIdx * 5;

        var toplevel = winMap[addr] || null;
        var ipc = toplevel ? toplevel.lastIpcObject : null;
        var cls = (ipc && ipc.class) ? ipc.class : "window";
        var title = (ipc && ipc.title) ? ipc.title : "";

        var isFloatSlot = (slotCounts[slotKey] > 1) || (floatSlots && !!floatSlots[slotKey]);

        var tileObj = {
            address: addr,
            x: tx,
            y: ty,
            width: tileW,
            height: tileH,
            gx: p.x,
            gy: p.y,
            isActive: (addr === activeAddr),
            appClass: cls,
            appTitle: title,
            color: colorForClass(cls),
            slotCount: slotCounts[slotKey] || 1,
            slotIndex: sIdx,
            isFloatSlot: isFloatSlot
        };
        tiles.push(tileObj);
        tileCoordMap[addr] = tileObj;
    }

    // Compute arrow vectors between connected nodes
    var arrows = [];
    if (connections && connections.length) {
        for (var c = 0; c < connections.length; c++) {
            var conn = connections[c];
            var f = tileCoordMap[conn.from];
            var t = tileCoordMap[conn.to];
            if (!f || !t) continue;
            // Skip arrows between windows inside the same slot
            if (conn.dir === "same" || (f.gx === t.gx && f.gy === t.gy)) continue;

            var x1, y1, x2, y2;
            if (conn.dir === "right") {
                x1 = f.x + f.width;
                y1 = f.y + f.height / 2;
                x2 = t.x;
                y2 = t.y + t.height / 2;
            } else if (conn.dir === "left") {
                x1 = f.x;
                y1 = f.y + f.height / 2;
                x2 = t.x + t.width;
                y2 = t.y + t.height / 2;
            } else if (conn.dir === "down") {
                x1 = f.x + f.width / 2;
                y1 = f.y + f.height;
                x2 = t.x + t.width / 2;
                y2 = t.y;
            } else if (conn.dir === "up") {
                x1 = f.x + f.width / 2;
                y1 = f.y;
                x2 = t.x + t.width / 2;
                y2 = t.y + t.height;
            } else {
                continue;
            }

            arrows.push({
                fromAddr: conn.from,
                toAddr: conn.to,
                dir: conn.dir,
                x1: Math.round(x1),
                y1: Math.round(y1),
                x2: Math.round(x2),
                y2: Math.round(y2)
            });
        }
    }

    return {
        tiles: tiles,
        arrows: arrows,
        tileW: tileW,
        tileH: tileH,
        startX: startX,
        startY: startY,
        gapX: gapX,
        gapY: gapY,
        minX: bb.minX,
        minY: bb.minY,
        maxX: bb.maxX,
        maxY: bb.maxY,
        cols: cols,
        rows: rows
    };
}

/**
 * Compute the snapped slot coordinates for a dragged tile on the minimap canvas.
 * - In PaperWM: snaps to sequential strip slot.
 * - In Custom 2D: detects slots, gaps between columns/rows (insertion), and center gaps (middle of 4 apps).
 */
function getSnapTarget(mouseX, mouseY, mapData, mode) {
    if (!mapData || mode === "float") return null;
    var defGapX = mapData.gapX > 0 ? mapData.gapX : 16;
    var defGapY = mapData.gapY > 0 ? mapData.gapY : 16;
    var stepX = mapData.tileW + defGapX;
    var stepY = mapData.tileH + defGapY;

    if (mode === "paper") {
        var isCol = (mapData.orientation === "col");
        var totalTiles = mapData.tiles ? mapData.tiles.length : 1;
        var idx;
        if (isCol) {
            idx = stepY > 0 ? Math.round((mouseY - (mapData.startY + mapData.tileH / 2)) / stepY) : 0;
        } else {
            idx = stepX > 0 ? Math.round((mouseX - (mapData.startX + mapData.tileW / 2)) / stepX) : 0;
        }
        idx = Math.max(0, Math.min(totalTiles - 1, idx));

        var snapPx = isCol ? mapData.startX : (mapData.startX + idx * stepX);
        var snapPy = isCol ? (mapData.startY + idx * stepY) : mapData.startY;

        return {
            index: idx,
            gx: isCol ? 0 : idx,
            gy: isCol ? idx : 0,
            x: Math.round(snapPx),
            y: Math.round(snapPy),
            width: mapData.tileW,
            height: mapData.tileH,
            insertCol: null,
            insertRow: null
        };
    } else {
        // Custom 2D Spatial Tree
        var minX = (typeof mapData.minX === "number" && !isNaN(mapData.minX)) ? mapData.minX : 0;
        var minY = (typeof mapData.minY === "number" && !isNaN(mapData.minY)) ? mapData.minY : 0;
        var cols = Math.max(1, mapData.cols || 1);
        var rows = Math.max(1, mapData.rows || 1);

        var relX = mouseX - mapData.startX;
        var relY = mouseY - mapData.startY;

        var gx, snapX, insertCol = null;
        if (relX < 0) {
            gx = minX - 1;
            snapX = mapData.startX - stepX;
        } else if (relX >= cols * stepX - defGapX) {
            gx = minX + cols;
            snapX = mapData.startX + cols * stepX;
        } else {
            var c = Math.floor(relX / stepX);
            c = Math.max(0, Math.min(cols - 1, c));
            var inTileX = relX - c * stepX;
            // Gap detection between column c and c+1
            if (c < cols - 1 && inTileX >= (mapData.tileW - 6)) {
                insertCol = minX + c + 1;
                var gapCenterX = mapData.startX + c * stepX + mapData.tileW + defGapX / 2;
                snapX = gapCenterX - mapData.tileW / 2;
                gx = insertCol;
            } else {
                gx = minX + c;
                snapX = mapData.startX + c * stepX;
            }
        }

        var gy, snapY, insertRow = null;
        if (relY < 0) {
            gy = minY - 1;
            snapY = mapData.startY - stepY;
        } else if (relY >= rows * stepY - defGapY) {
            gy = minY + rows;
            snapY = mapData.startY + rows * stepY;
        } else {
            var r = Math.floor(relY / stepY);
            r = Math.max(0, Math.min(rows - 1, r));
            var inTileY = relY - r * stepY;
            // Gap detection between row r and r+1
            if (r < rows - 1 && inTileY >= (mapData.tileH - 6)) {
                insertRow = minY + r + 1;
                var gapCenterY = mapData.startY + r * stepY + mapData.tileH + defGapY / 2;
                snapY = gapCenterY - mapData.tileH / 2;
                gy = insertRow;
            } else {
                gy = minY + r;
                snapY = mapData.startY + r * stepY;
            }
        }

        return {
            index: -1,
            gx: gx,
            gy: gy,
            x: Math.round(snapX),
            y: Math.round(snapY),
            width: mapData.tileW,
            height: mapData.tileH,
            insertCol: insertCol,
            insertRow: insertRow
        };
    }
}

/**
 * Move or insert a window into a target grid slot in Custom 2D mode.
 * - If insertCol or insertRow is provided: opens space in the grid (e.g. middle of 4 apps)
 *   and inserts the window smoothly between existing apps.
 * - If target slot is occupied by another window: swaps positions with that window.
 * - If target slot is empty: places window there and connects to nearest neighbor.
 */
function moveOrInsert2D(coords, connections, addr, targetGx, targetGy, insertCol, insertRow, floatSlots) {
    if (!coords || !coords[addr]) return { coords: coords, connections: connections };
    if (!connections) connections = [];

    var curPos = coords[addr];
    var isInserting = (insertCol !== null && insertCol !== undefined) || (insertRow !== null && insertRow !== undefined);

    if (!isInserting && curPos.x === targetGx && curPos.y === targetGy) {
        return { coords: coords, connections: connections };
    }

    var newCoords = {};
    for (var a in coords) {
        newCoords[a] = { x: coords[a].x, y: coords[a].y };
    }
    delete newCoords[addr];

    var newConns = connections.filter(function(c) {
        return c.from !== addr && c.to !== addr;
    });

    if (isInserting) {
        // Shift columns >= insertCol
        if (insertCol !== null && insertCol !== undefined) {
            for (var ca in newCoords) {
                if (newCoords[ca].x >= insertCol) {
                    newCoords[ca].x += 1;
                }
            }
        }
        // Shift rows >= insertRow
        if (insertRow !== null && insertRow !== undefined) {
            for (var ra in newCoords) {
                if (newCoords[ra].y >= insertRow) {
                    newCoords[ra].y += 1;
                }
            }
        }

        var finalGx = (insertCol !== null && insertCol !== undefined) ? insertCol : targetGx;
        var finalGy = (insertRow !== null && insertRow !== undefined) ? insertRow : targetGy;
        newCoords[addr] = { x: finalGx, y: finalGy };

        // Connect addr to nearest adjacent neighbor
        var bestN = null, bestD = 999999, bestDir = "right";
        for (var na in newCoords) {
            if (na === addr) continue;
            var np = newCoords[na];
            var dist = Math.abs(np.x - finalGx) + Math.abs(np.y - finalGy);
            if (dist < bestD) {
                bestD = dist;
                bestN = na;
                if (np.x < finalGx) bestDir = "right";
                else if (np.x > finalGx) bestDir = "left";
                else if (np.y < finalGy) bestDir = "down";
                else bestDir = "up";
            }
        }
        if (bestN) {
            newConns.push({ from: bestN, to: addr, dir: bestDir });
        }

        return compact2D(newCoords, newConns, [], floatSlots);
    }

    // Check occupant at target
    var occupant = findAtCoord(newCoords, targetGx, targetGy);

    if (occupant) {
        // Group into Float Place with occupant at target slot
        newCoords[addr] = { x: targetGx, y: targetGy };
        newConns.push({ from: occupant, to: addr, dir: "same" });
        return compact2D(newCoords, newConns, [], floatSlots);
    } else {
        // Moving to empty slot
        newCoords[addr] = { x: targetGx, y: targetGy };
        var bestEmptyN = null, minEmptyD = 999999, bestEmptyDir = "right";

        for (var ea in newCoords) {
            if (ea === addr) continue;
            var ep = newCoords[ea];
            var eDist = Math.abs(ep.x - targetGx) + Math.abs(ep.y - targetGy);
            if (eDist < minEmptyD) {
                minEmptyD = eDist;
                bestEmptyN = ea;
                if (ep.x < targetGx) bestEmptyDir = "right";
                else if (ep.x > targetGx) bestEmptyDir = "left";
                else if (ep.y < targetGy) bestEmptyDir = "down";
                else bestEmptyDir = "up";
            }
        }

        if (bestEmptyN) {
            newConns.push({ from: bestEmptyN, to: addr, dir: bestEmptyDir });
        }

        return compact2D(newCoords, newConns, [], floatSlots);
    }
}
