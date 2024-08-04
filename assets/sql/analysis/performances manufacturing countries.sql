--Performances of the manufacturing countries.
SELECT
	COUNT(*) AS num_shipments,
	manifacturing_site_country,
	ROUND(AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)),2) AS avg_profit
FROM supply_chain_n
GROUP BY manifacturing_site_country
HAVING COUNT(*) > 100
ORDER BY avg_profit DESC;

/*
This query gives the countries with the manifacturing sites, the average profit and the number of shipments for each manifacturing country. 
I've ordered the query by the avg_profit so that it would show the most profitable manifacturing site country on a descending order. India (IN)
is the country where the manifacturing sites have the highest avg_profit and the highest number of shipments. 
*/
SELECT
	COUNT(*) AS num_shipments,
	manifacturing_site_country,
	ROUND(AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)),2) AS avg_profit
FROM supply_chain_n
GROUP BY manifacturing_site_country
HAVING COUNT(*) > 100
ORDER BY avg_profit;

/*
By just removing the DESC at the end f the previous query we can find out what are the least profitable countries: South Korea (KR) is the least
profitable.
*/
