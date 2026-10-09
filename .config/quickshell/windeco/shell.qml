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

    // Drag helper (drag.py): moves the window itself and reports each position, which the strip follows in the same frame.
    property string dragAddr: ""
    property int dragX: 0
    property int dragY: 0
    Process {
        id: helper
        command: ["python3", "-I", Quickshell.env("HOME") + "/.config/quickshell/windeco/drag.py"]
        running: true
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                const p = line.split(" ");
                root.dragAddr = p[0];
                root.dragX = parseInt(p[1]);
                root.dragY = parseInt(p[2]);
            }
        }
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
            anchors { top: true; left: true }
            margins {
                left: Math.max(0, root.dragAddr === strip.modelData ? root.dragX : strip.g.x)
                top: Math.max(0, (root.dragAddr === strip.modelData ? root.dragY : strip.g.y) - 30)
            }
            implicitWidth: Math.max(120, strip.g.w)
            implicitHeight: 30
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "windeco"

            Item {
                anchors.fill: parent
                // Same colour and border as the window's top edge; the bottom half is square so strip and window read as one piece.
                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: strip.g.f ? "#f22a2140" : "#e61c1720"
                    border.color: strip.g.f ? "#cc9672da" : "#4d9672da"
                    border.width: 1
                }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 13
                    color: strip.g.f ? "#f22a2140" : "#e61c1720"
                    Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: 1; color: strip.g.f ? "#cc9672da" : "#4d9672da" }
                    Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: strip.g.f ? "#cc9672da" : "#4d9672da" }
                }

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
                    anchors.fill: parent
                    onPressed: {
                        root.hypr('hl.dsp.focus({ window = "' + strip.sel + '" })');
                        helper.write("start " + strip.modelData + " " + Math.round(strip.g.x) + " " + Math.round(strip.g.y) + "\n");
                    }
                    onReleased: {
                        helper.write("stop\n");
                        root.dragAddr = "";
                    }
                    onDoubleClicked: root.hypr('hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized", window = "' + strip.sel + '" })')
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
