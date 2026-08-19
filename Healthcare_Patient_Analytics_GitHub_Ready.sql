/*
===========================================================
Healthcare Patient Analytics - SQL Server Project
Author: Chinthalapudi Anil Kumar
Database: HealthcareAnalytics
Description:
Analysis of patient demographics, hospital visits,
treatment costs, revenue, recovery scores, and
readmission risk using SQL Server.

Project includes 25 business-driven SQL queries covering:
JOINs, aggregations, CASE, CTEs, subqueries,
correlated subqueries, EXISTS/NOT EXISTS, and
window functions.
===========================================================
*/

﻿CREATE DATABASE HealthcareAnalytics
CREATE TABLE PatientAnalytics
(
    patient_id INT,
    visit_date DATETIME,
    age_group VARCHAR(20),
    gender VARCHAR(10),
    region VARCHAR(30),
    department VARCHAR(50),
    treatment_type VARCHAR(50),
    visit_type VARCHAR(20),
    length_of_stay_days DECIMAL(4,1),
    treatment_cost INT,
    recovery_score INT,
    readmission_risk DECIMAL(4,2)
)
DROP TABLE PatientAnalytics;
EXEC sp_rename
'healthcare_patient_analytics',
'PatientAnalytics';
SELECT *FROM PatientAnalytics
SELECT COUNT(*) AS Total_Records
FROM PatientAnalytics
SELECT TOP 10 *
FROM PatientAnalytics
SELECT *
FROM PatientAnalytics
WHERE patient_id IS NULL
   OR visit_date IS NULL
   OR age_group IS NULL
   OR gender IS NULL
   OR region IS NULL
   OR department IS NULL
   OR treatment_type IS NULL
   OR visit_type IS NULL
   OR length_of_stay_days IS NULL
   OR treatment_cost IS NULL
   OR recovery_score IS NULL
   OR readmission_risk IS NULL;
SELECT patient_id,visit_date,COUNT(*) AS Duplicate_Count
FROM PatientAnalytics
GROUP BY patient_id,visit_date
HAVING COUNT(*) > 1
CREATE TABLE Patients
(
    patient_id SMALLINT PRIMARY KEY,
    age_group NVARCHAR(50),
    gender NVARCHAR(50),
    region NVARCHAR(50)
)
INSERT INTO Patients
(patient_id, age_group, gender, region)

SELECT DISTINCT patient_id,age_group,gender,region
FROM PatientAnalytics
select *from Patients
SELECT COUNT(*) AS TotalPatients
FROM Patients
SELECT COUNT(DISTINCT patient_id) AS UniquePatients
FROM PatientAnalytics
CREATE TABLE Treatments
(
    treatment_id INT IDENTITY(1,1) PRIMARY KEY,
    department NVARCHAR(50),
    treatment_type NVARCHAR(50)
)
INSERT INTO Treatments (department, treatment_type)
SELECT DISTINCT
    department,
    treatment_type
FROM PatientAnalytics
INSERT INTO Visits
(
    patient_id,
    treatment_id,
    visit_date,
    visit_type,
    length_of_stay_days,
    treatment_cost,
    recovery_score,
    readmission_risk
)
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
JOIN Treatments t
ON pa.department = t.department
AND pa.treatment_type = t.treatment_type
SELECT *FROM Patients
SELECT *FROM Treatments
SELECT *FROM Visits
--1)How many unique patients visited the hospital?
SELECT COUNT(DISTINCT patient_id)AS TOTAL_PATIENTS FROM Patients
--2)How many patients belong to each gender?
SELECT gender,COUNT(patient_id)AS TOTAL_PATIENTS FROM Patients
GROUP BY gender
--3)Which region has the highest number of patients?
SELECT region, COUNT(patient_id) AS PATIENTS_COUNT FROM Patients
GROUP BY region
ORDER BY COUNT(patient_id) DESC
--4)Which department treated the highest number of patients?
SELECT T.department,COUNT(V.patient_id) AS  PATIENTS_COUNT FROM Treatments T
LEFT JOIN
Visits AS V
ON T.treatment_id=V.treatment_id
GROUP BY T.department
ORDER BY COUNT(V.patient_id) DESC
--5)Which treatment type is used most frequently?
SELECT T.treatment_type, COUNT(V.patient_id) AS PATIENTS_COUNT FROM Treatments T
LEFT JOIN
Visits V
ON T.treatment_id=V.treatment_id
GROUP BY T.treatment_type
ORDER BY COUNT(V.patient_id) DESC
--6)Which department generated the highest total treatment cost (revenue)?
SELECT T.department, SUM(V.treatment_cost) AS TOTAL_REVENUE FROM Treatments T
LEFT JOIN
Visits V
ON T.treatment_id=V.treatment_id
GROUP BY T.department
ORDER BY SUM(V.treatment_cost) DESC
--7)Which department has the highest average treatment cost per patient?
SELECT T.department, AVG(V.treatment_cost) AS AVG_TREATMENT_COST FROM Treatments T
LEFT JOIN
Visits V
ON T.treatment_id=V.treatment_id
GROUP BY T.department
ORDER BY AVG(V.treatment_cost) DESC
--8)Which region generated the highest total treatment revenue?
SELECT P.region,SUM(V.treatment_cost)AS TOTAL_REVENUE FROM Patients P
LEFT JOIN
Visits V
ON P.patient_id=V.patient_id
GROUP BY P.region
ORDER BY SUM(V.treatment_cost) DESC
--9)Which month recorded the highest number of patient visits?
SELECT MONTH(V.visit_date)AS MONTH,COUNT(P.patient_id) AS PATIENT_COUNT FROM Visits V
LEFT JOIN 
Patients P
ON V.patient_id=P.patient_id
GROUP BY  MONTH(V.visit_date)
ORDER BY COUNT(P.patient_id) DESC
---OR-----------------
SELECT MONTH(visit_date)AS MONTH,COUNT(patient_id) AS PATIENT_COUNT 
FROM Visits
GROUP BY  MONTH(visit_date)
ORDER BY COUNT(patient_id) DESC
--10)Which patients had the highest treatment cost? (Top 10)
SELECT P.region,T.department,sum(V.treatment_cost)AS TOTAL_COST FROM Patients P
LEFT JOIN
Visits V
ON P.patient_id=V.patient_id
LEFT JOIN
Treatments T
ON T.treatment_id=V.treatment_id
GROUP BY P.patient_id,P.region,T.department
ORDER BY sum(V.treatment_cost) DESC
--11)Which departments have an average treatment cost greater than ₹5,000?
SELECT T.department, AVG(V.treatment_cost) AS AVG_TREATMENT_COST FROM Treatments T
LEFT JOIN
Visits V
ON T.treatment_id=V.treatment_id
GROUP BY T.department
HAVING  AVG(V.treatment_cost)>5000
ORDER BY AVG(V.treatment_cost) DESC
--12)Which departments treated more than 500 patients?
SELECT T.department,COUNT(V.patient_id) AS TOTAL_PATIENTS FROM Treatments T
INNER JOIN
Visits V
ON T.treatment_id=V.treatment_id
GROUP BY T.department
HAVING COUNT(V.patient_id)>500
ORDER BY COUNT(V.patient_id) DESC
--13)Which treatment types have generated a total treatment cost greater than ₹1,000,000?
SELECT T.treatment_type, SUM(V.treatment_cost)AS TOTAL_COST FROM Treatments T
INNER JOIN
Visits V
ON T.treatment_id=V.treatment_id
GROUP BY T.treatment_type
HAVING SUM(V.treatment_cost)>1000000
ORDER BY TOTAL_COST DESC
--14)Classify patients based on their recovery score.
SELECT *FROM Visits
SELECT patient_id,
       recovery_score,
       CASE
           WHEN recovery_score >= 90 THEN 'EXCELLENT'
           WHEN recovery_score >= 70 THEN 'GOOD'
           WHEN recovery_score >= 50 THEN 'AVERAGE'
           ELSE 'POOR'
       END AS Recovery_Status
FROM Visits
SELECT
    MIN(readmission_risk) AS Min_Risk,
    MAX(readmission_risk) AS Max_Risk
FROM Visits
--15)Classify patients based on readmission risk.
SELECT patient_id,readmission_risk,
CASE
WHEN readmission_risk>=0.7 THEN 'HIGH RISK'
WHEN readmission_risk>=0.4 THEN 'MEDIUM RISK'
ELSE 'LOW RISK'
END AS RISK_CATEGORY
FROM Visits
--16)Rank departments by total revenue. 
SELECT T.department,SUM(V.treatment_cost)AS TOTAL_REVENUE,
RANK()OVER(ORDER BY SUM(V.treatment_cost) DESC)AS DEPARTMENT_RNK
FROM Treatments T
LEFT JOIN
Visits V
ON T.treatment_id=V.treatment_id
GROUP BY T.department
--17)Find the Top 3 departments based on total revenue.
WITH CTE AS(
SELECT T.department,SUM(V.treatment_cost)AS TOTAL_REVENUE,
RANK()OVER(ORDER BY SUM(V.treatment_cost) DESC)AS DEPARTMENT_RNK
FROM Treatments T
LEFT JOIN
Visits V
ON T.treatment_id=V.treatment_id
GROUP BY T.department
)
SELECT *FROM CTE 
WHERE DEPARTMENT_RNK<=3
--18)Find the highest treatment cost for each department.
WITH CTE AS(
SELECT T.department,V.patient_id,V.treatment_cost,
RANK()OVER(PARTITION BY department ORDER BY V.treatment_cost DESC)AS RNK
FROM Treatments T
LEFT JOIN
Visits V
ON T.treatment_id=V.treatment_id
)
SELECT *FROM CTE 
WHERE RNK = 1
--19)Find the top 2 highest treatment cost records for each department.
WITH CT AS(
SELECT T.department,V.patient_id,V.treatment_cost,
ROW_NUMBER()OVER(PARTITION BY department ORDER BY V.treatment_cost DESC)AS ROW_NUM
FROM Treatments T
LEFT JOIN
Visits V
ON T.treatment_id=V.treatment_id
)
SELECT *FROM CT
WHERE ROW_NUM<=2
--20)Find the patients whose treatment cost is higher than the average treatment cost.
SELECT T.department,V.patient_id,V.treatment_cost FROM Treatments T
LEFT JOIN
Visits V
ON T.treatment_id=V.treatment_id
WHERE treatment_cost>(
SELECT AVG(treatment_cost)FROM Visits
)
--21)Find the departments whose total revenue is greater than the average revenue of all departments.
SELECT T.department, SUM(V.treatment_cost) AS TOTAL_REVENUE FROM Treatments T
LEFT JOIN
Visits V
ON T.treatment_id=V.treatment_id
GROUP BY T.department
HAVING SUM(V.treatment_cost)>(
SELECT AVG(TOTAL_REVENUE) FROM (
SELECT T.department, SUM(V.treatment_cost) AS TOTAL_REVENUE FROM Treatments T
LEFT JOIN
Visits V
ON T.treatment_id=V.treatment_id
GROUP BY T.department
)AS X
)
---------------------------------------OR--------------
WITH REVENUECTE AS(
SELECT T.department, SUM(V.treatment_cost) AS TOTAL_REVENUE FROM Treatments T
LEFT JOIN
Visits V
ON T.treatment_id=V.treatment_id
GROUP BY T.department
)
SELECT department,TOTAL_REVENUE FROM REVENUECTE
WHERE TOTAL_REVENUE>(
SELECT AVG(TOTAL_REVENUE) FROM REVENUECTE
)
--22)Find patients whose treatment cost is higher than the average treatment cost of their own department.
SELECT T.department,V.patient_id,V.treatment_cost FROM Treatments T
LEFT JOIN
Visits V
ON T.treatment_id=V.treatment_id
WHERE V.treatment_cost>(
SELECT AVG(V1.treatment_cost)AS AVERAGE_COST FROM Visits V1
INNER JOIN
Treatments T1
ON T1.treatment_id=V1.treatment_id
WHERE T1.department=T.department
)
--23)Find patients who have visited the hospital at least once.
SELECT patient_id,region,gender FROM Patients P
WHERE EXISTS(
SELECT 1 FROM Visits V
WHERE P.patient_id=V.patient_id
)
--24)Find patients who have never visited the hospital.
SELECT patient_id,region,gender FROM Patients P
WHERE NOT EXISTS(
SELECT 1 FROM Visits V
WHERE P.patient_id=V.patient_id
)
--25)Identify departments with a high average readmission risk.
SELECT T.department,COUNT(V.Patient_id)AS PATIRNT_COUNT,AVG(V.readmission_risk) AS AVG_readmission_risk FROM Treatments T
INNER JOIN
Visits V
ON T.treatment_id=V.treatment_id
GROUP BY T.department
HAVING AVG(V.readmission_risk)>0.25
ORDER BY AVG(V.readmission_risk)DESC