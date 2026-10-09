// Title strip with minimize / maximize / close above every floating window (desktop mode, see hypr/config/custom/desktop-mode.lua).
// Hyprland writes the windows' geometry to $XDG_RUNTIME_DIR/windeco.json; one small layer surface per window is its strip.
// Drag the strip to move the window, double-click it to maximize.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root
    property var geo: ({})   // address -> {x, y, w, h, t, f}, replaced on every change
    property var addrs: []   // addresses only: changes just when windows open or close, so delegates are not recreated while dragging

    FileView {
        id: feed
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/windeco.json"
        onLoaded: {
            try {
                const list = JSON.parse(text());
                const map = {};
                for (const w of list)
                    map[w.a] = w;
                const keys = list.map(w => w.a);
                if (JSON.stringify(map) !== JSON.stringify(root.geo))
                    root.geo = map;
                if (JSON.stringify(keys) !== JSON.stringify(root.addrs))
                    root.addrs = keys;
            } catch (e) {}
        }
    }
    // shortcut: polls the small file instead of watching it (the writer replaces it by rename); fine at 30 Hz.
    Timer {
        interval: 33
        running: true
        repeat: true
        onTriggered: feed.reload()
    }

    function hypr(dispatch) {
        Quickshell.execDetached(["hyprctl", "dispatch", dispatch]);
    }

    Variants {
        model: root.addrs

        PanelWindow {
            id: strip
            required property string modelData
            readonly property var g: root.geo[modelData] ?? ({ x: 0, y: 100, w: 200, h: 100, t: "", f: false })
            readonly property string sel: "address:" + modelData
            // While dragging, the strip stays put (the pointer grab reports positions relative to it) and only the window moves.
            property bool dragging: false
            property int frozenX: 0
            property int frozenY: 0
            anchors { top: true; left: true }
            margins {
                left: strip.dragging ? strip.frozenX : Math.max(0, strip.g.x)
                top: strip.dragging ? strip.frozenY : Math.max(0, strip.g.y - 32)
            }
            implicitWidth: Math.max(120, strip.g.w)
            implicitHeight: 30
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "windeco"

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: strip.g.f ? "#f22a2140" : "#e61c1720"
                border.color: strip.g.f ? "#cc9672da" : "#4d9672da"
                border.width: 1

                Text {
                    anchors { left: parent.left; right: buttons.left; verticalCenter: parent.verticalCenter; leftMargin: 14; rightMargin: 8 }
                    text: strip.g.t
                    elide: Text.ElideRight
                    color: strip.g.f ? "#d1d0d2" : "#a69daa"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                }

                // Drag area: the whole strip behind the title and the buttons.
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    property real startX: 0
                    property real startY: 0
                    property real winX: 0
                    property real winY: 0
                    property var pending: null
                    onPressed: mouse => {
                        strip.frozenX = Math.max(0, strip.g.x);
                        strip.frozenY = Math.max(0, strip.g.y - 32);
                        strip.dragging = true;
                        startX = mouse.x;
                        startY = mouse.y;
                        winX = strip.g.x;
                        winY = strip.g.y;
                        root.hypr('hl.dsp.focus({ window = "' + strip.sel + '" })');
                    }
                    onPositionChanged: mouse => {
                        if (!pressed)
                            return;
                        pending = { x: Math.round(winX + mouse.x - startX), y: Math.round(winY + mouse.y - startY) };
                        sendTimer.start();
                    }
                    onReleased: {
                        sendTimer.stop();
                        flush();
                        strip.dragging = false;
                    }
                    onDoubleClicked: root.hypr('hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized", window = "' + strip.sel + '" })')
                    function flush() {
                        if (!pending)
                            return;
                        root.hypr('hl.dsp.window.move({ x = ' + pending.x + ', y = ' + pending.y + ', window = "' + strip.sel + '" })');
                        pending = null;
                    }
                    // at most ~60 moves a second: each one is a hyprctl call
                    Timer {
                        id: sendTimer
                        interval: 16
                        repeat: true
                        onTriggered: dragArea.flush()
                    }
                }

                Row {
                    id: buttons
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    spacing: 4
                    Repeater {
                        model: [
                            { glyph: "󰖰", hover: "#669672da", act: "min" },
                            { glyph: "󰖯", hover: "#669672da", act: "max" },
                            { glyph: "󰖭", hover: "#ffe5484d", act: "close" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: 28
                            height: 22
                            radius: 11
                            color: area.containsMouse ? modelData.hover : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.glyph
                                color: "#d1d0d2"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                            }
                            MouseArea {
                                id: area
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (modelData.act === "close")
                                        root.hypr('hl.dsp.window.close({ window = "' + strip.sel + '" })');
                                    else if (modelData.act === "max")
                                        root.hypr('hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized", window = "' + strip.sel + '" })');
                                    else
                                        root.hypr('hl.dsp.window.move({ workspace = "special:min", follow = false, window = "' + strip.sel + '" })');
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
