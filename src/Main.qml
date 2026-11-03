import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: root
    width: 1440
    height: 900
    minimumWidth: 960
    minimumHeight: 640
    visible: true
    title: "LokiOS"
    color: "#080d18"
    property string activePanel: "home"
    property bool welcomeVisible: true
    property bool menuOpen: false
    property bool quickOpen: false
    property string searchText: ""

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#101a2b" }
            GradientStop { position: 0.48; color: "#0b1422" }
            GradientStop { position: 1; color: "#070b13" }
        }
    }
    Rectangle {
        width: 760; height: 760; radius: 380
        x: parent.width * 0.58 - width / 2; y: parent.height * 0.12 - height / 2
        color: "#244d86"; opacity: 0.16
        Behavior on opacity { NumberAnimation { duration: 900 } }
    }
    Rectangle {
        width: 520; height: 520; radius: 260
        x: parent.width * 0.12 - width / 2; y: parent.height * 0.78 - height / 2
        color: "#563a86"; opacity: 0.12
    }

    // Floating system bar
    GlassPanel {
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        anchors.margins: 16; height: 58; cornerRadius: 19; glassOpacity: 0.72
        Row {
            anchors.left: parent.left; anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter; spacing: 12
            Label { text: "◈"; color: "#9dc8ff"; font.pixelSize: 22 }
            Label { text: "LokiOS"; color: "#f4f7ff"; font.pixelSize: 16; font.weight: Font.DemiBold }
            Rectangle { width: 1; height: 22; color: "#35ffffff"; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Workspace"; color: "#aebbd0"; font.pixelSize: 13 }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter; spacing: 15
            Label { text: "◉  Connected"; color: "#9eb6c9"; font.pixelSize: 12 }
            ToolButton {
                text: "⌃"; font.pixelSize: 18
                palette.buttonText: "#eaf1ff"
                background: Rectangle { radius: 10; color: parent.hovered ? "#25ffffff" : "transparent" }
                onClicked: root.quickOpen = !root.quickOpen
            }
            Label {
                text: Qt.formatDateTime(new Date(), "ddd  d MMM  •  h:mm AP")
                color: "#e3eaf7"; font.pixelSize: 13
            }
        }
    }

    // Desktop welcome / home content
    Column {
        anchors.centerIn: parent; spacing: 12
        visible: root.activePanel === "home"
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
        Label { anchors.horizontalCenter: parent.horizontalCenter; text: "◈"; color: "#9fcaff"; font.pixelSize: 46 }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Good to see you."
            color: "#f4f7ff"; font.pixelSize: 42; font.weight: Font.Light
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "A calmer space for everything you do."
            color: "#a9b8ce"; font.pixelSize: 16
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
            Button {
                text: "Explore apps"
                onClicked: root.activePanel = "apps"
                contentItem: Label { text: parent.text; color: "#102033"; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: 13; color: "#b9d9ff" }
            }
            Button {
                text: "Personalize"
                onClicked: root.activePanel = "settings"
                contentItem: Label { text: parent.text; color: "#eaf2ff"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: 13; color: "#25ffffff"; border.color: "#35ffffff" }
            }
        }
    }

    // Start / application panel
    GlassPanel {
        id: appPanel
        width: 500; height: 560
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: dock.top; anchors.bottomMargin: 16
        cornerRadius: 26; glassOpacity: 0.94
        visible: root.activePanel !== "home"
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Column {
            anchors.fill: parent; anchors.margins: 25; spacing: 17
            Row {
                width: parent.width
                Label {
                    text: root.activePanel === "apps" ? "Your apps" : root.activePanel === "files" ? "Your files" : "System settings"
                    color: "#f4f7ff"; font.pixelSize: 27; font.weight: Font.DemiBold
                }
                Item { width: 1; height: 1 }
                ToolButton { anchors.right: parent.right; text: "×"; font.pixelSize: 22; palette.buttonText: "#cbd7e8"; onClicked: root.activePanel = "home" }
            }
            TextField {
                id: search; width: parent.width; placeholderText: "Search applications"
                color: "#f4f7ff"; placeholderTextColor: "#8292aa"
                background: Rectangle { radius: 13; color: "#1cffffff"; border.color: "#25ffffff" }
                onTextChanged: root.searchText = text.toLowerCase()
            }
            Grid {
                columns: 2; spacing: 12
                Repeater {
                    model: [
                        {name:"Terminal", detail:"Command line", glyph:"›_", cmd:"terminal"},
                        {name:"Files", detail:"Browse your folders", glyph:"▰", cmd:"files"},
                        {name:"Appearance", detail:"Customize your desktop", glyph:"◐", cmd:"appearance"},
                        {name:"Install LokiOS", detail:"Install to a computer", glyph:"⬇", cmd:"installer"}
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: 211; height: 100; radius: 17
                        visible: root.searchText.length === 0 || modelData.name.toLowerCase().includes(root.searchText)
                        color: mouse.containsMouse ? "#25b6d8ff" : "#14ffffff"
                        border.color: "#24ffffff"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Row {
                            anchors.fill: parent; anchors.margins: 14; spacing: 12
                            Label { text: modelData.glyph; color: "#a9d2ff"; font.pixelSize: 27; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                Label { text: modelData.name; color: "#f2f6ff"; font.pixelSize: 14; font.weight: Font.DemiBold }
                                Label { text: modelData.detail; color: "#9eacc1"; font.pixelSize: 11 }
                            }
                        }
                        MouseArea {
                            id: mouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                if (modelData.cmd === "terminal") SystemActions.launch("xterm")
                                else if (modelData.cmd === "files") SystemActions.launch("pcmanfm")
                                else if (modelData.cmd === "appearance") SystemActions.launch("lxappearance")
                                else if (modelData.cmd === "installer") SystemActions.launchInstaller()
                            }
                        }
                    }
                }
            }
            Item { width: 1; height: 1; Layout.fillHeight: true }
            Label { text: "LokiOS  •  Debian 13  •  Linux 6.12"; color: "#71839d"; font.pixelSize: 11 }
        }
    }

    // Quick settings flyout
    GlassPanel {
        width: 300; height: 210
        anchors.top: parent.top; anchors.right: parent.right
        anchors.topMargin: 84; anchors.rightMargin: 18
        cornerRadius: 20; glassOpacity: 0.96; visible: root.quickOpen
        Column {
            anchors.fill: parent; anchors.margins: 20; spacing: 13
            Label { text: "Quick settings"; color: "#f4f7ff"; font.pixelSize: 19; font.weight: Font.DemiBold }
            Label { text: "Network"; color: "#b8c7db"; font.pixelSize: 13 }
            Label { text: "Power and session"; color: "#b8c7db"; font.pixelSize: 13 }
            Label { text: "LokiOS preview build"; color: "#71839d"; font.pixelSize: 11 }
        }
    }

    // Bottom dock
    GlassPanel {
        id: dock
        width: dockRow.implicitWidth + 30; height: 76
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom
        anchors.bottomMargin: 22; cornerRadius: 25; glassOpacity: 0.86
        Row {
            id: dockRow; anchors.centerIn: parent; spacing: 7
            Repeater {
                model: [
                    {label:"◈", name:"Home", panel:"home"},
                    {label:"▦", name:"Apps", panel:"apps"},
                    {label:"▰", name:"Files", panel:"files"},
                    {label:"⚙", name:"Settings", panel:"settings"}
                ]
                delegate: ToolButton {
                    required property var modelData
                    width: 56; height: 56; text: modelData.label; font.pixelSize: 24
                    palette.buttonText: "#edf4ff"
                    background: Rectangle { radius: 17; color: parent.hovered ? "#30ffffff" : "transparent" }
                    ToolTip.visible: hovered; ToolTip.text: modelData.name
                    onClicked: { root.activePanel = modelData.panel; root.quickOpen = false }
                }
            }
        }
    }

    // First-session welcome card
    Rectangle {
        anchors.fill: parent; color: "#99050a13"; visible: root.welcomeVisible
        Rectangle {
            width: 470; height: 350; radius: 28
            anchors.centerIn: parent; color: "#ed172438"
            border.color: "#48ffffff"
            Column {
                anchors.centerIn: parent; width: parent.width - 60; spacing: 14
                Label { anchors.horizontalCenter: parent.horizontalCenter; text: "◈"; color: "#a9d2ff"; font.pixelSize: 48 }
                Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Welcome to LokiOS"; color: "#f5f8ff"; font.pixelSize: 27; font.weight: Font.DemiBold }
                Label {
                    width: parent.width; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                    text: "A fresh, focused desktop. Explore your apps, make it yours, and get comfortable."
                    color: "#b8c7db"; font.pixelSize: 14
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Get started"; onClicked: root.welcomeVisible = false
                    contentItem: Label { text: parent.text; color: "#102033"; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 13; color: "#b9d9ff" }
                }
            }
        }
    }
}
