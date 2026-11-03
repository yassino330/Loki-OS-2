import QtQuick

Rectangle {
    id: root

    property color glassTint: "#263044"
    property real glassOpacity: 0.68
    property real cornerRadius: 22

    radius: cornerRadius
    color: Qt.rgba(glassTint.r, glassTint.g, glassTint.b, glassOpacity)
    border.width: 1
    border.color: "#45ffffff"

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 1
        height: 1
        radius: 1
        color: "#30ffffff"
    }
}
