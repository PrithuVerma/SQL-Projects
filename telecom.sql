create database TELECOM;
USE TELECOM;

SELECT * FROM TELECOM LIMIT 5;

# 1. GENDER DISTRIBUTION
select gender,count(*) as total 
from telecom
group by gender;

# 2. COUNT OF SENIOR CITOZEN
select count(*) as SC
from telecom
where SeniorCitizen = 1;

# 3. COUNT OF MARRRIED PEOPLE
select count(Partner)
from telecom
where Partner = 'Yes';

# 4. AVERAGE TENURE
select round(avg(tenure),2) as Avg_Tenure
from telecom;

# 5. DISTRIBUTION OF SERVICES
select count(*), InternetService as IntSer
from telecom
group by IntSer; 

# 6. DISTRIBUTION OF CONTRACT
select count(*), Contract
from telecom 
group by contract;

# 7. OVERALL CHURN RATE
select
count(case when churn = 'Yes' then 1 end)* 100/count(*) as Churn_Rate
from telecom;

# 8. CUSTOMERS ON EACH CONTARCT TYPE
select count(*) as Customer_Count,contract from telecom
group by contract;

# 9. AVG MONTHLY CHARGE FOR CHURNED VS NON-CHURNED
select
    round(avg(case when churn = 'Yes' then totalcharges end),2) AS churned_avg,
    round(avg(case when churn = 'No' then totalcharges end),2) AS nonchurned_avg
from telecom;

# 10. SENIOR CITIZENS COUNT WITH THEIR CHURN RATE
SELECT 
    COUNT(*) AS SC,
    COUNT(CASE WHEN churn = 'Yes' THEN 1 END) * 100.0 / COUNT(*) AS SC_ChurnRate
FROM telecom
WHERE SeniorCitizen = 1;

# 11. PAYMENT METHOD WITH THE HIGHEST CHURN RATE
Select 
round(count(case when churn = 'Yes' then 1 end )* 100.0/count(*),2) as Churn_Rate,
paymentmethod
from telecom
group by paymentmethod;

# 12. DO COSTUMER WITH FIBRE OPTIC INTERNET CABLE CHURN MORE THAN DSL COSTUMER?
SELECT 
	COUNT(*) as Total_Customers,
    INTERNETSERVICE,
	ROUND(
		COUNT(CASE WHEN CHURN = 'YES' THEN 1 END)*100.0/COUNT(*),
        2) 
        AS Churn_rate
FROM TELECOM
WHERE INTERNETSERVICE IN ('DSL','Fiber optic')
GROUP BY INTERNETSERVICE;

# 13. WHAT IS THE AVG TENURE OF CHURNED VS RETAINED CUSTOMERS ? 
SELECT 
    Churn,
    COUNT(*) AS customers,
    AVG(Tenure) AS avg_tenure
FROM telecom
GROUP BY Churn;

# 14. AMONG CUSTOMERS WHO CHURNED, WHAT % HAD NO OnlineSecurty OR TechSupport
SELECT 
    COUNT(*) AS customers,
    ROUND(AVG(CASE WHEN OnlineSecurity = 'No' THEN 1.0 ELSE 0 END) * 100, 2) as No_Security_Rate,
    ROUND(AVG(CASE WHEN TechSupport = 'No' THEN 1.0 ELSE 0 END) * 100, 2) as No_TechSupport_Rate
FROM telecom
WHERE Churn = 'Yes';

# 15. CUSTOMERS BY TENURE BUCKET (1-72 MONTHS), WHICH BUCKET CHURN THE MOST
select count(*) as customers,
case 
	when tenure between 1 and 12 then 'Year 1'
	when Tenure between 13 and 24 then 'Year 2'
    when tenure between 25 and 36 then 'Year 3'
    when tenure between 37 and 48 then 'Year 4'
    when Tenure between 49 and 60 then 'Year 5'
    when Tenure between 61 and 72 then 'Year 6'
    end as Tenure_Bucket,
round(count(case when churn = 'Yes' then 1 end) * 100.0 / count(*),2) as churn_rate
from telecom
group by Tenure_Bucket
order by Tenure_Bucket asc;

select 
	floor((tenure - 1)/12)+1 as Tenure_Bucket,
    round(count(case when churn = 'Yes' then 1 end) * 100.0/count(*),2) as churn_rate,
    count(*) as customers
from telecom 
group by Tenure_Bucket;

# 16. FOR MONTH-TO-MONTH WHAT COMBINATION OF SERVICES LEADS TO HIGHEST CHURN
select internetservice,
	onlinesecurity,
    techsupport,
    count(*) as customers,
    count(case when churn = 'Yes' then 1.0 else 0 end) * 100 / count(*) as churn_rate
    from telecom 
    where contract = 'Month-To-Month'
group by internetservice,
	onlinesecurity,
    techsupport
order by churn_rate desc;

# 17. RANK CUSTOMER BY TOTAL CHARGES WITHIN EACH CONTRACT TYPE
select 
	customerid,
    contract,
    totalcharges,
rank() over ( Partition by Contract order by TotalCharges desc) as customer_rank
from telecom;

select * 
from(
	select 
		customerid,
		contract,
		totalcharges,
		rank() over (
			Partition by Contract
			order by TotalCharges desc
			) as ranking
	from telecom 
) as T
where ranking <=5
order by ranking desc;


with T as (
	select customerid, contract, totalcharges,
    dense_rank() over (Partition by Contract order by Totalcharges desc) as Ranking
    from telecom
    )

select * from T 
where ranking <=5
order by ranking desc;

# 18. REVENUE AT RISK -> SUM OF MonthlyCharges FOR ALL CHURNED CUSTOMERS
select round(sum(MonthlyCharges),2) as MonthlyCharges, count(*) as customers
from telecom 
where churn = 'Yes'





