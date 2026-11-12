# Bread pre-orders — results

*11 November 2026. Built and run by the coder (Claude Code on Stef's machine) from `docs/future_work/coder_brief_bread_preorders_2026-11-11.md`. Model version `2026-11-11.1` on EconoSim 0.3.1; suite at 76,935 tests, all passing. Nothing is committed: the change sits in the working copy beside Stef's own uncommitted edits to `HANDOFF_2026-09-18.md` and `START_HERE.md`.*

## 1. Do both modes end the queue deaths?

**For the two traced deaths, yes; across the experiment, mode B does and mode A as designed does not.** Both traced villagers live in both modes, and `deaths_with_cash` falls from 2 to 0 (§2 below). In the paired runs mode B leaves no death of a villager with money in cells 8 and B. In V8's debt village it cuts them from 11 to between 1 and 7 per ten runs; the six in the run traced died in a famine month when every bakery refused their orders (§5.3). Mode A creates deaths of villagers with money that base does not have: 34 in the co-op SuMSy village (B) and 7 in cell 8's SuMSy village, over ten runs each. The cause is that the cheapest bakery accepts more orders than it is allowed to bake, every month (§5.1). With the order limit also capped at what the bakery may bake (a diagnostic run, not the design), those deaths are gone.

## 2. The two traced deaths (brief §8.2)

Cell B, SuMSy village, realistic ladder: the income-tax package with seed 8 (person 506 died in month 23) and the parking-tax package with seed 1 (person 280 died in month 86).

| Run | Mode | Deaths | With money | Months missed with money | Bread on order | Orders refused | Orders failed |
|---|---|---|---|---|---|---|---|
| taxes, seed 8 | none | 1 (person 506, month 23) | 1 | 190 | 0 % | – | – |
| | A | 0 | 0 | 19 | 88 % | 344 | 2,963 |
| | B (3 months) | 0 | 0 | 165 | 1.7 % | 0 | 0 |
| parking, seed 1 | none | 1 (person 280, month 86) | 1 | 116 | 0 % | – | – |
| | A | 0 | 0 | 323 | 92 % | 347 | 2,858 |
| | B (3 months) | 0 | 0 | 402 | 2.6 % | 0 | 0 |

With the switch off both runs are identical, column by column, to the runs the trace was made on, so `deaths_with_cash` is 2 across the two runs, as the brief expected.

The two villagers, month by month around their former deaths:

- **Person 506, none:** whole meals in months 19 and 20 (two loaves off the shelf each), then nothing in 21, 22 and 23, and death.
- **Person 506, mode A:** two loaves delivered on order and a whole meal every month from 19 to 26; a new order of two loaves placed each month.
- **Person 506, mode B:** the village takes a different course; person 506 buys two loaves off the shelf and eats a whole meal every month from 19 to 26, so never orders.
- **Person 280, none:** whole meals in months 82 and 83, then nothing in 84, 85 and 86, and death.
- **Person 280, mode A:** an order of two every month, except in month 83 when the order failed (the bakery was short); they went first in the queue and bought four loaves off a shelf. Whole meals throughout.
- **Person 280, mode B:** an order delivered in month 82 (from an earlier missed meal), one more loaf ordered and delivered in 84, otherwise loaves off the shelf. Whole meals throughout.

## 3. The experiment (brief §8.3)

Paired runs, ten seeds, 120 months, 512 villagers, both villages, cells 8, B and V8, as in `ablation` (the realistic set added to the step's settings; fiscal package `own`). All seven variants on the realistic ladder; on the standard ladder base, mode A and mode B with three months. 600 runs, none failed. Folders `results/parts/ablation_2026-11-11.1_<variant>[_standard]`; tables `results/preorders_2026-11-11.1[_standard]_table.csv` and one row per run in `…_runs.csv`, made by `scripts/preorder_report.py`. `sd_gdp` and `ac1_gdp` are from `scripts/stylized_facts.py` on each folder (means over the runs here).

Columns: deaths and those of villagers holding at least five meals' worth of money are totals over the ten runs; everything else is a mean per run. *Missed with money*: villager-months without any bread while holding five meals' worth of money. *Hungry villager-months*: the sum of the monthly `hungry` column. *Refused, failed, unpaid*: orders per run. *Top bakery's share*: the largest bakery's share of the month's orders, averaged over months. *Bread baked a month* is against the 1,024 loaves 512 villagers need. *Firms wound up*: liquidations of all firms per run (the bakeries' own are not separated in the rows). Year-10 figures are the last twelve months.

#### Realistic ladder: who goes hungry, the orders, the bakeries

| cell | village | variant | deaths (10 runs) | of whom with money | missed with money | hungry villager-months | on order | refused | failed | unpaid | top bakery's share | bread baked a month | given + thrown a month | firms wound up |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | debt | base | 38 | 0 | 54 | 754 | 0 % | 0 | 0 | 0 | – | 1,037 | 10.2 | 31.5 |
| 8 | debt | A, at risk | 148 | 1 | 20 | 969 | 87 % | 419 | 373 | 27 | 0.90 | 1,018 | 2.3 | 37.4 |
| 8 | debt | B, 1 month | 28 | 0 | 45 | 738 | 2 % | 0 | 4 | 3 | 1.00 | 1,039 | 9.5 | 31.6 |
| 8 | debt | B, 3 months | 62 | 0 | 68 | 1,007 | 6 % | 0 | 29 | 8 | 1.00 | 1,030 | 7.0 | 32.2 |
| 8 | debt | B, 12 months | 44 | 0 | 56 | 955 | 19 % | 5 | 49 | 10 | 0.99 | 1,031 | 8.0 | 30.6 |
| 8 | debt | A, growth 50 % | 3,647 | 8 | 64 | 9,572 | 83 % | 1,542 | 9,883 | 414 | 0.51 | 563 | 0.2 | 36.5 |
| 8 | debt | A, no limit | 2,761 | 251 | 379 | 3,340 | 92 % | 0 | 3,242 | 52 | 1.00 | 615 | 3.3 | 44.9 |
| 8 | sumsy | base | 0 | 0 | 136 | 165 | 0 % | 0 | 0 | 0 | – | 1,072 | 14.1 | 57.6 |
| 8 | sumsy | A, at risk | 7 | 7 | 820 | 937 | 93 % | 528 | 3,094 | 0 | 0.58 | 1,015 | 0.7 | 17.2 |
| 8 | sumsy | B, 1 month | 0 | 0 | 119 | 148 | 0 % | 0 | 0 | 0 | 1.00 | 1,072 | 13.7 | 56.7 |
| 8 | sumsy | B, 3 months | 0 | 0 | 186 | 224 | 2 % | 0 | 0 | 0 | 0.99 | 1,071 | 15.0 | 56.8 |
| 8 | sumsy | B, 12 months | 0 | 0 | 366 | 442 | 9 % | 9 | 148 | 0 | 0.97 | 1,064 | 12.2 | 56.0 |
| 8 | sumsy | A, growth 50 % | 1,482 | 903 | 4,607 | 9,671 | 81 % | 1,428 | 11k | 2 | 0.50 | 639 | 1.6 | 31.6 |
| 8 | sumsy | A, no limit | 5,033 | 3,829 | 1,700 | 2,314 | 67 % | 0 | 3,665 | 1 | 1.00 | 51 | 0.4 | 81.3 |
| B | debt | base | 38 | 0 | 29 | 587 | 0 % | 0 | 0 | 0 | – | 1,036 | 8.4 | 31.4 |
| B | debt | A, at risk | 62 | 0 | 11 | 733 | 82 % | 376 | 258 | 19 | 0.90 | 1,020 | 2.0 | 38.6 |
| B | debt | B, 1 month | 30 | 0 | 48 | 845 | 2 % | 0 | 6 | 3 | 1.00 | 1,033 | 10.6 | 32.9 |
| B | debt | B, 3 months | 34 | 0 | 70 | 881 | 6 % | 0 | 12 | 7 | 1.00 | 1,030 | 7.6 | 33.8 |
| B | debt | B, 12 months | 44 | 0 | 74 | 1,111 | 23 % | 6 | 53 | 10 | 0.99 | 1,021 | 6.7 | 32.7 |
| B | debt | A, growth 50 % | 3,771 | 8 | 66 | 9,604 | 83 % | 1,455 | 9,876 | 412 | 0.50 | 552 | 0.2 | 35.0 |
| B | debt | A, no limit | 2,592 | 232 | 377 | 3,005 | 92 % | 0 | 2,979 | 36 | 1.00 | 633 | 3.2 | 40.0 |
| B | sumsy | base | 0 | 0 | 145 | 173 | 0 % | 0 | 0 | 0 | – | 1,073 | 14.4 | 55.9 |
| B | sumsy | A, at risk | 35 | 34 | 1,132 | 1,354 | 94 % | 573 | 3,335 | 0 | 0.61 | 1,004 | 0.7 | 14.7 |
| B | sumsy | B, 1 month | 0 | 0 | 173 | 200 | 0 % | 0 | 0 | 0 | 1.00 | 1,072 | 14.8 | 56.8 |
| B | sumsy | B, 3 months | 0 | 0 | 208 | 244 | 2 % | 0 | 1 | 0 | 1.00 | 1,071 | 13.8 | 57.6 |
| B | sumsy | B, 12 months | 0 | 0 | 127 | 151 | 5 % | 0 | 0 | 0 | 0.99 | 1,073 | 13.6 | 57.6 |
| B | sumsy | A, growth 50 % | 1,541 | 844 | 4,714 | 9,963 | 82 % | 1,140 | 11k | 6 | 0.49 | 642 | 1.7 | 52.3 |
| B | sumsy | A, no limit | 5,037 | 4,084 | 1,778 | 2,312 | 67 % | 0 | 3,675 | 2 | 1.00 | 50 | 0.3 | 104.6 |
| V8 | debt | base | 50 | 11 | 344 | 796 | 0 % | 0 | 0 | 0 | – | 1,038 | 12.4 | 22.0 |
| V8 | debt | A, at risk | 73 | 1 | 154 | 789 | 87 % | 847 | 367 | 1 | 0.83 | 1,020 | 6.9 | 19.3 |
| V8 | debt | B, 1 month | 53 | 1 | 507 | 1,108 | 2 % | 0 | 0 | 5 | 0.99 | 1,033 | 12.2 | 21.2 |
| V8 | debt | B, 3 months | 35 | 7 | 620 | 1,205 | 6 % | 27 | 60 | 3 | 0.97 | 1,036 | 15.1 | 21.6 |
| V8 | debt | B, 12 months | 57 | 1 | 603 | 1,505 | 29 % | 18 | 107 | 4 | 0.97 | 1,024 | 9.2 | 17.2 |
| V8 | debt | A, growth 50 % | 56 | 0 | 65 | 504 | 87 % | 279 | 173 | 1 | 0.94 | 1,022 | 7.7 | 16.0 |
| V8 | debt | A, no limit | 164 | 9 | 567 | 1,858 | 88 % | 0 | 1,500 | 4 | 1.00 | 992 | 8.0 | 21.3 |
| V8 | sumsy | base | 0 | 0 | 254 | 344 | 0 % | 0 | 0 | 0 | – | 1,083 | 22.3 | 57.2 |
| V8 | sumsy | A, at risk | 0 | 0 | 101 | 169 | 92 % | 269 | 121 | 0 | 0.59 | 1,075 | 11.9 | 33.7 |
| V8 | sumsy | B, 1 month | 0 | 0 | 261 | 346 | 1 % | 0 | 0 | 0 | 0.99 | 1,082 | 21.0 | 55.4 |
| V8 | sumsy | B, 3 months | 0 | 0 | 313 | 418 | 3 % | 0 | 24 | 0 | 0.95 | 1,083 | 23.6 | 52.2 |
| V8 | sumsy | B, 12 months | 0 | 0 | 563 | 706 | 16 % | 0 | 72 | 0 | 0.94 | 1,076 | 22.6 | 49.1 |
| V8 | sumsy | A, growth 50 % | 0 | 0 | 0 | 0 | 92 % | 16 | 6 | 0 | 0.75 | 1,076 | 11.3 | 49.1 |
| V8 | sumsy | A, no limit | 0 | 0 | 1,842 | 1,924 | 93 % | 0 | 2,316 | 0 | 1.00 | 1,031 | 5.9 | 57.3 |

#### Realistic ladder: prices, the cycle and everyone else

| cell | village | variant | bread, year 10 | bread %/yr | sd_gdp | ac1_gdp | unemployed | work a villager | wealth Gini | poorest tenth (meals) | public debt |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | debt | base | 5.61 | 0.6 | 4.45 | -0.28 | 119 | 2.65 | 0.76 | 0.1 | 89k |
| 8 | debt | A, at risk | 11.61 | 7.7 | 3.74 | 0.01 | 119 | 2.56 | 0.74 | -0.7 | 107k |
| 8 | debt | B, 1 month | 5.74 | 0.8 | 4.15 | -0.26 | 116 | 2.64 | 0.76 | -0.2 | 83k |
| 8 | debt | B, 3 months | 6.48 | 1.7 | 4.78 | -0.02 | 114 | 2.63 | 0.76 | -0.1 | 94k |
| 8 | debt | B, 12 months | 5.69 | 0.8 | 4.35 | -0.34 | 118 | 2.63 | 0.75 | 0.0 | 87k |
| 8 | debt | A, growth 50 % | 758.50 | 62.8 | 6.02 | 0.70 | 62 | 2.21 | 0.57 | 2.5 | 1,979k |
| 8 | debt | A, no limit | 127.52 | 26.2 | 17.80 | 0.16 | 62 | 2.66 | 0.57 | 0.5 | 188k |
| 8 | sumsy | base | 7.26 | 4.2 | 2.29 | 0.38 | 1 | 2.69 | 0.36 | 11.8 | 0 |
| 8 | sumsy | A, at risk | 7.89 | 5.4 | 2.59 | 0.47 | 3 | 2.24 | 0.25 | 15.0 | 0 |
| 8 | sumsy | B, 1 month | 7.38 | 4.5 | 2.41 | 0.47 | 2 | 2.66 | 0.36 | 11.2 | 0 |
| 8 | sumsy | B, 3 months | 7.89 | 5.2 | 2.51 | 0.31 | 3 | 2.66 | 0.35 | 10.7 | 0 |
| 8 | sumsy | B, 12 months | 8.32 | 5.7 | 3.09 | 0.44 | 3 | 2.61 | 0.35 | 10.3 | 0 |
| 8 | sumsy | A, growth 50 % | 38.29 | 26.8 | 3.99 | 0.63 | 97 | 2.08 | 0.90 | -1.2 | 130k |
| 8 | sumsy | A, no limit | 173.90 | 39.9 | 13.51 | 0.52 | 0 | 2.77 | 0.39 | 4.7 | 15 |
| B | debt | base | 5.85 | 1.0 | 4.15 | -0.18 | 116 | 2.66 | 0.74 | 0.6 | 88k |
| B | debt | A, at risk | 11.15 | 6.7 | 2.50 | 0.06 | 122 | 2.60 | 0.73 | -0.2 | 113k |
| B | debt | B, 1 month | 6.16 | 1.5 | 4.43 | -0.28 | 118 | 2.63 | 0.73 | 1.3 | 91k |
| B | debt | B, 3 months | 6.00 | 1.2 | 3.85 | -0.20 | 119 | 2.61 | 0.73 | 0.3 | 94k |
| B | debt | B, 12 months | 5.84 | 1.1 | 3.77 | -0.19 | 117 | 2.59 | 0.74 | 0.5 | 96k |
| B | debt | A, growth 50 % | 660.07 | 63.0 | 5.74 | 0.74 | 56 | 2.23 | 0.55 | 3.3 | 1,875k |
| B | debt | A, no limit | 64.30 | 18.1 | 21.58 | 0.33 | 54 | 2.64 | 0.58 | 1.7 | 106k |
| B | sumsy | base | 7.44 | 4.7 | 2.80 | 0.53 | 0 | 2.70 | 0.30 | 13.1 | 0 |
| B | sumsy | A, at risk | 9.78 | 7.3 | 2.45 | 0.46 | 3 | 2.27 | 0.24 | 14.2 | 0 |
| B | sumsy | B, 1 month | 7.87 | 5.2 | 2.90 | 0.52 | 1 | 2.70 | 0.30 | 11.8 | 0 |
| B | sumsy | B, 3 months | 8.68 | 6.4 | 3.46 | 0.55 | 3 | 2.67 | 0.31 | 11.2 | 0 |
| B | sumsy | B, 12 months | 7.36 | 4.6 | 2.66 | 0.52 | 0 | 2.71 | 0.29 | 12.8 | 0 |
| B | sumsy | A, growth 50 % | 42.97 | 28.5 | 4.38 | 0.60 | 85 | 2.17 | 0.62 | 1.6 | 129k |
| B | sumsy | A, no limit | 164.16 | 38.9 | 13.42 | 0.48 | 0 | 2.62 | 0.44 | 6.0 | 0 |
| V8 | debt | base | 0.78 | -11.9 | 5.65 | 0.06 | 135 | 1.61 | 0.81 | -3.6 | 46k |
| V8 | debt | A, at risk | 1.50 | -6.5 | 3.75 | 0.07 | 146 | 1.61 | 0.82 | -0.6 | 90k |
| V8 | debt | B, 1 month | 0.78 | -11.2 | 7.60 | 0.24 | 148 | 1.56 | 0.81 | -3.4 | 43k |
| V8 | debt | B, 3 months | 1.03 | -9.7 | 6.67 | 0.13 | 139 | 1.61 | 0.80 | -2.4 | 51k |
| V8 | debt | B, 12 months | 1.01 | -7.3 | 4.85 | 0.02 | 128 | 1.62 | 0.82 | -4.0 | 75k |
| V8 | debt | A, growth 50 % | 1.73 | -5.4 | 2.96 | 0.15 | 154 | 1.58 | 0.81 | -2.9 | 98k |
| V8 | debt | A, no limit | 2.66 | -1.6 | 7.88 | 0.10 | 165 | 1.72 | 0.79 | 0.3 | 122k |
| V8 | sumsy | base | 0.82 | -10.1 | 4.98 | 0.89 | 24 | 1.85 | 0.54 | 63.8 | 0 |
| V8 | sumsy | A, at risk | 1.17 | -7.7 | 1.56 | 0.22 | 16 | 1.90 | 0.53 | 48.0 | 0 |
| V8 | sumsy | B, 1 month | 0.76 | -10.5 | 4.79 | 0.89 | 32 | 1.82 | 0.54 | 70.1 | 0 |
| V8 | sumsy | B, 3 months | 0.75 | -10.6 | 5.41 | 0.90 | 30 | 1.83 | 0.54 | 72.0 | 0 |
| V8 | sumsy | B, 12 months | 0.85 | -7.7 | 5.56 | 0.75 | 26 | 1.86 | 0.53 | 62.9 | 0 |
| V8 | sumsy | A, growth 50 % | 0.89 | -10.4 | 2.43 | 0.57 | 21 | 1.88 | 0.53 | 61.6 | 0 |
| V8 | sumsy | A, no limit | 0.49 | -15.6 | 6.57 | 0.60 | 47 | 1.84 | 0.54 | 120.5 | 0 |

#### Standard ladder: who goes hungry, the orders, the bakeries

| cell | village | variant | deaths (10 runs) | of whom with money | missed with money | hungry villager-months | on order | refused | failed | unpaid | top bakery's share | bread baked a month | given + thrown a month | firms wound up |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | debt | base | 19 | 0 | 6 | 96 | 0 % | 0 | 0 | 0 | – | 1,047 | 0.3 | 12.3 |
| 8 | debt | A, at risk | 50 | 0 | 6 | 210 | 77 % | 342 | 193 | 0 | 0.93 | 1,029 | 0.1 | 14.6 |
| 8 | debt | B, 3 months | 22 | 0 | 1 | 70 | 2 % | 0 | 0 | 0 | 1.00 | 1,046 | 0.3 | 13.4 |
| 8 | sumsy | base | 0 | 0 | 4 | 4 | 0 % | 0 | 0 | 0 | – | 1,074 | 13.1 | 0.9 |
| 8 | sumsy | A, at risk | 0 | 0 | 157 | 193 | 94 % | 341 | 2,853 | 0 | 0.54 | 1,016 | 0.1 | 0.0 |
| 8 | sumsy | B, 3 months | 0 | 0 | 2 | 3 | 1 % | 0 | 0 | 0 | 1.00 | 1,075 | 13.2 | 0.7 |
| B | debt | base | 20 | 0 | 9 | 98 | 0 % | 0 | 0 | 0 | – | 1,046 | 0.3 | 13.6 |
| B | debt | A, at risk | 28 | 0 | 8 | 201 | 72 % | 343 | 242 | 0 | 0.92 | 1,033 | 0.1 | 14.3 |
| B | debt | B, 3 months | 18 | 0 | 0 | 91 | 2 % | 0 | 0 | 0 | 1.00 | 1,041 | 0.4 | 12.8 |
| B | sumsy | base | 0 | 0 | 3 | 4 | 0 % | 0 | 0 | 0 | – | 1,075 | 12.8 | 0.7 |
| B | sumsy | A, at risk | 0 | 0 | 154 | 186 | 94 % | 341 | 2,852 | 0 | 0.54 | 1,016 | 0.1 | 0.0 |
| B | sumsy | B, 3 months | 0 | 0 | 5 | 6 | 1 % | 0 | 0 | 0 | 1.00 | 1,075 | 11.9 | 1.4 |
| V8 | debt | base | 11 | 0 | 5 | 36 | 0 % | 0 | 0 | 0 | – | 1,035 | 1.6 | 8.4 |
| V8 | debt | A, at risk | 9 | 0 | 45 | 130 | 67 % | 704 | 0 | 0 | 0.86 | 1,037 | 1.5 | 7.7 |
| V8 | debt | B, 3 months | 12 | 0 | 2 | 40 | 1 % | 0 | 0 | 0 | 1.00 | 1,045 | 1.7 | 11.4 |
| V8 | sumsy | base | 0 | 0 | 3 | 4 | 0 % | 0 | 0 | 0 | – | 1,079 | 13.7 | 0.2 |
| V8 | sumsy | A, at risk | 0 | 0 | 40 | 62 | 95 % | 270 | 0 | 0 | 0.95 | 1,049 | 1.5 | 0.0 |
| V8 | sumsy | B, 3 months | 0 | 0 | 4 | 4 | 1 % | 0 | 0 | 0 | 1.00 | 1,077 | 12.8 | 0.6 |

#### Standard ladder: prices, the cycle and everyone else

| cell | village | variant | bread, year 10 | bread %/yr | sd_gdp | ac1_gdp | unemployed | work a villager | wealth Gini | poorest tenth (meals) | public debt |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | debt | base | 4.16 | -1.1 | 0.97 | -0.02 | 144 | 2.50 | 0.81 | -0.6 | 77k |
| 8 | debt | A, at risk | 4.73 | -0.1 | 0.90 | 0.08 | 144 | 2.48 | 0.83 | -1.1 | 101k |
| 8 | debt | B, 3 months | 4.07 | -1.3 | 0.90 | -0.01 | 141 | 2.50 | 0.81 | -0.4 | 75k |
| 8 | sumsy | base | 2.63 | -6.2 | 1.16 | 0.38 | 0 | 2.39 | 0.34 | 33.3 | 0 |
| 8 | sumsy | A, at risk | 4.78 | 0.0 | 0.18 | 0.09 | 0 | 2.22 | 0.47 | 15.7 | 0 |
| 8 | sumsy | B, 3 months | 2.82 | -5.5 | 1.17 | 0.42 | 0 | 2.39 | 0.34 | 32.0 | 0 |
| B | debt | base | 4.02 | -1.5 | 1.03 | 0.09 | 140 | 2.51 | 0.77 | 0.6 | 72k |
| B | debt | A, at risk | 4.72 | -0.1 | 0.96 | 0.20 | 142 | 2.51 | 0.71 | 4.0 | 98k |
| B | debt | B, 3 months | 4.21 | -0.9 | 1.17 | 0.05 | 139 | 2.51 | 0.76 | 2.3 | 76k |
| B | sumsy | base | 2.71 | -5.9 | 1.17 | 0.36 | 0 | 2.39 | 0.26 | 37.9 | 0 |
| B | sumsy | A, at risk | 4.77 | 0.0 | 0.16 | 0.09 | 0 | 2.22 | 0.31 | 22.3 | 0 |
| B | sumsy | B, 3 months | 2.65 | -6.1 | 1.18 | 0.34 | 0 | 2.40 | 0.26 | 38.3 | 0 |
| V8 | debt | base | 2.04 | -2.6 | 1.63 | 0.44 | 279 | 1.45 | 0.86 | -2.3 | 133k |
| V8 | debt | A, at risk | 2.32 | -1.7 | 1.40 | 0.56 | 284 | 1.47 | 0.87 | -3.1 | 146k |
| V8 | debt | B, 3 months | 1.20 | -8.9 | 2.17 | 0.47 | 268 | 1.49 | 0.86 | -2.2 | 103k |
| V8 | sumsy | base | 1.43 | -5.8 | 2.50 | 0.34 | 123 | 1.50 | 0.47 | 43.0 | 0 |
| V8 | sumsy | A, at risk | 2.71 | -0.0 | 2.31 | 0.11 | 136 | 1.45 | 0.58 | 16.6 | 0 |
| V8 | sumsy | B, 3 months | 1.29 | -6.8 | 2.92 | 0.44 | 122 | 1.51 | 0.45 | 47.9 | 0 |

**Seed noise.** Paired by seed against base, mode B with one or three months is within two standard errors of base on deaths, bread prices, firm failures, work and wealth inequality in nearly every cell. It does raise the months missed with money in V8 (both villages) and, with twelve months, V8's hunger and bread inflation. Mode A's effects on hunger, missed months, bread prices, firm failures and work are beyond two standard errors in most cells.

## 4. What mode A changes that mode B does not

Mode A puts 82–94 % of the bread on order; mode B 0.4–6.5 % with one or three months, 5–29 % with twelve. So mode B leaves the bakeries planning as before, and its results stay close to base. Mode A is the test of "the baker knows the demand", but as built it mixes two things: the bakers know the demand, and the cheapest one is handed more of it than it is allowed to bake (§5.1). The figures below are for mode A as built, growth limit 10 %.

- **Waste.** The spare loaves go: bread given away and thrown away falls from 8–22 to 0.7–12 loaves a month, and the bakeries bake 1,000–1,070 loaves a month instead of 1,037–1,080.
- **Cover.** So does the cover. About 26 orders fail every month in the SuMSy villages of cells 8 and B (3,090–3,340 a run), 2–3 a month in the debt villages (258–373 a run) and in V8's SuMSy village (121 a run); the villagers let down go first in the queue but find thin shelves. Hungry villager-months rise in cells 8 and B (SuMSy village: 165 → 937 and 173 → 1,354), and the months missed with money rise six- to eightfold there (136 → 820, 145 → 1,130). In the debt villages and in V8 the months missed with money fall (8: 54 → 20; V8 debt: 344 → 154).
- **Firm failures.** In the SuMSy villages firms are wound up far less often (8: 58 → 17 a run; B: 56 → 15; V8: 57 → 34); in the debt villages of 8 and B somewhat more (31 → 37 and 31 → 39).
- **Prices.** Bread inflation rises: in the debt villages from +0.6 and +1.0 %/yr to +7.7 and +6.7 %/yr (cells 8 and B), in the SuMSy villages from +4.2 and +4.7 to +5.4 and +7.3 %/yr; V8's deflation slows. On the standard ladder the SuMSy villages' price stops moving altogether: −6.2 %/yr becomes 0.0 %/yr and the output cycle nearly vanishes (`sd_gdp` 1.16 → 0.18 in cell 8). The likely reason, not traced: with nearly all bread on order, sales match expected sales month after month, and the price rule moves only outside its tolerance band.
- **Work.** In the SuMSy villages of 8 and B a villager works less (2.69 → 2.24 and 2.70 → 2.27 units a month): less is overproduced.
- **The poorest and inequality.** On the realistic ladder the SuMSy villages become more equal (wealth Gini 0.36 → 0.25 in cell 8, 0.30 → 0.24 in B; the poorest tenth 11.8 → 15.0 and 13.1 → 14.2 meals); on the standard ladder less equal (0.34 → 0.47, 0.26 → 0.31, V8 0.47 → 0.58; the poorest tenth 33 → 16, 38 → 22, 43 → 17 meals). The debt villages' poorest tenth falls slightly and their public debt rises (realistic: 89k → 107k in 8, 88k → 113k in B, 46k → 90k in V8).
- **V8**, where bread is already short for the debt village's poor: mode A does not thin the cover into more deaths there by much on the realistic ladder (debt village 50 → 73 deaths over ten runs, hungry villager-months 796 → 789, deaths with money 11 → 1), and on the standard ladder it does not at all (11 → 9). Its public debt doubles on the realistic ladder (46k → 90k).
- **The bakeries' shares.** In mode A the cheapest bakery takes 83–90 % of the orders in the debt villages and 58–61 % in the SuMSy villages, steadily (the share swings 2–6 % from month to month). No bakery founded during the run wins orders at 10 % growth. With a 50 % limit or none, orders swing more, and new bakeries take 37–44 % of the orders in some cells, but by then the villages are collapsing (§5.1). In mode B nearly every order goes to the single cheapest bakery (94–100 %), and the shares swing 9–58 % from month to month, because there are few orders.

## 5. What broke, what surprised, what did not fit

### 5.1 The brief's limit does not know the bakery's capacity, and mode A fails on it

§10 of the brief says nothing in the model caps a bakery's size. On both ladders something does: `plan_within_capacity` caps each bakery's target at its share of the village's hands (`bakery_capacity_loaves`). In mode A every villager orders from the cheapest bakery first. That bakery reaches its cap, bakes exactly that, and the limit, (1 + growth) × what it baked, lets it take 10 % more orders than it can bake, again every month. Checked month by month in the taxes run (seed 8, months 12–14): bakery 8's target sits at its cap of 256 grain (512 loaves), it bakes 512, and it takes 563 loaves of orders. Some 26 villagers' orders fail each month. Which ones is decided by the order the orders were placed in, a new shuffle every month: the lottery comes back, at the order book. The two dearer bakeries hold no orders and bake 20–26 loaves for the shelf, so those let down find little.

At 50 % growth the cheapest bakery takes half again what it can bake, and with no limit it takes every order in the village (996 loaves in month 1 of cell 8's SuMSy village, seed 1, against 512 it may bake). The orders it cannot bake fail every month, the other bakeries have planned for their thin shelves and cannot hire fast enough, and the villages of cells 8 and B collapse: 1,482–5,037 deaths over ten runs, 147–364 villagers alive on average at year ten with growth 50 %, 8–253 with no limit, bread at 38–759. V8 is largely spared (its debt village loses 164 villagers over ten runs with no limit, against 50 in base; its SuMSy village none). The brief asked whether the swamping happens; it does, and it is fatal.

**Diagnostic, not part of the design.** To test the explanation, mode A was re-run with the limit also capped at what the bakery may plan (`scripts/preorder_capacity_diagnostic.jl`, which redefines the limit at run time; `src/` is unchanged and remains the brief's design).

| cell | village | variant | deaths (10 runs) | of whom with money | missed with money | hungry villager-months | failed orders | bread %/yr |
|---|---|---|---|---|---|---|---|---|
| 8 | debt | base | 38 | 0 | 54 | 754 | 0 | +0.6 |
| 8 | debt | A, as built | 148 | 1 | 20 | 969 | 373 | +7.7 |
| 8 | debt | A, limit capped | 67 | 2 | 9 | 740 | 242 | +4.2 |
| 8 | debt | A, no limit, as built | 2,761 | 251 | 379 | 3,340 | 3,242 | +26.2 |
| 8 | debt | A, no limit, capped | 93 | 3 | 13 | 769 | 203 | +14.4 |
| 8 | sumsy | base | 0 | 0 | 136 | 165 | 0 | +4.2 |
| 8 | sumsy | A, as built | 7 | 7 | 820 | 937 | 3,094 | +5.4 |
| 8 | sumsy | A, limit capped | 0 | 0 | 55 | 70 | 111 | +7.0 |
| 8 | sumsy | A, no limit, as built | 5,033 | 3,829 | 1,700 | 2,314 | 3,665 | +39.9 |
| 8 | sumsy | A, no limit, capped | 0 | 0 | 995 | 1,410 | 1,754 | +17.4 |
| B | debt | base | 38 | 0 | 29 | 587 | 0 | +1.0 |
| B | debt | A, as built | 62 | 0 | 11 | 733 | 258 | +6.7 |
| B | debt | A, limit capped | 49 | 0 | 9 | 642 | 224 | +4.6 |
| B | debt | A, no limit, as built | 2,592 | 232 | 377 | 3,005 | 2,979 | +18.1 |
| B | debt | A, no limit, capped | 99 | 7 | 15 | 693 | 164 | +9.6 |
| B | sumsy | base | 0 | 0 | 145 | 173 | 0 | +4.7 |
| B | sumsy | A, as built | 35 | 34 | 1,132 | 1,354 | 3,335 | +7.3 |
| B | sumsy | A, limit capped | 0 | 0 | 41 | 52 | 112 | +5.9 |
| B | sumsy | A, no limit, as built | 5,037 | 4,084 | 1,778 | 2,312 | 3,675 | +38.9 |
| B | sumsy | A, no limit, capped | 32 | 29 | 1,340 | 1,749 | 2,173 | +12.8 |

With the limit capped, mode A's failed orders in the SuMSy villages of cells 8 and B fall from 3,090–3,340 to 111–112 a run. Their deaths of villagers with money fall from 7 and 34 to none, and their hungry villager-months and months missed with money fall below base (cell 8: 165 → 70 and 136 → 55; B: 173 → 52 and 145 → 41). The no-limit collapse is gone in cells 8 and B: deaths over ten runs 2,592–5,037 → 0–99. What the cap does not remove: bread inflation stays above base (+4.2 to +7.0 %/yr against +0.6 to +4.7), the debt villages still lose more people than base (cell 8: 67 against 38), and with no limit the cheapest bakery still takes everything it may bake and 1,750–2,170 orders a run still fail in the SuMSy villages. In V8 the capped runs are identical to the uncapped ones: its bakeries bake four loaves to a grain, so the cap never binds. The explanation of §5.1 holds; whether and how the limit should know the cap is a design question, left to Stef.

### 5.2 Where the build departs from the brief's words

| Point | Brief | Built | Why |
|---|---|---|---|
| What a bakery offered (`r.offered`) | §6.2: the shelf only | the shelf plus the loaves delivered on order | sales include the orders (§6.2). With the shelf alone a bakery sells more than it offered, and the price rule's sell-out test, `shelf_left`, the distress cut and the plan's sold-out step all compare sales with what was offered: in mode A every bakery would look sold out every month. The shelf is `offered − sold_on_order` wherever the plan reads it. |
| The price of an order | §6.2.1: `member_ask` | the posted price, `max(ask, cost floor)`, rounded as the market rounds it | `member_ask` nets a co-op member's expected rebate off the ask; the market charges the full price and pays the rebate later as patronage. Charging `member_ask` would give a member the rebate twice. `member_ask` still orders the bakeries, as §5.3 says. |
| Bakery state | §4: `bread_orders`, `bread_baked` | also `bread_orders_planned`, the orders the bakery's target and expected sales include | `own_plan!` reads the current target in several places (both sold-out steps, the gradual pace, the partial adjustment, the reserve rule, the first fill of the sales history). The shelf plan must read the shelf part of it, or the sold-out step scales the orders too and they are baked twice. |
| The market-share rule | §6.1: read shelf sales | also: villagers holding an order are left out of the village need; with `plan_within_capacity` the orders take the capacity first | that rule sizes the village's baking from every villager's missing meal, not from sales |
| The distress cut | not covered | a bakery near failure that did not sell its shelf out cuts it to what the shelf sold, plus its new orders | orders are certain |
| Where delivery sits | §6.2: after `bake!`, before `donate_bread!` | immediately before `donate_bread!`, after the month's benefits and basic income | the villager pays from the same cash as in the bread market |
| A guard | §3: unknown modes rejected | also: pre-orders need `demand_based_targets` (and `bread_preorder_months ≥ 1`, `bread_preorder_growth ≥ 0`) | the default ±1 ratchet does not plan from sales or need, so it cannot bake orders; every ladder sets `demand_based_targets` |
| An extra column | §7: eight columns | also `bread_orders_by_bakery` (`id:loaves;…`) | §8.3.2 asks for each bakery's share of the orders month by month |

Rationing (`bread_rationing`) divides the shelf, not the shelf plus orders, among the villagers. It is off on every ladder.

### 5.3 Mode B's remaining deaths come from the same limit

In V8's debt village, mode B with three months, seed 4: six villagers with money died in months 43–44. After their first missed meal (month 41) they placed no order: every bakery refused, in a famine month (110 hungry). The cheapest bakery held 844 loaves of orders, at its limit. The two dearer ones could take only 12 and 16, because their limit is tied to what they had baked, which was little since nobody bought their bread. The brief meant refusals to happen only when the village's bakeries cannot bake the meals asked of them. Here it was the growth limit that refused, not the dearer bakeries' capacity: in V8 the capacity cap never binds (§5.1, the diagnostic).

### 5.4 Smaller points

- **First misses stay.** Mode B, by design, acts only after a missed meal, so it cannot lower `missed_bread_with_cash`. With longer ordering it raises it in V8.
- **No deaths to prevent in the experiment's B.** The experiment's base has no deaths of villagers with money in cells 8 and B on either ladder; the two traced deaths were in the fiscal-package folders (`taxes`, `parking`), which the experiment, like `ablation`, does not use. On the standard ladder no variant has any.
- **Start-up refusals.** In month 1 the bakeries have baked only the start-up 320 loaves, so the limit refuses most of the first month's orders (about 330 a run); those villagers shop in the queue.
- **Pandas.** `scripts/stylized_facts.py` and `scripts/preorder_report.py` need pandas and scipy, which no Python on this machine had; they were run in a separate environment.

## 6. Files

- Code: `src/parameters.jl`, `src/agents.jl`, `src/model.jl`, `src/BreadEconomySim.jl`, `src/markets.jl` (section "bread pre-orders"), `src/negotiation.jl`, `src/lifecycle.jl`, `src/credit.jl`, `src/data.jl`.
- Scripts: `scripts/run_all.jl` (version, summaries), `scripts/planning_ablation.jl` (six variants; `realistic = false` for the standard ladder), `scripts/preorder_report.py` (the tables), `scripts/preorder_capacity_diagnostic.jl` (the diagnostic of §5.1).
- Tests: `test/runtests.jl`, testset "bread pre-orders (11 Nov 2026)": the eleven tests of §8.1, 141 checks.
- Off is off: the suite passes with the golden values unchanged, and seven part files of `2026-11-11.0` re-run identical in every column (both ladders, both villages; cells B, 8, 11 and the everyone-greedy S3).

No recommendation is made on switching pre-orders on in the base.
