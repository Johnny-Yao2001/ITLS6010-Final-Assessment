# Question 2, Part A — GS1 implementation recommendations for OMNIA Logistics

For OMNIA, the value of GS1 lies in connecting physical warehouse movements with consistent information across customers, SAP and transport partners. Assuming mixed customer products and palletised deliveries, the proposed design combines identification, barcode capture and shipment-data exchange. Research treats order picking as a system of interdependent design and control decisions, suggesting that identification technology needs to fit the operating process rather than function as an isolated addition (de Koster et al., 2007).

## Identify products, locations and logistics units

GTINs provide a common identity for trade items at relevant packaging levels. Mapping customer-supplied GTINs to SAP material numbers and units of measure would distinguish individual items from cases, reducing the risk of interpreting a case scan as one unit. Customer onboarding therefore includes identifier validation and packaging-conversion checks. Existing brand-owner GTINs remain the product identifiers; internal warehouse codes serve as cross-references (GS1, n.d.-b).

GLNs complement product identification by identifying parties and physical locations, including customers, the distribution centre and delivery destinations. Their mapping to SAP business-partner and location records creates consistent ship-to references across organisations (GS1, n.d.-a). Internal bins can retain SAP bin codes unless external interoperability requires finer location identification.

At logistics-unit level, an SSCC identifies each pallet independently of its product contents. Linking it to the SAP handling unit, contents and outbound delivery makes otherwise identical pallets distinguishable and supports mixed-pallet reconciliation. Allocation responsibilities need agreement with customers, while valid incoming SSCCs remain associated with unchanged logistics units (GS1, n.d.-e).

## Capture and share operational data

GS1-128 labels encode the SSCC using Application Identifier (00); batch and expiry data, where relevant, use AIs (10) and (17) (GS1, n.d.-c). The proposed checkpoints are receiving, picking, packing and loading. Operators verify incoming units against expected contents, scan bins and products against picking requirements, and match packed units to shipments. SAP validation can flag discrepancies for investigation before the next transaction proceeds.

These controls offer a plausible route to better inventory visibility, but technology alone does not guarantee accuracy. Sarac et al. (2010) review RFID’s effects on inventory management, highlighting both potential benefits and implementation considerations. Their findings provide context for evaluating identification technologies, not direct evidence of a particular barcode-related saving at OMNIA. Barcode capture is the initial recommendation; any RFID investment requires a separate business case.

For partner communication, GS1 EDI Despatch Advice can link SSCCs, quantities and destinations before goods arrive, allowing recipients to reconcile the notice with scanned units (GS1, n.d.-d). Partner-specific mappings and acknowledgements require testing alongside SAP integration.

## Implement and evaluate

A one-customer pilot would test identifier ownership, packaging conversions, label readability, transaction updates and exception handling before expansion. Evaluation can compare baseline and pilot results for first-pass scan success, wrong-item picks, inventory accuracy and notice-to-receipt matching. Training and clear responsibility for discrepancies are integral to this design. Importantly, a successful scan does not itself establish stock availability or confirm a warehouse transfer order: those outcomes depend on validated SAP transactions. Measured operational improvement, rather than label deployment alone, provides the basis for wider adoption.
