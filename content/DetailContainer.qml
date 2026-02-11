
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#0f172a"
    
    property var currentArticle: null
    property int baseFontSize: 16
    
    function showArticle(article) {
        currentArticle = article
        flickable.contentY = 0 // Reset scroll
    }

    ScrollView {
        id: flickable
        anchors.fill: parent
        contentWidth: parent.width
        clip: true
        
        ColumnLayout {
            width: root.width
            spacing: 20
            
            // Toolbar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "#1e293b" // Toolbar background
                visible: root.currentArticle !== null
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 40
                    anchors.rightMargin: 40
                    spacing: 16
                    
                    // Font Size Controls
                    RowLayout {
                        spacing: 0
                        Rectangle {
                            width: 32; height: 32; radius: 4; color: "#334155"
                            Text { text: "A-"; anchors.centerIn: parent; color: "white"; font.bold: true }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(baseFontSize > 12) baseFontSize -= 2 }
                        }
                        Rectangle {
                            width: 40; height: 32; color: "#1e293b"
                            Text { text: baseFontSize + "px"; anchors.centerIn: parent; color: "#94a3b8"; font.pixelSize: 12 }
                        }
                        Rectangle {
                            width: 32; height: 32; radius: 4; color: "#334155"
                            Text { text: "A+"; anchors.centerIn: parent; color: "white"; font.bold: true }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(baseFontSize < 32) baseFontSize += 2 }
                        }
                    }
                    
                    Item { Layout.fillWidth: true } // Spacer
                    
                    // Share Button
                    Button {
                        text: "Share Link"
                        background: Rectangle { color: "#3b82f6"; radius: 4 }
                        contentItem: RowLayout {
                            Text { text: "🔗"; color: "white" }
                            Text { text: "Copy Link"; color: "white"; font.bold: true }
                        }
                        onClicked: {
                            if (root.currentArticle && root.currentArticle.link) {
                                // Create a temporary TextEdit to copy to clipboard
                                var clipboardHelper = Qt.createQmlObject('import QtQuick; TextEdit { visible: false }', root)
                                clipboardHelper.text = root.currentArticle.link
                                clipboardHelper.selectAll()
                                clipboardHelper.copy()
                                clipboardHelper.destroy()
                                
                                // Show toast feedback (simulated)
                                shareFeedback.visible = true
                                shareFeedbackTimer.restart()
                            }
                        }
                    }
                    
                    Button {
                         text: "Open Browser"
                         background: Rectangle { color: "transparent"; border.color: "#334155"; radius: 4 }
                         contentItem: Text { text: "🌐 Open"; color: "#94a3b8"; horizontalAlignment: Text.AlignHCenter }
                         onClicked: {
                             if (root.currentArticle && root.currentArticle.link) {
                                 Qt.openUrlExternally(root.currentArticle.link)
                             }
                         }
                    }
                }
            }
            
            // Share Feedback Toast
            Rectangle {
                id: shareFeedback
                Layout.alignment: Qt.AlignHCenter
                width: 200
                height: 40
                color: "#10b981" // Green
                radius: 20
                visible: false
                
                RowLayout {
                    anchors.centerIn: parent
                    Text { text: "✓ Link Copied!"; color: "white"; font.bold: true }
                }
                
                Timer {
                    id: shareFeedbackTimer
                    interval: 2000
                    onTriggered: shareFeedback.visible = false
                }
            }

            // Content
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 40
                Layout.rightMargin: 40
                spacing: 15
                
                visible: root.currentArticle !== null
                
                Text {
                    text: root.currentArticle ? root.currentArticle.title.replace(/&#39;/g, "'") : ""
                    color: "#f8fafc"
                    font.bold: true
                    font.pixelSize: 28
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                
                RowLayout {
                    spacing: 10
                    Text {
                        text: root.currentArticle ? root.currentArticle.pubDate : ""
                        color: "#94a3b8"
                        font.pixelSize: 13
                    }
                    Text {
                        text: (root.currentArticle && root.currentArticle.author) ? "|  " + root.currentArticle.author : ""
                        color: "#94a3b8"
                        font.pixelSize: 13
                        visible: text !== ""
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#334155"
                }
                
                Text {
                    text: root.currentArticle ? root.currentArticle.description : ""
                    color: "#cbd5e1"
                    font.pixelSize: baseFontSize
                    lineHeight: 1.6
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    textFormat: Text.RichText // Allow HTML in description
                    
                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                }
            }
            
            // Empty State
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 400
                visible: root.currentArticle === null
                
                Column {
                    anchors.centerIn: parent
                    spacing: 20
                    
                    Text {
                        text: "Select an article to read"
                        color: "#475569"
                        font.pixelSize: 18
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
            
             // Bottom Padding
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
            }
        }
    }
}
