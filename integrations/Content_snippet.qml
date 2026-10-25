// ============================================================================
// Caelestia Bar Popouts Content Integration
// Add this entry into ~/.config/quickshell/caelestia/modules/bar/popouts/Content.qml
// inside the Popouts wrapper:
// ============================================================================

import "../../layout"

Popout {
    name: "layoutmap"
    sourceComponent: LayoutMapPopout {
        popouts: root.popouts
    }
}
