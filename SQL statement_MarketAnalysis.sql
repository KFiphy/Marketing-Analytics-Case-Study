USE Project_2;


-- 1. Products

# check for duplicates and Null
SELECT 
	  productID, COUNT(*) AS product_count
FROM products
GROUP BY productID
HAVING COUNT(*) > 1;    # returning empty records meant no duplicates

SELECT 
	   productID 
FROM product 
WHERE productID IS NULL 
   OR ProductName IS NULL 
   OR Category IS NULL
   OR Price IS NULL; # returning empty records meant no nulls


# Analysis Output
SELECT 
      ProductID, ProductName, Category, Price, 
CASE -- create price category
	WHEN Price < 50 THEN 'Low'
	WHEN Price BETWEEN 50 AND 200 THEN 'Medium'
	ELSE 'High' 
END AS Price_Point
FROM products;



-- 2. Customers

# check for duplicates and Null
SELECT 
       CustomerID, COUNT(*) AS customer_count
FROM customers
GROUP BY CustomerID
HAVING COUNT(*) > 1;    # returning empty records meant no duplicates

SELECT 
       CustomerID 
FROM customers 
WHERE CustomerID IS NULL  # assuming that unique customer identification and email are the most important 
   OR Email IS NULL ; # returning empty records meant no nulls


# Analysis Output to match customers with their location
SELECT 
       c.CustomerID, c.Email, c.Gender, c.Age, g.Country, g.City 
FROM customers AS c 
INNER JOIN geography g  
ON c.GeographyID = g.GeographyID; 



-- 3. rReviews

# check for duplicates and Null
SELECT 
       ReviewID, COUNT(*) AS review_count
FROM reviews
GROUP BY ReviewID
HAVING COUNT(*) > 1;    # returning empty records meant no duplicates

SELECT 
       ReviewID
FROM reviews 
WHERE ReviewID IS NULL 
   OR ReviewDate IS NULL 
   OR ReviewText IS NULL ; # returning empty records meant no nulls

# review date should be changed into date
SET SQL_SAFE_UPDATES = 0; # remove safe mode

UPDATE reviews
SET ReviewDate = CAST(ReviewDate AS DATE);

SET SQL_SAFE_UPDATES = 1; # return safe mode

# Analysis Output
SELECT 
       ReviewID, CustomerID, ProductID, 
       ReviewDate, Rating, ReviewText, CAST(ReviewDate AS DATE) AS DATE
FROM reviews; 

SELECT 
       ReviewID, CustomerID, ProductID, 
       ReviewDate, Rating, ReviewText
FROM reviews;



-- 4. Customer Engagement details


# check for duplicates and Null
SELECT 
       EngagementID, ContentID, COUNT(*) AS engagement_count
FROM customer_engagement
GROUP BY EngagementID, ContentID
HAVING COUNT(*) > 1;    # returning empty records meant no duplicates

SELECT 
       EngagementID
FROM customer_engagement 
WHERE EngagementID IS NULL 
   OR ContentType IS NULL 
   OR CampaignID IS NULL
   OR ContentID IS NULL; # returning empty records meant no nulls

SELECT * FROM customer_engagement;

-- Analysis Output
SELECT 
       EngagementID, ContentID,
	   REPLACE(UPPER(ContentType), 'SOCIALMEDIA', 'SOCIAL MEDIA') AS ContentType, # clean Content type column (inconsistent case and name formatting (space)
       CAST(EngagementDate AS DATE) AS DATE , # engageement date should be changed into date
       Likes, CampaignID, ProductID,
       SUBSTRING_INDEX(ViewsClicksCombined,'-',1) AS Views, # extract Views as number before the delimiter
       SUBSTRING_INDEX(ViewsClicksCombined, '-',-1) AS Clicks # extract clicks as number after the delimiter
FROM customer_engagement;



-- 5. customer_journey

# check for duplicates and Null
SELECT 
       JourneyID, CustomerID, ProductID, 
       VisitDate, Stage, Action, COUNT(*) AS engagement_count
FROM customer_journey
GROUP BY JourneyID, CustomerID, ProductID, 
       VisitDate, Stage, Action
HAVING COUNT(*) > 1;   		 # it returned 28 records which means duplicates exist

SELECT *
FROM customer_journey
WHERE JourneyID IS NULL 
   OR CustomerID IS NULL 
   OR ProductID IS NULL
   OR VisitDate IS NULL
   OR Action IS NULL
   OR Duration IS NULL; 		# the duration field returned nulls
   

SELECT * FROM customer_journey;  # saw some empty duration rows, perhaps spaces

-- Identify and remove duplicates
WITH CTE_rank AS(
SELECT
	  JourneyID, CustomerID, ProductID,
      Stage, Action, CAST(VisitDate AS DATE) AS VisitDate, # visit date should be changed into date
      NULLIF(TRIM(Duration), '') AS Duration,     # empty strings to NULL
      ROW_NUMBER() OVER(
						PARTITION BY JourneyID, CustomerID, ProductID,  # rank for duplicates
						VisitDate, Stage, Action ORDER BY JourneyID) AS row_num
FROM customer_journey),

CTE_filtered AS (
SELECT *
FROM CTE_rank
WHERE row_num < 2), # filter to exclude duplicates

-- fill the null values in the duration field based on records in silimar groups.
CTE_duration AS (
SELECT 
	   JourneyID, CustomerID, ProductID,
       Stage, Action, Duration, VisitDate,
       AVG(Duration) OVER(
						PARTITION BY Stage, VisitDate) AS avg_duration, # duration can be based on different date and what stage was completed that day
       AVG(Duration) OVER() AS overall_avg_duration  -- Compute an overall fallback average
FROM CTE_filtered)

SELECT 
	   JourneyID, CustomerID, ProductID,
	   VisitDate, Stage, Action,
       COALESCE(Duration, avg_duration, overall_avg_duration) AS Duration_fixed
FROM CTE_duration;





-- SELECT user, host FROM mysql.user;