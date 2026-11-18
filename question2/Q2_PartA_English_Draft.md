# Question 2, Part A — GS1 implementation recommendations for OMNIA Logistics

OMNIA should prioritise interoperable identification, barcode capture and shipment-data exchange as it configures SAP. As a warehouse service provider handling customers’ goods, it should preserve customers’ valid identifiers and map them to SAP records. The recommendations below assume mixed customer products and palletised outbound deliveries; they are proposed controls, not claims about OMNIA’s existing operations.

## Identify products, locations and logistics units

GTINs should identify trade items at the relevant packaging levels, with mappings to SAP material numbers and units of measure. OMNIA should validate customer-supplied GTINs during onboarding and distinguish eaches, cases and other traded configurations, preventing a case scan from being interpreted as one individual item. Brand owners normally allocate product GTINs; OMNIA should not replace them with warehouse-specific product identifiers (GS1, n.d.-b).

GLNs should identify relevant parties and physical locations, such as customers, the distribution centre and delivery destinations, and map to SAP business-partner and location records. This supports consistent ship-to identification across customers and carriers. Internal storage bins can retain SAP bin codes, with GLN extension components considered only where finer location identification is required; a separate GLN for every bin is unnecessary (GS1, n.d.-a).

Each pallet or other logistics unit should carry a unique SSCC, linked to its SAP handling unit, contents and outbound delivery. This distinguishes two pallets containing identical products and allows a mixed pallet’s contents to be retrieved without encoding every item on its label. OMNIA should agree SSCC allocation responsibilities with customers and preserve valid incoming SSCCs while the logistics unit remains unchanged (GS1, n.d.-e).

## Capture and share operational data

GS1-128 logistics labels should encode the SSCC using Application Identifier (00). Where relevant to customer products, additional GS1 data can identify batches and expiry dates using AIs (10) and (17). At receiving, staff should scan the logistics unit and verify its contents; during picking, scan the source bin and product against the delivery requirement; at packing and loading, scan the unit against the handling-unit record and shipment. SAP integration should reject mismatches and route exceptions for investigation rather than silently accepting incorrect quantities (GS1, n.d.-c).

OMNIA should exchange structured shipment information through agreed GS1 EDI messages, initially a Despatch Advice linking SSCCs, item quantities and destinations. Partners can match the arriving units to the electronic notice. Data mappings and acknowledgements must be tested with each partner. EPCIS can be assessed later if customers require interoperable event-level visibility; it is not essential to the initial barcode-and-despatch-notice scope (GS1, n.d.-d).

## Implement and evaluate

A pilot should cover one customer and one outbound flow before expansion. OMNIA should agree identifier ownership, validate master data and packaging conversions, test labels with actual scanners, train operators and define exception ownership. Measures should include first-pass scan success, wrong-item picks, inventory accuracy and despatch-notice matching. Scans must trigger the appropriate SAP transactions and confirmations: identification alone neither supplies missing stock nor completes a warehouse transfer order. This phased approach tests operational benefits before wider investment.
