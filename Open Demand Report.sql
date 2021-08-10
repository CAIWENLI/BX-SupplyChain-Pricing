SELECT T.ItemCode AS isbn
      ,T.WhsCode AS po_whse
	  ,AVG(T.OnHand) AS on_hand
FROM BookXCenterProduction.SAP.InventoryReportView T
WHERE T.WhsCode IN ('WW', 'AW', 'TB') AND T.OnHand > 0
GROUP BY T.ItemCode
        ,T.WhsCode;

SELECT T1.Isbn
	  ,T1.OpenQuantity AS so_open_qty
	  ,T1.UnitPrice AS sale_price
	  ,T1.WarehouseCode AS so_whse
	  ,T1.DeliveryDate AS customer_drop_date
	  ,T1.DocumentNumber AS so_number
	  ,T1.DocumentName AS so_name
	  ,T1.CustomerOrVendorCode AS customer_code
	  ,T1.CustomerOrVendorName AS customer_name
	  ,T1.CustomerRefNo AS customer_ref_no
	  ,T1.CustomerId AS customer_id 
	  ,T1.Condition AS condition
	  ,T1.DocDate AS so_creation_date
	  ,(CASE WHEN T1.DeliveryDate > GETDATE() THEN 'OnTime' ELSE 'Late' END) AS so_date_status
FROM BookXCenterProduction.SAP.SaleOrderReportView T1
WHERE T1.OpenQuantity > 0 AND T1.WarehouseCode IN ('WW');

SELECT T2.ISBN
	  ,T2.OpenQuantity AS po_open_qty
	  ,CASE WHEN T2.Rate = 1 THEN (T2.GrossPrice*(1-T2.Discount/100) + T2.USDShippingCost) ELSE (T2.GrossPrice*T2.Rate*(1-T2.Discount/100) + T2.USDShippingCost) END AS landed_cost
	  ,T2.Wherehouse AS po_whse
      ,T2.DueAtBXC AS due_at_bxc
      ,T2.DocumentNumber AS po_number
      ,T2.DocumentName AS po_name
      ,T2.BPCode AS supplier_code
      ,T2.BPName AS supplier_name
      ,T2.OrderStatus AS order_status
	  ,T2.DocDate AS po_creation_date
	  ,(CASE WHEN T2.DueAtBXC > GETDATE() THEN 'OnTime'ELSE 'Late'END) AS po_date_status
FROM  BookXCenterProduction.SAP.LinePurchaseOrderView T2
WHERE T2.Wherehouse in ('WW', 'TB') 
	  AND T2.OpenQuantity > 0;

SELECT ISBN AS Isbn
	  ,CASE WHEN T3.x_Rate = 0 THEN (T3.Price + T3.ShippingCost) ELSE (T3.Price*T3.x_Rate + T3.ShippingCost) END AS landed_cost
	  ,T3.WarehouseCode AS po_whse
	  ,T3.PostingDate AS received_date
      ,T3.DocNum AS po_number 
	  ,T3.DocName AS po_name
	  ,T3.BPCode AS supplier_code
	  ,T3.BPName AS supplier
FROM BookXCenterProduction.SAP.GoodsReceiptReportView T3
WHERE T3.WarehouseCode = 'WW'
ORDER BY T3.PostingDate DESC;

SELECT T4.CustomerOrVendorName AS customer_name
      ,T4.CustomerOrVendorCode AS customer_code
	  ,T4.DocumentNumber AS doc_num
	  ,T4.DocumentName AS doc_name
	  ,T4.WarehouseCode AS warehouse_code
	  ,T4.DocDate AS doc_date
	  ,T4.DeliveryDate AS delivery_date
	  ,(CASE
			WHEN (WarehouseCode IN ('TR','TB', 'AWU', 'AW') AND DATEDIFF(day, DocDate, GETDATE()) < 7 ) THEN 'GOOD'
			WHEN (WarehouseCode IN ('TR','TB', 'AWU', 'AW') AND (DATEDIFF(day, DocDate, GETDATE()) >=14) AND (DATEDIFF(week, GETDATE(),DeliveryDate) >=6 )) THEN 'TRANSFER TO WW'
			WHEN (WarehouseCode IN ('TR','TB', 'AWU', 'AW') AND DATEDIFF(day, DocDate, GETDATE()) >=14 ) THEN 'CLOSE'
			WHEN (WarehouseCode IN ('TR','TB', 'AWU', 'AW') AND DATEDIFF(day, DocDate, GETDATE()) >=7 ) THEN 'CHECK'
			WHEN (WarehouseCode IN ('P', '03') AND DATEDIFF(day, DocDate, GETDATE()) <21 ) THEN 'GOOD'
			WHEN (WarehouseCode IN ('P', '03') AND (DATEDIFF(day, DocDate, GETDATE()) >=28) AND (DATEDIFF(week, GETDATE(),DeliveryDate) >=6 )) THEN 'TRANSFER TO WW'
			WHEN (WarehouseCode IN ('P', '03') AND DATEDIFF(day, DocDate, GETDATE()) >=28 ) THEN 'CLOSE'
			WHEN (WarehouseCode IN ('P', '03') AND DATEDIFF(day, DocDate, GETDATE()) >=21 ) THEN 'CHECK'
		END) AS so_decision
FROM BookXCenterProduction.SAP.SaleOrderReportView T4
WHERE  T4.WarehouseCode NOT IN ('05','TB-2','PPE', 'WW') AND T4.DocumentStatus = 'O'
GROUP BY T4.CustomerOrVendorName
        ,T4.CustomerOrVendorCode
	    ,T4.DocumentNumber
		,T4.DocumentName
		,T4.WarehouseCode
		,T4.DocDate
		,T4.DeliveryDate;