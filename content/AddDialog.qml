
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: addDialog
    
    property var rssFeeds: null
    property alias feedUrl: feedInput.text
    property alias feedName: nameInput.text

    title: qsTr("Add New Feed")
    modal: true
    anchors.centerIn: parent
    
    // Dark theme styling
    background: Rectangle {
        color: "#1e293b"
        border.color: "#334155"
        radius: 8
    }
    
    header: Label {
        text: addDialog.title
        color: "#f8fafc"
        font.bold: true
        font.pixelSize: 18
        padding: 15
        background: Rectangle { color: "transparent" }
    }
    
    contentItem: ColumnLayout {
        spacing: 15
        
        Label {
            text: qsTr("Feed Name")
            color: "#cbd5e1"
            font.pixelSize: 14
        }

        TextField {
            id: nameInput
            Layout.fillWidth: true
            placeholderText: qsTr("Enter feed name")
            color: "#f8fafc"
            background: Rectangle {
                color: "#0f172a"
                border.color: parent.activeFocus ? "#3b82f6" : "#334155"
                radius: 4
            }
        }

        Label {
            text: qsTr("RSS URL")
            color: "#cbd5e1"
            font.pixelSize: 14
        }

        TextField {
            id: feedInput
            Layout.fillWidth: true
            placeholderText: qsTr("https://example.com/rss")
            color: "#f8fafc"
            background: Rectangle {
                color: "#0f172a"
                border.color: parent.activeFocus ? "#3b82f6" : "#334155"
                radius: 4
            }
        }

        Label {
            id: addErrorMessage
            text: ""
            color: "#ef4444"
            font.pixelSize: 13
            visible: text !== ""
        }
    }

    footer: DialogButtonBox {
        background: Rectangle { color: "transparent" }
        alignment: Qt.AlignRight
        
        Button {
            text: qsTr("Cancel")
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            flat: true
            
            contentItem: Text {
                text: parent.text
                color: "#94a3b8"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle { color: "transparent" }
            
            onClicked: addDialog.reject()
        }
        
        Button {
            text: qsTr("Add")
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            
            background: Rectangle {
                color: parent.pressed ? "#2563eb" : "#3b82f6"
                radius: 6
            }
            contentItem: Text {
                text: parent.text
                color: "white"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: {
                var name = String(nameInput.text)
                var feed = String(feedInput.text)

                if (name === "" || feed === "") {
                    addErrorMessage.text = qsTr("Please fill in all fields")
                    return
                }

                // Assuming databaseManager is available in global context or needs to be passed
                // Ideally should be passed, but sticking to existing pattern for now
                if (typeof databaseManager !== 'undefined') {
                    var result = databaseManager.addRssFeed(name, feed)
                     if (result.startsWith("添加成功")) {
                         addDialog.accept()
                         if (rssFeeds) rssFeeds.updateList(parseInt(result.split(":")[1]), name, feed)
                         nameInput.text = ""
                         feedInput.text = ""
                         addErrorMessage.text = ""
                     } else {
                         addErrorMessage.text = qsTr(result)
                     }
                } else {
                    console.error("databaseManager not found")
                }
            }
        }
    }
}
