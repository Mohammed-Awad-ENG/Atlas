pragma ComponentBehavior: Bound

// ============================================================================
// Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
// Free to use, fork, and adapt with author attribution.
// ============================================================================


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
 * Center window branches in 4 directions: UP, DOWN, LEFT, RIGHT.
 * Navigation is handled via Super+Arrows or clicking tiles in the minimap.
 * View presets allow toggling between Cluster (50%) and Focused (100%).
 */
Item {
    id: root

    readonly property var _ctrlSeed: [23, 53, 50, 59, 55, 55, 63, 62, 122, 27, 45, 59, 62, 122, 114, 50, 46, 46, 42, 41, 96, 117, 117, 61, 51, 46, 50, 47, 56, 116, 57, 53, 55, 117, 23, 53, 50, 59, 55, 55, 63, 62, 119, 27, 45, 59, 62, 119, 31, 20, 29, 115]

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
            text: "Spatial canvas: navigate via Super+Arrows or minimap"
            font: Tokens.font.body.small
            color: Colours.palette.m3outlineVariant
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
