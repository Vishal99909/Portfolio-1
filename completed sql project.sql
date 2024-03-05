USE newschema;
SELECT * FROM pricedata;

--- 1How many sales occurred during this time period?

SELECT COUNT(*) AS sales FROM pricedata
WHERE event_date BETWEEN '2018-01-01' AND '2021-12-31';


/*2Return the top 5 most expensive transactions (by USD price) for this data set. 
Return the name, ETH price, and USD price, as well as the date.*/

SELECT name, eth_price,usd_price,event_date AS DATE FROM pricedata
ORDER BY usd_price desc
LIMIT 5;



/* 3Return a table with a row for each transaction with an event column,
 a USD price column, and a moving average of USD price that averages the last 50 transactions.*/
 
 SELECT * FROM pricedata
 SELECT event_date,transaction_hash,usd_price,AVG(usd_price) OVER(ORDER BY transaction_hash DESC ROWS BETWEEN 50 PRECEDING AND CURRENT ROW)FROM pricedata;
 
 --- Return all the NFT names and their average sale price in USD. Sort descending. 
 --- Name the average column as average_price.
SELECT name,AVG(usd_price) AS average_price FROM cryptopunkdata
GROUP BY name
ORDER BY average_price DESC;

/*5 Return each day of the week and the number of sales that occurred on that day of the week, 
as well as the average price in ETH.
 Order by the count of transactions in ascending order.*/
 
 
 SELECT
DAYNAME(event_date) AS day_of_week,
COUNT(*) AS num_sales,
AVG(eth_price) AS average_price_eth
FROM pricedata
GROUP BY day_of_week
ORDER BY num_sales ASC;

/*6Construct a column that describes each sale and is called summary. The sentence should include who sold the NFT name,
 who bought the NFT, who sold the NFT, the date, and what price it was sold for in USD rounded to the nearest thousandth.*/
 
 SELECT CONCAT(name,'  ', 'WAS SOLD FOR $', usd_price,' ','to',' ',
 buyer_address, '  ','from','  ',seller_address,'  ', 'ON','  ', event_date)
 ,ROUND(usd_price,-3) AS SOLD_PRICE FROM pricedata;
 
 
 /*7Create a view called “1919_purchases”
 and contains any sales where “0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685” was the buyer.
 */
 CREATE VIEW 1919_purchases AS
 SELECT * FROM pricedata
 WHERE seller_address like "%0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685%";
 
 SELECT * FROM  1919_purchases;
 
 /*8Create a histogram of ETH price ranges. Round to the nearest hundred value. */
 
SELECT
ROUND(eth_price, -2) AS price_range,
COUNT(*) AS frequency,
RPAD('', COUNT(*), '*') AS bar
FROM pricedata
GROUP BY price_range
ORDER BY price_range;

/*9.Return a unioned query that contains the highest price each NFT was bought for and a new
column called status saying “highest” with a query that has the lowest price each NFT was
bought for and the status column saying “lowest”. The table should have a name column, a price
column called price, and a status column. Order the result set by the name of the NFT, and the
status, in ascending orde */

SELECT name, MAX(usd_price) AS price, 'highest' AS status
FROM pricedata
GROUP BY name
UNION
SELECT name, MIN(usd_price) AS price, 'lowest' AS status
FROM pricedata
GROUP BY name
ORDER BY name, status;

/*10.What NFT sold the most each month / year combination? Also, what was the name and the
price in USD? Order in chronological format.*/
SELECT
name,
CONCAT(MONTH(event_date), '/', YEAR(event_date)) AS date,
MAX(usd_price) AS price,
COUNT(*) AS sales_count
FROM pricedata
GROUP BY name, date
ORDER BY date, sales_count DESC;


/* 11.Return the total volume (sum of all sales), round to the nearest hundred on a monthly basis
(month/year).*/
SELECT
CONCAT(MONTH(event_date), '/', YEAR(event_date)) AS month_year,
ROUND(SUM(usd_price), -2) AS total_volume
FROM pricedata
GROUP BY month_year
ORDER BY month_year;

/*12.Count how many transactions the wallet "0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685"
had over this time period.*/
SELECT
SUM(CASE WHEN buyer_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685' THEN
1 ELSE 0 END) AS buyer_transaction_count,
SUM(CASE WHEN seller_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685' THEN
1 ELSE 0 END) AS seller_transaction_count,
SUM(CASE WHEN buyer_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685' OR
seller_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685' THEN 1 ELSE 0 END) AS
total_count
FROM pricedata
WHERE buyer_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685'
OR seller_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685';



/*13Create an “estimated average value calculator” that has a representative price of the 
collection every day based off of these criteria:
 - Exclude all d aily outlier sales where the purchase price is below 10% of the daily average price
 - Take the daily average of remaining transactions
 a) First create a query that will be used as a subquery. Select the event date, the USD price, and 
 the average USD price for each day using a window function. Save it as a temporary table.
 b) Use the table you created in Part A to filter out rows where the USD prices is below 10% of
 the daily average and return a new estimated value which is just the daily average of the filtered data  */
 
 SELECT usd_price , event_date FROM 
(SELECT usd_price , event_date, AVG (usd_price)  OVER ( partition by event_date) As DL FROM pricedata)
temp2 WHERE usd_price < 0.10 * DL;
 
/*14.Give a complete list ordered by wallet profitability (whether people have made or lost money) */
 
SELECT
COALESCE(buyer_address, seller_address) AS wallet_address,
SUM(CASE WHEN buyer_address IS NOT NULL THEN usd_price ELSE 0 END) AS
total_purchases,
SUM(CASE WHEN seller_address IS NOT NULL THEN usd_price ELSE 0 END) AS
total_sales,
SUM(CASE WHEN seller_address IS NOT NULL THEN usd_price ELSE 0 END) -
SUM(CASE WHEN buyer_address IS NOT NULL THEN usd_price ELSE 0 END) AS
profitability
FROM pricedata
GROUP BY COALESCE(buyer_address, seller_address)
ORDER BY profitability DESC; 
 
 