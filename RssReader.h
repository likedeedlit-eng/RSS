#ifndef RSSREADER_H
#define RSSREADER_H

#include <QObject>
#include <QXmlStreamReader>
#include <QNetworkReply>
#include <QNetworkAccessManager>
#include <QList>
#include <QFutureWatcher>
#include <QtConcurrent>
#include "RssItem.h"
#include "databaseManager.h"

class RssReader : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ isLoading NOTIFY loadingChanged)

public:
    explicit RssReader(QObject *parent = nullptr, DatabaseManager *databaseManager = nullptr);
    ~RssReader();

    Q_INVOKABLE void fetchRss(const QString &url);
    Q_INVOKABLE void clear();
    Q_INVOKABLE QList<RssItem> getItems() const;
    bool isLoading() const;
    
signals:
    void itemsReady(const QList<RssItem> &items);
    void error(const QString &message);
    void loadingChanged();

private slots:
    void onReplyFinished(QNetworkReply *reply);
    void onParsingFinished();

private:
    QNetworkAccessManager *m_networkManager;
    QList<RssItem> m_items;
    bool m_loading;
    QFutureWatcher<QList<RssItem>> m_watcher;
    
    // Static worker function for parsing (thread-safe)
    static QList<RssItem> parseRssWorker(const QByteArray &data);
    
    // Helper methods for parsing
    static void parseChannel(QXmlStreamReader &xml, QList<RssItem> &items);
    static void parseItem(QXmlStreamReader &xml, QList<RssItem> &items);
    static QString readElementText(QXmlStreamReader &xml);
    
    int setItemId(const RssItem &item);
    DatabaseManager *databaseManager;
};

#endif
