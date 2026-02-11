#include "RssFilterModel.h"
#include "RssModel.h"

RssFilterModel::RssFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
}

void RssFilterModel::setSearchString(const QString &string)
{
    if (m_searchString == string)
        return;

    m_searchString = string;
    invalidate();
}

void RssFilterModel::switchStar(int row)
{
    QModelIndex sourceIndex = mapToSource(index(row, 0));
    RSSModel *source = qobject_cast<RSSModel*>(sourceModel());
    if (source) {
        source->switchStar(sourceIndex.row());
    }
}

RssItem RssFilterModel::getItem(int row) const
{
    QModelIndex sourceIndex = mapToSource(index(row, 0));
    RSSModel *source = qobject_cast<RSSModel*>(sourceModel());
    if (source) {
        return source->getItem(sourceIndex.row());
    }
    return RssItem();
}

bool RssFilterModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    if (m_searchString.isEmpty())
        return true;

    QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
    
    QString title = sourceModel()->data(index, RSSModel::TitleRole).toString();
    QString description = sourceModel()->data(index, RSSModel::DescriptionRole).toString();
    QString author = sourceModel()->data(index, RSSModel::AuthorRole).toString();

    if (title.contains(m_searchString, Qt::CaseInsensitive) ||
        description.contains(m_searchString, Qt::CaseInsensitive) ||
        author.contains(m_searchString, Qt::CaseInsensitive)) {
        return true;
    }

    return false;
}
