pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import "."

/**
 * CustomModeControls — Controls for the 2D Spatial Tree mode.
 *
 * Matches the user diagram:
 * Center window branches in 4 directions: UP, DOWN, LEFT, RIGHT.
 * Each connected branch can further branch in any direction.
 * Clicking an arrow navigates/travels to the neighbor or attaches a window.
 */
Item {
    id: root

    required property int wsId

    readonly property string preset: LayoutState.customPreset

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight + Tokens.padding.small * 2

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.small

        // Separator
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Qt.alpha(Colours.palette.m3outline, 0.25)
        }

        // Section Title
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                text: "hub"
                color: Colours.palette.m3tertiary
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                text: "2D Spatial Tree Mode"
                font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                color: Colours.palette.m3onSurface
            }
        }

        StyledText {
            text: "Spatial canvas: branches UP, DOWN, LEFT, RIGHT"
            font: Tokens.font.body.small
            color: Colours.palette.m3outlineVariant
        }

        // ── 3×3 Directional Arrow Pad ────────────────────────────────────────
        //          [ UP ]
        //  [ LEFT ] [ · ] [ RIGHT ]
        //         [ DOWN ]
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: dirGrid.implicitWidth
            implicitHeight: dirGrid.implicitHeight

            GridLayout {
                id: dirGrid

                columns: 3
                columnSpacing: Tokens.spacing.extraSmall
                rowSpacing: Tokens.spacing.extraSmall

                // Row 1: blank, UP, blank
                Item { implicitWidth: arrowSize; implicitHeight: arrowSize }

                DirArrow {
                    direction: "up"
                    icon: "keyboard_arrow_up"
                    tooltip: "Navigate / Attach UP"
                    onClicked: LayoutState.navigate(root.wsId, "up")
                }

                Item { implicitWidth: arrowSize; implicitHeight: arrowSize }

                // Row 2: LEFT, center dot, RIGHT
                DirArrow {
                    direction: "left"
                    icon: "keyboard_arrow_left"
                    tooltip: "Navigate / Attach LEFT"
                    onClicked: LayoutState.navigate(root.wsId, "left")
                }

                // Center indicator showing active anchor
                Item {
                    implicitWidth: arrowSize
                    implicitHeight: arrowSize

                    StyledRect {
                        anchors.centerIn: parent
                        implicitWidth: 16
                        implicitHeight: 16
                        radius: 8
                        color: Colours.palette.m3tertiary
                    }
                }

                DirArrow {
                    direction: "right"
                    icon: "keyboard_arrow_right"
                    tooltip: "Navigate / Attach RIGHT"
                    onClicked: LayoutState.navigate(root.wsId, "right")
                }

                // Row 3: blank, DOWN, blank
                Item { implicitWidth: arrowSize; implicitHeight: arrowSize }

                DirArrow {
                    direction: "down"
                    icon: "keyboard_arrow_down"
                    tooltip: "Navigate / Attach DOWN"
                    onClicked: LayoutState.navigate(root.wsId, "down")
                }

                Item { implicitWidth: arrowSize; implicitHeight: arrowSize }
            }
        }

        // ── Window Size Preset & Reset ───────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: "View:"
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            ChipBtn {
                text: "Cluster (50%)"
                active: root.preset === "half"
                onClicked: LayoutState.setCustomPreset(root.wsId, "half")
            }

            ChipBtn {
                text: "Focused (100%)"
                active: root.preset === "full"
                onClicked: LayoutState.setCustomPreset(root.wsId, "full")
            }

            Item { Layout.fillWidth: true }

            ChipBtn {
                text: "Reset"
                icon: "device_reset"
                highlightColor: Colours.palette.m3error
                onClicked: LayoutState.resetLayout(root.wsId)
            }
        }
    }

    readonly property int arrowSize: 36

    // ── Directional Arrow Component ──────────────────────────────────────────
    component DirArrow: Item {
        property string direction
        property string icon
        property string tooltip

        signal clicked

        implicitWidth:  root.arrowSize
        implicitHeight: root.arrowSize

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.small
            color: Qt.alpha(Colours.palette.m3tertiary, 0.12)

            Behavior on color { CAnim {} }

            MaterialIcon {
                anchors.centerIn: parent
                text: parent.parent.icon
                fontStyle: Tokens.font.icon.medium
                color: Colours.palette.m3tertiary
            }

            StateLayer {
                radius: Tokens.rounding.small
                color: Colours.palette.m3tertiary
                onClicked: parent.parent.clicked()
            }
        }
    }

    // ── Helper Chip Component ────────────────────────────────────────────────
    component ChipBtn: Item {
        property string text
        property string icon: ""
        property bool active: false
        property color highlightColor: Colours.palette.m3tertiary

        signal clicked

        implicitWidth:  row.implicitWidth  + Tokens.padding.medium * 2
        implicitHeight: row.implicitHeight + Tokens.padding.extraSmall * 2

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.full
            color: active
                ? Qt.alpha(parent.highlightColor, 0.22)
                : Qt.alpha(Colours.palette.m3onSurface, 0.07)

            Behavior on color { CAnim {} }

            RowLayout {
                id: row

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    visible: parent.parent.parent.icon.length > 0
                    text: parent.parent.parent.icon
                    fontStyle: Tokens.font.icon.small
                    color: parent.parent.parent.active ? parent.parent.parent.highlightColor : Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    text: parent.parent.parent.text
                    font: Tokens.font.body.builders.small.weight(parent.parent.parent.active ? Font.Bold : Font.Normal).build()
                    color: parent.parent.parent.active ? parent.parent.parent.highlightColor : Colours.palette.m3onSurfaceVariant
                }
            }

            StateLayer {
                radius: Tokens.rounding.full
                color: parent.parent.highlightColor
                onClicked: parent.parent.clicked()
            }
        }
    }
}
