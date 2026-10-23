# Banks on real-world economics (future work, 23 October 2026)

## What was found
The model's banks earn far more than real banks relative to their revenue. At step B on the common fiscal packages (four seeds, version 2026-10-22.13), the two banks together took 1,400–2,800 a year of interest in the debt village and retained 83–89 % of it; in the SuMSy village their revenue is the account fees (3,300 a year; the interest on peer loans is negative and goes to the lenders), of which they keep about 97 %. Real banks keep about 30 % of revenue (Banks, Regional, 29.67 % net — docs/data/profit_margins_by_industry.csv), because staff, premises, defaults and provisions take the rest.

Two causes in the model:
1. **The loan rate sits at its cap** (`maximum_interest_rate` = 1.5 % a month, 18 % a year) in every run: the rate rule divides the banks' costs by the affordability ratio times the credit base, which puts it above cost-covering, and the cap binds.
2. **A bank has one employee.** Its costs are the staff unit's wage plus the deposit interest it promises; nothing scales with its customers or its loan book.

So the real-world net-margin target built on 23 October (`bank_target_net_margin`, `bank_margin_on_spread`) was below what the banks already made, and the `bankmargin` run (step B, both packages) changed nothing — a null result because the test was empty, not because bank profits do not matter. In absolute terms the profits are 1.3–3.2k a year against a money stock of 50–130k, so the retained profit `p` of Kuypers, Goorden & Delepierre (2021) cannot show in ten years at this scale.

## What to build
- **Costs that scale.** Staff and overhead as a function of customers and loan book (a cost per account, a cost per loan, a provision for defaults from the realised write-offs). The attempt of 22 September (staff scaled with customers) bankrupted the banks at 512 — it needs calibration to the margin data: set the cost ratios so that a bank covering its costs at the going loan volume keeps about 30 % of revenue.
- **The rate rule without the cap binding.** Once costs are realistic the rate should come out of the cost-plus-margin formula rather than the cap; check the cap only then.
- **The margin target as the bank's behaviour**, as for firms (greed against sufficiency): a bank on a reserve target against a bank on a net-margin target, in both moneys.
- **The test of the paper's `p`.** With realistic costs and margins, run the best village longer (20–30 years) and watch the ratio of the banks' retained profit to the money stock; the paper's instability is a ratio that compounds, not a ten-year event.
- **The SuMSy bank's revenue.** Account fees and the spread on peer loans; decide whether a SuMSy bank should also carry a default provision, and what its cost base is in SuMSy's design.

## Where it touches the talk
Nothing in the talk depends on it. The Q&A line stands: "real bank margins change nothing here in ten years; the model's banks have one employee and a rate at its cap, so they already keep most of their revenue — the realistic cost side is future work."
