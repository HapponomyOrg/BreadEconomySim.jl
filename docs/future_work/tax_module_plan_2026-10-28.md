# A tax module for the refactor — plan

*28 October 2026, decisions added the same day (§10); the plan is complete and ready for specification. Planning only: nothing is implemented. Stef's brief: a tax module comparable with MoneySim.jl's tax scheme, without its side effects; per-source control of what a tax change does; per-source destinations (handouts and/or the budget); handouts that can be fixed, tied to revenue, and targeted — taking into account what an actor already receives from other sources.*

## 1. Why a module

The bread model's fiscal rules grew one switch at a time: a wage tax with a schedule, capital, dividend and profit taxes, VAT, a tax on balances above a cushion, a land tax with its own lever, floor and dividend, three tax policies, a surplus rule, a reserve, a benefit, a meal-sized basic income, public jobs. Each works; together they interact through special cases. Two of those broke this week: step 10's reserve was silently undone for the SuMSy village by a line that forces the land tax's surplus to be paid out per head (a fix of 12 October for a different problem), and a budget-balancing policy pushed the wage tax past 100 %, which turned the public wage negative. A module with one coherent model of *where a tax comes from, how it moves, and where its revenue goes* removes the special cases instead of adding more.

It belongs in Step 9 of the MacroSim roadmap (the fiscal registry), built so that MoneySim.jl can use it as well.

## 2. What exists

| | BreadEconomySim.jl (today) | MoneySim.jl (`src/tax_scheme.jl`) |
|---|---|---|
| tax sources | wages (flat, or a progressive schedule with social contributions and a municipal surcharge), capital, dividends, profit or enterprise reserves, VAT on purchases, balances above a cushion (the parking tax), a demurrage tax, the land tax | income, or a stock tax on balances above the demurrage-free amount ("demurrage tax"); VAT |
| rate structure | flat rates and one bracket schedule; scales per family | tiers (brackets) for either base |
| moving the taxes | three policies (`:scale`, `:brackets`, `:levers`) with a standing tilt per family (`tax_levers`), a step limit and a coverage target; the land tax excluded when it funds the dividend | scale the brackets to a target revenue (floors 0.1 %, ceiling 95 %) |
| where revenue goes | into the government's account; surplus rules (reserve, then repay debt or cut taxes, or pay out per head); the land tax paid out per head where the dividend is on | split equally over a fixed set of "tax recipients" |
| handouts | land dividend per head; a basic income that tops income plus the dividend up to a meal (debt village, parking package); an unemployment benefit | the equal split itself |
| deficits | the government borrows (bank loans, bonds, peer loans) on its balance sheet | "deficit spending": projected expenses are distributed and a number `debt` is raised |
| timing | monthly (yearly as a switch) | a calculation interval and a shorter collection interval (taxes collected in slices) |

## 3. MoneySim's side effects — what the new module must not do

Each item is observed in `src/tax_scheme.jl` (commit `28c3a0d`, 18 Sept 2026).

1. **Hidden state on every actor and the model.** `initialize_tax_scheme!` adds a dozen fields to every actor (`income`, `taxable_income`, `tax_to_pay`, `tax_deduction`, `vat_eligible`, `data_*` …) and to the model (`tax_recipients`, `debt`, `tax_scale`, `tax_brackets`, …). Other code must know and maintain them (e.g. `actor.income` is added to the tax base every step by `register_income_and_expenses!`, so whoever sets it must also reset it).
2. **Behaviours registered as a side effect of initialisation.** Initialising the scheme appends model behaviours; their order relative to everything else is implicit.
3. **Calculation that mutates.** `calculate_taxes!` resets `taxable_income` and `tax_deduction` and writes `data_net_income` while computing what is owed: computing and booking are not separable, so a tax cannot be evaluated without changing state.
4. **Money from nothing in a deficit.** With `deficit_spending`, projected expenses beyond the revenue are booked onto recipients' accounts and a plain number `model.debt` is raised; no liability appears on any balance sheet, so stocks and flows no longer reconcile.
5. **No government account.** Revenue is taken from payers and handed straight to recipients; there is nowhere to hold a reserve or account for a budget.
6. **Taxes can empty an account.** When a tax or VAT slice cannot be paid, the whole SuMSy balance is taken and a failure counted; there is no protected minimum.
7. **Coupled to one money.** Every booking uses the `SUMSY_DEP` entry; the scheme cannot run on debt money.
8. **Arbitrary recipients and a global random draw.** Recipients are the first *N* actors by id; the rounding remainder goes to `rand(1:N)` on the global generator, which makes runs depend on everything else that draws from it.
9. **VAT on income.** `vat_eligible` accumulates income received, so the "VAT" is a second income tax rather than a tax on purchases.
10. **Ever-growing strings as data.** `model.tax_scale` and `model.tax_brackets` are appended to every period.
11. **A fragile scaling loop.** `scale_brackets` rounds rates to 0.01 and, when the scaling stalls, appends raised brackets to a list that already holds the scaled ones — duplicates rather than replacements.

## 4. Requirements

### 4.1 Sources and bases
A *source* is a named tax with a *base* (what is taxed), a *rate structure*, a *payer set* and a *collection calendar*. Bases are pure functions of the state at assessment: income by kind (wages, capital income, dividends, rents, interest, transfers received), sales (VAT — *decided 28 Oct:* the seller charges it, holds it as a debt to the government and remits it on the collection calendar, as in Belgium; two variants, to study their systemic effect: **on final sales only**, or **on every sale, with the VAT paid on inputs deducted when the VAT is remitted**. The revenue is the same; the difference is behavioural — a seller that spends what it should keep for the remittance cannot pay, so the VAT held is not set aside automatically, and an unpaid remittance is a tax arrear like any other; a seller that fails first leaves its VAT unpaid), profit (with deductions), stocks (balances above a cushion, wealth, land), transactions. SuMSy's demurrage is part of the money and stays outside the tax system (standing principle); a demurrage *tax* or parking tax is a stock source like any other.

### 4.2 Rates
Flat, tiered (brackets with exemptions or cushions), or a schedule (social contributions, surcharges). Every rate is capped at `maximum_rate` (90 % by default) **in every bracket**, which caps the total as well, and floored at zero; for a schedule the cap applies to the combined rate of a bracket (contributions, tax and surcharges together).

### 4.3 What a change of policy does to each source
Each source carries weights for how much it moves when taxes are **raised** and when they are **cut** (0 = untouched, 1 = moves with the policy, other values tilt it) — *decided 28 Oct:* set separately for the part of the source that goes to the **budget** and the part that goes to **handouts**; by default the policy acts on the budget part only (handout weights 0). A source whose revenue is entirely handed out is then untouched by default — which replaces today's special case for the land tax — and can still be moved by giving its handout part a weight.

### 4.4 Destinations
Each source splits its revenue between **handouts** and the **budget**, e.g. land tax (0.2, 0.8): a fifth handed out, four fifths to the budget. The budget is one pool: it covers spending, fills the reserve, and any surplus follows the budget rule (4.6). The reserve is a property of the budget, not of a source.

### 4.5 Handouts
*Decided 28 Oct (Stef): targeted handouts top up **net income over a chosen period**, one month by default (the simulation aims to lift every income to at least two loaves a month); what counts as income is set by a **list of income weights**, one per source, each between 0 and 1, all 1 by default; fixed handouts come first and are on that list; shortfalls are split between borrowing and paying out less by one number between 0 and 1, set by the tax policy. The general description follows.*

A handout has a **kind**, **eligibility**, **funding** and a **shortfall rule**:
- *fixed*: an amount per eligible actor per period (in money, or in goods at a stated price — e.g. two loaves at the price paid);
- *revenue-linked*: a share of a source's revenue, divided among the eligible (per head, or by a key);
- *how the kinds differ*: a fixed handout pays a stated amount per recipient; a revenue-linked one divides what a source actually raised (the same for everyone, larger in a good year — Gesell's land dividend, Alaska's dividend; it can never fall short); a targeted one pays each recipient the gap between the target and their own weighted net income (its cost follows incomes, not revenue, so it can fall short of its funding);
- the weights also give a policy instrument: a labour weight below 1 lets part of what someone earns not reduce their top-up, so working still pays (see the caution in §10).
- *targeted*: a top-up to a target given by a **target function** (*decided 28 Oct:* replaceable; the default returns the price of two loaves for a month, at the price paid), net of what the actor **already receives from other sources**: top-up = max(target − Σᵢ wᵢ × net incomeᵢ, 0) over the chosen period (one month by default), where i runs over the income sources — labour (wages, public wages included), dividends, rents, interest, the **guaranteed income, gross**, benefits, and every fixed or revenue-linked handout — and each weight wᵢ is between 0 and 1 (1 by default: the source counts in full; 0: it is ignored). *Decided 28 Oct:* the guaranteed income counts gross; a test on what an actor holds is **not** part of the default — it would reward spending everything to qualify — but exists as an optional eligibility condition for research (the means test below). Accepted consequence of the default: an actor with a large balance and little income (a landowner between rents) qualifies like anyone else with that income; in the SuMSy village the parking fee already discourages holding money idle;
- combinations: fixed handouts are paid first and appear on the weight list; the targeted top-up is computed afterwards (§7).
Eligibility (*decided 28 Oct*): **persons only**, living; an **unemployment switch** (only the unemployed qualify); and a **part-time weight** *q* ∈ [0, 1] saying how far part-time work counts as unemployment (*decided 28 Oct:* a part-time worker's eligibility is *q* × the share of the hours they offered and could not sell; *q* = 0: part-timers do not qualify; *q* = 1: in full proportion to the hours they lack). A **means test** (*added 28 Oct, off by default, for research*): when switched on, the top-up is **tapered** by default — reduced by a share *t* ∈ [0, 1] of the assessed means above a threshold, so it fades out without a cliff — or, as the alternative form, **gated**: an actor qualifies only if their assessed means are at or below the threshold. The means are Σⱼ vⱼ × holdingⱼ over the asset classes — money (deposits and SuMSy balances), land, shares, bonds, gold, loans made to others — each with a weight vⱼ in [0, 1] (so a test can be on money alone, on other wealth alone, or on both), valued as the outputs value them (shares at book, land at the land price, gold at its valuation); the threshold is a replaceable function like the target (e.g. a number of months of the target). Applies identically in both villages. Funding: from the source's handout share, then the budget. **Shortfall** (funding below what the handouts require): a share *b* ∈ [0, 1], set by the tax policy, is borrowed and the rest, 1 − *b*, is not paid — every handout scaled down pro rata (*b* = 1: borrow it all; *b* = 0: pay out what there is). Today's land dividend, the meal-sized basic income and the unemployment benefit become three configurations of this one mechanism.

### 4.6 The budget
A government account on the balance sheet: revenue in; public wages, purchases and budget-funded handouts out; a reserve target (months of spending); a deficit financed by instruments that appear as liabilities (bank loans, bonds, peer loans in debt money; SuMSy's rules in SuMSy); a surplus rule (fill the reserve, then repay debt, cut taxes or pay out — each a share). Debt service by its terms.

### 4.7 Timing and collection
An assessment period and a collection calendar (monthly, yearly, withholding with a yearly balance); slices allowed (as in MoneySim). *Decided 28 Oct:* a tax that cannot be paid in full becomes a **tax arrear, handled the same way as a debt arrear** — collected from what the actor holds in later periods, counted in arrears, and for a firm leading to liquidation by the rule that applies to its other debts, and settled from the estate on death — with a **protection of two loaves** when switched on: no collection takes a person below that floor (the bread model's collection floor; the floor uses the target function by default, so it moves with it).

### 4.8 Both monetary systems
The module books through the money's interface, never a specific balance entry, so it runs unchanged on debt money and SuMSy. A comparison runs both villages on the same tax configuration (the same-rules test carries over).

## 5. Design principles — no side effects
1. **Assess, then book.** Assessment is a pure function from state to a *tax statement* (who owes what, who receives what, budget lines). A single step books the statement. A statement can be computed, inspected and tested without changing anything.
2. **Explicit state.** The module's own state (accrued bases, amounts due, reserve, accounts) lives in one typed struct owned by the government, not in properties sprinkled over actors.
3. **Double entry only.** Every flow is a transfer between two accounts through one function that refuses negative amounts and asserts the money identity; deficits create liabilities through the financing instruments.
4. **Explicit order and randomness.** The caller places the module's steps in the month; any random draw uses a generator passed in.
5. **Typed configuration, validated once.** Sources, destinations, handouts and the budget rule are immutable configuration objects checked at construction (shares sum to 1, caps below 1, no handout without funding).
6. **Data by observation.** Statements and account balances are recorded by an observer; the module keeps no growing logs.

## 6. Sketch of the types (to be refined in the specification)
`TaxSource(name, base, rates, payers, calendar, levers = (raise, cut), destination = (handout, budget))` · `RateSchedule` (flat, tiers, schedule; cap) · `Handout(kind, amount_or_share_or_target, eligibility, income_definition, funding, shortfall, order)` · `BudgetRule(reserve_months, surplus_shares, financing)` · `FiscalConfig(sources, handouts, budget_rule, policy)` · `TaxStatement` (per actor: assessed, collected, received; per source: revenue, handed out, to budget; budget: in, out, reserve, financing) · `assess(state, config) → TaxStatement` · `book!(ledger, statement)`.

## 7. Order within a period
1 assess the bases accrued → 2 collect (respecting the floor) → 3 split each source's revenue by destination → 4 pay the fixed handouts → 5 pay the revenue-linked handouts → 6 compute each eligible actor's weighted net income over the period, the handouts of 4 and 5 included, and pay the targeted top-ups → 7 settle the budget: spending, reserve, surplus rule; a funding shortfall split by *b* between borrowing and paying out less → 8 policy: move each source by its raise/cut weights for the next period → 9 record.

*Timing:* the top-up needs the period's incomes, so it is computed once wages, dividends and rents for the period are known (the end of the month), and paid then; the first month uses the starting incomes.

## 8. Tests and acceptance
- **Invariants**, every period: the money identity; revenue = collected; Σ destinations = revenue; budget closes (in − out = Δaccount); no negative transfer; no payment to a dead actor; no rate above the cap; no person below the floor.
- **Reproduction of the bread model**: a configuration that reproduces today's fiscal behaviour exactly (golden values of `2026-10-28.x`): land (1, 0) where the dividend is on and (0, 1) otherwise, the meal-sized basic income as a targeted handout, the benefit as a targeted handout to the unemployed, the surplus rule. Then remove the special cases (ladder line 314; the land exclusion in the policy) and show the results unchanged.
- **Comparison with MoneySim**: its test cases run through the new module where the behaviour is intended to match (tiers, scaling to a target revenue, calculation and collection intervals), with each deliberate difference documented (the side effects of §3).
- **Property tests**: random configurations and states; the invariants hold.

## 9. Phasing
1. **Specification** (this plan → a full specification with the decisions of §10): a week of design, no code.
2. **Statement and invariants**: the pure assessment and the test harness, against small hand-built states.
3. **Sources and rates**, then **destinations and handouts**, then **the budget and financing**, each step with its invariants.
4. **Reproduction**: the bread model's fiscal behaviour through the module, golden values matched; then the special cases removed.
5. **Integration** into MacroSim (Step 9). *Decided 28 Oct:* the module is part of MacroSim; MoneySim.jl will be merged into MacroSim, so its tax scheme is replaced by this module there too.

## 10. Decisions

**Taken (28 Oct, Stef):**
- Targeted handouts top up **net income over a chosen period, one month by default**.
- **Income weights**: one per income source (labour, dividends, guaranteed income, …), each in [0, 1], all **1** by default.
- **Fixed handouts first**, on the weight list; then the targeted income is computed.
- **Shortfalls**: one number *b* ∈ [0, 1] set by the tax policy — the share borrowed; the rest is not paid out.
- **The module is part of MacroSim**; MoneySim.jl will be merged into MacroSim.
- **The target** is a replaceable function; the default returns the price of two loaves (a month, at the price paid).
- **Income**: the guaranteed income counts **gross**; no test on money held (it would reward spending everything to qualify).
- **Eligibility**: persons only; an unemployment switch; a part-time weight *q* in [0, 1] — eligibility = *q* × the share of offered hours not sold.
- **Handout order**: fixed, then revenue-linked (kept as its own kind, on the weight list), then targeted last.
- **A means test** on eligibility exists, **off by default**, for research: weighted holdings of money and other wealth (land, shares, bonds, gold, loans made) against a threshold function; gross of debts by default (a switch for net); when on, a **taper of 2 % a month** of the means above the threshold by default (close to the UK's Universal Credit rule), with a gate as the alternative.
- **Tax arrears** are handled as debt arrears, with a protection of two loaves when switched on.
- **Policy moves** act on the budget part and the handout part of a source, each with its own weights; by default on the budget part only.
- **The rate cap**: 90 % by default, in every bracket (so in total).
- **VAT** is collected by the seller and remitted later (Belgian practice), in two variants for research: final sales only, or every sale with input VAT deducted at remittance.
- **Timing**: monthly assessment by default; yearly, and withholding with a yearly balance, as options.

- **Late interest on tax arrears**: a rate set by the tax policy, **0 by default**.
- **The protection floor follows the target function** by default, so it moves when the target is replaced.

**Still open:** nothing. The plan is ready to be worked out into a full specification (phase 1 of §9).

**A caution on the weights.** With every weight at 1, a villager below the target loses one loaf of top-up for every loaf earned — an effective marginal tax rate of 100 % on the first two loaves, the welfare cliff of means-tested benefits. In the bread model labour supply is need-based (a villager offers the hours that cover a meal less other income), so a full top-up can lower the hours offered by those below the target. The labour weight is the instrument against it (0.5: half of each loaf earned reduces the top-up); the first runs should report hours offered and accepted below the target for a few labour weights, not only survival.

## Status of related work
The tax-rate cap for the bread model (`maximum_tax_rate`, 90 %) is written in the working copy but not yet checked or committed; it is a bug fix for UP8/UP8-P and independent of this module. Step 10 waits for the module (with per-source destinations it can mean "surplus returned as tax cuts" without special cases).
