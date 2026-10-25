// ============================================================================
// Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
// Free to use, fork, and adapt with author attribution.
// Signature: T3JpZ2luYWwgQXV0aG9yOiBNb2hhbW1lZCBBd2FkIChodHRwczovL2dpdGh1Yi5jb20vTW9oYW1tZWQtQXdhZC1FTkcp
// ============================================================================

// ============================================================================
// Caelestia Layout Shortcuts & IPC Integration
// Add these declarations into ~/.config/quickshell/caelestia/modules/Shortcuts.qml
// ============================================================================

import "./layout"

// ── Custom Shortcuts ────────────────────────────────────────────────────────

CustomShortcut {
    readonly property string __author_signature: "\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x20\x41\x77\x61\x64\x20\x28\x68\x74\x74\x70\x73\x3a\x2f\x2f\x67\x69\x74\x68\x75\x62\x2e\x63\x6f\x6d\x2f\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x2d\x41\x77\x61\x64\x2d\x45\x4e\x47\x29"
    name: "layout"
    description: "Cycle window layout (float -> paper -> custom)"
    onPressed: LayoutState.cycleMode(Hypr.activeWsId)
}

CustomShortcut {
    name: "layoutMap"
    description: "Toggle 2D visual layout map popout"
    onPressed: {
        const comps = ShellState.componentsForActive();
        const popouts = comps?.bar?.popouts;
        if (popouts) {
            if (popouts.hasCurrent && popouts.currentName === "layoutmap") {
                popouts.hasCurrent = false;
            } else {
                popouts.currentName = "layoutmap";
                if (!popouts.currentCenter || popouts.currentCenter < 50) {
                    popouts.currentCenter = (comps.bar?.height ?? 900) * 0.45;
                }
                popouts.hasCurrent = true;
            }
        }
    }
}

CustomShortcut {
    name: "layoutNavUp"
    description: "Navigate spatial tree up"
    onPressed: LayoutState.navigate(Hypr.activeWsId, "up")
}

CustomShortcut {
    name: "layoutNavDown"
    description: "Navigate spatial tree down"
    onPressed: LayoutState.navigate(Hypr.activeWsId, "down")
}

CustomShortcut {
    name: "layoutNavLeft"
    description: "Navigate spatial tree left"
    onPressed: LayoutState.navigate(Hypr.activeWsId, "left")
}

CustomShortcut {
    name: "layoutNavRight"
    description: "Navigate spatial tree right"
    onPressed: LayoutState.navigate(Hypr.activeWsId, "right")
}

CustomShortcut {
    name: "layoutCycleWindow"
    description: "Cycle focus forward in spatial sequence"
    onPressed: LayoutState.cycleWindow(Hypr.activeWsId, true)
}

CustomShortcut {
    name: "layoutCycleWindowPrev"
    description: "Cycle focus backward in spatial sequence"
    onPressed: LayoutState.cycleWindow(Hypr.activeWsId, false)
}

CustomShortcut {
    name: "layoutCycleDir"
    description: "Cycle default window spawn direction"
    onPressed: LayoutState.cycleNextOpenDir(Hypr.activeWsId)
}

CustomShortcut {
    name: "layoutToggleFull"
    description: "Toggle full window size"
    onPressed: LayoutState.toggleFull(Hypr.activeWsId)
}

CustomShortcut {
    name: "layoutSetDirUp"
    description: "Set next window spawn direction up"
    onPressed: LayoutState.setNextOpenDir(Hypr.activeWsId, "up")
}

CustomShortcut {
    name: "layoutSetDirDown"
    description: "Set next window spawn direction down"
    onPressed: LayoutState.setNextOpenDir(Hypr.activeWsId, "down")
}

CustomShortcut {
    name: "layoutSetDirLeft"
    description: "Set next window spawn direction left"
    onPressed: LayoutState.setNextOpenDir(Hypr.activeWsId, "left")
}

CustomShortcut {
    name: "layoutSetDirRight"
    description: "Set next window spawn direction right"
    onPressed: LayoutState.setNextOpenDir(Hypr.activeWsId, "right")
}

CustomShortcut {
    name: "layoutAttachUp"
    description: "Attach window up"
    onPressed: LayoutState.attach(Hypr.activeWsId, "up")
}

CustomShortcut {
    name: "layoutAttachDown"
    description: "Attach window down"
    onPressed: LayoutState.attach(Hypr.activeWsId, "down")
}

CustomShortcut {
    name: "layoutAttachLeft"
    description: "Attach window left"
    onPressed: LayoutState.attach(Hypr.activeWsId, "left")
}

CustomShortcut {
    name: "layoutAttachRight"
    description: "Attach window right"
    onPressed: LayoutState.attach(Hypr.activeWsId, "right")
}

CustomShortcut {
    name: "layoutReset"
    description: "Reset spatial layout"
    onPressed: LayoutState.resetLayout(Hypr.activeWsId)
}

CustomShortcut {
    name: "layoutPaperWiden"
    description: "Increase PaperWM strip width"
    onPressed: LayoutState.adjustPaperWidthRatio(Hypr.activeWsId, 0.1)
}

CustomShortcut {
    name: "layoutPaperNarrow"
    description: "Decrease PaperWM strip width"
    onPressed: LayoutState.adjustPaperWidthRatio(Hypr.activeWsId, -0.1)
}

CustomShortcut {
    name: "layoutToggleSlotFloat"
    description: "Toggle active slot as a Float Place (multi-app native dwindle)"
    onPressed: LayoutState.toggleSlotFloat(Hypr.activeWsId)
}

// ── IPC Handler ─────────────────────────────────────────────────────────────

IpcHandler {
    target: "layout"

    function cycle(): void {
        LayoutState.cycleMode(Hypr.activeWsId);
    }

    function set(mode: string): void {
        LayoutState.setMode(Hypr.activeWsId, mode);
    }

    function navigate(dir: string): void {
        LayoutState.navigate(Hypr.activeWsId, dir);
    }

    function attach(dir: string): void {
        LayoutState.attach(Hypr.activeWsId, dir);
    }

    function travel(addr: string): void {
        LayoutState.travelTo(Hypr.activeWsId, addr);
    }

    function setPaper(orientation: string, widthRatio: real): void {
        LayoutState.setPaperOrientation(Hypr.activeWsId, orientation);
        if (widthRatio > 0) LayoutState.setPaperWidthRatio(Hypr.activeWsId, widthRatio);
    }

    function adjustPaper(delta: real): void {
        LayoutState.adjustPaperWidthRatio(Hypr.activeWsId, delta);
    }

    function reset(): void {
        LayoutState.resetLayout(Hypr.activeWsId);
    }

    function cycleDir(): void {
        LayoutState.cycleNextOpenDir(Hypr.activeWsId);
    }

    function cycleWindow(forward: bool): void {
        LayoutState.cycleWindow(Hypr.activeWsId, forward);
    }

    function setDir(dir: string): void {
        LayoutState.setNextOpenDir(Hypr.activeWsId, dir);
    }

    function toggleSlotFloat(): void {
        LayoutState.toggleSlotFloat(Hypr.activeWsId);
    }
}
