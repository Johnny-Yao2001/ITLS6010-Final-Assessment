"""Supplementary SQLite checks, NOT SQL Server execution evidence.

Loads the actual setup/report files with a small, explicit dialect translation.
Checks expected outputs and meaningful edge cases; never produces fake screenshots.
Run: python question1/tools/validate_logic.py
"""
from pathlib import Path
import csv
import json
import re
import sqlite3
import unittest

ROOT = Path(__file__).resolve().parents[1]


def translate(sql):
    sql = re.sub(r"/\*.*?\*/", "", sql, flags=re.S)
    sql = re.sub(r"^\s*(USE .+;|GO|SET NOCOUNT ON;|DECLARE @AsOfDate .+;)\s*$", "", sql, flags=re.M)
    sql = sql.replace("dbo.", "").replace("@AsOfDate", "'2026-11-16'")
    sql = re.sub(r"\bINSERT (?!INTO\b)(\w+) VALUES", r"INSERT INTO \1 VALUES", sql)
    sql = re.sub(r"DATEADD\(day,\s*(-?\d+),\s*'2026-11-16'\)",
                 lambda m: f"date('2026-11-16', '{int(m[1]):+d} days')", sql)
    sql = re.sub(r"N'", "'", sql)
    sql = re.sub(r"'(\d{4})(\d{2})(\d{2})'", r"'\1-\2-\3'", sql)
    return sql


def connect():
    db = sqlite3.connect(":memory:")
    db.execute("PRAGMA foreign_keys = ON")
    setup = (ROOT / "01_setup.sql").read_text()
    setup = setup.split("BEGIN TRANSACTION;", 1)[1].split("COMMIT TRANSACTION;", 1)[0]
    db.executescript(translate(setup))
    return db


def report(db, number):
    path = sorted(ROOT.glob(f"0{number + 1}_query*.sql"))[0]
    return db.execute(translate(path.read_text()))


class ReportChecks(unittest.TestCase):
    def setUp(self):
        self.db = connect()

    def tearDown(self):
        self.db.close()

    def test_table_counts_and_foreign_keys(self):
        self.assertEqual(self.db.execute("PRAGMA foreign_key_check").fetchall(), [])
        for table, count in {"Book": 8, "Retailer": 3, "SalesOrder": 14,
                             "SalesOrderLine": 15, "StockBalance": 8, "DispatchLine": 9}.items():
            self.assertEqual(self.db.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0], count)

    def test_shortfall_outputs(self):
        self.assertEqual(report(self.db, 1).fetchall(), [
            (101, "Coastal Stories", 80, 45, 35), (108, "River Notes", 40, 10, 30)])

    def test_dormant_outputs(self):
        self.assertEqual(report(self.db, 2).fetchall(), [
            (103, "Outback Atlas", 50, 15, 750, "2026-07-11"),
            (104, "Quiet Stars", 40, 10, 400, "2026-07-10"),
            (105, "Forgotten Gardens", 20, 20, 400, None),
            (108, "River Notes", 10, 11, 110, None)])

    def test_consolidation_outputs(self):
        rows = report(self.db, 3).fetchall()
        self.assertEqual([(r[0], *r[3:]) for r in rows], [
            (1, "2026-11-18", 2, 85, 1), (2, "2026-11-18", 2, 40, 1)])

    def test_overdue_demand_is_included(self):
        self.db.execute("UPDATE SalesOrder SET RequestedDispatchDate='2026-11-14' WHERE SalesOrderID=1002")
        self.assertEqual(report(self.db, 1).fetchall()[0][2:], (80, 45, 35))

    def test_split_dispatch_does_not_multiply_order_quantities(self):
        self.db.execute("UPDATE DispatchLine SET DispatchedQty=2 WHERE DispatchLineID=1")
        self.db.execute("INSERT INTO DispatchLine VALUES (99,1,'2026-11-12',2)")
        self.assertEqual(report(self.db, 1).fetchall()[0][2:], (80, 45, 35))
        self.assertEqual(report(self.db, 3).fetchall()[0][-3:], (2, 85, 1))

    def test_recent_title_is_excluded(self):
        self.assertNotIn(106, [r[0] for r in report(self.db, 2)])

    def test_inactivity_window_includes_first_day(self):
        self.db.execute("UPDATE DispatchLine SET DispatchDate='2026-08-18' WHERE DispatchLineID=6")
        self.assertNotIn(104, [r[0] for r in report(self.db, 2)])
        self.db.execute("UPDATE DispatchLine SET DispatchDate='2026-08-17' WHERE DispatchLineID=6")
        self.assertIn(104, [r[0] for r in report(self.db, 2)])

    def test_last_day_and_snapshot_boundary(self):
        self.db.execute("UPDATE DispatchLine SET DispatchDate='2026-11-15' WHERE DispatchLineID=6")
        self.assertNotIn(104, [r[0] for r in report(self.db, 2)])
        self.db.execute("UPDATE DispatchLine SET DispatchDate='2026-11-16' WHERE DispatchLineID=6")
        row = next(r for r in report(self.db, 2) if r[0] == 104)
        self.assertIsNone(row[-1])

    def test_cancelled_fully_dispatched_and_future_orders_do_not_leak(self):
        self.db.execute("UPDATE SalesOrderLine SET OrderedQty=999999 WHERE SalesOrderLineID IN (8,11)")
        self.assertEqual(report(self.db, 1).fetchall()[0][2:], (80, 45, 35))
        self.assertEqual(len(report(self.db, 3).fetchall()), 2)

    def test_two_order_lines_are_not_counted_as_two_orders(self):
        self.db.execute("UPDATE SalesOrder SET OrderStatus='Cancelled' WHERE SalesOrderID=1002")
        self.assertEqual([r[0] for r in report(self.db, 3)], [2])

    def test_missing_stock_snapshot_is_detected(self):
        self.db.execute("DELETE FROM StockBalance WHERE BookID=101")
        rows = self.db.execute("SELECT b.BookID FROM Book b LEFT JOIN StockBalance s ON s.BookID=b.BookID AND s.SnapshotDate='2026-11-16' WHERE s.BookID IS NULL").fetchall()
        self.assertEqual(rows, [(101,)])


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(ReportChecks)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if not result.wasSuccessful():
        raise SystemExit(1)
    (ROOT / "results").mkdir(exist_ok=True)
    db = connect()
    outputs = {}
    for i in range(1, 4):
        cur = report(db, i)
        headers = [c[0] for c in cur.description]
        rows = cur.fetchall()
        with (ROOT / "results" / f"query{i}_EXPECTED.csv").open("w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(headers)
            writer.writerows(rows)
        outputs[f"query{i}"] = [dict(zip(headers, row)) for row in rows]
    db.close()
    summary = {"engine": "SQLite, explicit dialect translation of supplied T-SQL",
               "sql_server_verified": False, "tests_passed": result.testsRun,
               "note": "Expected results only. Run original SQL files in SQL Server and take genuine screenshots.",
               "expected_outputs": outputs}
    (ROOT / "results" / "logic_validation.json").write_text(json.dumps(summary, indent=2))
