USE HarperCollins_Final_Q1;
GO
SET NOCOUNT ON;
DECLARE @AsOfDate date = '20261116';

/* Q3: Same-retailer, same-requested-date open orders that could be reviewed
   for consolidation. Each retailer has exactly one fixed delivery address.
   Theoretical reduction assumes one separate dispatch per outstanding order.
   It does not establish stock readiness, freight savings or customer consent.
*/
WITH OrderRemainder AS (
    SELECT o.SalesOrderID, o.RetailerID, o.RequestedDispatchDate,
           SUM(l.OrderedQty - COALESCE(d.DispatchedQty, 0)) AS OutstandingCopies
    FROM dbo.SalesOrder AS o
    INNER JOIN dbo.SalesOrderLine AS l ON l.SalesOrderID = o.SalesOrderID
    LEFT JOIN (
        SELECT SalesOrderLineID, SUM(DispatchedQty) AS DispatchedQty
        FROM dbo.DispatchLine
        WHERE DispatchDate < @AsOfDate
        GROUP BY SalesOrderLineID
    ) AS d ON d.SalesOrderLineID = l.SalesOrderLineID
    WHERE o.OrderStatus = 'Open'
      AND o.CreatedDate < @AsOfDate
      AND o.RequestedDispatchDate >= @AsOfDate
      AND o.RequestedDispatchDate < DATEADD(day, 7, @AsOfDate)
      AND l.OrderedQty > COALESCE(d.DispatchedQty, 0)
    GROUP BY o.SalesOrderID, o.RetailerID, o.RequestedDispatchDate
)
SELECT r.RetailerID, r.RetailerName, r.DeliveryAddress, o.RequestedDispatchDate,
       COUNT(*) AS OutstandingOrders, SUM(o.OutstandingCopies) AS OutstandingCopies,
       COUNT(*) - 1 AS PotentialDispatchReduction
FROM OrderRemainder AS o
INNER JOIN dbo.Retailer AS r ON r.RetailerID = o.RetailerID
GROUP BY r.RetailerID, r.RetailerName, r.DeliveryAddress, o.RequestedDispatchDate
HAVING COUNT(*) >= 2
ORDER BY PotentialDispatchReduction DESC, r.RetailerID, o.RequestedDispatchDate;
GO
