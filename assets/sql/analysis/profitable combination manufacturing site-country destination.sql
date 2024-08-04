--Most profitable combination between manufacturin site and country of destination.
SELECT 
	COUNT(*) AS num_shipment,
	manifacturing_site_country,
	country,
	ROUND(AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)),2) AS avg_profit
FROM supply_chain_n
GROUP BY manifacturing_site_country, country
HAVING COUNT(*) >= 100
ORDER BY avg_profit DESC;
/* I've then added country to the previous query in order to look at the most profitable combination between manifacturin site and country of destination.
The most profitable combination with at least 100 shipments, has the manifacturing site in India (IN), and the country of destination in Mozambique. 
*/
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
/* By just removing the DESC from the previous query we can see how the least profitable combination having India (IN) as the manifacturing site country
and Guyana as the country of destination.
*/
