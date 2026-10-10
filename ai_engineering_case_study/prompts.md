# AI Prompts Used in the Case Study

## Prompt 1: test generation
"Review the repo's loan analytics model and suggest dbt tests that would catch repayment inconsistencies and bad loan balance logic. Focus on practical edge cases and business rules, not only schema checks."

## Prompt 2: debugging support
"The repo contains a loan analytics model with repayment and outstanding balance logic. Identify the most likely business-rule edge cases and suggest SQL diagnostics to validate whether the model can misstate repayment or balance behavior."

## Prompt 3: documentation review
"Draft model descriptions and column documentation for the intermediate loan summary and portfolio KPI marts. Keep the wording aligned with the repo's data contract and KPI definitions."

## Prompt 4: final review
"Given the repo context, which of these suggestions are valid business logic and which ones need human review before implementation? Explain the trade-offs and propose the final version to keep."
