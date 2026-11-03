import QtQuick
import QtQuick.Controls

Item {
    id: root

    implicitWidth: row.implicitWidth + 28
    implicitHeight: 76

    GlassPanel {
        id: dock
        anchors.centerIn: parent
        width: row.implicitWidth + 28
        height: 68
        cornerRadius: 24
        glassOpacity: 0.82

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: [
                    { label: "⌂", name: "Home" },
                    { label: "▦", name: "Apps" },
                    { label: "▱", name: "Files" },
                    { label: "⚙", name: "Settings" }
                ]

                delegate: ToolButton {
                    required property var modelData
                    width: 52
                    height: 52
                    text: modelData.label
                    font.pixelSize: 25
                    palette.buttonText: "#f4f6fb"
                    background: Rectangle {
                        radius: 16
                        color: parent.hovered ? "#28ffffff" : "transparent"
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: modelData.name
                }
            }
        }
    }
}
