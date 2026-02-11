#include "RssModel.h"
#include "databaseManager.h"

RSSModel::RSSModel(QObject* parent, DatabaseManager *dbManager)
    : QAbstractListModel(parent), m_dbManager(dbManager)
{
}

int RSSModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_items.size();
}

QVariant RSSModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_items.size())
        return QVariant();

    const RssItem &item = m_items.at(index.row());

    switch (role) {
    case TitleRole:
        return item.title;
    case LinkRole:
        return item.link;
    case GuidRole:
        return item.guid;
    case DescriptionRole:
        return item.description;
    case AuthorRole:
        return item.author;
    case PubDateRole:
        return item.pubDate;
    case ImageUrlRole:
        return item.imageUrl;
    case IsStarredRole:
        return item.isStarred;
    case ArticleIdRole:
        return item.articleId;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> RSSModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[TitleRole] = "title";
    roles[LinkRole] = "link";
    roles[GuidRole] = "guid";
    roles[DescriptionRole] = "description";
    roles[AuthorRole] = "author";
    roles[PubDateRole] = "pubDate";
    roles[ImageUrlRole] = "imageUrl";
    roles[IsStarredRole] = "isStarred";
    roles[ArticleIdRole] = "articleId";
    return roles;
}

void RSSModel::setItems(const QList<RssItem> &items)
{
    beginResetModel();
    m_items = items;
    endResetModel();
}


void RSSModel::switchStar(int i)
{
    if (i >= 0 && i < m_items.size())
    {
        RssItem item = m_items.at(i);
        item.isStarred = !item.isStarred;
        m_items[i] = item;
        emit dataChanged(index(i), index(i), {IsStarredRole});
    }
}

RssItem RSSModel::getItem(int i) const {
    if (i >= 0 && i < m_items.size())
        return m_items.at(i);
    return RssItem(); // 返回空对象防止越界
}

void RSSModel::loadStars()
{
    if (m_dbManager) {
        setItems(m_dbManager->getStarItems());
    }
}
