/*
Before everything else I created a new table, with the same data of the initial table, so that I have a back up if anythings happen,
and I'm not going to modify the initial table.

*/

SELECT *
INTO supply_chain_backup
FROM supply_chain_n
WHERE 1 = 0;

INSERT INTO supply_chain_backup
SELECT * FROM supply_chain_n;

-- An example just to show that it worked
SELECT TOP (5) *
FROM supply_chain_backup;


/*
Data Cleaning
1. Removing duplicates. Using a window function to look for duplicates.
2. Standardizing Data
3. Spelling mistakes
4. Null values


*/

-- 1. Removing duplicates
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
/* 
In the freight_cost_usd column, I identified values that were not valid numerical entries but instead pointed to external documents that we do 
not possess. To clean the data and ensure the integrity of subsequent calculations, I updated these entries to NULL.

*/
SELECT freight_cost_usd
FROM supply_chain_n
WHERE freight_cost_usd LIKE 'See%';


UPDATE supply_chain_n
SET freight_cost_usd = null
WHERE freight_cost_usd LIKE 'See%';

-- I did the same for the weight_kg

SELECT weight_kg
FROM supply_chain_n
WHERE weight_kg LIKE 'See%';

UPDATE supply_chain_n
SET weight_kg = null
WHERE weight_kg LIKE 'See%';

-- I noticed that scheduled_delivery_date had a datetime type, and I want to change it into date type
ALTER TABLE supply_chain_n
ADD scheduled_delivery_date_new DATE;

UPDATE supply_chain_n
SET scheduled_delivery_date_new = CAST(scheduled_delivery_date AS DATE);

ALTER TABLE supply_chain_n
DROP COLUMN scheduled_delivery_date;

EXEC sp_rename 'supply_chain_n.scheduled_delivery_date_new', 'scheduled_delivery_date', 'COLUMN';

-- I did the same for delivered_to_client_date 

ALTER TABLE supply_chain_n
ADD delivered_to_client_date_new DATE;

UPDATE supply_chain_n
SET delivered_to_client_date_new = CAST( delivered_to_client_date AS DATE);

ALTER TABLE supply_chain_n
DROP COLUMN delivered_to_client_date;

EXEC sp_rename 'supply_chain_n.delivered_to_client_date_new', 'delivered_to_client_date', 'COLUMN';

-- I did the same with delivery_recorded_date
ALTER TABLE supply_chain_n
ADD delivery_recorded_date_new DATE;

UPDATE supply_chain_n
SET delivery_recorded_date_new = CAST(delivery_recorded_date AS DATE);

ALTER TABLE supply_chain_n
DROP COLUMN delivery_recorded_date;

EXEC sp_rename 'supply_chain_n.delivery_recorded_date_new', 'delivery_recorded_date', 'COLUMN';

-- Found out the line_item_quantity has the wrong data type, varchar instead of int, so I'm changin it

ALTER TABLE supply_chain_n
ADD line_item_quantity_int INT;

UPDATE supply_chain_n
SET line_item_quantity_int = CAST(line_item_quantity AS INT);

ALTER TABLE supply_chain_n
DROP COLUMN line_item_quantity;

EXEC sp_rename 'supply_chain_n.line_item_quantity_int', 'line_item_quantity', 'COLUMN';

-- Same thing happened for freight_cost_ usd

-- Add a new column with DECIMAL type
ALTER TABLE supply_chain_n
ADD freight_cost_usd_decimal DECIMAL(18, 2);

UPDATE supply_chain_n
SET freight_cost_usd_decimal = TRY_CAST(freight_cost_usd AS DECIMAL(18, 2));

ALTER TABLE supply_chain_n
DROP COLUMN freight_cost_usd;

EXEC sp_rename 'supply_chain_n.freight_cost_usd_decimal', 'freight_cost_usd', 'COLUMN';


-- Noticed that line_item_value's data type, int, had numbers larger that the maximum value that it can handle, so I've changed the data type

-- Alter the column type to BIGINT
ALTER TABLE supply_chain_n
ALTER COLUMN line_item_value BIGINT;

--  Doing some cleaning I found a row in the dosage_form that said oral powder instead of powder for oral solution, so I put all of them in the same column

UPDATE supply_chain_n
SET dosage_form = 'Powder for oral solution'
WHERE dosage_form = 'Oral powder';

-- Found some rows where it wasn't indicating a country, so I changed them to null
UPDATE supply_chain_n
SET manifacturing_site_country = null
WHERE manifacturing_site_country IN ('L.C.', 'Inc', 'Ltd.', 'Plc');


-- Found rows where it was written 'Weight Captured Separately' so I changed that to null
UPDATE supply_chain_n
SET weight_kg = null
WHERE weight_kg = 'Weight Captured Separately';

--With queries like this I checked if the data was Standardized and Spelling mistakes
SELECT DISTINCT(dosage_form)
FROM supply_chain_n;
