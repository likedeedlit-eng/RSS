#include "RssReader.h"
#include <QDebug>
#include <QUrl>
#include <QNetworkDiskCache>
#include <QStandardPaths>

RssReader::RssReader(QObject *parent, DatabaseManager *databaseManager)
    : QObject(parent)
    , databaseManager(databaseManager)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_loading(false)
{
    // Setup disk cache for RSS feeds
    QNetworkDiskCache *diskCache = new QNetworkDiskCache(this);
    diskCache->setCacheDirectory(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/rss_cache");
    diskCache->setMaximumCacheSize(50 * 1024 * 1024); // 50 MB for XMLs
    m_networkManager->setCache(diskCache);
    
    connect(m_networkManager, &QNetworkAccessManager::finished,
            this, &RssReader::onReplyFinished);
    
    connect(&m_watcher, &QFutureWatcher<QList<RssItem>>::finished,
            this, &RssReader::onParsingFinished);
}

RssReader::~RssReader()
{
}

bool RssReader::isLoading() const
{
    return m_loading;
}

void RssReader::fetchRss(const QString &url)
{
    qInfo() << "开始获取 RSS:" << url;
    
    if (m_loading) {
        qWarning() << "正在加载中，忽略请求";
        return;
    }

    m_loading = true;
    emit loadingChanged();
    
    m_items.clear();
    
    QUrl rssUrl(url);
    if (!rssUrl.isValid() || rssUrl.scheme().isEmpty()) {
        emit error("无效的 URL: " + url);
        m_loading = false;
        emit loadingChanged();
        return;
    }
    
    QNetworkRequest request(rssUrl);
    // 设置 User-Agent 避免被部分服务器拦截
    request.setHeader(QNetworkRequest::UserAgentHeader, "RSSNews/1.0");
    m_networkManager->get(request);
}

void RssReader::clear()
{
    m_items.clear();
    emit itemsReady(m_items);
}

QList<RssItem> RssReader::getItems() const
{
    return m_items;
}

void RssReader::onReplyFinished(QNetworkReply *reply)
{
    if (reply->error() != QNetworkReply::NoError) {
        qDebug() << "网络错误:" << reply->errorString();
        emit error(reply->errorString());
        reply->deleteLater();
        m_loading = false;
        emit loadingChanged();
        return;
    }
    
    QByteArray data = reply->readAll();
    qDebug() << "收到数据，大小:" << data.size() << "字节，开始后台解析...";
    
    // Start parsing in a background thread
    QFuture<QList<RssItem>> future = QtConcurrent::run(&RssReader::parseRssWorker, data);
    m_watcher.setFuture(future);
    
    reply->deleteLater();
}

void RssReader::onParsingFinished()
{
    qDebug() << "后台解析完成，处理数据库关联...";
    m_items = m_watcher.result();
    
    // Process items (set IDs and check stars) on the main thread
    // This is safe because databaseManager is on the main thread
    for (auto &item : m_items) {
        item.articleId = setItemId(item);
    }
    
    if (databaseManager) {
        for (auto &item : m_items) {
            item.isStarred = databaseManager->checkIfStarred(item.articleId);
        }
    }
    
    emit itemsReady(m_items);
    m_loading = false;
    emit loadingChanged();
    qDebug() << "数据处理完毕，已通知 UI";
}

int RssReader::setItemId(const RssItem &item)
{
    QString str = item.title+item.link+item.guid+item.description+item.author+item.pubDate+item.imageUrl;
    uint hashValue = qHash(str); // 返回 uint
    return hashValue;
}

// Static Worker Function
QList<RssItem> RssReader::parseRssWorker(const QByteArray &data)
{
    QList<RssItem> items;
    QXmlStreamReader xml(data);
    
    while (!xml.atEnd() && !xml.hasError()) {
        QXmlStreamReader::TokenType token = xml.readNext();
        
        if (token == QXmlStreamReader::StartElement) {
            if (xml.name() == QLatin1String("rss")) {
                parseChannel(xml, items);
            }
        }
    }
    
    if (xml.hasError()) {
        qDebug() << "XML 解析错误:" << xml.errorString();
    }
    
    return items;
}

void RssReader::parseChannel(QXmlStreamReader &xml, QList<RssItem> &items)
{
    while (!xml.atEnd() && !xml.hasError()) {
        QXmlStreamReader::TokenType token = xml.readNext();
        
        if (token == QXmlStreamReader::StartElement) {
            if (xml.name() == QLatin1String("item")) {
                parseItem(xml, items);
            }
        } else if (token == QXmlStreamReader::EndElement) {
            if (xml.name() == QLatin1String("channel")) {
                break;
            }
        }
    }
}

void RssReader::parseItem(QXmlStreamReader &xml, QList<RssItem> &items)
{
    RssItem item;
    
    while (!xml.atEnd() && !xml.hasError()) {
        QXmlStreamReader::TokenType token = xml.readNext();
        
        if (token == QXmlStreamReader::StartElement) {
            QString elementName = xml.name().toString();
            
            if (elementName == QLatin1String("title")) {
                item.title = readElementText(xml);
            } else if (elementName == QLatin1String("link")) {
                QString linkText = readElementText(xml);
                if (!linkText.isEmpty()) {
                    item.link = linkText;
                }
            } else if (elementName == QLatin1String("guid")) {
                item.guid = readElementText(xml);
            } else if (elementName == QLatin1String("description")) {
                item.description = readElementText(xml);
            } else if (elementName == QLatin1String("author")) {
                item.author = readElementText(xml);
            } else if (elementName == QLatin1String("pubDate")) {
                item.pubDate = readElementText(xml);
            } else if (elementName == QLatin1String("media:content") || 
                       elementName == QLatin1String("content")) {
                item.imageUrl = xml.attributes().value("url").toString();
            }
        } else if (token == QXmlStreamReader::EndElement) {
            if (xml.name() == QLatin1String("item")) {
                items.append(item);
                break;
            }
        }
    }
}

QString RssReader::readElementText(QXmlStreamReader &xml)
{
    QString text;
    while (!xml.atEnd() && !xml.hasError()) {
        QXmlStreamReader::TokenType token = xml.readNext();
        
        if (token == QXmlStreamReader::Characters) {
            text += xml.text();
        } else if (token == QXmlStreamReader::EndElement) {
            break;
        }
    }
    return text.trimmed();
}
