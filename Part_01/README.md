# DWH Step By Step: Part 1 - Data Correction and Generation

This repository contains the source code and materials for the first part of the "DWH Step By Step" article series, dedicated to data correction and test data generation for a simple Data Warehouse schema.

## Repository Structure

```mermaid
---
config:
  treeView:
    showIcons: true
---
treeView-beta
  Part_01/
    orig/
      cust_info.csv
      prd_info.csv
      sales_details.csv
    new/
      Customer.csv
      Product.csv
      Sales.csv
    docs/
      Part01.md
    img/
      part1_title.png
      part1_diagram1.png
      part1_diagram2.png
      part1_diagram3.png
    stat_queries.sql
    generation_queries.sql
    README.md
```

### Directory Description

- **orig/** - Original source files containing data quality issues.
- **new/** - Pre-generated, corrected example files ready for DWH loading (for reference).
- **doc/** - Full article documentation in Markdown format.
- **img/** - Images and diagrams used to illustrate the article.
- **stat_queries.sql** - Statistical analysis queries for data profiling.
- **generation_queries.sql** - SQL scripts for data correction and generation.

## Self-Generation Workflow

To reproduce the data correction and generation process, follow these steps:

1. **Analyze customer and product data**
   - Execute statistical queries from `stat_queries.sql` for `cust_info` and `prd_info`.
2. **Generate corrected customer and product data**
   - Execute generation queries from `generation_queries.sql` to create the `Customer` and `Product` tables.
3. **Analyze sales data**
   - Execute statistical queries from `stat_queries.sql` for `sales_details`.
4. **Generate corrected sales data**
   - Execute generation queries from `generation_queries.sql` to create the `Sales` table.
5. **Export the results**
   - Export the generated `Customer`, `Product`, and `Sales` tables to CSV files in a directory of your choice. *(Note: The `new/` directory already contains pre-generated example files for your reference, so you do not need to overwrite them).*

## Full Documentation

The complete article with detailed explanations, SQL code, and diagrams is available at:

**[docs/Part01.md](./docs/Part01.md)**

## Related Links

- Original project by Baraa Khatib Salkini: [sql-data-warehouse-project](https://github.com/DataWithBaraa/sql-data-warehouse-project)

---

*This material is part of a practical guide on building a Data Warehouse and its ETL pipelines, progressing from foundational concepts to advanced implementations.*
```

