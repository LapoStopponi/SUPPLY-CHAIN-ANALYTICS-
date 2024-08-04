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
/* The product type that is the most profitable to ship is the ARV product group, if we want to look athe the most profitable combination 
between product group and subclassification, the ARV product group with "Adult" as the subclassification is the most profitable combination. I've also
calculated the avg profit per shipment, with the ANTM product group in combination with the subclassification Malaria, as the one that has the most
avg profit per shipment. To take into consideration though the low number of shipments in this case. Then I've also compared the colume with the
profitability, comparing num_shipmentwith avg_profit. In this case it shows how High Volume alwasy goes with High Profit, but we cannot say the opposite.
High Profit doesn't always go with High Volume. From this query we can also see how there is a combination between product group and subclassification
that is a loss, HRDT, HIV test- Ancillary.
