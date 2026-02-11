
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#0f172a"
    
    property var model: null
    property string currentPage: ""
    property bool isLoading

    signal articleSelected(var article)
    signal starSelect(var index)
    signal starCancel(var index,var id)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "transparent"
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 10

                Text {
                    text: "Articles"
                    color: "#f8fafc"
                    font.bold: true
                    font.pixelSize: 16
                }

                // 搜索框
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    color: "#1e293b"
                    radius: 16
                    border.color: searchInput.activeFocus ? "#38bdf8" : "#334155"

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#f1f5f9"
                        font.pixelSize: 13
                        selectByMouse: true
                        selectionColor: "#38bdf8"
                        
                        Text {
                            text: "Search articles..."
                            color: "#64748b"
                            visible: !searchInput.text && !searchInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                        }

                        onTextChanged: {
                            if (typeof rssFilterModel !== "undefined") {
                                rssFilterModel.setSearchString(text)
                            }
                            if (typeof starFilterModel !== "undefined") {
                                starFilterModel.setSearchString(text)
                            }
                        }
                    }
                }
                
                BusyIndicator {
                    visible: root.isLoading
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 30
                }
            }
        }
        
        
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#334155" }
        
        // List
        ListView {
            id: articleList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            // 使用 rssFilterModel 替代原始 model
            model: currentPage=="rss" ? rssFilterModel : starFilterModel
            spacing: 0 
            
            delegate: ItemDelegate {
                width: ListView.view.width
                height: contentItem.implicitHeight + 30
                id: item
                
                background: Rectangle {
                    color: parent.hovered ? "#1e293b" : "transparent"
                }
                
                contentItem: ColumnLayout {
                       spacing: 6

                       width: parent.width
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: model.title ? model.title.replace(/&#39;/g, "'") : ""
                                color: "#f8fafc"
                                font.bold: true
                                font.pixelSize: 15
                                Layout.fillWidth: true  
                                elide: Text.ElideRight
                            }

                            Button {
                                id: starButton
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.rightMargin: 8 
                                Layout.alignment: Qt.AlignRight
                                visible: item.hovered || model.isStarred
                                
                                contentItem: Text {
                                    text: model.isStarred ? "★" : "☆"
                                    color: model.isStarred ? "#fbbf24" : (starButton.hovered ? "#f1f5f9" : "#94a3b8")
                                    font.pixelSize: 20
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    scale: starButton.pressed ? 0.9 : 1.0
                                }

                                background: Rectangle {
                                    color: starButton.hovered ? "#334155" : "transparent"
                                    radius: 16
                                    opacity: 0.5
                                }
                                
                                onClicked: {
                                    if(model.isStarred==true)
                                      starCancel(index,model.articleId)
                                    else 
                                      starSelect(index)
                                }
                            }
                        }
                    Text {
                        text: model.description ? model.description.replace(/<[^>]+>/g, "") : ""
                        color: "#94a3b8"
                        font.pixelSize: 13
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    
                    RowLayout {
                        Text { 
                            text: model.pubDate 
                            color: "#64748b"
                            font.pixelSize: 11
                        }
                    }
                }
                
                padding: 15
                
                onClicked: {
                    // Create a JS object to pass
                    var article = {
                        title: model.title,
                        description: model.description,
                        link: model.link,
                        pubDate: model.pubDate,
                        author: model.author
                    }
                    root.articleSelected(article)
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#1e293b"
                    anchors.bottom: parent.bottom
                }
            }
            
            ScrollBar.vertical: ScrollBar { }
        }
    }
}
