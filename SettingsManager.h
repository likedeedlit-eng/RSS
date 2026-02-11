#ifndef SETTINGSMANAGER_H
#define SETTINGSMANAGER_H

#include <QObject>
#include <QSettings>
#include <QNetworkProxy>
#include <QVariantMap>

class SettingsManager : public QObject
{
    Q_OBJECT
public:
    explicit SettingsManager(QObject *parent = nullptr);

    Q_INVOKABLE void saveProxy(bool enabled, int type, const QString &host, const QString &port, const QString &username, const QString &password);
    Q_INVOKABLE QVariantMap getProxy();
    
    Q_INVOKABLE void saveAutoRefresh(int minutes);
    Q_INVOKABLE int getAutoRefresh();

    void applyProxy();

private:
    QSettings m_settings;
};

#endif // SETTINGSMANAGER_H
