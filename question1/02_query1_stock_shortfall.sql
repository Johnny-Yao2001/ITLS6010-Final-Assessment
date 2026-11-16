USE HarperCollins_Final_Q1;
GO
SET NOCOUNT ON;
DECLARE @AsOfDate date = '20261116';

/* Q1: Saleable-stock shortfalls against overdue/next-seven-day open demand.
   Do not join raw dispatch rows to stock or order totals: pre-aggregate first.
   There is no inter-order allocation priority; this is a title-level exception report.
*/
WITH OutstandingLine AS (
    SELECT l.BookID,
           l.OrderedQty - COALESCE(d.DispatchedQty, 0) AS OutstandingQty
    FROM dbo.SalesOrderLine AS l
    INNER JOIN dbo.SalesOrder AS o ON o.SalesOrderID = l.SalesOrderID
    LEFT JOIN (
        SELECT SalesOrderLineID, SUM(DispatchedQty) AS DispatchedQty
        FROM dbo.DispatchLine
        WHERE DispatchDate < @AsOfDate
        GROUP BY SalesOrderLineID
    ) AS d ON d.SalesOrderLineID = l.SalesOrderLineID
    WHERE o.OrderStatus = 'Open'
      AND o.CreatedDate < @AsOfDate
      AND o.RequestedDispatchDate < DATEADD(day, 7, @AsOfDate)
), Demand AS (
    SELECT BookID, SUM(OutstandingQty) AS OutstandingQty
    FROM OutstandingLine
    WHERE OutstandingQty > 0
    GROUP BY BookID
)
SELECT b.BookID, b.Title, d.OutstandingQty,
       s.OnHandQty - s.QuarantineQty AS SaleableQty,
       d.OutstandingQty - (s.OnHandQty - s.QuarantineQty) AS ShortfallQty
FROM Demand AS d
INNER JOIN dbo.Book AS b ON b.BookID = d.BookID
INNER JOIN dbo.StockBalance AS s ON s.BookID = b.BookID
WHERE s.SnapshotDate = @AsOfDate
  AND d.OutstandingQty > s.OnHandQty - s.QuarantineQty
ORDER BY ShortfallQty DESC, b.BookID;
GO
