--Geographic analysis: How does profitability vary by destination?
SELECT
	COUNT(*) AS num_shipment,
	country, 
	ROUND(AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)),2) AS avg_profit
FROM supply_chain_n
GROUP BY country
HAVING COUNT(*) >= 100
ORDER BY avg_profit DESC;
/*
This is an overview of how profitability varies by destination country. I've considered countries with at least 100 shipping which is around 1% 
of the total shipping. I found that the top 3 profitable countries are Zambia with $ 9996597.13, Mozambique with $ 10675219.01, Nigeria being the 
most profitable with $ 10914602.89.
*/

SELECT
	COUNT(*) AS num_shipment,
	country,
	ROUND(AVG(line_item_value)-(AVG(freight_cost_usd) + AVG(line_item_insurance_usd)),2) AS avg_profit
FROM supply_chain_n
GROUP BY country
HAVING COUNT(*) >= 100
ORDER BY avg_profit ASC;

/* This shows the countries that performed the worst, with low profits. In this case also I've considered countries with at least 100 shippings.
The least profitable country is South Sudan, with an average profit of only $182613.78.
*/
