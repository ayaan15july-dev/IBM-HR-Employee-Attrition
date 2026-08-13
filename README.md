# IBM HR Employee Attrition Analysis

End-to-end data analytics project: cleaning a messy HR dataset in MySQL, writing business-focused SQL queries, and building an interactive Power BI dashboard to uncover employee attrition drivers.

## Overview

Using the IBM HR Analytics Employee Attrition dataset (1,470 employee records), I intentionally introduced realistic data quality issues — duplicate records, missing values, inconsistent text formatting, and invalid entries — to simulate a real-world messy source system. I then cleaned and analyzed the data entirely in SQL, and built a dashboard to surface actionable attrition insights.

## Tools Used

- **MySQL** — data cleaning, transformation, and business analysis queries
- **Python (pandas, SQLAlchemy)** — loading data into MySQL
- **Power BI** — interactive dashboard and visualization

## Workflow

1. **Data Preparation** — Generated a deliberately messy version of the dataset (duplicate rows, ~40 duplicate employee IDs, missing values across 7 columns, inconsistent category labels, invalid numeric entries) to practice real-world data cleaning.
2. **Data Cleaning (SQL)**
   - Removed duplicate records using `ROW_NUMBER()` window functions (exact-row `DISTINCT` was insufficient since duplicates had inconsistent formatting)
   - Standardized inconsistent text (casing, whitespace, typos) across Department, Gender, MaritalStatus, OverTime, Attrition, and EducationField
   - Identified and handled invalid numeric entries (negative ages, non-numeric values) by converting to `NULL` and imputing with column averages
   - Preserved missing categorical values as `'Unknown'` rather than guessing, to avoid introducing bias
   - Converted all columns from staging `VARCHAR` to proper numeric types post-cleaning
3. **Business Analysis (SQL)** — Wrote 10+ queries answering key HR questions: attrition rate by department, income by job role, attrition risk by tenure/age cohort, and a multi-condition "attrition risk" query combining satisfaction, overtime, and tenure.
4. **Dashboard (Power BI)** — Connected directly to the cleaned MySQL table and built an interactive dashboard with KPI cards, department/tenure/income breakdowns, and attrition trend visuals.

## Key Findings

- Overall attrition rate: **16.14%**
- Employees working overtime show a **significantly higher attrition rate** than those who don't
- Attrition is highest among employees in their **first 0-2 years** of tenure
- Employees who leave report **lower average job satisfaction** than those who stay

## Files

- [SQL/IBM HR Attrition(cleaned data).sql](<SQL/IBM HR Attrition(cleaned data).sql>) — full data cleaning script (MySQL)
- [SQL/IBM HR Attrition(Business Queries).sql](<SQL/IBM HR Attrition(Business Queries).sql>) — business analysis queries (MySQL)
- [Power BI/IBM HR Attrition.pbix](<Power BI/IBM HR Attrition.pbix>) — Power BI dashboard file

## Dashboard Preview

![Dashboard Preview](<Power BI/IBM HR Attrition Dashboard.png>)

## Skills Demonstrated

SQL data cleaning, window functions (`ROW_NUMBER`, `PARTITION BY`), CTEs, data type conversion, Python-to-MySQL data pipelines, DAX measures, and Power BI dashboard design.
