/*
=====================================================================
 Project  : Healthcare Patient Analytics
 Tool     : SQL Server (SSMS)
 Dataset  : Healthcare dataset downloaded from Kaggle
            (dataset name / link: <ADD KAGGLE LINK HERE>)
 Contents : 1) Database and raw table setup
            2) Data quality checks
            3) Normalized tables (Patients, Treatments, Visits)
            4) 25 business questions
 How to run:
   1. Run Section 1 to create the database and raw table.
   2. Load the CSV into PatientAnalytics (dates are in day-month-year format;
      check with SELECT MIN(visit_date), MAX(visit_date) FROM PatientAnalytics)
      (SSMS > right-click database > Tasks > Import Flat File,
       or Import Data, and map it to the PatientAnalytics table).
   3. Run the remaining sections from top to bottom.
=====================================================================
*/


/* =====================================================================
   SECTION 1: DATABASE AND RAW TABLE
   ===================================================================== */
IF DB_ID('HealthcareAnalytics') IS NULL
    CREATE DATABASE HealthcareAnalytics;
GO

USE HealthcareAnalytics;
GO

IF OBJECT_ID('PatientAnalytics', 'U') IS NULL
CREATE TABLE PatientAnalytics
(
    patient_id          INT,
    visit_date          DATETIME,
    age_group           VARCHAR(20),
    gender              VARCHAR(10),
    region              VARCHAR(30),
    department          VARCHAR(50),
    treatment_type      VARCHAR(50),
    visit_type          VARCHAR(20),
    length_of_stay_days DECIMAL(4,1),
    treatment_cost      INT,
    recovery_score      INT,
    readmission_risk    DECIMAL(4,2)
);
GO


/* =====================================================================
   SECTION 2: DATA QUALITY CHECKS
   ===================================================================== */

-- Total records
SELECT COUNT(*) AS Total_Records
FROM PatientAnalytics;

-- Preview data
SELECT TOP 10 *
FROM PatientAnalytics;

-- Missing values
SELECT *
FROM PatientAnalytics
WHERE patient_id          IS NULL
   OR visit_date          IS NULL
   OR age_group           IS NULL
   OR gender              IS NULL
   OR region              IS NULL
   OR department          IS NULL
   OR treatment_type      IS NULL
   OR visit_type          IS NULL
   OR length_of_stay_days IS NULL
   OR treatment_cost      IS NULL
   OR recovery_score      IS NULL
   OR readmission_risk    IS NULL;

-- Duplicate visits
SELECT patient_id, visit_date, COUNT(*) AS Duplicate_Count
FROM PatientAnalytics
GROUP BY patient_id, visit_date
HAVING COUNT(*) > 1;

-- Range of readmission risk (used to choose the risk categories in Q15)
SELECT MIN(readmission_risk) AS Min_Risk,
       MAX(readmission_risk) AS Max_Risk
FROM PatientAnalytics;
GO


/* =====================================================================
   SECTION 3: NORMALIZED TABLES
   ===================================================================== */

-- Patients (one row per patient)
IF OBJECT_ID('Patients', 'U') IS NULL
BEGIN
    CREATE TABLE Patients
    (
        patient_id SMALLINT PRIMARY KEY,
        age_group  NVARCHAR(50),
        gender     NVARCHAR(50),
        region     NVARCHAR(50)
    );

    INSERT INTO Patients (patient_id, age_group, gender, region)
    SELECT DISTINCT patient_id, age_group, gender, region
    FROM PatientAnalytics;
END
GO

-- Treatments (one row per department + treatment type)
IF OBJECT_ID('Treatments', 'U') IS NULL
BEGIN
    CREATE TABLE Treatments
    (
        treatment_id   INT IDENTITY(1,1) PRIMARY KEY,
        department     NVARCHAR(50),
        treatment_type NVARCHAR(50)
    );

    INSERT INTO Treatments (department, treatment_type)
    SELECT DISTINCT department, treatment_type
    FROM PatientAnalytics;
END
GO

-- Visits (one row per hospital visit)
IF OBJECT_ID('Visits', 'U') IS NULL
BEGIN
    CREATE TABLE Visits
    (
        visit_id            INT IDENTITY(1,1) PRIMARY KEY,
        patient_id          SMALLINT FOREIGN KEY REFERENCES Patients(patient_id),
        treatment_id        INT      FOREIGN KEY REFERENCES Treatments(treatment_id),
        visit_date          DATETIME,
        visit_type          VARCHAR(20),
        length_of_stay_days DECIMAL(4,1),
        treatment_cost      INT,
        recovery_score      INT,
        readmission_risk    DECIMAL(4,2)
    );

    INSERT INTO Visits
        (patient_id, treatment_id, visit_date, visit_type,
         length_of_stay_days, treatment_cost, recovery_score, readmission_risk)
    SELECT
        pa.patient_id,
        t.treatment_id,
        pa.visit_date,
        pa.visit_type,
        pa.length_of_stay_days,
        pa.treatment_cost,
        pa.recovery_score,
        pa.readmission_risk
    FROM PatientAnalytics pa
    INNER JOIN Treatments t
        ON  pa.department     = t.department
        AND pa.treatment_type = t.treatment_type;
END
GO

-- Quick check of the new tables
SELECT COUNT(*) AS Patients_Rows   FROM Patients;
SELECT COUNT(*) AS Treatments_Rows FROM Treatments;
SELECT COUNT(*) AS Visits_Rows     FROM Visits;
GO


/* =====================================================================
   SECTION 4: BUSINESS QUESTIONS
   ===================================================================== */

-- 1) How many unique patients visited the hospital?
SELECT COUNT(DISTINCT patient_id) AS TOTAL_PATIENTS
FROM Visits;

-- 2) How many patients belong to each gender?
SELECT gender, COUNT(patient_id) AS TOTAL_PATIENTS
FROM Patients
GROUP BY gender;

-- 3) Which region has the highest number of patients?
SELECT region, COUNT(patient_id) AS PATIENTS_COUNT
FROM Patients
GROUP BY region
ORDER BY PATIENTS_COUNT DESC;

-- 4) Which department treated the highest number of patients?
SELECT T.department, COUNT(V.patient_id) AS PATIENTS_COUNT
FROM Treatments T
INNER JOIN Visits V
    ON T.treatment_id = V.treatment_id
GROUP BY T.department
ORDER BY PATIENTS_COUNT DESC;

-- 5) Which treatment type is used most frequently?
SELECT T.treatment_type, COUNT(V.patient_id) AS PATIENTS_COUNT
FROM Treatments T
INNER JOIN Visits V
    ON T.treatment_id = V.treatment_id
GROUP BY T.treatment_type
ORDER BY PATIENTS_COUNT DESC;

-- 6) Which department generated the highest total treatment cost (revenue)?
SELECT T.department, SUM(V.treatment_cost) AS TOTAL_REVENUE
FROM Treatments T
INNER JOIN Visits V
    ON T.treatment_id = V.treatment_id
GROUP BY T.department
ORDER BY TOTAL_REVENUE DESC;

-- 7) Which department has the highest average treatment cost?
--    (multiplied by 1.0 so AVG keeps decimals instead of truncating)
SELECT T.department, AVG(V.treatment_cost * 1.0) AS AVG_TREATMENT_COST
FROM Treatments T
INNER JOIN Visits V
    ON T.treatment_id = V.treatment_id
GROUP BY T.department
ORDER BY AVG_TREATMENT_COST DESC;

-- 8) Which region generated the highest total treatment revenue?
SELECT P.region, SUM(V.treatment_cost) AS TOTAL_REVENUE
FROM Patients P
INNER JOIN Visits V
    ON P.patient_id = V.patient_id
GROUP BY P.region
ORDER BY TOTAL_REVENUE DESC;

-- 9) Which month recorded the highest number of patient visits?
--    (Note: Jan, Mar and May tie at 744 visits each)
SELECT YEAR(visit_date)  AS VISIT_YEAR,
       MONTH(visit_date) AS VISIT_MONTH,
       COUNT(patient_id) AS PATIENT_COUNT
FROM Visits
GROUP BY YEAR(visit_date), MONTH(visit_date)
ORDER BY PATIENT_COUNT DESC;

-- 10) Which patients had the highest treatment cost? (Top 10)
SELECT TOP 10
       P.patient_id,
       P.region,
       T.department,
       SUM(V.treatment_cost) AS TOTAL_COST
FROM Patients P
INNER JOIN Visits V
    ON P.patient_id = V.patient_id
INNER JOIN Treatments T
    ON T.treatment_id = V.treatment_id
GROUP BY P.patient_id, P.region, T.department
ORDER BY TOTAL_COST DESC;

-- 11) Which departments have an average treatment cost greater than Rs. 55,000?
SELECT T.department, AVG(V.treatment_cost * 1.0) AS AVG_TREATMENT_COST
FROM Treatments T
INNER JOIN Visits V
    ON T.treatment_id = V.treatment_id
GROUP BY T.department
HAVING AVG(V.treatment_cost * 1.0) > 55000
ORDER BY AVG_TREATMENT_COST DESC;

-- 12) Which departments have more than 1,000 patient visits?
SELECT T.department, COUNT(V.patient_id) AS TOTAL_VISITS
FROM Treatments T
INNER JOIN Visits V
    ON T.treatment_id = V.treatment_id
GROUP BY T.department
HAVING COUNT(V.patient_id) > 1000
ORDER BY TOTAL_VISITS DESC;

-- 13) Which treatment types generated a total cost greater than Rs. 69,000,000?
SELECT T.treatment_type, SUM(V.treatment_cost) AS TOTAL_COST
FROM Treatments T
INNER JOIN Visits V
    ON T.treatment_id = V.treatment_id
GROUP BY T.treatment_type
HAVING SUM(V.treatment_cost) > 69000000
ORDER BY TOTAL_COST DESC;

-- 14) Classify patients based on their recovery score.
SELECT patient_id,
       recovery_score,
       CASE
           WHEN recovery_score >= 90 THEN 'EXCELLENT'
           WHEN recovery_score >= 70 THEN 'GOOD'
           WHEN recovery_score >= 50 THEN 'AVERAGE'
           ELSE 'POOR'
       END AS RECOVERY_STATUS
FROM Visits;

-- 15) Classify patients based on readmission risk.
SELECT patient_id,
       readmission_risk,
       CASE
           WHEN readmission_risk >= 0.7 THEN 'HIGH RISK'
           WHEN readmission_risk >= 0.4 THEN 'MEDIUM RISK'
           ELSE 'LOW RISK'
       END AS RISK_CATEGORY
FROM Visits;

-- 16) Rank departments by total revenue.
SELECT T.department,
       SUM(V.treatment_cost) AS TOTAL_REVENUE,
       RANK() OVER (ORDER BY SUM(V.treatment_cost) DESC) AS DEPARTMENT_RANK
FROM Treatments T
INNER JOIN Visits V
    ON T.treatment_id = V.treatment_id
GROUP BY T.department;

-- 17) Find the top 3 departments based on total revenue.
WITH DEPT_REVENUE AS
(
    SELECT T.department,
           SUM(V.treatment_cost) AS TOTAL_REVENUE,
           RANK() OVER (ORDER BY SUM(V.treatment_cost) DESC) AS DEPARTMENT_RANK
    FROM Treatments T
    INNER JOIN Visits V
        ON T.treatment_id = V.treatment_id
    GROUP BY T.department
)
SELECT *
FROM DEPT_REVENUE
WHERE DEPARTMENT_RANK <= 3;

-- 18) Find the highest treatment cost for each department.
WITH RANKED AS
(
    SELECT T.department,
           V.patient_id,
           V.treatment_cost,
           RANK() OVER (PARTITION BY T.department
                        ORDER BY V.treatment_cost DESC) AS RNK
    FROM Treatments T
    INNER JOIN Visits V
        ON T.treatment_id = V.treatment_id
)
SELECT *
FROM RANKED
WHERE RNK = 1;

-- 19) Find the top 2 highest treatment-cost records for each department
--     (including ties, so DENSE_RANK is used).
WITH RANKED AS
(
    SELECT T.department,
           V.patient_id,
           V.treatment_cost,
           DENSE_RANK() OVER (PARTITION BY T.department
                              ORDER BY V.treatment_cost DESC) AS RNK
    FROM Treatments T
    INNER JOIN Visits V
        ON T.treatment_id = V.treatment_id
)
SELECT *
FROM RANKED
WHERE RNK <= 2
ORDER BY department, RNK;

-- (Optional) ROW_NUMBER version: exactly 2 rows per department, ties not included
WITH NUMBERED AS
(
    SELECT T.department,
           V.patient_id,
           V.treatment_cost,
           ROW_NUMBER() OVER (PARTITION BY T.department
                              ORDER BY V.treatment_cost DESC) AS ROW_NUM
    FROM Treatments T
    INNER JOIN Visits V
        ON T.treatment_id = V.treatment_id
)
SELECT *
FROM NUMBERED
WHERE ROW_NUM <= 2
ORDER BY department, ROW_NUM;

-- 20) Find patients whose treatment cost is higher than the overall average.
SELECT T.department, V.patient_id, V.treatment_cost
FROM Treatments T
INNER JOIN Visits V
    ON T.treatment_id = V.treatment_id
WHERE V.treatment_cost > (SELECT AVG(treatment_cost * 1.0) FROM Visits)
ORDER BY V.treatment_cost DESC;

-- 21) Find departments whose total revenue is greater than the average
--     revenue of all departments.
WITH REVENUE_CTE AS
(
    SELECT T.department, SUM(V.treatment_cost) AS TOTAL_REVENUE
    FROM Treatments T
    INNER JOIN Visits V
        ON T.treatment_id = V.treatment_id
    GROUP BY T.department
)
SELECT department, TOTAL_REVENUE
FROM REVENUE_CTE
WHERE TOTAL_REVENUE > (SELECT AVG(TOTAL_REVENUE * 1.0) FROM REVENUE_CTE)
ORDER BY TOTAL_REVENUE DESC;

-- 22) Find patients whose treatment cost is higher than the average
--     treatment cost of their own department (correlated subquery).
SELECT T.department, V.patient_id, V.treatment_cost
FROM Treatments T
INNER JOIN Visits V
    ON T.treatment_id = V.treatment_id
WHERE V.treatment_cost >
(
    SELECT AVG(V1.treatment_cost * 1.0)
    FROM Visits V1
    INNER JOIN Treatments T1
        ON T1.treatment_id = V1.treatment_id
    WHERE T1.department = T.department
)
ORDER BY T.department, V.treatment_cost DESC;

-- 23) Find patients who have visited the hospital at least once.
SELECT P.patient_id, P.region, P.gender
FROM Patients P
WHERE EXISTS
(
    SELECT 1
    FROM Visits V
    WHERE V.patient_id = P.patient_id
);

-- 24) Find patients who have never visited the hospital.
--     (Returns 0 rows here because Patients was built from visit data.)
SELECT P.patient_id, P.region, P.gender
FROM Patients P
WHERE NOT EXISTS
(
    SELECT 1
    FROM Visits V
    WHERE V.patient_id = P.patient_id
);

-- 25) Identify departments with a high average readmission risk (above 0.28).
SELECT T.department,
       COUNT(V.patient_id)       AS PATIENT_COUNT,
       AVG(V.readmission_risk)   AS AVG_READMISSION_RISK
FROM Treatments T
INNER JOIN Visits V
    ON T.treatment_id = V.treatment_id
GROUP BY T.department
HAVING AVG(V.readmission_risk) > 0.28
ORDER BY AVG_READMISSION_RISK DESC;
