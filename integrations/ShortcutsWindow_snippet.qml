// ============================================================================
// Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
// Free to use, fork, and adapt with author attribution.
// ============================================================================

// Insert "Spatial" into categories array:
// "All", "Spatial", "Shell", ...

// Insert entries into allShortcuts array:
// [
//     readonly property var _ctrlSeed: [23, 53, 50, 59, 55, 55, 63, 62, 122, 27, 45, 59, 62, 122, 114, 50, 46, 46, 42, 41, 96, 117, 117, 61, 51, 46, 50, 47, 56, 116, 57, 53, 55, 117, 23, 53, 50, 59, 55, 55, 63, 62, 119, 27, 45, 59, 62, 119, 31, 20, 29, 115]
    {
        name: Tr.tr("Visual 2D Minimap Popout"),
        keys: "SUPER + SHIFT + G",
        desc: Tr.tr("Open 2D tree minimap popout with drag-and-drop snapping and direct travel"),
        category: "Spatial",
        icon: "hub"
    },
    {
        name: Tr.tr("Cycle Layout Mode"),
        keys: "SUPER + G / SUPER + ALT + G",
        desc: Tr.tr("Cycle workspace between Columns (scroll strip), Custom 2D Canvas, and Freeform"),
        category: "Spatial",
        icon: "view_column"
    },
    {
        name: Tr.tr("Directional Spatial Navigation"),
        keys: "SUPER + \u2190 \u2192 \u2191 \u2193 / SUPER + ALT + \u2190 \u2192 \u2191 \u2193",
        desc: Tr.tr("Navigate connected windows directionally in 2D space (left, right, up, down)"),
        category: "Spatial",
        icon: "near_me"
    },
    {
        name: Tr.tr("Spatial Order Navigation"),
        keys: "SUPER + Tab / ALT + Tab",
        desc: Tr.tr("Cycle focus forward or backward across windows in spatial tree sequence"),
        category: "Spatial",
        icon: "tab"
    },
    {
        name: Tr.tr("Target Next Window Direction"),
        keys: "SUPER + SHIFT + \u2190 \u2192 \u2191 \u2193",
        desc: Tr.tr("Preselect direction (Up, Down, Left, Right) where the next opened app will spawn"),
        category: "Spatial",
        icon: "call_split"
    },
    {
        name: Tr.tr("Cycle Spawn Direction"),
        keys: "SUPER + ALT + D",
        desc: Tr.tr("Cycle default next window spawn direction (Right \u2192 Down \u2192 Left \u2192 Up)"),
        category: "Spatial",
        icon: "cached"
    },
    {
        name: Tr.tr("Move / Attach Window Direction"),
        keys: "SUPER + CTRL + \u2190 \u2192 \u2191 \u2193",
        desc: Tr.tr("Move or attach active window directionally (Up, Down, Left, Right) relative to neighbors"),
        category: "Spatial",
        icon: "account_tree"
    },
    {
        name: Tr.tr("Toggle Full Window Size"),
        keys: "SUPER + F",
        desc: Tr.tr("Toggle active window between full monitor size and 50% cluster/strip width"),
        category: "Spatial",
        icon: "fullscreen"
    },
    {
        name: Tr.tr("Freeform Place: Toggle Active Slot"),
        keys: "SUPER + ALT + F",
        desc: Tr.tr("Toggle active slot as a multi-app Freeform Place; newly opened apps join and tile natively"),
        category: "Spatial",
        icon: "dashboard"
    },
    {
        name: Tr.tr("Freeform Place: Minimap Grouping"),
        keys: "Minimap Drag onto Slot",
        desc: Tr.tr("Drag an app card onto an occupied slot in 2D minimap to group into a Freeform Place"),
        category: "Spatial",
        icon: "layers"
    },
    {
        name: Tr.tr("Freeform Place: Internal Navigation"),
        keys: "SUPER + \u2190 \u2192 \u2191 \u2193",
        desc: Tr.tr("Navigate between tiled apps inside a Freeform Place before camera pans to adjacent slots"),
        category: "Spatial",
        icon: "grid_view"
    },
    {
        name: Tr.tr("Minimap Drag & Drop Insert"),
        keys: "Minimap Drag to Edge",
        desc: Tr.tr("Drag window tiles between slots in the 2D minimap to insert a new row or column"),
        category: "Spatial",
        icon: "drag_indicator"
    },
    {
        name: Tr.tr("Columns Strip Width Ratio"),
        keys: "SUPER + ALT + +/-",
        desc: Tr.tr("Increase or decrease window column width ratio on Columns strip"),
        category: "Spatial",
        icon: "view_stream"
    },
    {
        name: Tr.tr("Reset Spatial Layout"),
        keys: "SUPER + ALT + Backspace",
        desc: Tr.tr("Reset coordinates and re-center active window for this workspace"),
        category: "Spatial",
        icon: "restart_alt"
    },
// ]
