#include "databaseManager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QSqlDatabase>
#include <QVariantList>
#include <QVariantMap>
#include <QFile>
#include <QXmlStreamReader>
#include <QXmlStreamWriter>
#include <QUrl>
#include <RssItem.h>
DatabaseManager::DatabaseManager(QObject *parent)
    : QObject(parent)
    , m_connected(false)
{
    qDebug() << "DatabaseManager 构造函数被调用";
}

DatabaseManager::~DatabaseManager()
{
    qDebug() << "DatabaseManager 析构函数被调用";
    closeDatabase();
}

bool DatabaseManager::connectToDatabase(const QString &host, const QString &databaseName,
                                    const QString &username, const QString &password,
                                    int port)
{
    qDebug() << "========== 开始连接数据库 ==========";
    qDebug() << "使用 SQLite 数据库:" << databaseName;

    if (m_connected) {
        qDebug() << "数据库已连接";
        return true;
    }

    if (QSqlDatabase::contains("qt_sql_default_connection")) {
        m_database = QSqlDatabase::database("qt_sql_default_connection");
    } else {
        m_database = QSqlDatabase::addDatabase("QSQLITE");
        m_database.setDatabaseName(databaseName);
    }

    if (!m_database.isValid()) {
        qDebug() << "数据库驱动无效";
        m_connected = false;
        return false;
    }

    if (!m_database.open()) {
        qDebug() << "数据库连接失败:" << m_database.lastError().text();
        m_connected = false;
        return false;
    }

    qDebug() << "数据库连接成功";
    m_connected = true;
    
    // 初始化数据库表结构和默认数据
    initDatabase();
    
    return true;
}

void DatabaseManager::initDatabase()
{
    if (!m_connected) return;

    QSqlQuery query;
    
    // 启用外键支持
    query.exec("PRAGMA foreign_keys = ON");

    // 创建用户表
    bool success = query.exec(
        "CREATE TABLE IF NOT EXISTS users ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "username TEXT NOT NULL UNIQUE,"
        "password TEXT NOT NULL,"
        "created_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
        "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP"
        ")"
    );
    if (!success) qDebug() << "创建用户表失败:" << query.lastError().text();

    // 创建 RSS 订阅源表
    success = query.exec(
        "CREATE TABLE IF NOT EXISTS rss_feeds ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "name TEXT NOT NULL,"
        "feed TEXT NOT NULL UNIQUE,"
        "user_id INTEGER,"
        "created_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
        "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
        "FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE"
        ")"
    );
    if (!success) qDebug() << "创建 RSS 表失败:" << query.lastError().text();
    
    success = query.exec(
        "CREATE TABLE IF NOT EXISTS star ("
        "star_id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "user_id INTEGER NOT NULL,"
        "rss_feeds_id INTEGER NOT NULL,"
        "title TEXT NOT NULL,"
        "link TEXT,"
        "guid TEXT,"
        "description TEXT,"
        "author TEXT,"
        "pubDate TEXT,"
        "imageUrl TEXT,"
        "created_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
        "FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE"
        ")"
    );
    if (!success) qDebug() << "创建收藏表失败:" << query.lastError().text();
    
    // 检查是否需要插入默认用户
    query.exec("SELECT COUNT(*) FROM users");
    if (query.next() && query.value(0).toInt() == 0) {
        qDebug() << "插入默认用户...";
        query.prepare("INSERT INTO users (username, password) VALUES (:username, :password)");
        query.bindValue(":username", "admin");
        query.bindValue(":password", hashPassword("123456"));
        if (!query.exec()) qDebug() << "插入默认用户失败:" << query.lastError().text();
        
        // 获取新用户的 ID
        int userId = query.lastInsertId().toInt();
        
        // 插入默认订阅源
        qDebug() << "插入默认订阅源...";
        struct Feed { QString name; QString url;};
        QList<Feed> defaults = {
            {"Top Stories", "news.yahoo.com/rss/topstories"},
            {"World", "news.yahoo.com/rss/world"},
            {"Europe", "news.yahoo.com/rss/europe"},
            {"Asia", "news.yahoo.com/rss/asia"},
            {"U.S. National", "news.yahoo.com/rss/us"},
            {"Politics", "news.yahoo.com/rss/politics"},
            {"Business", "news.yahoo.com/rss/business"},
            {"Technology", "news.yahoo.com/rss/tech"},
            {"Entertainment", "news.yahoo.com/rss/entertainment"},
            {"Health", "news.yahoo.com/rss/health"},
            {"Science", "news.yahoo.com/rss/science"},
            {"Sports", "news.yahoo.com/rss/sports"}
        };
        
        query.prepare("INSERT INTO rss_feeds (name, feed, user_id) VALUES (:name, :feed, :uid)");
        for (const auto &f : defaults) {
            query.bindValue(":name", f.name);
            query.bindValue(":feed", f.url);
            query.bindValue(":uid", userId);
            if (!query.exec()) qDebug() << "插入订阅源失败:" << f.name << query.lastError().text();
        }
    }
}

bool DatabaseManager::verifyUser(const QString &username, const QString &password)
{
    if (!m_connected) {
        qDebug() << "数据库未连接";
        return false;
    }

    QSqlQuery query;
    query.prepare("SELECT id FROM users WHERE username = :username and password = :password");
    query.bindValue(":username", username);
    query.bindValue(":password", hashPassword(password));

    if (!query.exec()) {
        qDebug() << "查询失败:" << query.lastError().text();
        return false;
    }

    if (query.next()) {
        m_userId = query.value(0).toInt();
        return true;
    }

    qDebug() << "用户不存在:" << username;
    return false;
}

QString DatabaseManager::registerUser(const QString &username, const QString &password)
{
    if (!m_connected) {
        qDebug() << "数据库未连接";
        return "数据库未连接";
    }

    QSqlQuery query;
    query.prepare("INSERT INTO users (username, password) VALUES (:username, :password)");
    query.bindValue(":username", username);
    query.bindValue(":password", hashPassword(password));

    qDebug() << "准备注册用户:" << username;

    if (!query.exec()) {
        qDebug() << "注册失败:" << query.lastError().text();
        qDebug() << "错误代码:" << query.lastError().nativeErrorCode();

        // 检查是否是用户名已存在的错误
        QString errorText = query.lastError().text();
        if (errorText.contains("Duplicate entry") || errorText.contains("duplicate")) {
            return "注册失败:用户名已存在";
        }
        return "注册失败:" + query.lastError().text();
    }

    int rowsAffected = query.numRowsAffected();
    qDebug() << "受影响的行数:" << rowsAffected;
    
    if (rowsAffected > 0) {
        qDebug() << "注册成功";
        m_userId = query.lastInsertId().toInt();
        return "注册成功";
    } else {
        qDebug() << "注册失败:没有插入任何行";
        return "注册失败";
    }
}





void DatabaseManager::closeDatabase()
{
    if (m_connected) {
        m_database.close();
        m_connected = false;
        qDebug() << "数据库连接已关闭";
    }
}

QVariantList DatabaseManager::getRssFeeds()
{
    QVariantList feeds;

    if (!m_connected || m_userId == -1) {
        return feeds;
    }

    QSqlQuery query;
    query.prepare("SELECT id, name, feed FROM rss_feeds where user_id = :user_id");
    query.bindValue(":user_id", m_userId);

    if (!query.exec()) {
        qWarning() << "getRssFeeds 查询失败:" << query.lastError().text();
        return feeds;
    }

    while (query.next()) {
        QVariantMap feed;
        feed["name"] = query.value(1).toString();
        feed["feed"] = query.value(2).toString();
        feed["id"] = query.value(0).toInt();
        feeds.append(feed);
    }

    // qDebug() << "加载了" << feeds.size() << "个订阅源";
    return feeds;
}

QString DatabaseManager::addRssFeed(const QString &name, const QString &feed)
{
    if (!m_connected || m_userId == -1) {
        return "用户未登录或数据库未连接";
    }

    QSqlQuery query;
    query.prepare("INSERT INTO rss_feeds (name, feed, user_id) VALUES (:name, :feed, :user_id)");
    query.bindValue(":name", name);
    query.bindValue(":feed", feed);
    query.bindValue(":user_id", m_userId);

    if (!query.exec()) {
        qWarning() << "添加订阅源失败:" << query.lastError().text();
        return "添加失败:" + query.lastError().text();
    }

    QVariant lastId = query.lastInsertId();
    qInfo() << "添加订阅源成功:" << name << "ID:" << lastId.toInt();
    return "添加成功，ID:" + lastId.toString();
}

bool DatabaseManager::deleteRssFeed(const int &feedId)
{
    qDebug() << "========== 删除 RSS 订阅源 ==========";
    qDebug() << "ID:" << feedId;

    if (!m_connected) {
        qDebug() << "数据库未连接";
        return false;
    }

    QSqlQuery query;
    query.prepare("DELETE FROM rss_feeds WHERE id = :id");
    query.bindValue(":id", feedId);

    if (!query.exec()) {
        qDebug() << "删除失败:" << query.lastError().text();
        return false;
    }

    int rowsAffected = query.numRowsAffected();
    qDebug() << "删除成功，影响行数:" << rowsAffected;
    return rowsAffected > 0;
}

bool DatabaseManager::quitUser()
{
    if (!m_connected) {
        qDebug() << "数据库未连接";
        return false;
    }

    QSqlQuery query;
    query.prepare("DELETE FROM users WHERE id = :id");
    query.bindValue(":id", m_userId);

    if (!query.exec()) {
        qDebug() << "删除失败:" << query.lastError().text();
        return false;
    }
    int rowsAffected = query.numRowsAffected();
    qDebug() << "删除成功，影响行数:" << rowsAffected;
    return rowsAffected > 0;
}


bool DatabaseManager::changePassword(const QString& oldPassword,const QString &newPassword)
{
    if (!m_connected) {
        qDebug() << "数据库未连接";
        return false;
    }

    QSqlQuery query;
    qDebug() << "========== 修改密码 ==========";
    qDebug() << "旧密码:" << oldPassword;
    query.prepare("UPDATE users SET password = :password WHERE id = :id and password = :oldPassword");
    query.bindValue(":password", hashPassword(newPassword));
    query.bindValue(":id", m_userId);
    query.bindValue(":oldPassword", hashPassword(oldPassword));

    if (!query.exec()) {
        qDebug() << "更新失败:" << query.lastError().text();
        return false;
    }
    int affectedRows = query.numRowsAffected();
    qDebug() << "受影响的行数:" << affectedRows;
    return affectedRows > 0;
}



bool DatabaseManager::addStar(const RssItem &rssItem){
    if (!m_connected) {
        qDebug() << "数据库未连接";
        return false;
    }
    if(m_userId == -1)
    {
        qDebug() << "用户未登录";
        return false;
    }

    QSqlQuery query;
    query.prepare("INSERT INTO star (user_id, rss_feeds_id, title, link, guid, description, author, pubDate, imageUrl) VALUES (:user_id, :rss_feeds_id, :title, :link, :guid, :description, :author, :pubDate, :imageUrl)");
    query.bindValue(":user_id", m_userId);
    query.bindValue(":rss_feeds_id", rssItem.articleId);
    query.bindValue(":title", rssItem.title);
    query.bindValue(":link", rssItem.link);
    query.bindValue(":guid", rssItem.guid);
    query.bindValue(":description", rssItem.description);
    query.bindValue(":author", rssItem.author);
    query.bindValue(":pubDate", rssItem.pubDate);
    query.bindValue(":imageUrl", rssItem.imageUrl);

    if (!query.exec()) {
        qDebug() << "更新失败:" << query.lastError().text();
        return false;
    }
    int affectedRows = query.numRowsAffected();
    qDebug() << "受影响的行数:" << affectedRows;
    return affectedRows > 0;
}


bool DatabaseManager::deleteStar(const int &articleId){
    if (!m_connected) {
        qDebug() << "数据库未连接";
        return false;
    }
    if(m_userId == -1)
    {
        qDebug() << "用户未登录";
        return false;
    }

    QSqlQuery query;
    query.prepare("DELETE FROM star WHERE user_id = :user_id AND rss_feeds_id = :rss_feeds_id");
    query.bindValue(":user_id", m_userId);
    query.bindValue(":rss_feeds_id", articleId);

    if (!query.exec()) {
        qDebug() << "更新失败:" << query.lastError().text();
        return false;
    }
    int affectedRows = query.numRowsAffected();
    qDebug() << "受影响的行数:" << affectedRows;
    return affectedRows > 0;
}

QString DatabaseManager::exportOpml(const QString &filePath)
{
    if (!m_connected) {
        return "数据库未连接";
    }
    if (m_userId == -1) {
        return "用户未登录";
    }

    QString path = filePath;
    if (path.startsWith("file:")) {
        path = QUrl(path).toLocalFile();
    }
    if (path.isEmpty()) {
        return "文件路径无效";
    }

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return "文件打开失败";
    }

    QXmlStreamWriter xml(&file);
    xml.setAutoFormatting(true);
    xml.writeStartDocument("1.0", "UTF-8");
    xml.writeStartElement("opml");
    xml.writeAttribute("version", "2.0");
    xml.writeStartElement("head");
    xml.writeTextElement("title", "RSS Feeds");
    xml.writeEndElement();
    xml.writeStartElement("body");

    QSqlQuery query;
    query.prepare("SELECT name, feed FROM rss_feeds");
    if (!query.exec()) {
        file.close();
        return "查询失败:" + query.lastError().text();
    }

    int count = 0;
    while (query.next()) {
        QString name = query.value(0).toString();
        QString feed = query.value(1).toString();
        if (name.isEmpty() || feed.isEmpty()) {
            continue;
        }
        xml.writeStartElement("outline");
        xml.writeAttribute("text", name);
        xml.writeAttribute("title", name);
        xml.writeAttribute("type", "rss");
        xml.writeAttribute("xmlUrl", feed);
        xml.writeEndElement();
        count++;
    }

    xml.writeEndElement();
    xml.writeEndElement();
    xml.writeEndDocument();
    file.close();

    return "导出成功:" + QString::number(count);
}

QString DatabaseManager::importOpml(const QString &filePath)
{
    if (!m_connected) {
        return "数据库未连接";
    }
    if (m_userId == -1) {
        return "用户未登录";
    }

    QString path = filePath;
    if (path.startsWith("file:")) {
        path = QUrl(path).toLocalFile();
    }
    if (path.isEmpty()) {
        return "文件路径无效";
    }

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        return "文件打开失败";
    }

    QXmlStreamReader xml(&file);
    int inserted = 0;
    int skipped = 0;

    while (!xml.atEnd()) {
        xml.readNext();
        if (xml.isStartElement() && xml.name() == QLatin1String("outline")) {
            QString xmlUrl = xml.attributes().value("xmlUrl").toString();
            QString title = xml.attributes().value("title").toString();
            if (title.isEmpty()) {
                title = xml.attributes().value("text").toString();
            }
            if (xmlUrl.isEmpty()) {
                continue;
            }
            if (title.isEmpty()) {
                QUrl url(xmlUrl);
                title = url.host().isEmpty() ? "RSS Feed" : url.host();
            }

            QSqlQuery query;
            query.prepare("INSERT OR IGNORE INTO rss_feeds (name, feed, user_id) VALUES (:name, :feed, :user_id)");
            query.bindValue(":name", title);
            query.bindValue(":feed", xmlUrl);
            query.bindValue(":user_id", m_userId);

            if (!query.exec()) {
                skipped++;
                continue;
            }
            if (query.numRowsAffected() > 0) {
                inserted++;
            } else {
                skipped++;
            }
        }
    }

    if (xml.hasError()) {
        file.close();
        return "解析失败:" + xml.errorString();
    }

    file.close();
    return "导入成功:" + QString::number(inserted) + " 跳过:" + QString::number(skipped);
}



QVariantList DatabaseManager::getStar()
{
    qDebug() << "========== 获取收藏 ==========";
    QVariantList star;

    if (!m_connected) {
        qDebug() << "数据库未连接";
        return star;
    }
    if(m_userId == -1)
    {
        qDebug() << "用户未登录";
        return star;
    }

    QSqlQuery query;
    query.prepare("SELECT star_id,rss_feeds_id, title, link, guid, description, author, pubDate, imageUrl FROM star WHERE user_id = :user_id");
    query.bindValue(":user_id", m_userId);

    if (!query.exec()) {
        qDebug() << "查询失败:" << query.lastError().text();
        return star;
    }

    while (query.next()) {
        QVariantMap feed;
        feed["star_id"] = query.value(0).toInt();
        feed["articleId"] = query.value(1).toInt();
        feed["title"] = query.value(2).toString();
        feed["link"] = query.value(3).toString();
        feed["guid"] = query.value(4).toString();
        feed["description"] = query.value(5).toString();
        feed["author"] = query.value(6).toString();
        feed["pubDate"] = query.value(7).toString();
        feed["imageUrl"] = query.value(8).toString();
        star.append(feed);
        qDebug() << "加载收藏:";
    }

    qDebug() << "共加载" << star.size() << "个收藏";
    return star;
}

QList<RssItem> DatabaseManager::getStarItems()
{
    qDebug() << "========== 获取收藏(RssItem List) ==========";
    QList<RssItem> star;

    if (!m_connected) {
        qDebug() << "数据库未连接";
        return star;
    }
    if(m_userId == -1)
    {
        qDebug() << "用户未登录";
        return star;
    }

    QSqlQuery query;
    query.prepare("SELECT star_id,rss_feeds_id, title, link, guid, description, author, pubDate, imageUrl FROM star WHERE user_id = :user_id");
    query.bindValue(":user_id", m_userId);

    if (!query.exec()) {
        qDebug() << "查询失败:" << query.lastError().text();
        return star;
    }

    while (query.next()) {
        RssItem feed;
        // feed.star_id = query.value(0).toInt(); // RssItem doesn't have star_id, but it has rss_feeds_id
        feed.articleId = query.value(1).toInt();
        feed.title = query.value(2).toString();
        feed.link = query.value(3).toString();
        feed.guid = query.value(4).toString();
        feed.description = query.value(5).toString();
        feed.author = query.value(6).toString();
        feed.pubDate = query.value(7).toString();
        feed.imageUrl = query.value(8).toString();
        feed.isStarred = true;
        star.append(feed);
    }

    qDebug() << "共加载" << star.size() << "个收藏项";
    return star;
}


bool DatabaseManager::checkIfStarred(const int &articleId)
{
    if (!m_connected) {
        qDebug() << "数据库未连接";
        return false;
    }
    if(m_userId == -1)
    {
        qDebug() << "用户未登录";
        return false;
    }
    QSqlQuery query;
    query.prepare("SELECT COUNT(*) FROM star WHERE user_id = :user_id AND rss_feeds_id = :rss_feeds_id");
    query.bindValue(":user_id", m_userId);
    query.bindValue(":rss_feeds_id", articleId);
    if (!query.exec()) {
        qDebug() << "查询失败:" << query.lastError().text();
        return false;
    }

    if (query.next()) {
        int count = query.value(0).toInt();
        return count > 0;
    }

    return false;
}

QString DatabaseManager::hashPassword(const QString &password)
{
    return QString(QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256).toHex());
}
