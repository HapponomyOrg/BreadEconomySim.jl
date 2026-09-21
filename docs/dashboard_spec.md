# BreadEconomySim — dashboard design document

*Kept in step with `src/parameters.jl`; last updated 18 September 2026 (cooperative forms, membership contribution, random streams). The parameter tables below are generated from the source, so every field of `SimulationParameters` appears exactly once.*

## 1. Purpose

A web dashboard from which a non-programmer can configure a village, run it under one or both kinds of money, and read the results. Every parameter and switch of the simulation is exposed; nothing is hidden in code. The dashboard drives the Julia package through a thin service layer and never re-implements any rule.

## 2. Architecture

- **Backend**: a Julia HTTP service (HTTP.jl + JSON3) wrapping `run_simulation(SimulationParameters(; kwargs...))`. One endpoint validates and runs a job; results stream as the run progresses (one JSON row per round from `round_data`), so charts fill in live. Batch jobs run several seeds and both systems in parallel processes.
- **Frontend**: a single-page app. State = one `SimulationParameters` object per side (debt / SuMSy) plus run controls. All widgets bind to parameter names 1:1; the JSON sent to the backend is the keyword list of `SimulationParameters`, nothing else.
- **Validation** happens in the frontend from the rules in Section 5 (ranges, gating, consistency) and again in the backend (the same rules, plus Julia's own type checks).
- **Persistence**: every run is saved with its full parameter set, seed list, git commit of the package, and the per-round CSV; presets are parameter sets with a name.

## 3. Layout

Three columns on a wide screen, stacked on a narrow one.

1. **Configure** (left): the parameter panels of Section 4, one collapsible card per panel, in the order given. A search box filters parameters by name or description. Each parameter shows its name, a plain-language description, its widget, its default, and a reset button. A gated parameter is greyed out with a note naming the switch that enables it.
2. **Run** (middle): the run controls (Section 6), the preset picker (Section 7), the *compare* toggle that runs the same village under both kinds of money, progress bars per seed, and the log of warnings from validation.
3. **Results** (right): the charts and tables of Section 8, in two columns when comparing (debt left, SuMSy right, colour-coded as in the report), with the metric cards first and the per-round charts beneath.

## 4. Parameter panels

Column meanings: *widget* is the control; *range* the dashboard's allowed span (the code accepts more; the range is what makes sense to expose); *enabled by* the switch or value that must be on for the parameter to matter (blank = always). Defaults are the code's defaults, which reproduce the original specification; the presets of Section 7 set the behaviour rules.

### Agents

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `number_of_banks` | Int | `2` | integer field |  |  |  |
| `number_of_farms` | Int | `3` | integer field |  |  |  |
| `number_of_bakeries` | Int | `3` | integer field |  |  |  |
| `number_of_persons` | Int | `16` | integer field | 4–5000 |  |  |
| `number_of_landowners` | Int | `2` | integer field | 1–500 |  |  |

### Capacity, food and death

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `maximum_capacity` | Float64 | `3.0` | slider / number | 1–6 |  |  |
| `capacity_recovery_per_round` | Float64 | `2.0` | slider / number |  |  |  |
| `half_meal_capacity_fraction` | Float64 | `2 / 3` | slider / number |  |  |  |
| `rounds_without_food_until_death` | Int | `3` | integer field |  |  |  |
| `breads_per_grain` | Int | `2` | integer field |  |  |  |
| `breads_per_meal` | Int | `2` | integer field |  |  |  |
| `initial_breads_per_person` | Float64 | `2.0` | slider / number |  |  | bootstrap: everyone starts with one meal in stock |
| `maximum_breads_per_round` | Int | `3` | integer field |  |  | gluttony: up to this many breads eaten in a round |
| `gluttony_probability` | Float64 | `0.10` | slider / number | 0–1 |  | chance a person who can pay cash eats a third bread |
| `stocking_marginality` | Vector{Tuple{Int, Float64}} | `[(3, 1.0), (4, 0.5), (5, 0.3), (7, 0.15)]` | table editor |  |  | after gluttony: chance of one more bread while stock < units |

### Goods

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `spoilage_age_in_rounds` | Int | `3` | integer field |  |  |  |

### Prices and negotiation

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `initial_prices` | Dict{Symbol, Float64} | `Dict(:bread => 5.0, :grain => 5.2, :rent => 0.75, :wage => 3.92, :ticket => 2.0)` | table editor |  |  | static-consistent vector, see HANDOFF |
| `land_price_rent_multiple` | Float64 | `15.0` | slider / number | 5–400 |  |  |
| `negotiation_steps` | Int | `6` | integer field |  |  |  |
| `minimum_concession_fraction` | Float64 | `0.25` | slider / number |  |  |  |
| `maximum_concession_fraction` | Float64 | `0.40` | slider / number |  |  |  |
| `ask_increase_after_sellout` | Float64 | `0.06` | slider / number |  |  |  |
| `ask_decrease_after_partial_sale` | Float64 | `0.06` | slider / number |  |  |  |
| `unsold_tolerance_units` | Float64 | `2.0` | slider / number |  |  | unsold ≤ this (one grain-unit of bread) is not 'partly unsold' |
| `ask_decrease_when_idle` | Vector{Float64} | `[0.15, 0.30, 0.45]` | table editor |  |  | desperation: consecutive idle rounds |
| `bid_decrease_after_success` | Float64 | `0.03` | slider / number |  |  |  |
| `bid_increase_when_starved` | Vector{Float64} | `[0.06, 0.12, 0.25]` | table editor |  |  | consecutive rounds of missing out |
| `bread_price_ageing_discount` | Float64 | `0.40` | slider / number |  |  |  |
| `hunger_wage_discount` | Float64 | `0.25` | slider / number |  |  |  |
| `farm_maximum_rent_fraction_of_grain_price` | Float64 | `0.6` | slider / number |  |  |  |
| `bakery_grain_wage_fraction` | Float64 | `0.5` | slider / number |  |  |  |
| `bread_bid_base_multiplier` | Float64 | `1.3` | slider / number |  |  |  |
| `bread_bid_hunger_multiplier` | Float64 | `0.4` | slider / number |  |  |  |
| `initial_production_target` | Int | `6` | integer field |  |  |  |

### Enterprises

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `reserve_target_in_rounds` | Float64 | `3.0` | slider / number |  |  | standard reserve = rounds × expected input cost |
| `surplus_reserve_multiple` | Float64 | `2.0` | slider / number |  |  |  |
| `reserve_protection_probability` | Float64 | `0.5` | slider / number |  |  | enterprises: borrow first (v1 savings rule) vs use own cash first            # wages absorb surplus once reserves reach this multiple |

### Credit

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `loan_term_in_rounds` | Int | `20` | integer field | 5–100 |  |  |
| `affordability_ratio` | Float64 | `0.8` | slider / number |  |  |  |
| `initial_interest_rate` | Float64 | `0.05` | slider / number |  |  |  |
| `interbank_rate_discount` | Float64 | `0.5` | slider / number |  |  | bank-to-bank loans at discount × lender's rate |
| `government_rate_discount` | Float64 | `0.5` | slider / number |  |  |  |
| `arrears_rounds_until_seizure` | Int | `2` | integer field |  |  |  |
| `garnishment_rate` | Float64 | `0.25` | slider / number |  |  |  |

### Savings (persons)

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `savings_target_in_meals` | Float64 | `3.0` | slider / number |  |  |  |
| `savings_protection_probability` | Float64 | `0.5` | slider / number |  |  |  |

### Government

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `wage_tax_rate` | Float64 | `0.15` | slider / number | 0–0.6 | income_tax_schedule = :flat |  |
| `capital_tax_rate` | Float64 | `0.15` | slider / number | 0–0.6 |  |  |
| `government_employment_share` | Float64 | `0.10` | slider / number |  |  | of total person capacity |
| `government_wage_in_breads` | Float64 | `2.0` | slider / number |  |  |  |
| `government_wage_premium` | Float64 | `0.10` | slider / number |  |  | net wage for full-time = breads × (1 + premium) |
| `unemployment_fee_in_breads` | Float64 | `2.0` | slider / number |  |  |  |
| `minimum_fee_in_breads` | Float64 | `1.0` | slider / number |  |  |  |
| `fee_reduction_interval` | Int | `3` | integer field |  |  |  |
| `fee_reduction_rate` | Float64 | `0.10` | slider / number |  |  |  |
| `employment_rounds_to_reset_fee` | Int | `3` | integer field |  |  |  |

### Variants

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `debt_dies_with_bank` | Bool | `false` | toggle |  |  |  |

### Behavioural rules (viability study, 12 September 2026) — all off reproduces spec v2

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `demand_based_targets` | Bool | `false` | toggle |  |  | producers plan output for the living population instead of the ±1 ratchet |
| `planning_margin` | Float64 | `0.0` | slider / number | 0–0.5 | demand_based_targets | extra share of demand planned for (0.0 = plan exactly the population's meals) |
| `plan_for_gluttony` | Bool | `false` | toggle |  | demand_based_targets | plan for the expected third loaves too (otherwise gluttony is a pure demand shock) |
| `wage_ceiling_from_own_ask` | Bool | `false` | toggle |  |  | employer's maximum wage from the price it will ask for its output, not the market average |
| `expected_price_from_asks` | Bool | `false` | toggle |  |  | when a good was not traded, expected price = mean posted ask (no frozen prices) |
| `ask_increase_only_on_unmet_demand` | Bool | `false` | toggle |  |  | sellers raise the ask only when customers were turned away, not on a mere sell-out |
| `offer_full_capacity` | Bool | `false` | toggle |  |  | persons offer all their capacity instead of the minimum that covers their needs |
| `wage_reservation_net_of_tax` | Bool | `false` | toggle |  |  | worker's floor nets a meal after wage tax (the price vector was derived this way) |
| `random_hiring_ties` | Bool | `false` | toggle |  |  | equal asks: random order (default: stable sort ⇒ agent-id order) |
| `no_labour_tolerance` | Bool | `false` | toggle |  |  | unsold labour units always count as 'partly unsold' (tolerance is for goods) |
| `partial_unemployment_fee` | Bool | `false` | toggle |  |  | fee pro rata to the unsold share of offered labour |
| `credit_for_bread` | Bool | `false` | toggle |  |  | a person may promise a meal on credit when eligible for the loan (spec v1 §4.9 'borrowed if needed') |
| `spoilage_aware_stocking` | Bool | `false` | toggle |  |  | stockers hold at most breads_per_meal × spoilage_age (nothing they buy will spoil) |
| `distress_land_sales` | Bool | `false` | toggle |  |  | a hungry or indebted-in-arrears landholder sells one unit per round at a discount |
| `distress_land_discount` | Float64 | `0.8` | slider / number |  | distress_land_sales |  |
| `land_units_per_landowner_override` | Int | `0` | integer field |  | 0 = spec formula | 0 = spec formula floor((n − p)/(p − 1)) |
| `land_per_person` | Float64 | `0.0` | slider / number | 0–4 | > 0 overrides both | total land = land_per_person × persons, shared equally by the landowners; 2 makes four loaves a head feasible on the land side |

### Enterprise taxation (12 September 2026)

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `enterprise_tax` | Symbol | `:none` | select | :none, :income, :reserves |  | :none | :income (on net operating cash flow minus interest; banks on interest received) | :reserves (on cash held at end of round) |
| `enterprise_income_tax_rate` | Float64 | `0.10` | slider / number | 0–0.5 | enterprise_tax = :income |  |
| `enterprise_reserve_tax_rate` | Float64 | `0.10` | slider / number | 0–0.2 | enterprise_tax = :reserves |  |
| `reserve_tax_exempts_standard_reserve` | Bool | `false` | toggle |  | enterprise_tax = :reserves | :reserves — tax only cash above the standard working reserve |

### Monetary system (SuMSy variant, 12 September 2026)

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `monetary_system` | Symbol | `:debt` | select | :debt, :sumsy |  | :debt (bank credit creates money) | :sumsy (GI created, demurrage destroys, peer lending only) |
| `guaranteed_income` | Float64 | `5.0` | slider / number | 0–15 | monetary_system = :sumsy | per person per round, fixed nominal (one bread at the initial price) |
| `demurrage_rate` | Float64 | `0.02` | slider / number | 0–0.10 | monetary_system = :sumsy | per round, on balances above the buffer; destroys money |
| `demurrage_tax_rate` | Float64 | `0.0` | slider / number |  | monetary_system = :sumsy | surcharge on the same base, transferred to the government |
| `demurrage_free_buffer` | Float64 | `30.0` | slider / number | 0–60 | monetary_system = :sumsy | persons only (3 meals at initial prices); everyone else: 0 |
| `initial_money_per_person` | Float64 | `30.0` | slider / number |  | monetary_system = :sumsy and initial_endowment = :none | debt-free initial money, created by the authority |
| `start_at_saturation` | Symbol | `:none` | select | :none, :upper, :lower | monetary_system = :sumsy | :upper — every person starts at buffer + GI/d (stock N·b + N·GI/d); :lower — one person holds b + N·GI/d, the rest nothing |
| `initial_price_multiplier` | Float64 | `1.0` | slider / number | 0.3–3 |  | scales the initial price vector (a saturated village runs at about 0.63 of the starting level) |
| `account_fee_person` | Float64 | `0.5` | slider / number |  |  | per round, promised to the person's bank at clearing |
| `account_fee_enterprise` | Float64 | `1.5` | slider / number |  |  |  |
| `peer_lending` | Bool | `true` | toggle |  | monetary_system = :sumsy |  |
| `peer_loan_rate` | Float64 | `-0.01` | slider / number | −0.05–0.05 | monetary_system = :sumsy | borrower's rate per round (negative: lending beats demurrage) |
| `bank_spread` | Float64 | `0.005` | slider / number | 0–0.02 | monetary_system = :sumsy | lender receives peer_loan_rate − bank_spread |
| `affordability_pricing` | Bool | `false` | toggle |  |  | a seller who turned buyers away for lack of cash cuts its ask towards their cash, above its cost floor |
| `indexed_pricing` | Bool | `false` | toggle |  |  | wage, grain and rent asks/bids are re-expressed in bread units every round |
| `wage_reservation_net_of_gi` | Bool | `false` | toggle |  | monetary_system = :sumsy | SuMSy: the worker's floor covers only the part of the meal the GI does not |
| `reserve_pricing` | Bool | `false` | toggle |  |  | producers cut their ask (to the cost floor) while cash exceeds the working reserve, raise it when below half of it |
| `reserve_pricing_step` | Float64 | `0.05` | slider / number |  | reserve_pricing |  |
| `wage_reservation_includes_savings` | Bool | `false` | toggle |  |  | the worker's floor also covers building the savings buffer (3 meals) over savings_build_rounds |
| `savings_build_rounds` | Int | `10` | integer field | 1–50 | wage_reservation_includes_savings |  |

### Initial endowment (12 September 2026): every actor starts at its stock-flow norm

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `initial_endowment` | Symbol | `:none` | select | :none, :norm |  | :none | :norm — persons: savings target (3 meals); farms/bakeries: standard working reserve |
| `startup_loan_term` | Int | `50` | integer field | 10–200 | initial_endowment = :norm and monetary_system = :debt | :debt — enterprises borrow the endowment (own reserve + the persons' share) and pay it out |
| `inherited_money` | Bool | `false` | toggle |  | monetary_system = :debt and initial_endowment = :norm | villagers start with the SuMSy starting cash debt-free — residual money of deceased villagers whose loans were written off (booked against the banks' net worth, not their operating funds) |
| `startup_loan_rate` | Float64 | `0.005` | slider / number |  | initial_endowment = :norm and monetary_system = :debt |  |
| `land_loans` | Bool | `false` | toggle |  |  | land may be bought on credit (collateral: the land itself, seized after 2 rounds of arrears) |
| `bread_loan_term` | Int | `0` | integer field |  | credit_for_bread | persons' clearing credit (meals) at this term; 0 = loan_term_in_rounds |
| `land_sales` | Symbol | `:forced` | select | :forced, :distress_only, :reservation |  | :forced (spec: any buyer with surplus takes a unit) | :distress_only | :reservation (seller sells only above the value of the rent stream) |
| `land_reservation_multiple` | Float64 | `100.0` | slider / number | 10–400 | land_sales = :reservation and monetary_system = :debt | :reservation, debt money: rounds of rent a landowner wants for a unit; SuMSy uses rent / demurrage_rate |

### Deposit interest (debt system): paid by the account holder's bank from retained interest

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `deposit_interest_rate` | Float64 | `0.0` | slider / number | 0–0.05 | monetary_system = :debt | per payout period, on the average end-of-round balance over the period |
| `deposit_interest_period` | Int | `1` | integer field |  | deposit_interest_rate > 0 | rounds between payouts (1 = every round; 12 = yearly) |
| `loyalty_bonus_rate` | Float64 | `0.0` | slider / number | 0–0.1 | monetary_system = :debt | per period, on the lowest end-of-round balance over the period |
| `deposit_interest_to_enterprises` | Bool | `false` | toggle |  | deposit_interest_rate > 0 | business accounts earn nothing unless switched on |

### Instalment purchases (SuMSy): seller-financed land sales, paid in equal instalments, land as collateral

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `instalment_purchases` | Bool | `false` | toggle |  | monetary_system = :sumsy |  |
| `instalment_rounds` | Int | `20` | integer field | 5–60 | instalment_purchases |  |
| `deferred_payment` | Bool | `false` | toggle |  | share_market | a share buyer short of cash may pay in instalments; the seller finances it (bank keeps its spread), shares as collateral |
| `deferred_payment_rounds` | Int | `20` | integer field | 5–60 | deferred_payment |  |
| `deferred_payment_rate` | Float64 | `NaN` | slider / number | −0.02–0.02 | deferred_payment | NaN = peer_loan_rate under SuMSy (−1 %), 0.5 % a round under debt money |

### Buffer pool and default insurance (SuMSy, 12 September 2026)

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `buffer_lending` | Bool | `false` | toggle |  | monetary_system = :sumsy | persons may lend part of their demurrage-free buffer to their bank (exemption moves with the money) |
| `buffer_lending_participation` | Float64 | `0.5` | slider / number | 0–1 | buffer_lending | share of persons who opt in |
| `buffer_lend_fraction` | Float64 | `0.5` | slider / number | 0–1 | buffer_lending | share of the buffer a participant lends |
| `buffer_lender_spread_discount` | Float64 | `0.5` | slider / number |  | buffer_lending | participants pay this fraction less of the bank spread when they borrow |
| `default_insurance` | Bool | `false` | toggle |  | monetary_system = :sumsy and instalment_purchases | instalment sellers pay a premium; the bank covers missed instalments from its reserves and takes over the claim |
| `insurance_premium_rate` | Float64 | `0.02` | slider / number |  | default_insurance | share of each instalment paid by the insured seller to the bank |

### Harvest shock

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `harvest_shock_start` | Int | `0` | integer field |  |  | 0 = no shock |
| `harvest_shock_length` | Int | `3` | integer field |  | harvest_shock_start > 0 |  |
| `harvest_shock_factor` | Float64 | `0.5` | slider / number | 0–1 | harvest_shock_start > 0 |  |

### Government bonds (13 September 2026): sold to surplus holders through the bank before any bank credit

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `government_bonds` | Bool | `false` | toggle |  | monetary_system = :debt |  |
| `bond_term_long` | Int | `60` | integer field |  | government_bonds |  |
| `bond_term_short` | Int | `12` | integer field |  | government_bonds |  |

### Income tax schedule (13 September 2026). :belgian — brackets as shares of the full-time gross wage (median gross ≈ €45k):

*social contributions 13.07 % first, then 25/40/45/50 % on taxable income above 0.363/0.64/1.108 × reference, a 25 % credit on an allowance of 0.242 × reference, and a 7 % municipal surcharge. Wage tax only; rent keeps capital_tax_rate.*

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `income_tax_schedule` | Symbol | `:flat` | select | :flat, :belgian |  |  |
| `social_contribution_rate` | Float64 | `0.1307` | slider / number |  | income_tax_schedule = :belgian |  |
| `tax_free_share` | Float64 | `0.242` | slider / number |  | income_tax_schedule = :belgian |  |
| `tax_bracket_edges` | Vector{Float64} | `[0.363, 0.640, 1.108]` | table editor |  | income_tax_schedule = :belgian |  |
| `tax_bracket_rates` | Vector{Float64} | `[0.25, 0.40, 0.45, 0.50]` | table editor |  | income_tax_schedule = :belgian |  |
| `municipal_surcharge` | Float64 | `0.07` | slider / number |  | income_tax_schedule = :belgian |  |

### Entertainment (13 September 2026): a pure service, labour only

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `entertainment` | Bool | `false` | toggle |  |  |  |
| `number_of_theatres` | Int | `1` | integer field |  | entertainment |  |
| `customers_per_labour_unit` | Float64 | `2.5` | slider / number | 1–20 | entertainment | 10 customers per full-time job at capacity 4 |
| `max_tickets_per_person` | Int | `3` | integer field |  | entertainment | 1–3 tickets a round, at random within what cash above the buffer allows |
| `entertainment_propensity` | Float64 | `1.0` | slider / number | 0–1 | entertainment | probability a person who can afford a ticket wants one |
| `plan_for_tickets` | Bool | `true` | toggle |  | entertainment | theatres plan hiring on expected ticket demand (like bakeries on gluttony) |

### Clearing switch (13 September 2026): true = all intra-round payments are promises netted at clearing (spec v2 addendum);

*false = every payment is settled immediately (cash, then credit, the unpaid tail becomes a trade arrear)*

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `clearing` | Bool | `true` | toggle |  |  |  |

### Ownership (13 September 2026)

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `ownership` | Symbol | `:none` | select | :none, :cooperative, :shareholders, :mixed |  | :none | :cooperative (every person holds an equal share of every producer) | :shareholders (a few persons hold all shares) | :mixed (cooperative_* producers are co-ops, the rest shareholder-owned) |
| `shareholder_count` | Int | `2` | integer field |  | ownership ≠ :none | :shareholders / :mixed — persons (lowest ids) who hold the shares |
| `cooperative_farms` | Int | `2` | integer field |  | ownership = :mixed | :mixed |
| `cooperative_bakeries` | Int | `2` | integer field |  | ownership = :mixed |  |
| `cooperative_theatres` | Int | `0` | integer field | 0–number_of_theatres | ownership = :mixed and entertainment | theatres were for-profit only before 14 September 2026 |
| `cooperative_form_farms` | Symbol | `:member` | select | :member, :worker | ownership ∈ (:cooperative, :mixed) | :member (the 13 September rule: open membership at par, one equal dividend per member) | :worker (membership follows employment, surplus by hours worked, taxed as wages). Farms cannot be consumer co-ops: they sell to bakeries, not persons |
| `cooperative_form_bakeries` | Symbol | `:member` | select | :member, :worker, :consumer | ownership ∈ (:cooperative, :mixed) | as above; :consumer = membership follows purchases, surplus as an untaxed patronage rebate by units bought |
| `cooperative_form_theatres` | Symbol | `:member` | select | :member, :worker, :consumer | cooperative_theatres > 0 | as above |
| `patronage_window` | Int | `12` | integer field | 1–50 | any :worker / :consumer form | rounds of hours or purchases a distribution and the lapse rule are measured over |
| `retained_surplus_share` | Float64 | `0.25` | slider / number | 0–0.9 | any :worker / :consumer form | share of every distribution locked in the indivisible reserve (never distributed; to the government on dissolution). Under SuMSy it pays demurrage like any balance |
| `capital_deduction_share` | Float64 | `0.10` | slider / number | 0–1 | :worker form | share of each net wage withheld until the membership share is paid |
| `membership_lapse_rounds_worker` | Int | `6` | integer field | 1–50 | :worker form | grace period before a member without hours is redeemed |
| `membership_lapse_rounds_consumer` | Int | `12` | integer field | 1–50 | :consumer form | grace period before a member without purchases is redeemed |
| `minimum_member_hours` | Float64 | `0.5` | slider / number | 0–4 | :worker form | average units a round below which worker membership lapses |
| `members_first_hiring` | Bool | `true` | toggle |  | :worker form | members' capacity is allocated before the open market and the work spread over them in proportion to capacity; bakery members reserve capacity at the start of the round |
| `member_price_awareness` | Bool | `true` | toggle |  | :consumer form | members rank sellers by ask net of the expected rebate |
| `cooperative_founding` | Symbol | `:par_only` | select | :par_only, :symmetric | ownership ∈ (:cooperative, :mixed) | :symmetric — a cooperative short of capital calls on its members (spare cash first, then a personal loan), as a shareholder firm's founders are; :par_only — the cooperative borrows itself |
| `membership_contribution` | Symbol | `:money` | select | :money, :buffer, :mixed_fixed, :mixed_flexible | ownership ∈ (:cooperative, :mixed) | what a member brings in: money at par; a pledge of demurrage-free buffer (no money moves, the exemption does); both; or one total split as the member chooses (idle buffer first, then money). A pledge is worth nothing under debt money: :buffer is then free and :mixed_flexible costs its money half |
| `membership_buffer_pledge` | Float64 | `10.0` | slider / number | 0–demurrage_free_buffer | membership_contribution ≠ :money | buffer requirement, in currency units of exemption |
| `buffer_contribution_value` | Float64 | `1.0` | slider / number | 0–5 | membership_contribution = :mixed_flexible | money a unit of pledged buffer counts for (0 under debt money) |
| `dividend_build_rounds` | Int | `10` | integer field | 1–50 | ownership ≠ :none | cash above the reserve target is paid out over this many rounds |
| `dividend_tax_rate` | Float64 | `0.30` | slider / number | 0–0.5 | ownership ≠ :none | Belgian withholding tax on dividends |
| `share_market` | Bool | `false` | toggle |  | ownership ∈ (:shareholders, :mixed) | shareholder enterprises' shares trade once a round |
| `shares_per_person` | Int | `0` | integer field | 0–100 | share_market | share units per firm = this × number of persons (0 = 100 units per firm), so every villager could hold shares |
| `startup_financing` | Symbol | `:enterprise_loans` | select | :enterprise_loans, :paid_in_capital | ownership ≠ :none | :enterprise_loans (businesses borrow their own start) | :paid_in_capital (owned businesses start empty; founders borrow personally and pay capital in; co-ops raise membership capital) |
| `membership_share_price` | Float64 | `10.0` | slider / number |  | ownership ∈ (:cooperative, :mixed) and startup_financing = :paid_in_capital | a cooperative share, at par (one meal at initial prices) |
| `cooperative_join_probability` | Float64 | `0.5` | slider / number | 0–1 | same as membership_share_price | a person with surplus who is not yet a member joins one cooperative a round with this probability |
| `required_yield` | Float64 | `0.01` | slider / number | 0.001–0.05 | share_market | base required dividend yield per round; a person's own yield is drawn once around it |
| `required_yield_dispersion` | Float64 | `0.0` | slider / number | 0–0.01 | share_market | half-width of the per-person spread (0 = everyone values a firm alike → no voluntary trades) |
| `forward_valuation` | Bool | `false` | toggle |  | share_market | value a firm by its expected dividends after its loans are repaid, not by trailing dividends and book |
| `founder_minimum_stake` | Float64 | `0.51` | slider / number | 0–1 | share_market | founders together keep at least this fraction of each firm |
| `expected_price_growth` | Float64 | `0.0` | slider / number | 0–0.01 | share_market | per round; buyers' valuation = dividend / (own yield − this) — the resale-expectation term, off by default |
| `share_step` | Float64 | `0.05` | slider / number |  | share_market | ask/bid adaptation per round |
| `arrears_de_minimis_in_meals` | Float64 | `0.01` | slider / number |  |  | a shortfall smaller than this share of a meal is not a missed payment |
| `closure_debt_threshold_in_breads` | Float64 | `1.0` | slider / number |  |  | an enterprise with nothing left to seize is closed only if the uncovered debt exceeds this |

### Greed (13 September 2026): a property of persons, above their own reserve

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `greed` | Bool | `false` | toggle |  |  |  |
| `greed_share` | Float64 | `0.25` | slider / number | 0–1 | greed | share of persons who are greedy |
| `greed_hoarding` | Float64 | `0.5` | slider / number | 0–1 | greed | every greedy person is both: each act of greed goes to capital with this probability (most profitable of land, shares, cash first), to consumption (a loaf or a ticket, coin flip) otherwise |
| `greed_selection` | Symbol | `:rich` | select | :rich, :random | greed | :rich (the wealthiest at the founding) | :random |
| `greedy_max_breads_per_round` | Int | `10` | integer field | 3–20 | greed | replaces the 3-loaf ceiling for greedy consumers (eaten, not stocked) |
| `greedy_max_tickets_per_round` | Int | `10` | integer field | 3–20 | greed | replaces the 3-ticket ceiling |

### Bread rationing (13 September 2026): stage one, everyone up to the ration; stage two, leftovers to the greedy

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `bread_rationing` | Bool | `false` | toggle |  |  |  |
| `ration_breads_per_person` | Int | `4` | integer field | 2–10 | bread_rationing | lowered to what the shelves can give everyone, never below a meal |
| `tiered_bread_price` | Bool | `false` | toggle |  |  | loaves beyond the ration sell at a second posted price that rises on unmet greed and falls on unsold leftovers (never below the ordinary price) |
| `tier_step` | Float64 | `0.06` | slider / number |  | tiered_bread_price |  |
| `no_self_service` | Bool | `false` | toggle |  | entertainment | a theatre's workers are not served at their own theatre that round |
| `stop_when_half_dead` | Bool | `true` | toggle |  |  |  |
| `stop_when_stationary` | Bool | `true` | toggle |  |  |  |

### Run control

| parameter | type | default | widget | range / options | enabled by | meaning |
|---|---|---|---|---|---|---|
| `random_streams` | Bool | `true` | toggle |  |  | one random stream per subsystem (negotiation, land, labour, grain, bread, tickets, greed, credit, estates, shares, cooperatives), each seeded from `seed` and its name; false = the single shared stream of runs before 18 September 2026 |
| `maximum_rounds` | Int | `50` | integer field | 10–500 |  |  |
| `government_reserve_in_rounds` | Int | `0` | integer field | 0–24 |  | 0 = the government keeps whatever tax exceeds spending (under SuMSy it pays demurrage on it; reached a fifth of the stock). n = a reserve of n rounds of expected spending (trailing mean of outlays over `government_expense_window`) |
| `government_expense_window` | Int | `12` | integer field | 1–50 | reserve > 0 | rounds over which expected spending and revenue are averaged |
| `surplus_redistribution_share` | Float64 | `0.0` | slider | 0–1 | reserve > 0 | share of the surplus above target paid out equally to every living person each round |
| `surplus_tax_reduction_share` | Float64 | `0.0` | slider | 0–1 | reserve > 0 | share of the surplus returned by lowering taxes (through `tax_policy` when set, else in full) |
| `tax_policy` | Symbol | `:none` | select | :none, :scale, :brackets | reserve > 0 | raises on a shortfall (spending above revenue plus the reserve gap), cuts on a surplus; :scale = one multiplier on all taxes; :brackets = each progressive bracket in proportion to its rate (needs `income_tax_schedule = :progressive`) |
| `tax_response_coverage` | Float64 | `0.5` | slider | 0–1 | tax_policy ≠ :none | share of the shortfall a raise is sized to cover |
| `tax_response_step` | Float64 | `0.02` | slider | 0.005–0.2 | tax_policy ≠ :none | largest relative change in revenue per round, both directions — the "no shocks" limit |
| `bracket_fixed_rise` | Float64 | `0.0` | number | 0–0.05 | tax_policy = :brackets | points added to every bracket per step on top of the proportional rise |
| `tax_scale_maximum` | Float64 | `3.0` | number | 1–10 | tax_policy ≠ :none | ceiling on the multiplier |
| `bracket_rate_maximum` | Float64 | `0.9` | number | 0.5–1 | tax_policy = :brackets | ceiling on any bracket rate |
| `consumption_tax_rate` | Float64 | `0.0` | slider | 0–0.3 |  | VAT on bread and tickets, paid by the buyer on top of the price and booked as government revenue; buyers' willingness to pay is gross. Belgium ≈ 6 % |
| `tax_levers` | NamedTuple | `(income = 0, consumption = 0, wealth = 0)` | three numbers | any finite | tax_policy ≠ :none | shift then move: each family first goes by r × its lever (positive = with the policy, negative = against, 0 = none), then by r with the others. (0, 0, 0) = one scale; −1 holds a family flat; (−2, +1, 0) shifts the burden from income to consumption while the total follows the budget |
| `wealth_tax_rate` | Float64 | `0.0` | slider | 0–0.3 |  | yearly rate on persons' land (at the land price) and shares (at book value per unit; co-op membership at capital paid), charged every round at rate ÷ `wealth_tax_rounds_per_year`, scaled by the fiscal policy; unpaid amounts carried as arrears |
| `wealth_tax_rounds_per_year` | Int | `12` | integer field | 1–52 | wealth_tax_rate > 0 | rounds a year for the wealth tax. Its own scale: moved with the policy's r and by the shift |
| `shows_per_round` | Int | `0` | integer field | 0–10 | entertainment | 0 = unlimited; a theatre sells at most shows × seats tickets a round and hires no more labour than that takes |
| `seats_per_show` | Int | `0` | integer field | 0–N | shows > 0 | 0 = one seat per person at founding |
| `unmet_demand_share` | Float64 | `0.0` | slider | 0–0.5 |  | 0 = one missed buyer raises the ask; s = the unserved units must be ≥ s of sold + unserved. Wages keep the one-miss rule |
| `unsold_share` | Float64 | `0.0` | slider | 0–0.5 |  | 0 = more than `unsold_tolerance_units` left cuts the ask; s = the unsold units must be ≥ s of what was offered |
| `ask_floor` | Symbol | `:none` | select | :none, :cost | | :cost = the posted ask never below unit cost (`seller_reservation` at age 0), plus `ask_floor_markup_when_short` while the reserve or buffer is not full |
| `ask_floor_markup_when_short` | Float64 | `0.05` | slider | 0–0.5 | ask_floor = :cost | markup above cost while cash is below the reserve (producer) or buffer (person) |
| `stationary_rounds` | Int | `5` | integer field |  | stop_when_stationary |  |
| `stationary_tolerance` | Float64 | `0.01` | slider / number |  | stop_when_stationary |  |
| `seed` | Int | `1` | integer field | 1–10⁶ |  |  |

## 5. Validation and consistency rules

- `number_of_landowners` ≥ 1 and ≤ `number_of_persons`; with `land_units_per_landowner_override = 0` the spec formula floor((n − p)/(p − 1)) must give at least one unit and total land must cover `number_of_persons` grain — the dashboard shows the resulting land total and warns when it is below the population's meals.
- `breads_per_meal` ≤ `maximum_breads_per_round` ≤ `greedy_max_breads_per_round`; `ration_breads_per_person` ≥ `breads_per_meal`.
- Under `monetary_system = :sumsy` the dashboard forces `wage_tax_rate = 0`, `capital_tax_rate = 0`, the unemployment fee to 0 and `partial_unemployment_fee = false` unless the user unlocks them (a SuMSy village with wage taxes is allowed but flagged as unusual); `demurrage_tax_rate` is the SuMSy tax.
- `initial_endowment = :norm` with `startup_financing = :paid_in_capital` requires `ownership ≠ :none` (otherwise there are no founders to borrow the villagers' starting cash).
- `share_market = true` requires `ownership ∈ (:shareholders, :mixed)`; `cooperative_farms ≤ number_of_farms`, `cooperative_bakeries ≤ number_of_bakeries`, `cooperative_theatres ≤ number_of_theatres`; `cooperative_form_farms ≠ :consumer`; `membership_contribution = :buffer` needs `membership_buffer_pledge > 0`; `0 ≤ retained_surplus_share < 1`. These are enforced at construction (`validate_cooperatives`).
- `harvest_shock_start` + `harvest_shock_length` ≤ `maximum_rounds`; `bond_term_short` < `bond_term_long`; `tax_bracket_edges` strictly increasing with one more rate than edges.
- `initial_production_target` should be about `number_of_persons` ÷ (2 × number of farms) for a village that feeds itself from round 1; the dashboard proposes this value when the population changes.
- Runs that end early report why (`termination_reason`): everyone dead, half dead (if enabled), no farm or bakery left, stationary, maximum rounds.

## 6. Run controls

| control | default | notes |
|---|---|---|
| seeds | 1–6 | list or range; each seed is an independent replay; the same seeds are used for both sides in compare mode |
| `maximum_rounds` | 50 | up to 500; a 16-person round takes milliseconds, a 1,000-person round about a second |
| compare debt / SuMSy | on | runs the configured village under both systems with the system-specific defaults of Section 7 applied to the other side |
| stop rules | `stop_when_half_dead`, `stop_when_stationary` | both off for fixed-length comparisons |
| identity check | on | the money-accounting gap is reported per run and flagged if not zero to 1e-6 |
| export | CSV of per-round data, JSON of parameters, PNG of every chart, a printable two-column comparison page in the report's format |

## 7. Presets

A preset is a named parameter set. The ladder of the report is the first family; the user can save their own.

| preset | what it sets |
|---|---|
| Original specification | all behaviour switches off (the code defaults) |
| Behaviour rules (price of admission) | `demand_based_targets`, `wage_ceiling_from_own_ask`, `expected_price_from_asks`, `ask_increase_only_on_unmet_demand`, `random_hiring_ties`, `no_labour_tolerance`, `offer_full_capacity`, `credit_for_bread`, `spoilage_aware_stocking`, `distress_land_sales`, `wage_reservation_net_of_tax`, `initial_endowment = :norm`, `startup_loan_term = 60`, `land_sales = :reservation`, `maximum_capacity = 4`, `number_of_landowners = 4`, `land_units_per_landowner_override = 6`, `gluttony_probability = 0.1`, `plan_for_gluttony` |
| Rung 0 bare bones | rules + no government activity, no benefit, no deposit interest, no theatre |
| Rung 1 + planning margin | + `planning_margin = 0.1` |
| Rung 2 + government | + taxes 15 %, benefit one meal for the fully idle, public jobs 10 % (SuMSy: `demurrage_tax_rate = 0.01`, public jobs 10 %) |
| Rung 3 + interest on deposits | + yearly 1 % + 2 % loyalty (debt only) |
| Rung 4 + theatre | + `entertainment` |
| Rung 5 + bonds | + `government_bonds` (debt only) |
| Rung 6 + charge on balances | + `enterprise_tax = :reserves`, 5 %, standard reserve exempt (debt only) |
| Rung 7 + second theatre | `number_of_theatres = 2` |
| Rung 8 + shareholders | + `ownership = :shareholders`, `share_market` |
| Rung 9 co-ops vs profit | `number_of_farms = 4`, `number_of_bakeries = 4`, `ownership = :mixed`, `share_market`, `startup_financing = :paid_in_capital` |
| Greed stress test | rung 8 + `greed`, `greed_share = 1` (with the hoarding slider, Section 9) |
| SuMSy side defaults | `monetary_system = :sumsy`, `guaranteed_income = 5`, `demurrage_free_buffer = 30`, `demurrage_rate = 0.02`, account fees 0.5 / 1.5, `instalment_purchases`, `land_price_rent_multiple = 50`, taxes and benefit off |
| 64-person village | `number_of_persons = 64`, `number_of_landowners = 16`, `land_per_person = 1.5`, `initial_production_target = 10`, `shares_per_person = 10`, `shareholder_count = 4`, two theatres |
| 1,000-person village | `number_of_persons = 1000`, `number_of_landowners = 100`, `land_units_per_landowner_override = 12`, 5 farms, 4 bakeries, 3 banks, 2 theatres, `initial_production_target = 250`, `shareholder_count = 10` |

## 8. Results

**Metric cards** (per side, from each run's *last* round, averaged over seeds, with the range; runs that ended early are included at their last round and counted): persons alive; hungry person-rounds; persons without work per round; bread baked and needed; tickets per round; bread price, wage, rent, ticket price; money in circulation; public debt, private debt, and both as % of a year's GDP (GDP = bread sold × price + ticket revenue, annualised over the trailing twelve rounds, shown from round 12); government deficit % of GDP; Gini of cash and of net wealth among persons; enterprise cash against reserves; dividends paid; share trades and share price against book value; cooperative memberships and capital; founders' debt and capital; money-identity gap.

**Per-round charts** (same scale on both sides): persons alive with the seed band and hungry bars; money in circulation; money, all debt and public debt as % of GDP (solid / dashed / dotted); prices and wages; output against need; unemployment and theatre labour; wealth by actor group (share of total and % of an equal share per actor); Gini of cash and of wealth; under SuMSy, guaranteed income created against demurrage destroyed; under greed runs, extra loaves and tickets per consumer and capital per hoarder.

**Tables**: the per-round CSV (`round_data`), the event log filtered by kind (loans, refusals, seizures, closures, share trades, memberships, dividends), and the end state of every agent.

## 9. Staged changes (not yet in the code; the dashboard should reserve the widgets)

- *(done 14 September)* `land_per_person` and `greed_hoarding` are now in the code and in the tables above; `greed_hoarder_fraction` is gone.
- A *sweep* control: run one parameter across a list of values (e.g. `greed_hoarding` 0, 0.25, 0.5, 0.75, 1) and chart the metric cards against it.

## 10. Change log

- 20 September 2026 (night): the mix is a lever per tax family (`tax_levers`: shift by r × lever, then move by r; replacing the weights, which could only raise, and the sliders, whose shift the raise cancelled), the wealth tax in the mix with its own scale; `mix` block.
- 20 September 2026 (latest): wealth tax on land and shares at book value (`wealth_tax_rate`, `wealth_tax_rounds_per_year`); `wealth` block. 428 tests.
- 20 September 2026 (later): consumption tax (`consumption_tax_rate`, `consumption_tax_share`), scaled by the fiscal policy; `vat` block. 418 tests.
- 20 September 2026: theatre capacity (`shows_per_round`, `seats_per_show`); unmet-demand and unsold thresholds; ask floor at cost; `start_at_saturation = :equilibrium`; government reserve with per-capita and tax-cut disposal; fiscal policy (`tax_policy` :scale / :brackets, incremental, both directions). Findings in `HANDOFF_2026-09-18.md`. 395 tests. `all64.jl` resumable, takes `<block> <seeds> <systems>`. Starting prices asserted identical across systems.

- 18 September 2026: one random stream per subsystem (`random_streams`); golden values regenerated as a second set, the 15 September set kept under `random_streams = false`; every cooperative run rerun. Membership contribution forms (`membership_contribution`, `membership_buffer_pledge`, `buffer_contribution_value`): a member may pledge demurrage-free buffer instead of money. 329 tests passing.
- 14 September 2026 (cooperatives): three cooperative forms per kind (`cooperative_form_*`: :member kept as the original rule, :worker, :consumer), `cooperative_theatres`, patronage distribution with an indivisible reserve, members-first hiring with the work spread over members, membership out of wages, patronage rebates with member price awareness, hours- and purchase-based lapse, asset lock on dissolution, `cooperative_founding = :symmetric` capital calls. New data columns `coop_*`, `patronage_wages`, `rebates`, `membership_capital`, `reserved_labour`, `unemployed_members` / `_nonmembers`. Ladder rungs 9a, 9b; `all64.jl` blocks `coops` (8 variants) and `contribution` (6).

- 13 September 2026: first version, generated from `parameters.jl` after the greed, rationing and tiered-price additions; 113-test suite passing.
- 15 September 2026 (later): ladder rerun at 64 persons over 100 rounds with three seeds; `inherited_money` test variant; the report's ladder rebuilt on it.
- 15 September 2026: `start_at_saturation` (upper / lower bound of the money-stock band) and `initial_price_multiplier`; every rung rerun from both saturated starts.
- 14 September 2026 (night): `shares_per_person` (share units scaled to the population); greedy share purchases use the trading market's valuation, voluntary sellers and control floor; 64-person preset; 145 tests passing.
- 14 September 2026 (evening): deferred payment for shares with share collateral; tests for the trading share market and deferred payment (140 tests passing); distress trades marked in the event log.
- 14 September 2026 (later): share market extended — forward valuation, per-person yield spread, voluntary founder sales down to a control floor, resale-expectation switch; `wage_ceiling_in_breads`, `guaranteed_income_in_breads` (test switch), `no_self_service`, `tiered_bread_price`, `bread_rationing` added to their panels.
- 14 September 2026: `land_per_person` and the `greed_hoarding` slider added (replacing `greed_hoarder_fraction`); clearing and peer-lending made one pass over the books (a 1,000-person SuMSy round from 30 s to 1 s); 117 tests passing.