use banking;

select count(*) from customers;

select count(distinct loan_status) from loans ;
select distinct loan_status from loans;
select count(*) from loans as active_loan where loan_status = 'Active' ;
select count(*) from loans where loan_status = 'Closed';
select count(*) from loans where loan_status = 'Pending Approval';
select count(*) from loans where loan_status = 'Defaulted';
select count(*) from loans where loan_status = 'Restructured';

select customer_id from loans where loan_status = 'Active' limit 5;
select customer_id from loans where loan_status = 'Closed' limit 5;
select customer_id from loans where loan_status = 'Pending Approval' limit 5;
select customer_id from loans where loan_status = 'Defaulted' limit 5;
select customer_id from loans where loan_status = 'Restructured' limit 5;

select
round(max(loan_amount),2) as MAX_LOAN_AMT,
round(min(loan_amount),2) as MIN_LOAN_AMT, 
round(avg(loan_amount),2) as AVG_LOAN_AMT
from loans;

select loan_status, count(*) as LOAN_GROUPS from loans group by loan_status;
select loan_status, count(*) as LOAN_GROUPS from loans group by loan_status having COUNT(*) > 30;

select loan_status, count(*) as Loan_grp_desc 
from loans group by loan_status 
having count(*) > 30 
order by loan_status desc;

SELECT loan_status, COUNT(*) AS loan_groups 
FROM loans 
GROUP BY loan_status 
HAVING loan_status = 'Active';

select customer_id, loan_status, loan_amount
from loans where loan_status = 'Active' and loan_amount > 50000;


