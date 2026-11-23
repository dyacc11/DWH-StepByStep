# DWH Step By Step: Part 3 - A Simple Data Pipeline

This repository contains the source code and materials for the third part of the "DWH Step By Step" article series. It is dedicated to implementing the medallion architecture in a single SQLite database to prove the concept and implement base algorithms when clean test data is used.

## Repository Structure

```mermaid
---
config:
  treeView:
    showIcons: true
---
treeView-beta
  Part_03/
    docs/
      Part03.md
    img/
    src/
      test_by_entity/
         01_Product.sql
         02_Customer.sql
         03_Sales.sql
      test_all_entities/
         dwh_pipeline.sql
      simple_dwh.db
      simple_dwh_ddl.sql
    README.md
```

### Directory and File Description

- **docs/** - Full article documentation in Markdown format, detailing the architectural decisions and step-by-step implementation.
- **img/** - Images used to illustrate the article.
- **src/** - Organized SQL scripts for testing the pipeline:
  - `simple_dwh.db` - A ready-to-use SQLite database file containing both the data simulator (from Part 2) and the fully implemented DWH zones (Bronze, Silver and Gold), along with the cleanup trigger. You can open it directly in any SQLite client to start testing immediately without running any scripts.
  - `simple_dwh_ddl.sql` - The complete SQL script containing DDL for the DWH objects (tables, unique indexes, cleanup triggers, and views). *Note: This script only creates the DWH layer and assumes the simulator objects already exist.*
  - `test_by_entity/`: Scripts for debugging the pipeline one entity (Product, Customer, or Sales) at a time.
  - `test_all_entities/`: Scripts for testing the full pipeline execution and simultaneous loading of all entities.
- **README.md** - This file.

## Pipeline Setup and Testing Workflow

To test the ETL/ELT logic, zone transformations, and dependency handling, you have two options. The recommended approach is to use the pre-built database:

### Option 1: Use the Ready-Made Database (Recommended)
1. **Open the database**
   - Open the `simple_dwh.db` file in your preferred SQLite client (e.g., DB Browser for SQLite, DBeaver, DataGrip, or via SQLite CLI). The data simulator is already included, so no additional setup is required.
2. **Test a Specific Scenario**
   - Update the active scenario in the singleton control table. For example, to test the initial full load of all entities:
     ```sql
     UPDATE simCurrentLoadScenario SET tls_id = 11;
     ```
3. **Verify the Output**
   - Query the endpoint views in the "Gold" zone to ensure they return the correct, expected business-ready data:
     ```sql
     SELECT * FROM dimProduct;
     SELECT * FROM dimCustomer;
     SELECT * FROM factSales;
     ```
4. **Test Incremental Loads and Resets**
   - Switch to incremental scenarios (e.g., `tls_id = 12` or `13`) to verify that the `UPSERT` logic correctly updates existing records and inserts new ones based on the `HDIFF`/`HKEY` checks.
   - Use the reserved clear scenario (`tls_id = 10`) to trigger the `AFTER UPDATE` cleanup trigger, which instantly wipes the `RAW` and `REF` tables, allowing you to reset the target database state before running a full test cycle again.

### Option 2: Reproduce from Scratch (Optional)
If you want to build the pipeline manually to study the code execution flow:
1. Create a new, empty SQLite database.
2. Execute the `data_simulator.sql` script from [Part 2](../Part_02/) of this series to create and populate the underlying simulator tables and views.
3. Execute the `src/simple_dwh_ddl.sql` script to create the DWH tables, indexes, triggers, and views on top of the simulator.
4. Proceed with steps 2-4 from Option 1 to verify the results.

## Full Documentation

The complete article with detailed explanations, SQL code, field mapping tables, and pipeline diagrams is available at:

**[docs/Part03.md](./docs/Part03.md)**

## Related Links

- **Part 1 of this series:** [DWH Step By Step: Part 1 - Data Correction and Generation](../Part_01/README.md)
- **Part 2 of this series:** [DWH Step By Step: Part 2 - Data Simulation and Small Test Datasets](../Part_02/README.md)
- Original project by Baraa Khatib Salkini: [sql-data-warehouse-project](https://github.com/DataWithBaraa/sql-data-warehouse-project)

---

*This material is part of a practical guide on building a Data Warehouse and its ETL pipelines, progressing from foundational concepts to advanced, production-ready implementations.*
