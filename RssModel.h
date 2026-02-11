// rssmodel.h
#pragma once
#include <QAbstractListModel>
#include "Rssitem.h"
#include "databaseManager.h"



class RSSModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Roles {
        TitleRole = Qt::UserRole + 1,
        LinkRole,
        GuidRole,
        DescriptionRole,
        AuthorRole,
        PubDateRole,
        ImageUrlRole,
        IsStarredRole,
        ArticleIdRole
    };

    RSSModel(QObject* parent = nullptr, DatabaseManager *dbManager = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE RssItem getItem(int i) const;
    void setItems(const QList<RssItem>& items);
    Q_INVOKABLE void switchStar(int i);
    Q_INVOKABLE void loadStars();

private:
    QList<RssItem> m_items;
    DatabaseManager *m_dbManager;
};