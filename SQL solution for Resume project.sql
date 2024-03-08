## Adding new column as per the the changes occur after promotion
 ALTER TABLE fact_events
 ADD COLUMN revised_price decimal(10);
UPDATE fact_events
SET revised_price= CASE
WHEN promo_type='BOGOF' THEN base_price*0.5
WHEN promo_type='500 Cashback' THEN base_price-500
WHEN promo_type='33% OFF' THEN base_price*0.67
WHEN promo_type='25% OFF' THEN base_price*0.75
WHEN promo_type='50% OFF' THEN base_price*0.5
ELSE base_price
END;
ALTER TABLE fact_events
ADD COLUMN price_before decimal(10);
UPDATE fact_events
SET price_before= base_price*qty_sold_before;
ALTER TABLE fact_events
ADD COLUMN revenue_after decimal(10);
UPDATE fact_events
SET revenue_after= revised_price*revised_quantity;
ALTER TABLE fact_events
RENAME COLUMN price_before TO revenue_before;


ALTER TABLE fact_events
ADD COLUMN revised_quantity decimal(10);
ALTER TABLE fact_events
RENAME COLUMN `quantity_sold(after_promo)` TO qty_sold_after;

ALTER TABLE fact_events
RENAME COLUMN `quantity_sold(before_promo)` TO qty_sold_before;

UPDATE fact_events
SET revised_quantity= CASE
WHEN promo_type='BOGOF' THEN qty_sold_after*2
ELSE qty_sold_after
END;

## Q.1- Provide the list of product with base_price greater than 500 and promo_type is "BOGOF". These products are the high value products that are currently having heavy discount

SELECT  dp.product_name
FROM dim_products dp
JOIN fact_events fe ON dp.product_code= fe.product_code
WHERE fe.base_price>500 
AND fe.promo_type='BOGOF'
GROUP BY dp.product_name;

## Q.2- Number of stores in each city .
SELECT 
city,COUNT(DISTINCT store_id) AS store_count
FROM dim_stores
GROUP BY city
ORDER BY store_count DESC;

## Q.3 Campaign name and total revenue generated before and after campaign
SELECT dc.campaign_name,CONCAT(CAST(SUM(fe.base_price*fe.qty_sold_before)/1000000 AS DECIMAL(10)),'M') AS total_revenue_before,
CONCAT(CAST(SUM(fe.revised_price*fe.revised_quantity)/1000000 AS DECIMAL(10)),'M') AS total_revenue_after
FROM dim_campaigns dc
JOIN fact_events fe ON dc.campaign_id=fe.campaign_id
GROUP BY dc.campaign_name;

##Q.4 calculate incremental sold unit % for each category during the diwali campaign and rank them accordingly
SELECT dp.category,
ROUND((SUM(fe.revised_quantity-fe.qty_sold_before)/SUM(fe.qty_sold_before)*100),2) AS ISU_Percentage,
RANK() OVER(ORDER BY (SUM(fe.revised_quantity-fe.qty_sold_before)/SUM(fe.qty_sold_before)*100)DESC) AS ISU_rank
FROM dim_products dp
JOIN fact_events fe ON dp.product_code=fe.product_code
JOIN dim_campaigns dc ON fe.campaign_id= dc.campaign_id
WHERE dc.campaign_name='Diwali'
GROUP BY 
dp.category
ORDER BY 
ISU_Percentage DESC;

## Q.5- Calculate incremental revenue percentage across every campaign as per the product name & category
SELECT dp.product_name,dp.category,
ROUND((SUM(fe.revenue_after)-SUM(fe.revenue_before))/SUM(fe.revenue_before)*100,2) AS IR_percentage
FROM dim_products dp
JOIN fact_events fe ON dp.product_code=fe.product_code
GROUP BY
dp.product_name,dp.category
ORDER BY
IR_percentage DESC
LIMIT 5;