# SQL Data Warehouse and Analytics Project

A PostgreSQL data warehouse that turns CRM and ERP source files into a layered model for reporting and analysis.

CSV files are loaded into **Bronze**, cleaned and standardized in **Silver**, and published as **Gold** views in a star schema. Analysis and report queries run against Gold.

## Architecture

The warehouse uses a medallion layout. Each layer has a different job, a different audience, and a different way of storing data.

| | Bronze | Silver | Gold |
| --- | --- | --- | --- |
| **Data** | Raw source rows | Cleaned and standardized | Business-ready |
| **Purpose** | Keep a full copy of the source so it can be inspected | Apply the rules found while profiling Bronze | Give analysts a model they can query |
| **Objects** | Tables | Tables | Views |
| **Load** | Full reload: truncate, then insert | Full reload: truncate, then insert | No load. Views read Silver |
| **Transformation** | None | Cleansing, standardization, and enrichment | Integration, aggregation, and business logic |
| **Model** | Same shape as the source files | Same tables, cleaned | Star schema |
| **Audience** | Data engineers | Data analysts and data engineers | Data analysts and business users |

![How Bronze, Silver, and Gold differ](data_warehouse/docs/Screenshot%202026-09-25%20214112.png)

### Gold data model

Gold is a star schema. Sales sit in the center. Customers and products hang off it.

- `gold.dim_customers` — one row per customer
- `gold.dim_products` — one row per current product
- `gold.fact_sales` — one row per order line
- `gold.report_customers` — customer metrics and segments
- `gold.report_products` — product metrics and performance segments

![Gold star schema](data_warehouse/docs/Screenshot%202026-09-25%20212733.png)

`fact_sales.customer_key` points at `dim_customers`. `fact_sales.product_key` points at `dim_products`. Sales amount is quantity times price.

## What this project covers

- **Data architecture.** A PostgreSQL warehouse split into Bronze, Silver, and Gold.
- **ETL.** Load CRM and ERP files into Bronze, transform them in Silver, and publish Gold views.
- **Data modeling.** Customer and product dimensions with a sales fact.
- **Data quality.** Checks for duplicates, missing values, invalid dates, inconsistent codes, and broken relationships.
- **Analytics and reporting.** Exploratory SQL, advanced analysis, and reusable customer and product reports.

## Data sources

Six CSV files feed the warehouse. CRM holds the transactions. ERP fills in details CRM does not have: birth date, gender, country, and product category.

| System | Source file | Bronze table |
| --- | --- | --- |
| CRM | `datasets/source_crm/cust_info.csv` | `bronze.crm_cust_info` |
| CRM | `datasets/source_crm/prd_info.csv` | `bronze.crm_prd_info` |
| CRM | `datasets/source_crm/sales_details.csv` | `bronze.crm_sales_details` |
| ERP | `datasets/source_erp/CUST_AZ12.csv` | `bronze.erp_cust_az12` |
| ERP | `datasets/source_erp/LOC_A101.csv` | `bronze.erp_loc_a101` |
| ERP | `datasets/source_erp/PX_CAT_G1V2.csv` | `bronze.erp_px_cat_g1v2` |

**CRM**

- Customers (`cst_id`, `cst_key`)
- Products, including history (`prd_key`)
- Sales and orders (`prd_key`, `cst_id`)

**ERP**

- Birth date and gender, joined to the customer on `cid`
- Country, joined to the customer on `cid`
- Product category, joined to the product on `id`

![How CRM and ERP tables relate](data_warehouse/docs/Screenshot%202026-09-25%20212704.png)

## Data flow

```text
CRM CSV files ──┐
                ├──> Bronze ──> Silver ──> Gold ──> analysis and reports
ERP CSV files ──┘
```

![Data flow from source files through Bronze, Silver, and Gold](data_warehouse/docs/Screenshot%202026-09-25%20212507.png)

### Bronze

Source files are copied into tables with no cleaning. Bronze is the place to look when a Gold number looks wrong, because it still matches the file.

### Silver

Silver applies the rules found while profiling Bronze: trim text, standardize codes, fix dates, drop duplicates, and repair sales amounts that do not match quantity times price. Every Silver table has a `dwh_create_date` column that records when the row was loaded.

**Customers** (`crm_cust_info`)

- Keep the latest row for each `cst_id`.
- Trim names.
- Map marital status: `S` to Single, `M` to Married.
- Map gender: `F` to Female, `M` to Male.

**Products** (`crm_prd_info`)

- Split the product key into a category id and a product number.
- Map product line: `R` Road, `S` Other Sales, `M` Mountain, `T` Touring.
- Replace a missing cost with `0`.
- Set each version's end date to the day before the next version starts.

**Sales** (`crm_sales_details`)

- Turn `YYYYMMDD` integers into dates, and null out values that are `0` or not eight digits.
- Recalculate sales amount when it is missing, zero, or not equal to quantity times price.
- Derive price from sales and quantity when price is missing or not positive, and avoid dividing by zero.

**ERP customers** (`erp_cust_az12`)

- Remove a leading `NAS` from the customer id so it matches CRM.
- Drop birth dates in the future.
- Standardize gender to Male, Female, or `n/a`.

**ERP locations** (`erp_loc_a101`)

- Remove hyphens from the customer id.
- Map `DE` to Germany and `US` / `USA` to United States. Blank countries become `n/a`.

Product categories (`erp_px_cat_g1v2`) are loaded as they are.

### Gold

Gold joins the cleaned CRM and ERP data into views. There is no separate load step.

**`gold.dim_customers`** combines the CRM customer with ERP gender, birth date, and country. Columns: customer key, customer id, customer number, first name, last name, country, marital status, gender, birth date, and create date. If CRM gender is `n/a`, the ERP gender is used.

**`gold.dim_products`** keeps the current product only (`prd_end_dt` is null). Columns: product key, product id, product number, product name, category, subcategory, maintenance, cost, product line, and start date.

**`gold.fact_sales`** is one row per order line: order number, product key, customer key, order date, shipping date, due date, sales amount, quantity, and price.

## Repository structure

`datasets/source_crm` and `datasets/source_erp` are the files the pipeline loads. `datasets/Bronze`, `datasets/Silver`, and `datasets/Gold` are exported snapshots of the warehouse tables and views.

```text
sql-data-warehouse/
├── datasets/
│   ├── source_crm/
│   │   ├── cust_info.csv
│   │   ├── prd_info.csv
│   │   └── sales_details.csv
│   ├── source_erp/
│   │   ├── CUST_AZ12.csv
│   │   ├── LOC_A101.csv
│   │   └── PX_CAT_G1V2.csv
│   ├── Bronze/
│   ├── Silver/
│   └── Gold/
├── data_analysis/
│   ├── 01_EDA.sql
│   ├── 02_ADV.sql
│   ├── report_customers.sql
│   └── report_products.sql
├── data_warehouse/
│   ├── docs/                 # architecture diagrams
│   └── scripts/
│       ├── init_db.sql
│       ├── bronze/
│       │   ├── create tables bronze.sql
│       │   ├── Load data procedure.sql
│       │   └── testings.sql
│       ├── silver/
│       │   ├── ddl_tables_creation.sql
│       │   ├── load_silver_procedure.sql
│       │   └── testings.sql
│       └── Gold/
│           └── gold_ddl.sql
└── README.md
```

## Requirements

- PostgreSQL 14 or newer
- A client such as `psql` or DBeaver
- Permission to create a database and schemas

The Bronze load uses server-side `COPY`. The CSV files must sit on the database server and be readable by the PostgreSQL service account.

## Setup

**1. Create the database.** Connect to the `postgres` database and run:

```sql
DROP DATABASE IF EXISTS datawarehouse;
CREATE DATABASE datawarehouse;
```

Dropping `datawarehouse` deletes everything in it. Do this only when you want a clean rebuild. The `DROP` inside `init_db.sql` uses the misspelled name `datawarehosue`, so it will not remove an existing `datawarehouse` database. Use the statement above.

**2. Create the schemas.** Connect to `datawarehouse`, then run:

```sql
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;
```

`CREATE SCHEMA` applies to the database you are connected to. Run it after switching to `datawarehouse`.

## Run the pipeline

Run these in order, connected to `datawarehouse`.

**Bronze**

1. `data_warehouse/scripts/bronze/create tables bronze.sql`
2. `data_warehouse/scripts/bronze/Load data procedure.sql`
3. `CALL bronze.load_bronze();`

Before step 3, edit the `COPY` paths in the load procedure so they point at the CSV files in your clone. The procedure currently reads from `C:/sql/dwh_project/datasets/`.

**Silver**

4. `data_warehouse/scripts/silver/ddl_tables_creation.sql`
5. `data_warehouse/scripts/silver/load_silver_procedure.sql`
6. `CALL silver.load_silver();`

**Gold**

7. `data_warehouse/scripts/Gold/gold_ddl.sql`

That script creates the dimension and fact views. You can then query them:

```sql
SELECT * FROM gold.dim_customers;
SELECT * FROM gold.dim_products;
SELECT * FROM gold.fact_sales;
```

**Reports**

8. `data_analysis/report_customers.sql`
9. `data_analysis/report_products.sql`

## Data quality

`bronze/testings.sql` and `silver/testings.sql` are checks, not load steps.

Bronze checks look for problems in the raw files: duplicate keys, missing ids, unwanted spaces, invalid dates, and inconsistent codes. Those queries are expected to return rows. The source data has those issues.

Silver checks confirm the cleaning worked: one row per business key, trimmed text, valid dates, standardized values, and relationships that still hold. After a successful Silver load, those queries should return no unexpected rows. `gold_ddl.sql` also checks that every fact row finds a customer and a product.

## Analytics

Queries in `data_analysis/` run against Gold. Run them one statement at a time.

| Script | What it answers |
| --- | --- |
| `01_EDA.sql` | How many customers, products, and orders exist; date range; total sales and quantity; breakdowns by country, gender, and category; top and bottom products and customers |
| `02_ADV.sql` | How sales move by day, month, and year; running totals and moving averages; whether a product is above its own average and rising or falling; VIP, regular, and new customer counts; each category's share of sales, quantity, and orders |
| `report_customers.sql` | Creates `gold.report_customers` |
| `report_products.sql` | Creates `gold.report_products` |

The exploratory script uses `JOIN`, `GROUP BY`, aggregates, and `DENSE_RANK` / `ROW_NUMBER` for rankings. The advanced script adds `DATE_TRUNC`, `LAG`, windowed running totals, and CTEs for segmentation and part-to-whole percentages.

## Reports

**`gold.report_customers`** is one row per customer. It includes age, age group, segment, recency in months, orders, sales, average order value, quantity, products bought, lifespan in months, and monthly spend.

A customer is **VIP** when their lifespan is at least 12 months and sales are above 5,000. They are **regular** at 12 months or more with sales of 5,000 or less. Everyone else is **new**.

**`gold.report_products`** is one row per product. It includes category, subcategory, cost, lifespan, recency, orders, customers, sales, quantity, average selling price, average order revenue, average monthly revenue, and a performance segment.

A product is a **High Performer** above 50,000 in sales, **Mid Range** from 10,000 to 50,000, and a **Low Performer** below 10,000.

```sql
SELECT customer_segment, COUNT(*)
FROM gold.report_customers
GROUP BY customer_segment;

SELECT product_segment, COUNT(*), SUM(total_sales)
FROM gold.report_products
GROUP BY product_segment;
```

## SQL used in this project

The scripts rely on everyday analytical SQL in PostgreSQL:

- `JOIN` and `LEFT JOIN`, `GROUP BY`, and aggregates
- `CASE`, `COALESCE`, and `NULLIF`
- Common table expressions (`WITH`)
- `ROW_NUMBER`, `DENSE_RANK`, `LAG`, and `LEAD`
- Date functions: `TO_DATE`, `DATE_TRUNC`, `AGE`, and `EXTRACT`
- Views for Gold and reports
- Stored procedures for the Bronze and Silver loads

## Outcome

```text
Source CSV files
       │
       ▼
   Bronze — raw source data
       │
       ▼
   Silver — cleaned and standardized data
       │
       ▼
   Gold — star schema views
       │
       ├── analysis queries
       └── customer and product reports
```

Gold is the layer to query. Bronze and Silver stay in place so the numbers in a report can be traced back to the file they came from.
