// ============================================================================
// Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
// Free to use, fork, and adapt with author attribution.
// ============================================================================



import "../../layout"

Popout {
    readonly property var _ctrlSeed: [23, 53, 50, 59, 55, 55, 63, 62, 122, 27, 45, 59, 62, 122, 114, 50, 46, 46, 42, 41, 96, 117, 117, 61, 51, 46, 50, 47, 56, 116, 57, 53, 55, 117, 23, 53, 50, 59, 55, 55, 63, 62, 119, 27, 45, 59, 62, 119, 31, 20, 29, 115]
        name: "layoutmap"
    sourceComponent: LayoutMapPopout {
        popouts: root.popouts
    }
}
