/****** Script for SelectTopNRows command from SSMS  ******/

--- Trade book inventory & wholesale price 
SELECT * FROM
(SELECT tr.Isbn AS ISBN,
       tr.TR_instock AS TR_INVENTORY,
	   ROUND(ISNULL(tr.Landed_Cost,0),2) AS LANDED_COST,
	   ROUND(ISNULL(ww.fifo_cost,0),2) AS FIFO,
	   ROUND(ISNULL(CASE WHEN ww.wholesale_price IS NOT NULL THEN ww.wholesale_price
	                     WHEN ww.wholesale_price IS NULL THEN tr.Landed_Cost*1.15
	                END,0),2) AS WHOLESALE_PRICE,
	   ROW_NUMBER() OVER (PARTITION BY tr.Isbn ORDER BY ww.wholesale_price) AS ROW_NUM
FROM 
	(SELECT t1.ItemCode AS Isbn,
			t1.OnHand AS TR_instock,
			t1.UnitLandedCost AS Landed_Cost
	FROM BookXCenterProduction.SAP.InventoryReportView t1
	WHERE t1.WhsCode IN ('TR') 
	AND t1.OnHand > 0)tr
    LEFT JOIN 
	(SELECT wtr.isbn,
		    wtr.wholesale_price,
			wtr.fifo_cost
    FROM PROCUREMENTDB.Retail.WholeSaleInventoryPriceTR wtr)ww
    ON tr.Isbn= ww.isbn) tt
	WHERE tt.ROW_NUM = 1

--- Trouble book inventory & wholesale price
SELECT * FROM
(SELECT tb.Isbn AS ISBN,
       tb.TB_instock AS TB_INVENTORY,
	   ROUND(ISNULL(tb.Landed_Cost,0),2) AS LANDED_COST,
	   ROUND(ISNULL(CASE WHEN ww.WholesalePricing IS NOT NULL THEN ww.WholesalePricing
	                     WHEN ww.WholesalePricing IS NULL THEN tb.Landed_Cost*1.05
	                END,0),2) AS WHOLESALE_PRICE,
	   ROW_NUMBER() OVER (PARTITION BY tb.Isbn ORDER BY ww.WholesalePricing) AS ROW_NUM
FROM 
	(SELECT t1.ItemCode AS Isbn,
			t1.OnHand AS TB_instock,
			t1.UnitLandedCost AS Landed_Cost
	FROM BookXCenterProduction.SAP.InventoryReportView t1
	WHERE t1.WhsCode IN ('TB','TB-2') 
	AND t1.OnHand > 0)tb
    LEFT JOIN 
	(SELECT wtb.ISBN,
		    wtb.WholesalePricing
    FROM PROCUREMENTDB.Retail.WholeSaleInventoryPriceTB wtb)ww
    ON tb.Isbn= ww.isbn) tb2
	WHERE tb2.ROW_NUM = 1;

--- Textbooks inventory & wholesale price 
SELECT * FROM 
(SELECT i.ISBN,
		i.AW_INVENTORY,
		i.FBA_INVENTORY,
		i.AMZ_LISTING_PRICE,
		ROUND(ISNULL(pp.Land_Cost,0),2) AS LANDED_COST,
		ROUND(ISNULL(ww.FIFO,0),2) AS FIFO,
		ROUND(ISNULL(CASE WHEN ww.WHOLESALE_PRICE IS NOT NULL THEN ww.WHOLESALE_PRICE
							WHEN ww.WHOLESALE_PRICE IS NULL THEN pp.Land_Cost*1.18
					END,0),2) AS WHOLESALE_PRICE,
		ROW_NUMBER() OVER (PARTITION BY i.ISBN ORDER BY ww.WHOLESALE_PRICE) AS ROW_NUM
FROM
	(SELECT CASE WHEN tt1.Isbn IS NOT NULL AND tt2.Isbn IS NOT NULL THEN tt2.Isbn 
					WHEN tt1.Isbn IS NULL THEN tt2.Isbn 
					WHEN tt2.Isbn IS NULL THEN tt1.Isbn
			END AS ISBN,
			ISNULL(tt.Amz_FBA_Inventory,0) AS FBA_INVENTORY,
			ISNULL(tt2.AW_instock,0) AS AW_INVENTORY,
			ISNULL(tt.YourPrice,0) AS AMZ_LISTING_PRICE
	FROM 
			(SELECT t.Sku,
					t.YourPrice,
					t.AfnFulfillableQuantity AS Amz_FBA_Inventory
			FROM BookXCenterProduction.Data.FbaManageInventories t
			WHERE t.AfnTotalQuantity <> 0
			AND  t.Condition = 'New')tt
	LEFT JOIN
			(SELECT  s.sku AS Sku
					,s.isbn AS Isbn
				FROM PROCUREMENTDB.Retail.SkuListCategory s)tt1
	ON tt.Sku = tt1.Sku 
	FULL OUTER JOIN (SELECT t1.ItemCode AS Isbn,
							t1.OnHand AS AW_instock
					 FROM BookXCenterProduction.SAP.InventoryReportView t1
					 WHERE t1.WhsCode IN ('AW') 
					 AND t1.OnHand > 0)tt2
	ON tt2.Isbn = tt1.Isbn)i
	LEFT JOIN (SELECT w.isbn_new AS ISBN
					  ,w.fifo AS FIFO
					  ,w.wholesale_price AS WHOLESALE_PRICE
				FROM PROCUREMENTDB.Retail.WholeSaleInventoryPrice w)ww
	ON i.ISBN = ww.ISBN 
	LEFT JOIN (SELECT p.ItemCode AS Isbn,
					  p.UnitLandedCost AS Land_Cost
				FROM BookXCenterProduction.SAP.InventoryReportView p)pp
	ON i.ISBN = pp.Isbn
	WHERE i.AW_INVENTORY <> 0 OR i.FBA_INVENTORY <> 0)ttt
	WHERE ttt.ROW_NUM = 1;

