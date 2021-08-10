--- Total Orders 
USE PROCUREMENTDB
GO
DROP VIEW Warehouse.TotalOrders;
GO
USE PROCUREMENTDB
GO
CREATE VIEW Warehouse.TotalOrders AS 
SELECT O.WarehouseCode AS whse_code 
      ,SUM(O.DeliveredQty) AS delivered_qty
      ,CONVERT(VARCHAR(10), O.DeliveryDate, 101) AS delivery_date
	  ,DATEPART(WK, O.DeliveryDate) AS week_num
	  ,DATEPART(YEAR, O.DeliveryDate) AS year_num
  FROM [BookXCenterProduction].[SAP].[SaleOrderReportView] O
  WHERE O.DeliveredQty <> 0 AND O.WarehouseCode <> 'PPE' AND O.Isbn LIKE '978%' 
  GROUP BY O.WarehouseCode
          ,O.DeliveryDate; 
GO
--- Total Received 
USE PROCUREMENTDB
GO
DROP VIEW Warehouse.TotalReceived;
GO
CREATE VIEW Warehouse.TotalReceived AS 
SELECT CONVERT(VARCHAR(10), GR.PostingDate, 101)  AS posting_date
      ,GR.WarehouseCode AS whse_code 
	  ,ROUND(SUM(GR.Quantity),2) AS total_qty
FROM [BookXCenterProduction].[SAP].[GoodsReceiptReportView] GR
WHERE GR.WarehouseCode <> 'PPE'
AND GR.ISBN LIKE '978%' 
GROUP BY GR.PostingDate
        ,GR.WarehouseCode;
GO

SELECT * FROM [BookXCenterProduction].[SAP].[GoodsReceiptReportView]
SELECT * FROM [BookXCenterProduction].[SAP].[SaleOrderReportView] 