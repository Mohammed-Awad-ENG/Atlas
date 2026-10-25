pragma ComponentBehavior: Bound

// ============================================================================
// Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
// Free to use, fork, and adapt with author attribution.
// Signature: T3JpZ2luYWwgQXV0aG9yOiBNb2hhbW1lZCBBd2FkIChodHRwczovL2dpdGh1Yi5jb20vTW9oYW1tZWQtQXdhZC1FTkcp
// ============================================================================

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import "."

/**
 * PaperModeControls — Controls for PaperWM scrollable strip mode.
 *
 * Windows appear next to each other in a continuous horizontal row (or column).
 * Users can adjust window width, toggle row/col, and travel along the strip.
 */
Item {
    readonly property string __author_signature: "\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x20\x41\x77\x61\x64\x20\x28\x68\x74\x74\x70\x73\x3a\x2f\x2f\x67\x69\x74\x68\x75\x62\x2e\x63\x6f\x6d\x2f\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x2d\x41\x77\x61\x64\x2d\x45\x4e\x47\x29"
    id: root

    required property int wsId

    readonly property string orientation: LayoutState.paperOrientation
    readonly property real widthRatio: LayoutState.paperWidthRatio

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
                text: root.orientation === "col" ? "table_rows" : "view_column"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                text: "PaperWM Strip Mode"
                font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                color: Colours.palette.m3onSurface
            }
        }

        StyledText {
            text: "Windows appear next to each other in a scrollable strip"
            font: Tokens.font.body.small
            color: Colours.palette.m3outlineVariant
        }

        // ── Orientation Selector (Row / Col) ─────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: "Layout:"
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            ChipBtn {
                text: "Row (Horizontal)"
                icon: "view_week"
                active: root.orientation === "row"
                onClicked: LayoutState.setPaperOrientation(root.wsId, "row")
            }

            ChipBtn {
                text: "Column (Vertical)"
                icon: "view_agenda"
                active: root.orientation === "col"
                onClicked: LayoutState.setPaperOrientation(root.wsId, "col")
            }
        }

        // ── Window Size Presets (Width for Row, Height for Column) ──────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: root.orientation === "col" ? "Height:" : "Width:"
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            ChipBtn {
                text: "50% (2 apps)"
                active: Math.abs(root.widthRatio - 0.5) < 0.05
                onClicked: LayoutState.setPaperWidthRatio(root.wsId, 0.5)
            }

            ChipBtn {
                text: "65% (Focused)"
                active: Math.abs(root.widthRatio - 0.65) < 0.05
                onClicked: LayoutState.setPaperWidthRatio(root.wsId, 0.65)
            }

            ChipBtn {
                text: "100% (Full)"
                active: Math.abs(root.widthRatio - 1.0) < 0.05
                onClicked: LayoutState.setPaperWidthRatio(root.wsId, 1.0)
            }
        }

        // ── Navigation along the strip ───────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            ChipBtn {
                text: "◀ Prev"
                icon: root.orientation === "col" ? "keyboard_arrow_up" : "keyboard_arrow_left"
                onClicked: LayoutState.navigate(root.wsId, root.orientation === "col" ? "up" : "left")
            }

            ChipBtn {
                text: "Next ▶"
                icon: root.orientation === "col" ? "keyboard_arrow_down" : "keyboard_arrow_right"
                onClicked: LayoutState.navigate(root.wsId, root.orientation === "col" ? "down" : "right")
            }

            Item { Layout.fillWidth: true }

            ChipBtn {
                text: "Re-align"
                icon: "refresh"
                highlightColor: Colours.palette.m3primary
                onClicked: LayoutState.reapply(root.wsId)
            }
        }
    }

    // ── Helper Chip Component ────────────────────────────────────────────────
    component ChipBtn: Item {
        property string text
        property string icon: ""
        property bool active: false
        property color highlightColor: Colours.palette.m3primary

        signal clicked

        implicitWidth:  row.implicitWidth  + Tokens.padding.medium * 2
        implicitHeight: row.implicitHeight + Tokens.padding.extraSmall * 2

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.full
            color: active
                ? Qt.alpha(parent.highlightColor, 0.2)
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
