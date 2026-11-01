# Coder brief — validation and statistics fixes for BreadEconomySim

*1 November 2026. A brief for the coding session, against model version `2026-10-31.1` and the reference ladders on `2026-10-30.3`. Background: `docs/future_work/roadmap_macrosim_2026-10-18.md` (steps 3, 6 and 11).*

## Summary

Five tasks, against model version `2026-10-31.1` and the reference ladders on `2026-10-30.3`. Tasks 1 and 2 are analysis scripts and change no model result. Tasks 3–5 are investigations: trace first, then propose a fix as a switch, off by default.

| # | Task | Kind | Changes golden values? |
| --- | --- | --- | --- |
| 1 | New `scripts/stylized_facts.py`: business-cycle and distribution facts per run, scored against data | Analysis script | No |
| 2 | `scripts/paired_tests.py`: test time averages over the post-burn-in window, not the last month | Analysis script | No |
| 3 | Trace the debt village's quarter-to-quarter oscillation (negative autocorrelation of cyclical GDP) | Investigation, then switch | No (switch off) |
| 4 | Trace why unemployment and inflation move together (wrong-signed Phillips relation) | Investigation, then switch | No (switch off) |
| 5 | Trace the debt village's deflation of about 11 % a year at step 11; add a policy-rate switch | Investigation, then switch | No (switch off) |

**Why now.** The simulation is meant to come as close to reality as possible so it can serve as a policy tool. A first stylized-facts check on step 11 of the realistic ladder found the debt village too volatile, oscillating from quarter to quarter, with a Phillips relation of the wrong sign and a strong deflation. The refactor's Phase A will reproduce `2026-10-31.1` bit for bit, so these properties would carry into MacroSim unless they are understood first.

**What must not change.** The reference tests and golden values. Every model change in tasks 3–5 is a new switch, off in the model's defaults; it may be turned on in the ladder's `RULES` only after Stef decides, and then with a `MODEL_VERSION` bump.

**Order.** Task 1 first, since tasks 3–5 use its output to show whether a switch helps. Task 2 can be done in the same package.

## Rules for the coder

These are the repository's standing conventions; a package that breaks one cannot be applied.

- **Deliver a complete package.** Stef applies a package by replacing everything in the repository except `results/`. The zip must contain every non-results file, or that file is deleted.
- **Data from the repository.** Fetch only the result files a task needs (sparse checkout of the folder or the cells), never the whole `results/` tree.
- **Model changes are switches.** New behaviour arrives as a parameter, off in the model's defaults, so the golden values hold. It enters the ladder through `RULES` only when Stef decides; then bump `MODEL_VERSION` in `scripts/run_all.jl`.
- **Tests.** The full suite passes. The comment test stays green: no code after a comment on the same line. Every new price or planning rule gets a symmetry test (a rise and a fall triggered by mirror-image conditions), after the ratchet bug of 24 October.
- **Runs.** `run_all` is a function with keyword arguments, called from the REPL with worker processes. Anything a worker needs travels inside the job, never as a main-process global. Stef decides when runs happen; the brief gives no run-time estimates, and the coder should not plan around any.
- **Words.** "The debt village" and "the SuMSy village", always. People who do not work are "not working for reasons of their own". Gaps between rich and poor are in meals, with the poorest tenth's holding beside them; gold is reported beside wealth, never in it.
- **Python dependencies.** The existing scripts use pandas, numpy and scipy only. Implement the Hodrick–Prescott filter with `scipy.sparse` (a ten-line function) instead of adding statsmodels.

## Task 1 — `scripts/stylized_facts.py`

A script that reads one ladder folder, computes business-cycle and distribution facts for every run, and scores them against empirical values. This is roadmap step 11, item 1, built on the current model.

**Call.**

```
python3 scripts/stylized_facts.py results/parts/<ladder folder> [--from-month 25] [--rungs "11_,V8_"] [--lambda 1600]
```

**Input.** The per-run files `<step>__<system>__<seed>.csv` in the folder. Columns used: `round`, `persons_alive`, `gdp_in_loaves`, `gdp_consumption`, `price_bread`, `unemployed`, `outstanding_debt`, `bread_stocked`, `bread_sold`, `gini_net_wealth_persons`, `rung`, `system`, `seed`.

**Method, in order**

1. Drop months before `--from-month` (default 25, so the first two years are burn-in).
2. Aggregate to quarters, quarter = (round − 1) ÷ 3, dropping an incomplete last quarter. Flows are summed: `gdp_in_loaves`, `gdp_consumption`, `bread_sold`. Stocks and rates are averaged: `unemployed`, `persons_alive`, `price_bread`, `outstanding_debt`, `bread_stocked`.
3. Derive the series. Real GDP = `gdp_in_loaves`. Real consumption = `gdp_consumption` ÷ `price_bread`. Unemployment rate u = `unemployed` ÷ `persons_alive`. Quarterly inflation = change in log `price_bread`.
4. Take cyclical components with a Hodrick–Prescott filter (λ = 1600) on logs, and on u in levels (percentage points). Also filter log u for the Caiani-comparable volatility, but only when mean u is at least 2 %; below that, log u explodes and the measure is reported as missing.
5. Skip a run with fewer than 20 quarters left, and flag a run as collapsed when `persons_alive` ends below half its start. Collapsed runs are counted and excluded from the medians.
6. Compute the measures in the table below per run; then per rung × system the count, median, 25th and 75th percentile, and a score from the median: *matched*, *partly*, *failed*.

**Measures and targets.** Targets marked "approx." come from general knowledge, not from a checked source; Stef should confirm or replace them before the scores are quoted anywhere.

| Measure | Definition | Target | Matched | Partly | Source |
| --- | --- | --- | --- | --- | --- |
| `sd_gdp` | s.d. of cyclical log real GDP | about 1.5 % | 1.0–2.5 % | 0.5–4 % | US post-war, approx. |
| `rel_sd_cons` | s.d. of cyclical log real consumption ÷ `sd_gdp` | 0.80 | 0.6–1.0 | 0.4–1.2 | Carlin and Soskice 2015, via Caiani et al. 2016 |
| `rel_sd_unemp` | s.d. of cyclical log u ÷ `sd_gdp` | 8.2 | 5–14 | 3–20 | same; Caiani's model gives 13.3 |
| `corr_gdp_unemp` | correlation of the two cycles at lag 0 | strongly negative | ≤ −0.6 | < 0 | FRED series, via Caiani et al. |
| `unemp_lag` | the k in −3…+3 with the most negative corr(GDP cycle at t, u cycle at t + k) | +1 (unemployment lags) | +1 | 0 | same |
| `ac1_gdp` | first-order autocorrelation of the GDP cycle | about 0.85 | ≥ 0.6 | > 0 | approx. |
| `okun` | slope of Δu (pp) on quarterly real GDP growth (%) | −0.3 to −0.5 | −0.2 to −0.6 | < 0 | approx. (Ball et al. 2013 for the law) |
| `phillips` | correlation of u with quarterly inflation | negative | ≤ −0.2 | < 0 | Fitzgerald et al. 2013, via Ponta et al. |
| `infl_cycle` | correlation of the GDP cycle with inflation, at the lag (0…+3) where it peaks | positive, lagging | > 0.2 at k ≥ 1 | > 0 | Caiani et al., Fig. 6 |
| `inv_sales_cycle` | correlation of the GDP cycle with cyclical log(`bread_stocked` ÷ `bread_sold`) | negative | ≤ −0.2 | < 0 | Bils and Kahn 2000, via Caiani et al. |
| `kurt_growth` | excess kurtosis of quarterly real GDP growth | positive (fat tails) | > 1 | > 0 | Fagiolo et al. 2008 |
| `corr_gdp_credit` | correlation of the GDP cycle with cyclical log `outstanding_debt` | positive | > 0.2 | > 0 | Lown and Morgan 2006, via Caiani et al. |
| `mean_unemp` | mean u after burn-in | about 6 % | 4–9 % | 2–12 % | Belgium, approx. |
| `infl_annual` | annualised growth of `price_bread` from the first to the last kept month | about 2 % | 0–4 % | −2 to 6 % | euro-area target |
| `gini_wealth_end` | `gini_net_wealth_persons`, last month | to fill from the Household Finance and Consumption Survey (Belgium) | — | — | leave the target empty until Stef supplies it |

Markup cyclicality cannot be computed yet, since no markup column exists; leave it out rather than approximate it.

**Output.** Two files beside the ladder folder: `results/<ladder>_stylized_facts_runs.csv` (one row per run, every measure) and `results/<ladder>_stylized_facts.csv` (per rung × system: n, collapsed count, median, p25, p75, score per measure). Print a short table for the headline rungs, reusing the `HEADLINE` list from `paired_tests.py`. Scores for the SuMSy village are computed the same way and labelled "for comparison": a SuMSy village need not reproduce debt-money facts.

**Self-test** (`--selftest`, no data needed):

- [ ] HP of a straight line in logs gives a cycle of zero to numerical precision.
- [ ] A sine with a period of 8 quarters gives `ac1_gdp` close to cos(2π/8) ≈ 0.71.
- [ ] Two series built with a known correlation of −0.7 return −0.7 ± 0.05.
- [ ] A series with growth drawn from a Laplace distribution gives `kurt_growth` near 3.
- [ ] On `11_fiscal_policy_and_VAT` of `ladder2_512_realistic_120months_2026-10-30.3` the debt-village medians reproduce the numbers under "The numbers this brief rests on" to two decimals (with statsmodels' HP filter as the check, run once by hand).

**Done when** the script runs on both `2026-10-30.3` ladders, writes the two files, and passes the self-test.

## Task 2 — `scripts/paired_tests.py` on time averages

The paired tests compare each run's final month (`.iloc[-1]`). In the step-11 debt village, unemployment moves between 35 and 149 people within six months (seed 1, months 37–42), so one month's value carries that swing into every test. Ponta et al. test time averages over the whole run; the post-burn-in mean is the standard.

**What to change**

1. **Two kinds of measure.**
    1. *End-state* measures keep the last month: `persons_alive` (deaths accumulate), `government_debt` (a stock whose end value is the finding).
    2. *Level* measures use the mean over the months from `--from-month` (default 25) to the end: `unemployed`, `wealth_gap_meals`, `wealth_bottom10_meals`.
2. **Replace the price level with the price trend.** `price_bread` at the last month mixes level and drift. Test the annualised growth of `price_bread` from month 25 to the end instead, as `infl_annual` (same definition as task 1).
3. **A `basis` column** in the output (`end` or `mean`), and `--from-month` recorded in the file name, so no reader mistakes one for the other.
4. **Collapsed pairs.** Count pairs where either village ends below half its starting population (`collapsed_pairs`). Keep them in the test, since collapse is an outcome, but report the count beside the p-value.
5. **State the power ceiling.** Add `p_min_holm` per row: the smallest p Holm could return for that n and that number of headline rungs. With 10 pairs and 13 rungs it is about 0.025, so a reader sees at once that a result just under 0.05 needs every pair to agree.
6. **Keep the rest.** Wilcoxon signed-rank on matched seeds, Holm over the headline rungs per measure, the four-seed minimum.

**Done when**

- [ ] The script runs on both `2026-10-30.3` ladders with the default window and with `--from-month 1`, and the two outputs differ only in the level measures.
- [ ] On a hand-built folder of four fake runs, the means and end values in the output match values computed by hand.

## Task 3 — Trace the debt village's quarter-to-quarter oscillation

On the realistic ladder, the debt village's cyclical GDP has a first-order autocorrelation of −0.31; in data it is strongly positive. On the base ladder the same cell gives +0.70. So the oscillation comes with the realistic set (`REALISTIC_LABOUR`), and the farms are the first suspect.

**What the data already show** (step 11, `2026-10-30.3`, 10 seeds, medians; monthly series after month 24, deviations from a 13-month centred mean)

| | Realistic, debt village | Realistic, SuMSy village | Base, debt village |
| --- | --- | --- | --- |
| s.d. of monthly unemployment deviations | 6.8 pp | 2.1 pp | 0.7 pp |
| Dominant period of unemployment | about 10 months | about 4 months | 12 months |
| Correlation of unemployment with grain harvested, same month | −0.75 | −0.55 | −0.60 |
| Correlation of the farms' production target with next month's harvest | 0.31 | −0.26 | 0.11 |

Unemployment swings are farm hiring swings: the harvest moves between 390 and 768 in four months (seed 1, months 39–42) while bread sold stays near 1,000.

**Hypotheses, to test in this order**

1. *Own-market planning on farms.* A three-month average of sales plus customers turned away, net of stock, with an adaptive buffer, may overshoot and correct with a period of about ten months, as a cobweb does.
2. *Contracts at 0.8 with spare hours on the market.* Four fifths of hands are tied, so all adjustment falls on the remaining fifth and on the spot market, which amplifies swings in labour sold.
3. *Farms hiring before the harvest* while bakeries and theatres hire in one market in turns; a timing effect within the month.
4. *Land-term rule and deleveraging by land sales* changing farm capacity in steps.

**What to do**

1. **Ablation runs.** Step 11, realistic set, both villages, 10 seeds: switch off one component of `REALISTIC_LABOUR` at a time, then switch each on alone over the base. For each run, record from task 1: `sd_gdp`, `ac1_gdp`, `rel_sd_unemp`, and the monthly unemployment s.d. above. The component whose removal brings `ac1_gdp` above zero is the cause, or the first of several.
2. **A trace of one seed** (seed 1, months 30–48) with the farms' plan per month: expected sales, turned-away customers, stock, buffer, target, hires, harvest. Save it as `results/trace_oscillation_seed1.csv` beside the existing `death_trace_*` files.
3. **Propose a fix as switches** (off by default) only once the cause is known. Candidates the literature uses:
    1. Adaptive expectations of sales with a weight on the latest error, `sales_expectation_weight` (Caiani et al. use 0.25).
    2. Partial adjustment of hiring: close a share of the gap between staff and target each month, `hiring_adjustment_share`.
    3. A grain inventory target as a share of expected use (Caiani et al. use 10 % for every good).

**Done when**

- [ ] The ablation table exists and names the component or components that produce the negative autocorrelation.
- [ ] One switch, off by default, brings `ac1_gdp` above +0.5 on the realistic debt village without raising deaths, and its symmetry test passes.
- [ ] Stef has the table and decides whether the switch enters `RULES`.

## Task 4 — Trace why unemployment and inflation move together

In the realistic debt village, quarterly unemployment and quarterly bread inflation correlate at +0.43; in data the relation is negative. The base ladder gives +0.08. The months of high unemployment are also months of shortage, which points to a cycle driven from the supply side.

**What the data already show** (realistic ladder, step 11, debt village, monthly, medians over 10 seeds)

| Correlation | Value |
| --- | --- |
| Unemployment with people without bread | +0.44 |
| Unemployment with people hungry | +0.45 |
| Unemployment with wage growth (`price_wage`) | +0.26 |
| Bread price change with people without bread | +0.09 |
| Bread price change with last month's bread stock | −0.11 |
| Grain price change with unemployment | +0.01 |

The grain price does not move with unemployment, so a cost push through grain is unlikely. Wages rising when unemployment is high is a second wrong sign, and may be the more important one.

**Hypotheses**

1. *Shortage months.* A low harvest (task 3) leaves bakeries short of grain; customers are turned away and the price-rise rule fires; the same months have high unemployment because farms hired less. If so, task 3's fix also fixes this one.
2. *The emergency labour rule.* When bread or hands fall short, everyone offers all their hours and employers may hire at a loss up to `employer_loss_tolerance`. That may bid wages up exactly in the months of high unemployment.
3. *Contract indexation.* Contract wages follow the bread price, so a shortage-driven price rise feeds straight into wages and back into the cost floor.

**What to do**

1. **Diagnostic counters** in the data row, output only, behaviour unchanged: per month and per good, how many asks rose on demand, fell on a shortfall, were held up by the cost floor, or were capped by the buyer ceiling; and how many hires happened under the emergency rule. Name them `price_rule_*` and `hires_emergency`. The golden values are unaffected; if a test checks the column list, extend it.
2. **Rerun after task 3's switch.** If the correlation of unemployment with inflation turns negative, close this task with a note.
3. **Otherwise, ablate hypotheses 2 and 3** with the existing switches (emergency rule, indexation) and report the four correlations in the table above for each run.

**Done when**

- [ ] The counters exist and a short note says which rule fires in high-unemployment months.
- [ ] Either task 3's switch fixes the sign, or a second switch (off by default) does, with its symmetry test.

## Task 5 — The deflation drift and a policy-rate switch

At step 11 of the realistic ladder, bread prices in the debt village fall 11 % a year (seeds range from −15 % to +1 %), wages and grain by the same amount, while the money stock falls only 2 % a year and real GDP stays flat. Every nominal quantity drifts down together. That is the missing nominal anchor already listed in the roadmap's open questions, now visible in the cell the report rests on.

**What the data already show** (step 11, `2026-10-30.3`, medians over 10 seeds, months 25–120, annual rates)

| | Realistic, debt village | Realistic, SuMSy village | Base, debt village |
| --- | --- | --- | --- |
| Bread price | −11.7 % | −2.1 % | −6.7 % |
| Wage (`price_wage`) | −11.3 % | −2.5 % | — |
| Money in circulation | −2.0 % | +7.7 % | −0.5 % |
| Real GDP | −0.2 % | +0.2 % | — |
| Mean unemployment | 16.4 % | 1.1 % | 21.9 % |
| Change in bank loans, months 25–120 | −11,800 | +1,150 | −3,800 |
| Change in public debt, months 25–120 | +19,700 | 0 | +43,700 |

Prices falling about 10 points a year faster than money, with output flat, means money is circulating more slowly. Part 1 below finds where it stops.

**Part 1 — trace**

1. **The quantity equation, monthly.** M × V = P × Y, with M = `money_in_circulation`, P × Y = `gdp_nominal`. Write V and the holder shares of M (persons by wealth tenth, farms, bakeries, theatres, banks, government) to `results/trace_deflation_<cell>.csv` for step 11 realistic, seeds 1–3.
2. **Three hypotheses to separate.**
    1. *No anchor, with indexation.* With 16 % unemployment, market wages fall; contract wages follow the bread price; the cost floor follows wages; nothing nominal is fixed. Test: rerun with contract wages fixed in money for twelve months at a time instead of indexed, as a temporary experiment switch.
    2. *Asymmetric price triggers.* Prices fall when sales are 10 % below expectation (`price_on_expected_sales`) and rise when demand is 10 % above it (`price_rise_band`). Sales are capped by stock and demand includes turned-away customers, so the two triggers may not fire equally often in a flat market. Test: count how often each fires per month (task 4's counters) in a run with steady demand; write the missing symmetry test if it fails.
    3. *Money resting with the well-off.* If the richest tenth's share of M rises while V falls, satiation is slowing circulation. This is the mechanism behind Stef's limited-consumption-capacity argument, so it must be measured, not assumed.

**Part 2 — a policy-rate switch** (roadmap step 6, the minimal version without a central-bank balance sheet)

1. **Parameters**, all inert at their defaults: `policy_rate_rule = :none` (or `:taylor`), `inflation_target = 0.02` (a year), `neutral_real_rate = 0.01`, `taylor_inflation_weight = 0.5`, `taylor_unemployment_weight = 0.2` (Ponta et al.'s baseline), `unemployment_target = 0.06`, `zero_lower_bound = true`, `policy_rate_smoothing = 0.0`.
2. **The rule**, the dual mandate as in Ponta et al., Appendix B.3, with inflation measured by the existing `trailing_inflation(model)` (twelve months) and converted to a monthly rate:

    $$i_t = \pi_t + r^* + a_\pi (\pi_t - \pi^*) + a_u (u^* - u_t)$$

3. **Transmission.** The banks' loan rate becomes the policy rate plus today's cost-based rate as the spread; the deposit rate follows the policy rate, floored at zero; new bonds are issued at the policy rate. Under SuMSy the switch does nothing, and a test asserts that.
4. **Experiments.** Step 2 (inflation of 6.8 % a year under realistic rules), V8 (deflation without end), step 11; the debt village with the rule on and off; the SuMSy village unchanged. Stef writes his predictions into the experiment file before the runs. A higher rate also raises the government's interest bill in a village of fixed output, so public debt is reported beside prices.

**Done when**

- [ ] The deflation trace exists and the note says which hypothesis holds.
- [ ] `policy_rate_rule = :taylor` runs, its tests pass, and the golden values are unchanged with the default `:none`.
- [ ] A table for steps 2, V8 and 11: price trend, unemployment, public debt and deaths, with and without the rule, scored by task 1.

## Queued for later

Three items from the gap review are not part of this package; they are listed so the coder does not start them unasked. Each is a roadmap step that Stef schedules.

- **A wealth-spending switch** (roadmap step 7, item 1). Households spend a share of wealth above their buffer each month, as in Caiani et al. (0.25 a quarter). It tests whether satiation drives the debt village's public deficit. It needs Stef's design decision on which goods absorb the spending, because bread saturates.
- **The transaction-flow matrix and the net-worth check** (roadmap step 2, items 3–4). Every row and column of the flow matrix sums to zero; total net worth equals the value of real assets. The money identity already holds every month; these two checks cover what it cannot see.
- **GDP by income** (roadmap step 9, item 6). Wages, profits, rent, interest and taxes on products, checked against GDP by spending every month.

The refactor's Phase A, starting with the tax module, is separate; this brief changes nothing it depends on.

## The numbers this brief rests on

All figures come from step 11 (`11_fiscal_policy_and_VAT`) of the two reference ladders on `2026-10-30.3`: 10 seeds per village, no collapsed runs. Method exactly as in task 1: months 25–120, full quarters only, Hodrick–Prescott with λ = 1600 (statsmodels, as a check on the coder's scipy version), sample standard deviations, medians over seeds. Task 1's self-test must reproduce these to two decimals.

| Measure | Realistic, debt village | Realistic, SuMSy village | Base, debt village | Base, SuMSy village |
| --- | --- | --- | --- | --- |
| `sd_gdp` (%) | 5.53 | 2.64 | 2.71 | 2.35 |
| `rel_sd_cons` | 0.65 | 0.30 | 1.08 | 1.08 |
| `rel_sd_unemp` | 5.60 | missing (u < 2 %) | 1.26 | missing |
| `corr_gdp_unemp` | −0.64 | −0.19 | −0.58 | missing (no unemployment) |
| `unemp_lag` | 0 | 0 | 0 | — |
| `ac1_gdp` | −0.31 | −0.10 | 0.70 | 0.62 |
| `okun` | −0.52 | −0.14 | −0.09 | 0.00 |
| `phillips` | 0.43 | −0.12 | 0.08 | missing |
| `infl_cycle` (at lag) | 0.24 (2) | 0.17 (1–2) | 0.39 (2–3) | 0.18 (2) |
| `inv_sales_cycle` | 0.17 | 0.19 | 0.34 | 0.20 |
| `kurt_growth` | 0.34 | 1.06 | 0.55 | 8.58 |
| `corr_gdp_credit` | 0.16 | 0.15 | −0.09 | 0.09 |
| `mean_unemp` (%) | 16.4 | 1.1 | 21.9 | 0.0 |
| `infl_annual` (%) | −11.2 | −2.1 | −6.7 | 0.0 |
| `gini_wealth_end` | 0.81 | 0.11 | 0.90 | 0.77 |

Two things stand out beyond tasks 3–5. The inventory-to-sales ratio is pro-cyclical in every column, against the data; it may resolve with task 3, and task 1 will show whether it does. The base debt village's unemployment of 22 % is far above the reference economy's, which is why `mean_unemp` sits in task 1's table at all.

An earlier figure of 0.51 for consumption volatility used `bread_sold` as consumption; the brief's definition (`gdp_consumption` ÷ `price_bread`) gives 0.65.

**To reproduce.** Sparse-checkout the two folders `results/parts/ladder2_512_realistic_120months_2026-10-30.3/` and `results/parts/ladder2_512_120months_2026-10-30.3/`, files `11_fiscal_policy_and_VAT__*`, and run task 1's script with `--rungs "11_"`. The monthly diagnostics in tasks 3–5 use the same files.
