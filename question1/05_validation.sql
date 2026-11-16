USE HarperCollins_Final_Q1;
GO
SET NOCOUNT ON;
/* All exception queries below must return zero rows on the supplied data.
   These are supplementary checks; they do not replace executing all 3 reports.
*/
-- No line has been dispatched beyond its ordered quantity.
SELECT l.SalesOrderLineID, l.OrderedQty, SUM(d.DispatchedQty) AS DispatchedQty
FROM dbo.SalesOrderLine AS l
INNER JOIN dbo.DispatchLine AS d ON d.SalesOrderLineID = l.SalesOrderLineID
GROUP BY l.SalesOrderLineID, l.OrderedQty
HAVING SUM(d.DispatchedQty) > l.OrderedQty;

-- No dispatch predates its order or falls outside the supplied snapshot history.
SELECT d.DispatchLineID
FROM dbo.DispatchLine AS d
INNER JOIN dbo.SalesOrderLine AS l ON l.SalesOrderLineID = d.SalesOrderLineID
INNER JOIN dbo.SalesOrder AS o ON o.SalesOrderID = l.SalesOrderID
WHERE d.DispatchDate < o.CreatedDate OR d.DispatchDate >= '20261116';

-- Every book has a matching stock snapshot, including zero-stock titles.
SELECT b.BookID
FROM dbo.Book AS b
LEFT JOIN dbo.StockBalance AS s ON s.BookID = b.BookID AND s.SnapshotDate = '20261116'
WHERE s.BookID IS NULL;

-- Closed orders are completely dispatched in this synthetic snapshot.
SELECT o.SalesOrderID
FROM dbo.SalesOrder AS o
INNER JOIN dbo.SalesOrderLine AS l ON l.SalesOrderID = o.SalesOrderID
LEFT JOIN (
    SELECT SalesOrderLineID, SUM(DispatchedQty) AS Qty
    FROM dbo.DispatchLine GROUP BY SalesOrderLineID
) AS d ON d.SalesOrderLineID = l.SalesOrderLineID
WHERE o.OrderStatus = 'Closed' AND l.OrderedQty <> COALESCE(d.Qty, 0);

DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
GO
