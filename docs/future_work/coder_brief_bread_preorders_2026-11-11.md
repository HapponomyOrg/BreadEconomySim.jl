# Coder brief — bread pre-orders, in two modes

*11 November 2026. Design by Claude on Stef's instructions; to be built and tested by the coder on Stef's machine. Model version `2026-11-11.0` on EconoSim 0.3.1; suite at 76,290 tests.*

## 1. Why

A trace of two deaths in the SuMSy cooperative village found that both villagers had a job and more than ten meals of cash. They died because the bread market is a single pass through a randomly shuffled queue each month (`bread_market!`, `src/markets.jl`), earlier buyers took extra loaves before everyone had a meal, and each was drawn near the back three months running. Going a month without bread happens in 0.2–0.4 % of villager-months; three in a row kills.

Stef's decision: **nobody who has the money to buy bread should go hungry by the luck of the draw.** In a real village such a person makes sure of their bread by ordering it. A death in this model should mean that there was not enough bread or that someone could not pay for it.

The remedy is a pre-order, and it comes in two modes because the two will affect the bakeries differently, which is the thing to test:

- **Mode A, `:at_risk`.** Every villager who would otherwise risk going hungry next month orders next month's meal. A design check shows what that means in practice: at the end of a month 485–498 of 512 villagers have no bread at home (step 8, both villages, month 36), so about a thousand of the 1,055 loaves sold a month would be sold on order. The bakeries would know nearly all their demand a month ahead.
- **Mode B, `:after_hunger`.** Only a villager who has just gone hungry orders, and keeps ordering for a set number of months. Orders are then a few loaves a month, and the bakeries plan as they do now.

Both modes should end the queue deaths. Mode A also changes how bakeries plan; mode B barely does. Comparing them separates "the lottery is gone" from "the baker knows the demand".

## 2. Ground rules

- **Everything is behind a switch that is off by default.** With `bread_preorders = :none` every result must be bit-for-bit what it is now: the golden values in `test/runtests.jl` must not move and the suite must pass unchanged.
- **The rule is the same in both villages** and for every villager. Add symmetry tests as for earlier rules.
- **Do not turn it on in the ladder's base** (`scripts/ladder_definition.jl`). Whether and in which mode it goes into the base is Stef's decision, after the tests of §8.
- **Money and bread must balance.** The accounting identity (`identity_gap` in the monthly data) must stay at zero to rounding with the switch on, and no loaf may be created, lost or sold twice.
- Bump `MODEL_VERSION` in `scripts/run_all.jl`; record the change in `HANDOFF_2026-09-18.md`.

## 3. Parameters

Add to `src/parameters.jl`, with comments in the file's style:

| parameter | type, default | meaning |
|---|---|---|
| `bread_preorders` | `Symbol`, `:none` | `:none`, `:at_risk` (mode A) or `:after_hunger` (mode B) |
| `bread_preorder_months` | `Int`, `3` | mode B: how many months a villager keeps ordering after a month in which they went hungry |
| `bread_preorder_growth` | `Float64`, `0.10` | how much more than it baked in the month just ended a bakery will take in orders; `Inf` = no limit (see §5.3) |

Reject any other value of `bread_preorders` with an error at model creation.

## 4. New state

**On a person** (`Person` in `src/agents.jl`):

| field | meaning |
|---|---|
| `bread_order_bakery::Int = 0` | the bakery holding this villager's order for the coming month (0 = none) |
| `bread_order_units::Float64 = 0.0` | the loaves ordered |
| `bread_order_months_left::Int = 0` | mode B: months of ordering still to run |
| `bread_order_failed::Bool = false` | this month's order could not be delivered; the villager goes to the front of the queue (§6.3) |

**On a bakery** (`Enterprise`): `bread_orders::Float64 = 0.0`, the loaves ordered from it for the coming month, and `bread_baked::Float64 = 0.0`, the loaves it baked in its most recent month (set in `bake!`). In its bread market record (`b.market[:bread]`): `sold_on_order::Float64`, reset each month with the other market fields.

**On the model:** monthly counters, reset in `begin_round!` with the others, for the columns of §7.

Clear a villager's order when they die, and a bakery's orders when it is wound up (`close_enterprise!`); a villager whose bakery was wound up is treated as having a failed order (§6.3).

## 5. Placing orders

### 5.1 When

A new step in the month, `place_bread_orders!(model)`, **after `eat!` and `age_stock!` and before `record_and_adapt!`**. That order matters: the villager knows whether they ate and what bread they have left, and the bakery receives its orders before it plans next month's baking. I take the planning (`own_plan!` and the market-share rule) to run from `record_and_adapt!`; **check where they are called**, and if it is elsewhere, place the step so that orders are known before any bakery's `production_target` for the next month is set. Register it in the month's list of steps (`ROUND_BEHAVIORS`, `src/model.jl` and `src/BreadEconomySim.jl`) between `age_stock!` and `record_and_adapt!`. It returns at once when `bread_preorders == :none`.

### 5.2 Who orders, and how much

For every living villager, in an order shuffled with the model's stable shuffle on a **new** random stream `:bread_orders` (`stream(model, :bread_orders)`; a new stream leaves every existing stream untouched):

1. **Mode B only — the clock.** If the villager did not eat a whole meal this month (`ate_this_round != :whole`, which covers no bread and half a meal), set `bread_order_months_left = bread_preorder_months`. Otherwise, if it is above zero, lower it by one. A villager with `bread_order_months_left == 0` places no order in mode B.
2. **The need.** `need = breads_per_meal − bread_units(w)`, the loaves missing for next month's meal from what is at home after eating and ageing. If `need < 1`, no order.
3. **The means.** The villager must be able to pay for `need` loaves at the chosen bakery's current asking price, including any sales tax, from the money they hold now (`cash(w) >= gross_price(model, w, need * ask)`). No credit is used to place an order. A villager who cannot pay places no order and shops in the open market as today.
4. **The order.** `need` loaves, from the bakery chosen in §5.3.

In mode A step 1 is skipped: every villager with a need and the means orders.

### 5.3 From which bakery

The villager asks the bakeries in order of their asking price for this buyer, cheapest first (`member_ask(model, b, buyer, :bread)`, the same ordering `bread_market!` uses). A bakery **accepts** the order if, with it, its orders stay within its limit:

`b.bread_orders + need <= max((1 + bread_preorder_growth) * b.bread_baked, b.production_target * breads_per_grain)`

Orders are placed at the end of a month, so `bread_baked` is what the bakery baked in the month just ended. The limit is on the pace of growth, not on growth: a bakery may take 10 % more than it just baked, the pace the model already gives a firm that sells out (`plan_step`), so a bakery customers prefer doubles in about seven months. The second term lets any bakery take orders up to what it already plans to bake, so that a new or restarted bakery, which has baked little or nothing, is not shut out. With `bread_preorder_growth = Inf` there is no limit. If the cheapest bakery refuses, the villager asks the next. If every bakery refuses, the villager has no order, is counted in `bread_orders_refused`, and shops in the open market. This is the one place where the luck of the draw remains, and it is meant to: it only happens when the village's bakeries cannot bake the meals asked of them.

On acceptance: set the villager's `bread_order_bakery` and `bread_order_units`, add `need` to `b.bread_orders`, log an event `:bread_order` (actor, bakery, units), and count it.

No money changes hands when an order is placed. There is no deposit.

## 6. Baking and delivering

### 6.1 The bakery's plan

A bakery's target for next month is set in `own_plan!` (`src/negotiation.jl`, the function that ends in `e.production_target = clamp(…)`) on the realistic ladder, and by the market-share rule earlier in the same file on the standard ladder. Both plan from last month's sales plus a margin.

With pre-orders on, a bakery plans the two parts of its custom separately:

- **Orders are certain.** They are baked in full and carry no margin.
- **The shelf is planned as now,** but from shelf sales only: wherever the plan reads last month's bread sales (`r.sold`) for a bakery, use `r.sold − r.sold_on_order`. Loaves delivered on order must not be counted again as shelf demand, or the bakery would bake them twice.

So, for a bakery and the good `:bread`: `target (in loaves) = b.bread_orders + shelf plan`, converted to grain as the existing code does (`breads_per_grain`) and clamped as now. Apply the same split to `expected_sales`, which the pricing rule compares with what was sold: `expected_sales = b.bread_orders + shelf expectation`.

This is the heart of the test. In mode A the shelf part is small (extras, and villagers without an order), so the bakery's margin of spare loaves shrinks from about 10 % of everything to about 10 % of very little. Expect less stale bread, fewer donations, and thinner cover when something goes wrong.

Check that the bakery's hiring and its grain purchases follow `production_target` as they do now; they should need no change.

### 6.2 Delivery

A new step, `deliver_bread_orders!(model)`, **after `bake!` and before `donate_bread!`** (and so before `bread_market!`). For each bakery in id order, for its order-holders in the order their orders were placed:

1. **The price** is the bakery's asking price for this buyer at that moment (`member_ask`), for fresh bread: the newest loaves are delivered (`move_stock!(…; newest_first = true)`), at full price, with no discount for age.
2. **Payment** as in `bread_market!`: the villager pays if they hold the money, or may use credit for bread where the model allows it (`credit_for_bread` and `credit_eligible`). Use `pay_consumption!`, record the sale exactly as the market does (`record_transaction!`, `record_patronage!`, the `:bread_sale` event with an added field `on_order = true`), add the loaves to `b.market[:bread].sold` **and** to `sold_on_order`, and set the buyer's `market[:bread].got`.
3. **The buyer's ceiling does not apply.** A villager who ordered a meal takes it at the posted price if they can pay. (In the open market a buyer still refuses a price above their ceiling.)
4. Clear the villager's order and lower `b.bread_orders` by what was delivered.

Loaves delivered on order leave the bakery's stock before `bread_market!` sets `offered`, so the shelf offers only what is left.

### 6.3 When an order fails

An order fails when the bakery has fewer loaves than its orders (it lacked workers or grain), when the bakery was wound up, or when the villager cannot pay at delivery.

- **The bakery is short:** it delivers in the order the orders were placed until its fresh loaves run out. A villager served in part keeps what they got.
- **Every villager whose order was not delivered in full** for one of the first two reasons gets `bread_order_failed = true`, is counted in `bread_orders_failed`, and logged (`:bread_order_failed`, with the reason).
- **A villager who cannot pay** simply loses the order; they are counted in `bread_orders_unpaid` and are not moved to the front.

In `bread_market!`, in the first pass of the month only, put the villagers with `bread_order_failed` at the front of the queue, in their shuffled order, and everyone else behind them in theirs. Do this by a stable partition of the shuffled list, so that with no failed orders the queue is exactly what it is today. Clear the flag after the market.

## 7. What to record

Add to the monthly data (`src/data.jl`), each zero when the switch is off:

| column | meaning |
|---|---|
| `bread_orders_placed` | orders accepted this month for next month (count) |
| `bread_ordered_units` | loaves in those orders |
| `bread_orders_refused` | villagers with a need and the means whom every bakery refused |
| `bread_delivered_on_order` | loaves delivered on order this month |
| `bread_orders_failed` | orders not delivered in full (bakery short or closed) |
| `bread_orders_unpaid` | orders lost because the villager could not pay at delivery |
| `missed_bread_with_cash` | villagers who ate no bread this month while holding at least five meals' worth of money at this month's bread price |
| `deaths_with_cash` | deaths this month of villagers holding at least five meals' worth of money |

The last two are measurements and must be recorded **whatever the switch says**; they are how the problem is counted before the remedy and shown to be gone after it. Adding them must not change any result.

Carry `missed_bread_with_cash` (summed over the run), `deaths_with_cash` (summed), and the share of bread sold on order into the run summaries in `scripts/run_all.jl`, guarded so that older result folders still summarise.

## 8. Tests

### 8.1 Unit tests (in `test/runtests.jl`, hand-built villages)

1. **Off is off.** With `:none`: the suite passes, the golden values are unchanged, no order is ever placed.
2. **Mode A places an order** for a villager with no bread at home and enough money; none for a villager with a meal at home; none for a villager without the money.
3. **Delivery comes before the queue.** A villager with an order receives their meal even when the shelf would have been empty at their place in the queue. Build the case from the trace: bread for all but the last ten in the queue, the villager placed last.
4. **Mode B's clock.** No order before a missed meal; orders for exactly `bread_preorder_months` months after one; a second missed meal restarts the count; with `bread_preorder_months = 1`, one order.
5. **The cheapest bakery first, the next when it is full.** With `bread_preorder_growth = 0` and plans no larger than last month's baking, the cheapest bakery fills and later villagers' orders go to the second; when all are full, the villager is counted as refused and shops in the open market. With `Inf`, every order goes to the cheapest. A bakery that baked nothing accepts orders up to its plan.
6. **A short bakery.** Remove a bakery's workers for a month: orders are delivered in the order placed until the loaves run out; the rest are flagged, go to the front of the queue, and buy from another bakery's shelf.
7. **A bakery wound up** between order and delivery: its order-holders go to the front of the queue.
8. **No money at delivery:** the order lapses, nothing is paid, the loaves stay on the shelf.
9. **No double baking.** In mode A, a bakery whose customers all order bakes its orders plus a shelf plan computed from shelf sales alone; its target does not grow month after month while its sales stay level.
10. **Accounting.** The identity holds every month in ten-year runs of both villages in both modes; bread baked equals bread sold, given, thrown away and left in stock.
11. **Symmetry.** The same rule, the same counters, in the debt village and the SuMSy village.

### 8.2 The two deaths

Rerun the two runs of the trace, cell `B`, SuMSy village, with the fiscal packages: income-tax package seed 8 (person 506 died in month 23) and parking-tax package seed 1 (person 280 died in month 86), in `:none`, `:at_risk` and `:after_hunger`. Expected: both live in both modes; `deaths_with_cash` is 2 across the two runs under `:none` and 0 otherwise. Report what happens to those two villagers month by month around the deaths.

### 8.3 The experiment

Paired runs, ten seeds, 120 months, both villages, on the realistic ladder and then on the standard ladder for the variants that matter. Cells `8`, `B` and `V8`. Variants:

| variant | settings |
|---|---|
| base | `bread_preorders = :none` |
| at risk | `:at_risk` |
| after hunger, 1 month | `:after_hunger`, `bread_preorder_months = 1` |
| after hunger, 3 months | `:after_hunger`, `bread_preorder_months = 3` |
| after hunger, 12 months | `:after_hunger`, `bread_preorder_months = 12` |
| at risk, faster growth | `:at_risk`, `bread_preorder_growth = 0.5` |
| at risk, no limit | `:at_risk`, `bread_preorder_growth = Inf` |

Add them to `ABLATION_VARIANTS` in `scripts/planning_ablation.jl` and run with `ablation(cells = ["8 ", "B ", "V8 "], seeds = 1:10, variants = […], jobs = …)`.

For each cell, village and variant, report:

1. **The purpose:** deaths, `deaths_with_cash`, `missed_bread_with_cash`, hungry months.
2. **The orders:** share of bread sold on order; orders refused, failed and unpaid; **each bakery's share of the orders month by month** (does one bakery take everything, do shares swing from month to month, can a new bakery win custom?).
3. **The bakeries:** bread baked against the 1,024 loaves the village needs; loaves gone stale, given away and thrown away; bakeries wound up; their profit.
4. **Prices and the cycle:** the bread price at year ten and its yearly change; the month-to-month swing in output (run `scripts/stylized_facts.py` on each variant's folder: `sd_gdp`, `ac1_gdp`).
5. **Everyone else:** people without work, work sold a villager, the wealth Gini, the poorest tenth, public debt.

`V8` matters most on the last point. It is the village where bread is already short for the debt village's poor; if mode A thins the bakeries' spare loaves, that is where it will cost lives, and the report must show whether it does.

## 9. What to deliver

A markdown file, `docs/future_work/bread_preorders_results_<date>.md`, with:

1. Whether both modes end the queue deaths (§8.2), in a sentence, with the evidence.
2. The table of §8.3, every variant, both villages, both ladders where run.
3. **The comparison the design exists for:** what mode A changes that mode B does not, and so what the bakeries' knowing their demand does to waste, to firm failures, to prices, to work and to the poorest.
4. Anything that broke, anything surprising, and anything in this design that turned out not to fit the code. If a point of the design cannot be built as written, say so and say what you did instead; do not quietly change it.
5. No recommendation to switch it on in the base is needed. Stef decides that from the table.

## 10. Design choices, and the reasons

So that a choice can be challenged without guessing at it:

- **Orders are placed at the end of the month for the next,** because the bakery must know them before it plans. An order placed and filled within the same month would give the bakery no information and would be the queue under another name.
- **The trigger in mode B is a meal not eaten in full,** half a meal included. A villager who got one loaf has had a warning.
- **The price is the posted price on delivery, paid on delivery.** Fixing the price a month ahead would need a deposit and would put price risk on one side or the other; neither is needed to remove the lottery.
- **The cheapest bakery, not the usual one,** so that an order cannot tie a villager to a bakery whose price has run away (as bakery 10's did in the trace).
- **A limit on how fast a bakery's orders may grow,** and none on how far (Stef, 11 Nov: a bakery must be able to increase its output). Nothing in the model caps a bakery's size; it grows as fast as it can hire workers and buy grain. But in mode A nearly every villager orders and each picks the cheapest bakery, so without a limit one bakery could be handed the whole village's orders in a single month, four times its output, while on the realistic ladder most workers are held by contracts and notice periods. Most of those orders would fail and the other bakeries would have planned for almost nothing. The default lets orders grow by 10 % a month. Whether the swamping happens is an empirical question, which is why §8.3 has variants at 50 % and with no limit: report failed orders, hungry months and the bakeries' shares for all three.
- **Any bakery may take orders up to its own plan.** With nearly all bread on order in mode A, a limit tied only to past output would give a new bakery no orders and leave it a shelf worth 5 % of the market to grow through. That would lock in the incumbents, which is not intended.
- **The ceiling is waived on delivery** because the villager chose to order. The separate question of what a starving villager will pay in the open market (person 506 refused loaves at 21 with over a hundred in cash) is not part of this design.
- **Failed orders go to the front of the queue,** so that a villager who did the right thing and was let down by the bakery is not then exposed to the lottery in the same month.
- **A villager who cannot pay places no order and gets no priority.** Pre-orders protect people with money from bad luck; they are not a food programme. What happens to those without money is the business of the benefit, the guaranteed income and the bread that is given away.

## 11. Not in this design

- Putting hungry villagers first in the open queue as a rule of its own. (It appears here only for failed orders.)
- Letting everyone buy a meal before anyone buys extras.
- What a starving villager is willing to pay.
- Why bakery 10 held a price four times its competitors' for months.

Each is a separate question; none should be folded into this work.
