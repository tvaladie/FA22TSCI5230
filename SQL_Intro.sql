-- !preview conn=DBI::dbConnect(RPostgres::Postgres(),dbname = 'postgres',host = 'db.zgqkukklhncxcctlqpvg.supabase.co',port = 5432,user = 'student',password = 'X')

/*SELECT * FROM tv_patients limit 10*/

--drop TABLE tv_demographics;

--CREATE TABLE tv_demographics as
SELECT
  subject_id,
  COUNT(DISTINCT ethnicity) as ethnicity_demo,
  cast(array_agg(ethnicity) as character(20)) as ethnicity_combo,
  MAX(language) as language_demo,
  MAX(deathtime) as death,
  COUNT(*) as admits,
  COUNT(edregtime) as num_ED,
  avg(DATE_PART('day', dischtime - admittime)) as LOS
FROM tv_admissions GROUP BY subject_id
SELECT COUNT(*) from tv_demographics GROUP BY language_demo

#10-26-2022
/*SELECT *
FROM Generate_series (Timestamp '2022-10-26', Timestamp '2022-11-15', Interval '1 day') AS scaffold(day)*/

/*WITH q0 AS
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
GROUP BY hadm_id, day)

SELECT *,
CASE
	WHEN Vanc >0 AND Zosyn >0 THEN 'Vanc&Zosyn'
	WHEN Vanc >0 AND Other >0 THEN 'Vanc&Other'
	WHEN Vanc >0 THEN 'Vanc'
	WHEN Zosyn >0 OR Other >0 THEN 'Other'
	WHEN Vanc + Zosyn + Other =0 THEN 'None'
	ELSE 'Undefined' END as Antibiotic
FROM q4*/

SELECT label, value, hadm_id, charttime
FROM tv_d_labitems AS items
INNER JOIN tv_labevents AS events
ON items.itemid = events.itemid
WHERE label LIKE '%reatinine%'
AND fluid = 'Blood'

