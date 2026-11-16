USE HarperCollins_Final_Q1;
GO
SET NOCOUNT ON;
DECLARE @AsOfDate date = '20261116';

/* Q2: Mature titles with saleable stock but no dispatch in the last 90 days.
   The window is [2026-08-18, 2026-11-16). Recent titles are excluded.
   This is title-level inactivity, NOT the age of individual physical copies.
*/
SELECT b.BookID, b.Title, s.OnHandQty - s.QuarantineQty AS SaleableQty,
       b.UnitCost,
       CAST((s.OnHandQty - s.QuarantineQty) * b.UnitCost AS decimal(12,2)) AS SaleableStockCost,
       (
           SELECT MAX(d.DispatchDate)
           FROM dbo.DispatchLine AS d
           INNER JOIN dbo.SalesOrderLine AS l ON l.SalesOrderLineID = d.SalesOrderLineID
           WHERE l.BookID = b.BookID AND d.DispatchDate < @AsOfDate
       ) AS LastDispatchDate
FROM dbo.Book AS b
INNER JOIN dbo.StockBalance AS s ON s.BookID = b.BookID
WHERE s.SnapshotDate = @AsOfDate
  AND s.OnHandQty > s.QuarantineQty
  AND b.FirstStockedDate <= DATEADD(day, -90, @AsOfDate)
  AND NOT EXISTS (
      SELECT 1
      FROM dbo.DispatchLine AS d
      INNER JOIN dbo.SalesOrderLine AS l ON l.SalesOrderLineID = d.SalesOrderLineID
      WHERE l.BookID = b.BookID
        AND d.DispatchDate >= DATEADD(day, -90, @AsOfDate)
        AND d.DispatchDate < @AsOfDate
  )
ORDER BY SaleableStockCost DESC, b.BookID;
GO
