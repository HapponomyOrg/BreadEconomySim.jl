# Handover to the code chat: the runs for the talk slides

*23 October 2026, from the talk chat. The talk is on Sunday 25 October. This file says what to change in the model, which runs to make, and what to report back. It writes no code. Stef runs everything himself, from the Julia REPL in VS Code.*

*Suggested place in the repository: `docs/talk/handoff_code_talk_runs_2026-10-23.md`. It replaces §5 of `surplus_rule_instructions_2026-10-23.md`; the rest of that file stays valid as background.*

---

## 0. In one paragraph

The talk now shows three villages:

1. step 0, bare bones;
2. rung B, the debt side: the best debt village;
3. rung B, the SuMSy side: the best SuMSy village.

After the third village comes a stress test: the same best village, with everyone greedy. The talk closes with an inequality slide that includes gold. Step 0 has no government, so its 22.13 numbers stand. Rung B and its greedy version must be rerun, because the government's surplus rule changes (§1). The inequality slide needs a version of rung B with gold (§2). Everything runs on the current base, with a full meal protected from creditors, under both tax packages and with four seeds.

---

## 1. Model change: what a government does with a surplus

### The rule (Stef, 23 October)

The rule is the same in both villages. Each month, once taxes are in and spending is paid, the government's cash above its reserve is used in this order:

1. **Repay public debt.**
2. **Pay the land tax out to everyone, per head.** Only the land tax is paid out. The amount paid out is at most this month's land-tax revenue.
3. **Lower taxes with whatever is left.** This uses the existing reduction channel (`tax_scale`, its floor `tax_scale_minimum`, and its climb-back when the government is short). It lowers every tax except the land tax.

### What the code does now (22.13)

From step 8 onward, the government keeps a reserve of three months of spending and pays everything above it out per head (`surplus_redistribution_share = 1.0`). It never lowers taxes (`surplus_tax_reduction_share = 0.0`) and never repays debt from a surplus first. Before step 8 there is no reserve, so a surplus is simply held.

The code is in `manage_government_reserve!` and `pay_levy_dividend!`, in `src/government.jl`.

### Decisions: the defaults below apply unless Stef changes them before handing this over

- **D1. Bonds.** A surplus repays bank loans first (in the debt village) or peer loans (in the SuMSy village). When only bonds are left, the surplus buys bonds back at face value.
  - If the code cannot retire bonds early, report that before building anything.
- **D2. Reserve before debt.** The three-month reserve stays ahead of debt repayment. Only cash above the reserve counts as surplus.
- **D3. Steps 2 to 7.** Leave them as they are for the talk. Applying the rule from step 2, with the reserve moved forward, is work for the report, not for Sunday.

### What to build

1. **One named setting.** Add `surplus_rule`:
   - `:debt_levy_taxcut` is the new rule;
   - `:per_head` is the 22.13 behaviour.

   It replaces the pair `surplus_redistribution_share` / `surplus_tax_reduction_share` as the setting a rung chooses. It travels inside the job, so the workers see it, and it appears as a column in the rungs CSV.
2. **One payout mechanism.** Pay the land tax out through one mechanism only, the same in both villages.
3. **Monthly columns.** Add these to the run files, and their means at month 120 to the summary:
   - `surplus_debt_repaid`: debt repaid from surplus;
   - `levy_paid_out`: the land tax paid out, in total and per head;
   - `tax_scale`.
4. **The identity test.** The test that both villages differ only in the money settings must also cover `surplus_rule`. This is §3.5 of `same_fiscal_rules_instructions_2026-10-22.md`.
5. **Regression.** With `surplus_rule = :per_head`, rung B must reproduce 22.13 exactly: both villages, seed 1, every month. If it doesn't, stop and report.
6. **`MODEL_VERSION`.** Bump it, per the date rule.

---

## 2. One new rung: B with gold

Add a rung named, for example, `BG best village, with gold`. It is rung B with the gold holders of R8, exactly as R8 adds them to step 8.

- Run it on both sides, under both packages.
- This lets the inequality slide (money, wealth, wealth with gold) show the same village as the rest of the talk. At present it uses R8, which is step 8, a different village.

## 2b. The stress test: the best village with everyone greedy

This uses the existing rung `SB2 best SuMSy + everyone greedy`: rung B, the same fiscal rules in both villages, plus `GREEDY_A`. No new rung is needed. In `GREEDY_A`:

- every villager is greedy (`greed_share = 1.0`);
- each act of greed goes to capital (land, shares, or cash, whichever is most profitable first) or to consumption (an extra loaf or ticket, on a coin flip), each with probability one half (`greed_hoarding = 0.5`);
- a greedy villager eats up to ten loaves a month (`greedy_max_breads_per_round = 10`) in place of the ordinary ceiling of three.

Two points the talk depends on:

- **Greed here is a choice made by households.** It is separate from how firms set prices (a margin target against a reserve target). Confirm that `SB2` leaves the firms' pricing as it is in rung B.
- **The steady state is not guaranteed in this cell.** With ten loaves allowed, consumption may rise. The talk's introduction says "nobody wants more than a few", and this cell breaks that on purpose. Report bread eaten and tickets sold per head over the years (§4), so the slide can say how far consumption grew.

---

## 3. The runs

All runs use the current base (meal protected from creditors, `collection_floor_in_breads = 2.0`), both tax packages, both villages and four seeds.

| Priority | Rung | Why | Jobs |
|---|---|---|---|
| 1 | `B ` | villages 2 and 3, and the side-by-side table | 16 |
| 1 | `BG` | the inequality slide with gold | 16 |
| 1 | `SB2` | the stress test: the best village with everyone greedy | 16 |
| 2 | `SB1` | the milder stress test: the richest quarter greedy, chosen at month 12 | 16 |
| 2 | `V8 ` | Stef may use the productive village as "the best debt village" instead of B: it is the debt village that holds its debt | 16 |
| 3 | `B ` and `SB2`, realistic labour market (`variant = REALISTIC_LABOUR`) | so the talk can say whether the pattern holds with realistic firms | 32 |

Step 0 is **not** rerun: no government, so the surplus rule does not touch it.

The intended calls are below. Make them work as written, or tell Stef what differs:

```
include("scripts/run_all.jl")

# priority 1
run_all(seeds = 4, fiscal = :taxes,   rungs = ["B ", "BG", "SB2"])
run_all(seeds = 4, fiscal = :parking, rungs = ["B ", "BG", "SB2"])

# priority 2
run_all(seeds = 4, fiscal = :taxes,   rungs = ["SB1", "V8 "])
run_all(seeds = 4, fiscal = :parking, rungs = ["SB1", "V8 "])

# priority 3
run_all(seeds = 4, fiscal = :taxes,   rungs = ["B ", "SB2"], variant = REALISTIC_LABOUR, variant_label = "realistic")
run_all(seeds = 4, fiscal = :parking, rungs = ["B ", "SB2"], variant = REALISTIC_LABOUR, variant_label = "realistic")

# summaries, one per folder
run_all(summary_only = true, fiscal = :taxes)      # and :parking; and both again with the realistic variant
```

A few points about these calls:

- **Trailing space.** The space in `"B "` and `"V8 "` matters, because `rungs` matches by prefix. Without it, `"B"` also catches `BG`, and `"V8"` catches V8-P, V8-NJ and the other V8 cells.
- **Folder names.** Folders get the new version in their name, so nothing mixes with 22.13 parts.
- **Seeds.** If a cell swings (a wide band, or a worst run far from the mean), rerun that rung with `seeds = 1:10`.

---

## 4. What to report back (a new §4d in `docs/talk/handoff_talk_2026-10-22.md`)

For each cell (rung × package × village), from the summary:

| Field | Summary column |
|---|---|
| Alive at month 120, mean and worst | `alive_at_end`, `alive_worst` |
| Public debt at month 120, its peak, month repaid | `public_debt`, `public_debt_peak`, `public_debt_repaid_month` |
| Poorest tenth: money in meals, wealth in meals | `cash_bottom10_meals`, `wealth_bottom10_meals` |
| Gini of money, of wealth, of wealth with gold | `gini_cash`, `gini_wealth`, `gini_total_wealth` |
| Theatre tickets a month | `tickets` |
| Bread price change a year | `bread_price_change_per_year` |
| Land tax paid out per head a month | new (§1) |
| Tax scale at month 120 | new (§1) |
| Debt repaid from surplus, over ten years | new (§1) |
| `SB2` and `SB1` only: bread eaten and tickets sold per head per month, year 2 and year 10 | from the part files |

**Part files.** The talk chat reads the monthly part files of rungs B and SB2 under the income-tax package, for the public-debt charts. Keep the column names `persons_alive`, `government_debt` and `tickets_sold`. Give the folder name in §4d.

**Before/after table.** Add a short table: rungs B and SB2 under the old rule (22.13) next to the new rule. Key figures: alive, public debt, land tax paid out per head, poorest tenth's money and wealth, wealth Gini. The talk chat needs this to see what the rule changed.

---

## 5. Questions the talk chat needs answered

These need no new runs. Each needs an answer from the code or from existing files.

1. **What does `unemployed` count?** Rung B shows 126 in the debt village and 0 in the SuMSy village. Is it people who want work and have none, or people receiving the benefit? The number stays off the slides until this is answered.
2. **What does the capital tax tax?** A comment in `parameters.jl` says rent keeps the capital tax rate. Does it also cover interest income? The slides currently say "wages, rents, dividends, profits".
3. **Which measure is the repaid month?** For the SuMSy start-up loan, earlier answers said month 22, while the summary's mean says 24. Is `public_debt_repaid_month` a mean over the runs that repaid, a median, or the first month? The slides say "within two years", which holds either way.
4. **Gold Gini under the tax on idle money.** At R8, the debt village's Gini of wealth with gold (0.71) is *lower* than its Gini of wealth (0.73). Adding gold that the richest tenth hold should raise inequality. Is gold counted correctly in `gini_total_wealth`?
5. **The government's interest rate.** The debt village's government borrows at 0.5 % a month, about 6 % a year. The Belgian Debt Agency reported 2.01 % on federal debt at the end of 2025, so "a policy rate near Belgium's" in the handoff is wrong; please correct it there. Optional, only if there is time: step 2 under income taxes with the government's rate at about 0.17 % a month (2 % a year), four seeds, 8 jobs. This answers "what if the government paid Belgium's rate?"

---

## 6. Standing rules (unchanged)

- Nothing may follow a comment on a `RULES` line.
- A code package contains every non-results file in the repository, because Stef replaces everything except `results/`.
  - The talk deck lives in `docs/talk/deck/`. Leave it as it is in the repository; the talk chat updates it.
- No run-time estimates. Stef decides when anything runs.
- The villages are "the debt village" and "the SuMSy village".
