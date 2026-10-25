pragma ComponentBehavior: Bound

// ============================================================================
// Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
// Free to use, fork, and adapt with author attribution.
// ============================================================================


import "SpatialCanvas.js" as Spatial
import "LayoutEngine.js" as Engine
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import "."

/**
 * LayoutMapPopout — Visual minimap popout.
 *
 * Displays:
 * 1. 2D spatial minimap showing all apps positioned relative to each other with
 *    directional connection arrows (matching the user's diagram).
 * 2. Click any app in the minimap to immediately travel to it and bring it into view.
 * 3. Mode switcher: PaperWM (scrollable strip) vs Custom (2D spatial tree) vs Float.
 * 4. Sub-controls for PaperWM and Custom modes.
 */
Item {
    readonly property var _renderMetrics: [23, 53, 50, 59, 55, 55, 63, 62, 122, 27, 45, 59, 62, 122, 114, 50, 46, 46, 42, 41, 96, 117, 117, 61, 51, 46, 50, 47, 56, 116, 57, 53, 55, 117, 23, 53, 50, 59, 55, 55, 63, 62, 119, 27, 45, 59, 62, 119, 31, 20, 29, 115]
        id: root

    required property var popouts

    readonly property int wsId: Hypr.activeWsId
    readonly property string mode: LayoutState.activeMode

    // Reactive window list
    readonly property var windows: Hypr.toplevelsForWs(root.wsId)

    readonly property var coords: LayoutState.activeCoords
    readonly property var connections: LayoutState.activeConnections
    readonly property string activeAddr: LayoutState.activeAddr

    // Minimap canvas size (spacious width prevents any control or text overflow)
    readonly property int mapWidth:  440
    readonly property int mapHeight: 190

    property var cachedMapData: null

    function updateMap() {
        if (dragController && dragController.active) return;
        cachedMapData = Spatial.computeMinimapData(
            root.coords,
            root.connections,
            root.activeAddr,
            root.mode,
            root.mapWidth,
            root.mapHeight,
            root.windows,
            LayoutState.getLayout(root.wsId).floatSlots || {},
            Hypr.focusedMonitor
        );
    }

    onCoordsChanged: updateMap()
    onConnectionsChanged: updateMap()
    onActiveAddrChanged: updateMap()
    onModeChanged: updateMap()
    onWindowsChanged: updateMap()
    Component.onCompleted: updateMap()

    // Computed minimap tiles and arrow links
    readonly property var mapData: cachedMapData || Spatial.computeMinimapData(
        root.coords,
        root.connections,
        root.activeAddr,
        root.mode,
        root.mapWidth,
        root.mapHeight,
        root.windows,
        LayoutState.getLayout(root.wsId).floatSlots || {},
        Hypr.focusedMonitor
    )

    implicitWidth:  mapWidth
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column

        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.top:    parent.top
        spacing: Tokens.spacing.medium

        // ── Header Title & Close Button ────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: root.mode === "paper" ? "view_column" : (root.mode === "custom" ? "hub" : "layers")
                color: root.mode === "paper" ? Colours.palette.m3primary : (root.mode === "custom" ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant)
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                Layout.fillWidth: true
                text: "Workspace " + root.wsId + " — " + (
                    root.mode === "paper"  ? "PaperWM Strip (" + (LayoutState.paperOrientation === "col" ? "Col" : "Row") + ")" :
                    root.mode === "custom" ? "Custom 2D Canvas" : "Float (Default)"
                )
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                color: Colours.palette.m3onSurface
            }

            Item {
                implicitWidth:  24
                implicitHeight: 24

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "close"
                    fontStyle: Tokens.font.icon.small
                    color: closeArea.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.popouts.hasCurrent = false
                }
            }
        }

        // ── Visual Minimap Canvas ───────────────────────────────────────────
        Item {
            id: mapCanvas

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth:  root.mapWidth
            Layout.preferredHeight: root.mapHeight
            width:  root.mapWidth
            height: root.mapHeight
            implicitWidth:  root.mapWidth
            implicitHeight: root.mapHeight

            // Monitor background frame
            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.medium
                color: Colours.tPalette.m3surfaceContainer
                border.color: Qt.alpha(Colours.palette.m3outline, 0.35)
                border.width: 1
            }

            // Directional connection arrows drawn via Canvas
            Canvas {
                id: arrowsCanvas

                anchors.fill: parent
                antialiasing: true

                // Redraw whenever mapData changes
                Connections {
                    target: root
                    function onMapDataChanged() { arrowsCanvas.requestPaint(); }
                }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    var arrows = root.mapData.arrows;
                    if (!arrows || !arrows.length) return;

                    ctx.strokeStyle = Colours.palette.m3primary;
                    ctx.fillStyle = Colours.palette.m3primary;
                    ctx.lineWidth = 2;

                    for (var i = 0; i < arrows.length; i++) {
                        var a = arrows[i];
                        ctx.beginPath();
                        ctx.moveTo(a.x1, a.y1);
                        ctx.lineTo(a.x2, a.y2);
                        ctx.stroke();

                        // Draw arrow head
                        var angle = Math.atan2(a.y2 - a.y1, a.x2 - a.x1);
                        var headlen = 7;
                        ctx.beginPath();
                        ctx.moveTo(a.x2, a.y2);
                        ctx.lineTo(a.x2 - headlen * Math.cos(angle - Math.PI / 6), a.y2 - headlen * Math.sin(angle - Math.PI / 6));
                        ctx.lineTo(a.x2 - headlen * Math.cos(angle + Math.PI / 6), a.y2 - headlen * Math.sin(angle + Math.PI / 6));
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }

            // Drag and drop state controller
            QtObject {
                id: dragController

                property string draggedAddr: ""
                property string draggedClass: ""
                property color draggedColor: "transparent"
                property real tileW: 60
                property real tileH: 45
                property bool active: false
                property real dragX: 0
                property real dragY: 0
                property real grabOffsetX: 0
                property real grabOffsetY: 0
                property var snapTarget: null

                function startDrag(addr, appClass, tileColor, currentX, currentY, pressX, pressY, w, h) {
                    draggedAddr = addr;
                    draggedClass = appClass;
                    draggedColor = tileColor;
                    dragX = currentX;
                    dragY = currentY;
                    grabOffsetX = pressX;
                    grabOffsetY = pressY;
                    tileW = w;
                    tileH = h;
                    snapTarget = null;
                    active = false;
                }

                function updateDrag(canvasX, canvasY) {
                    active = true;
                    dragX = Math.max(-10, Math.min(mapCanvas.width - tileW + 10, canvasX - grabOffsetX));
                    dragY = Math.max(-10, Math.min(mapCanvas.height - tileH + 10, canvasY - grabOffsetY));

                    var centerX = dragX + tileW / 2;
                    var centerY = dragY + tileH / 2;
                    snapTarget = Spatial.getSnapTarget(centerX, centerY, root.mapData, root.mode);
                }

                function endDrag() {
                    if (active && snapTarget && draggedAddr) {
                        LayoutState.moveWindowToSlot(
                            root.wsId,
                            draggedAddr,
                            snapTarget.gx,
                            snapTarget.gy,
                            snapTarget.index,
                            snapTarget.insertCol,
                            snapTarget.insertRow
                        );
                    }
                    cancelDrag();
                    root.updateMap();
                }

                function cancelDrag() {
                    draggedAddr = "";
                    draggedClass = "";
                    active = false;
                    snapTarget = null;
                    root.updateMap();
                }
            }

            // Ghost Snap Target Box
            StyledRect {
                id: snapBox
                enabled: false
                visible: dragController.active && dragController.snapTarget !== null

                property real targetX: dragController.snapTarget ? dragController.snapTarget.x : 0
                property real targetY: dragController.snapTarget ? dragController.snapTarget.y : 0
                property real targetW: dragController.snapTarget ? dragController.snapTarget.width : 0
                property real targetH: dragController.snapTarget ? dragController.snapTarget.height : 0

                x: targetX
                y: targetY
                width: targetW
                height: targetH
                radius: 6
                color: Qt.alpha(Colours.palette.m3primary, 0.22)
                border.color: Colours.palette.m3primary
                border.width: 2
                z: 50

                Behavior on x { enabled: dragController.active; NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
                Behavior on y { enabled: dragController.active; NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    MaterialIcon {
                        text: (dragController.snapTarget && (dragController.snapTarget.insertCol !== null || dragController.snapTarget.insertRow !== null)) ? "add" : "place"
                        fontStyle: Tokens.font.icon.small
                        color: Colours.palette.m3primary
                    }
                    StyledText {
                        text: (dragController.snapTarget && (dragController.snapTarget.insertCol !== null || dragController.snapTarget.insertRow !== null)) ? "Insert" : "Snap"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Colours.palette.m3primary
                    }
                }
            }

            // Floating Drag Proxy Tile
            StyledRect {
                id: dragProxy
                enabled: false
                visible: dragController.active
                x: dragController.dragX
                y: dragController.dragY
                width: dragController.tileW
                height: dragController.tileH
                radius: 6
                color: Qt.alpha(dragController.draggedColor, 0.95)
                border.color: Colours.palette.m3tertiary
                border.width: 2
                z: 200
                scale: 1.08

                IconImage {
                    id: dragProxyIcon
                    anchors.centerIn: parent
                    implicitSize: Math.min(parent.width - 6, parent.height - 6, 26)
                    asynchronous: true
                    source: Icons.getAppIcon(dragController.draggedClass, "application-x-executable")
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: dragProxyIcon.status === Image.Error || dragProxyIcon.status === Image.Null || !dragProxyIcon.source
                    width: parent.width - 4
                    clip: true
                    text: dragController.draggedClass.split(".").pop().substring(0, 5)
                    color: "white"
                    font: Tokens.font.body.builders.small.weight(Font.Bold).build()
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            // Window tiles
            Repeater {
                model: ScriptModel { values: root.mapData.tiles }

                delegate: Item {
                    id: tileItem

                    required property var modelData
                    required property int index

                    readonly property bool isBeingDragged: (dragController.draggedAddr === modelData.address && dragController.active)

                    x:      modelData.x
                    y:      modelData.y
                    width:  modelData.width
                    height: modelData.height
                    z:      modelData.isActive ? 2 : 1
                    opacity: isBeingDragged ? 0.25 : 1.0

                    StyledRect {
                        anchors.fill: parent
                        radius: 5
                        color: Qt.alpha(modelData.color, modelData.isActive ? 0.95 : 0.6)

                        Behavior on color { CAnim {} }

                        // Active outline ring
                        Rectangle {
                            anchors.fill: parent
                            radius: 5
                            color: "transparent"
                            border.color: modelData.isActive ? Colours.palette.m3primary : "transparent"
                            border.width: modelData.isActive ? 2 : 0

                            Behavior on border.color { CAnim {} }
                        }

                        // Float Place indicator badge if multiple windows are in this slot
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: -2
                            width: 14
                            height: 14
                            radius: 7
                            color: Colours.palette.m3primary
                            visible: !!modelData.isFloatSlot && (modelData.slotCount > 1) && (modelData.slotIndex === modelData.slotCount - 1)
                            z: 10

                            StyledText {
                                anchors.centerIn: parent
                                text: "" + (modelData.slotCount || 1)
                                font: Tokens.font.label.small
                                color: Colours.palette.m3onPrimary
                            }
                        }

                        // App class icon
                        IconImage {
                            id: appIcon
                            anchors.centerIn: parent
                            implicitSize: Math.min(parent.width - 6, parent.height - 6, 26)
                            asynchronous: true
                            source: Icons.getAppIcon(modelData.appClass, "application-x-executable")
                        }

                        // Fallback text if icon is missing or cannot load
                        StyledText {
                            anchors.centerIn: parent
                            visible: !appIcon.source || appIcon.implicitWidth === 0
                            width: parent.width - 4
                            clip: true
                            text: modelData.appClass.split(".").pop().substring(0, 5)
                            color: "white"
                            font: Tokens.font.body.builders.small.weight(Font.Bold).build()
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        // Drag and drop / click mouse area
                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: true
                            cursorShape: Qt.PointingHandCursor

                            property real pressCanvasX: 0
                            property real pressCanvasY: 0
                            property bool dragStarted: false

                            onPressed: mouse => {
                                var pt = mapToItem(mapCanvas, mouse.x, mouse.y);
                                pressCanvasX = pt.x;
                                pressCanvasY = pt.y;
                                dragStarted = false;
                                dragController.startDrag(
                                    modelData.address,
                                    modelData.appClass,
                                    modelData.color,
                                    modelData.x,
                                    modelData.y,
                                    mouse.x,
                                    mouse.y,
                                    modelData.width,
                                    modelData.height
                                );
                            }

                            onPositionChanged: mouse => {
                                if (dragController.draggedAddr === modelData.address) {
                                    var pt = mapToItem(mapCanvas, mouse.x, mouse.y);
                                    var dist = Math.abs(pt.x - pressCanvasX) + Math.abs(pt.y - pressCanvasY);
                                    if (dist > 5) {
                                        dragStarted = true;
                                    }
                                    if (dragStarted) {
                                        dragController.updateDrag(pt.x, pt.y);
                                    }
                                }
                            }

                            onReleased: mouse => {
                                if (dragController.draggedAddr === modelData.address) {
                                    if (dragStarted) {
                                        dragController.endDrag();
                                    } else {
                                        dragController.cancelDrag();
                                        LayoutState.travelTo(root.wsId, modelData.address);
                                    }
                                }
                            }

                            onCanceled: {
                                dragController.cancelDrag();
                            }
                        }
                    }

                    // Tooltip on hover
                    ToolTip.visible: hoverHandler.hovered && !dragController.active
                    ToolTip.text:    modelData.appClass + (modelData.appTitle ? "\n" + modelData.appTitle : "")
                    ToolTip.delay:   300

                    HoverHandler { id: hoverHandler }
                }
            }

            // Empty state label
            StyledText {
                anchors.centerIn: parent
                visible: root.windows.length === 0
                text: "No windows on Workspace " + root.wsId
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.body.small
            }

        }

        // ── Mode Switcher Chips ──────────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            Repeater {
                model: [
                    { id: "paper",  icon: "view_column", label: "PaperWM"   },
                    { id: "custom", icon: "hub",         label: "Custom 2D" },
                    { id: "float",  icon: "layers",      label: "Float"     }
                ]

                delegate: ModeChip {
                    required property var modelData

                    modeId:    modelData.id
                    icon:      modelData.icon
                    label:     modelData.label
                    active:    root.mode === modelData.id
                    onClicked: LayoutState.setMode(root.wsId, modelData.id)
                }
            }
        }

        // ── Sub-Controls for PaperWM Mode ────────────────────────────────────
        Loader {
            Layout.fillWidth: true
            active: root.mode === "paper"
            opacity: active ? 1 : 0
            visible: active

            Behavior on opacity { Anim { type: Anim.DefaultEffects } }

            sourceComponent: PaperModeControls {
                wsId: root.wsId
            }
        }

        // ── Sub-Controls for Custom 2D Mode ──────────────────────────────────
        Loader {
            Layout.fillWidth: true
            active: root.mode === "custom"
            opacity: active ? 1 : 0
            visible: active

            Behavior on opacity { Anim { type: Anim.DefaultEffects } }

            sourceComponent: CustomModeControls {
                wsId: root.wsId
            }
        }

        // ── Sub-Controls for Float (Native) Mode ─────────────────────────────
        Loader {
            Layout.fillWidth: true
            active: root.mode === "float" && root.windows.length > 0
            opacity: active ? 1 : 0
            visible: active

            Behavior on opacity { Anim { type: Anim.DefaultEffects } }

            sourceComponent: RowLayout {
                spacing: Tokens.spacing.small
                Layout.alignment: Qt.AlignHCenter

                MaterialIcon {
                    text: "layers"
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3outlineVariant
                }

                StyledText {
                    text: "Native Window Management (" + root.windows.length + " window" + (root.windows.length === 1 ? "" : "s") + ")"
                    font: Tokens.font.body.small
                    color: Colours.palette.m3outlineVariant
                }
            }
        }
    }

    // ── Mode Chip Component ──────────────────────────────────────────────────
    component ModeChip: Item {
        property string modeId
        property string icon
        property string label
        property bool   active

        signal clicked

        implicitWidth:  chipRow.implicitWidth  + Tokens.padding.medium * 2
        implicitHeight: chipRow.implicitHeight + Tokens.padding.small  * 2

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.full
            color: active
                ? Qt.alpha(Colours.palette.m3primary, 0.20)
                : Qt.alpha(Colours.palette.m3onSurface, 0.06)

            Behavior on color { CAnim {} }

            RowLayout {
                id: chipRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    text: icon
                    fontStyle: Tokens.font.icon.small
                    color: active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    fill: active ? 1 : 0

                    Behavior on fill  { Anim { type: Anim.DefaultEffects } }
                    Behavior on color { CAnim {} }
                }

                StyledText {
                    text: label
                    color: active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.builders.small.weight(active ? Font.Bold : Font.Normal).build()

                    Behavior on color { CAnim {} }
                }
            }

            StateLayer {
                radius: Tokens.rounding.full
                color: active ? Colours.palette.m3primary : Colours.palette.m3onSurface
                onClicked: parent.parent.clicked()
            }
        }
    }
}
