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
    visibility: Window.FullScreen
    title: "LokiOS"
    color: "#101522"

    property bool launcherOpen: false
    property bool settingsOpen: false

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#182235" }
            GradientStop { position: 0.55; color: "#101827" }
            GradientStop { position: 1.0; color: "#090e18" }
        }
    }

    Rectangle {
        width: 560
        height: 560
        radius: 280
        x: parent.width * 0.57 - width / 2
        y: parent.height * 0.38 - height / 2
        color: "#263f70"
        opacity: 0.18
    }

    GlassPanel {
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

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Welcome to your desktop"
            color: "#8291aa"
            font.pixelSize: 12
        }
    }

    Dock {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24

        onAppClicked: function(appName) {
            if (appName === "Home") {
                root.launcherOpen = false
                root.settingsOpen = false
            } else if (appName === "Apps") {
                root.launcherOpen = !root.launcherOpen
                root.settingsOpen = false
            } else if (appName === "Files") {
                SystemActions.launch("pcmanfm")
            } else if (appName === "Settings") {
                root.settingsOpen = !root.settingsOpen
                root.launcherOpen = false
            }
        }
    }

    GlassPanel {
        visible: root.launcherOpen
        width: 360
        height: 300
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 112
        cornerRadius: 26
        glassOpacity: 0.94

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            Label {
                text: "Applications"
                color: "#f5f7fc"
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }

            Button {
                text: "Terminal"
                onClicked: {
                    SystemActions.launch("xterm")
                    root.launcherOpen = false
                }
            }

            Button {
                text: "File Manager"
                onClicked: {
                    SystemActions.launch("pcmanfm")
                    root.launcherOpen = false
                }
            }

            Button {
                text: "System Settings"
                onClicked: {
                    root.settingsOpen = true
                    root.launcherOpen = false
                }
            }
        }
    }

    GlassPanel {
        visible: root.settingsOpen
        width: 390
        height: 250
        anchors.centerIn: parent
        cornerRadius: 26
        glassOpacity: 0.96

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12

            Label {
                text: "LokiOS Settings"
                color: "#f5f7fc"
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }

            Label {
                text: "Desktop preview"
                color: "#d3dbea"
            }

            Label {
                text: "Display and hardware controls are coming next."
                color: "#aebbd0"
                wrapMode: Text.WordWrap
            }

            Button {
                text: "Close"
                onClicked: root.settingsOpen = false
            }
        }
    }
}
