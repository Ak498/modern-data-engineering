/*============================================================
   WEEK 3 — DIMENSIONAL MODEL
   Domain: Loan Process
============================================================*/

------------------------------------------------------------
-- DIMENSION TABLES
------------------------------------------------------------

CREATE TABLE dim_customer (
    customer_id VARCHAR(50) PRIMARY KEY,
    full_name VARCHAR(200),
    date_of_birth DATE,
    risk_segment VARCHAR(50),
    employment_status VARCHAR(50),
    effective_start_date DATE,
    effective_end_date DATE,
    is_current BIT
);

------------------------------------------------------------

CREATE TABLE dim_employee (
    employee_id INT IDENTITY PRIMARY KEY,
    employee_code VARCHAR(50) NOT NULL,
    role VARCHAR(100),
    branch VARCHAR(100),
    department VARCHAR(100)
);

------------------------------------------------------------

CREATE TABLE dim_date (
    date_id INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day INT,
    month INT,
    year INT,
    quarter INT,
    is_weekend BIT
);

------------------------------------------------------------

CREATE TABLE dim_medium (
    medium_id INT IDENTITY PRIMARY KEY,
    medium_name VARCHAR(100) NOT NULL
);

------------------------------------------------------------
-- FACT TABLES
------------------------------------------------------------

CREATE TABLE fact_loan (
    loan_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    employee_id INT NOT NULL,
    date_id INT NOT NULL,
    medium_id INT NOT NULL,
    loan_amount DECIMAL(18,2) NOT NULL,
    approved_amount DECIMAL(18,2),
    interest_rate DECIMAL(5,4),
    tenure_months INT,
    
    CONSTRAINT fk_loan_customer
        FOREIGN KEY (customer_id)
        REFERENCES dim_customer(customer_id),

    CONSTRAINT fk_loan_employee
        FOREIGN KEY (employee_id)
        REFERENCES dim_employee(employee_id),

    CONSTRAINT fk_loan_date
        FOREIGN KEY (date_id)
        REFERENCES dim_date(date_id),

    CONSTRAINT fk_loan_medium
        FOREIGN KEY (medium_id)
        REFERENCES dim_medium(medium_id)
);

------------------------------------------------------------

CREATE TABLE fact_repayment (
    repayment_id VARCHAR(50) PRIMARY KEY,
    loan_id VARCHAR(50) NOT NULL,
    date_id INT NOT NULL,
    medium_id INT NOT NULL,
    repayment_amount DECIMAL(18,2) NOT NULL,
    principal_component DECIMAL(18,2),
    interest_component DECIMAL(18,2),
    penalty_amount DECIMAL(18,2),

    CONSTRAINT fk_repayment_loan
        FOREIGN KEY (loan_id)
        REFERENCES fact_loan(loan_id),

    CONSTRAINT fk_repayment_date
        FOREIGN KEY (date_id)
        REFERENCES dim_date(date_id),

    CONSTRAINT fk_repayment_medium
        FOREIGN KEY (medium_id)
        REFERENCES dim_medium(medium_id)
);
