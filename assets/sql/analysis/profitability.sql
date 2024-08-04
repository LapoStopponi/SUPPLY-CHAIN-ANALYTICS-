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
	
/* I've created a CTE and used it to work with different window functions, - I've calculated the three-month moving average, 
for example for the Truck shipment mode managed by PMO-US, for the year 2014, -> Insights: the moving average shows a big values range, 
from about 5,6 million to 18 million. There's a clear peak in the middle of the series. The series ends higher than it stars. There are significant 
changes between consecutive periods, indicating volatility. The largest increase between the 4th and 5th values. The largest decrease between the 7th and 8th values. 
Despite fluctuations, there's a general upward trend from the beginning to the end of the series. -I've calculated the cumulative_yearly_profit, 
which displays the cumulative profitability over the year, providing a sense of how profitability builds up over time. Taking as an example the year 2008,
for Air shipment_mode managed by PMO-US, we can see that there is a significant drop from the first to the second value, but from the second value onward, 
the trend is upward. The growth rate seems to slow down towards the end of the series. -I've also calculated the difference from the overall average, this
highlights the deviations from the overall average profitability, pinpointing months that perform better or worse than average, while all the other
months have less profitability than the overall average.
*/
