# Question 1 — English discussion draft

Draft status: expected results have been checked through supplementary SQLite logic tests. SQL Server execution, genuine screenshots and the .bacpac export remain pending. Update the wording after verifying the supplied scripts in SSMS.

## Scope, assumptions and table design

The proposed database supports three decisions at HarperCollins Australia's single distribution centre: which titles face a saleable-stock shortfall, which stocked titles warrant an inactivity review, and which outstanding retailer orders could be consolidated. These reports concern physical books because eBooks and audio downloads do not consume physical warehouse stock. All records, titles, identifiers, costs and retailer addresses are fictional demonstration data rather than evidence of HarperCollins' actual operations.

The reporting snapshot is the beginning of 16 November 2026. Quantities represent individual copies, costs are Australian dollars, and all earlier dispatches are reflected in the stock snapshot. Quarantined copies are physically present but unavailable for sale. Historical dispatches are subtracted from order quantities, not deducted again from current stock. The seven-day planning horizon includes 16–22 November; Query 1 additionally retains overdue demand. Statuses represent the snapshot, so this prototype cannot reconstruct arbitrary historical order states.

Six tables provide the necessary relationships without reproducing a complete WMS. Book stores title identity, a unique synthetic ISBN, first-stocked date and unit cost. Retailer stores each demonstration customer's single delivery address. SalesOrder stores the retailer, dates and status, while SalesOrderLine stores book quantities. Separating headers from lines avoids repeating order-level information. StockBalance holds one dated balance per book for the single centre. DispatchLine records quantities dispatched against order lines, allowing partial fulfilment. Primary keys identify records, foreign keys preserve references, and CHECK constraints reject negative or inconsistent stock quantities. This separation follows relational design principles concerning redundancy and integrity (Silberschatz et al., 2020).

The simplified model assumes no returns, over-dispatches, split delivery addresses or additional stock reservations. A separate validation script checks dispatch quantities, dates, snapshot coverage and closed-order completeness. Cross-row dispatch limits are checked by that script rather than enforced by a CHECK constraint. Eight books, three retailers and multiple order and dispatch records provide at least two rows per table and test contrasting situations. Additional production controls would be needed before using the database operationally.

## Reporting Query 1 — Saleable-stock shortfalls

Query 1 compares outstanding open-order demand with saleable stock by title. A nested derived table first aggregates dispatch quantities by order line. A LEFT JOIN retains lines with no dispatch records, with COALESCE treating their dispatched quantities as zero. Subsequent aggregation calculates total outstanding demand before joining Book and StockBalance. This order of operations prevents multiple dispatch records from multiplying ordered quantities or stock balances. Cancelled and closed orders, future-created orders and demand beyond the planning horizon are excluded; overdue demand remains visible.

The expected output identifies Coastal Stories with 80 outstanding copies against 45 saleable copies, a shortfall of 35. River Notes has demand for 40 copies against 10 available, a shortfall of 30. Coastal Stories includes a line dispatched in two instalments, demonstrating that the calculation subtracts their combined quantity once. Quarantined stock is excluded rather than overstating availability.

Managers could investigate replenishment, release eligible quarantined stock after inspection, or negotiate customer allocations. However, the query identifies a current planning gap rather than predicting a guaranteed service failure. It omits scheduled receipts, customer priority and future demand. It also depends on a complete stock snapshot; missing balances must be resolved using the validation script before interpreting the report. It does not prescribe which retailer should receive scarce copies.

## Reporting Query 2 — Stocked titles without recent dispatches

Query 2 identifies mature titles with positive saleable stock and no dispatch in the preceding 90 days, from 18 August through 15 November inclusive. An INNER JOIN connects books to their stock balances. A correlated NOT EXISTS subquery checks for recent dispatches through SalesOrderLine, while a second correlated subquery retrieves the latest earlier dispatch date. Books first stocked less than 90 days ago are excluded to avoid applying the same inactivity criterion to newly introduced titles. A NULL last-dispatch date means no earlier dispatch is recorded, not that a date is missing from an otherwise proven transaction.

Expected results are Outback Atlas, Quiet Stars, Forgotten Gardens and River Notes, with saleable stock costs of AUD750, AUD400, AUD400 and AUD110 respectively. The combined AUD1,660 is an inventory-cost exposure for review, not a calculated loss. Forgotten Gardens and River Notes have no recorded dispatch history. The use of NOT EXISTS preserves such titles, which an INNER JOIN to historical dispatches alone would omit.

The report can prompt investigation of demand, replenishment settings or marketing options. It measures title-level dispatch inactivity, not the residence time of particular copies, because receipt batches are not modelled. Crucially, River Notes also appears in Query 1: past inactivity coexists with current unmet demand. Managers should therefore cross-check outstanding orders before proposing clearance. Seasonal titles, incomplete history and returns could also change the interpretation. No automatic write-off or disposal decision follows from the 90-day threshold.

## Reporting Query 3 — Order-consolidation candidates

Query 3 identifies retailers with at least two outstanding orders sharing a requested dispatch date within the next seven days. A nested dispatch summary prevents duplicate counting, and the first aggregation produces one row per outstanding order. Fully dispatched lines and orders contribute nothing. The second aggregation joins Retailer and groups by retailer, fixed destination and requested date; HAVING retains groups containing multiple orders. Consequently, two book lines in one order do not incorrectly become two orders.

The expected output shows Retailer Alpha with two orders and 85 outstanding copies for 18 November, and Retailer Beta with two orders and 40 copies for the same date. Assuming one separate dispatch per remaining order, each group offers a theoretical reduction of one dispatch. Alpha's order for 19 November is kept separate, while cancelled, fully dispatched and out-of-horizon orders do not inflate the opportunity.

Managers could review these groups to coordinate packing, documentation and carrier collection. Nevertheless, a candidate is not an approved consolidated shipment or a quantified freight saving. Customer consent, carton capacity, carrier rules and stock availability remain untested. Query 1 also shows shortages affecting these groups, so combining orders may require replenishment first. The single-address assumption must be replaced with delivery-site records if retailers have multiple destinations. Unlike a delivery-punctuality measure, this report examines outstanding-order grouping and makes no claim about on-time performance.

## Reference

Silberschatz, A., Korth, H. F., & Sudarshan, S. (2020). *Database system concepts* (7th ed.). McGraw-Hill Education.
