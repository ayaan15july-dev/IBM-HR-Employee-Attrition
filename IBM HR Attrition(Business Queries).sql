-- IBM HR Employee Attrition — Business Analysis Queries
-- Run on cleaned table: hr_clean

use hr_project;

-- Q1. What is the overall attrition rate?
select 
    count(*) as total_employees,
    sum(case when Attrition = 'Yes' then 1 else 0 end) as employees_left,
    round(100 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*), 2) as attrition_rate_pct
from hr_clean;

-- Q2. Which department has the highest attrition rate?
select Department,
    count(*) as total_employees,
    sum(case when Attrition = 'Yes' then 1 else 0 end) as employees_left,
    round(100 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*), 2) as attrition_rate_pct
from hr_clean
group by Department
order by attrition_rate_pct desc;

-- Q3. Does working overtime increase attrition?
select OverTime,
    count(*) as total_employees,
    round(100 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*), 2) as attrition_rate_pct
from hr_clean
group by OverTime;

-- Q4. What is the average monthly income by job role, ranked highest to lowest?
select JobRole,
    round(avg(MonthlyIncome), 2) as avg_income,
    count(*) as num_employees
from hr_clean
group by JobRole
order by avg_income desc;

-- Q5. Do employees who leave have lower job satisfaction on average?
select Attrition,
    round(avg(JobSatisfaction), 2) as avg_job_satisfaction,
    round(avg(EnvironmentSatisfaction), 2) as avg_environment_satisfaction,
    round(avg(WorkLifeBalance), 2) as avg_work_life_balance
from hr_clean
group by Attrition;

-- Q6. Which age group has the highest attrition rate?
with age_groups as (
    select *,
    case
        when Age < 25 then 'Under 25'
        when Age between 25 and 34 then '25-34'
        when Age between 35 and 44 then '35-44'
        when Age between 45 and 54 then '45-54'
        else '55+'
    end as age_group
    from hr_clean
)
select age_group,
    count(*) as total_employees,
    round(100 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*), 2) as attrition_rate_pct
from age_groups
group by age_group
order by attrition_rate_pct desc;

-- Q7. Rank employees by income within each department (top 3 earners per department)
with ranked_income as (
    select Department, JobRole, MonthlyIncome,
    row_number() over (partition by Department order by MonthlyIncome desc) as income_rank
    from hr_clean
)
select Department, JobRole, MonthlyIncome, income_rank
from ranked_income
where income_rank <= 3;

-- Q8. How does attrition trend across tenure (years at company) brackets?
with tenure_groups as (
    select *,
    case
        when YearsAtCompany <= 2 then '0-2 years'
        when YearsAtCompany between 3 and 5 then '3-5 years'
        when YearsAtCompany between 6 and 10 then '6-10 years'
        else '10+ years'
    end as tenure_bracket
    from hr_clean
)
select tenure_bracket,
    count(*) as total_employees,
    round(100 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*), 2) as attrition_rate_pct
from tenure_groups
group by tenure_bracket
order by min(YearsAtCompany);

-- Q9. Compare average income between employees who left vs stayed, by department
select Department, Attrition,
    round(avg(MonthlyIncome), 2) as avg_income,
    count(*) as num_employees
from hr_clean
group by Department, Attrition
order by Department, Attrition;

-- Q10. Which employees are highest attrition risk? (Low satisfaction + OverTime + low tenure)
select EmployeeNumber, Department, JobRole, JobSatisfaction, OverTime, YearsAtCompany, Attrition
from hr_clean
where JobSatisfaction <= 2
    and OverTime = 'Yes'
    and YearsAtCompany <= 3
order by JobSatisfaction asc, YearsAtCompany asc;