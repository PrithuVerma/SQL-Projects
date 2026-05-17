create database BankChurn;
use BankChurn;

select * from bankchurn limit 5;
# 1. GEOGRAPHY OF CUSTOMERS
select 
	count(*) as customers,
    country from Bankchurn
group by country
order by country;

# 2. COUNT OF CREDIT CARD HOLDERS
select count(*) as CC_Holders
from bankchurn
where credit_card = 1;

# 3. COUNT OF ACTIVE MEMBERS
select 
	count(*) as Active_Members
    from bankchurn
    where active_member = 1;
    
# 4. OVERALL CHURN RATE
Select
	ROUND(count(case when churn = 1 then 1.0 end) * 100 / count(*),2) as churn_rate
    from bankchurn;

# 5. CHURN RATE BY GEOGRAPHY
Select
	COUNTRY AS location,
	ROUND(count(case when churn = 1 then 1.0 end) * 100 / count(*),2) as churn_rate
    from bankchurn
    group by country
    order by churn_rate desc;

# 6. AVERAGE CREDIT SCORE BY COUNTRY
SELECT COUNTRY,GENDER, ROUND(AVG(CREDIT_SCORE),2) AS Avg_CC_Score
FROM BANKCHURN 
GROUP BY COUNTRY,GENDER;

# 7. COUNTRY WITH MOST ACTIVE MEMBERS
SELECT COUNTRY,GENDER, COUNT(*) AS Members
FROM BANKCHURN
WHERE ACTIVE_MEMBER = 1
GROUP BY COUNTRY,GENDER;

# 8. COUNTRY WITH THE MOST CC HOLDERS
SELECT COUNTRY,GENDER, COUNT(*) AS Members
FROM BANKCHURN
WHERE CREDIT_CARD = 1
GROUP BY COUNTRY,GENDER;

# 9. AVERAGE CREDT SCORE OF CHURNED VS NON-CHURNED
SELECT 
    CASE 
        WHEN Churn = 1 THEN 'Yes'
        WHEN Churn = 0 THEN 'No'
    END AS churn_status,
    ROUND(AVG(Credit_Score),2) AS avg_credit_score

FROM BankChurn
GROUP BY churn_status;

# 10. ACTIVE STATUS OF CHURNED CUSTOMERS
select
	case
		when active_member = 1 Then 'Active'
		when active_member = 0 then 'Inactive'
    end as Active_status,
    round(count(*) * 100.0/
		(
			select count(*) from bankchurn
			where churn = 1
        ),
        2) as Percentage
from bankchurn 
where churn = 1 
group by Active_status;

SELECT 
    CASE
        WHEN active_member = 1 THEN 'Active'
        WHEN active_member = 0 THEN 'Inactive'
    END AS active_status,
    COUNT(*) AS customers,
    ROUND(
        COUNT(*) * 100.0 / 
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM bankchurn
WHERE churn = 1
GROUP BY active_status;

# 10. AVG BALANCE OF CUSTOMERS GROPED BY NUMBER OF PRODUCES? DO CUSTOMERS WITH MORE PRODUCT HAVE HIGHER BALANCE?
SELECT round(avg(BALANCE),2) AS Avg_Balance , COUNT(*) AS CUSTOMERS, PRODUCTS_NUMBER
FROM BANKCHURN 
GROUP BY PRODUCTS_NUMBER
order by avg_balance desc;

# 11. COUNT OF CUSTOMERS WITH 0 BALANCE AND HAVE CHURNED
SELECT 
    COUNT(*) AS churned_customers
FROM BankChurn
WHERE Balance = 0
AND Churn = 1;

# 12. AGE BUCKETS AND CHURN RATE FOR EACH BUCKET
SELECT CASE 
	WHEN AGE < 30 THEN 'YOUNG'
    WHEN AGE BETWEEN 30 AND 45 THEN 'MIDDLE AGED'
    WHEN AGE BETWEEN 45 AND 60 THEN 'SENIOR'
    WHEN AGE > 60 THEN 'RETIRED'
    END AS AGE_BUCKET,
ROUND(COUNT(CASE WHEN CHURN = 1 THEN 1.0 END) * 100/ COUNT(*),2) AS CHURN_RATE,
COUNT(*) AS CUSTOMERS
FROM BANKCHURN
GROUP BY AGE_BUCKET
ORDER BY CHURN_RATE DESC;

# 13. TOP 3 CUSTOMERS BY EACH COUNTRY RANKED BY BALANCE 
WITH T3_RANK AS (
	SELECT customer_id,COUNTRY,BALANCE,
    RANK() OVER(PARTITION BY COUNTRY ORDER BY BALANCE desc) AS RANKING
	FROM BANKCHURN
)
SELECT * FROM T3_RANK WHERE RANKING <=3;

SELECT *
FROM (
    SELECT 
        Customer_Id,
        Country,
        Balance,
        RANK() OVER (
            PARTITION BY Country
            ORDER BY Balance DESC
        ) AS ranking
    FROM BankChurn
) t

WHERE ranking <= 3;

# 14. CUSTOMERS WHOSE CREDIT SCORE IS BELOW AVERAGE OF THEIR OWN COUNTRY
WITH AVG_SCC AS (
	SELECT 
    AVG(CREDIT_SCORE) AS AVG_CNT_SC, COUNTRY
	FROM BANKCHURN
	GROUP BY COUNTRY
    )

SELECT COUNT(*) AS CUSTOMERS
FROM BANKCHURN B
JOIN AVG_SCC A
ON B.COUNTRY = A.COUNTRY
WHERE B.CREDIT_SCORE < A.AVG_CNT_SC;




