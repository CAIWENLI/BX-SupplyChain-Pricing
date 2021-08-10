--- MBS Table
SELECT ISBN
	  ,CASE WHEN T.author IS NULL THEN '' ELSE UPPER(T.author) END AS AUTHOR
	  ,UPPER(T.Title) AS TITLE
	  ,CASE WHEN T.publisher IS NULL THEN '' ELSE UPPER(T.publisher) END AS PUBLISHER 
	  ,CASE WHEN T.Binding IS NULL THEN '' 
	        WHEN T.Binding  = 'n/a' THEN '' ELSE UPPER(T.Binding) END AS BINDING 
	  ,CASE WHEN T.ListPrice IS NULL THEN 0 ELSE ROUND(T.ListPrice, 0) END AS LIST_PRICE 
	  ,CASE WHEN T.maxprice IS NULL THEN 0 ELSE ROUND(T.maxprice,0) END AS MAX_PRICE
	  ,T.[Date] AS DATE 
	  ,CASE WHEN T.SpecB IS NULL THEN '' 
	        WHEN T.SpecB = 'N/A' THEN '' ELSE UPPER(T.SpecB) END AS SPECB 
	  ,CASE WHEN T.NewOnly IS NULL THEN '' ELSE UPPER(T.NewOnly) END AS NEW_ONLY
	  ,CASE WHEN T.BXCHNewOTB IS NULL THEN 0 ELSE ROUND(T.BXCHNewOTB, 0) END AS BXC_NEWOTB
	  ,CASE WHEN T.BXCHUsedOTB IS NULL THEN 0 ELSE ROUND(T.BXCHUsedOTB, 0) END AS BXC_USEDOTB
	  ,CASE WHEN T.NewOTB IS NULL THEN 0 ELSE ROUND(T.NewOTB, 0) END AS NEWOTB
	  ,CASE WHEN T.UsedOTB IS NULL THEN 0 ELSE ROUND(T.UsedOTB, 0) END AS USEDOTB 
	  ,T.SuggestedNewPrice AS OFFER_NEWPRICE
	  ,T.SuggestedUsedPrice AS OFFER_USEDPRICE
	  ,CASE WHEN T.Disc IS NULL THEN 0 ELSE T.Disc END AS DISCOUNT
	  ,CASE WHEN T.act IS NULL THEN 0 ELSE T.act END AS ACT
FROM [PROCUREMENTDB].[dbo].[ComboHistoricalCustDemand] T
WHERE T.CustName = 'MBS';

-- Not MBS Table 
SELECT UPPER(T.CustName) AS CUST_NAME 
      ,ISBN
	  ,CASE WHEN T.author IS NULL THEN '' ELSE UPPER(T.author) END AS AUTHOR
	  ,CASE WHEN T.Title IS NULL THEN '' ELSE UPPER(T.Title) END AS TITLE
	  ,CASE WHEN T.publisher IS NULL THEN '' ELSE UPPER(T.publisher) END AS PUBLISHER 
	  ,CASE WHEN T.[Binding] IS NULL THEN '' ELSE UPPER(T.[Binding]) END AS BINDING 
	  ,CASE WHEN T.ListPrice = 0 THEN T.maxprice ELSE ROUND(T.ListPrice, 0) END AS LIST_PRICE 
	  ,T.[Date] AS DATE --- filter out any data without date
	  ,T.Quanitity AS DEMAND_QUANTITY --- Could be the any type of demand quantity combined from other customers(Not NBS) - fill blank/NULL with 0
	  ,T.maxprice AS OFFER_PRICE --- Could be the highest offer price or any offer price from other customers(Not NBS)- fill blank/NULL with 0
FROM [PROCUREMENTDB].[dbo].[ComboHistoricalCustDemand] T;

--- Customer Check
SELECT T.CustName AS CUST_NAME
      ,COUNT(T.ISBN) AS TOTAL_DEMANDS
FROM [PROCUREMENTDB].[dbo].[ComboHistoricalCustDemand] T
GROUP BY T.CustName
