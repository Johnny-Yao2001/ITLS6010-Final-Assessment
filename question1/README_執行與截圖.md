# Question 1：SSMS 執行與截圖指南

## 目前狀態

SQL、dummy data、英文討論稿及預期結果已完成。輔助 SQLite 邏輯測試通過 12 項，但**尚未在 SQL Server 執行**。由你在本機 SQL Server 執行及截圖後，才能補上最終證據與 `.bacpac`。沒有產生模擬 SSMS 截圖。

## 與期中作業的區別

| 查詢 | 期中主題 | 本次主題 |
|---|---|---|
| 1 | 揀貨準確率 | 按書籍計算未完成訂單的 saleable-stock 缺口 |
| 2 | 準時出貨率 | 90 天無出貨的庫存書籍及其庫存成本 |
| 3 | 供應商準時收貨率 | 同一零售商、同一要求出貨日的訂單合併機會 |
| 4 | 倉庫容量使用率 | 本次不使用此指標 |

本次沒有計算上述四個期中 KPI，也沒有複製期中查詢。Query 3 的日期用於分組，不是在計算準時率。

## 1. 在 SSMS 建立資料庫

1. 連線到你的 SQL Server instance，使用有權建立資料庫的帳號。
2. 開啟 `01_setup.sql`，按 Execute / F5。
3. 它會建立獨立資料庫 `HarperCollins_Final_Q1`；不會刪除原有資料庫。
4. 確認 Messages 沒有錯誤，並核對六張表的筆數：Book 8、Retailer 3、SalesOrder 14、SalesOrderLine 15、StockBalance 8、DispatchLine 9。
5. 設定腳本只執行一次。重跑若顯示「Q1 tables already exist」，代表保護機制阻止重複寫入；不要刪除期中資料庫。可直接繼續執行查詢檔案。

如果只想用一個檔案，可以改跑 `Q1_COMPLETE.sql`，內含建表、資料、三個查詢與驗證；**不要同時重複跑它和 01_setup.sql**。提交時可使用這份完整 SQL。

## 2. 執行三個報表

依序開啟、完整執行：

1. `02_query1_stock_shortfall.sql`
2. `03_query2_dormant_stock.sql`
3. `04_query3_consolidation.sql`

每個檔案會自行切換資料庫並使用固定日期 `20261116`，所以不用改成本機今天日期。避免只選取查詢的一部分執行，否則 DECLARE 或 CTE 可能沒有被包含。

### Query 1：應有 2 列

| BookID | Title | OutstandingQty | SaleableQty | ShortfallQty |
|---|---|---:|---:|---:|
| 101 | Coastal Stories | 80 | 45 | 35 |
| 108 | River Notes | 40 | 10 | 30 |

例：Coastal Stories = (50 − 4 − 6) + 40 = 80；saleable stock = 50 − 5 = 45；缺口 = 35。

### Query 2：應有 4 列

| BookID | Title | SaleableQty | UnitCost | SaleableStockCost | LastDispatchDate |
|---|---|---:|---:|---:|---|
| 103 | Outback Atlas | 50 | 15.00 | 750.00 | 2026-07-11 |
| 104 | Quiet Stars | 40 | 10.00 | 400.00 | 2026-07-10 |
| 105 | Forgotten Gardens | 20 | 20.00 | 400.00 | NULL |
| 108 | River Notes | 10 | 11.00 | 110.00 | NULL |

New Voices 是新上架書籍，未滿 90 天，因此不列入。River Notes 仍有未完成需求，不應因為零歷史出貨就直接建議清倉。

### Query 3：應有 2 列

| Retailer | RequestedDispatchDate | OutstandingOrders | OutstandingCopies | PotentialDispatchReduction |
|---|---|---:|---:|---:|
| Retailer Alpha | 2026-11-18 | 2 | 85 | 1 |
| Retailer Beta | 2026-11-18 | 2 | 40 | 1 |

實際結果還包含 RetailerID 與 DeliveryAddress。PotentialDispatchReduction 是「每張尚未完成訂單原本各出貨一次」假設下的候選減少次數，並非已達成的節省。

## 3. 真實截圖

每個查詢至少保留：

- 完整 SQL，包括 JOIN、子查詢、日期條件及排序。
- 對應的 Results，完整顯示所有欄位及列。
- 最好保留 SSMS 的查詢分頁或資料庫資訊，方便辨識。

若同一畫面放不下，不要縮到看不清：分成同一個查詢的 SQL 截圖（必要時上下兩張）與結果截圖。建議命名 `Q1_Query1_SQL.png`、`Q1_Query1_Result.png`，依此類推，放在 `question1/evidence/`。

另外可截六張表的欄位與 PK/FK，或在 SSMS Database Diagrams 中加入六張表並保存關聯圖。腳本本身已提供完整結構。`evidence/schema.png` 是設計示意圖，不是 SSMS 執行截圖。

## 4. 驗證資料

執行 `05_validation.sql`。前四個 exception result sets 應該都是 0 列，DBCC CHECKCONSTRAINTS 不應回報違規。三個報表的列數與數值仍須另外核對上方表格。

若結果不同，先保留錯誤或結果畫面，再檢查是否修改了資料、日期或只執行部分 SQL。不要為了符合預期數字直接修改結果表。

## 5. 匯出 .bacpac

1. 在 Object Explorer 重新整理，右鍵 **HarperCollins_Final_Q1**。
2. 選 **Tasks → Export Data-tier Application**。
3. 選 **Save to local disk**，檔名 `HarperCollins_Final_Q1.bacpac`。
4. 完成匯出並確認 Success。
5. 建議用 **Databases → Import Data-tier Application** 匯入另一個測試資料庫（例如 `HarperCollins_Final_Q1_ImportCheck`），確認六張表及筆數。若要在該副本測試查詢，須將查詢的 USE 改為副本名稱，避免誤查原資料庫。

注意：`.bak` 備份檔不是 `.bacpac`；Export Data-tier Application 也不同於 Generate Scripts。

## 6. 完成 Word

`Q1_Working_Template.docx` 是依原 template 填入 Q1 的工作稿，Q2 保留待寫；`Q1_English_Draft.md` 是可編輯文字來源。

1. 在 Reporting Query 1–3 的預留位置插入真實 SQL 與結果截圖。
2. 確認實際結果與草稿一致後，更新「預期／待驗證」字樣及狀態註記。
3. 參考文獻的斜體及 APA 格式最後統一整理，並保留 Q2 的字數空間。
4. 理解並調整文字，確保能解釋每個 JOIN、子查詢及假設；依課程規定披露 AI 協助。
5. 最終提交完成的 Word、完整 `.sql`、`.bacpac`，以及你另外建立的 Excel（若有）。分別上傳，不要 ZIP。

## 輔助測試（可選）

在 repository 根目錄執行 `python question1/tools/validate_logic.py`。它使用 SQLite 與明確的 T-SQL 語法轉換，測試預期結果及邊界條件。`results/*_EXPECTED.csv` 和 `results/logic_validation.json` 是輔助結果，**不代表 SQL Server 執行成功，也不是要提交的截圖**。

資料模型只保留一個 current snapshot；如要換報表日期，不能只改日期參數，還需提供對應庫存與訂單狀態資料。
