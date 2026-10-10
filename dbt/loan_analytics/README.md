# Loan Analytics dbt Project

This dbt project formalises the loan portfolio analytics work already developed in the repo. It is intended to show a production-style analytics engineering pattern: clean staging, reusable intermediate logic, tested mart outputs, and business-aligned KPI definitions.

## Business context
The repo already contains the foundation for a loan analytics model:
- dimensional-model thinking for loans and repayments
- KPI definitions and rolling performance logic
- portfolio health patterns and validation rules

This dbt project converts those ideas into a more maintainable project structure so the work reads like an analytics-engineering deliverable rather than a set of disconnected SQL scripts.

## Intended structure
- staging: raw cleansing and standardisation
- intermediate: reusable loan-state and repayment logic
- marts: analyst-facing outputs and portfolio KPI snapshots

## Intended sources
This starter assumes tables named:
- loans
- repayments

The current implementation uses small seeded samples so the project can be validated quickly while still following the same business domain as the rest of the repository.

## Current milestone
This phase demonstrates:
- a staged transformation flow
- validated data quality checks
- one intermediate loan-summary layer
- a KPI mart for portfolio health

The next planned enhancement is to expand the mart layer with periodised KPI views and richer delinquency logic aligned to the existing SQL analytics work.
