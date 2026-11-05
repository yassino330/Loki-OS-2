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
    visibility: root.installerOpen ? Window.FullScreen : Window.Maximized
    title: "LokiOS"
    color: "#080d18"
    property string activePanel: "home"
    property bool welcomeVisible: false
    property bool menuOpen: false
    property bool installerOpen: false
    property bool quickOpen: false
    property string searchText: ""

    Shortcut {
        sequence: "Meta"
        context: Qt.ApplicationShortcut
        onActivated: root.activePanel = root.activePanel === "apps" ? "home" : "apps"
    }
    Shortcut {
        sequence: "Ctrl+Alt+T"
        context: Qt.ApplicationShortcut
        onActivated: SystemActions.launch("xfce4-terminal")
    }
    Shortcut {
        sequence: "Ctrl+Alt+F"
        context: Qt.ApplicationShortcut
        onActivated: SystemActions.launch("pcmanfm")
    }
    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (root.installerOpen) root.installerOpen = false
            else if (root.quickOpen) root.quickOpen = false
            else root.activePanel = "home"
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#172a48" }
            GradientStop { position: 0.42; color: "#101a31" }
            GradientStop { position: 1; color: "#070b17" }
        }
    }
    Rectangle {
        width: 760; height: 760; radius: 380
        x: parent.width * 0.58 - width / 2; y: parent.height * 0.12 - height / 2
        color: "#4b9cff"; opacity: 0.19
        Behavior on opacity { NumberAnimation { duration: 900 } }
    }
    Rectangle {
        width: 520; height: 520; radius: 260
        x: parent.width * 0.12 - width / 2; y: parent.height * 0.78 - height / 2
        color: "#8b5cf6"; opacity: 0.16
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
            Label { text: "LIQUID GLASS"; color: "#9eb6c9"; font.pixelSize: 10; font.letterSpacing: 1.8 }
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

    // Modern LokiOS dashboard
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -12
        width: Math.min(parent.width - 100, 900)
        spacing: 22
        visible: root.activePanel === "home"
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 240 } }

        Row {
            width: parent.width
            spacing: 24
            Column {
                width: parent.width * 0.62
                spacing: 9
                Label {
                    text: Qt.formatDateTime(new Date(), "dddd, d MMMM")
                    color: "#a9c4e4"; font.pixelSize: 14; font.letterSpacing: 1.1
                }
                Label {
                    text: "Your space.\nYour pace."
                    color: "#f5f8ff"; font.pixelSize: 54; font.weight: Font.Light
                    lineHeight: 0.98
                }
                Label {
                    text: "A calmer, clearer space for everything you do."
                    color: "#b6c6dc"; font.pixelSize: 16
                }
                Row {
                    spacing: 10
                    Button {
                        text: "Open applications"
                        onClicked: root.activePanel = "apps"
                        contentItem: Label { text: parent.text; color: "#102033"; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 14; gradient: Gradient { GradientStop { position: 0; color: "#e2f2ff" } GradientStop { position: 1; color: "#9bcaff" } } }
                    }
                    Button {
                        text: "Personalize"
                        onClicked: root.activePanel = "settings"
                        contentItem: Label { text: parent.text; color: "#edf5ff"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 14; color: "#24ffffff"; border.color: "#45ffffff" }
                    }
                }
            }
            GlassPanel {
                width: parent.width * 0.34; height: 190
                cornerRadius: 25; glassOpacity: 0.66
                Column {
                    anchors.fill: parent; anchors.margins: 20; spacing: 8
                    Label { text: "LOCAL TIME"; color: "#9bb8d9"; font.pixelSize: 10; font.letterSpacing: 1.8 }
                    Label { text: Qt.formatDateTime(new Date(), "h:mm"); color: "#f4f8ff"; font.pixelSize: 54; font.weight: Font.Light }
                    Label { text: Qt.formatDateTime(new Date(), "dddd  •  d MMMM"); color: "#b8c9df"; font.pixelSize: 13 }
                    Rectangle { width: parent.width; height: 1; color: "#28ffffff" }
                    Label { text: "LokiOS  ·  Liquid Glass"; color: "#9fcaff"; font.pixelSize: 12 }
                }
            }
        }

        Row {
            width: parent.width; spacing: 14
            GlassPanel {
                width: (parent.width - 28) / 3; height: 118; cornerRadius: 21; glassOpacity: 0.58
                Row {
                    anchors.fill: parent; anchors.margins: 17; spacing: 13
                    Label { text: "◎"; color: "#a9d2ff"; font.pixelSize: 30; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 5
                        Label { text: "Browse the web"; color: "#f3f7ff"; font.pixelSize: 14; font.weight: Font.DemiBold }
                        Label { text: "Chromium is ready"; color: "#9eafc7"; font.pixelSize: 11 }
                    }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: SystemActions.launch("chromium") }
            }
            GlassPanel {
                width: (parent.width - 28) / 3; height: 118; cornerRadius: 21; glassOpacity: 0.58
                Row {
                    anchors.fill: parent; anchors.margins: 17; spacing: 13
                    Label { text: "▰"; color: "#b5aaff"; font.pixelSize: 29; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 5
                        Label { text: "Your files"; color: "#f3f7ff"; font.pixelSize: 14; font.weight: Font.DemiBold }
                        Label { text: "Open your workspace"; color: "#9eafc7"; font.pixelSize: 11 }
                    }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: SystemActions.launch("pcmanfm") }
            }
            GlassPanel {
                width: (parent.width - 28) / 3; height: 118; cornerRadius: 21; glassOpacity: 0.58
                Row {
                    anchors.fill: parent; anchors.margins: 17; spacing: 13
                    Label { text: "✧"; color: "#ffc98e"; font.pixelSize: 30; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 5
                        Label { text: "Make it yours"; color: "#f3f7ff"; font.pixelSize: 14; font.weight: Font.DemiBold }
                        Label { text: "Tune your desktop"; color: "#9eafc7"; font.pixelSize: 11 }
                    }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.activePanel = "settings" }
            }
        }
        Label {
            text: "LOKI OS  /  A NEW KIND OF DESKTOP"
            color: "#7087a5"; font.pixelSize: 10; font.letterSpacing: 2.2
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Start / application panel
    GlassPanel {
        id: appPanel
        width: Math.min(740, parent.width - 48); height: 640
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
                columns: 3; spacing: 12
                Repeater {
                    model: [
                        {name:"Browser", detail:"Browse the web", glyph:"◎", cmd:"browser"},
                        {name:"Terminal", detail:"Command line", glyph:"›_", cmd:"terminal"},
                        {name:"Files", detail:"Browse your folders", glyph:"▰", cmd:"files"},
                        {name:"Text Editor", detail:"Write and edit files", glyph:"T", cmd:"editor"},
                        {name:"Appearance", detail:"Customize your desktop", glyph:"◐", cmd:"appearance"},
                        {name:"Network", detail:"Wi-Fi and connections", glyph:"⌁", cmd:"network"},
                        {name:"Sound", detail:"Audio devices and volume", glyph:"♫", cmd:"sound"},
                        {name:"Bluetooth", detail:"Pair wireless devices", glyph:"ᛒ", cmd:"bluetooth"},
                        {name:"Power", detail:"Battery and power options", glyph:"ϟ", cmd:"power"},
                        {name:"System Monitor", detail:"Processes and memory", glyph:"▥", cmd:"monitor"},
                        {name:"Screenshot", detail:"Capture your screen", glyph:"▧", cmd:"screenshot"},
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
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            focus: true
                            activeFocusOnTab: true
                            function activateApp() {
                                if (modelData.cmd === "browser") SystemActions.launch("chromium")
                                else if (modelData.cmd === "terminal") SystemActions.launch("xfce4-terminal")
                                else if (modelData.cmd === "files") SystemActions.launch("pcmanfm")
                                else if (modelData.cmd === "editor") SystemActions.launch("mousepad")
                                else if (modelData.cmd === "appearance") SystemActions.launch("lxappearance")
                                else if (modelData.cmd === "network") SystemActions.launch("nm-connection-editor")
                                else if (modelData.cmd === "sound") SystemActions.launch("pavucontrol")
                                else if (modelData.cmd === "bluetooth") SystemActions.launch("blueman-manager")
                                else if (modelData.cmd === "power") SystemActions.launch("xfce4-power-manager-settings")
                                else if (modelData.cmd === "monitor") SystemActions.launch("xfce4-taskmanager")
                                else if (modelData.cmd === "screenshot") SystemActions.launch("xfce4-screenshooter")
                                else if (modelData.cmd === "installer") { root.installerOpen = true; root.activePanel = "home" }
                            }
                            onClicked: activateApp()
                            Keys.onReturnPressed: activateApp()
                            Keys.onSpacePressed: activateApp()
                        }
                    }
                }
            }
            Label { text: "LokiOS Beta Preview  •  Linux kernel 6.12"; color: "#71839d"; font.pixelSize: 11 }
        }
    }

    // Quick settings flyout
    GlassPanel {
        width: 340; height: 290
        anchors.top: parent.top; anchors.right: parent.right
        anchors.topMargin: 84; anchors.rightMargin: 18
        cornerRadius: 20; glassOpacity: 0.96; visible: root.quickOpen
        Column {
            anchors.fill: parent; anchors.margins: 18; spacing: 9
            Label { text: "Quick settings"; color: "#f4f7ff"; font.pixelSize: 19; font.weight: Font.DemiBold }
            Grid {
                columns: 2; spacing: 8
                Button { text: "Wi-Fi & Network"; onClicked: SystemActions.launch("nm-connection-editor") }
                Button { text: "Sound"; onClicked: SystemActions.launch("pavucontrol") }
                Button { text: "Bluetooth"; onClicked: SystemActions.launch("blueman-manager") }
                Button { text: "Power"; onClicked: SystemActions.launch("xfce4-power-manager-settings") }
            }
            Label { text: "LokiOS • Chromium • Linux 6.12"; color: "#9eb6c9"; font.pixelSize: 11 }
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


    // Guided installer hand-off: disk selection and explicit destructive confirmation.
    Rectangle {
        anchors.fill: parent
        z: 20
        visible: root.installerOpen
        color: "#cc050a13"
        Rectangle {
            width: Math.min(parent.width - 64, 920); height: Math.min(parent.height - 64, 760); radius: 30
            anchors.centerIn: parent
            color: "#f018263b"
            border.color: "#55ffffff"
            Column {
                anchors.fill: parent; anchors.margins: 30; spacing: 16
                Row {
                    width: parent.width
                    Label { text: "Install LokiOS"; color: "#f4f7ff"; font.pixelSize: 29; font.weight: Font.DemiBold }
                    Item { width: 1; height: 1 }
                    ToolButton { anchors.right: parent.right; text: "×"; font.pixelSize: 22; palette.buttonText: "#dce8fa"; onClicked: root.installerOpen = false }
                }
                Label {
                    width: parent.width; wrapMode: Text.WordWrap
                    text: "Choose where LokiOS should be installed. The selected drive will be erased completely."
                    color: "#b8c7db"; font.pixelSize: 14
                }
                Label { text: "INSTALLATION DRIVE"; color: "#91a8c5"; font.pixelSize: 11; font.letterSpacing: 1.2 }
                ComboBox {
                    id: diskPicker
                    width: parent.width
                    model: SystemActions.installDisks()
                    textRole: "label"
                    valueRole: "device"
                    enabled: count > 0
                    background: Rectangle { radius: 12; color: "#25ffffff"; border.color: "#35ffffff" }
                    contentItem: Text {
                        leftPadding: 12; text: diskPicker.displayText
                        color: "#f2f6ff"; verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
                Rectangle {
                    width: parent.width; height: 94; radius: 15
                    color: "#3a8e4e38"; border.color: "#70d69b72"
                    Column {
                        anchors.fill: parent; anchors.margins: 14; spacing: 6
                        Label { text: "⚠  THIS WILL ERASE THE SELECTED DRIVE"; color: "#ffd2a8"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Label {
                            width: parent.width; wrapMode: Text.WordWrap
                            text: "Back up documents and other files first. Installation cannot be undone."
                            color: "#d9c7b8"; font.pixelSize: 12
                        }
                    }
                }
                Label {
                    text: diskPicker.currentValue ? "Type ERASE " + String(diskPicker.currentValue).split("/").pop() + " to confirm" : "No eligible disk detected"
                    color: "#b8c7db"; font.pixelSize: 13
                }
                TextField {
                    id: eraseField; width: parent.width
                    placeholderText: "ERASE " + (diskPicker.currentValue ? String(diskPicker.currentValue).split("/").pop() : "disk")
                    color: "#ffffff"; placeholderTextColor: "#7788a2"
                    background: Rectangle { radius: 12; color: "#1cffffff"; border.color: "#25ffffff" }
                }
                Row {
                    width: parent.width; spacing: 10
                    Button {
                        text: "Cancel"; onClicked: root.installerOpen = false
                        contentItem: Label { text: parent.text; color: "#eaf2ff"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 12; color: "#25ffffff"; border.color: "#35ffffff" }
                    }
                    Button {
                        text: SystemActions.installerRunning ? "Installing…" : "Erase drive and install"
                        enabled: !SystemActions.installerRunning && diskPicker.currentValue && eraseField.text === "ERASE " + String(diskPicker.currentValue).split("/").pop()
                        onClicked: SystemActions.startInstaller(diskPicker.currentValue, eraseField.text)
                        contentItem: Label { text: parent.text; color: "#24160c"; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 12; color: parent.enabled ? "#ffc18e" : "#665f6874" }
                    }
                }
                Label { text: SystemActions.installerStatus; color: "#b9d9ff"; font.pixelSize: 12; font.weight: Font.DemiBold }
                ScrollView {
                    width: parent.width
                    height: 125
                    clip: true
                    background: Rectangle { radius: 12; color: "#b008101c"; border.color: "#25ffffff" }
                    TextArea {
                        readOnly: true
                        wrapMode: TextEdit.Wrap
                        text: SystemActions.installerOutput
                        color: "#c7d7eb"
                        font.family: "monospace"
                        font.pixelSize: 10
                        selectByMouse: true
                        background: Item {}
                    }
                }
                Label { text: "UEFI systems • GPT partition layout • LokiOS ext4"; color: "#71839d"; font.pixelSize: 11 }
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
                    focus: true
                    text: "Get started"; onClicked: root.welcomeVisible = false
                    contentItem: Label { text: parent.text; color: "#102033"; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 13; color: "#b9d9ff" }
                }
            }
        }
    }
}
