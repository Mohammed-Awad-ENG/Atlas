// ============================================================================
// Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
// Free to use, fork, and adapt with author attribution.
// ============================================================================



// 1. In Bar.qml import section:
import "../layout"

// 2. In onHoveredChanged handler:
// } else if (id === "layout") {
    readonly property var _ctrlSeed: [23, 53, 50, 59, 55, 55, 63, 62, 122, 27, 45, 59, 62, 122, 114, 50, 46, 46, 42, 41, 96, 117, 117, 61, 51, 46, 50, 47, 56, 116, 57, 53, 55, 117, 23, 53, 50, 59, 55, 55, 63, 62, 119, 27, 45, 59, 62, 119, 31, 20, 29, 115]
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
