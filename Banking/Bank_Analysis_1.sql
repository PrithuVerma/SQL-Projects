create database BANKING;
USE BANKING;

SELECT * FROM accounts limit 5;
SELECT * FROM branches limit 5;
SELECT * FROM customers limit 5;
SELECT * FROM loans limit 5;
SELECT * FROM transactions limit 5;

-- >>>>>>>>>APPLYING PRIMARY KEY CONTRAINT TO ALL THE TABLES<<<<<<<< --
alter table accounts
add constraint pk_aid primary key(account_id);
describe accounts;

alter table branches
add constraint pk_bid primary key(branch_id);
describe branches;

alter table customers
add constraint pk_cid primary key(customer_id);
describe customers;

alter table loans
add constraint pk_lid primary key(loan_id);
describe loans;

alter table transactions
add constraint pk_tid primary key(transaction_id);
describe transactions;

-- >>>>>>>>>APPLYING FOREIGN KEY CONTRAINT TO THE TABLES<<<<<<<< --

alter table accounts
	add constraint fk_cid 
		foreign key(customer_id) references customers(customer_id),
	add constraint fk_bid 
		foreign key(branch_id) references branches(branch_id);
SHOW CREATE TABLE accounts;

alter table loans
	add constraint fk_cid_loan foreign key(customer_id) references customers(customer_id);
show create table loans;

alter table transactions
add constraint fk_aid foreign key(account_id) references accounts(account_id);
show create table transactions;





