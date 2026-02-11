#pragma once

#include <QString>
#include <QStringList>

struct RssItem {
    int articleId;
    QString title;
    QString link;
    QString guid;
    QString description;
    QString author;
    QString pubDate;
    QString imageUrl;
    bool isStarred;
};

