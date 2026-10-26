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
 * LayoutButton — Bar entry that displays the active layout mode icon & badge.
 *
 * Left-click: toggles the visual minimap popout.
 * Right-click: cycles through layout modes (Freeform -> Columns -> Custom 2D -> Freeform).
 */
Item {
    readonly property var _ctrlSeed: [23, 53, 50, 59, 55, 55, 63, 62, 122, 27, 45, 59, 62, 122, 114, 50, 46, 46, 42, 41, 96, 117, 117, 61, 51, 46, 50, 47, 56, 116, 57, 53, 55, 117, 23, 53, 50, 59, 55, 55, 63, 62, 119, 27, 45, 59, 62, 119, 31, 20, 29, 115]
        id: root

    required property var bar

    readonly property int wsId: Hypr.activeWsId
    readonly property string mode: LayoutState.activeMode

    readonly property string modeIcon: {
        if (mode === "paper" || mode === "columns")  return "view_column";
        if (mode === "custom") return "hub";
        return "layers";
    }

    readonly property string modeLabel: {
        if (mode === "paper" || mode === "columns")  return "C";
        if (mode === "custom") return "S";
        return "F";
    }

    readonly property color modeColor: {
        if (mode === "paper" || mode === "columns")  return Colours.palette.m3primary;
        if (mode === "custom") return Colours.palette.m3tertiary;
        return Colours.palette.m3onSurfaceVariant;
    }

    clip: true
    implicitWidth:  Tokens.sizes.bar.innerWidth
    implicitHeight: column.implicitHeight + Tokens.padding.extraSmall * 2
    width:  implicitWidth
    height: implicitHeight

    // Full-area mouse interaction: click toggles popout, right click cycles mode
    MouseArea {
        id: mouseArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onEntered: {
            const popouts = root.bar?.popouts;
            if (popouts) {
                popouts.currentName = "layoutmap";
                popouts.currentCenter = Qt.binding(() => root.mapToItem(root.bar, 0, root.implicitHeight / 2).y);
                popouts.hasCurrent = true;
            }
        }

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                LayoutState.cycleMode(root.wsId);
            } else {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent && popouts.currentName === "layoutmap") {
                    popouts.hasCurrent = false;
                } else {
                    popouts.currentName = "layoutmap";
                    popouts.currentCenter = Qt.binding(() => root.mapToItem(root.bar, 0, root.implicitHeight / 2).y);
                    popouts.hasCurrent = true;
                }
            }
        }
    }

    ColumnLayout {
        id: column

        anchors.centerIn: parent
        spacing: 2

        // ── Mode icon ──────────────────────────────────────────────────────
        Item {
            id: iconWrapper

            Layout.alignment: Qt.AlignHCenter
            implicitWidth:  iconBg.implicitWidth
            implicitHeight: iconBg.implicitHeight
            width:  implicitWidth
            height: implicitHeight

            // Tonal background pill that highlights in the active color
            StyledRect {
                id: iconBg

                anchors.centerIn: parent
                implicitWidth:  Math.min(icon.implicitWidth + Tokens.padding.small * 2, root.implicitWidth)
                implicitHeight: icon.implicitHeight + Tokens.padding.small * 2
                radius: Tokens.rounding.full
                color: mouseArea.containsMouse ? Qt.alpha(root.modeColor, 0.25) : "transparent"

                Behavior on color { CAnim {} }

                MaterialIcon {
                    id: icon

                    anchors.centerIn: parent
                    text: root.modeIcon
                    color: root.modeColor
                    fill: (mode !== "float" && mode !== "freeform") ? 1 : 0
                    fontStyle: Tokens.font.icon.medium

                    Behavior on fill  { Anim { type: Anim.DefaultEffects } }
                    Behavior on color { CAnim {} }
                }
            }
        }

        // ── Next Open Direction Indicator Arrow [→ ↓ ← ↑] ───────────────────
        Item {
            id: dirArrowWrapper

            Layout.alignment: Qt.AlignHCenter
            implicitWidth:  dirArrowBg.implicitWidth
            implicitHeight: dirArrowBg.implicitHeight
            width:  implicitWidth
            height: implicitHeight

            StyledRect {
                id: dirArrowBg

                anchors.centerIn: parent
                implicitWidth:  dirIcon.implicitWidth  + Tokens.padding.extraSmall * 2
                implicitHeight: dirIcon.implicitHeight + Tokens.padding.extraSmall * 2
                radius: Tokens.rounding.full
                color: dirMouseArea.containsMouse ? Qt.alpha(root.modeColor, 0.25) : "transparent"

                Behavior on color { CAnim {} }

                MaterialIcon {
                    id: dirIcon

                    anchors.centerIn: parent
                    text: {
                        const d = LayoutState.nextOpenDir;
                        if (d === "down")  return "arrow_downward";
                        if (d === "left")  return "arrow_back";
                        if (d === "up")    return "arrow_upward";
                        return "arrow_forward";
                    }
                    color: root.modeColor
                    fontStyle: Tokens.font.icon.small

                    Behavior on color { CAnim {} }
                }

                MouseArea {
                    id: dirMouseArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: LayoutState.cycleNextOpenDir(root.wsId)
                }
            }
        }
    }

    Behavior on implicitHeight { Anim {} }
}
