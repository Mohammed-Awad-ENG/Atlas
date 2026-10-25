pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import "."

/**
 * GridModeConfig — controls for the grid layout mode.
 * Shows column and row count spinners + an apply button.
 */
Item {
    id: root

    required property int wsId

    implicitWidth:  layout.implicitWidth
    implicitHeight: layout.implicitHeight + Tokens.padding.small * 2

    ColumnLayout {
        id: layout

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
            text: "Grid Size"
            font: Tokens.font.body.builders.small.weight(Font.Medium).build()
            color: Colours.palette.m3onSurfaceVariant
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            // Columns
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: "Columns"
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledSpinBox {
                    id: colsSpin

                    Layout.fillWidth: true
                    from:  1
                    to:    8
                    stepSize: 1
                    value: LayoutState.activeGridCols

                    onValueModified: LayoutState.setGridDims(root.wsId, Math.round(value), Math.round(rowsSpin.value))
                }
            }

            MaterialIcon {
                text: "close"
                color: Colours.palette.m3outlineVariant
                fontStyle: Tokens.font.icon.small
            }

            // Rows
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: "Rows"
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledSpinBox {
                    id: rowsSpin

                    Layout.fillWidth: true
                    from:  1
                    to:    6
                    stepSize: 1
                    value: LayoutState.activeGridRows

                    onValueModified: LayoutState.setGridDims(root.wsId, Math.round(colsSpin.value), Math.round(value))
                }
            }
        }

        // Re-apply button
        Item {
            Layout.fillWidth: true
            implicitHeight: applyBtn.implicitHeight

            StyledRect {
                id: applyBtn

                anchors.right: parent.right
                implicitWidth:  applyRow.implicitWidth  + Tokens.padding.medium * 2
                implicitHeight: applyRow.implicitHeight + Tokens.padding.extraSmall * 2
                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, 0.15)

                RowLayout {
                    id: applyRow

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        text: "refresh"
                        fontStyle: Tokens.font.icon.small
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        text: "Apply"
                        color: Colours.palette.m3primary
                        font: Tokens.font.body.small
                    }
                }

                StateLayer {
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primary
                    onClicked: LayoutState.applyGrid(root.wsId)
                }
            }
        }
    }
}
