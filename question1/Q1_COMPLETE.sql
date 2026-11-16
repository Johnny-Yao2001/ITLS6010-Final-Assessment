-- COMPLETE Q1 SCRIPT: run ONCE in SQL Server / SSMS. Synthetic data.
-- Existing Q1 tables are protected; no databases or tables are dropped.

-- ==================== 01_setup.sql ====================
/* ITLS6010 Final Assessment — Question 1
   Synthetic data only. One physical-book distribution centre.
   Run this file ONCE in SSMS. It creates a separate database and never drops data.
   Snapshot: beginning of 16 November 2026. All quantities are individual copies.
*/
USE master;
GO
IF DB_ID(N'HarperCollins_Final_Q1') IS NULL
    EXEC(N'CREATE DATABASE HarperCollins_Final_Q1');
GO
USE HarperCollins_Final_Q1;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF OBJECT_ID(N'dbo.Book', N'U') IS NOT NULL
    THROW 50001, 'Q1 tables already exist. Setup stopped without changing data. Run the reporting files instead.', 1;

BEGIN TRANSACTION;
CREATE TABLE dbo.Book (
    BookID int NOT NULL CONSTRAINT PK_Book PRIMARY KEY,
    ISBN13 char(13) NOT NULL CONSTRAINT UQ_Book_ISBN UNIQUE,
    Title nvarchar(120) NOT NULL,
    FirstStockedDate date NOT NULL,
    UnitCost decimal(10,2) NOT NULL CONSTRAINT CK_Book_Cost CHECK (UnitCost >= 0)
);
CREATE TABLE dbo.Retailer (
    RetailerID int NOT NULL CONSTRAINT PK_Retailer PRIMARY KEY,
    RetailerName nvarchar(80) NOT NULL,
    DeliveryAddress nvarchar(160) NOT NULL
);
CREATE TABLE dbo.SalesOrder (
    SalesOrderID int NOT NULL CONSTRAINT PK_SalesOrder PRIMARY KEY,
    RetailerID int NOT NULL CONSTRAINT FK_Order_Retailer REFERENCES dbo.Retailer(RetailerID),
    CreatedDate date NOT NULL,
    RequestedDispatchDate date NOT NULL,
    OrderStatus varchar(10) NOT NULL,
    CONSTRAINT CK_Order_Status CHECK (OrderStatus IN ('Open','Closed','Cancelled')),
    CONSTRAINT CK_Order_Dates CHECK (RequestedDispatchDate >= CreatedDate)
);
CREATE TABLE dbo.SalesOrderLine (
    SalesOrderLineID int NOT NULL CONSTRAINT PK_OrderLine PRIMARY KEY,
    SalesOrderID int NOT NULL CONSTRAINT FK_Line_Order REFERENCES dbo.SalesOrder(SalesOrderID),
    BookID int NOT NULL CONSTRAINT FK_Line_Book REFERENCES dbo.Book(BookID),
    OrderedQty int NOT NULL CONSTRAINT CK_Line_Qty CHECK (OrderedQty > 0),
    CONSTRAINT UQ_Line_OrderBook UNIQUE (SalesOrderID, BookID)
);
CREATE TABLE dbo.StockBalance (
    BookID int NOT NULL CONSTRAINT PK_Stock PRIMARY KEY
        CONSTRAINT FK_Stock_Book REFERENCES dbo.Book(BookID),
    SnapshotDate date NOT NULL,
    OnHandQty int NOT NULL,
    QuarantineQty int NOT NULL,
    CONSTRAINT CK_Stock_Qty CHECK (OnHandQty >= 0 AND QuarantineQty >= 0 AND QuarantineQty <= OnHandQty)
);
CREATE TABLE dbo.DispatchLine (
    DispatchLineID int NOT NULL CONSTRAINT PK_Dispatch PRIMARY KEY,
    SalesOrderLineID int NOT NULL CONSTRAINT FK_Dispatch_Line REFERENCES dbo.SalesOrderLine(SalesOrderLineID),
    DispatchDate date NOT NULL,
    DispatchedQty int NOT NULL CONSTRAINT CK_Dispatch_Qty CHECK (DispatchedQty > 0)
);

-- Fictional titles, ISBN-like identifiers, retailers and addresses; not company facts.
INSERT dbo.Book VALUES
 (101,'9780000000101',N'Coastal Stories','20260101',12.00),
 (102,'9780000000118',N'Harbour Walking Guide','20260101',8.00),
 (103,'9780000000125',N'Outback Atlas','20260101',15.00),
 (104,'9780000000132',N'Quiet Stars','20260101',10.00),
 (105,'9780000000149',N'Forgotten Gardens','20260101',20.00),
 (106,'9780000000156',N'New Voices','20261101',18.00),
 (107,'9780000000163',N'City Sketches','20260101',9.00),
 (108,'9780000000170',N'River Notes','20260101',11.00);
INSERT dbo.Retailer VALUES
 (1,N'Retailer Alpha',N'10 Example Street, Sydney NSW'),
 (2,N'Retailer Beta',N'20 Example Street, Melbourne VIC'),
 (3,N'Retailer Gamma',N'30 Example Street, Brisbane QLD');
INSERT dbo.SalesOrder VALUES
 (1001,1,'20261110','20261118','Open'),
 (1002,1,'20261111','20261118','Open'),
 (1003,1,'20261112','20261119','Open'),
 (1004,2,'20261110','20261118','Open'),
 (1005,2,'20261111','20261118','Open'),
 (1006,3,'20261112','20261120','Open'),
 (1007,3,'20261112','20261120','Cancelled'),
 (1008,3,'20261112','20261120','Closed'),
 (1009,3,'20261112','20261120','Open'),
 (1010,3,'20261112','20261201','Open'),
 (9001,1,'20260701','20260710','Closed'),
 (9002,2,'20260701','20260711','Closed'),
 (9003,3,'20260801','20260818','Closed'),
 (9004,1,'20261101','20261105','Closed');
INSERT dbo.SalesOrderLine VALUES
 (1,1001,101,50),(2,1001,102,10),(3,1002,101,40),
 (4,1003,103,10),(5,1004,102,10),(6,1005,108,30),
 (7,1006,108,10),(8,1007,101,999),(9,1008,101,7),
 (10,1009,107,5),(11,1010,101,500),
 (12,9001,104,10),(13,9002,103,20),(14,9003,107,5),
 (15,9004,101,10);
INSERT dbo.StockBalance VALUES
 (101,'20261116',50,5),(102,'20261116',20,0),
 (103,'20261116',60,10),(104,'20261116',40,0),
 (105,'20261116',25,5),(106,'20261116',30,0),
 (107,'20261116',0,0),(108,'20261116',10,0);
-- Two dispatch records on line 1 deliberately test aggregation before joins.
INSERT dbo.DispatchLine VALUES
 (1,1,'20261112',4),(2,1,'20261113',6),(3,2,'20261113',5),
 (4,9,'20261113',7),(5,10,'20261113',5),
 (6,12,'20260710',10),(7,13,'20260711',20),
 (8,14,'20260818',5),(9,15,'20261105',10);
COMMIT TRANSACTION;

-- Counts: Book 8; Retailer 3; SalesOrder 14; SalesOrderLine 15; StockBalance 8; DispatchLine 9.
SELECT N'Book' AS TableName, COUNT(*) AS [RowCount] FROM dbo.Book
UNION ALL SELECT N'Retailer',COUNT(*) FROM dbo.Retailer
UNION ALL SELECT N'SalesOrder',COUNT(*) FROM dbo.SalesOrder
UNION ALL SELECT N'SalesOrderLine',COUNT(*) FROM dbo.SalesOrderLine
UNION ALL SELECT N'StockBalance',COUNT(*) FROM dbo.StockBalance
UNION ALL SELECT N'DispatchLine',COUNT(*) FROM dbo.DispatchLine;
GO


-- ==================== 02_query1_stock_shortfall.sql ====================
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


-- ==================== 03_query2_dormant_stock.sql ====================
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


-- ==================== 04_query3_consolidation.sql ====================
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


-- ==================== 05_validation.sql ====================
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


