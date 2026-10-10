# AI-Assisted Analytics Engineering Case Study

This case study demonstrates a controlled AI-assisted engineering workflow on the repo's loan analytics dbt project.

## Objective
Use AI to accelerate issue diagnosis and test design, then verify the final fix with repo-native evidence and retain human accountability for the outcome.

## Scope
This case study focuses on a real issue in the analytics layer: the portfolio balance logic was not correctly represented in the daily snapshot model, and the balance guardrail was using a clamped value instead of checking the underlying business rule.

## Workflow
1. Inspect the existing finance logic and model definitions.
2. Ask an AI assistant to propose candidate tests and diagnostics for the identified risk.
3. Review the suggestion against the repo's data model and business assumptions.
4. Fix the actual logic where needed.
5. Run the dbt build and confirm the corrected outcome with evidence.

## What changed
The repo originally had two related issues:
- the daily portfolio mart published an outstanding balance of zero for every day, which made the daily snapshot inaccurate
- the non-negative balance assertion checked the clamped value rather than the presignal that repayment exceeded principal

The final fix removed the silent clamp, re-derived the daily snapshot from a calendar date spine, and added a business assertion that catches the real invalid condition: principal repaid greater than loan amount.

## Why this matters
This demonstrates that AI is used as a force multiplier for analysis and test generation, not as the source of final truth. The engineering review, business logic, and dbt validation remain the deciding factors.

## Evidence
The repo was validated with:

```powershell
uv run dbt build --project-dir dbt\loan_analytics --profiles-dir dbt\loan_analytics
```

Result: 57 dbt nodes succeeded, 49 data tests passed, 0 warnings, 0 errors.
