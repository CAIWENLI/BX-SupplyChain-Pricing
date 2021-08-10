
SELECT * FROM PROCUREMENTDB.Wholesale.WholesalePriceView

------ Please read the notes below:------
-- FBA_AW is the textbooks at Amazon warehouse 
-- FBA_TR is the trade books at Amazon warehouse 

-- Amazon inventory is refreshed hourly (Only fulfillable inventory is included)
-- SAP inventory is live data
-- Buybox information is refrehsed daily (Still in testing period, but the loaded data is accurate, any missing data you will need to get from Keepa as needed) 
-- Listing price is live data 

USE PROCUREMENTDB;
GO 
DROP VIEW Wholesale.WholesalePriceView;
GO

USE PROCUREMENTDB;
GO 
CREATE VIEW Wholesale.WholesalePriceView AS 
SELECT *
      ,CASE WHEN V1.WP_1 >= V1.WP_2 THEN V1.WP_1 ELSE V1.WP_2 END AS WP_MAX
	  ,CASE WHEN V1.WP_1 < V1.WP_2 THEN V1.WP_1 ELSE V1.WP_2 END AS WP_MIN
	  ,CASE WHEN V1.Amz_Listing_Price <> 0 AND V1.WP_1 >= V1.WP_2 AND V1.WP_1 >= V1.Amz_Listing_Price*0.9 THEN V1.Amz_Listing_Price*0.9
	        WHEN V1.Amz_Listing_Price <> 0 AND V1.WP_1 < V1.WP_2 AND V1.WP_2 >= V1.Amz_Listing_Price*0.9 THEN  V1.Amz_Listing_Price*0.9 
			WHEN V1.WP_1 >= V1.WP_2 THEN V1.WP_1 ELSE V1.WP_2 END AS WP_F
	  ,CASE WHEN V1.Amz_Listing_Price <> 0 AND V1.WP_1 >= V1.WP_2 AND V1.WP_1 >= V1.Amz_Listing_Price*0.9 THEN 'RED FLAG' 
	        WHEN V1.Amz_Listing_Price <> 0 AND V1.WP_1 < V1.WP_2 AND V1.WP_2 >= V1.Amz_Listing_Price*0.9 THEN 'RED FLAG' ELSE 'GREEN FLAG' END AS Amz_Listing_Flag
FROM 
(SELECT FINAL.*
      ,CONVERT(DECIMAL(7,2),CASE WHEN FINAL.ROI <> 0 AND FINAL.FIFO <> 0 AND FINAL.Warehouse IN ('FBA_AW', 'FBA_TR') THEN (1+FINAL.ROI)*FINAL.FIFO + 4
			                     WHEN FINAL.ROI <> 0 AND FINAL.FIFO <> 0 AND FINAL.Warehouse IN ('AW', 'TR', 'FBM', 'WSPEC') THEN (1+FINAL.ROI)*FINAL.FIFO
								 WHEN FINAL.ROI <> 0 AND FINAL.FIFO = 0  AND FINAL.Landed_Cost <> 0 AND FINAL.Warehouse IN ('FBA_AW', 'FBA_TR') THEN (1+FINAL.ROI)*FINAL.Landed_Cost + 4
								 WHEN FINAL.ROI <> 0 AND FINAL.FIFO = 0  AND FINAL.Landed_Cost <> 0 AND FINAL.Warehouse IN ('AW', 'TR', 'FBM', 'WSPEC') THEN (1+FINAL.ROI)*FINAL.Landed_Cost
								 WHEN FINAL.FIFO <> 0 AND FINAL.Warehouse IN ('FBA_AW', 'FBA_TR') THEN 1.18*FINAL.FIFO + 4
			                     WHEN FINAL.FIFO <> 0 AND FINAL.Warehouse IN ('AW', 'TR', 'FBM', 'WSPEC') THEN 1.18*FINAL.FIFO
								 WHEN FINAL.FIFO = 0  AND FINAL.Landed_Cost <> 0 AND FINAL.Warehouse IN ('FBA_AW', 'FBA_TR') THEN 1.18*FINAL.Landed_Cost + 4
								 WHEN FINAL.FIFO = 0  AND FINAL.Landed_Cost <> 0 AND FINAL.Warehouse IN ('AW', 'TR', 'FBM', 'WSPEC') THEN 1.18*FINAL.Landed_Cost
								 WHEN FINAL.Used_Price <> 0 AND FINAL.Warehouse IN ('TB-2', 'AWU') THEN FINAL.Used_Price*0.5 
	                             WHEN FINAL.Used_Price = 0 AND FINAL.Warehouse IN ('TB-2', 'AWU') THEN 7 
								 WHEN FINAL.FIFO = 0 AND FINAL.BuyBox_Price <> 0 THEN 0.6*FINAL.BuyBox_Price
								 WHEN FINAL.ROI = 0 AND FINAL.BuyBox_Price <> 0 THEN 0.6*FINAL.BuyBox_Price
								 WHEN FINAL.FIFO = 0 AND FINAL.BuyBox_Price = 0 AND FINAL.Landed_Cost = 0 AND FINAL.Warehouse IN ('TR', 'FBA_TR') THEN 10 ELSE 25 END) AS WP_1
	  ,CONVERT(DECIMAL(7,2),CASE WHEN FINAL.Listing_Price <> 0 AND FINAL.Warehouse IN ('AW', 'TR', 'FBM', 'FBA_AW', 'FBA_TR') THEN FINAL.Listing_Price*0.7 
	                             WHEN FINAL.Listing_Price <> 0 AND FINAL.Warehouse IN ('WSPEC') THEN FINAL.Listing_Price*0.6
								 WHEN FINAL.Used_Price <> 0 AND FINAL.Warehouse IN ('TB-2', 'AWU') THEN FINAL.Used_Price*0.5 
	                             WHEN FINAL.Used_Price = 0 AND FINAL.Warehouse IN ('TB-2', 'AWU') THEN 7 
	                             WHEN FINAL.Listing_Price = 0  AND FINAL.Warehouse IN ('TR', 'FBA_TR') THEN 10 ELSE 25 END) AS WP_2
	                          
FROM
(SELECT TT.Isbn
      ,TT.Inventory
	  ,TT.Warehouse
	  ,CONVERT(DECIMAL(7,2),CASE WHEN LL.Listing_Price IS NULL THEN 0 ELSE LL.Listing_Price END) AS Listing_Price
	  ,CONVERT(DECIMAL(7,2),CASE WHEN PP.Amz_Listing_Price IS NULL THEN 0 ELSE PP.Amz_Listing_Price END) AS Amz_Listing_Price 
	  ,CONVERT(DECIMAL(7,2),CASE WHEN KK.BuyBox_Price IS NULL THEN 0 ELSE KK.BuyBox_Price END) AS BuyBox_Price
	  ,CONVERT(DECIMAL(7,2),CASE WHEN KK.Used_Price IS NULL THEN 0 ELSE KK.Used_Price END) AS Used_Price
	  ,CASE WHEN KK.SaleRank_Current IS NULL THEN 0 ELSE KK.SaleRank_Current END AS SaleRank_Current 
	  ,CONVERT(DECIMAL(7,2),CASE WHEN FF.FIFO IS NULL THEN 0 ELSE FF.FIFO END) AS FIFO
	  ,CONVERT(DECIMAL(7,2),CASE WHEN CC.Landed_Cost IS NULL THEN 0 ELSE CC.Landed_Cost END) AS Landed_Cost
	  ,CONVERT(DECIMAL(7,2),CASE WHEN ROI.QTY IS NULL THEN 0 ELSE ROI.QTY END) AS Total_Qty_Sold_LMth
	  ,CONVERT(DECIMAL(7,2),CASE WHEN ROI.TOTAL_SALE IS NULL THEN 0 ELSE ROI.TOTAL_SALE END) AS Total_Sale_USD_LMth
	  ,CONVERT(DECIMAL(7,2),CASE WHEN ROI.ROI IS NULL THEN 0 WHEN ROI.ROI <= 0 THEN 0 ELSE ROI END) AS ROI
FROM (SELECT item_no AS Isbn, SUM(instock_inventory) AS Inventory, whse_code AS Warehouse FROM PROCUREMENTDB.Retail.InventoryReportView WHERE whse_code NOT IN ('PPE') GROUP BY item_no, whse_code)TT
LEFT JOIN (SELECT LP.Isbn AS Isbn_LP, LP.Price AS Listing_Price FROM BookxcenterProduction.isbn.listprice LP WHERE Currency = 'USD')LL ON TT.Isbn = LL.Isbn_LP
LEFT JOIN (SELECT ISBN, FIFO FROM PROCUREMENTDB.Retail.FIFO)FF ON TT.Isbn = FF.ISBN
LEFT JOIN (SELECT LC.ItemCode AS Isbn_LC, MAX(LC.UnitLandedCost) AS Landed_Cost FROM BookXCenterProduction.sap.InventoryReportView LC GROUP BY LC.ItemCode)CC ON TT.Isbn = CC.Isbn_LC
LEFT JOIN (SELECT Isbn, Warehouse, MAX(Price) AS Amz_Listing_Price FROM PROCUREMENTDB.Retail.SkuWarehousePriceView GROUP BY Isbn, Warehouse)PP ON CONCAT(TT.Isbn, TT.Warehouse) = CONCAT(PP.Isbn, PP.Warehouse)
LEFT JOIN (SELECT Isbn_Keepa, MAX(BuyBox_Price) AS BuyBox_Price, MAX(Used_Price) AS Used_Price, MIN(SaleRank_Current) AS SaleRank_Current FROM PROCUREMENTDB.Retail.KeepaCleanedRawView GROUP BY Isbn_Keepa)KK ON TT.Isbn = KK.Isbn_Keepa
LEFT JOIN (SELECT * FROM PROCUREMENTDB.Retail.LmthROIAmzView)ROI ON TT.Isbn = ROI.ISBN)FINAL)V1;
GO
