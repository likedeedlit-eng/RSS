#include "SettingsManager.h"
#include <QNetworkProxy>
#include <QDebug>

SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent), m_settings("QtProject", "RSSNews"){
        this->applyProxy();
    }

void SettingsManager::saveProxy(bool enabled, int type, const QString &host, const QString &port, const QString &username, const QString &password)
{
    m_settings.setValue("proxy/enabled", enabled);
    m_settings.setValue("proxy/type", type);
    m_settings.setValue("proxy/host", host);
    m_settings.setValue("proxy/port", port);
    m_settings.setValue("proxy/username", username);
    m_settings.setValue("proxy/password", password);
    
    applyProxy();
}

void SettingsManager::saveAutoRefresh(int minutes)
{
    m_settings.setValue("autoRefresh", minutes);
}

int SettingsManager::getAutoRefresh()
{
    return m_settings.value("autoRefresh", 0).toInt();
}

QVariantMap SettingsManager::getProxy()
{
    QVariantMap map;
    map["enabled"] = m_settings.value("proxy/enabled", false).toBool();
    map["type"] = m_settings.value("proxy/type", QNetworkProxy::HttpProxy).toInt();
    map["host"] = m_settings.value("proxy/host", "").toString();
    map["port"] = m_settings.value("proxy/port", "8080").toString();
    map["username"] = m_settings.value("proxy/username", "").toString();
    map["password"] = m_settings.value("proxy/password", "").toString();
    return map;
}

void SettingsManager::applyProxy()
{
    bool enabled = m_settings.value("proxy/enabled", false).toBool();
    
    if (!enabled) {
        QNetworkProxy::setApplicationProxy(QNetworkProxy::NoProxy);
        qDebug() << "Proxy disabled";
        return;
    }

    int typeInt = m_settings.value("proxy/type", QNetworkProxy::HttpProxy).toInt();
    QNetworkProxy::ProxyType type = static_cast<QNetworkProxy::ProxyType>(typeInt);
    
    QString host = m_settings.value("proxy/host", "").toString();
    bool ok;
    int port = m_settings.value("proxy/port", 0).toString().toInt(&ok);
    if (!ok) port = 8080;
    
    QString user = m_settings.value("proxy/username", "").toString();
    QString password = m_settings.value("proxy/password", "").toString();

    if (host.isEmpty()) {
        QNetworkProxy::setApplicationProxy(QNetworkProxy::NoProxy);
        return;
    }

    QNetworkProxy proxy;
    proxy.setType(type);
    proxy.setHostName(host);
    proxy.setPort(port);
    if (!user.isEmpty()) {
        proxy.setUser(user);
        proxy.setPassword(password);
    }

    QNetworkProxy::setApplicationProxy(proxy);
    qDebug() << "Proxy applied:" << host << ":" << port << "Type:" << type;
}
