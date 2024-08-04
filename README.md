# Supply Chain Shipment Pricing Analysis

## Introduction
This project analyzes a supply chain shipment pricing dataset from Data.gov, focusing on shipment volumes, costs, performance across different modes and management teams, profitability, and geographic analysis.

## Background
Driven to discover more about the world of Supply Chain, I've downloaded from Data.gov this csv file, "Supply Chain shipment pricing dataset" from [Data.gov](https://catalog.data.gov/dataset/supply-chain-shipment-pricing-data-07d29)
The questions I wanted to answer and the points I wanted to discover were:
 1. Overview of shipment volumes and costs.
 2. Shipping performances across different modes and management teams.
 3. How do different shipment modes and management teams compare in terms of cost and profitability?
 4. How the profitability changes over time. Are there seasonal patterns or trends?
 5. Geographic analysis: How does profitability vary by destination?
 6. Performances of the manufacturing countries.
 7. Most profitable combination between manufacturing site and country of destination.
 8. Product-specific analysis: Are there certain types of products that are more profitable to ship?

## Tools Used
For my deep dive into the Supply Chain world I've used as:
- Power Query for initial data cleaning, like adjusting some data types, and removing some columns.
- Microsoft SQL Server for in-depth data cleaning and analysis

## Cleaning data
I've started by cleaning data in Power Query, adjusting some data types, removing some columns, and looking for duplicates.
Then I loaded the CSV file into Microsoft SQL Server and kept going with the cleaning part. Once the data was loaded, before starting to clean the data, 
I created a new table, with the same data of the initial table, so that I would have a backup if anything happened.
```sql
SELECT *
INTO supply_chain_backup
FROM supply_chain_n
WHERE 1 = 0;
```
Then I copied the initial table, into the new one.
```sql
INSERT INTO supply_chain_backup
SELECT * FROM supply_chain_n;
```
Then I started Removing duplicates, I already done that in Power Query before, but I wanted to be sure that everything was okay. To do that I've used a CTE.
```sql
WITH duplicate_cte AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id, country, managed_by, shipment_mode, scheduled_delivery_date, delivered_to_client_date, delivery_recorded_date, product_group, sub_classification, vendor, brand, unit_of_measure_per_pack, line_item_quantity, line_item_value, pack_price, unit_price, manifacturing_site_country, weight_kg, freight_cost_usd, line_item_insurance_usd
			ORDER BY id
        ) AS row_num
    FROM supply_chain_n
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
Each query for this project aimed to investigate specific aspects of the supply chain shipment pricing dataset.
```
In the freight_cost_usd column, I identified values that were not valid numerical entries but instead pointed to external documents that we do 
not possess. To clean the data and ensure the integrity of subsequent calculations, I updated these entries to NULL.
```sql
SELECT freight_cost_usd
FROM supply_chain_n
WHERE freight_cost_usd LIKE 'See%';
```
```sql
UPDATE supply_chain_n
SET freight_cost_usd = null
WHERE freight_cost_usd LIKE 'See%';
```
I did the same for the weight_kg column. 
```sql
SELECT weight_kg
FROM supply_chain_n
WHERE weight_kg LIKE 'See%';
```
```sql
UPDATE supply_chain_n
SET weight_kg = null
WHERE weight_kg LIKE 'See%';
```
I then that scheduled_delivery_date had a DateTime type, and I wanted to change it into date type
```sql
ALTER TABLE supply_chain_n
ADD scheduled_delivery_date_new DATE;

UPDATE supply_chain_n
SET scheduled_delivery_date_new = CAST(scheduled_delivery_date AS DATE);

ALTER TABLE supply_chain_n
DROP COLUMN scheduled_delivery_date;
EXEC sp_rename 'supply_chain_n.scheduled_delivery_date_new', 'scheduled_delivery_date', 'COLUMN';
```
I then did the same for delivered_to_client_date
```sql

ALTER TABLE supply_chain_n
ADD delivered_to_client_date_new DATE;

UPDATE supply_chain_n
SET delivered_to_client_date_new = CAST( delivered_to_client_date AS DATE);

ALTER TABLE supply_chain_n
DROP COLUMN delivered_to_client_date;

EXEC sp_rename 'supply_chain_n.delivered_to_client_date_new', 'delivered_to_client_date', 'COLUMN';
```
I did the same with delivery_recorded_date
```sql
ALTER TABLE supply_chain_n
ADD delivery_recorded_date_new DATE;

UPDATE supply_chain_n
SET delivery_recorded_date_new = CAST(delivery_recorded_date AS DATE);

ALTER TABLE supply_chain_n
DROP COLUMN delivery_recorded_date;

EXEC sp_rename 'supply_chain_n.delivery_recorded_date_new', 'delivery_recorded_date', 'COLUMN';
```
Found out the line_item_quantity has the wrong data type, varchar instead of int, so I'm changed it
```sql
ALTER TABLE supply_chain_n
ADD line_item_quantity_int INT;

UPDATE supply_chain_n
SET line_item_quantity_int = CAST(line_item_quantity AS INT);

ALTER TABLE supply_chain_n
DROP COLUMN line_item_quantity;

EXEC sp_rename 'supply_chain_n.line_item_quantity_int', 'line_item_quantity', 'COLUMN';
```
Same thing happened for freight_cost_ USD. So I added a new column with DECIMAL type
```sql
ALTER TABLE supply_chain_n
ADD freight_cost_usd_decimal DECIMAL(18, 2);

UPDATE supply_chain_n
SET freight_cost_usd_decimal = TRY_CAST(freight_cost_usd AS DECIMAL(18, 2));

ALTER TABLE supply_chain_n
DROP COLUMN freight_cost_usd;

EXEC sp_rename 'supply_chain_n.freight_cost_usd_decimal', 'freight_cost_usd', 'COLUMN';
```
I've noticed that line_item_value's data type, int, had numbers larger than the maximum value that it can handle, so I've changed the data type. I've altered the column type to BIGINT.

```sql
ALTER TABLE supply_chain_n
ALTER COLUMN line_item_value BIGINT;
```
Doing some cleaning I found a row in the dosage_form that said oral powder instead of powder for oral solution, so I put all of them in the same column.
```sql
UPDATE supply_chain_n
SET dosage_form = 'Powder for oral solution'
WHERE dosage_form = 'Oral powder';
```
Found some rows where it wasn't indicating a country, so I changed them to null.
```sql
UPDATE supply_chain_n
SET manifacturing_site_country = null
WHERE manifacturing_site_country IN ('L.C.', 'Inc', 'Ltd.', 'Plc');
```

Found rows where it was written 'Weight Captured Separately' so I changed that to null.
```sql
UPDATE supply_chain_n
SET weight_kg = null
WHERE weight_kg = 'Weight Captured Separately';
```
With queries like this I checked if the data was Standardized and Spelling mistakes.
```sql
SELECT DISTINCT(dosage_form)
FROM supply_chain_n;
```
Once I was happy with the result, I was ready to start the analysis.
## The EDA
1. As the first thing, I looked for an "Overview of shipment volumes and costs." In order to do that, I've written the following query:
```sql
SELECT
	COUNT(*) AS total_shipments,
	SUM(line_item_quantity) AS total_quantity,
	ROUND(AVG(unit_price),2) AS avg_unit_price,
	ROUND(SUM(line_item_value),2) AS total_value,
	ROUND(AVG(freight_cost_usd),2) AS avg_freight_cost
FROM supply_chain_n;
```
assets/overview of shipments and costs.png
The total number of shipments is 10,324, the total quantity is 189,265,090, the average unit price is $29, the total value is $56,112,867,105, the average freight cost is $11103.23.

2. Then I looked for: "Shipping performances across different modes and management teams."
```sql
SELECT
	COUNT(*) AS num_of_shipments,
	shipment_mode,
	managed_by,
	SUM(DATEDIFF(DAY, scheduled_delivery_date, delivered_to_client_date)) AS tot_delay_scheduled_to_delivery,
	ROUND(AVG(DATEDIFF(DAY, scheduled_delivery_date, delivered_to_client_date)),2) AS avg_delay_to_delivery,
	SUM(DATEDIFF(DAY, delivery_recorded_date, delivered_to_client_date)) AS tot_delay_delivered_to_recorded,
	ROUND(AVG(DATEDIFF(DAY, delivery_recorded_date, delivered_to_client_date)),2) AS avg_delay_to_record
FROM supply_chain_n
GROUP BY shipment_mode, managed_by
ORDER BY num_of_shipments DESC;
```
I've calculated the number of shipments for each combination of shipment mode and management team, 
the total and average delay between the scheduled and actual delivery date, the total and average between delivery and recording dates 
and I've ordered the results by the number of shipments, showing the most frequent combination first.
This query answers several important questions: - The shipment mode most commonly used is "Air". 
- The management team that handles the most shipments is PMO-US. -PMO-US can deliver with the different shipment modes always
earlier than the scheduled delivery date, with the exception of the Ocean shipment mode. - There isn't a big gap between when items are delivered
and when they're recorded as delivered, with a maximum of 4.4 average delays to record. 
We cannot do a comparison between the different managements because PMO-US alone manages 99% of the shipments. 
The combination of shipment mode and management team that stands out as more efficient is Air Charte by PMO-US, with an average delay to deliver of -19
days, meaning 19 days in advance of the delivery date.
3. Then I answered the question: "How do different shipment modes and management teams compare in terms of cost and profitability?"
```sql
WITH Median AS (
    SELECT 
        shipment_mode,
        managed_by,
        freight_cost_usd,
        line_item_insurance_usd,
        line_item_value,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY freight_cost_usd) OVER (PARTITION BY shipment_mode, managed_by) AS median_freight_cost,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY line_item_insurance_usd) OVER (PARTITION BY shipment_mode, managed_by) AS median_insurance_cost,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY line_item_value) OVER (PARTITION BY shipment_mode, managed_by) AS median_line_item_value
    FROM supply_chain_n
)
SELECT 
    COUNT(*) AS shipment_count, 
    shipment_mode,
    managed_by,
    AVG(freight_cost_usd) AS avg_freight_cost,
    AVG(line_item_insurance_usd) AS avg_insurance_cost,
	AVG(freight_cost_usd) + AVG(line_item_insurance_usd) AS avg_total_cost,
    AVG(line_item_value) AS avg_line_item_value,
    AVG(line_item_value) - (AVG(freight_cost_usd) + AVG(line_item_insurance_usd)) AS avg_profit,
    ROUND(
        (
            (AVG(line_item_value) - (AVG(freight_cost_usd) + AVG(line_item_insurance_usd)))
            / NULLIF(AVG(line_item_value), 0)
        ) * 100, 2
    ) AS avg_profit_margin_percentage,
    MAX(median_freight_cost) AS median_freight_cost,
    MAX(median_insurance_cost) AS median_insurance_cost,
    MAX(median_line_item_value) AS median_line_item_value,
    MAX(median_line_item_value) - (MAX(median_freight_cost) + MAX(median_insurance_cost)) AS median_profit,
    ROUND(
        (
            (MAX(median_line_item_value) - (MAX(median_freight_cost) + MAX(median_insurance_cost)))
            / NULLIF(MAX(median_line_item_value), 0)
        ) * 100, 2
    ) AS median_profit_margin_percentage
FROM Median
GROUP BY shipment_mode, managed_by
ORDER BY avg_profit DESC;
```
This query gives an overview of the profitability of different shipment modes and management teams. The shipment mode with the highest avg_freight_cost
and with the highest avg_total_cost, is Air Charter managed by PMO-US, which is also the one with the highest avg_line_item_value and the one with the 
highest avg_profit and the one with the highest avg_profit_margin_percentage.
I've also calculated the median to see if things changed because of outliers, and we can see that Air Charter still has the most expenses, 
while the Ocean mode has the highest median line_item_value, the highest median_profit, and the highest median_profit_margin_percentage.

4. Then I answered the question: "How the profitability changes over time. Are there seasonal patterns or trends?"
```sql
WITH shipments_data AS
(
	SELECT
		COUNT(*) AS shipment_count,
		YEAR(delivered_to_client_date) AS year,
		MONTH(delivered_to_client_date) AS month,
		shipment_mode,
		managed_by,
		AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)) AS avg_profit,
		ROUND(((AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)))/NULLIF(AVG(line_item_value),0))*100,2) AS avg_profit_margin_percentage
	FROM supply_chain_n
	GROUP BY YEAR(delivered_to_client_date),MONTH(delivered_to_client_date) , shipment_mode, managed_by
	HAVING AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)) > 0
)
SELECT 
	*,
	AVG(avg_profit) OVER(
		PARTITION BY shipment_mode, managed_by
		ORDER BY year, month
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) three_month_moving_avg,
	RANK () OVER(
		PARTITION BY year, month
		ORDER BY avg_profit DESC) AS profit_rank_within_month,
	SUM(avg_profit) OVER(
		PARTITION BY year, shipment_mode, managed_by
		ORDER BY month) AS cumulative_yearly_profit,
	avg_profit- AVG(avg_profit) OVER (
	 PARTITION BY shipment_mode, managed_by) AS diff_from_overall_avg
FROM shipments_data
ORDER BY year, month, shipment_mode,managed_by;
```
I've created a CTE and used it to work with different Windows functions, - I've calculated the three-month moving average, 
for example for the Truck shipment mode managed by PMO-US, for the year 2014, -> Insights: the moving average shows big values range, 
from about 5,6 million to 18 million. There's a clear peak in the middle of the series. The series ends higher than it stars. There are significant 
changes between consecutive periods, indicating volatility. The largest increase between the 4th and 5th values. The largest decrease between the 7th and 8th values. 
Despite fluctuations, there's a general upward trend from the beginning to the end of the series. -I've calculated the cumulative_yearly_profit, 
which displays the cumulative profitability over the year, providing a sense of how profitability builds up over time. Taking as an example the year 2008,
for Air shipment_mode managed by PMO-US, we can see that there is a significant drop from the first to the second value, but from the second value onward, 
the trend is upward. The growth rate seems to slow down towards the end of the series. -I've also calculated the difference fro the overall average, this
highlights the deviations from the overall average profitability, pinpointing months that perform better or worse than average, while all the other
months have less profitability than the overall average.
5. Then I answered the question: "Geographic analysis: How does profitability vary by destination?"
```sql

SELECT
	COUNT(*) AS num_shipment,
	country,
	ROUND(AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)),2) AS avg_profit
FROM supply_chain_n
GROUP BY country
HAVING COUNT(*) >= 100
ORDER BY avg_profit ASC;
```
This shows the countries that performed the worst, with low profits. In this case also I've considered countries with at least 100 shippings.
The least profitable country is South Sudan, with an average profit of only $182613.78.

```sql
SELECT
	COUNT(*) AS num_shipment,
	country, 
	ROUND(AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)),2) AS avg_profit
FROM supply_chain_n
GROUP BY country
HAVING COUNT(*) >= 100
ORDER BY avg_profit DESC;
```
This is an overview of how profitability varies by destination country. I've considered countries with at least 100 shipping which is around 1% 
of the total shipping. I found that the top 3 profitable countries are Zambia with $ 9996597.13, Mozambique with $ 10675219.01, Nigeria being the 
most profitable with $ 10914602.89.

6. Then I looked for the "Performances of the manufacturing countries."
```sql
SELECT
	COUNT(*) AS num_shipments,
	manifacturing_site_country,
	ROUND(AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)),2) AS avg_profit
FROM supply_chain_n
GROUP BY manifacturing_site_country
HAVING COUNT(*) > 100
ORDER BY avg_profit DESC;
```
This query gives the countries with the manufacturing sites, the average profit, and the number of shipments for each manufacturing country. 
I've ordered the query by the avg_profit so that it would show the most profitable manufacturing site country in descending order. India (IN)
is the country where the manufacturing sites have the highest average profit and the highest number of shipments. 
```sql
SELECT
	COUNT(*) AS num_shipments,
	manifacturing_site_country,
	ROUND(AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)),2) AS avg_profit
FROM supply_chain_n
GROUP BY manifacturing_site_country
HAVING COUNT(*) > 100
ORDER BY avg_profit;
```
By just removing the DESC at the end of the previous query we can find out what the least profitable countries: South Korea (KR) is the least
profitable.
7. Then I looked for the "Most profitable combination between manufacturing site and country of destination."
```sql
SELECT 
	COUNT(*) AS num_shipment,
	manifacturing_site_country,
	country,
	ROUND(AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)),2) AS avg_profit
FROM supply_chain_n
GROUP BY manifacturing_site_country, country
HAVING COUNT(*) >= 100
ORDER BY avg_profit DESC;
```
I've then added the country to the previous query to look at the most profitable combination between the manufacturing site and the country of destination.
The most profitable combination with at least 100 shipments, has the manufacturing site in India (IN), and the country of destination in Mozambique. 
```sql
SELECT 
	COUNT(*) AS num_shipment,
	manifacturing_site_country,
	country,
	ROUND(AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)),2) AS avg_profit
FROM supply_chain_n
WHERE manifacturing_site_country IS NOT NULL
GROUP BY manifacturing_site_country, country
HAVING COUNT(*) >= 100
ORDER BY avg_profit;
```
By just removing the DESC from the previous query we can see how the least profitable combination having India (IN) as the manufacturing site country
and Guyana as the country of destination.
8. And in the end I answered the question: "Product-specific analysis: Are there certain types of products more profitable to ship?"
```sql
WITH product_metrics AS
(
	SELECT
		product_group,
		sub_classification,
		COUNT(*) AS num_shipment,
		ROUND(AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)),2) AS avg_profit,
		ROUND((AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)))/ COUNT(*),2) AS avg_profit_per_shipment
	FROM supply_chain_n
	GROUP BY product_group, sub_classification
)
SELECT
	*,
	CASE
		WHEN num_shipment >= 1000 AND avg_profit >= 20000 THEN 'High Volume, High Profit'
		WHEN num_shipment >= 1000 AND avg_profit BETWEEN 4000 AND 20000 THEN 'High Volume, Low Profit'
		WHEN num_shipment < 1000 AND avg_profit >= 20000 THEN 'Low Volume, High Profit'
		ELSE 'Low Volume, Low Profit'
		END AS volume_profit_category
	FROM product_metrics
	ORDER BY num_shipment DESC, avg_profit DESC;
 ```
The product type that is the most profitable to ship is the ARV product group, if we want to look at the most profitable combination 
between product group and subclassification, the ARV product group with "Adult" as the subclassification is the most profitable combination. I've also
calculated the average profit per shipment, with the ANTM product group in combination with the subclassification Malaria, as the one that has the highest
average profit per shipment. To take into consideration the low number of shipments in this case. Then I've also compared the volume with the
profitability, comparing num_shipmentwith avg_profit. In this case, it shows how High Volume always goes with High Profit, but we cannot say the opposite.
High Profit doesn't always go with High Volume. From this query, we can also see how there is a combination between product group and subclassification
that is a loss, HRDT, HIV test- Ancillary.
## Key Findings

1. Shipment Overview:
   - Total shipments: 10,324
   - Total Quantity: 189,265,090
   - Average unit price: $29
   - Total value: $56,112,867,105
   - Average freight cost: $11,103.23

2. Shipping Performance:
   - Most common shipment mode: Air
   - Management team handling most shipments: PMO-US (99% of shipments)
   - PMO-US delivers earlier than scheduled for all modes except Ocean
   - Most efficient combination: Air Charter by PMO-US (avg. 19 days early)

3. Profitability Analysis:
   - Most profitable shipment mode: Air Charter (managed by PMO-US)
     - Highest average line item value, profit, and profit margin percentage
   - Ocean mode shows the highest median profit and profit margin percentage

4. Temporal Trends:
   - Significant volatility in profitability over time
   - General upward trend in profitability for some modes (e.g., Truck by PMO-US in 2014)

5. Geographic Analysis:
   - Top 3 most profitable destination countries (min. 100 shipments):
     1. Nigeria: $10,914,602.89 avg. profit
     2. Mozambique: $10,675,219.01 avg. profit
     3. Zambia: $9,996,597.13 avg. profit
   - Least profitable destination: South Sudan ($182,613.78 avg. profit)

6. Manufacturing Site Performance:
   - Most profitable manufacturing country: India (IN)
     - Highest average profit and number of shipments
   - Least profitable manufacturing country: South Korea (KR)

7. Product Analysis:
   - Most profitable product group: ARV
   - Most profitable combination: ARV product group with "Adult" subclassification
   - Highest avg. profit per shipment: ANTM product group, "Malaria" subclassification
   - One loss-making combination identified: HRDT, HIV test - Ancillary

8. Volume vs. Profitability:
   - High-volume shipments tend to correlate with high profitability
   - However, high profitability doesn't always indicate high volume

These findings provide valuable insights into the supply chain operations, highlighting areas of efficiency, profitability, and potential improvement across various dimensions such as shipment modes, destinations, product types, and manufacturing locations.
