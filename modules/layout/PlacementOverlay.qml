pragma ComponentBehavior: Bound

// ============================================================================
// Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
// Free to use, fork, and adapt with author attribution.
// Signature: T3JpZ2luYWwgQXV0aG9yOiBNb2hhbW1lZCBBd2FkIChodHRwczovL2dpdGh1Yi5jb20vTW9oYW1tZWQtQXdhZC1FTkcp
// ============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils
import "."

Scope {
    readonly property string __author_signature: "\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x20\x41\x77\x61\x64\x20\x28\x68\x74\x74\x70\x73\x3a\x2f\x2f\x67\x69\x74\x68\x75\x62\x2e\x63\x6f\x6d\x2f\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x2d\x41\x77\x61\x64\x2d\x45\x4e\x47\x29"
    id: scope

    LazyLoader {
        id: loader

        active: LayoutState.placementPromptActive && (Hypr.activeWsId === LayoutState.placementWsId)

        Variants {
            model: Screens.screens

            StyledWindow {
                id: win

                required property ShellScreen modelData

                screen: modelData
                name: "layout-placement"
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true
                color: "transparent"

                // Dim background backdrop
                Rectangle {
                    anchors.fill: parent
                    color: "#77000000"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: LayoutState.applyPlacement("same")
                    }
                }

                // Floating Target Selector Card
                StyledRect {
                    id: card

                    anchors.centerIn: parent
                    implicitWidth: 340
                    implicitHeight: 300
                    radius: Tokens.rounding.extraLarge
                    color: Colours.palette.m3surfaceContainer
                    border.color: Colours.palette.m3primary
                    border.width: 2

                    focus: true
                    Component.onCompleted: forceActiveFocus()

                    // Countdown timer: 3.5s defaults to "right"
                    Timer {
                        id: autoTimer
                        interval: 3500
                        running: true
                        repeat: false
                        onTriggered: LayoutState.applyPlacement("right")
                    }

                    // Keyboard navigation
                    Keys.onUpPressed:     { autoTimer.stop(); LayoutState.applyPlacement("up"); }
                    Keys.onDownPressed:   { autoTimer.stop(); LayoutState.applyPlacement("down"); }
                    Keys.onLeftPressed:   { autoTimer.stop(); LayoutState.applyPlacement("left"); }
                    Keys.onRightPressed:  { autoTimer.stop(); LayoutState.applyPlacement("right"); }
                    Keys.onReturnPressed: { autoTimer.stop(); LayoutState.applyPlacement("right"); }
                    Keys.onEnterPressed:  { autoTimer.stop(); LayoutState.applyPlacement("right"); }
                    Keys.onEscapePressed: { autoTimer.stop(); LayoutState.applyPlacement("right"); }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_K) { autoTimer.stop(); LayoutState.applyPlacement("up"); event.accepted = true; }
                        else if (event.key === Qt.Key_J) { autoTimer.stop(); LayoutState.applyPlacement("down"); event.accepted = true; }
                        else if (event.key === Qt.Key_H) { autoTimer.stop(); LayoutState.applyPlacement("left"); event.accepted = true; }
                        else if (event.key === Qt.Key_L) { autoTimer.stop(); LayoutState.applyPlacement("right"); event.accepted = true; }
                        else if (event.key === Qt.Key_Space) { autoTimer.stop(); LayoutState.applyPlacement("right"); event.accepted = true; }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: 8

                        // Header with App Icon and Name
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            IconImage {
                                source: Icons.getAppIcon(LayoutState.placementAppClass, "application-x-executable")
                                implicitSize: 28
                            }

                            StyledText {
                                text: LayoutState.placementAppTitle || "New Window"
                                font.weight: Font.Bold
                                font.pixelSize: 15
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                                Layout.maximumWidth: 230
                            }
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Select window placement:"
                            font.pixelSize: 12
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        Item { Layout.fillHeight: true }

                        // Directional Cross Grid
                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 6

                            // UP Button
                            StyledRect {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 70
                                implicitHeight: 38
                                radius: Tokens.rounding.medium
                                color: upMouse.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh
                                border.color: Colours.palette.m3outlineVariant
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialIcon { text: "arrow_upward"; fontStyle: Tokens.font.icon.small; color: Colours.palette.m3primary }
                                    StyledText { text: "↑ Up"; font.weight: Font.Bold; color: Colours.palette.m3onSurface }
                                }

                                MouseArea {
                                    id: upMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { autoTimer.stop(); LayoutState.applyPlacement("up"); }
                                }
                            }

                            // MIDDLE ROW: LEFT - SAME - RIGHT
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 6

                                // LEFT Button
                                StyledRect {
                                    implicitWidth: 76
                                    implicitHeight: 38
                                radius: Tokens.rounding.medium
                                color: leftMouse.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh
                                border.color: Colours.palette.m3outlineVariant
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialIcon { text: "arrow_back"; fontStyle: Tokens.font.icon.small; color: Colours.palette.m3primary }
                                    StyledText { text: "← Left"; font.weight: Font.Bold; color: Colours.palette.m3onSurface }
                                }

                                MouseArea {
                                    id: leftMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { autoTimer.stop(); LayoutState.applyPlacement("left"); }
                                }
                            }

                            // CENTER / SAME Button (Default on Enter)
                            StyledRect {
                                implicitWidth: 130
                                implicitHeight: 38
                                radius: Tokens.rounding.medium
                                color: sameMouse.containsMouse ? Colours.palette.m3primary : Colours.palette.m3primaryContainer
                                border.color: Colours.palette.m3primary
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialIcon { text: "check"; fontStyle: Tokens.font.icon.small; color: Colours.palette.m3onPrimaryContainer }
                                    StyledText {
                                        text: "↵ Open Next"
                                        font.weight: Font.Bold
                                        font.pixelSize: 11
                                        color: Colours.palette.m3onPrimaryContainer
                                    }
                                }

                                MouseArea {
                                    id: sameMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { autoTimer.stop(); LayoutState.applyPlacement("right"); }
                                }
                            }

                            // RIGHT Button
                            StyledRect {
                                implicitWidth: 76
                                implicitHeight: 38
                                radius: Tokens.rounding.medium
                                color: rightMouse.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh
                                border.color: Colours.palette.m3outlineVariant
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    StyledText { text: "Right →"; font.weight: Font.Bold; color: Colours.palette.m3onSurface }
                                    MaterialIcon { text: "arrow_forward"; fontStyle: Tokens.font.icon.small; color: Colours.palette.m3primary }
                                }

                                MouseArea {
                                    id: rightMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { autoTimer.stop(); LayoutState.applyPlacement("right"); }
                                }
                            }
                        }

                        // DOWN Button
                        StyledRect {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 70
                            implicitHeight: 38
                            radius: Tokens.rounding.medium
                            color: downMouse.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh
                            border.color: Colours.palette.m3outlineVariant
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                MaterialIcon { text: "arrow_downward"; fontStyle: Tokens.font.icon.small; color: Colours.palette.m3primary }
                                StyledText { text: "↓ Down"; font.weight: Font.Bold; color: Colours.palette.m3onSurface }
                            }

                            MouseArea {
                                id: downMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { autoTimer.stop(); LayoutState.applyPlacement("down"); }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Press ↑ ↓ ← → or Enter (auto in 3s)"
                        font.pixelSize: 11
                        color: Colours.palette.m3outline
                    }
                }
            }
        }
    }
}
}
