Shipping performances across different modes and management teams.
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

/*I've calculated the number of shipments for each combination of shipment mode and management team, 
the total and average delay between scheduled and actual delivery date, the tital and average between delivery and recording dates 
and I've ordered the results by the number of shipments, showing the most frequent combination first.
This query answers several important questions: - The shipment mode most commonly used is "Air". 
- The managment team that handles the most shipment is PMO-US. -PMO-US is able to deliver with the different shipment modes always
earlier than the scheduled delivery date, with the exception of the Ocean shipment mode. - There isn't a big gap between when items are delivered
and when they're recorded as delivered, with a maximum of 4.4 avg delay to record. 
We cannot really do a comparison between the different managements because PMO-US alone menages 99% of the shipments. 
The combination of shipment mode and management team that stands out as more efficient is Air Charte by PMO-US, with an avg delay to deliver of -19
days, meaning 19 day in advance to the delivery date. 
*/
