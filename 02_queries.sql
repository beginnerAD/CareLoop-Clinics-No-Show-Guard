--TASK 2.1: Primary Key Duplicate Test & Error Output
SELECT COUNT(*) AS total_clinics FROM clinics;
SELECT COUNT(*) AS total_appointments, SUM(no_show) AS total_no_shows FROM appointments;


--Duplicate primary key insert test:
--INSERT INTO appointments VALUES (
--    'A0001', 'P999', 'C01', '2025-01-01', '2025-01-05', 30, 'F',
--    5.0, 500, 'App', 'Consultation', 'Yes', 0, 'Attended', 4, 0
--);
--Error Output:
--SQLITE_CONSTRAINT_PRIMARYKEY: sqlite3 result code 1555: UNIQUE constraint failed: appointments.appointment_id


-- Task 2.2 (Part A): No-show rate by clinic (clinics with >= 95 appointments)
SELECT 
    c.clinic_name,
    c.city,
    COUNT(*) AS appointments,
    SUM(a.no_show) AS no_shows,
    ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments a
JOIN clinics c ON a.clinic_id = c.clinic_id
GROUP BY c.clinic_id, c.clinic_name, c.city
HAVING COUNT(*) >= 95
ORDER BY no_show_pct DESC;


-- Task 2.2 (Part B): All 8 clinics without HAVING filter
SELECT 
    c.clinic_name,
    c.city,
    COUNT(*) AS appointments,
    SUM(a.no_show) AS no_shows,
    ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments a
JOIN clinics c ON a.clinic_id = c.clinic_id
GROUP BY c.clinic_id, c.clinic_name, c.city
ORDER BY no_show_pct DESC;


-- Task 2.3: No-show rate by lead_days band
SELECT 
    CASE 
        WHEN lead_days <= 7 THEN '1-7'
        WHEN lead_days <= 14 THEN '8-14'
        WHEN lead_days <= 30 THEN '15-30'
        ELSE '31+'
    END AS lead_band,
    COUNT(*) AS appointments,
    SUM(no_show) AS no_shows,
    ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments
GROUP BY lead_band
ORDER BY MIN(lead_days);


-- Task 2.4: Month-by-month no-show trend using CTE and LAG()
WITH monthly AS (
    SELECT 
        SUBSTR(appt_date, 1, 7) AS month,
        COUNT(*) AS appointments,
        ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
    FROM appointments
    GROUP BY SUBSTR(appt_date, 1, 7)
)
SELECT 
    month,
    appointments,
    no_show_pct,
    ROUND(no_show_pct - LAG(no_show_pct) OVER (ORDER BY month), 1) AS change_pct_pts
FROM monthly
ORDER BY month;


-- Task 2.5: Rank clinics inside each city and compare against overall no-show rate
WITH clinic_rates AS (
    SELECT 
        c.clinic_name AS clinic,
        c.city,
        ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
    FROM appointments a
    JOIN clinics c ON a.clinic_id = c.clinic_id
    GROUP BY c.clinic_id, c.clinic_name, c.city
)
SELECT 
    clinic,
    city,
    no_show_pct,
    RANK() OVER (PARTITION BY city ORDER BY no_show_pct DESC) AS rank_in_city,
    CASE 
        WHEN no_show_pct > (SELECT ROUND(100.0 * SUM(no_show) / COUNT(*), 1) FROM appointments) THEN 'above'
        WHEN no_show_pct < (SELECT ROUND(100.0 * SUM(no_show) / COUNT(*), 1) FROM appointments) THEN 'below'
        ELSE 'equal'
    END AS vs_overall
FROM clinic_rates
ORDER BY city, rank_in_city;