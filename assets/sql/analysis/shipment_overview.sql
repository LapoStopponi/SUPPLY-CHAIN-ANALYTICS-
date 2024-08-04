Overview of shipment volumes and costs.
SELECT
	COUNT(*) AS total_shipments,
	SUM(line_item_quantity) AS total_quantity,
	ROUND(AVG(unit_price),2) AS avg_unit_price,
	ROUND(SUM(line_item_value),2) AS total_value,
	ROUND(AVG(freight_cost_usd),2) AS avg_freight_cost
FROM supply_chain_n;

-- The total number of shipments is 10,324, total quantity is 189,265,090,average unit price is $29, total value is $56,112,867,105, average freight cost is $11103.23.
