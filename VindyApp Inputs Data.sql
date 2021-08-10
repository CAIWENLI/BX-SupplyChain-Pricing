--- File Formatting
--- The body of the call will binary content in the form of a CSV file beginning with a header row defining the following columns: Operation, SKU (optional), ISBN, Quantity, Price, Condition, Comments.
--- Usage note: Operation is a single character; valid options are C (create new), U (update existing), or D (delete). If you use SKUs, ensure they are completely unique. Price is a simple decimal value without a dollar sign ($). Condition can be “Acceptable”, “Good”, “Very Good”, “Like New”, or “New”. Also note that a purge operation can be time consuming for large lists, so don’t abuse it. For deletions, the Quantity, Price, Condition, and Comments columns are ignored.
USE BookXCenterProduction;
GO 
DROP VIEW Inputs.VindyAppInvPrice;
GO

USE BookXCenterProduction;
GO 
CREATE VIEW Inputs.VindyAppInvPrice AS 
SELECT CONVERT(VARCHAR(13), Isbn) AS ISBN
      ,CONVERT(DECIMAL(7,0),SUM(Quantity)) AS Quantity
	  ,CONVERT(DECIMAL(7,2),MAX(CASE WHEN Listing_Price IS NOT NULL THEN Listing_Price*0.7 
	                                 WHEN Listing_Price IS NULL AND BuyBox IS NOT NULL THEN BuyBox*0.6
			                         WHEN Listing_Price IS NULL AND BuyBox IS NULL AND Fifo IS NOT NULL THEN Fifo*1.16 ELSE 25 END)) AS Price
	  ,'New' AS Condition 
	  ,CONVERT(VARCHAR(10), GETDATE(), 101) AS Comments 
FROM
(SELECT I.item_no AS Isbn, SUM(I.instock_inventory) AS Quantity, MAX(I.item_price) AS Fifo FROM PROCUREMENTDB.Retail.InventoryReportView I WHERE I.whse_code IN ('AW', 'TR', 'FBM') GROUP BY I.item_no)II
LEFT JOIN (SELECT LP.Isbn AS Isbn_LP, LP.Price AS Listing_Price FROM BookxcenterProduction.isbn.listprice LP WHERE Currency = 'USD')LL ON II.Isbn = LL.Isbn_LP
LEFT JOIN (SELECT K.Isbn_Keepa, MAX(K.BuyBox_Price) AS BuyBox ,MAX(K.FBA_Fees) AS FBA_Fees FROM PROCUREMENTDB.Retail.KeepaCleanedRawView K GROUP BY K.Isbn_Keepa)KK ON II.Isbn = KK.Isbn_Keepa
GROUP BY Isbn;
GO

SELECT * FROM PROCUREMENTDB.Wholesale.VindyAppInvPrice 
SELECT * FROM BookXCenterProduction.Inputs.VindyAppInvPrice