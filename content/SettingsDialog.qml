
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Dialog {
    id: settingsDialog
    title: qsTr("Settings")
    modal: true
    width: parent.width/2
    height: parent.height/2
    anchors.centerIn: parent
    
    // Dark theme background
    background: Rectangle {
        color: "#1e293b"
        border.color: "#334155"
        radius: 8
    }

    signal logoutRequested()
    signal reloadRssSource()
    signal autoRefreshChanged(int minutes)

    contentItem: SplitView {
        orientation: Qt.Horizontal
        
        handle: Rectangle {
            implicitWidth: 1
            color: "#334155"
        }

        // Left Sidebar: Navigation
        Rectangle {
            SplitView.preferredWidth: 200
            SplitView.minimumWidth: 150
            SplitView.maximumWidth: 300
            color: "#0f172a"

            ListView {
                id: navList
                anchors.fill: parent
                model: ListModel {
                    ListElement { name: "Change Password"; icon: "🔒"; page: "password" }
                    ListElement { name: "Change Username"; icon: "👤"; page: "username" }
                    ListElement { name: "Proxy Settings"; icon: "🌐"; page: "proxy" }
                    ListElement { name: "OPML Import/Export"; icon: "🧩"; page: "opml" }
                    ListElement { name: "About"; icon: "ℹ️"; page: "about" }
                    ListElement { name: "Quit"; icon: "🚪"; page: "quit" }
                }

                delegate: ItemDelegate {
                    width: ListView.view.width
                    height: 50
                    highlighted: ListView.isCurrentItem

                    contentItem: RowLayout {
                        spacing: 10
                        Text {
                            text: model.icon
                            font.pixelSize: 16
                            color: "#cbd5e1"
                        }
                        Text {
                            text: model.name
                            color: highlighted ? "#ffffff" : "#cbd5e1"
                            font.bold: highlighted
                            Layout.fillWidth: true
                        }
                    }

                    background: Rectangle {
                        color: highlighted ? "#3b82f6" : (parent.hovered ? "#334155" : "transparent")
                    }

                    onClicked: {
                        if (model.page === "quit") {
                            settingsDialog.close()
                            settingsDialog.logoutRequested()
                        } else {
                            navList.currentIndex = index
                            stackLayout.currentIndex = index
                        }
                    }
                }
            }
        }

        // Right Content Area
    Rectangle {
        SplitView.fillWidth: true
        color: "#1e293b"
        
        StackLayout {
            id: stackLayout
            anchors.fill: parent
            anchors.margins: 20
            currentIndex: 0

            // 1. Change Password Page
            Component {
                 id: passwordPage
                 ColumnLayout {
                    spacing: 30
                    Label { 
                        text: qsTr("Change Password")
                        font.pixelSize: 20
                        font.bold: true
                        color: "#f8fafc"
                    }
                    
                    TextField {
                        id: originalPassword
                        Layout.fillWidth: true
                        placeholderText: qsTr("Current Password")
                        echoMode: TextInput.Password
                        color: "#f8fafc"
                        background: Rectangle { color: "#0f172a"; radius: 4; border.color: "#334155" }
                    }
                    TextField {
                        id: password
                        Layout.fillWidth: true
                        placeholderText: qsTr("New Password")
                        echoMode: TextInput.Password
                        color: "#f8fafc"
                        background: Rectangle { color: "#0f172a"; radius: 4; border.color: "#334155" }
                    }
                    TextField {
                        id: passwordN
                        Layout.fillWidth: true
                        placeholderText: qsTr("Confirm New Password")
                        echoMode: TextInput.Password
                        color: "#f8fafc"
                        background: Rectangle { color: "#0f172a"; radius: 4; border.color: "#334155" }
                    }
                    Label { 
                        id: errorMessage
                        text: ""
                        font.pixelSize: 10
                        font.bold: true
                        color: "#e74d15ff"
                        visible: false
                        Layout.topMargin: -15  
                    }
                    Button {
                        Layout.alignment: Qt.AlignRight
                        text: qsTr("Update Password")
                        background: Rectangle { color: "#3b82f6"; radius: 4 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: {
                              if(String(password.text)!=String(passwordN.text)){
                                  errorMessage.visible = true
                                  errorMessage.text="Password is not alignned"
                                  return 
                              }
                              if(!databaseManager.changePassword(String(originalPassword.text),String(passwordN.text))){
                                 errorMessage.visible = true
                                 errorMessage.text="Password Wrong"
                                 return
                              }
                              else{
                               errorMessage.visible = true
                               errorMessage.text = "Modify Suceess"
                               errorMessage.color = "#f8fafc"
                              }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.fillWidth: true } // Spacer
                }
            }

            Loader { sourceComponent: passwordPage; active: stackLayout.currentIndex === 0 }

            // 2. Change Username Page
            Component {
                id: usernamePage
                ColumnLayout {
                    spacing: 30
                    Label { 
                        text: qsTr("Change Username")
                        font.pixelSize: 20
                        font.bold: true
                        color: "#f8fafc"
                    }
                    
                    TextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("New Username")
                        color: "#f8fafc"
                        background: Rectangle { color: "#0f172a"; radius: 4; border.color: "#334155" }
                    }
                    Button {        
                        Layout.alignment: Qt.AlignRight
                        text: qsTr("Update Username")
                        background: Rectangle { color: "#3b82f6"; radius: 4 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                    Item { Layout.fillHeight: true } // Spacer
                }
            }

            Loader { sourceComponent: usernamePage; active: stackLayout.currentIndex === 1 }

            // 3. Proxy Settings Page
            Component {
                id: proxyPage
                ColumnLayout {
                    spacing: 20
                    Label { 
                        text: qsTr("Proxy Settings")
                        font.pixelSize: 20
                        font.bold: true
                        color: "#f8fafc"
                    }

                    CheckBox {
                        id: proxyEnabled
                        text: qsTr("Enable Proxy")
                        contentItem: Text {
                            text: proxyEnabled.text
                            color: "#f8fafc"
                            leftPadding: proxyEnabled.indicator.width + proxyEnabled.spacing
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    RowLayout {
                        spacing: 10
                        visible: proxyEnabled.checked
                        Label { text: "Type:"; color: "#cbd5e1" }
                        ComboBox {
                            id: proxyType
                            model: ListModel {
                                ListElement { text: "HTTP"; value: 3 }
                                ListElement { text: "SOCKS5"; value: 1 }
                            }
                            textRole: "text"
                            valueRole: "value"
                            Layout.preferredWidth: 120
                        }
                    }

                    RowLayout {
                        spacing: 10
                        visible: proxyEnabled.checked
                        TextField {
                            id: proxyHost
                            Layout.fillWidth: true
                            placeholderText: qsTr("Host / IP")
                            color: "#f8fafc"
                            background: Rectangle { color: "#0f172a"; radius: 4; border.color: "#334155" }
                        }
                        TextField {
                            id: proxyPort
                            Layout.preferredWidth: 80
                            placeholderText: qsTr("Port")
                            color: "#f8fafc"
                            background: Rectangle { color: "#0f172a"; radius: 4; border.color: "#334155" }
                            validator: IntValidator { bottom: 1; top: 65535 }
                        }
                    }

                    RowLayout {
                        spacing: 10
                        visible: proxyEnabled.checked
                        TextField {
                            id: proxyUser
                            Layout.fillWidth: true
                            placeholderText: qsTr("Username (Optional)")
                            color: "#f8fafc"
                            background: Rectangle { color: "#0f172a"; radius: 4; border.color: "#334155" }
                        }
                        TextField {
                            id: proxyPass
                            Layout.fillWidth: true
                            placeholderText: qsTr("Password (Optional)")
                            echoMode: TextInput.Password
                            color: "#f8fafc"
                            background: Rectangle { color: "#0f172a"; radius: 4; border.color: "#334155" }
                        }
                    }

                    Button {
                        Layout.alignment: Qt.AlignRight
                        text: qsTr("Save Proxy Settings")
                        background: Rectangle { color: "#3b82f6"; radius: 4 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: {
                            var typeVal = 3; 
                            if (proxyType.currentText === "SOCKS5") typeVal = 1;
                            
                            settingsManager.saveProxy(
                                proxyEnabled.checked,
                                typeVal,
                                proxyHost.text,
                                proxyPort.text,
                                proxyUser.text,
                                proxyPass.text
                            )
                        }
                    }
                    
                    Item { Layout.fillHeight: true } 
                    
                    Component.onCompleted: {
                        var settings = settingsManager.getProxy()
                        proxyEnabled.checked = settings.enabled
                        proxyHost.text = settings.host
                        proxyPort.text = settings.port
                        proxyUser.text = settings.username
                        proxyPass.text = settings.password
                        
                        if (settings.type === 1) {
                            proxyType.currentIndex = 1
                        } else {
                            proxyType.currentIndex = 0
                        }
                    }
                }
            }

            Loader { sourceComponent: proxyPage; active: stackLayout.currentIndex === 2 }

            // 4. OPML Import/Export Page
            Component {
                id: opmlPage
                ColumnLayout {
                    spacing: 20
                    Label {
                        text: qsTr("OPML Import/Export")
                        font.pixelSize: 20
                        font.bold: true
                        color: "#f8fafc"
                    }

                    Label {
                        text: qsTr("Import or export your subscriptions in OPML format.")
                        color: "#cbd5e1"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 10
                        Button {
                            text: qsTr("Import OPML")
                            background: Rectangle { color: "#3b82f6"; radius: 4 }
                            contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: opmlImportDialog.open()
                        }
                        Item {
                                Layout.fillWidth: true 
                        }

                        Button {
                            text: qsTr("Export OPML")
                            background: Rectangle { color: "#3b82f6"; radius: 4 }
                            contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: opmlExportDialog.open()
                        }
                    }

                    Label {
                        id: opmlMessage
                        text: ""
                        color: "#f8fafc"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        visible: text !== ""
                    }

                    Connections {
                        target: opmlImportDialog
                        function onAccepted() {
                             opmlMessage.text = databaseManager.importOpml(opmlImportDialog.selectedFile)
                             settingsDialog.reloadRssSource()
                        }
                    }

                    Connections {
                        target: opmlExportDialog
                        function onAccepted() {
                             opmlMessage.text = databaseManager.exportOpml(opmlExportDialog.selectedFile)
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
            
            Loader { sourceComponent: opmlPage; active: stackLayout.currentIndex === 3 }
            
            // 5. Auto Refresh Page
            Component {
                id: refreshPage
                ColumnLayout {
                    spacing: 20
                    Label {
                        text: qsTr("Auto Refresh Settings")
                        font.pixelSize: 20
                        font.bold: true
                        color: "#f8fafc"
                    }
                    
                    RowLayout {
                        spacing: 10
                        Label { text: "Refresh Interval:"; color: "#cbd5e1" }
                        ComboBox {
                            id: refreshIntervalCombo
                            model: ["Disabled", "1 Minute", "5 Minutes", "15 Minutes", "30 Minutes", "60 Minutes"]
                            Layout.preferredWidth: 200
                        }
                    }

                    Button {
                        text: qsTr("Save Refresh Settings")
                        background: Rectangle { color: "#3b82f6"; radius: 4 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: {
                            var minutes = 0;
                            switch(refreshIntervalCombo.currentIndex) {
                                case 1: minutes = 1; break;
                                case 2: minutes = 5; break;
                                case 3: minutes = 15; break;
                                case 4: minutes = 30; break;
                                case 5: minutes = 60; break;
                            }
                            settingsManager.saveAutoRefresh(minutes);
                            settingsDialog.autoRefreshChanged(minutes);
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                    
                    Component.onCompleted: {
                        var minutes = settingsManager.getAutoRefresh();
                        var index = 0;
                        if (minutes === 1) index = 1;
                        else if (minutes === 5) index = 2;
                        else if (minutes === 15) index = 3;
                        else if (minutes === 30) index = 4;
                        else if (minutes === 60) index = 5;
                        refreshIntervalCombo.currentIndex = index;
                    }
                }
            }
            
            Loader { sourceComponent: refreshPage; active: stackLayout.currentIndex === 4 }

            // 6. About Page
            Component {
                id: aboutPage
                ColumnLayout {
                    spacing: 15
                    Label { 
                        text: qsTr("About RSS Reader")
                        font.pixelSize: 20
                        font.bold: true
                        color: "#f8fafc"
                    }
                    Label { 
                        text: qsTr("Version 1.0.0\nA simple and modern RSS reader built with Qt Quick.")
                        color: "#cbd5e1"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    Item { Layout.fillHeight: true } // Spacer
                }
            }

            Loader { sourceComponent: aboutPage; active: stackLayout.currentIndex === 5 }
        }
    }
    }

    FileDialog {
        id: opmlImportDialog
        title: qsTr("Import OPML")
        nameFilters: [qsTr("OPML files (*.opml)"), qsTr("All files (*)")]
        fileMode: FileDialog.OpenFile
        onAccepted: {
            opmlMessage.text = databaseManager.importOpml(selectedFile)
            settingsDialog.reload()
            }
        }

    FileDialog {
        id: opmlExportDialog
        title: qsTr("Export OPML")
        nameFilters: [qsTr("OPML files (*.opml)"), qsTr("All files (*)")]
        fileMode: FileDialog.SaveFile
        onAccepted: {
            opmlMessage.text = databaseManager.exportOpml(selectedFile)
        }
    }
}
