# Handover to the code chat: a check and a short rerun before the talk

*24 October 2026, from the talk chat. This replaces the earlier version of this file, whose §1 was wrong. The talk is on Sunday. Stef runs everything himself.*

---

## 1. Correction: the land tax is paid out no matter what

Stef: when the land-tax dividend is switched on, the land tax is paid out to everyone, per head, every month, whatever the budget. That includes months when the government is in debt. The surplus rule applies to everything else: a surplus first repays debt, then lowers taxes.

So `.8` does what Stef intends, and **nothing needs fixing**. The earlier request to hold back the land tax while in debt is withdrawn.

---

## 2. The check the talk needs: rung B with the land tax kept as revenue

Under T, the debt village's land-tax payout is about as large as its whole public debt. From the `.8` run files (rung B, four seeds, totals over ten years):

| Rung B, T | land tax collected = paid out | public debt, month 120 |
|---|---|---|
| Debt village | 77,900 | 75,300 |
| SuMSy village | 271,300 | 0 |

Without the dividend, the debt village's books might roughly balance. The talk's main claim, that the debt village borrows without end, would then rest on paying out the land tax. Someone in the room will ask about this, so the talk needs the number.

**One new cell:** rung B with the land-tax dividend switched off, so the land tax is ordinary revenue. Run it under both packages, both villages, base labour market, four seeds: 16 jobs. Everything else is as in B. In the SuMSy village the extra revenue will simply lower taxes further, which is the surplus rule at work.

**Under P the benefit has to come back on.** Under P the two-loaf land-tax dividend replaces the unemployment benefit, which is switched off (Stef, 24 Oct). Switching the dividend off under P without restoring the benefit would leave the unemployed with nothing, and that would be a different experiment. So in this cell under P:

- the unemployment benefit is switched back on at two loaves, as under T;
- the land tax is ordinary revenue;
- everything else is as in B.

Under T the benefit is already on, so only the dividend changes.

Report for this cell:

- alive, mean and worst;
- public debt at month 120, its peak, and whether it is still climbing in the last two years;
- tax scale;
- the poorest tenth's money and wealth;
- the three Ginis.

---

## 3. The meal under P (confirmed by Stef, 24 Oct)

Under P everyone receives a meal: two loaves a month, paid as the land-tax dividend. The land tax is scaled to pay it (`levy_dividend_target_in_breads = 2`). It is paid whatever the budget, and **the unemployment benefit is switched off** while it is paid. The debt village borrows for the meal: 142–178k over ten years. Nothing to change. This only needs to be written into §4e, so that the talk's spending line for P is correct: "a meal for everyone from the land tax; no separate benefit".

## 4. One version for the slides

- **Step 0** (`"0 "`, T only, no government): rerun on the current version. `.8` changed the banks (their rate set from the going wage, staff scaling with the number of loans), and those changes act at step 0 too. 8 jobs.
- **Rungs B, BG and SB2 under T and P:**
  - Confirm that the 24.0–24.2 changes leave the base `.8` results unchanged. The greedy ask matters here, because SB2 is in the base set.
  - If they don't, rerun all three on the current version: 48 jobs.
- **The realistic set** stays out of the talk.

```
include("scripts/run_all.jl")
run_all(seeds = 4, fiscal = :taxes,   rungs = ["0 ", "B-nodiv"])   # rung name as you define it
run_all(seeds = 4, fiscal = :parking, rungs = ["B-nodiv"])
```

Report it as a new §4e in `handoff_talk_2026-10-22.md`.
