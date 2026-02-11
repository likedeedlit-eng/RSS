#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QString>
#include <QSqlDatabase>
#include <QCryptographicHash>
#include "rssitem.h"

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();

    // Connection
    Q_INVOKABLE bool connectToDatabase(const QString &host = "", const QString &databaseName = "rssnews.db",
                       const QString &username = "", const QString &password = "",
                       int port = 0);
    Q_INVOKABLE void closeDatabase();

    // User Management
    Q_INVOKABLE bool verifyUser(const QString &username, const QString &password);
    Q_INVOKABLE QString registerUser(const QString &username, const QString &password);
    Q_INVOKABLE bool quitUser(); // Deletes current user
    Q_INVOKABLE bool changePassword(const QString& oldPassword,const QString &newPassword);

    // RSS Feed Management
    Q_INVOKABLE QVariantList getRssFeeds();
    Q_INVOKABLE QString addRssFeed(const QString &name, const QString &feed);
    Q_INVOKABLE bool deleteRssFeed(const int &feedId);
    
    // Star/Favorite Management
    Q_INVOKABLE bool checkIfStarred(const int &articleId);
    Q_INVOKABLE bool addStar(const RssItem &rssItem);
    Q_INVOKABLE bool deleteStar(const int &articleId);
    Q_INVOKABLE QVariantList getStar(); // Returns list of variant maps
    QList<RssItem> getStarItems();      // Returns list of RssItem objects

    // Import/Export
    Q_INVOKABLE QString exportOpml(const QString &filePath);
    Q_INVOKABLE QString importOpml(const QString &filePath);

private:
    void initDatabase();
    QString hashPassword(const QString &password);
    QSqlDatabase m_database;
    bool m_connected;
    int m_userId = -1;
};

#endif // DATABASEMANAGER_H
