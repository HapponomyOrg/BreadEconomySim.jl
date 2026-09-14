# BreadEconomySim.jl v2 — handoff (11 September 2026)

## State of the code
Package rewritten for spec v2: two agent types (`Person`, `Enterprise` of kind bank/farm/bakery/government),
EconoSim.jl at commit cad156e (`process_debt!` with partial payments is the servicing engine; arrears, garnishment,
seizure, closure and estates are in `src/credit.jl`). Money identity Σ deposit assets − Σ bank deposit liabilities +
lost = 0 to 1e-14 in every run. v1 code is kept in `../BreadEconomySim_v1`. `scripts/probe.jl` is the batch driver.

Implemented as agreed: two banks with interbank lending at a discount; bank wage paid by deposit creation capped by
retained interest (bank equity is monetised to service its own debts too); rate = wage bill /
(affordability × (outstanding loans + last round's credit demand)); surplus above 2× standard reserve → wage bid;
enterprises hire and post prices, persons post wage asks; labour supply = minimise work to meet needs; landowners
work; government hires leftover labour up to 10 % of capacity at a net wage of 2 breads + 10 %, taxes all person
income (30 % wages, 15 % rent), pays the graded unemployment fee (2 breads / last wage, −10 % every 3 rounds,
floor 1 bread, spell resets after 3 rounds of work), borrows at half the rate, always approved, never seized;
enterprise failure: cash then land seized, closure when uncovered; heirs: random living person gets cash and land;
everyone starts with one meal in stock.

## Deviations / open readings (flag before publishing)
- Worker wage reservation is gross (meal ÷ 3 = 3.33). Grossing up for the 30 % tax (4.76) exceeds both employer
  ceilings (farm 4.0, bakery 4.5) and no private hiring occurs at all. With the gross reading a full-time worker nets
  7 < one meal (10): tax-funded fees and government jobs are what close the gap. Decide which is intended.
- Fees are paid before the bread market (my choice: the fee exists to stop the death spiral).
- "Unemployed" = offered labour and sold none; someone selling one unit is employed and unsupported.
- Bank `process_debt!` books interest against the deposit liability; the bank's spendable money is created against
  retained interest (`monetise_equity!`), so money creation for bank wages/debt service is logged as such.
- Loans issued in a round are first serviced the round after (spec §6); v1 code serviced them the same round.
- `reserve_protection_probability` (new parameter) lets enterprises use own cash first (0) or borrow first (0.5).

## Result: still not viable — but the collapse mechanism has changed and is now economic, not credit-technical
Every run ends by round 6–13 (4 seeds × 6 variants, `results/probe.csv`). Round 1–2 work at full output
(36 breads, 42 labour units, all fed). Two mechanisms, both visible in the event log (`/tmp/trace2.jl` pattern):

1. **Start-up margins vs amortisation (farms).** At the initial price vector value added is 0.5 per grain unit
   (5.5 − 1.5 − 3.5) and 1.0 per bread pair (10 − 5.5 − 3.5). Round-1 working capital (32 per farm, 55 per bakery)
   is credit on 5-round terms → installments 6–11 per round against margins 3–6 per round → arrears in round 3,
   credit blocked, no rent/hiring, closed in round 4. Terms of 15–30 rounds delay this by 1–5 rounds only.
2. **Saturated demand vs the price/target adaptation (bakeries).** Persons buy exactly one meal: demand is fixed at
   32 breads. Three bakeries at target 6 bake 36; the 4 unsold breads trigger "partly unsold → ask −6 %" every round
   while farms sell out and raise grain +6 %. By round 2 bread is 4.68 and grain 5.9: 2×4.68 − 5.9 − 3.7 < 0, the
   bakeries sell below cost until closed. The cost floor (reservation) lags one round and does not protect them.
   Integer targets cannot represent 16 grain across 3 bakeries without oscillating between 30 and 36 breads.

After the closures: unemployment → fees → government borrows (the deficit dynamic works as designed), then hunger
and deaths.

## Recommendation
Before the next run, derive the initial price vector analytically instead of by hand: a static consistency check
that (a) each link's margin covers its amortisation at the chosen term, (b) persons' net income (wages after tax +
rent + fees + government wages) equals the bread bill at the bread price, (c) the tax take equals government
outlays. Then fix the bakery adaptation: cut the ask only when stock is left *and* it is ageing, or let the
reservation floor use this round's actual input prices. Both are one-line changes once the price vector is
consistent. I can do the algebra and propose the vector next.


## Addendum, 11 September 2026 (evening): consistent price vector, remaining collapse, and an open inconsistency

**Static consistency check** (`/tmp/static.py`, reproduced in `scripts/static_check.py`): with output = demand
(32 breads, 16 grain, 16 land, 34 private labour units), a full-time worker must gross 2b/(3(1−t_w)) per unit to
net one meal. At t_w = 0.30 that is 4.76 → the private wage bill alone (162) exceeds the value of all bread (160):
**no price vector is feasible at 30 % wage tax**, at any loan term. Feasible region: t_w ≤ 0.15 with loan term ≥ 20
(t_w = 0.20 only with term ≥ 20 and rent ≤ 0.5). A per-capita return channel (guaranteed income U) relaxes the
constraint to w ≥ (2b − U)/(3(1−t_w)) — i.e. the SuMSy instrument changes the feasibility set, which is worth
stating in the paper before any simulation.

**New defaults**: bread 5, grain 5.2, rent 0.75, wage 3.92, wage tax 0.15, capital tax 0.15, loan term 20.
Margins at these prices: farm 0.53/unit (needs ≥ 0.38 for 8 % amortisation+interest), bakery 0.88/pair (≥ 0.73).
Other changes: bakery reservation floor uses this round's actual grain and wage prices; an unsold remainder of at
most one grain-unit of bread (`unsold_tolerance_units = 2`) triggers neither the −6 % ask cut nor the −1 target cut,
for farms and bakeries alike.

**Result**: collapse moves from round 6 to rounds 9–11 on all 5 seeds; farms now mostly survive, bakeries do not.
The per-enterprise table (`scripts/diagnose.jl`, `results/diagnose_seed1.csv`) shows the chain: bakeries hire
labour before the grain market (spec order §4.3 before §4.6) and repeatedly find no grain; farms cut targets
6→5→4→3 while holding unsold grain; by round 5 two bakeries hire nothing and stock is zero. The aggregate demand
cap (32 breads) plus integer ±1 targets on three identical producers is the coordination failure; the tolerance
rule did not stop it (seed-1 numbers identical before and after), so the cut is coming through another path —
most likely the bakery `wanted_input = min(hired labour, target) − stock` shrinking after a round with leftover
bread, which then leaves farms with unsold grain.

**Open inconsistency to resolve first**: in round 2 the per-bakery market records show offered = 12, sold = 0 for
all three bakeries while the aggregate reports 32 breads sold, and the bakeries' asks then diverge (4.5 / 3.99 /
2.97), which they could not if all three records had been idle. Either the diagnostic reads stale state or
`market[:bread]` is being reset or shadowed inside the bread market. Check `bread_market!` and `record!` ordering
with `scripts/diagnose.jl 1 3` before interpreting any bakery result.

**Recommended next step**: (1) resolve the inconsistency; (2) move the bakery's grain purchase before its hiring
(or let it hire only up to grain in stock + expected purchases); (3) rerun `scripts/probe.jl`. If bakeries then
survive, the baseline is ready for the 20-seed batch and the SuMSy variant (drop banks, add `guaranteed_income`
and `demurrage` on person and enterprise balances; the static check gives the feasible tax/GI region directly).

## Addendum, 11 September 2026 (late): gluttony and stocking; clearing proposal
- Gluttony/stocking implemented in `markets.jl` (`gluttony_and_stocking!`, `buy_extra_bread!`), parameters
  `gluttony_probability = 0.10`, `maximum_breads_per_round = 3`, `stocking_marginality = [(3,1.0),(4,0.5),(5,0.3),(7,0.15)]`
  (EconoSim `Marginality` semantics, re-implemented on the model RNG because EconoSim's `process` uses the global `rand()`).
  Affordability: cash including savings, no credit. A glutton eats up to 3 breads at `eat!`; stock beyond that ages normally.
- Activity: at 0.25 there are 1–4 gluttons per round and 1–5 breads stocked; at 0.10 about 6 glutton-rounds per run.
  Effect on the collapse regime: bread output per round rises (17 → 19–23) and unemployment falls slightly, collapse timing
  unchanged (rounds 9–13). Runs are reproducible (three identical seed-1 runs give identical trajectories).
- Clearing (proposed, not implemented): all intra-round payments as promises, netted at step 13. Solves working-capital
  credit and the payment-order problem; does not solve the goods-order problem (bakeries hire before the grain market).
  Needs a default rule at clearing — recommended: priority settlement (tax, wages, inputs, debt service) with the unpaid tail
  as trade-credit arrears to the counterparty. Also shrinks the banks' loan book (rates will rise) and introduces
  interest-free counterparty credit, which weakens "all money enters as bank credit" — state as a modelling choice.

## Addendum, 11 September 2026 (night): clearing system, grain-before-hiring, two bug fixes — enterprises now survive

**Implemented (spec v2 addendum, agreed):**
- Clearing: every intra-round payment is a `Promise` (model.jl); `clear!` (credit.jl, step 12) finances each agent's net
  deficit once (banks monetise equity first, then interbank; others: savings/reserve rule on the net, credit on the
  shortfall), then settles by fixed-point iteration in priority order (0 trade arrears carried, 1 tax, 2 wages and fees,
  3 inputs incl. land). Unpaid tails become priority-0 trade arrears to the counterparty next round (`trade_arrears`
  column). Debt service runs on cash after clearing. `fund!` is now trivially true; wages are promised at hiring.
- Round order: land → labour (farms, banks) → harvest → grain market → labour (bakeries, up to grain in stock) → bake →
  government hiring → fees → bread market → clear → debt service → eat → age → record/adapt.
- Two bugs fixed that had distorted every v2 result: (a) `log_event!` kinds for loan/refusal/missed/closure/seizure were
  overwritten by an `agent_kind` kwarg named `kind` — those events were invisible in all earlier traces; (b) the arrears
  test compared interest paid with a pre-computed due amount and flagged fully paid installments as missed (4-decimal
  rounding in `process_debt!`), which is what closed the bakeries and one bank in round 3–4. Test is now
  `shortfall > 0 || rest_interest > 0`.
- Clearing credit bug found and fixed on the way: the protected amount is capped at this round's obligations (the
  savings rule protects existing savings; it does not borrow to fill the buffer).

**Result (6 seeds × 3 variants, `results/probe.csv`):** farms 1–3 and bakeries 1–3 open at the end of every run; runs
last 12–44 rounds (seed 4: 44); credit refusals 38–179 vs 200–400 before; all runs stop on "half of the persons are
dead". Bread output 17–25 per round against 32 needed; money 400–1400, debt 300–1200; person net-wealth Gini 0.24–0.70.
The binding mechanism is now on the household side: persons refused credit at clearing (`unaffordable`), buying one bread
instead of a meal, capacity falling to 2/3, income falling, fees decaying — a distributional spiral, which is the research
object. Enterprises adapt targets to the shrinking demand rather than failing.

**Next steps:** (1) household diagnostics (who dies: landowners never; which workers, at what wage/fee history) — extend
`scripts/diagnose.jl` to persons; (2) decide whether the termination rule "half dead" is the right window or whether a
fixed 50 rounds with survival counts is the paper's metric; (3) sweep `wage_tax_rate`, fee parameters and
`government_employment_share` — the model is now responsive to them; (4) the SuMSy variant: drop the banks, add
`guaranteed_income` (a per-person promise from a money-creating authority each round) and `demurrage` on balances at
clearing; the static check gives the feasible tax/GI region. Gluttony remains inert until households hold surplus.
