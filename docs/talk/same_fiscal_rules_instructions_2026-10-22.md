# Same rules on both sides: instructions for the code chat

*22 October 2026, revised the same day after Stef's decisions on D1, D3, D4, D5, D8 and D9. Written in the talk chat for the simulation (code) chat. Stef reads it first and settles the decisions still open in §2. The code chat then carries out §3 to §7.*

*Nothing here is code. The document says what the code must do and how to check that it does it.*

*Suggested place in the repository: `docs/talk/same_fiscal_rules_instructions_2026-10-22.md`.*

---

## 1. Why this is needed

Stef's rule for the talk and the report is that in every side-by-side comparison the two villages differ in one thing only: how money works.

The ladder of run 2026-10-20.4 does not meet that rule. `scripts/ladder_definition.jl` and `results/ladder2_512_rungs.csv` give each money its own fiscal package:

| From step | Setting | Debt village | SuMSy village | Where |
|---|---|---|---|---|
| 0 | dividend tax | 30 % (parameter default) | 0 | `BARE_SUMSY` sets it; `BARE_DEBT` leaves the default |
| 2 | wage tax, capital tax | 15 %, 15 % | 0, 0 | `GOV_DEBT` / `GOV_SUMSY` |
| 2 | profit tax | 10 % | 0 | `GOV_DEBT` |
| 2 | tax on balances above the cushion ("parking tax") | 0 | 1.5 % a month | `GOV_SUMSY` |
| 2 | benefit | 2 loaves | 1 loaf | `GOV_DEBT` / `GOV_SUMSY` |
| 3 | deposit interest, loyalty bonus | 1 % a year, 2 % | none | `DEP` (money: SuMSy prohibits deposit interest, D4) |
| 5 | government bonds | yes | no bonds; the government borrows from the public through the banks (peer loans) from step 2 on | rungs 5 to 8 (money: D3) |
| 8 | land levy, paid out as a dividend | no | yes | `V8_SUMSY` (the switch is fiscal; the rate follows the money, D5) |
| 8 | government reserve of 3 months | no (only from step 10) | yes | `V8_SUMSY` |
| 8–11 | what a budget surplus does | cuts taxes (`RESERVE`) | paid out per head | `RESERVE`, and the post-processing at the end of `ladder_definition` |

**Consequence 1: step 8 cannot be read.** The SuMSy village's wealth Gini falls from 0.75 at step 7 to 0.45 at step 8. Its start-up public debt falls from 3,765 to 608 at the same step. That is the step where the land levy, the dividend and the reserve switch on, for SuMSy only. The ladder therefore cannot say whether the shares did this.

**Consequence 2: the cross-checks are not clean.** X1 and X2 exist to separate the money from the fiscal package, but they leave other differences in place:

- X2 (debt money, SuMSy's package) keeps the debt village's 10 % profit tax and pays no benefit at all.
- X1 (SuMSy money, debt package) keeps the land levy, the dividend and the 3-month reserve, which the debt village's step 11 does not have.

**A reporting gap.** `scripts/dump_rungs.jl` (line 25) writes `parking_tax` and `parking_fee` as 0 for every debt-money row. It does so even where a debt village has a tax on balances: DD8, DDL8, DDGL8 (1.5 %) and DDGL8-35 (3.5 %). The rungs CSV therefore misreports those rows.

---

## 2. Decisions

### Decided by Stef (22 October)

**D1. What counts as "the money".** These settings belong to the money and may differ between the two villages. Every other setting must be identical.

- `monetary_system`: how money is created and destroyed.
- `guaranteed_income`: 5 a month.
- `demurrage_rate`: the 2 % fee that is destroyed.
- `account_fee_person`, `account_fee_enterprise`: account fees are part of SuMSy (Stef's reference: *An alternative general-purpose money supply model for a future-proof sustainable economy*, https://www.researchgate.net/publication/370063555). SuMSy banks earn from the spread on loans; debt banks earn from interest.
- `deposit_interest_rate`, `deposit_interest_period`, `loyalty_bonus_rate`: see D4.
- `government_bonds`, `peer_lending`, `peer_loan_rate`, `bank_spread`, and the debt banks' rate settings: see D3.
- The land levy **rate**: see D5. The levy switch itself is fiscal and must be identical.

**D3. Government borrowing.** Bonds are the government's way to borrow from the public instead of letting banks create money. Under SuMSy the same function runs through the banks, because they act as intermediaries and do not create money.

- In the model this is already the case. A SuMSy borrower, the government included, takes a peer loan through the banks at `peer_loan_rate` (−1 % a month). The lender receives that rate minus `bank_spread` (−1.5 % a month), and the bank keeps the 0.5 % spread. See `request_loan!` in `src/credit.jl`, which sends every SuMSy borrower to `request_peer_loan!`.
- **Consequence:** the 20.4 ladder's treatment stands, and no change is needed. The debt village gets bonds from step 5. The SuMSy government borrows from the public through the banks from step 2.
- Explicit SuMSy bonds would carry a negative rate, a logical consequence of the money. They add nothing the peer loans do not already do, so none are built.

**D4. Deposit interest.** SuMSy prohibits interest on accounts, so deposit interest belongs to the money. Under the common packages, step 3 adds deposit interest to the debt village only. The rung name says so: "3 + interest on deposits (debt money; SuMSy prohibits it)".

**D5. Land levy.** That the levy rate follows the cost of holding money is a direct consequence of the money. The rule is therefore the same formula on both sides (`land_levy_rate` in `src/markets.jl`), and the number it gives differs by money and by package:

- SuMSy: about 2 % + the parking tax + the margin, per month.
- Debt money under package T: about the margin alone, because deposit interest gives money a positive return.
- Debt money under package P: about 1.5 % less the deposit return, plus the margin.

These rates are reported (§3.5). No fixed-rate cell is needed.

**What stays to be done under D5:** the payout must follow one mechanism on both sides. SuMSy pays the levy out through `surplus_redistribution_share`, while the debt-money cells (DDL8 and others) use `land_levy_dividend`. The code chat makes one of these the general mechanism and uses it on both sides.

### Still open: the packages (Stef is thinking; defaults shown)

**D2. The benefit.**

- **Default:** the same number of loaves on both sides, 2 loaves. SuMSy's unemployed then receive the guaranteed income on top, which under this rule is something the money does.
- **Why the current 1-loaf rule cannot stay:** the SuMSy benefit was set at 1 loaf because the income covers the other loaf. A benefit sized by the money cannot belong to a package that is the same for both moneys.
- **Alternative:** a top-up rule, where the benefit raises a person's monthly receipts to 2 loaves at the current bread price, counting the guaranteed income. This needs new code, so it belongs in the full ladder only.

**D6. Budget surplus.**

- **Default:** paid out per head on both sides. This is the current SuMSy rule, and it also carries the land dividend.
- **Alternative:** cut taxes on both sides.

**D7. The two common packages.** Both packages run on both moneys.

| | Package T, "taxes" (the debt village's current package) | Package P, "parking" |
|---|---|---|
| wage / capital / dividend / profit tax | 15 % / 15 % / 30 % / 10 % | 0 / 0 / 0 / 0 |
| tax on balances above a cushion of 30 | 0 | 1.5 % a month, paid to the government |
| benefit | 2 loaves (D2) | 2 loaves (D2) |
| public jobs | 10 % | 10 % |
| from step 8 | land levy (rate per D5) and dividend, 3-month reserve, surplus per head (D6) | same |

Notes on the packages:

- Under package P nothing is destroyed by the tax itself. Under SuMSy the 2 % fee is still destroyed on top, because that fee is part of the money.
- Steps 0 and 1 have no government, so there are no taxes at all on either side; the dividend tax is 0 on both.
- Package T on SuMSy breaks the guard in `ladder_definition.jl` that says "SuMSy never taxes income". That break is intended here; §3.4 says how to handle the guard.

### Decided by Stef (22 October, continued)

**D8. No double demurrage under SuMSy: a coding error to fix.** The enterprise charge (`CHARGE`: `enterprise_tax = :reserves`, 2 % a month on cash above the working reserve, paid to the government) was built as the debt village's stand-in for the fee on idle business money.

- Under SuMSy it lands on top of the real fee. Enterprises get no cushion, so a SuMSy firm already pays the 2 % fee and the 1.5 % parking tax on all of its cash.
- Stef: SuMSy villages must not suffer double demurrage, and this is a coding error to fix. See §3.11.

**Scope (checked in `results/ladder2_512_rungs.csv`):** the charge is on only at step 6, on both sides. Steps 7 and later drop it (`charge_on_balances = 0`), and so do all the stress cells. The error therefore affects the SuMSy side of step 6 only. The talk's numbers (steps 0, 2, 8, 11, V8, S3) do not carry it.

**D9. Loan rates that cover deposit interest become a switch.** At present `set_interest_rates!` (in `src/credit.jl`) always adds the promised deposit interest to the rate banks charge borrowers, the government included. Stef: this must be a switch, not built-in logic. See §3.12.

### Still open: questions raised by D8 to D10 (defaults shown)

**D8a. Step 6 under package P, debt side.** Under P the debt village already pays the 1.5 % tax on all balances, and the charge adds 2 % on top above the reserve. If the principle "no double charge on balances" holds for both moneys, the charge is off wherever a tax on balances applies.

- **Default:** under P, the charge is off on both sides at step 6.
- Under T, it is on for the debt side and off for SuMSy, per D8.

**D8b. Step 6 in the ladder.** Step 7 is named "+ two more theatres" but also drops step 6's charge, so the ladder is not cumulative at that point. There are two ways to fix this:

- **(a) Label step 6 a side rung**, like step 9. Steps 7 and later stay as they are, and the 20.4 numbers for steps 7 and up remain valid.
- **(b) Carry the charge on from step 6**, so the ladder is cumulative. Every later step then changes on the debt side (and on the SuMSy side under P, if D8a is reversed).
- **Default:** (a).

**D9a. The switch's setting.** It matters under debt money only, because SuMSy has no deposit interest (D4).

- **Default:** on, as now, so that the 20.4 debt village is reproduced.
- In the full ladder, add an "off" cell at steps 3, 8 and 11 on the debt side.

**D10. Which cost of holding money sets the SuMSy levy (D5).**

- The levy formula uses the cost of holding cash: under SuMSy, 2 % + 1.5 % = 3.5 % a month.
- The land-price code (`seller_alternative`) uses the better alternative, lending through the bank at −1.5 % a month.
- If the levy is meant to make land no better a store than the best use of money, it should be based on 1.5 % plus the margin.
- Related: under debt money the formula uses the promised deposit rate, not the fraction actually paid (§3.12).
- **Default:** unchanged until Stef decides. The partial run reports the rates actually charged (§3.5).

---

## 3. What the code must do

**3.1 A new setting, `fiscal`, on `run_all`.**

- It takes one of three values:
  - `:own`, the default: the ladder exactly as it is now;
  - `:taxes`: package T on both sides;
  - `:parking`: package P on both sides.
- It travels inside the job, like `variant` does, because workers do not see main-process globals.
- It becomes part of the folder name, combined with the variant label. For example: `ladder2_512_fiscal_taxes_120months_<version>` and `ladder2_512_realistic_fiscal_parking_120months_<version>`.
- The summary and rungs files carry the same suffix and gain a `fiscal` column.
- It works together with `variant`, `rungs`, `seeds`, `shard` and `summary_only`.

**3.2 How the ladder is built under `:taxes` and `:parking`.** Each rung is made of three parts:

- **(i) the rung's institutions:** theatres, shares, co-ops, price rules, greed and so on. These are already identical on both sides.
- **(ii) the fiscal package for that step**, from §2. It is written once per step and applied to both sides; it must not be written twice.
- **(iii) the money, from D1.** This is the only part chosen by `system`.

**3.3 Step 8 under the common packages.** Step 8 carries shares, the share market, the land levy with its dividend, and the reserve, on both sides. The full ladder splits these apart (§6).

**3.4 The guard.** The guard "SuMSy must not tax income" stays in force for `:own`. Under `:taxes` and `:parking` the test of §3.5 replaces it.

**3.5 A new test, in `test/`,** so it runs with the suite and counts in the code fingerprint.

- For every two-sided rung under `:taxes` and under `:parking`, the test builds both full parameter sets.
- It asserts that the two sets differ only in the D1 fields. Allow the step-3 and step-5 settings (deposit interest, bonds) to differ only in the direction D3 and D4 give: on for debt money, off for SuMSy.
- Any other difference fails the test, with the field name and the rung in the message.

This checks the rule directly, so nobody has to rely on reading the definition file.

The land levy rate and the land price are computed from the money's return rate. Two parameter sets that are equal can therefore still charge different levies. For this reason, also report the levy rate actually charged at step 8, on both sides and in both packages, in months 1 and 120. This is a reported number, not a test failure.

**3.6 `scripts/dump_rungs.jl`.**

- Report `parking_tax` (`demurrage_tax_rate`) for both moneys. `parking_fee` stays SuMSy-only.
- Add a column for every fiscal field the test compares: levy on or off, levy dividend, surplus rule, the enterprise charge. Add a column for every money field from D1: deposit interest, loyalty bonus, bonds, peer loan rate, bank spread, account fees. With these, the rungs CSV shows the full package and the full money for each row.

**3.7 Regression check.** `fiscal = :own` must reproduce the current base exactly, except for the SuMSy side of step 6, which the fix in §3.11 changes.

- Compare step 2 and step 8, both moneys, seed 1, every month, against the latest base parts.
- If they differ, stop and report before running anything else.

**3.8 `MODEL_VERSION`.** Set a new version per the date rule. Because `:own` reproduces the old behaviour, the 20.4 base remains the talk's base, and nothing in its folder is rewritten.

**3.9 The analysis scripts.** `scripts/paired_tests.py` and `scripts/report_numbers.py` must accept the fiscal folders. Paired tests compare debt and SuMSy seed by seed within one package, never across packages.

**3.10 Standing rules.**

- Nothing may follow a comment on a `RULES` line (the bug of 18 October).
- The code package contains every non-results file in the repository.
- No run-time estimates.

**3.11 Fix the double demurrage (D8).** Under SuMSy the enterprise charge must not apply to the cash of farms, bakeries and theatres, because the fee already applies to that cash.

- **Where to fix it:** in the model (`tax_enterprises!` in `src/credit.jl`), not only in the ladder definition. That way no future rung can reintroduce the double charge.
- **The rungs CSV:** it shows `charge_on_balances = 0` for every SuMSy row.
- **A new test:** in a SuMSy village with `enterprise_tax = :reserves`, no non-bank enterprise pays both the fee and the charge on the same month's cash.
- **Banks:** the charge also falls on banks, based on their retained interest. Report what that does under SuMSy, where banks earn from the spread. If it is also a charge on money already under the fee, tell Stef before changing it.
- **Rerun:** step 6, SuMSy side, in the `:own` ladder.

**3.12 The deposit-interest switch (D9).** Add a parameter, for example `loan_rate_covers_deposit_interest::Bool`, defaulting to the current behaviour (on).

- In `set_interest_rates!`, the deposit cost enters the loan rate only when the switch is on.
- It appears as a column in the rungs CSV.
- It is a money setting (D1), so the identity test of §3.5 must allow it.
- While in this code: the land levy formula (`money_return_rate` in `src/markets.jl`) uses the promised deposit rate. Report the fraction actually paid out per year at step 8 (debt side, both packages), so Stef can judge D10.

---

## 4. The partial run (for the talk)

**Steps:**

- Priority 1: 0, 2, 8 and V8 (the productive village).
- Priority 2: 11 and S3 (everyone greedy).

**Settings:** both packages, both moneys, 4 seeds. Run the base labour market first, then the realistic one.

**Step 0:** it has no government, so the package makes no difference. It runs once, in the `:taxes` folder.

**Rung prefixes:** `run_all` matches rungs by prefix, so `"V8"` would also catch V8-P, V8-NDC, V8-NJ and V8-J100, and `"S3"` would catch every S3 variant. Use `"V8 "` and `"S3 "` with a trailing space.

The intended calls are below. The code chat makes them work as written, or tells Stef what differs:

```
include("scripts/run_all.jl")

# priority 1 — base labour market
run_all(seeds = 4, fiscal = :taxes,   rungs = ["0", "2", "8", "V8 "])
run_all(seeds = 4, fiscal = :parking, rungs = ["2", "8", "V8 "])

# priority 1 — realistic labour market
run_all(seeds = 4, fiscal = :taxes,   rungs = ["0", "2", "8", "V8 "], variant = REALISTIC_LABOUR, variant_label = "realistic")
run_all(seeds = 4, fiscal = :parking, rungs = ["2", "8", "V8 "],      variant = REALISTIC_LABOUR, variant_label = "realistic")

# priority 2 — the same four calls with rungs = ["11", "S3 "]

# summaries, one call per folder
run_all(summary_only = true, fiscal = :taxes)    # and :parking, and both again with the realistic variant
```

**Size, in jobs** (one job = one village, one seed, ten years):

- Priority 1: 56 per labour market, 112 in total.
- Priority 2: 32 per labour market, 64 in total.
- For comparison, a full 10-seed ladder is about 1,910 jobs.

**Seeds:** where a cell swings (wide `_p5`/`_p95` bands, or a worst run far from the mean), rerun that rung with `seeds = 1:10`.

**What the talk needs from each cell** (step × package × money):

- alive at month 120, mean and worst run;
- public debt at month 120, its peak, and the month it is repaid;
- bread price change per year;
- Gini of cash and Gini of wealth;
- the poorest tenth's wealth in meals;
- the paired test within each package.

**What stays on 20.4.** Comparisons inside one village do not compare moneys and need no rerun:

- the debt ceiling (D8-60), austerity (A8), and the basic income cells (EU8, DGI8), each set against the debt village's step 8. The talk quotes these against 20.4's debt step 8 (488 alive), never against a new step 8;
- the greed-against-sufficiency strategy runs, as long as the talk compares strategies within one money only.

**Not in the partial.** PL8 (public land) does compare the two moneys. If the talk uses it, add `"PL8 "` to priority 2; otherwise leave it out of the talk.

---

## 5. Corrections to the talk handoff (`handoff_talk_2026-10-22.md`)

The code chat keeps the handoff up to date. It should make these changes now:

- **§1 and §6.** Replace "same fiscal and market rules … is already the ladder's design" with what is true: the 20.4 ladder gives each money its own fiscal package, and the common-package runs are under way.
- **§4, step 11, debt village.** 436.5 alive (worst run 408), bread −10.9 % a year, poorest tenth −4.7 meals. The handoff says about 485.
- **§4, SuMSy start-up debt.** 4,870, repaid by month 33 at step 2; 608, repaid by month 22 at step 8. The handoff says "about 4,000, repaid by year four", which comes from the 24 September run.
- **§4, inequality.** SuMSy's lower wealth Gini holds from step 8 on. At steps 2 to 7 both villages sit at about 0.74.
- **§4, paired tests.** At step 5 the poorest tenth holds 3.9 meals in SuMSy against 4.8 in the debt village (ten-run means). Check the claim "10 of 10 at every headline step" against the step list the tests actually used.

When the partial results are in, add a §4b with the common-package numbers.

---

## 6. The full side-by-side ladder (runs alongside the talk work)

**Scope:** every rung under `:taxes` and `:parking`, both moneys, 10 seeds, sharded over the two machines.

**Reuse of the partial run.** The partial run's folders are the full run's folders, because the folder name holds the version, the variant and the package, not the seed count. A 10-seed call therefore skips the seeds the partial run already finished.

**Step 8 split into two rungs:**

- "8 + shareholders & share market": the shares only;
- "8L + land levy and dividend": cumulative on 8.

The reserve stays at step 10 for both moneys. Rungs that build on `V8_*` today build on 8L, so they keep the levy.

**Default treatment of the rungs that are one-sided today** (Stef confirms or changes):

- **Made two-sided under the same rule:**
  - debt ceilings: D2, D8 and D10 variants, D8-60;
  - austerity: A8, A10. Under the common packages SuMSy has a benefit to cut;
  - benefit fixed in money: I2, I8, I10;
  - buyers who overpay: W variants;
  - land: L2, LPT8, PL8-X, PL8-B;
  - public employment: U8, U8-P, UP8, UP8-P;
  - the parking-tax policy GP10-*, under package P only.
- **Money-only, SuMSy side only, labelled as such:** E, F and FF (the money stock and the fee rate).
- **Subsumed by the new structure:**
  - Z8 and RZ8 ("without the levy" is the new step 8 on both sides);
  - X1 and X2 (the package dimension replaces them);
  - RB8 and RB11 (the realistic variant replaces them).
- **Kept as labelled cross-money probes on the debt side:** DGI8, DD8, DDL8, DDGL8, DDGL8-35, DDL8-PT, EU8, and RV8's debt side.

**Steps 3 and 5 under the common packages** change the debt village only (D3, D4). Run both sides anyway, so that the ladder stays side by side. The SuMSy side repeats step 2 or step 4, and the summary marks it as the same village run again.

**New cell, if Stef chooses it under D2:** the benefit as a top-up.

---

## 7. What the code chat reports back

- The result of the test in §3.5: pass, or the list of rungs and fields that differ.
- The result of the regression check in §3.7.
- The land levy rates actually charged at step 8, per money and package, in months 1 and 120.
- The folder names of the partial runs, and which summaries have been rebuilt. Stef decides when anything runs.
- The results of §3.11 (SuMSy banks under the charge) and §3.12 (deposit interest actually paid).
- The handoff changes from §5, and later §4b.
