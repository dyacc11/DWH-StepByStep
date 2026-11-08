# DWH Step By Step: Part 2 - Data Simulation and Small Test Datasets

This repository contains the source code and materials for the second part of the "DWH Step By Step" article series, dedicated to creating a data simulator and small, manageable test datasets for debugging ETL pipelines.

## Repository Structure

```mermaid
---
config:
  treeView:
    showIcons: true
---
treeView-beta
  Part_02/
    data_simulator.db
    data_simulator.sql
    docs/
      Part02.md
    img/
      part2_title.png
      part2_diagram1.png
      part2_diagram2.png
      part2_diagram3.png
      part2_diagram4.png
      part2_diagram5.png
      part2_diagram6.png
      part2_diagram7.png
      part2_diagram8.png
      part2_diagram9.png
      part2_diagram10.png
      part2_diagram11.png
    README.md
```

### Directory and File Description

- **data_simulator.db** - A ready-to-use SQLite database file containing all tables, views, and pre-populated test data. You can open it directly in any SQLite client to start testing immediately without running any scripts.
- **data_simulator.sql** - The complete SQL script containing DDL, DML, and Views. It is provided for reference, educational purposes, or if you wish to reproduce the simulator setup from scratch.
- **docs/** - Full article documentation in Markdown format.
- **img/** - Images and diagrams used to illustrate the article (simulator architecture, test scenario matrices, and spreadsheet visualizations).
- **README.md** - This file.

## Simulator Setup and Testing Workflow

To test the ETL logic switching, you have two options. The recommended approach is to use the pre-built database:

### Option 1: Use the Ready-Made Database (Recommended)
1. **Open the database**
   - Open the `data_simulator.db` file in your preferred SQLite client (e.g., DB Browser for SQLite, DBeaver, DataGrip, or via SQLite CLI).
2. **Test a Specific Scenario**
   - Update the active scenario in the singleton control table. For example, to test the initial load of all data:
     ```sql
     UPDATE simCurrentLoadScenario SET tls_id = 11;
     ```
3. **Verify the Output**
   - Query the endpoint views to ensure they return the correct, expected subset of data for the chosen scenario:
     ```sql
     SELECT * FROM simCustomer;
     SELECT * FROM simProduct;
     SELECT * FROM simSales;
     ```
4. **Test Incremental Loads and Resets**
   - Switch to incremental scenarios (e.g., `tls_id = 12` or `13`) to verify SCD Type 1 and Type 2 logic.
   - Use the clear scenario (`tls_id = 10`) to reset the target database state before running a full test cycle again.

### Option 2: Reproduce from Scratch (Optional)
If you want to build the simulator manually to study the code:
1. Create a new, empty SQLite database.
2. Execute the DDL and DML statements from `data_simulator.sql` to create and populate the underlying data tables.
3. Execute the `CREATE VIEW` statements from the same file to set up the `simCustomer`, `simProduct`, and `simSales` endpoints.
4. Proceed with steps 2–4 from Option 1.

## Full Documentation

The complete article with detailed explanations, SQL code, bitmask logic, and diagrams is available at:

**[docs/Part02.md](./docs/Part02.md)**

## Related Links

- **Part 1 of this series:** [DWH Step By Step: Part 1 - Data Correction and Generation](../Part_01/README.md)
- Original project by Baraa Khatib Salkini: [sql-data-warehouse-project](https://github.com/DataWithBaraa/sql-data-warehouse-project)

---

*This material is part of a practical guide on building a Data Warehouse and its ETL pipelines, progressing from foundational concepts to advanced implementations.*
