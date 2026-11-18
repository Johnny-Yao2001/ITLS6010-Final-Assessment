# Question 2, Part B — Diagnosing and correcting the PGI errors

Separate working draft. No Word file is edited. Figures B1–B6 below are proposed final-answer figure labels; source numbers refer to image order in `SAP Screenshots.docx`, not the conversation evidence log. The final section provides screenshot instructions for the end of the assignment.

## Draft answer

VL609 indicates that the delivery has not been completely picked, whereas VL608 indicates incomplete warehouse-management processing. I would treat these as related process-control failures rather than assume that repeatedly attempting Post Goods Issue (PGI) would resolve them. My investigation would distinguish three possibilities: insufficient eligible stock, failure to create a picking transfer order (TO), and an existing TO awaiting confirmation. The allocated delivery 80000082 initially required 710 EA of BRKT-038 but recorded zero picked, with picking and WM statuses A (Figure B1). This establishes the unmet prerequisites behind the supplied errors, although I did not independently reproduce that exact error log.

I would first reconcile delivery requirements with warehouse availability and transaction history. LS24 returned no quants, while MMBE showed no unrestricted quantity and 45 EA on order. The corresponding PO 4500000013 remained entirely undelivered and had no purchase-order history (Figure B2). MB51 also returned no material documents under the recorded selection. Together, these observations identified an unfulfilled stock prerequisite; an outstanding purchase does not constitute stock available for picking. Wave monitoring also returned no picking-progress records, directing attention to TO creation rather than simply confirming an assumed existing TO.

For this classroom test, I made an explicit replenishment assumption: create a separate 710 EA purchase while retaining the original 45 EA PO and allocated outbound documents. This quantity was a testing decision, not an assessment instruction. Receipt document 5000000074 and confirmed putaway TO 5138 subsequently established 710 EA available at allocated bin STBN-1-138 (Figure B3). Receipt alone would have been insufficient without completing and checking putaway.

I would then test whether the system could convert the available stock into a delivery-specific picking instruction. Automatic creation still failed; foreground processing reported an undefined storage-type search. This identified a source-determination problem distinct from the earlier stock gap. Manually selecting the verified source enabled TO 5149 to move 710 EA from type 001/bin STBN-1-138 to type 004/bin 0080000082. This addressed the tested transaction without demonstrating a permanent configuration repair. After confirming the actual quantity, I checked that the delivery recorded 710 EA picked and both picking and WM statuses C (Figure B4). These status checks verify correction of the two prerequisites rather than merely successful TO creation.

Finally, I completed packing and the classroom shipment stages, then retried PGI. Goods-issue document 4900038063 and status C confirmed successful posting on 18 November 2026 (Figure B5). Saved invoice 90000048 shows 710 EA, net USD60 and zero tax; the existing sales pricing was retained. Final document flow confirms completed delivery and invoice (Figure B6). The linked journal entry remains uncleared, which concerns financial settlement rather than failure of outbound processing.

## Editorial notes — do not paste into the answer

- The explanation centres on the causal sequence: stock prerequisite → source determination → TO confirmation → delivery-status verification → successful PGI/invoice.
- Do not claim that the exact supplied VL608/VL609 error screenshot was independently reproduced. Cite it as the question's supplied error log, then use actual delivery states to investigate the prerequisites.
- Foreground storage-search errors were captured in the conversation but are not clearly included as standalone outgoing-search screenshots in the uploaded 56-image Word. Do not relabel source image 22, which concerns inbound putaway search, as the outbound search failure. The observed outbound error is recorded in the conversation log as evidence 033/037; attach that original separately if desired.
- The replenishment assumption is disclosed. Neither the assessment instruction nor a confirmed configuration repair is invented.
- USD60 is a total net value. Its pricing mechanism and commercial validity have not been independently established.
- Use the six proposed figure labels consistently when inserting the actual screenshots. The following placement guide explains their source-image numbers.
- Verify the combined 2,000-word limit against the latest Q1 and Part A text before final submission. This file introduces no new external reference; the original SAP screenshots substantiate the observed results.

## 文件最後應放哪些證明截圖（編排指引，不屬英文正文）

將以下六組圖放在 Part B 正文之後、全篇 References 之前，或依老師指定格式放在文件末尾。它們是建議圖組，不表示題目明定六組圖。每組可有 a/b/c 子圖；只裁除無關空白，不改動數字、狀態或訊息。不要放入全部56張而讓主要證據難以閱讀。完整操作過程已另外保存在原始截圖Word。

| 正式圖號 | 原檔圖片位置 | 建議截圖內容 | 證明的分析／修正結論 |
|---|---|---|---|
| **Figure B1** | **第1張** | VL03N初始Picking：Delivery710、Picked0、PickingA、WMA | VL609/VL608相關前提確實未滿足；建立修正前基準。 |
| **Figure B2(a–c)** | **第9、10、14張** | LS24查無quant；MMBE無unrestricted現貨、45EA在訂購中；PO History無紀錄 | 交叉核對庫存及收貨，而不是看到採購單便認為有貨。第13張45EA全數未交、第16張MB51無資料可作選配補圖。 |
| **Figure B3** | **第27張** | LS24：001/STBN-1-138可用710EA | 證明補貨及上架後，實際揀貨來源已具備足夠可用量。 |
| **Figure B4(a–c)** | **第32、33、34張** | TO5149正確來源/目的與710EA；TO確認成功；交貨Picked710、Picking/WM=C | 區分建立指令、完成確認、更新交貨單三件事；直接對照B1，證明修正不是手動改已揀數字。 |
| **Figure B5** | **第45張** | Goods Movement=C Completed、ActualGI11/18/2026、710EA、601 | 證明PGI真正成功。第44張新建出庫文件4900038063的成功訊息可作子圖補充。 |
| **Figure B6(a–b)** | **第51、56張** | VF03正式Invoice90000048：客戶、710EA、60USD、稅0；最終Document Flow | **題目明確要求的發票明細以第51張為主**；第56張證明它與指定交貨單及已完成GI連結，並說明Not Cleared不等於開票失敗。 |

### 可直接使用的英文圖說

- **Figure B1.** Initial delivery status: 710 EA required, zero picked, and picking/WM statuses A.
- **Figure B2.** Stock and receipt investigation: no WM quants returned, 45 EA on order rather than unrestricted stock, and no history for the corresponding purchase-order item.
- **Figure B3.** After replenishment and putaway confirmation, 710 EA is available in allocated bin STBN-1-138.
- **Figure B4.** Picking TO 5149 specifies the correct movement, is confirmed, and updates the delivery to 710 EA picked with picking/WM statuses C.
- **Figure B5.** Goods movement completed on 18 November 2026 for 710 EA, movement type 601.
- **Figure B6.** Saved invoice 90000048 and final document flow confirm billing of 710 EA and completion of delivery 80000082; the linked journal entry remains uncleared.

### 不必作為主要證明的畫面

不必放每一次返回、重複清單、全部橫向捲動欄位或PDF載入失敗。Invoice **Create**（暫時$00000001）不能取代正式 **Display** 發票；Shipment綠勾也不能取代PGI證據。學術上需要解釋的是造成前提未滿足的原因、如何排查、如何修正，以及如何驗證，而不是逐一列出按鍵。
