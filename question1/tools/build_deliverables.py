"""Build the complete SQL and Q1 working copy of the supplied Word template.

Requires python-docx; run from any directory. Original template stays unchanged.
No screenshots or SQL Server results are fabricated.
"""
from pathlib import Path
import json
import os
import re
import subprocess

from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.style import WD_STYLE_TYPE
from docx.oxml import OxmlElement
from docx.text.paragraph import Paragraph

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parent


def insert_before(anchor, text, style=None):
    paragraph = anchor.insert_paragraph_before(text, style)
    paragraph.paragraph_format.space_after = Pt(6)
    return paragraph


sql_files = ["01_setup.sql", "02_query1_stock_shortfall.sql", "03_query2_dormant_stock.sql",
             "04_query3_consolidation.sql", "05_validation.sql"]
complete = "-- COMPLETE Q1 SCRIPT: run ONCE in SQL Server / SSMS. Synthetic data.\n"
complete += "-- Existing Q1 tables are protected; no databases or tables are dropped.\n\n"
for filename in sql_files:
    complete += f"-- ==================== {filename} ====================\n"
    complete += (ROOT / filename).read_text() + "\n\n"
(ROOT / "Q1_COMPLETE.sql").write_text(complete)

subprocess.run(["dot", "-Tpng", "-Gdpi=160", str(ROOT / "tools/schema.dot"),
                "-o", str(ROOT / "evidence/schema.png")], check=True,
               env={**os.environ, "XDG_CACHE_HOME": "/tmp/itls-font-cache"})

doc = Document(REPO / "ITLS6010 Final Assessment Template-1-1.docx")
normal = doc.styles["Normal"]
normal.font.name = "Calibri"
normal.font.size = Pt(11)
if "Heading 2" not in doc.styles:
    heading = doc.styles.add_style("Heading 2", WD_STYLE_TYPE.PARAGRAPH)
    heading.base_style = normal
    heading.font.bold = True
    heading.font.size = Pt(12)
for section in doc.sections:
    section.top_margin = Inches(0.65)
    section.bottom_margin = Inches(0.65)

tables_anchor = next(p for p in doc.paragraphs if p.text.strip() == "Tables:")
status = insert_before(tables_anchor,
    "WORKING DRAFT — Q1 only. SQL Server execution, genuine query/result screenshots and .bacpac export are pending. Q2 is not yet completed.")
for run in status.runs:
    run.bold = True
    run.font.color.rgb = RGBColor.from_string("9C3B10")

diagram = tables_anchor.insert_paragraph_before()
# Put the diagram after the Tables label, before the next original paragraph.
tables_anchor._p.addnext(diagram._p)
diagram.add_run().add_picture(str(ROOT / "evidence/schema.png"), width=Inches(6.7))
caption = Paragraph(OxmlElement("w:p"), diagram._parent)
diagram._p.addnext(caption._p)
caption.add_run("Figure 1. Proposed table relationships; generated design diagram, not an SSMS screenshot.").italic = True

schema = [
    ("Book", "BookID (PK); ISBN13 (unique); Title; FirstStockedDate; UnitCost", "8"),
    ("Retailer", "RetailerID (PK); RetailerName; DeliveryAddress", "3"),
    ("SalesOrder", "SalesOrderID (PK); RetailerID (FK); CreatedDate; RequestedDispatchDate; OrderStatus", "14"),
    ("SalesOrderLine", "SalesOrderLineID (PK); SalesOrderID, BookID (FKs); OrderedQty; unique order/book", "15"),
    ("StockBalance", "BookID (PK/FK); SnapshotDate; OnHandQty; QuarantineQty", "8"),
    ("DispatchLine", "DispatchLineID (PK); SalesOrderLineID (FK); DispatchDate; DispatchedQty", "9"),
]
t = doc.add_table(rows=1, cols=3)
t.style = "Table Grid"
for c, text in zip(t.rows[0].cells, ["Table", "Fields and keys", "Rows"]):
    c.text = text
for row in schema:
    for c, text in zip(t.add_row().cells, row):
        c.text = text
caption._p.addnext(t._tbl)

data = json.loads((ROOT / "results/logic_validation.json").read_text())
report_table = doc.tables[1]  # newly inserted schema table is now table 0
titles = ["Saleable-stock shortfalls", "Stocked titles without recent dispatches", "Order-consolidation candidates"]
for i, title in enumerate(titles, 1):
    report_table.rows[(i - 1) * 2].cells[0].text = f"Reporting Query {i}: {title}"
    cell = report_table.rows[(i - 1) * 2 + 1].cells[0]
    cell.text = f"[INSERT GENUINE SSMS QUERY {i} SQL SCREENSHOT(S) AND CORRESPONDING RESULTS HERE]"
    cell.add_paragraph("Expected results below are illustrative, checked with translated SQLite logic; SQL Server confirmation is pending.")
    rows = data["expected_outputs"][f"query{i}"]
    keys = list(rows[0])
    if i == 3:
        keys.remove("DeliveryAddress")
    result_table = cell.add_table(rows=1, cols=len(keys))
    result_table.style = "Table Grid"
    for c, key in zip(result_table.rows[0].cells, keys):
        c.text = key
    for row in rows:
        for c, key in zip(result_table.add_row().cells, keys):
            c.text = "NULL" if row[key] is None else str(row[key])
    for row in result_table.rows:
        for c in row.cells:
            for p in c.paragraphs:
                for run in p.runs:
                    run.font.size = Pt(8)

q2 = next(p for p in doc.paragraphs if p.text.startswith("Question 2"))
text = (ROOT / "Q1_English_Draft.md").read_text()
body = text.split("## Scope, assumptions and table design\n", 1)[1].split("## Reference", 1)[0]
insert_before(q2, "Scope, assumptions and table design", "Heading 2")
for block in body.strip().split("\n\n"):
    if block.startswith("## "):
        insert_before(q2, block[3:].strip(), "Heading 2")
    else:
        insert_before(q2, block.strip())
insert_before(q2, "[Before submission: confirm all reported results in SQL Server and replace the expected-result wording and draft status.]")
refs = next(p for p in doc.paragraphs if p.text.strip() == "References")
ref_p = Paragraph(OxmlElement("w:p"), refs._parent)
refs._p.addnext(ref_p._p)
ref_p.add_run("Silberschatz, A., Korth, H. F., & Sudarshan, S. (2020). ")
ref_p.add_run("Database system concepts").italic = True
ref_p.add_run(" (7th ed.). McGraw-Hill Education.")
# Remove the original template's trailing empty spacer table in this working copy.
last_table = doc.tables[-1]
if not any(c.text.strip() for row in last_table.rows for c in row.cells):
    last_table._tbl.getparent().remove(last_table._tbl)
# Keep short table rows intact across pages, including nested expected-result tables.
for row in doc.element.body.iter():
    if row.tag.endswith("}tr"):
        properties = row.find("{http://schemas.openxmlformats.org/wordprocessingml/2006/main}trPr")
        if properties is None:
            properties = OxmlElement("w:trPr")
            row.insert(0, properties)
        properties.append(OxmlElement("w:cantSplit"))
doc.save(ROOT / "Q1_Working_Template.docx")
word_count = len(re.sub(r"^## .+$", "", body, flags=re.M).split())
print(f"Wrote Q1_COMPLETE.sql and Q1_Working_Template.docx. Q1 discussion: approximately {word_count} words, excluding table text, references and draft notes.")
