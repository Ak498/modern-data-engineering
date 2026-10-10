# Debugging Case: loan balance and repayment consistency

## Problem statement
The loan analytics layer summarises repayment activity and outstanding balance. A key failure mode is that the model can appear valid while silently hiding a mismatch between cumulative repayments and the business logic for remaining balance.

This issue was detected by reviewing the daily portfolio output and the balance assertion logic together. The core risk was that a clamped value could make a bad state look valid.

## AI suggestion
An AI assistant was asked to propose the most important diagnostics for this issue. The suggestion included:
- a check that principal repaid does not exceed loan principal
- a review of the daily portfolio output for a non-zero outstanding balance over time
- validation that the business logic is derived consistently from the intermediate model

## Human review
The AI suggestion was useful as a starting point, but it required validation against the actual repo logic. The key checks were:
- whether the daily snapshot truly represented daily outstanding balance rather than a zero-filled placeholder
- whether the balance guardrail was testing the real invalid state rather than a post-processed clamp
- whether the mart layer was reusing the intermediate summary instead of duplicating logic

## Final decision
The AI-assisted analysis surfaced the risk, but the final decision and implementation remained with the human developer. The fix was applied only after checking the business rule against the repo's domain assumptions.

## Final implemented checks
- ensure the daily portfolio model uses a calendar date spine and cumulative balance logic
- ensure principal repaid is checked against loan amount before any clamping is applied
- ensure the fact model consumes the reusable intermediate summary rather than re-aggregating directly from staging
- validate the corrected logic with dbt build
