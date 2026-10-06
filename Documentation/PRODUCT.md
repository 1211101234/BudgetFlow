# BudgetFlow product foundation

BudgetFlow is a private, local-first monthly budgeting assistant for macOS. It helps a person understand cash flow, allocate the amount remaining after expenses, and test changes before committing to them.

## Product principles

1. Calculations are deterministic and inspectable. AI may explain a result later, but it must not invent or silently change one.
2. Currency calculations use `Decimal`, not binary floating-point values.
3. Data stays on the Mac unless the user explicitly enables a future external integration.
4. The Financial Stability Score is a planning indicator. It is not a credit score, financial guarantee, or substitute for professional advice.
5. Recommendations describe the tradeoff and the numbers behind it instead of labelling a user as good or bad.

## Current calculation

```text
Available to allocate =
    Net monthly income
    - Monthly commitments
    - Essential monthly expenses
    - Non-essential monthly expenses
```

The default recommendation first preserves the user's requested minimum cash buffer. It then reserves up to 20% of the remaining allocatable cash for the next estimated credit-card statement (10% when the selected priority is debt reduction). The rest is distributed according to the selected priority. Debt money is separated into additional loan and credit-card payments; when both exist, credit cards receive 75% of that extra-debt bucket because they typically carry the higher rate. Money intended for debt is redirected to long-term savings when no recorded balance needs it. Money intended for the emergency fund is redirected after the chosen reserve target is met.

## Credit-card payment plan

Each credit card records its statement balance, minimum due, statement date, payment due date, any payment planned before salary day, expected next statement, current outstanding balance, credit limit, annual rate, and whether new spending is paused. Statement dates and minimums may remain pending rather than being replaced with invented values. The monthly commitment uses a confirmed minimum due so it is protected before discretionary allocation begins.

Cards are planned in due-date order, with higher-rate cards first when dates match. The dashboard first subtracts any pre-salary payment, then calculates the salary-day recommendation as the protected minimum plus its available share of the additional credit-card allocation, capped at the remaining statement balance. It also shows the projected unpaid amount and how much of the dedicated reserve is set aside for the next estimated statement. These calculations are planning guidance and do not account for transactions, interest, fees, or bank processing that occur after the entered statement data.

Monthly expenses can carry separate weekly limits. An optional emergency-fund baseline keeps starter, three-month, and six-month targets aligned with an explicitly agreed budget instead of silently changing when a temporary debt payment changes.

## Future plans

The 12-month simulator looks only for macOS Calendar events whose title is exactly `Payday`. Actual event dates replace the estimated 24th for matching months; missing months remain visibly marked as estimates. The current salary allocation is treated as already planned, so the forecast begins with the following month.

Each future payday applies the same monthly baseline, pays the remaining credit-card balance first, fills the selected emergency target next, and assigns the remaining amount to long-term savings. March can be switched between 2.5× and 3× net income. The simulation assumes income and baseline expenses remain unchanged and that no new credit-card spending, interest, or fees are added.

## Financial Stability Score

| Component | Weight |
| --- | ---: |
| Commitment load | 30% |
| Monthly surplus | 25% |
| Emergency coverage | 20% |
| Savings allocation | 15% |
| Consumer-credit reliance | 10% |

Every component and its explanation is visible in the app. Thresholds are currently product defaults and must be reviewed before public release or use as formal financial guidance.

## Near-term roadmap

1. Complete the local MVP and validate the workflow with realistic monthly budgets.
2. Add editing for individual commitments and expenses, not only add/delete.
3. Add month-to-month history and scenario comparison.
4. Add goals, debt payoff projections, import/export, accessibility review, and automated UI tests.
5. Evaluate an optional explanation service only after privacy, consent, cost, and data-retention requirements are defined.
