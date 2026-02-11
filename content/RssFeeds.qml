// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick

ListModel {
    id: rssFeeds
    signal finished()
    Component.onCompleted: {
        console.log("RssFeeds 组件加载完成，开始从数据库加载订阅源")
        if (typeof databaseManager !== 'undefined') {
            var feeds = databaseManager.getRssFeeds()
            console.log("从数据库获取到", feeds.length, "个订阅源")

            for (var i = 0; i < feeds.length; i++) {
                var feed = feeds[i]
                if (!feed.feed) continue;
                console.log("添加订阅源:", feed.name, feed.feed)
                append({
                    id: feed.id,
                    name: feed.name,
                    feed: feed.feed,
                })
            }
        } else {
            console.log("警告：databaseManager 未定义，使用默认数据")
        }
        rssFeeds.finished()
    }

    function updateList(id,name,feed){
        console.log("更新订阅源")
        insert(0,{id: id,name: name,feed: feed})
    }

    function reloadFeeds(){
        clear()
        if (typeof databaseManager !== 'undefined') {
            var feeds = databaseManager.getRssFeeds()
            for (var i = 0; i < feeds.length; i++) {
                var feed = feeds[i]
                append({
                    id: feed.id,
                    name: feed.name,
                    feed: feed.feed,
                })
            }
        }
    }

}
