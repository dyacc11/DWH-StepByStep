# DWH Step By Step

A practical guide on building a Data Warehouse and its ETL pipelines, progressing from foundational concepts to advanced implementations.

## About the Project

This repository accompanies a series of articles that walk you through the complete process of designing, building, and populating a Data Warehouse - starting from a simple schema and gradually moving to more complex architectures.

Each part of the series focuses on a specific aspect of DWH development, such as data modeling, ETL pipeline implementation, data quality profiling, test dataset generation, and SCD handling.

## Repository Structure

```mermaid
---
config:
  treeView:
    showIcons: true
---
treeView-beta
  DWH_StepByStep/
    Part_01/
    Part_02/
    README.md
    LICENSE
```

## Parts

- **[Part 1: Data Correction and Generation](./Part_01/)** - Profiling source data, fixing quality issues, and generating consistent test datasets for a simple DWH schema.
- **[Part 2: Data Simulation and Small Test Datasets](./Part_02/)** - Building a SQL-based data simulator using bitmasks and views to easily manage, test, and debug initial and incremental (SCD Type 1 & 2) ETL loads on small, visually verifiable datasets.

## Getting Started

Each part of the series is self-contained and includes its own `README.md` with detailed instructions and ready-to-use assets.

**To begin with Part 1:**
1. Navigate to the **[Part_01](./Part_01/)** directory.
2. Follow the instructions in its `README.md`.
3. Read the full article at **[Part_01/docs/Part01.md](./Part_01/docs/Part01.md)**.

**To proceed to Part 2:**
1. Navigate to the **[Part_02](./Part_02/)** directory.
2. Follow the instructions in its `README.md` (includes a ready-to-use SQLite database for immediate testing).
3. Read the full article at **[Part_02/docs/Part02.md](./Part_02/docs/Part02.md)**.

## License

This project is distributed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

* Inspiration: [Pragmatic data platform](https://github.com/pragmatic-data/pragmatic-data-platform)

---

*This material is part of a practical guide on building a Data Warehouse and its ETL pipelines, progressing from foundational concepts to advanced implementations.*
```
