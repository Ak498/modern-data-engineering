# modern-data-engineering

This repository demonstrates a practical analytics engineering workflow grounded in a loan portfolio use case. It combines SQL modeling, data quality thinking, dbt transformation patterns, and AI-assisted engineering review in one narrative that reflects how modern warehouse teams build trusted analytical products.

## Quick start

```powershell
# install dependencies
uv sync --python 3.14

# run the dbt validation build
uv run dbt build --project-dir dbt\loan_analytics --profiles-dir dbt\loan_analytics
```

## Project story
The repo starts from a real business problem: how to model loan origination, repayment behavior, and portfolio health in a way that is understandable to analysts and robust enough for downstream reporting.

The progression is:
- SQL and modeling foundations
- dimensional modeling and validation logic
- KPI definitions and portfolio analytics
- dbt implementation for staging, intermediate logic, and marts
- automated build validation in CI
- AI-assisted engineering case study documenting a real workflow

## Repository layout
- `week_05_python_pipeline/` - ETL pipeline context and ingestion/validation concepts
- `sql/` - SQL patterns, dimensional modeling, validation logic, and KPI definitions
- `dbt/loan_analytics/` - production-style dbt project for the loan analytics domain
- `ai_engineering_case_study/` - evidence of AI-assisted engineering used responsibly
- `.github/workflows/dbt.yml` - CI workflow that executes the dbt build on code changes
- `performance/Week_02/` - query tuning and optimization exercises
- `docs/` - architecture summaries and reviewer-facing notes

## What this repo demonstrates
- business-aware analytics design
- dimensional modeling with explicit grain and fact/dimension separation
- KPI logic and portfolio-level summary modeling
- tests and validation for data quality
- maintainable transformation layers with dbt
- reproducible verification in CI
- responsible use of AI in engineering workflows while retaining final accountability

## Analytics-engineering themes
- Staging layer for source standardisation and cleaning
- Intermediate layer for reusable loan and repayment logic
- Mart layer for analyst-ready outputs and portfolio KPIs
- Data validation and business assertions
- Documentation and model readability
- Automated verification for production-minded quality control

## Reviewer handoff
This project is designed to show a complete analytics-engineering workflow rather than a set of disconnected examples. The main value is that the business logic is explicit, testable, and validated repeatedly. It demonstrates how a team can move from raw financial event data to trusted portfolio metrics using a staged dbt architecture and strong data quality controls.

## Current verification status
The dbt project is validated with:

```powershell
uv run dbt build --project-dir dbt\loan_analytics --profiles-dir dbt\loan_analytics
```

This currently passes with fresh evidence: 57 dbt nodes succeeded, including 49 data tests, 0 warnings, 0 errors.

## Notes
This repository is meant to read as a cohesive portfolio project rather than a set of isolated exercises. The common thread is trusted analytics design: making business logic clear, testable, automated, and explainable.
