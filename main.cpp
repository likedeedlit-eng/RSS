// 版权声明：2020年 Qt 公司
// 许可证：Qt 商业许可证或 BSD-3-Clause

#include <QDebug>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <iostream>
#include "databaseManager.h"
#include "RssReader.h"
#include "RssModel.h"
#include "RssFilterModel.h"
#include "NetworkFactory.h"
#include "SettingsManager.h"


// 主函数，程序入口点
// argc: 命令行参数个数
// argv: 命令行参数数组
int main(int argc, char *argv[])
{
    // 设置应用程序的组织名称为 "QtProject"
    QCoreApplication::setOrganizationName("QtProject");
    // 设置应用程序名称为 "RSS News"
    // 这个名称用于标识应用程序
    QCoreApplication::setApplicationName("RSS News");

    // 创建 QGuiApplication 实例
    // 这是 Qt GUI 应用程序的核心类，管理应用程序的生命周期
    // argc 和 argv 传递给应用程序，用于处理命令行参数
    QGuiApplication app(argc, argv);


    // 创建 QML 应用引擎实例
    // QQmlApplicationEngine 用于加载 QML 文件，特别是使用 ApplicationWindow 的 QML 文件
    QQmlApplicationEngine engine;
    
    // 设置网络工厂，启用全局图片缓存
    engine.setNetworkAccessManagerFactory(new NetworkFactory());

    // 创建数据库管理器实例
    DatabaseManager *dbManager = new DatabaseManager(&app);
    qDebug()<<"数据库管理器已创建";

    // 将数据库管理器暴露给 QML，使其可以在 QML 中访问
    engine.rootContext()->setContextProperty("databaseManager", dbManager);
    qDebug()<<"数据库管理器已暴露给 QML";

    // 尝试连接数据库（使用默认配置 SQLite）
    dbManager->connectToDatabase();

    // 创建 RSS 读取器实例
    RssReader *rssReader = new RssReader(&app, dbManager);
    qDebug()<<"RSS 读取器已创建";

    // 创建 RSS 模型实例
    RSSModel *rssModel = new RSSModel(&app);
    qDebug()<<"RSS 模型已创建";

    // 创建收藏模型实例
    RSSModel *starModel = new RSSModel(&app, dbManager);
    qDebug()<<"收藏模型已创建";

    // 创建 Filter 模型
    RssFilterModel *filterModel = new RssFilterModel(&app);
    filterModel->setSourceModel(rssModel);
    qDebug()<<"Filter 模型已创建";

    // 创建收藏 Filter 模型
    RssFilterModel *starFilterModel = new RssFilterModel(&app);
    starFilterModel->setSourceModel(starModel);
    qDebug()<<"收藏 Filter 模型已创建";

    // 创建 SettingsManager 实例
    SettingsManager *settingsManager = new SettingsManager(&app);
    engine.rootContext()->setContextProperty("settingsManager", settingsManager);

    // 将 RSS 读取器和模型暴露给 QML
    engine.rootContext()->setContextProperty("rssReader", rssReader);
    engine.rootContext()->setContextProperty("rssModel", rssModel);
    engine.rootContext()->setContextProperty("starModel", starModel);
    engine.rootContext()->setContextProperty("rssFilterModel", filterModel);
    engine.rootContext()->setContextProperty("starFilterModel", starFilterModel);
    qDebug()<<"RSS 读取器和模型已暴露给 QML";

    // 连接 RSS 读取器的信号到模型的槽函数
    QObject::connect(rssReader, &RssReader::itemsReady, rssModel, &RSSModel::setItems);
    QObject::connect(rssReader, &RssReader::error, [](const QString &message) {
        qDebug() << "RSS 错误:" << message;
    });


    engine.loadFromModule(u"RssNewsModule", u"MainEntry");

    // 检查 QML 文件是否加载成功
    // 如果根对象为空，说明加载失败
    if (engine.rootObjects().isEmpty())
    {
        qDebug()<<"错误：QML 加载失败，根对象为空！";
        // 返回 -1 表示程序异常退出
        return -1;
    }

    qDebug()<<"QML 加载成功，根对象数量:"<<engine.rootObjects().count();

    // 进入应用程序的主事件循环
    // app.exec() 会阻塞，直到应用程序退出
    // 返回值是应用程序的退出码
    return app.exec();
}
