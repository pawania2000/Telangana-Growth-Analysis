-- Documents revenue by district --

SELECT
    d.district,
    SUM(fs.documents_registered_rev) AS total_revenue
FROM
    stamps fs
JOIN
    districts d
ON
    fs.dist_code = d.dist_code
GROUP BY
    d.district
ORDER BY
    total_revenue DESC;

-- Percentage of total revenue and top 5 districts with highest revenue --

SELECT
    d.district,
    SUM(fs.documents_registered_rev)/(select sum(documents_registered_rev) from stamps)*100 AS per_total_revenue
FROM
    stamps fs
JOIN
    districts d
ON
    fs.dist_code = d.dist_code
GROUP BY
    d.district
ORDER BY
    per_total_revenue DESC;

-- the top 5 districts where e-stamps revenue contributes significantly more to the revenue than the documents in FY 2022 --

SELECT
    ds.district,
    SUM(s.documents_registered_rev) AS document_registration_revenue,
    SUM(s.estamps_challans_rev) AS estamps_revenue
FROM
    stamps s
JOIN
    districts ds ON s.dist_code = ds.dist_code
JOIN
    Date d ON s.month = d.month
WHERE
    d.fiscal_year = 2022
GROUP BY
    ds.district
HAVING
    SUM(s.estamps_challans_rev) > 1 * SUM(s.documents_registered_rev) -- Adjust the threshold as needed
ORDER BY
    SUM(s.estamps_challans_rev) DESC
LIMIT
    5;
    
 -- Is there any alteration of e-Stamp challan count and document registration count pattern since the implementation of e-Stamp challan? --
   
SELECT
    DATE_FORMAT(month, '%Y-%m') AS period,
    'Before Implementation' AS implementation_phase,
    SUM(estamps_challans_cnt) AS estamps_challans_count,
    SUM(documents_registered_cnt) AS documents_registered_count
FROM
    stamps
WHERE
    month < '2020-01-01'
GROUP BY
    DATE_FORMAT(month, '%Y-%m')

UNION ALL

SELECT
    DATE_FORMAT(month, '%Y-%m') AS period,
    'After Implementation' AS implementation_phase,
    SUM(estamps_challans_cnt) AS estamps_challans_count,
    SUM(documents_registered_cnt) AS documents_registered_count
FROM
    stamps
WHERE
    month >= '2020-01-01'
GROUP BY
    DATE_FORMAT(month, '%Y-%m');
    
-- Categorize districts into three segments based on their stamp registration revenue generation during the fiscal year 2021 to 2022. --
    
SELECT
    dist_code,
    revenue_2021_2022,
    CASE
        WHEN revenue_quantile = 1 THEN 'Low Revenue'
        WHEN revenue_quantile = 2 THEN 'Medium Revenue'
        WHEN revenue_quantile = 3 THEN 'High Revenue'
    END AS revenue_segment
FROM (
    SELECT
        dist_code,
        revenue_2021_2022,
        NTILE(3) OVER (ORDER BY revenue_2021_2022) AS revenue_quantile
    FROM (
        SELECT
            dist_code,
            SUM(CASE
                WHEN (YEAR(month) = 2021 AND MONTH(month) >= 4) OR
                     (YEAR(month) = 2022 AND MONTH(month) <= 3) THEN documents_registered_rev
                ELSE 0
            END) AS revenue_2021_2022
        FROM
            stamps
        GROUP BY
            dist_code
    ) AS Revenue2021_2022
) AS RevenueQuantiles;

-- Transport dataset --

-- Investigate whether there is any correlation between vehicle sales and specific months or seasons in different districts. Are there any months or seasons that consistently show higher or lower sales rate, (Consider Fuel-Type category only) 

SELECT
    DATE_FORMAT(month, '%m') as month,
    SUM(fuel_type_petrol) AS petrol_sales,
    SUM(fuel_type_diesel) AS diesel_sales,
    SUM(fuel_type_electric) AS electric_sales,
    SUM(fuel_type_others) AS others_sales
FROM
    transport
GROUP BY
    DATE_FORMAT(month, '%m')
ORDER BY
    DATE_FORMAT(month, '%m');

-- total vehicle sales

SELECT
    monthname(month),
    sum(fuel_type_petrol + fuel_type_diesel + fuel_type_electric + fuel_type_others) AS total_vehicle_sales
FROM
    transport
GROUP BY
	date_format(month,'%m'),monthname(month)
ORDER BY
    date_format(month,'%m');

-- How does the distribution of vehicles vary by vehicle class (MotorCycle, MotorCar, AutoRickshaw, Agriculture) across different districts? 

SELECT
    d.district AS district_name,
    sum(t.vehicleClass_MotorCycle) as motor_cycle,
    sum(t.vehicleClass_MotorCar) as motor_car,
    sum(t.vehicleClass_AutoRickshaw) as auto_rickshaw,
    sum(t.vehicleClass_Agriculture) as agriculture
FROM
    transport t
JOIN
    districts d ON t.dist_code = d.dist_code
GROUP BY
    d.district;


-- top 3 districts and bottom 3 districts --

SELECT
    d.district,
    SUM(fuel_type_petrol) AS petrol_sales,
    SUM(fuel_type_diesel) AS diesel_sales,
    SUM(fuel_type_electric) AS electric_sales
FROM
    transport t
JOIN
    districts d on d.dist_code = t.dist_code
WHERE 
    EXTRACT(YEAR FROM t.month) = 2022
GROUP BY
    d.district
ORDER BY
    petrol_sales  desc;

-- Ipass dataset

-- top 5 sectors with high investment--    

SELECT 
    sector,
    round(SUM(investment_in_cr),2) AS total_investment_in_cr
FROM 
   ts_ipass I
JOIN
        Date D ON DATE_FORMAT(STR_TO_DATE(I.month, '%d-%m-%Y'), '%Y-%m-%d') = D.month
WHERE 
        D.fiscal_year = 2022
GROUP BY 
    sector
ORDER BY 
    total_investment_in_cr DESC
LIMIT 5; 

--  top 3 districts that have attracted the most significant sector investments during FY 2019 to 2022? --

SELECT
    DN.district,
    round(sum(T.investment_in_cr),2) as total_invest
FROM
    districts AS DN
JOIN
    ts_ipass T ON DN.dist_code = T.dist_code
GROUP BY
    DN.district
ORDER BY
    total_invest DESC
LIMIT
    3;
  
-- sectors that have shown investment in multiple districts --

SELECT 
    sector, count(distinct d.district) as district_counts,
    round(SUM(investment_in_cr),2) AS total_investment_in_cr
FROM 
    ts_ipass I
JOIN 
    districts d on d.dist_code = I.dist_code
WHERE 
    STR_TO_DATE(month, '%d-%m-%Y') >= '2021-04-01' AND STR_TO_DATE(month, '%d-%m-%Y') <= '2022-03-01'
GROUP BY 
    sector
ORDER BY 
    district_counts DESC;

