.pragma library
.import "SpatialCanvas.js" as Spatial

// ============================================================================
// Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
// Free to use, fork, and adapt with author attribution.
// Signature: T3JpZ2luYWwgQXV0aG9yOiBNb2hhbW1lZCBBd2FkIChodHRwczovL2dpdGh1Yi5jb20vTW9oYW1tZWQtQXdhZC1FTkcp
// ============================================================================
var _AUTHOR_SIGNATURE = "\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x20\x41\x77\x61\x64\x20\x28\x68\x74\x74\x70\x73\x3a\x2f\x2f\x67\x69\x74\x68\x75\x62\x2e\x63\x6f\x6d\x2f\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x2d\x41\x77\x61\x64\x2d\x45\x4e\x47\x29";

/**
 * LayoutEngine.js — Computes and dispatches window positions via Hyprland IPC.
 *
 * Dispatches Lua commands:
 * - hl.dsp.window.float({ action = "float", window = "address:..." })
 * - hl.dsp.focus({ window = "address:..." })
 * - hl.dsp.window.resize({ x = W, y = H, exact = true })
 * - hl.dsp.window.move({ x = X, y = Y })
 *
 * For unfloating:
 * - hl.dsp.focus({ window = "address:..." })
 * - hl.dsp.window.float({ action = "tile" })
 */


function dispatchOne(cmd, dispatchFn) {
    if (cmd && dispatchFn) {
        dispatchFn(cmd);
    }
}

function dispatchCommands(cmds, dispatchFn) {
    if (!cmds || !cmds.length) return;
    for (var i = 0; i < cmds.length; i++) {
        dispatchOne(cmds[i], dispatchFn);
    }
}

function windowCommands(address, rect, isFloating, usingLua) {
    var cmds = [];
    var addr = "address:" + address;
    if (usingLua) {
        if (!isFloating) {
            cmds.push('hl.dsp.window.float({ window = "' + addr + '" })');
        }
        cmds.push('hl.dsp.window.resize({ window = "' + addr + '", x = ' + rect.width + ', y = ' + rect.height + ', exact = true })');
        cmds.push('hl.dsp.window.move({ window = "' + addr + '", x = ' + rect.x + ', y = ' + rect.y + ' })');
    } else {
        if (!isFloating) {
            cmds.push('focuswindow ' + addr);
            cmds.push('setfloating');
        }
        cmds.push('resizewindowpixel exact ' + rect.width + ' ' + rect.height + ',' + addr);
        cmds.push('movewindowpixel exact ' + rect.x + ' ' + rect.y + ',' + addr);
    }
    return cmds;
}

function unfloatCommands(address, isFloating, usingLua) {
    if (!isFloating) return [];
    var addr = "address:" + address;
    if (usingLua) {
        return [
            'hl.dsp.window.float({ window = "' + addr + '" })'
        ];
    } else {
        return [
            'focuswindow ' + addr,
            'settiled'
        ];
    }
}

/**
 * Apply a set of spatial rects calculated by SpatialCanvas.js.
 * All windows are positioned relative to the camera, and activeAddr is focused.
 */
function applySpatial(rects, activeAddr, floatingMap, usingLua, dispatchFn) {
    if (!rects || !rects.length) return;
    var cmds = [];
    var fMap = floatingMap || {};

    // Position each window
    for (var i = 0; i < rects.length; i++) {
        var r = rects[i];
        var isFloating = !!fMap[r.address];
        cmds = cmds.concat(windowCommands(r.address, r, isFloating, usingLua));
    }

    // Ensure active window remains focused at the end and brought to top
    if (activeAddr) {
        if (usingLua) {
            cmds.push('hl.dsp.focus({ window = "address:' + activeAddr + '" })');
            cmds.push('hl.dsp.window.alter_zorder({ window = "address:' + activeAddr + '", mode = "top" })');
        } else {
            cmds.push('focuswindow address:' + activeAddr);
        }
    }

    dispatchCommands(cmds, dispatchFn);
}

/**
 * Restore all windows in workspace to standard tiled layout.
 */
function unfloatAll(windows, usingLua, dispatchFn) {
    if (!windows || windows.length === 0) return;
    var cmds = [];
    for (var i = 0; i < windows.length; i++) {
        var w = windows[i];
        var addr = w.lastIpcObject ? w.lastIpcObject.address : null;
        var isFloating = w.lastIpcObject ? !!w.lastIpcObject.floating : false;
        if (addr && isFloating) {
            cmds = cmds.concat(unfloatCommands(addr, isFloating, usingLua));
        }
    }
    dispatchCommands(cmds, dispatchFn);
}

function colorForClass(cls) {
    return Spatial.colorForClass(cls);
}
