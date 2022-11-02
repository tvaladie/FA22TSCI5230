/*SELECT *
FROM Generate_series (Timestamp '2022-10-26', Timestamp '2022-11-15', Interval '1 day') AS scaffold(day)*/

DROP TABLE tv_antibiotic_cr;
CREATE TABLE tv_antibiotic_cr AS
WITH q0 AS
(SELECT
GENERATE_SERIES(MIN(admittime), MAX(dischtime), INTERVAL '1 day') AS day
FROM tv_admissions),
q1 AS
(SELECT hadm_id, day::DATE
FROM q0
INNER JOIN tv_admissions AS adm ON q0.day BETWEEN adm.admittime::date AND adm.dischtime::date),
q2 AS
(SELECT hadm_id, item.abbreviation, starttime::date, endtime::date
FROM tv_d_items AS item
INNER JOIN tv_inputevents AS inp ON item.itemid = inp.itemid
WHERE (label LIKE '%anco%'
OR label LIKE '%iperacillin%'
OR label LIKE '%efepime%'
OR label LIKE '%rtapenem%'
OR label LIKE '%evofloxacin%')
AND category = 'Antibiotics'),

q3 AS
(SELECT abbreviation, q1.*
FROM q1 LEFT JOIN q2 ON q1.hadm_id = q2.hadm_id AND
q1.day BETWEEN starttime AND endtime),

q4 AS (SELECT hadm_id, day,
SUM(CASE WHEN abbreviation = 'Vancomycin' THEN 1 ELSE 0 END) AS Vanc,
SUM(CASE WHEN abbreviation LIKE '%Zosyn%' THEN 1 ELSE 0 END) AS Zosyn,
SUM(CASE WHEN abbreviation NOT LIKE '%Zosyn%' AND abbreviation != 'Vancomycin' THEN 1 ELSE 0 END) AS Other
FROM q3
GROUP BY hadm_id, day),

q5 AS
(SELECT
	   AVG(cast(value AS numeric)) OVER (PARTITION BY hadm_id, charttime::date) AS AverageCr,
	   --max(cast(value AS numeric)) AS MaxCr,
	   first_value(cast(value AS numeric)) OVER
 			(PARTITION BY hadm_id, charttime::date ORDER BY charttime desc) LastCr,
	   cast(value AS numeric),
 	   hadm_id,
	   charttime,
       row_number() OVER (PARTITION BY hadm_id, charttime::date ORDER BY charttime),
 		flag
	   --,sum(CASE WHEN flag is not null THEN 1
	  	--ELSE 0 END) AS AbnormalCount
FROM tv_d_labitems AS items
INNER JOIN tv_labevents AS events
ON items.itemid = events.itemid
WHERE label LIKE '%reatinine%'
AND fluid = 'Blood'
--GROUP BY hadm_id,charttime::date
ORDER BY hadm_id, charttime
),

q6 AS
(SELECT
	   AVG(value) AS AverageCr,
	   max(value) AS MaxCr,
	   max(LastCr) AS LastCr,
	   hadm_id,
	   charttime::date AS charttime,
	   sum(CASE WHEN flag is not null THEN 1
	  	ELSE 0 END) AS AbnormalCount
FROM q5
GROUP BY hadm_id, charttime::date)

SELECT q4.*, AverageCr, MaxCr, LastCr, AbnormalCount,
CASE
	WHEN Vanc >0 AND Zosyn >0 THEN 'Vanc&Zosyn'
	WHEN Vanc >0 AND Other >0 THEN 'Vanc&Other'
	WHEN Vanc >0 THEN 'Vanc'
	WHEN Zosyn >0 OR Other >0 THEN 'Other'
	WHEN Vanc + Zosyn + Other =0 THEN 'None'
	ELSE 'Undefined' END as Antibiotic
FROM q4

LEFT JOIN q6 ON q4.hadm_id = cast(q6.hadm_id AS bigint)
AND q4.day = q6.charttime

#11/2/22
DROP TABLE tv_antibiotic_cr;
CREATE TABLE tv_antibiotic_cr AS
WITH q0 AS
(SELECT
GENERATE_SERIES(MIN(admittime), MAX(dischtime), INTERVAL '1 day') AS day
FROM tv_admissions),
q1 AS
(SELECT hadm_id, day::DATE
FROM q0
INNER JOIN tv_admissions AS adm ON q0.day BETWEEN adm.admittime::date AND adm.dischtime::date),
q2 AS
(SELECT hadm_id, item.abbreviation, starttime::date, endtime::date
FROM tv_d_items AS item
INNER JOIN tv_inputevents AS inp ON item.itemid = inp.itemid
WHERE (label LIKE '%anco%'
OR label LIKE '%iperacillin%'
OR label LIKE '%efepime%'
OR label LIKE '%rtapenem%'
OR label LIKE '%evofloxacin%')
AND category = 'Antibiotics'),

q3 AS
(SELECT abbreviation, q1.*
FROM q1 LEFT JOIN q2 ON q1.hadm_id = q2.hadm_id AND
q1.day BETWEEN starttime AND endtime),

q4 AS (SELECT hadm_id, day,
SUM(CASE WHEN abbreviation = 'Vancomycin' THEN 1 ELSE 0 END) AS Vanc,
SUM(CASE WHEN abbreviation LIKE '%Zosyn%' THEN 1 ELSE 0 END) AS Zosyn,
SUM(CASE WHEN abbreviation NOT LIKE '%Zosyn%' AND abbreviation != 'Vancomycin' THEN 1 ELSE 0 END) AS Other
FROM q3
GROUP BY hadm_id, day),

q5 AS
(SELECT
	   AVG(cast(value AS numeric)) OVER (PARTITION BY hadm_id, charttime::date) AS AverageCr,
	   --max(cast(value AS numeric)) AS MaxCr,
	   first_value(cast(value AS numeric)) OVER
 			(PARTITION BY hadm_id, charttime::date ORDER BY charttime desc) LastCr,
	   cast(value AS numeric),
 	   hadm_id,
	   charttime,
       row_number() OVER (PARTITION BY hadm_id, charttime::date ORDER BY charttime),
 		flag
	   --,sum(CASE WHEN flag is not null THEN 1
	  	--ELSE 0 END) AS AbnormalCount
FROM tv_d_labitems AS items
INNER JOIN tv_labevents AS events
ON items.itemid = events.itemid
WHERE label LIKE '%reatinine%'
AND fluid = 'Blood'
--GROUP BY hadm_id,charttime::date
ORDER BY hadm_id, charttime
),

q6 AS
(SELECT
	   AVG(value) AS AverageCr,
	   max(value) AS MaxCr,
	   max(LastCr) AS LastCr,
	   hadm_id,
	   charttime::date AS charttime,
	   sum(CASE WHEN flag is not null THEN 1
	  	ELSE 0 END) AS AbnormalCount
FROM q5
GROUP BY hadm_id, charttime::date)

SELECT q4.*, AverageCr, MaxCr, LastCr, AbnormalCount,
CASE
	WHEN Vanc >0 AND Zosyn >0 THEN 'Vanc&Zosyn'
	WHEN Vanc >0 AND Other >0 THEN 'Vanc&Other'
	WHEN Vanc >0 THEN 'Vanc'
	WHEN Zosyn >0 OR Other >0 THEN 'Other'
	WHEN Vanc + Zosyn + Other =0 THEN 'None'
	ELSE 'Undefined' END as Antibiotic
FROM q4

LEFT JOIN q6 ON q4.hadm_id = cast(q6.hadm_id AS bigint)
AND q4.day = q6.charttime




