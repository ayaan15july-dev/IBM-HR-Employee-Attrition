-- IBM HR Employee Attrition — Data Cleaning
-- Raw messy data loaded into hr_staging via Python (pandas + SQLAlchemy)


-- Checking row count and previewing raw data
select count(*) from hr_staging;
select * from hr_staging limit 20;

-- Finding duplicate EmployeeNumbers
select EmployeeNumber, count(*)
from hr_staging
group by EmployeeNumber
having count(*) > 1;

-- Removing any leftover tables from earlier attempts, then rebuild fresh
drop table if exists hr_clean;
drop table if exists hr_clean_temp;

-- Copying raw data into a working table 
create table hr_clean as
select * from hr_staging;

-- Removing duplicate EmployeeNumbers, keeping first occurrence only
create table hr_clean_temp as
select *,
row_number() over (partition by EmployeeNumber order by EmployeeNumber) as row_num
from hr_clean;

set SQL_SAFE_UPDATES = 0;

delete from hr_clean_temp where row_num > 1;

alter table hr_clean_temp drop column row_num;

drop table hr_clean;
rename table hr_clean_temp to hr_clean;

-- Confirming duplicates removed 
select count(*) from hr_clean;

-- Standardizing OverTime and Attrition (Yes/YES/yes/Y/1 -> Yes, else No)
update hr_clean
set OverTime = case
    when upper(trim(OverTime)) in ('YES','Y','1') then 'Yes'
    else 'No'
end;

update hr_clean
set Attrition = case
    when upper(trim(Attrition)) = 'YES' then 'Yes'
    else 'No'
end;

-- Standardizing Gender and MaritalStatus
update hr_clean
set Gender = case
    when upper(trim(Gender)) = 'MALE' then 'Male'
    when upper(trim(Gender)) = 'FEMALE' then 'Female'
    else Gender
end;

update hr_clean
set MaritalStatus = case
    when upper(trim(MaritalStatus)) = 'SINGLE' then 'Single'
    when upper(trim(MaritalStatus)) = 'MARRIED' then 'Married'
    when upper(trim(MaritalStatus)) = 'DIVORCED' then 'Divorced'
    else MaritalStatus
end;

--  Standardizing Department (fixed typos: Saless, R&D, HR Dept)
update hr_clean
set Department = case
    when upper(trim(Department)) in ('SALES','SALESS') then 'Sales'
    when upper(trim(Department)) in ('RESEARCH & DEVELOPMENT','R&D') then 'Research & Development'
    when upper(trim(Department)) in ('HUMAN RESOURCES','HR DEPT') then 'Human Resources'
    else Department
end;

-- Standardizing JobRole, EducationField, BusinessTravel
update hr_clean
set JobRole = trim(JobRole);

update hr_clean
set EducationField = case
    when upper(trim(EducationField)) = 'MEDICAL' then 'Medical'
    when upper(trim(EducationField)) = 'LIFE SCIENCES' then 'Life Sciences'
    when upper(trim(EducationField)) = 'MARKETING' then 'Marketing'
    when upper(trim(EducationField)) = 'TECHNICAL DEGREE' then 'Technical Degree'
    when upper(trim(EducationField)) = 'HUMAN RESOURCES' then 'Human Resources'
    when upper(trim(EducationField)) = 'OTHER' then 'Other'
    else EducationField
end;

update hr_clean
set BusinessTravel = trim(BusinessTravel);

-- Finding invalid Age values (non-numeric, blank, or unrealistic: <15 or >75)
select distinct Age from hr_clean
where Age not regexp '^[0-9]+$' or Age = '' or cast(Age as unsigned) < 15 or cast(Age as unsigned) > 75;

-- Finding invalid MonthlyIncome values (non-numeric, blank, or <= 0)
select distinct MonthlyIncome from hr_clean
where MonthlyIncome not regexp '^[0-9]+$' or MonthlyIncome = '' or cast(MonthlyIncome as unsigned) <= 0;

-- Setting invalid Age and MonthlyIncome values to NULL
update hr_clean
set Age = NULL
where Age not regexp '^[0-9]+$' or Age = '' or cast(Age as unsigned) < 15 or cast(Age as unsigned) > 75;

update hr_clean
set MonthlyIncome = NULL
where MonthlyIncome not regexp '^[0-9]+$' or MonthlyIncome = '' or cast(MonthlyIncome as unsigned) <= 0;

-- Checking how many NULLs/blanks remain across key columns
select 
    sum(case when Age is null then 1 else 0 end) as null_age,
    sum(case when MonthlyIncome is null then 1 else 0 end) as null_income,
    sum(case when Department is null or Department = '' then 1 else 0 end) as null_dept,
    sum(case when Gender is null or Gender = '' then 1 else 0 end) as null_gender,
    sum(case when JobRole is null or JobRole = '' then 1 else 0 end) as null_jobrole,
    sum(case when YearsAtCompany is null or YearsAtCompany = '' then 1 else 0 end) as null_years,
    sum(case when DistanceFromHome is null or DistanceFromHome = '' then 1 else 0 end) as null_distance
from hr_clean;

-- Filling missing Age and MonthlyIncome with the average (rounded)
update hr_clean
set Age = (select avg_val from (select round(avg(cast(Age as unsigned))) as avg_val from hr_clean where Age is not null) as t)
where Age is null;

update hr_clean
set MonthlyIncome = (select avg_val from (select round(avg(cast(MonthlyIncome as unsigned))) as avg_val from hr_clean where MonthlyIncome is not null) as t)
where MonthlyIncome is null;

-- Filling missing YearsAtCompany and DistanceFromHome with the average
update hr_clean
set YearsAtCompany = (select avg_val from (select round(avg(YearsAtCompany)) as avg_val from hr_clean where YearsAtCompany is not null and YearsAtCompany != '') as t)
where YearsAtCompany is null or YearsAtCompany = '';

update hr_clean
set DistanceFromHome = (select avg_val from (select round(avg(DistanceFromHome)) as avg_val from hr_clean where DistanceFromHome is not null) as t)
where DistanceFromHome is null;

-- Filling missing Department, Gender, JobRole with 'Unknown'
update hr_clean set Department = 'Unknown' where Department is null or Department = '';
update hr_clean set Gender = 'Unknown' where Gender is null or Gender = '';
update hr_clean set JobRole = 'Unknown' where JobRole is null or JobRole = '';

-- Re-checking nulls, all should now be 0
select 
    sum(case when Age is null then 1 else 0 end) as null_age,
    sum(case when MonthlyIncome is null then 1 else 0 end) as null_income,
    sum(case when Department is null or Department = '' then 1 else 0 end) as null_dept,
    sum(case when Gender is null or Gender = '' then 1 else 0 end) as null_gender,
    sum(case when JobRole is null or JobRole = '' then 1 else 0 end) as null_jobrole,
    sum(case when YearsAtCompany is null or YearsAtCompany = '' then 1 else 0 end) as null_years,
    sum(case when DistanceFromHome is null or DistanceFromHome = '' then 1 else 0 end) as null_distance
from hr_clean;

-- Converting key numeric columns from text to proper number types
alter table hr_clean
modify column Age int,
modify column MonthlyIncome int,
modify column DistanceFromHome int,
modify column YearsAtCompany int,
modify column TotalWorkingYears int,
modify column NumCompaniesWorked int,
modify column PercentSalaryHike int,
modify column YearsInCurrentRole int,
modify column YearsSinceLastPromotion int,
modify column YearsWithCurrManager int,
modify column JobLevel int,
modify column JobSatisfaction int,
modify column EnvironmentSatisfaction int,
modify column WorkLifeBalance int,
modify column PerformanceRating int,
modify column StockOptionLevel int;

-- Confirming final structure
describe hr_clean;
