pragma Singleton

// ============================================================================
// Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
// Free to use, fork, and adapt with author attribution.
// Signature: T3JpZ2luYWwgQXV0aG9yOiBNb2hhbW1lZCBBd2FkIChodHRwczovL2dpdGh1Yi5jb20vTW9oYW1tZWQtQXdhZC1FTkcp
// ============================================================================

import "SpatialCanvas.js" as Spatial
import "LayoutEngine.js" as Engine
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
import Caelestia

/**
 * LayoutState — Per-workspace layout state singleton.
 *
 * Supports:
 * - "paper": PaperWM-style scrollable strip of windows next to each other (row / column).
 * - "custom": 2D Spatial Tree (original window in center, branching UP, DOWN, LEFT, RIGHT).
 * - "float": Standard Hyprland default tiling / floating.
 */
Singleton {
    readonly property string __author_signature: "\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x20\x41\x77\x61\x64\x20\x28\x68\x74\x74\x70\x73\x3a\x2f\x2f\x67\x69\x74\x68\x75\x62\x2e\x63\x6f\x6d\x2f\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x2d\x41\x77\x61\x64\x2d\x45\x4e\x47\x29"
    id: root

    // Map<workspaceId, layoutObj>
    property var workspaceLayouts: ({})
    property int updateTick: 0

    // Map<wsId, direction> ("up", "down", "left", "right", "same")
    property var pendingOpenDirs: ({})

    function setPendingOpenDir(wsId, dir) {
        pendingOpenDirs[wsId] = dir;
        notifyChange();
    }

    function consumePendingDir(wsId) {
        var d = pendingOpenDirs[wsId] || null;
        if (d) {
            delete pendingOpenDirs[wsId];
            return d;
        }
        return null;
    }

    // Interactive Placement Prompt state
    property bool placementPromptActive: false
    property string placementTargetAddr: ""
    property int placementWsId: 1
    property string placementAppClass: ""
    property string placementAppTitle: ""

    function showPlacementPrompt(wsId, addr) {
        if (placementPromptActive) return;
        placementWsId = wsId;
        placementTargetAddr = addr;
        var wins = _managedWindows(wsId);
        var match = wins.find(function(w) { return w.lastIpcObject && w.lastIpcObject.address === addr; });
        if (match && match.lastIpcObject) {
            placementAppClass = match.lastIpcObject.class || "window";
            placementAppTitle = match.lastIpcObject.title || "New Window";
        } else {
            placementAppClass = "window";
            placementAppTitle = "New Window";
        }
        placementPromptActive = true;
    }

    function applyPlacement(dir) {
        if (!placementPromptActive && !placementTargetAddr) return;
        placementPromptActive = false;
        var addr = placementTargetAddr;
        var wsId = placementWsId;
        placementTargetAddr = "";
        if (addr) {
            var layout = getLayout(wsId);
            var curAddr = layout.activeAddr || layout.rootAddr;
            if (layout.mode === "custom" && curAddr && curAddr !== addr && layout.coords[curAddr]) {
                var res = Spatial.attachWindow(layout.coords, layout.connections, curAddr, addr, dir || "same");
                layout.coords = res.coords;
                layout.connections = res.connections;
                layout.activeAddr = addr;
                workspaceLayouts[wsId] = layout;
                notifyChange();
                reapply(wsId);
            } else if (layout.mode === "paper") {
                _ensureWindowPlaced(wsId, addr, dir || "same");
                reapply(wsId);
            }
        }
    }

    function notifyChange() {
        updateTick++;
        workspaceLayouts = Object.assign({}, workspaceLayouts);
    }

    // Active workspace ID on the focused monitor
    readonly property int activeWsId: Hypr.activeWsId

    // Quick accessors for the active workspace
    readonly property string activeMode: {
        root.updateTick;
        return getLayout(activeWsId).mode;
    }
    readonly property var activeCoords: {
        root.updateTick;
        return getLayout(activeWsId).coords || {};
    }
    readonly property var activeConnections: {
        root.updateTick;
        return getLayout(activeWsId).connections || [];
    }
    readonly property string activeAddr: {
        root.updateTick;
        return getLayout(activeWsId).activeAddr || "";
    }
    readonly property string paperOrientation: {
        root.updateTick;
        return getLayout(activeWsId).paperOrientation || "row";
    }
    readonly property real paperWidthRatio: {
        root.updateTick;
        return getLayout(activeWsId).paperWidthRatio || 0.5;
    }
    readonly property string customPreset: {
        root.updateTick;
        return getLayout(activeWsId).customPreset || "half";
    }
    readonly property string nextOpenDir: {
        root.updateTick;
        return getLayout(activeWsId).nextOpenDir || "right";
    }

    // Gap between windows in pixels
    readonly property int gaps: 10

    // ─── Public API ────────────────────────────────────────────────────────────

    /**
     * Get (or create) layout state for a workspace.
     */
    function getLayout(wsId) {
        if (!workspaceLayouts[wsId]) {
            workspaceLayouts[wsId] = {
                mode: "float",
                coords: {},
                connections: [],
                floatSlots: {},
                rootAddr: null,
                activeAddr: null,
                paperOrientation: "row",
                paperWidthRatio: 0.5,
                customPreset: "half",
                nextOpenDir: "right"
            };
        }
        return workspaceLayouts[wsId];
    }

    /**
     * Set mode for a specific workspace ("paper" | "custom" | "float").
     * Supports legacy aliases: "grid" -> "paper", "tree" -> "custom".
     */
    function setMode(wsId, rawMode) {
        var mode = rawMode;
        if (mode === "grid") mode = "paper";
        if (mode === "tree") mode = "custom";

        var layout = getLayout(wsId);
        layout.mode = mode;

        var wins = _managedWindows(wsId);
        var addrs = wins.map(function(w) { return w.lastIpcObject ? w.lastIpcObject.address : ""; }).filter(Boolean);

        if (mode === "float") {
            _unfloatAll(wsId);
            // Prune dead windows from coords and sync activeAddr
            var newCoords = {};
            for (var a = 0; a < addrs.length; a++) {
                if (layout.coords && layout.coords[addrs[a]]) {
                    newCoords[addrs[a]] = layout.coords[addrs[a]];
                }
            }
            layout.coords = newCoords;
            layout.activeAddr = _focusedOrFirstAddr(wsId, addrs);
            workspaceLayouts[wsId] = layout;
            notifyChange();
            return;
        } else if (mode === "paper") {
            var strip = Spatial.initPaperStrip(addrs, layout.paperOrientation);
            layout.coords = strip.coords;
            layout.connections = strip.connections;
            layout.rootAddr = strip.rootAddr;
            layout.activeAddr = _focusedOrFirstAddr(wsId, addrs);
            workspaceLayouts[wsId] = layout;
            notifyChange();
            reapply(wsId);
            return;
        } else if (mode === "custom") {
            var tree = Spatial.initCustom2D(addrs);
            layout.coords = tree.coords;
            layout.connections = tree.connections;
            layout.rootAddr = tree.rootAddr;
            layout.activeAddr = _focusedOrFirstAddr(wsId, addrs);
            workspaceLayouts[wsId] = layout;
            notifyChange();
            reapply(wsId);
            return;
        }

        workspaceLayouts[wsId] = layout;
        notifyChange();
    }

    /**
     * Cycle through modes: float -> paper -> custom -> float.
     */
    function cycleMode(wsId) {
        var cur = getLayout(wsId).mode;
        if      (cur === "float")  setMode(wsId, "paper");
        else if (cur === "paper")  setMode(wsId, "custom");
        else                       setMode(wsId, "float");
    }

    /**
     * Travel to a specific window: pans the canvas to make that window visible,
     * sets it as active, and dispatches focus in Hyprland.
     */
    function travelTo(wsId, targetAddr) {
        if (!targetAddr) return;
        var layout = getLayout(wsId);
        if (layout.mode === "float") {
            _focusOnly(targetAddr);
            return;
        }

        // If window is not in coords yet, add it
        if (!layout.coords[targetAddr]) {
            _ensureWindowPlaced(wsId, targetAddr);
            layout = getLayout(wsId);
        }

        layout.activeAddr = targetAddr;
        workspaceLayouts[wsId] = layout;
        notifyChange();
        reapply(wsId);
    }

    /**
     * Navigate in a direction (up, down, left, right).
     * If a window exists in that direction, travels to it.
     * If no window exists, attaches an unplaced window in that direction.
     */
    function navigate(wsId, direction) {
        var layout = getLayout(wsId);
        if (layout.mode === "float") {
            var nativeDir = direction === "left" ? "l" : (direction === "right" ? "r" : (direction === "up" ? "u" : "d"));
            if (Hypr.usingLua) {
                Hypr.dispatch('hl.dsp.focus({ direction = "' + direction + '" })');
            } else {
                Hypr.dispatch('movefocus ' + nativeDir);
            }
            return;
        }

        var curAddr = layout.activeAddr || _focusedOrFirstAddr(wsId);
        if (!curAddr) return;

        // In Custom 2D: if multiple windows share the current slot (Float Place),
        // try directional navigation among peers inside this slot first
        if (layout.mode === "custom") {
            var curPos = layout.coords[curAddr];
            if (curPos) {
                var peers = [];
                for (var pa in layout.coords) {
                    if (layout.coords[pa].x === curPos.x && layout.coords[pa].y === curPos.y) {
                        peers.push(pa);
                    }
                }
                if (peers.length > 1) {
                    var monitor = Hypr.focusedMonitor;
                    var settings = {
                        customPreset: layout.customPreset,
                        floatSlots: layout.floatSlots || {}
                    };
                    var rects = Spatial.computeScreenRects(layout.mode, monitor, layout.coords, layout.activeAddr, settings, root.gaps);
                    var curR = null;
                    var peerRects = [];
                    for (var ri = 0; ri < rects.length; ri++) {
                        if (rects[ri].address === curAddr) curR = rects[ri];
                        else if (peers.indexOf(rects[ri].address) !== -1) peerRects.push(rects[ri]);
                    }
                    if (curR) {
                        var bestPeer = null;
                        var minPeerDist = 999999;
                        for (var pi = 0; pi < peerRects.length; pi++) {
                            var pr = peerRects[pi];
                            var dx = (pr.x + pr.width / 2) - (curR.x + curR.width / 2);
                            var dy = (pr.y + pr.height / 2) - (curR.y + curR.height / 2);
                            var matchDir = false;
                            if (direction === "right" && dx > 20 && Math.abs(dx) >= Math.abs(dy)) matchDir = true;
                            else if (direction === "left" && dx < -20 && Math.abs(dx) >= Math.abs(dy)) matchDir = true;
                            else if (direction === "down" && dy > 20 && Math.abs(dy) >= Math.abs(dx)) matchDir = true;
                            else if (direction === "up" && dy < -20 && Math.abs(dy) >= Math.abs(dx)) matchDir = true;

                            if (matchDir) {
                                var dist = dx * dx + dy * dy;
                                if (dist < minPeerDist) {
                                    minPeerDist = dist;
                                    bestPeer = pr.address;
                                }
                            }
                        }
                        if (bestPeer) {
                            travelTo(wsId, bestPeer);
                            return;
                        }
                    }
                }
            }
        }

        var neighborAddr = Spatial.getNeighbor(layout.coords, layout.connections, curAddr, direction);
        if (neighborAddr) {
            travelTo(wsId, neighborAddr);
        } else {
            // Find unplaced window in workspace to attach in that direction
            var unplaced = _unplacedAddresses(wsId);
            if (unplaced.length > 0) {
                attach(wsId, direction, unplaced[0]);
            }
        }
    }

    /**
     * Cycle focus sequentially through placed windows/tabs on workspace.
     * forward === true -> next window (SUPER + Tab)
     * forward === false -> prev window (SUPER + SHIFT + Tab)
     */
    function cycleWindow(wsId, forward) {
        var layout = getLayout(wsId);
        var wins = _managedWindows(wsId);
        var liveAddrs = wins.map(function(w) { return w.lastIpcObject ? w.lastIpcObject.address : ""; }).filter(Boolean);
        if (liveAddrs.length === 0) return;

        if (layout.mode === "float") {
            var curA = layout.activeAddr || _focusedOrFirstAddr(wsId);
            var idx = liveAddrs.indexOf(curA);
            var nextIdx = forward ? (idx + 1) % liveAddrs.length : (idx - 1 + liveAddrs.length) % liveAddrs.length;
            _focusOnly(liveAddrs[nextIdx]);
            return;
        }

        // In PaperWM or Custom 2D: sort by spatial position (y asc, then x asc), preserving order in same slot
        var ordered = liveAddrs.slice().sort(function(a, b) {
            var pa = layout.coords[a] || { x: 0, y: 0 };
            var pb = layout.coords[b] || { x: 0, y: 0 };
            if (pa.y !== pb.y) return pa.y - pb.y;
            if (pa.x !== pb.x) return pa.x - pb.x;
            return liveAddrs.indexOf(a) - liveAddrs.indexOf(b);
        });

        var curAddr = layout.activeAddr || _focusedOrFirstAddr(wsId);
        var cIdx = ordered.indexOf(curAddr);
        if (cIdx === -1) cIdx = 0;
        var targetIdx = forward ? (cIdx + 1) % ordered.length : (cIdx - 1 + ordered.length) % ordered.length;
        travelTo(wsId, ordered[targetIdx]);
    }

    /**
     * Cycle next open direction: right -> down -> left -> up -> right.
     */
    function cycleNextOpenDir(wsId) {
        var layout = getLayout(wsId);
        var dirs = ["right", "down", "left", "up"];
        var cur = layout.nextOpenDir || "right";
        var nextIdx = (dirs.indexOf(cur) + 1) % dirs.length;
        layout.nextOpenDir = dirs[nextIdx];
        workspaceLayouts[wsId] = layout;
        notifyChange();
    }

    /**
     * Set next open direction explicitly ("right", "down", "left", "up").
     */
    function setNextOpenDir(wsId, dir) {
        var layout = getLayout(wsId);
        if (["right", "down", "left", "up"].indexOf(dir) !== -1) {
            layout.nextOpenDir = dir;
            workspaceLayouts[wsId] = layout;
            notifyChange();
            Toaster.toast("Spatial Spawn Target", "Next app will spawn: " + dir.toUpperCase(), "call_split");
        }
    }

    /**
     * Attach a window in a specific direction from the currently active window,
     * or move the currently active window in that direction if all windows are placed.
     */
    function attach(wsId, direction, targetAddr) {
        var layout = getLayout(wsId);
        if (layout.mode === "float") return;

        var curAddr = layout.activeAddr || _focusedOrFirstAddr(wsId);
        if (!curAddr) return;

        if (targetAddr) {
            var res = Spatial.attachWindow(layout.coords, layout.connections, curAddr, targetAddr, direction);
            layout.coords = res.coords;
            layout.connections = res.connections;
            layout.activeAddr = targetAddr;
            workspaceLayouts[wsId] = layout;
            notifyChange();
            reapply(wsId);
            return;
        }

        var unplaced = _unplacedAddresses(wsId);
        if (unplaced.length > 0) {
            var newAddr = unplaced[0];
            var resUnplaced = Spatial.attachWindow(layout.coords, layout.connections, curAddr, newAddr, direction);
            layout.coords = resUnplaced.coords;
            layout.connections = resUnplaced.connections;
            layout.activeAddr = newAddr;
            workspaceLayouts[wsId] = layout;
            notifyChange();
            reapply(wsId);
            return;
        }

        // When all windows are placed, attach/move active window in that direction
        if (layout.mode === "paper") {
            var wins = _managedWindows(wsId);
            var liveAddrs = wins.map(function(w) { return w.lastIpcObject ? w.lastIpcObject.address : ""; }).filter(Boolean);
            var isCol = (layout.paperOrientation === "col");
            var strip = liveAddrs.slice().sort(function(a, b) {
                var pa = layout.coords[a] ? (isCol ? layout.coords[a].y : layout.coords[a].x) : 999999;
                var pb = layout.coords[b] ? (isCol ? layout.coords[b].y : layout.coords[b].x) : 999999;
                return pa - pb;
            });
            var curIdx = strip.indexOf(curAddr);
            if (curIdx !== -1) {
                var delta = (direction === "right" || direction === "down") ? 1 : -1;
                var targetIdx = Math.max(0, Math.min(strip.length - 1, curIdx + delta));
                moveWindowToSlot(wsId, curAddr, 0, 0, targetIdx);
            }
        } else if (layout.mode === "custom") {
            var curPos = layout.coords[curAddr] || { x: 0, y: 0 };
            var d = Spatial.DIRS[direction] || Spatial.DIRS["right"];
            var targetGx = curPos.x + d.dx;
            var targetGy = curPos.y + d.dy;
            moveWindowToSlot(wsId, curAddr, targetGx, targetGy);
        }
    }

    /**
     * Set PaperWM width ratio (e.g. 0.5 = 2 windows side-by-side, 1.0 = fullscreen width).
     */
    function setPaperWidthRatio(wsId, ratio) {
        var layout = getLayout(wsId);
        layout.paperWidthRatio = Math.max(0.2, Math.min(1.0, ratio));
        workspaceLayouts[wsId] = layout;
        notifyChange();
        if (layout.mode === "paper") reapply(wsId);
    }

    /**
     * Adjust PaperWM width ratio by delta (e.g. +0.1 or -0.1).
     */
    function adjustPaperWidthRatio(wsId, delta) {
        var layout = getLayout(wsId);
        var cur = layout.paperWidthRatio || 0.5;
        var nextRatio = Math.max(0.2, Math.min(1.0, Math.round((cur + delta) * 10) / 10));
        setPaperWidthRatio(wsId, nextRatio);
    }

    /**
     * Set PaperWM orientation ("row" for horizontal next to each other, "col" for vertical).
     */
    function setPaperOrientation(wsId, orientation) {
        var layout = getLayout(wsId);
        layout.paperOrientation = orientation;
        var wins = _managedWindows(wsId);
        var addrs = wins.map(function(w) { return w.lastIpcObject ? w.lastIpcObject.address : ""; }).filter(Boolean);
        var strip = Spatial.initPaperStrip(addrs, orientation);
        layout.coords = strip.coords;
        layout.connections = strip.connections;
        workspaceLayouts[wsId] = layout;
        notifyChange();
        if (layout.mode === "paper") reapply(wsId);
    }

    /**
     * Set Custom 2D window preset ("half" for cluster view, "full" for focused view).
     */
    function setCustomPreset(wsId, preset) {
        var layout = getLayout(wsId);
        layout.customPreset = preset;
        workspaceLayouts[wsId] = layout;
        notifyChange();
        if (layout.mode === "custom") reapply(wsId);
    }

    /**
     * Move or insert a window to a target grid slot in Custom 2D mode,
     * or to a target index in PaperWM mode. Snaps into place and reapplies layout.
     */
    function moveWindowToSlot(wsId, addr, targetGx, targetGy, targetIndex, insertCol, insertRow) {
        if (!addr) return;
        var layout = getLayout(wsId);
        if (layout.mode === "float") return;

        var wins = _managedWindows(wsId);
        var liveAddrs = wins.map(function(w) { return w.lastIpcObject ? w.lastIpcObject.address : ""; }).filter(Boolean);

        if (layout.mode === "paper") {
            var isCol = (layout.paperOrientation === "col");
            // 1. Current strip order based on coordinates
            var strip = liveAddrs.slice().sort(function(a, b) {
                var pa = layout.coords[a] ? (isCol ? layout.coords[a].y : layout.coords[a].x) : 999999;
                var pb = layout.coords[b] ? (isCol ? layout.coords[b].y : layout.coords[b].x) : 999999;
                return pa - pb;
            });

            var curIdx = strip.indexOf(addr);
            if (curIdx === -1) return;

            // Remove addr from old position
            strip.splice(curIdx, 1);

            // Clamp targetIndex and insert
            var insertAt = Math.max(0, Math.min(strip.length, targetIndex));
            strip.splice(insertAt, 0, addr);

            // Re-assign sequential coordinates and connections directly from strip
            var newCoords = {};
            var newConns = [];
            for (var idx = 0; idx < strip.length; idx++) {
                var winAddr = strip[idx];
                newCoords[winAddr] = isCol ? { x: 0, y: idx } : { x: idx, y: 0 };
                if (idx > 0) {
                    newConns.push({
                        from: strip[idx - 1],
                        to: winAddr,
                        dir: isCol ? "down" : "right"
                    });
                }
            }

            layout.coords = newCoords;
            layout.connections = newConns;
            layout.activeAddr = addr;
            workspaceLayouts[wsId] = layout;
            notifyChange();
            reapply(wsId);
            return;
        }

        if (layout.mode === "custom") {
            var res = Spatial.moveOrInsert2D(layout.coords, layout.connections, addr, targetGx, targetGy, insertCol, insertRow, layout.floatSlots);
            layout.coords = res.coords;
            layout.connections = res.connections;
            layout.activeAddr = addr;

            // Track float slots: if slot has multiple windows, mark as a Float Place
            layout.floatSlots = layout.floatSlots || {};
            var targetSlotKey = targetGx + "," + targetGy;
            var targetCount = 0;
            for (var tca in layout.coords) {
                if (layout.coords[tca].x === targetGx && layout.coords[tca].y === targetGy) {
                    targetCount++;
                }
            }
            if (targetCount > 1) {
                layout.floatSlots[targetSlotKey] = true;
            }

            // Clean up slots that now have <= 1 window
            for (var fs in layout.floatSlots) {
                var fparts = fs.split(",");
                var fx = parseInt(fparts[0], 10), fy = parseInt(fparts[1], 10);
                var fCount = 0;
                for (var fca in layout.coords) {
                    if (layout.coords[fca].x === fx && layout.coords[fca].y === fy) fCount++;
                }
                if (fCount <= 1) {
                    delete layout.floatSlots[fs];
                }
            }

            workspaceLayouts[wsId] = layout;
            notifyChange();
            reapply(wsId);
        }
    }

    /**
     * Toggle active slot as a Float Place ("like Float (Native)").
     * In Custom 2D mode, allows multiple apps to co-exist in this slot
     * tiled natively (dwindle) inside the 100% monitor view.
     */
    function toggleSlotFloat(wsId) {
        var layout = getLayout(wsId);
        if (layout.mode !== "custom") return;

        var curAddr = layout.activeAddr || _focusedOrFirstAddr(wsId);
        if (!curAddr || !layout.coords[curAddr]) return;

        var pos = layout.coords[curAddr];
        var slotKey = pos.x + "," + pos.y;
        layout.floatSlots = layout.floatSlots || {};

        var isCurrentlyFloat = !!layout.floatSlots[slotKey];
        if (!isCurrentlyFloat) {
            layout.floatSlots[slotKey] = true;
            workspaceLayouts[wsId] = layout;
            notifyChange();
            Toaster.toast("Float Slot Enabled", "Slot (" + pos.x + ", " + pos.y + ") is now a Float Place. Apps placed here tile natively.", "dashboard");
        } else {
            delete layout.floatSlots[slotKey];
            var winsInSlot = [];
            for (var a in layout.coords) {
                if (layout.coords[a].x === pos.x && layout.coords[a].y === pos.y) {
                    winsInSlot.push(a);
                }
            }
            if (winsInSlot.length > 1) {
                for (var wi = 0; wi < winsInSlot.length; wi++) {
                    var wAddr = winsInSlot[wi];
                    if (wAddr !== curAddr) {
                        var targetX = pos.x + wi;
                        while (Spatial.findAtCoord(layout.coords, targetX, pos.y)) {
                            targetX++;
                        }
                        layout.coords[wAddr] = { x: targetX, y: pos.y };
                        layout.connections.push({ from: curAddr, to: wAddr, dir: "right" });
                    }
                }
            }
            workspaceLayouts[wsId] = layout;
            notifyChange();
            Toaster.toast("Float Slot Disabled", "Slot (" + pos.x + ", " + pos.y + ") returned to single-window view", "fullscreen");
        }
        reapply(wsId);
    }

    /**
     * Toggle full window size for the focused window in current mode:
     * - In custom 2D mode: toggles between "half" (50%) and "full" (100% monitor size).
     * - In paper mode: toggles between 0.5 (half width) and 1.0 (full width).
     * - In float mode: toggles Hyprland fullscreen.
     */
    function toggleFull(wsId) {
        var layout = getLayout(wsId);
        if (layout.mode === "custom") {
            var curPreset = layout.customPreset || "half";
            setCustomPreset(wsId, curPreset === "full" ? "half" : "full");
        } else if (layout.mode === "paper") {
            var curRatio = layout.paperWidthRatio || 0.5;
            setPaperWidthRatio(wsId, curRatio >= 0.9 ? 0.5 : 1.0);
        } else {
            if (Hypr.usingLua) {
                Hypr.dispatch('hl.dsp.window.fullscreen()');
            } else {
                Hypr.dispatch('fullscreen 0');
            }
        }
    }

    /**
     * Reset layout for a workspace.
     */
    function resetLayout(wsId) {
        var layout = getLayout(wsId);
        var curMode = layout.mode;
        layout.coords = {};
        layout.connections = [];
        layout.rootAddr = null;
        layout.activeAddr = null;
        workspaceLayouts[wsId] = layout;
        notifyChange();
        setMode(wsId, curMode);
    }

    property bool isApplying: false

    /**
     * Reapply window positions for a workspace.
     */
    function reapply(wsId) {
        if (isApplying) return;
        isApplying = true;
        try {
            var layout = getLayout(wsId);
            if (layout.mode === "float") return;

            _syncWindows(wsId);
            layout = getLayout(wsId);

            var monitor = Hypr.focusedMonitor;
            var settings = {
                orientation: layout.paperOrientation,
                widthRatio: layout.paperWidthRatio,
                customPreset: layout.customPreset,
                floatSlots: layout.floatSlots || {}
            };

            var rects = Spatial.computeScreenRects(layout.mode, monitor, layout.coords, layout.activeAddr, settings, root.gaps);
            var wins = _managedWindows(wsId);
            var fMap = {};
            for (var i = 0; i < wins.length; i++) {
                var w = wins[i];
                if (w.lastIpcObject) {
                    fMap[w.lastIpcObject.address] = !!w.lastIpcObject.floating;
                }
            }
            Engine.applySpatial(rects, layout.activeAddr, fMap, Hypr.usingLua, function(cmd) {
                Hypr.dispatch(cmd);
            });
        } finally {
            isApplying = false;
        }
    }

    // ─── Private Helpers ───────────────────────────────────────────────────────

    function _managedWindows(wsId) {
        var toplevels = Hypr.toplevelsForWs(wsId);
        return toplevels.filter(function(w) {
            if (!w || !w.lastIpcObject) return false;
            var cls = w.lastIpcObject.class || "";
            var title = w.lastIpcObject.title || "";
            if (cls === "org.quickshell" || title.indexOf("Caelestia") !== -1) return false;
            return true;
        });
    }

    function _focusedOrFirstAddr(wsId, optionalAddrs) {
        var focused = Hypr.activeToplevel;
        if (focused && focused.lastIpcObject && focused.workspace && focused.workspace.id === wsId) {
            return focused.lastIpcObject.address;
        }
        var addrs = optionalAddrs;
        if (!addrs) {
            var wins = _managedWindows(wsId);
            addrs = wins.map(function(w) { return w.lastIpcObject ? w.lastIpcObject.address : ""; }).filter(Boolean);
        }
        return addrs[0] || null;
    }

    function _unplacedAddresses(wsId) {
        var layout = getLayout(wsId);
        var wins = _managedWindows(wsId);
        var allAddrs = wins.map(function(w) { return w.lastIpcObject ? w.lastIpcObject.address : ""; }).filter(Boolean);
        return allAddrs.filter(function(a) { return !layout.coords[a]; });
    }

    function _ensureWindowPlaced(wsId, addr, chosenDir) {
        var layout = getLayout(wsId);
        if (layout.coords[addr]) return;

        var curA = layout.activeAddr || layout.rootAddr;
        var curPos = (curA && layout.coords[curA]) ? layout.coords[curA] : { x: 0, y: 0 };
        var curSlotKey = curPos.x + "," + curPos.y;

        var defaultFallback = (layout.mode === "paper")
            ? (layout.paperOrientation === "col" ? "down" : "right")
            : (layout.nextOpenDir || "right");

        var dir = chosenDir || consumePendingDir(wsId);
        if (!dir) {
            if (layout.mode === "custom" && layout.floatSlots && layout.floatSlots[curSlotKey]) {
                dir = "same";
            } else {
                dir = defaultFallback;
            }
        }

        if (layout.mode === "paper") {
            var curA = layout.activeAddr || layout.rootAddr;
            var curPos = (curA && layout.coords[curA]) ? layout.coords[curA] : { x: 0, y: 0 };
            var isCol = (layout.paperOrientation === "col");

            if (dir === "same") {
                layout.coords[addr] = { x: curPos.x, y: curPos.y };
                if (curA && curA !== addr) {
                    layout.connections.push({ from: curA, to: addr, dir: "same" });
                }
            } else if (dir === "left" || dir === "up") {
                var shiftKey = isCol ? "y" : "x";
                var insertVal = curPos[shiftKey];
                for (var ca in layout.coords) {
                    if (layout.coords[ca][shiftKey] >= insertVal) {
                        layout.coords[ca][shiftKey] += 1;
                    }
                }
                layout.coords[addr] = isCol ? { x: 0, y: insertVal } : { x: insertVal, y: 0 };
                if (curA && curA !== addr) {
                    layout.connections.push({ from: curA, to: addr, dir: dir });
                }
            } else {
                var shiftKey2 = isCol ? "y" : "x";
                var insertVal2 = curPos[shiftKey2] + 1;
                for (var ca2 in layout.coords) {
                    if (layout.coords[ca2][shiftKey2] >= insertVal2) {
                        layout.coords[ca2][shiftKey2] += 1;
                    }
                }
                layout.coords[addr] = isCol ? { x: 0, y: insertVal2 } : { x: insertVal2, y: 0 };
                if (curA && curA !== addr) {
                    layout.connections.push({ from: curA, to: addr, dir: dir });
                }
            }
        } else if (layout.mode === "custom") {
            var curAddr = layout.activeAddr || layout.rootAddr;
            if (curAddr && layout.coords[curAddr]) {
                var res = Spatial.attachWindow(layout.coords, layout.connections, curAddr, addr, dir);
                layout.coords = res.coords;
                layout.connections = res.connections;
            } else {
                layout.coords[addr] = { x: 0, y: 0 };
                layout.rootAddr = addr;
            }
        }
        layout.activeAddr = addr;
        workspaceLayouts[wsId] = layout;
        notifyChange();
    }

    function _syncWindows(wsId) {
        var layout = getLayout(wsId);
        if (layout.mode === "float") return;

        var wins = _managedWindows(wsId);
        var liveAddrs = wins.map(function(w) { return w.lastIpcObject ? w.lastIpcObject.address : ""; }).filter(Boolean);

        // Track previous active window and its coordinates before removals
        var oldActiveAddr = layout.activeAddr;
        var oldActivePos = (oldActiveAddr && layout.coords[oldActiveAddr])
            ? { x: layout.coords[oldActiveAddr].x, y: layout.coords[oldActiveAddr].y }
            : null;
        var oldConnections = layout.connections ? layout.connections.slice() : [];

        // Find closed/removed windows
        var removed = [];
        for (var addr in layout.coords) {
            if (liveAddrs.indexOf(addr) === -1) {
                removed.push(addr);
            }
        }

        var changed = (removed.length > 0);

        if (layout.mode === "paper") {
            // For PaperWM: clean, contiguous, gapless re-index
            var strip = Spatial.normalizePaperStrip(layout.coords, layout.connections, layout.paperOrientation, liveAddrs);
            layout.coords = strip.coords;
            layout.connections = strip.connections;
            if (liveAddrs.length > 0 && (!layout.rootAddr || liveAddrs.indexOf(layout.rootAddr) === -1)) {
                layout.rootAddr = liveAddrs[0];
            }
        } else if (layout.mode === "custom") {
            // For Custom 2D: re-stitch connections and compact gaps along all axes
            var res = Spatial.compact2D(layout.coords, layout.connections, removed, layout.floatSlots);
            layout.coords = res.coords;
            layout.connections = res.connections;
            if (liveAddrs.length > 0 && (!layout.rootAddr || liveAddrs.indexOf(layout.rootAddr) === -1)) {
                layout.rootAddr = liveAddrs[0];
            }
        }

        // Add newly opened windows that aren't placed yet
        for (var i = 0; i < liveAddrs.length; i++) {
            var a = liveAddrs[i];
            if (!layout.coords[a]) {
                var pending = consumePendingDir(wsId);
                _ensureWindowPlaced(wsId, a, pending);
                changed = true;
            }
        }

        // Ensure activeAddr is valid.
        // If the active window was closed, focus moves to the spatially closest remaining window!
        if (!layout.activeAddr || liveAddrs.indexOf(layout.activeAddr) === -1) {
            if (liveAddrs.length === 0) {
                layout.activeAddr = null;
            } else if (oldActivePos) {
                var bestAddr = liveAddrs[0];
                var minDistance = 99999999;
                for (var li = 0; li < liveAddrs.length; li++) {
                    var lAddr = liveAddrs[li];
                    var lPos = layout.coords[lAddr];
                    if (lPos) {
                        var dx = lPos.x - oldActivePos.x;
                        var dy = lPos.y - oldActivePos.y;
                        var dist = dx * dx + dy * dy;
                        var wasDirectlyConnected = oldConnections.some(function(c) {
                            return (c.from === oldActiveAddr && c.to === lAddr) || (c.to === oldActiveAddr && c.from === lAddr);
                        });
                        if (dist < minDistance || (dist === minDistance && wasDirectlyConnected)) {
                            minDistance = dist;
                            bestAddr = lAddr;
                        }
                    }
                }
                layout.activeAddr = bestAddr;
            } else {
                layout.activeAddr = liveAddrs[0];
            }
            changed = true;
        }

        if (changed) {
            workspaceLayouts[wsId] = layout;
            notifyChange();
        }
    }

    function _unfloatAll(wsId) {
        var wins = _managedWindows(wsId);
        Engine.unfloatAll(wins, Hypr.usingLua, function(cmd) { Hypr.dispatch(cmd); });
    }

    function _focusOnly(addr) {
        if (!addr) return;
        if (Hypr.usingLua) {
            Hypr.dispatch('hl.dsp.focus({ window = "address:' + addr + '" })');
        } else {
            Hypr.dispatch("focuswindow address:" + addr);
        }
    }

    // ─── Workspace Switch & Window Event Listeners ───────────────────────────

    onActiveWsIdChanged: {
        var layout = root.getLayout(root.activeWsId);
        if (layout.mode !== "float") {
            reapplyTimer.restart();
        }
    }

    Timer {
        id: reapplyTimer
        interval: 50
        repeat: false
        onTriggered: {
            var layout = root.getLayout(root.activeWsId);
            if (layout.mode !== "float") {
                root.reapply(root.activeWsId);
            } else {
                root.notifyChange();
            }
        }
    }

    Connections {
        target: Hyprland

        function onActiveToplevelChanged() {
            if (root.isApplying) return;
            var focused = Hypr.activeToplevel;
            if (!focused || !focused.lastIpcObject) return;
            var ws = (focused.workspace && focused.workspace.id) ? focused.workspace.id : root.activeWsId;
            var addr = focused.lastIpcObject.address;
            var cls = focused.lastIpcObject.class || "";
            var title = focused.lastIpcObject.title || "";
            if (cls === "org.quickshell" || title.indexOf("Caelestia") !== -1) return;

            var layout = root.getLayout(ws);
            if (layout.mode === "float") {
                if (layout.activeAddr !== addr) {
                    layout.activeAddr = addr;
                    root.workspaceLayouts[ws] = layout;
                    root.notifyChange();
                }
                return;
            }
            if (layout.coords && layout.coords[addr] && layout.activeAddr !== addr) {
                layout.activeAddr = addr;
                root.workspaceLayouts[ws] = layout;
                root.notifyChange();
            }
        }

        function onRawEvent(event) {
            if (root.isApplying) return;
            var n = event.name;
            if (["openwindow", "closewindow"].includes(n)) {
                reapplyTimer.restart();
            }
        }
    }
}
