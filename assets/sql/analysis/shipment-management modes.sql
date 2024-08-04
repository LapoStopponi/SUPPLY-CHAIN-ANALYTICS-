--How do different shipment modes and management teams compare in terms of cost and profitability?

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

/*
This query gives an overview of the profitability of different shipment modes and management teams. The shipment mode with the highest avg_freight_cost
and with the highest avg_total_cost, is Air Charter managed by PMO-US, that is also the one with the highest avg_line_item_value, and the one with the 
highest avg_profit and the one with the highest avg_profit_margin_percentage.
I've also calculated the median to see if things changed because of outliers, and we can see that Air Charter still has the most expenses, 
while the Ocean mode has the highest meadian line_item_value, the highest median_profit and the highest median_profit_margin_percentage.
*/
