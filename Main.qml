
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "content"

Rectangle {
    id: window
    anchors.fill: parent
    color: "#0f172a"

    property string currentFeed: ""
    property string currentPage: "rss"
    property bool loading: rssReader.loading
    
    // Instantiate the Feeds Model
    RssFeeds {
        id: rssFeeds
        onFinished: {
            if (count > 0 && currentFeed === "") {
                var firstFeed = get(0).feed
                if (firstFeed !== "") {
                    currentFeed = firstFeed
                    rssReader.fetchRss(currentFeed)
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 0
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            if (window.currentFeed !== "" && window.currentPage === "rss") {
                console.log("Auto-refreshing feed:", window.currentFeed)
                rssReader.fetchRss(window.currentFeed)
            }
        }
    }

    Connections {
        target: settingsDialog
        function onReloadRssSource() {
           rssFeeds.reloadFeeds()
        }
        function onAutoRefreshChanged(minutes) {
             console.log("Auto refresh changed to:", minutes, "minutes")
             if (minutes > 0) {
                 refreshTimer.interval = minutes * 60 * 1000
                 refreshTimer.restart()
             } else {
                 refreshTimer.stop()
             }
        }
    }
    

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal
        
        handle: Rectangle {
            implicitWidth: 1
            color: "#334155"
        }

        // Sidebar (Feed Categories)
        Sidebar {
            id: sidebar
            SplitView.preferredWidth: 250
            SplitView.minimumWidth: 200
            SplitView.maximumWidth: 400
            rssFeedsModel: rssFeeds
            currentFeedUrl: window.currentFeed
            currentPage: window.currentPage
            settingsDialog: settingsDialog
            addDialog: addDialog
            
            onFeedSelected: function(url) {
                window.currentFeed = url
                rssReader.fetchRss(url)
                window.currentPage = "rss"
            }
            onFeedDeleted: function(url) {
                if (window.currentFeed === url) {
                    console.log("Deleted current feed, clearing view")
                    window.currentFeed = ""
                    rssReader.clear()
                    detailContainer.showArticle(null)
                }
            }
            onSwitchStar: function(){
                starModel.loadStars()
                window.currentPage= "star"
            }
        }

        // News List
        NewsListContainer {
            id: newsList
            SplitView.preferredWidth: 450
            SplitView.minimumWidth: 350
            currentPage: window.currentPage
            isLoading: window.loading
            onStarSelect: function(index){
                var model = window.currentPage=="rss" ? rssFilterModel : starFilterModel
                var item = model.getItem(index)
                if(databaseManager.addStar(item)){
                    model.switchStar(index)
                }
            }
            onStarCancel: function(index,id){
                if(databaseManager.deleteStar(id)){
                    var model = window.currentPage=="rss" ? rssFilterModel : starFilterModel
                    model.switchStar(index)
                }
            }
            onArticleSelected: function(article) {
                detailContainer.showArticle(article)
            }
        }

        // Article Detail
        DetailContainer {
            id: detailContainer
            SplitView.fillWidth: true
        }
    }

    // Dialog for adding new feeds
    AddDialog {
        id: addDialog
        rssFeeds: rssFeeds
        anchors.centerIn: parent
    }
    
    // Dialog for adding new feeds
    SettingsDialog {
        id: settingsDialog
        onLogoutRequested: {
            window.logout()
        }
    }
    
    signal logout()

    // Expose addDialog to sidebar
    Component.onCompleted: {
        
        var minutes = settingsManager.getAutoRefresh()
        if (minutes > 0) {
             refreshTimer.interval = minutes * 60 * 1000
             refreshTimer.start()
        }
    }
    
    Connections {
        target: rssReader
        function onError(message) {
            console.error("RSS Error:", message)
        }
    }
}
