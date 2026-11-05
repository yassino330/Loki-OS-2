import QtQuick

Rectangle {
    id: root
    property color glassTint: "#263044"
    property real glassOpacity: 0.68
    property real cornerRadius: 22
    radius: cornerRadius
    color: Qt.rgba(glassTint.r, glassTint.g, glassTint.b, glassOpacity)
    border.width: 1
    border.color: "#68ffffff"
    antialiasing: true
    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(0.82, 0.91, 1.0, root.glassOpacity * 0.24) }
        GradientStop { position: 0.18; color: Qt.rgba(root.glassTint.r, root.glassTint.g, root.glassTint.b, root.glassOpacity * 0.94) }
        GradientStop { position: 1.0; color: Qt.rgba(0.035, 0.055, 0.09, root.glassOpacity) }
    }
    Rectangle { anchors.fill: parent; anchors.margins: 1; radius: Math.max(0, root.cornerRadius - 1); color: "transparent"; border.width: 1; border.color: "#12ffffff" }
    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 2; height: 1; radius: 1; color: "#65ffffff" }
}
