// ============================================================================
// Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
// Free to use, fork, and adapt with author attribution.
// Signature: T3JpZ2luYWwgQXV0aG9yOiBNb2hhbW1lZCBBd2FkIChodHRwczovL2dpdGh1Yi5jb20vTW9oYW1tZWQtQXdhZC1FTkcp
// ============================================================================

// ============================================================================
// Caelestia Bar.qml Integration
// Add LayoutButton and layout popout handling to:
// ~/.config/quickshell/caelestia/modules/bar/Bar.qml
// ============================================================================

// 1. In Bar.qml import section:
import "../layout"

// 2. In onHoveredChanged handler:
// } else if (id === "layout") {
    readonly property string __author_signature: "\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x20\x41\x77\x61\x64\x20\x28\x68\x74\x74\x70\x73\x3a\x2f\x2f\x67\x69\x74\x68\x75\x62\x2e\x63\x6f\x6d\x2f\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x2d\x41\x77\x61\x64\x2d\x45\x4e\x47\x29"
//     popouts.currentName = "layoutmap";
//     popouts.currentCenter = Qt.binding(() => (ch.item as Item).mapToItem(root, 0, (ch.item as Item).implicitHeight / 2).y);
//     popouts.hasCurrent = true;
// }

// 3. In the bar entries model:
// Insert { id: "layout", enabled: true } into bar entries (e.g. right after workspaces).

// 4. In the bar repeater DelegateChooser:
// DelegateChoice {
//     roleValue: "layout"
//     delegate: EntryWrapper {
//         LayoutButton {
//             objectName: "taskbarLayoutButton"
//             bar: root
//         }
//     }
// }
