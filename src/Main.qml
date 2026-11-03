import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: root
    width: 1280
    height: 800
    minimumWidth: 900
    minimumHeight: 600
    visible: true
    title: "LokiOS"
    color: "#101522"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#182235" }
            GradientStop { position: 0.55; color: "#101827" }
            GradientStop { position: 1.0; color: "#090e18" }
        }
    }

    Rectangle {
        width: 520
        height: 520
        radius: 260
        x: parent.width * 0.57 - width / 2
        y: parent.height * 0.38 - height / 2
        color: "#263f70"
        opacity: 0.18
    }

    GlassPanel {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 18
        height: 54
        cornerRadius: 18
        glassOpacity: 0.56

        Label {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: "◈  LokiOS"
            color: "#f5f7fc"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        Label {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(new Date(), "ddd  •  h:mm")
            color: "#b8c2d4"
            font.pixelSize: 13
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 12

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "LokiOS"
            color: "#f6f8ff"
            font.pixelSize: 64
            font.weight: Font.Light
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "A calmer way to compute."
            color: "#aebbd0"
            font.pixelSize: 17
        }
    }

    Dock {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
    }
}
