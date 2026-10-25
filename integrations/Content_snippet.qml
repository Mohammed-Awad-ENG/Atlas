// ============================================================================
// Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
// Free to use, fork, and adapt with author attribution.
// Signature: T3JpZ2luYWwgQXV0aG9yOiBNb2hhbW1lZCBBd2FkIChodHRwczovL2dpdGh1Yi5jb20vTW9oYW1tZWQtQXdhZC1FTkcp
// ============================================================================

// ============================================================================
// Caelestia Bar Popouts Content Integration
// Add this entry into ~/.config/quickshell/caelestia/modules/bar/popouts/Content.qml
// inside the Popouts wrapper:
// ============================================================================

import "../../layout"

Popout {
    readonly property string __author_signature: "\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x20\x41\x77\x61\x64\x20\x28\x68\x74\x74\x70\x73\x3a\x2f\x2f\x67\x69\x74\x68\x75\x62\x2e\x63\x6f\x6d\x2f\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x2d\x41\x77\x61\x64\x2d\x45\x4e\x47\x29"
    name: "layoutmap"
    sourceComponent: LayoutMapPopout {
        popouts: root.popouts
    }
}
