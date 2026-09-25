# SQL Data Warehouse

A PostgreSQL data warehouse that turns CRM and ERP extracts into a star schema for reporting. Source files land as-is, get cleaned, then become customer, product, and sales objects you can query.

The pipeline uses a medallion layout:

| Layer | Role | Objects |
| --- | --- | --- |
| **Bronze** | Raw copy of each source file | Tables |
| **Silver** | Cleaned, typed, and deduplicated records | Tables |
| **Gold** | Business model for analysis | Views |

Gold is a star schema: `dim_customers` and `dim_products` around `fact_sales`, plus two report views.

## Sources

Six CSV files under `datasets/`:

| System | File | Lands in |
| --- | --- | --- |
| CRM | `source_crm/cust_info.csv` | `bronze.crm_cust_info` |
| CRM | `source_crm/prd_info.csv` | `bronze.crm_prd_info` |
| CRM | `source_crm/sales_details.csv` | `bronze.crm_sales_details` |
| ERP | `source_erp/CUST_AZ12.csv` | `bronze.erp_cust_az12` |
| ERP | `source_erp/LOC_A101.csv` | `bronze.erp_loc_a101` |
| ERP | `source_erp/PX_CAT_G1V2.csv` | `bronze.erp_px_cat_g1v2` |

CRM holds customers, products, and sales. ERP holds birth dates and gender, country, and product category.

## What each layer does

**Bronze** truncates each table and reloads it with `COPY`. Nothing is cleaned here.

**Silver** (`silver.load_silver`) applies the rules found while profiling bronze:

- Keep the latest customer row per `cst_id`, trim names, and map marital status and gender codes (`S`/`M`, `F`/`M`).
- Split the product key into a category id and a product number, map product lines (`R`, `S`, `M`, `T`), fill missing cost with `0`, and close each product version the day before the next one starts.
- Turn `YYYYMMDD` sales dates into real dates, and repair sales amount and price when they are missing, zero, or inconsistent with quantity.
- Strip the `NAS` prefix from ERP customer ids, drop birth dates in the future, and standardize gender.
- Remove hyphens from location ids and map country codes (`DE`, `US`, `USA`) to full names.

Each silver table also stores `dwh_create_date`.

**Gold** builds:

- `gold.dim_customers` — CRM customer, plus country and a gender that falls back to the ERP value when CRM is `n/a`.
- `gold.dim_products` — current products only (`prd_end_dt` is null), with category, subcategory, and maintenance.
- `gold.fact_sales` — one row per order line, joined to the customer and product surrogate keys.

## Repository layout

```text
sql-data-warehouse/
├── datasets/
│   ├── source_crm/
│   └── source_erp/
├── data_warehouse/scripts/
│   ├── init_db.sql
│   ├── bronze/          # table DDL, load procedure, quality checks
│   ├── silver/          # table DDL, load procedure, quality checks
│   └── Gold/gold_ddl.sql
└── data_analysis/
    ├── 01_EDA.sql
    ├── 02_ADV.sql
    ├── report_customers.sql
    └── report_products.sql
```

Quality scripts in `bronze/testings.sql` and `silver/testings.sql` are checks, not load steps. Bronze checks are expected to return dirty rows. Silver checks are expected to return none.

## Requirements

- PostgreSQL 14 or newer (`TO_DATE`, procedures, and `COPY` are used throughout).
- A role that can create a database and read server-side files (`COPY ... FROM` runs on the database server, so the CSVs must be on that machine and readable by the PostgreSQL service account).

## Setup

`data_warehouse/scripts/init_db.sql` is the starting point: it creates the `datawarehouse` database and the `bronze`, `silver`, and `gold` schemas. Run it in two steps. `CREATE SCHEMA` applies to the database you are connected to, so create the database from `postgres`, then connect to `datawarehouse` before creating the schemas. In `psql`:

```sql
DROP DATABASE IF EXISTS datawarehouse;
CREATE DATABASE datawarehouse;
\c datawarehouse
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;
```

The `DROP` in `init_db.sql` targets the misspelled name `datawarehosue`, so it will not remove an existing `datawarehouse` database. Use the `DROP` above if you want a clean rebuild. That deletes every object in `datawarehouse`.

Before loading bronze, open `data_warehouse/scripts/bronze/Load data procedure.sql` and point each `COPY` path at this clone. The procedure currently reads from `C:/sql/dwh_project/datasets/...`. On this machine the files are under `datasets/` in the repository root. Use forward slashes in the path.

Then run the scripts in this order, connected to `datawarehouse`:

```text
1. data_warehouse/scripts/bronze/create tables bronze.sql
2. data_warehouse/scripts/bronze/Load data procedure.sql
3. CALL bronze.load_bronze();

4. data_warehouse/scripts/silver/ddl_tables_creation.sql
5. data_warehouse/scripts/silver/load_silver_procedure.sql
6. CALL silver.load_silver();

7. data_warehouse/scripts/Gold/gold_ddl.sql
8. data_analysis/report_customers.sql
9. data_analysis/report_products.sql
```

`gold_ddl.sql` mixes view definitions with check queries. Run the whole file, or run each `CREATE OR REPLACE VIEW` on its own. After it finishes you can query:

```sql
SELECT * FROM gold.dim_customers;
SELECT * FROM gold.dim_products;
SELECT * FROM gold.fact_sales;
```

## Analysis

`data_analysis/` queries the gold layer. Run statements one at a time.

| Script | What it covers |
| --- | --- |
| `01_EDA.sql` | Row counts, date ranges, sales measures, breakdowns by country, gender, and category, and top and bottom products and customers |
| `02_ADV.sql` | Sales over time, running totals and moving averages, year-over-year product performance, VIP / regular / new customer segments, and category share of sales |
| `report_customers.sql` | View `gold.report_customers`: age group, segment (VIP if lifespan is at least 12 months and sales exceed 5,000), recency, average order value, and monthly spend |
| `report_products.sql` | View `gold.report_products`: High Performer / Mid Range / Low Performer by revenue, recency, average order revenue, and average monthly revenue |

```sql
SELECT customer_segment, COUNT(*)
FROM gold.report_customers
GROUP BY customer_segment;

SELECT product_segment, COUNT(*), SUM(total_sales)
FROM gold.report_products
GROUP BY product_segment;
```
