#ifndef NETWORKFACTORY_H
#define NETWORKFACTORY_H

#include <QQmlNetworkAccessManagerFactory>
#include <QNetworkAccessManager>
#include <QNetworkDiskCache>
#include <QStandardPaths>
#include <QDebug>

class NetworkFactory : public QQmlNetworkAccessManagerFactory
{
public:
    QNetworkAccessManager *create(QObject *parent) override
    {
        QNetworkAccessManager *manager = new QNetworkAccessManager(parent);
        QNetworkDiskCache *cache = new QNetworkDiskCache(manager);
        
        QString cachePath = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
        cache->setCacheDirectory(cachePath);
        cache->setMaximumCacheSize(100 * 1024 * 1024); // 100 MB cache
        
        manager->setCache(cache);
        
        qDebug() << "全局网络缓存已初始化，路径:" << cachePath;
        return manager;
    }
};

#endif // NETWORKFACTORY_H
