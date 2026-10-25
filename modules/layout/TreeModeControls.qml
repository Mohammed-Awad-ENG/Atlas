pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import "."

/**
 * TreeModeControls — controls for the Tree layout mode.
 *
 * Provides directional split buttons (UP / DOWN / LEFT / RIGHT) that split
 * the currently focused window's cell in the chosen direction.
 */
Item {
    id: root

    required property int wsId

    property string pendingSplitDir: ""

    implicitWidth:  col.implicitWidth
    implicitHeight: col.implicitHeight + Tokens.padding.small * 2

    ColumnLayout {
        id: col

        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.small

        // Separator
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Qt.alpha(Colours.palette.m3outline, 0.3)
        }

        StyledText {
            text: "Tree Split Direction"
            font: Tokens.font.body.builders.small.weight(Font.Medium).build()
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            text: "Split active window or attach new apps"
            font: Tokens.font.body.small
            color: Colours.palette.m3outlineVariant
        }

        // ── Directional arrow grid ──────────────────────────────────────────
        //       [UP]
        //  [LEFT] [·] [RIGHT]
        //      [DOWN]
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth:  dirGrid.implicitWidth
            implicitHeight: dirGrid.implicitHeight

            GridLayout {
                id: dirGrid

                columns: 3
                columnSpacing: Tokens.spacing.extraSmall
                rowSpacing:    Tokens.spacing.extraSmall

                // Row 1: blank, UP, blank
                Item { implicitWidth: arrowSize; implicitHeight: arrowSize }

                SplitArrow {
                    direction: "up"
                    icon: "keyboard_arrow_up"
                    tooltip: "Split UP"
                    active: root.pendingSplitDir === "up"
                    onClicked: root._triggerSplit("up")
                }

                Item { implicitWidth: arrowSize; implicitHeight: arrowSize }

                // Row 2: LEFT, center dot, RIGHT
                SplitArrow {
                    direction: "left"
                    icon: "keyboard_arrow_left"
                    tooltip: "Split LEFT"
                    active: root.pendingSplitDir === "left"
                    onClicked: root._triggerSplit("left")
                }

                // Center indicator
                Item {
                    implicitWidth:  arrowSize
                    implicitHeight: arrowSize

                    StyledRect {
                        anchors.centerIn: parent
                        implicitWidth:  10
                        implicitHeight: 10
                        radius: 5
                        color: Colours.palette.m3tertiary
                    }
                }

                SplitArrow {
                    direction: "right"
                    icon: "keyboard_arrow_right"
                    tooltip: "Split RIGHT"
                    active: root.pendingSplitDir === "right"
                    onClicked: root._triggerSplit("right")
                }

                // Row 3: blank, DOWN, blank
                Item { implicitWidth: arrowSize; implicitHeight: arrowSize }

                SplitArrow {
                    direction: "down"
                    icon: "keyboard_arrow_down"
                    tooltip: "Split DOWN"
                    active: root.pendingSplitDir === "down"
                    onClicked: root._triggerSplit("down")
                }

                Item { implicitWidth: arrowSize; implicitHeight: arrowSize }
            }
        }

        // ── Action buttons ──────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            // Reset tree button
            ActionChip {
                icon:  "device_reset"
                label: "Reset"
                chipColor: Colours.palette.m3error
                onClicked: {
                    var layout = LayoutState.getLayout(root.wsId);
                    layout.treeRoot = null;
                    LayoutState.workspaceLayoutsChanged();
                    LayoutState.setMode(root.wsId, "tree");
                }
            }

            Item { Layout.fillWidth: true }

            // Re-apply button
            ActionChip {
                icon:  "refresh"
                label: "Re-tile"
                chipColor: Colours.palette.m3primary
                onClicked: LayoutState.applyTree(root.wsId)
            }
        }
    }

    // ─── Private ──────────────────────────────────────────────────────────────

    readonly property int arrowSize: 38

    function _triggerSplit(dir) {
        root.pendingSplitDir = dir;
        var focused = Hypr.activeToplevel;
        var addr = (focused && focused.lastIpcObject) ? focused.lastIpcObject.address : null;
        LayoutState.treeSplit(root.wsId, dir, addr);
        Qt.callLater(function() { root.pendingSplitDir = ""; });
    }

    // ── Sub-components ────────────────────────────────────────────────────────

    component SplitArrow: Item {
        property string direction
        property string icon
        property string tooltip
        property bool   active

        signal clicked

        implicitWidth:  root.arrowSize
        implicitHeight: root.arrowSize

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.small
            color: active
                ? Qt.alpha(Colours.palette.m3tertiary, 0.3)
                : Qt.alpha(Colours.palette.m3onSurface, 0.08)

            Behavior on color { CAnim {} }

            MaterialIcon {
                anchors.centerIn: parent
                text: icon
                fontStyle: Tokens.font.icon.medium
                color: active ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
                fill: active ? 1 : 0

                Behavior on fill  { Anim { type: Anim.DefaultEffects } }
                Behavior on color { CAnim {} }
            }

            StateLayer {
                radius: Tokens.rounding.small
                color: Colours.palette.m3tertiary
                onClicked: parent.parent.clicked()
            }
        }
    }

    component ActionChip: Item {
        property string icon
        property string label
        property color  chipColor: Colours.palette.m3primary

        signal clicked

        implicitWidth:  chipRow.implicitWidth  + Tokens.padding.small * 2
        implicitHeight: chipRow.implicitHeight + Tokens.padding.extraSmall * 2

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.full
            color: Qt.alpha(parent.chipColor, 0.12)

            Behavior on color { CAnim {} }

            RowLayout {
                id: chipRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    text: icon
                    fontStyle: Tokens.font.icon.small
                    color: parent.parent.parent.chipColor
                }

                StyledText {
                    text: label
                    font: Tokens.font.body.small
                    color: parent.parent.parent.chipColor
                }
            }

            StateLayer {
                radius: Tokens.rounding.full
                color: parent.parent.chipColor
                onClicked: parent.parent.clicked()
            }
        }
    }
}
