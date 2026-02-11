#ifndef RSSFILTERMODEL_H
#define RSSFILTERMODEL_H

#include <QSortFilterProxyModel>
#include "RssItem.h"

class RssFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
public:
    explicit RssFilterModel(QObject *parent = nullptr);

    Q_INVOKABLE void setSearchString(const QString &string);
    Q_INVOKABLE void switchStar(int row);
    Q_INVOKABLE RssItem getItem(int row) const;

protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;

private:
    QString m_searchString;
};

#endif // RSSFILTERMODEL_H
