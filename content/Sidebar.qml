
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#1e293b"

    property var rssFeedsModel: null
    property string currentFeedUrl: ""
    property var addDialog: null
    property var settingsDialog: null
    property var starList: null
    property var currentPage: null
    
    signal feedSelected(string url)
    signal feedDeleted(string url)
    signal switchStar()
    
    // Drag and drop support
    DropArea {
        anchors.fill: parent
        onEntered: (drag) => {
            drag.accept(Qt.LinkAction);
        }
        onDropped: (drop) => {
            if (drop.hasText) {
                var url = drop.text;
                // Simple validation
                if (url.startsWith("http")) {
                     if (addDialog) {
                         addDialog.feedUrl = url
                         // Try to extract a name from domain
                         var domain = url.split('/')[2]
                         addDialog.feedName = domain
                         addDialog.open()
                     }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Material Design Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120 // Taller header
            color: "#0f172a" // Darker shade for header
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 8
                
                RowLayout {
                    spacing: 12
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: "#3b82f6"
                        Text {
                            anchors.centerIn: parent
                            text: "R"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 18
                        }
                    }
                    Text { 
                        text: "RSS Reader"
                        color: "#f8fafc" 
                        font.bold: true
                        font.pixelSize: 20 
                        font.family: "Roboto"
                    }
                }
                
                Text { 
                    text: "Your daily news feed"
                    color: "#94a3b8" 
                    font.pixelSize: 13
                    Layout.topMargin: -4
                }
            }
        }

        // FAB-like Add Button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            color: "transparent"
            
            Button {
                id: addBtn
                text: "New Subscription"
                anchors.centerIn: parent
                width: parent.width - 32
                height: 48
                
                background: Rectangle {
                    color: addBtn.pressed ? "#1d4ed8" : "#3b82f6"
                    radius: 24 // Pill shape
                    border.width: 0
                    
                    // Shadow simulation
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 2
                        z: -1
                        color: "#000000"
                        opacity: 0.2
                        radius: 24
                    }
                }
                
                contentItem: RowLayout {
                    spacing: 8
                    anchors.centerIn: parent
                    Text {
                        text: "+"
                        color: "white"
                        font.pixelSize: 20
                        font.bold: true
                    }
                    Text {
                        text: "New Subscription"
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                    }
                }
                
                onClicked: {
                    if (addDialog) addDialog.open()
                }
            }
        }

        // Navigation Menu
        ListView {
            id: feedList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 8
            clip: true
            spacing: 4

            model: rssFeedsModel

            header: Column {
                width: parent.width
                spacing: 4
                
                // Favorites Item
                Rectangle {
                    width: parent.width - 16
                    height: 48
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 24 // Rounded corners
                    color: root.currentPage !== "rss" ? "#1e293b" : "transparent"
                    border.color: root.currentPage !== "rss" ? "#334155" : "transparent"
                    
                    // Selection indicator
                    Rectangle {
                        visible: root.currentPage !== "rss"
                        width: 4
                        height: 24
                        color: "#fbbf24"
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 2
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 24 // Indent text
                        anchors.rightMargin: 16
                        spacing: 16
                        
                        Text {
                            text: "★"
                            color: "#fbbf24"
                            font.pixelSize: 18
                        }
                        
                        Text {
                            text: "Favorites"
                            color: "#f8fafc"
                            font.pixelSize: 14
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.color = root.currentPage !== "rss" ? "#1e293b" : "#334155"
                        onExited: parent.color = root.currentPage !== "rss" ? "#1e293b" : "transparent"
                        onClicked: root.switchStar()
                    }
                }
                
                // Divider with label
                Item {
                    width: parent.width
                    height: 40
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        Text {
                            text: "SUBSCRIPTIONS"
                            color: "#64748b"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.2
                        }
                    }
                }
            }

            delegate: ItemDelegate {
                width: ListView.view.width - 16
                height: 48
                anchors.horizontalCenter: parent.horizontalCenter
                
                property bool isSelected: root.currentFeedUrl === model.feed && root.currentPage === "rss"
                
                background: Rectangle {
                    radius: 24
                    color: isSelected ? "#334155" : (parent.hovered ? "#1e293b" : "transparent")
                    
                    // Active indicator
                    Rectangle {
                        visible: isSelected
                        width: 4
                        height: 24
                        color: "#3b82f6"
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 2
                    }
                }

                contentItem: RowLayout {
                    spacing: 16
                    anchors.leftMargin: 24
                    
                    // Favicon placeholder (Circle)
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: isSelected ? "#3b82f6" : "#475569"
                        Text {
                            anchors.centerIn: parent
                            text: model.name ? model.name.charAt(0).toUpperCase() : "?"
                            color: "white"
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    Text {
                        text: model.name
                        color: isSelected ? "#60a5fa" : "#cbd5e1"
                        font.pixelSize: 14
                        font.weight: isSelected ? Font.DemiBold : Font.Normal
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
                
                onClicked: root.feedSelected(model.feed)

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            contextMenu.popup()
                        }
                    }

                    Menu {
                        id: contextMenu
                        MenuItem {
                            text: "删除"
                            onTriggered: {
                                console.log("尝试删除订阅源 ID:", model.id)
                                var deletedUrl = model.feed
                                if (databaseManager.deleteRssFeed(model.id)) {
                                    if (root.rssFeedsModel) {
                                        root.rssFeedsModel.reloadFeeds()
                                    }
                                    if (deletedUrl === root.currentFeedUrl) {
                                        root.feedDeleted(deletedUrl)
                                    }
                                } else {
                                    console.log("删除失败")
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Settings / Bottom Area
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "transparent"
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                
                Item { Layout.fillWidth: true }
                
                Button {
                    icon.name: "settings" // Basic icon if available
                    text: "⚙ Settings"
                    flat: true
                    contentItem: Text {
                        text: "⚙ Settings"
                        color: "#94a3b8"
                        font.pixelSize: 13
                    }
                    background: Rectangle { color: "transparent" }
                    onClicked: {
                        if (root.settingsDialog) root.settingsDialog.open()
                    }
                }
            }
        }
    }
}
