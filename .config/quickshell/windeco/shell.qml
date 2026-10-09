// Minimize / maximize / close buttons on every floating window (desktop mode, see hypr/config/custom/desktop-mode.lua).
// Hyprland writes the windows' geometry to $XDG_RUNTIME_DIR/windeco.json; one click-through layer draws a small pill per window.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root
    property var geo: ({})   // address -> {x, y, w, h}, replaced on every change
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

    // One tiny layer surface per window (its whole surface is the pill, so clicks elsewhere reach the windows).
    Variants {
        model: root.addrs

        PanelWindow {
            id: pillWin
            required property string modelData
            readonly property var g: root.geo[modelData] ?? ({ x: 0, y: 0, w: 100, h: 100 })
            anchors { top: true; left: true }
            margins {
                left: Math.max(4, g.x + g.w - 100)
                top: g.y >= 36 ? g.y - 32 : g.y + 6
            }
            implicitWidth: 96
            implicitHeight: 28
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "windeco"

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: "#e61c1720"
                border.color: "#599672da"
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Repeater {
                        model: [
                            { glyph: "󰖰", hover: "#669672da", act: "min" },
                            { glyph: "󰖯", hover: "#669672da", act: "max" },
                            { glyph: "󰖭", hover: "#ffe5484d", act: "close" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: 26
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
                                    const a = "address:" + pillWin.modelData;
                                    if (modelData.act === "close")
                                        root.hypr('hl.dsp.window.close({ window = "' + a + '" })');
                                    else if (modelData.act === "max")
                                        root.hypr('hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized", window = "' + a + '" })');
                                    else
                                        root.hypr('hl.dsp.window.move({ workspace = "special:min", follow = false, window = "' + a + '" })');
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
