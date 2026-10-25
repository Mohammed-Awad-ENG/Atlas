// ============================================================================
// Caelestia Bar.qml Integration
// Add LayoutButton and layout popout handling to:
// ~/.config/quickshell/caelestia/modules/bar/Bar.qml
// ============================================================================

// 1. In Bar.qml import section:
import "../layout"

// 2. In onHoveredChanged handler:
// } else if (id === "layout") {
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
