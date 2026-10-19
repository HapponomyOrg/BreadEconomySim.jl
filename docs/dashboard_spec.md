# BreadEconomySim — dashboard design document

*Version 6, 19 October 2026 (model version 2026-10-19.2). Supersedes version 5 of 18 October: the purpose widened from running the ladder to a policy tool and a game, with configurations, series, a tutorial and tooltips in two registers. The parameter tables of §5 are generated from `src/parameters.jl` (349 parameters) by `scripts/dashboard_tables.py` and must be regenerated whenever that file changes; everything else is design.*

## 1. Purpose and audiences

The dashboard is a tool for testing configurations of the village, under either kind of money or both. Three kinds of people use it, and it must serve each without getting in the others' way:

- **The researcher**, who wants every switch and parameter, sweeps, the ladder as presets, and the raw data.
- **The policy maker**, who wants to ask what a measure does — a basic income, a debt ceiling, a land levy, public land, a tax on bread — in a village like the one in the report, and read the answer as lives, work, prices, debt and the gap between rich and poor.
- **The player**, who takes the village as a game: pick a money, set the rules, run ten years, see who lives, try again.

What they share is the object they work on: a **configuration**, and a way of saving, comparing and grouping configurations into series. What differs is how much of the model they see at once (§3) and how it is explained to them (§12).

## 2. The objects

- **A parameter set** is one complete `SimulationParameters`: every switch and number, including the money system and its own parameters (the fee, the tax, the income under SuMSy; the interest rates and bonds under debt money). A parameter set is saved by name, with the model version it was made under.
- **A configuration** is what the dashboard runs: a parameter set for the debt side and one for the SuMSy side, with everything the two share held in common and only the money-specific parameters differing — exactly how a rung of the ladder is defined (`V8_DEBT…`, `V8_SUMSY…` over a shared base). A configuration can also be one side alone. Running a configuration means N seeds of each side, the same seeds for both, so that the two villages are compared seed by seed.
- **A series** (Stef, 18 October; the ladder is the series that ships with the model) is an ordered list of configurations with a name and a note, run as one batch like `scripts/run_all.jl` runs the ladder: resumable, deduplicated by parameter hash and model version, summarised into one table. A user builds a series by adding configurations to it, from scratch, from a preset, or by varying one configuration over a list of values (a sweep is a series generated that way). Series can be shared and run by someone else, which is how a policy question becomes a reproducible experiment.
- **A run** is a configuration or series executed under a model version, with its seeds, its per-round data, its summary rows and its event log. Runs are never silently reused across model versions.

## 3. Architecture and layout

- **Backend**: a Julia HTTP service wrapping `run_simulation(SimulationParameters(; kwargs...))`, the same code path as `scripts/run_all.jl`. One endpoint validates and runs a configuration (N seeds × 1 or 2 sides × M rounds) on a worker pool; a series is a batch of those. Results are the per-round data (`round_data`), the summary columns of `run_all.jl` and the event log. Finished runs are reused by parameter hash and model version.
- **Frontend**: a single-page app. State = the configuration being edited (two parameter sets over a shared base), the run controls, the current series and the results view. Widgets bind to parameter names 1:1, so a saved configuration is parameter sets and nothing else.
- **Three views of the same configuration**, chosen at the top and switchable at any time:
  - **Basic** (the game and the first policy questions): the money chooser and about twenty-five levers in plain words — the income, the benefit, the taxes, the land levy or public land, the debt ceiling, austerity, public jobs, the transport line, contracts and temps, greed, hoarding — each with its default and its ladder range. Everything else at the model's defaults.
  - **Policy**: the Basic levers plus the government, land, money and labour tabs in full, about sixty parameters, with the switches that turn whole parts of the model on and off.
  - **Expert**: every parameter of `SimulationParameters`, in the tabs of §5, with the ladder as presets and the sweep builder.
  A configuration made in one view opens in any other; Basic shows a note when something outside its levers is set away from the default.
- **The village's size and the run's length are set in every view** (Stef, 18 October): the run in years (the model's `maximum_rounds`, shown as years and months), the number of villagers (`number_of_persons`) and the land (`number_of_landowners` and `land_units_per_landowner_override`, shown as plots in all and plots per owner; under public land, plots in all), and for each kind of firm its minimum and maximum: farms, bakeries, theatres and banks (the starting numbers `number_of_farms`, `number_of_bakeries`, `number_of_theatres`, `number_of_banks`; the floor below which a kind is restarted, `refound_minimum`; the ceiling on entry, `entry_max_ratio` × the start, shown as a number). The report's village (512 people, 120 months, 4 of each kind, 128 plots) is the default and marked as such, so that a result can be compared with the report's or deliberately moved away from it. Validation holds the sizes to what the model's rules assume: at least two of each kind of firm where there is a market in it, landowners fewer than villagers, the land enough to feed them (the plots per farm formula of §6).
- **A runtime estimate before every run**, with a warning when it is long. Runtime grows with villagers × months (the per-month cost of the markets is roughly linear in villagers, with a quadratic share in the labour market's ordering and the land market), and with seeds and sides. The estimate is **calibrated, not assumed**: the backend keeps, per model version, the measured seconds per villager-month on its own workers from every run it has made (the ladder's runs give it 1,900 points at 512 × 120 before anyone else runs anything), fits a line through them, and shows "about N minutes on this machine" with the fit's spread; the first run after a model version change shows the previous version's estimate marked as such. Above a threshold (default ten minutes) the run asks for confirmation and offers the usual ways down — fewer seeds, fewer years, one side — with their estimates. A run that will take hours is queued and the page can be left; the result is in the user's runs when they come back.
- **Validation** in the frontend from the rules of §6 and again in the backend.
- **Persistence**: in a database (below); every run is saved with its configuration, seed list, model version (`MODEL_VERSION`) and git commit; presets, configurations and series are named and versioned; runs made under an older model version are shown greyed with their version.

### Storage and sharing (design only — not implemented)

**The database is DuckDB** (Stef, 18 October), through its Julia client (https://duckdb.org/docs/lts/clients/julia): embedded, one file, SQL, columnar, and it reads and writes Parquet and CSV directly, so the part files `run_all.jl` already writes can be loaded as they are and the results tables of §9 are queries. The backend owns the file; the frontend never touches it.

**Tables** (the names are the objects of §2):
- `users` — id, name, created.
- `parameter_sets` — id, owner, name, note, model version, created, the parameter hash, and the parameters themselves in one JSON column (the full `SimulationParameters` as keyword pairs; a struct column would break at every added parameter, JSON does not). The hash is over the parameters and the model version; two sets with the same hash are the same village.
- `configurations` — id, owner, name, note, the shared base (a parameter set), the debt side and the SuMSy side (each a parameter set, or null for a one-sided configuration), created.
- `series` — id, owner, name, note, created; `series_items` — series, position, configuration. The ladder is loaded as a series owned by the system from `scripts/ladder_definition.jl`, one configuration per rung.
- `runs` — id, configuration, side, seed, model version, git commit, rounds, started, finished, status (done / failed / running), and the per-round data as a Parquet file referenced by path (the part file), with its summary row (the columns of `run_all.jl`'s summary) in `run_summaries`. A run is reused by (parameter hash, side, seed, rounds, model version), as `run_all.jl` reuses part files.
- `shares` — what is shared with whom, below.

**Sharing** is decided by the owner, object by object, and separately for parameters and results:
- A parameter set, configuration or series is **private** by default. Its owner can share it with named users, with a group, or with everyone; a shared series brings its configurations and parameter sets along as read-only copies, so a change by the owner never changes what someone else is looking at (a share is a snapshot with a pointer to the original).
- **A subset of parameters** can be shared instead of the whole set: the owner marks which parameters are visible (by tab, or one by one); the rest are shown to others as "set, not shared" so that a recipient knows the village has settings they cannot see. A run cannot be reproduced from a partial share, and the dashboard says so.
- **Results** are shared separately from parameters: a run's per-round data, its summary row and its event log can each be shared or kept, so that someone may publish what their village did without publishing how it was built, or the reverse.
- Everything shared with everyone is listed in a public gallery with its model version; the report's own cells are there as the system's series, so that a policy maker's configuration can be compared with the report's village by one click.

**Two things to know about DuckDB before building on it.** It is an embedded database with one writer at a time: a web service with several worker processes writes through one connection (the backend's) and the workers return their results to it, which is how `run_all.jl` already works. And it is a file: sharing between users means one backend serving one file, or a hosted DuckDB; nothing in the schema above depends on which. Parquet export of any table or query is one statement, which is the route to the report's figures and to anyone who wants the data in Python or R.

- **Layout** (Policy and Expert views): a tab bar across the top, one tab per group of §5 plus **Run**, **Series** and **Results**. Each parameter tab has, at its head, the tab's switches, and below them the parameters, each greyed out until the switch that governs it is on. A **compare** toggle (debt / SuMSy / both) applies to every tab; parameters that exist in only one money are shown only when that side is selected. A search box finds any parameter by name or meaning across tabs. The Basic view is one page: the money, the levers, Run, and the result as a picture (§11).

## 4. Switches and what they govern

Each tab's switches, with the parameters they enable. A switch that is off removes its part of the model entirely (the ladder's lower steps are nothing else).

| tab | switch | enables |
|---|---|---|
| Village | `entertainment` | theatres, tickets, `number_of_theatres`, `shows_per_round`, `customers_per_labour_unit`, `theatre_seat_margin`, `volunteers_in_theatres` |
| Village | `bread_rationing`, `tiered_bread_price` | rationing and its tiers |
| Money | `monetary_system` (= :sumsy) | `guaranteed_income`, `demurrage_*`, the parking tax, peer lending, buffer pool, default insurance, instalments at a negative rate |
| Money | `government_bonds` | bond terms, `bond_coupon` |
| Money | `settlement` (= :invoicing) | `receivables_advance_rate`, `liquidation_*`, the invoice month |
| Money | `interest_from_equity`, `bank_capital_ratio` > 0 | the capital reserve; `capital_constrains_lending` |
| Money | `bank_rate_follows_inflation` | `bank_rate_inflation_cap` |
| Money | `owner_guarantee` | `guarantee_write_off_rounds` |
| Money | `bank_bailout` | the government behind the banks (off at steps 0–1) |
| Government | `government_employment_share` > 0 | public jobs; `government_wage_*` |
| Government | `unemployment_fee_in_breads` > 0 | the benefit; `minimum_fee_in_breads`, `fee_reduction_*`, `benefit_indexed`, `austerity_*` |
| Government | `tax_policy` (≠ :none) | `tax_levers`, `tax_response_*`, `tax_scale_*` |
| Government | `government_reserve_in_rounds` > 0 | the reserve rule, `surplus_tax_reduction_share`, `surplus_redistribution_share` (the dividend) |
| Government | `public_debt_limit` > 0 | the debt ceiling, `public_spending_floor` |
| Government | `public_project_start` > 0 | the public investment and its parameters |
| Government | `land_levy` | `land_levy_margin`; requires the land market |
| Prices | `fixed_prices` | freezes every price; disables the whole tab below it |
| Prices | `land_pricing` (= :market) | the land market's discovery; `land_price_step`, `land_life_event_rate`, `instalment_bargaining` |
| Labour | `wage_threshold`, `wage_cut_maximum` < 1 | the wage rules; `wage_floor_months`, `food_emergency_share` |
| Labour | `employer_loyalty`, `notice_months` > 0 | continuity of employment; `notice_tenure_months` |
| Labour | `minimum_labour_offer` > 0, `volunteer_share` > 0 | work as purpose; the commons measure |
| Labour | `standard_of_living_tickets` > 0 | the standard of living |
| Firms | `ownership` (≠ :none) | owners, shares, `founders`, `founding_equity`, `share_market`, the cooperative block |
| Firms | `market_entry` | `entry_*` |
| Firms | `refound_minimum` > 0 | restarts, `refound_cooldown` |
| Land and gold | `gold_grams_per_villager` > 0 | the gold market and its parameters |
| Behaviour variants | `greed` | `greed_share`, `greed_hoarding`, `greed_selection`, `greedy_max_*` |
| Run control | `stop_when_half_dead`, `stop_when_stationary`, `stop_without_producers` | the stopping rules |
| Village | `volunteer_kinds` (non-empty), `volunteers_in_theatres` | volunteers staff the named enterprise kinds after the paid hiring; farms and bakeries produce with volunteer labour |
| Village | `community_theatres` > 0 | volunteer-run theatres that hire nobody; `community_ticket_in_breads` |
| Money | `monetary_system` = :debt with `demurrage_tax_rate` > 0 | a tax on idle money in the debt village (nothing destroyed); the levy then follows the cost of holding money |
| Government | `basic_income` > 0 (debt money) | a basic income paid by the government, borrowed where taxes fall short; cut by a debt ceiling |
| Government | `income_cut_start` > 0 | the income (either money) cut to `income_cut_share` from that month |
| Government | `land_levy_dividend` | the month's levy paid out per head (debt-money twins) |
| Land and gold | `levy_pass_through` | landowners let no plot for less than its levy (Gesell's objection) |
| Prices | `greedy_pricing` | firms with greedy owners price at what buyers will pay on a sell-out |
| Prices | `distress_pricing` | a firm near failure abandons the step limit (`distress_share`, `distress_months`) |
| Firms | `distress_cost_cutting` (on by default) | a firm near failure with stock left cuts its plan to what it sold |
| Firms | `own_market_planning` (on the base) | each firm plans on its own sales at the gradual pace (`plan_adjustment_months`, `plan_small_change`) and plans `plan_step` more after selling out; the village plan is only the **emergency rule**, in force while bread is short for want of production (not for want of money) until `intervention_exit_months` months with enough baked |
| Firms | `firms_plan_on_sales` (superseded) | each firm's share of a village plan follows its sales share, gradually; kept for comparison |
| Firms | `refound_minimum` (2 on the base) | the fewest firms of a kind the village keeps: below it, entrepreneurs found a new one from a closed firm's shell |
| Firms | `plan_greedy_on_purchases`, `plan_within_capacity` | bakers plan greedy demand on purchases, within their ovens (`bakery_capacity_share`) |
| Firms | `premium_markup` > 1 | the premium loaf (`premium_labour_per_loaf`, `premium_buyer_margin_in_meals`) |
| Labour | `labour_for_bread` | offers sized on the village's need, everyone's capacity when bread or hands fell short (`labour_for_bread_margin`, `labour_for_bread_memory`) |
| Behaviour | `greed_month` > 0 | the greedy chosen at that month by net wealth (or at random) |
| Behaviour | `cash_hoarder_share` > 0 | cash hoarders (bread only, nothing else bought or lent); `cash_hoarder_month` |
| Behaviour | `nonworking_share` > 0 | villagers who take paid work only to eat (`nonworking_hungry_share`) |
| Behaviour | `spoilage_acceptance` | the most bread a greedy villager will hold |
| Land and gold | `gold_grams_per_villager` > 0 | gold; reported beside wealth, never in it |
| Labour | `joint_labour_market` (on by the ladder) | bakeries and theatres hire in one market, in turns; farms and banks before the harvest |
| Labour | `contracts` (on the base, `contract_share` = 0.8: a fifth of every employer's hands are temps), the dial | a worker with three months' tenure gets a contract while there is room; the employer takes the contracted units first, the worker's other hours stay on the market; indexed to bread (`contract_indexation`); notice both ways (`notice_months`, `worker_notice_months`) |
| Labour | `experience` | months running in one kind of enterprise: levels, output bonus, hired first at equal cost (`experience_months`, `experience_bonus`, `experience_decay_months`) |
| Land and gold | `public_land` | the government owns the land; ground rents in loaves under the tax levers; excludes the land market and the levy; `public_land_dwelling_exempt_benefit`, `public_land_dwelling_in_benefit` for those on the benefit |


## 5. Parameter tabs

Columns: *type* as in `SimulationParameters`; *default* as in the code (the ladder's `RULES` override many — the Run tab shows the ladder's values beside the code's); *sweep*: **yes** = a numeric or Boolean parameter that can be given a list or a range in a sweep; **list** = a Symbol that can be given a list of options; **no** = structured (a dictionary, a vector, a named tuple) — editable in a form, not swept. The *meaning* column is the comment from the code, shortened.

<!-- generated by scripts/dashboard_tables.py from src/parameters.jl: 349 parameters -->

### Village — 41 parameters

| parameter | type | default | sweep | meaning |
|---|---|---|---|---|
| `number_of_banks` | Int | `2` | yes | Agents |
| `number_of_farms` | Int | `3` | yes |  |
| `number_of_bakeries` | Int | `3` | yes |  |
| `number_of_persons` | Int | `16` | yes |  |
| `number_of_landowners` | Int | `2` | yes |  |
| `maximum_capacity` | Float64 | `3.0` | yes | Capacity, food and death |
| `capacity_recovery_per_round` | Float64 | `2.0` | yes |  |
| `half_meal_capacity_fraction` | Float64 | `2 / 3` | yes |  |
| `rounds_without_food_until_death` | Int | `3` | yes |  |
| `breads_per_grain` | Int | `2` | yes |  |
| `breads_per_meal` | Int | `2` | yes |  |
| `initial_breads_per_person` | Float64 | `2.0` | yes | bootstrap: everyone starts with one meal in stock |
| `maximum_breads_per_round` | Int | `3` | yes | gluttony: up to this many breads eaten in a round |
| `gluttony_probability` | Float64 | `0.10` | yes | chance a person who can pay cash eats a third bread |
| `stocking_marginality` | Vector{Tuple{Int, Float64}} | `[(3, 1.0), (4, 0.5), (5, 0.3), (7, 0.15)]` | no | after gluttony: chance of one more bread while stock < units |
| `spoilage_age_in_rounds` | Int | `3` | yes | Goods |
| `initial_prices` | OrderedDict{Symbol, Float64} | `OrderedDict(:bread => 5.0, :grain => 5.2, :rent => 0.75, :wage => 3.92, :ticket => 2.0)` | no | static-consistent vector, see HANDOFF |
| `initial_production_target` | Int | `6` | yes |  |
| `initial_interest_rate` | Float64 | `0.05` | yes |  |
| `demand_based_targets` | Bool | `false` | yes | producers plan output for the living population instead of the ±1 ratchet |
| `spoilage_aware_stocking` | Bool | `false` | yes | stockers hold at most breads_per_meal × spoilage_age (nothing they buy will spoil) |
| `land_per_person` | Float64 | `0.0` | yes | > 0: total land = land_per_person × persons, shared equally by the landowners (overrides the formula and the override); 2 makes four loaves a head feasible on the land side |
| `initial_money_per_person` | Float64 | `30.0` | yes | debt-free initial money, created by the authority |
| `initial_price_multiplier` | Float64 | `1.0` | yes | scales the initial price vector (a saturated village runs at a lower price level than a starting one) |
| `initial_endowment` | Symbol | `:none` | list | :none \| :norm — persons: savings target (3 meals); farms/bakeries: standard working reserve |
| `harvest_shock_start` | Int | `0` | yes | 0 = no shock |
| `harvest_shock_length` | Int | `3` | yes |  |
| `harvest_shock_factor` | Float64 | `0.5` | yes |  |
| `entertainment` | Bool | `false` | yes | Entertainment (13 September 2026): a pure service, labour only |
| `number_of_theatres` | Int | `1` | yes |  |
| `customers_per_labour_unit` | Float64 | `2.5` | yes | 10 customers per full-time job at capacity 4 |
| `max_tickets_per_person` | Int | `3` | yes | 1–3 tickets a round, at random within what cash above the buffer allows |
| `entertainment_propensity` | Float64 | `1.0` | yes | probability a person who can afford a ticket wants one |
| `shows_per_round` | Int | `0` | yes | Theatre capacity (20 September 2026). A theatre runs at most `shows_per_round` shows a round with `seats_per_show` seats each, so it can sell at most shows × seats tickets and never needs more labour than that takes at `customers_per_labour_unit`. 0 shows = unlimited (the rule until 20 September: a theatre absorbed whatever labour ticket demand paid for). 0 seats = one seat for every person in the village at founding. |
| `seats_per_show` | Int | `0` | yes | 0 = villagers ÷ theatres × (1 + theatre_seat_margin), so the theatres together seat the village plus the margin |
| `theatre_seat_margin` | Float64 | `0.25` | yes | 21 September: with several theatres a seat per villager *per theatre* would be several times the village |
| `bread_rationing` | Bool | `false` | yes | Bread rationing (13 September 2026): stage one, everyone up to the ration; stage two, leftovers to the greedy |
| `ration_breads_per_person` | Int | `4` | yes | lowered to what the shelves can give everyone, never below a meal |
| `tiered_bread_price` | Bool | `false` | yes | loaves beyond the ration sell at a second posted price that rises on unmet greed and falls on unsold leftovers (never below the ordinary price) |
| `tier_step` | Float64 | `0.06` | yes |  |
| `no_self_service` | Bool | `false` | yes | a theatre's workers are not served at their own theatre that round |

### Money — 59 parameters

| parameter | type | default | sweep | meaning |
|---|---|---|---|---|
| `loan_term_in_rounds` | Int | `20` | yes | Credit |
| `affordability_ratio` | Float64 | `0.8` | yes |  |
| `interbank_rate_discount` | Float64 | `0.5` | yes | bank-to-bank loans at discount × lender's rate |
| `government_rate_discount` | Float64 | `0.5` | yes |  |
| `government_rate` | Float64 | `0.005` | yes | per round; the government's borrowing rate (a policy rate, about 6 % a year); NaN = the bank's marginal rate × government_rate_discount (a bank with a small loan book then charges a great deal) |
| `maximum_interest_rate` | Float64 | `0.05` | yes | per round; a ceiling on the rate a bank may set |
| `arrears_rounds_until_seizure` | Int | `2` | yes |  |
| `garnishment_rate` | Float64 | `0.25` | yes |  |
| `debt_dies_with_bank` | Bool | `false` | yes | Variants |
| `credit_for_bread` | Bool | `false` | yes | a person may promise a meal on credit when eligible for the loan (spec v1 §4.9 'borrowed if needed') |
| `monetary_system` | Symbol | `:debt` | list | :debt (bank credit creates money) \| :sumsy (GI created, demurrage destroys, peer lending only) |
| `guaranteed_income` | Float64 | `5.0` | yes | per person per round, fixed nominal (one bread at the initial price) |
| `guaranteed_income_in_breads` | Float64 | `0.0` | yes | > 0: the income is this many loaves at the expected bread price each round (indexed; breaks the bounded money stock — a test, not a design) |
| `demurrage_rate` | Float64 | `0.02` | yes | per round, on balances above the buffer; destroys money |
| `demurrage_tax_rate` | Float64 | `0.0` | yes | surcharge on the same base, transferred to the government |
| `demurrage_free_buffer` | Float64 | `30.0` | yes | persons only (3 meals at initial prices); everyone else: 0 |
| `start_at_saturation` | Symbol | `:none` | list | SuMSy: :upper — every person starts at buffer + GI/d (all buffers used, stock N·b + N·GI/d); :lower — one person holds b + N·GI/d, the rest nothing; :equilibrium (20 September 2026) — every person at b + GI/(d + demurrage tax), the balance at which their own creation equals their own destruction, so the stock starts inside its bounds and stays there. The money stock depends on GI and demurrage only, never on prices: a village started below its equilibrium sees the stock — and with it the price level — rise for ~60 rounds. Pair with `initial_price_multiplier` ≈ 1.35 (the 64-person steady state: bread 1.27×, grain 1.32×, wage 1.49× the initial vector; the 0.63 used in the 15 September saturation runs is a 16-person figure) |
| `account_fee_person` | Float64 | `0.5` | yes | per round, promised to the person's bank at clearing |
| `account_fee_enterprise` | Float64 | `1.5` | yes |  |
| `peer_lending` | Bool | `true` | yes |  |
| `peer_loan_rate` | Float64 | `-0.01` | yes | borrower's rate per round (negative: lending beats demurrage) |
| `bank_spread` | Float64 | `0.005` | yes | lender receives peer_loan_rate − bank_spread |
| `affordability_pricing` | Bool | `false` | yes | a seller who turned buyers away for lack of cash cuts its ask towards their cash, above its cost floor |
| `inherited_money` | Bool | `false` | yes | debt money: villagers start with the SuMSy starting cash debt-free — residual money of deceased villagers whose loans were written off (booked against the banks' equity) |
| `bread_loan_term` | Int | `0` | yes | persons' clearing credit (meals) at this term; 0 = loan_term_in_rounds |
| `deposit_interest_rate` | Float64 | `0.0` | yes | per payout period, on the average end-of-round balance over the period |
| `deposit_interest_period` | Int | `1` | yes | rounds between payouts (1 = every round; 12 = yearly) |
| `loyalty_bonus_rate` | Float64 | `0.0` | yes | per period, on the lowest end-of-round balance over the period |
| `deposit_interest_to_enterprises` | Bool | `false` | yes | business accounts earn nothing unless switched on |
| `instalment_purchases` | Bool | `false` | yes | Instalment purchases (SuMSy): seller-financed land sales, paid in equal instalments, land as collateral |
| `instalment_rounds` | Int | `20` | yes |  |
| `deferred_payment` | Bool | `false` | yes | a share buyer short of cash may pay in instalments; the seller finances it at deferred_payment_rate (bank keeps its spread) |
| `deferred_payment_rounds` | Int | `20` | yes |  |
| `deferred_payment_rate` | Float64 | `NaN (unset: see meaning)` | yes | NaN = peer_loan_rate under SuMSy (−1 %), 0.5 % a round under debt money |
| `buffer_lending` | Bool | `false` | yes | persons may lend part of their demurrage-free buffer to their bank (exemption moves with the money) |
| `buffer_lending_participation` | Float64 | `0.5` | yes | share of persons who opt in |
| `buffer_lend_fraction` | Float64 | `0.5` | yes | share of the buffer a participant lends |
| `buffer_lender_spread_discount` | Float64 | `0.5` | yes | participants pay this fraction less of the bank spread when they borrow |
| `default_insurance` | Bool | `false` | yes | instalment sellers pay a premium; the bank covers missed instalments from its reserves and takes over the claim |
| `insurance_premium_rate` | Float64 | `0.02` | yes | share of each instalment paid by the insured seller to the bank |
| `bond_term_long` | Int | `60` | yes |  |
| `bond_term_short` | Int | `12` | yes |  |
| `bond_coupon` | Float64 | `NaN (unset: see meaning)` | yes | The coupon (28 September, Stef): NaN = the market rule (midpoint of the deposit rate and the government's bank rate); a number = a coupon the government sets, per month (a safe haven sells at a low rate too; 0 is the floor without a central bank). |
| `clearing` | Bool | `true` | yes | Clearing switch (13 September 2026): true = all intra-round payments are promises netted at clearing (spec v2 addendum); false = every payment is settled immediately (cash, then credit, the unpaid tail becomes a trade arrear) |
| `buffer_contribution_value` | Float64 | `1.0` | yes | money a unit of pledged buffer counts for under :mixed_flexible (0 under debt money) |
| `receivables_advance_rate` | Float64 | `0.8` | yes | Liquidation (design §2): a producer whose invoices overdue by `liquidation_overdue_rounds` or more reach `liquidation_arrears_share` of its book value is sold as a going concern at `liquidation_price_share` × book value (never below the debt left after its cash), to up to `shareholder_count` buyers with the most spare cash, who hold the new shares pro rata; if no group can pay, it is closed and its assets go to its creditors, the rest struck. Working capital (22 September): under :invoicing a supplier waits a month to be paid, so banks lend against what it is owed — a loan is affordable when it is covered by `receivables_advance_rate` of the open invoices owed to the borrower, whatever the income test says (invoice financing). 0 switches it off. |
| `bank_customers_per_labour_unit` | Int | `0` | yes | Bank staff (22 September): 0 = one unit of labour per bank, as before. k > 0 = one unit per k villagers the bank serves, so a bank's wage bill grows with its customers and the cost-recovery lending rate does not fall just because the village is larger. |
| `instalment_bargaining` | Float64 | `0.5` | yes | Seller credit on land (24 September): the monthly rate is a market decision between the seller's best alternative for the money and the buyer's best alternative source of credit; the seller gets this share of the gap (0.5 = split the difference). Under SuMSy both alternatives are negative, so the rate is too. |
| `owner_guarantee` | Bool | `false` | yes | Owners' guarantee (28 September, Stef): a failed firm's bank loans are not written off but pass to its owners in proportion to their shares (or members equally), as personal loans over `founding_loan_term` months — the personal guarantees banks take from small firms' owners; unpaid invoices are still written off in the liquidation. An owner who then pays nothing for `guarantee_write_off_rounds` months is written off (the bank's loss). |
| `guarantee_write_off_rounds` | Int | `6` | yes |  |
| `interest_from_equity` | Bool | `false` | yes | Deposit interest only from equity (28 September, Stef): a bank pays what its retained interest AND its net worth allow — the effective rate can fall to zero, never below; it never books interest it has not earned. |
| `bank_capital_ratio` | Float64 | `0.0` | yes | A capital requirement (28 September, Stef; the Basel accords): a bank keeps equity of at least `bank_capital_ratio` × its risk-weighted loans — private loans at 100 %, loans to the government at 0 % (own-currency sovereign debt needs no capital, under Basel too). Deposit interest is paid only from equity above it. With `capital_constrains_lending` a bank at its requirement makes no new private loan (credit rationing) — public borrowing is never constrained by it. |
| `capital_constrains_lending` | Bool | `false` | yes |  |
| `bank_rate_follows_inflation` | Bool | `false` | yes |  |
| `bank_rate_inflation_cap` | Float64 | `0.10` | yes |  |
| `founding_loan_term` | Int | `60` | yes | Founding loans on business terms (24 September): a founder borrows for their share of the founding equity only what passes the affordability test over `founding_loan_term` months; a founder who cannot carry the full share puts in what they can and the firm starts with less equity (it borrows the rest itself when it needs it). |
| `collection_floor_in_breads` | Float64 | `1.0` | yes | A protected minimum on debt collection (24 September; cf. the legal limits on garnishment): loan repayment and garnishment never take a person's cash below this many loaves at the current price — what cannot be paid becomes arrears. |
| `bank_bailout` | Bool | `true` | yes | a bank whose net worth goes below zero is recapitalised by the government (failure: a future option) |
| `peer_loan_insurance` | Bool | `false` | yes | SuMSy: every peer loan is insured (premium on repayments to the bank's pool; the pool covers a struck loan, the rest is the lenders' loss) |

### Government — 63 parameters

| parameter | type | default | sweep | meaning |
|---|---|---|---|---|
| `surplus_reserve_multiple` | Float64 | `2.0` | yes |  |
| `wage_tax_rate` | Float64 | `0.15` | yes | Government |
| `capital_tax_rate` | Float64 | `0.15` | yes |  |
| `government_employment_share` | Float64 | `0.1` | yes |  |
| `public_project_start` | Int | `0` | yes | A public investment (3 October, Stef — public transport): from `public_project_start` the government employs `public_project_labour_share` of the village's capacity on it at the public wage for `public_project_build_months`, with nothing coming back; then the same workforce runs it and every villager wants one ride a month, bought if affordable after bread at `public_project_fare_in_breads` loaves; the fares are the government's. 0 = no project. |
| `public_project_build_months` | Int | `60` | yes |  |
| `public_project_labour_share` | Float64 | `0.05` | yes |  |
| `public_project_fare_in_breads` | Float64 | `0.50` | yes | of total person capacity |
| `government_wage_in_breads` | Float64 | `2.0` | yes |  |
| `government_wage_premium` | Float64 | `0.10` | yes | net wage for full-time = breads × (1 + premium) |
| `unemployment_fee_in_breads` | Float64 | `2.0` | yes |  |
| `austerity_start` | Int | `0` | yes | Austerity (30 September, Stef): from `austerity_start` the benefit tapers over `austerity_months` to `austerity_fee_in_breads` loaves and stays there (0 = no austerity). |
| `austerity_months` | Int | `6` | yes |  |
| `austerity_fee_in_breads` | Float64 | `1.0` | yes |  |
| `minimum_fee_in_breads` | Float64 | `1.0` | yes |  |
| `fee_reduction_interval` | Int | `3` | yes |  |
| `fee_reduction_rate` | Float64 | `0.10` | yes |  |
| `employment_rounds_to_reset_fee` | Int | `3` | yes |  |
| `partial_unemployment_fee` | Bool | `false` | yes | fee pro rata to the unsold share of offered labour |
| `enterprise_tax` | Symbol | `:none` | list | :none \| :income (on net operating cash flow minus interest; banks on interest received) \| :reserves (on cash held at end of round) |
| `enterprise_income_tax_rate` | Float64 | `0.10` | yes |  |
| `enterprise_reserve_tax_rate` | Float64 | `0.10` | yes |  |
| `reserve_tax_exempts_standard_reserve` | Bool | `false` | yes | :reserves — tax only cash above the standard working reserve |
| `basic_income` | Float64 | `0.0` | yes | 14 Oct (a reader's question: does any village with a basic income and a land dividend keep its people alive?): under debt money `demurrage_tax_rate` > 0 runs too — a tax on balances above the cushion, paid to the government, nothing destroyed — and the cost of holding money becomes the demurrage tax less the deposit return, which is what the land levy follows. `basic_income`: under debt money, paid by the government to every villager each month, borrowed where taxes fall short (under SuMSy the guaranteed income is the money itself). `land_levy_dividend`: the month's levy paid out per head. |
| `income_cut_start` | Int | `0` | yes | The income reversed (15 October): from `income_cut_start` the income — SuMSy's guaranteed income or the debt village's basic income — is cut to `income_cut_share` of its level and stays there, to see what undoing it costs in each money. 0 = never. |
| `income_cut_share` | Float64 | `0.5` | yes |  |
| `public_land` | Bool | `false` | yes | Public land (18 October, Stef — close to Gesell's Freiland): all land is the government's; farms rent the plots they work, bakeries and theatres pay for the ground they stand on, every villager for the ground they live on — ground rents set in loaves, scaled with the tax levers (`tax_scale`), paid to the government as tax. Nobody owns land, so no land market, no land in wealth, no levy: mutually exclusive with `land_pricing = :market` and `land_levy`. The rents default to zero. |
| `public_land_farm_rent_in_breads` | Float64 | `0.0` | yes | per plot a farm works, a month |
| `public_land_firm_rent_in_breads` | Float64 | `0.0` | yes | per bakery or theatre, a month |
| `public_land_dwelling_rent_in_breads` | Float64 | `0.0` | yes | per villager, a month |
| `public_land_dwelling_exempt_benefit` | Bool | `false` | yes | 18 Oct (Stef): the dwelling rent and those on the benefit — exempt them, or add the rent to the benefit (the two policies a debt-money village has; under SuMSy the dividend covers it without a policy). |
| `public_land_dwelling_in_benefit` | Bool | `false` | yes |  |
| `government_reserve_in_rounds` | Int | `0` | yes | Government reserve (20 September 2026). 0 = the rule until now: whatever tax exceeds spending sits on the government's balance (under SuMSy it pays demurrage there, and in the no-greed village it reached a fifth of the money stock). n > 0: the government keeps a reserve of n rounds of expected spending (the trailing mean of its outlays over `government_expense_window` rounds) and disposes of the surplus above it each round, `surplus_redistribution_share` of it as an equal per-capita payment to the living and `surplus_tax_reduction_share` of it by scaling next round's taxes down (all of them: wage, capital, demurrage tax — the scale is one number, `tax_scale`, never above 1). With the two shares summing to 1 the reserve tracks the target up to the volatility of spending; below 1 it drifts up. A shortfall lets the scale climb back towards 1 at `surplus_tax_reduction_share` of the gap a round. |
| `government_expense_window` | Int | `12` | yes |  |
| `surplus_redistribution_share` | Float64 | `0.0` | yes |  |
| `surplus_tax_reduction_share` | Float64 | `0.0` | yes |  |
| `consumption_tax_rate` | Float64 | `0.0` | yes | Fiscal policy (20 September 2026): taxes that move in both directions, incrementally. The shortfall a round is what spending exceeds revenue by (trailing means over `government_expense_window`) plus the gap between the reserve and its target spread over `government_reserve_in_rounds` rounds. The policy aims to close `tax_response_coverage` of it by raising taxes, and lowers them again on a surplus (the reserve rule's `surplus_tax_reduction_share` of the surplus above target), but never changes revenue by more than `tax_response_step` (a fraction of current revenue) in one round, so that there are no shocks. :none     — no raises; only the reserve rule's reductions, unlimited in size (the rule until now) :scale    — one multiplier on every tax (flat wage tax, capital tax, demurrage tax; the whole progressive schedule). The "income" family is the wage and capital tax under debt money and the demurrage tax under SuMSy, which taxes no income; the lever on that family acts on whichever the village has. :brackets — needs `income_tax_schedule = :progressive`: a rise of r changes each bracket's rate to rate × (1 + r) + `bracket_fixed_rise` × sign(r) — proportional, so the 50 % bracket moves five times as much as the 10 % one, plus a fixed number of points per bracket; falls back to :scale under :flat Consumption tax (20 September 2026): a VAT on what persons buy to consume — bread and tickets — paid by the buyer on top of the negotiated price and promised to the government (grain is an input and stays untaxed, as VAT is neutral between firms). The buyer's willingness to pay is for the price including tax, so the ceiling passed to the negotiation is divided by (1 + rate). Belgium's average rate on consumption is about 6 %. The fiscal policy scales it with the same triggers and step as the income tax. |
| `tax_levers` | NamedTuple | `(income = 0.0, consumption = 0.0, wealth = 0.0, profit = 0.0, parking = 0.0, land = 0.0)` | no | land: the land levy (24 Sept) |
| `income_tax_period` | Int | `1` | yes | Collection periods (design §3): 1 = every month, as before; 12 = accrued through the year and charged in the twelfth month. Monthly withholding with a yearly balance (the Belgian mode) is a future option. |
| `profit_tax_rate` | Float64 | `0.0` | yes | Profit tax (design §3): per period, revenue − `deductible_materials` × (materials, rent and interest) − `deductible_labour` × wages, never below 0 (no loss carry-forward), at `profit_tax_rate` (the rate applies to the profit whatever the period's length). Charged to farms, bakeries and theatres; an invoice to the government under settlement = :invoicing. |
| `profit_tax_period` | Int | `1` | yes |  |
| `deductible_materials` | Float64 | `1.0` | yes |  |
| `deductible_labour` | Float64 | `0.5` | yes |  |
| `wealth_tax_rate` | Float64 | `0.0` | yes | per year, on book value of land and shares held by persons |
| `wealth_tax_rounds_per_year` | Int | `12` | yes |  |
| `tax_policy` | Symbol | `:none` | list |  |
| `tax_response_coverage` | Float64 | `0.5` | yes | share of the shortfall a raise is sized to cover |
| `tax_response_step` | Float64 | `0.02` | yes | largest relative change in revenue per round (2 % = incremental) |
| `bracket_fixed_rise` | Float64 | `0.0` | yes | :brackets — points added to every bracket per step, on top of the proportional rise |
| `tax_scale_maximum` | Float64 | `3.0` | yes | :scale — the multiplier never exceeds this (statutory rates × 3) |
| `bracket_rate_maximum` | Float64 | `0.9` | yes | :brackets — no bracket rate above this |
| `government_bonds` | Bool | `false` | yes | Government bonds (13 September 2026): sold to surplus holders through the bank before any bank credit |
| `income_tax_schedule` | Symbol | `:flat` | list | Income tax schedule (13 September 2026). :belgian — brackets as shares of the full-time gross wage (median gross ≈ €45k): social contributions 13.07 % first, then 25/40/45/50 % on taxable income above 0.363/0.64/1.108 × reference, a 25 % credit on an allowance of 0.242 × reference, and a 7 % municipal surcharge. Wage tax only; rent keeps capital_tax_rate. |
| `social_contribution_rate` | Float64 | `0.1307` | yes |  |
| `tax_free_share` | Float64 | `0.242` | yes |  |
| `tax_bracket_edges` | Vector{Float64} | `[0.363, 0.640, 1.108]` | no |  |
| `tax_bracket_rates` | Vector{Float64} | `[0.25, 0.40, 0.45, 0.50]` | no |  |
| `municipal_surcharge` | Float64 | `0.07` | yes |  |
| `dividend_tax_rate` | Float64 | `0.30` | yes | Belgian withholding tax on dividends |
| `benefit_indexed` | Bool | `true` | yes | Banks price inflation into their lending rate (26 September): the cost-covering rate plus the trailing twelve-month rise in the bread price, per month, up to `bank_rate_inflation_cap` a month on top of `maximum_interest_rate`. Off = the rate ignores inflation (a deeply negative real rate once prices rise, and unlimited credit to chase them). A ceiling on public borrowing (26 September): when the public debt exceeds `public_debt_limit` × the village's yearly output (bread and ticket sales over the last twelve months), the government scales its spending — public jobs and the benefit — down in proportion (never below `public_spending_floor`) until the ratio is back under the ceiling. 0 = no ceiling. The benefit is set in loaves at the current bread price (indexed, the rule so far). `benefit_indexed = false` (26 September): the same number of loaves at the founding price — a fixed sum of money, like SuMSy's guaranteed income. |
| `public_debt_limit` | Float64 | `0.0` | yes |  |
| `public_spending_floor` | Float64 | `0.25` | yes |  |
| `tax_scale_minimum` | Float64 | `0.05` | yes | The reserve rule without a tax policy never scales taxes below this (25 September, review 6: at 0 they could never recover). |

### Prices and bargaining — 36 parameters

| parameter | type | default | sweep | meaning |
|---|---|---|---|---|
| `negotiation_steps` | Int | `6` | yes |  |
| `minimum_concession_fraction` | Float64 | `0.25` | yes |  |
| `maximum_concession_fraction` | Float64 | `0.40` | yes |  |
| `ask_increase_after_sellout` | Float64 | `0.06` | yes |  |
| `ask_decrease_after_partial_sale` | Float64 | `0.06` | yes |  |
| `unsold_tolerance_units` | Float64 | `2.0` | yes | unsold ≤ this (one grain-unit of bread) is not 'partly unsold' |
| `ask_decrease_when_idle` | Vector{Float64} | `[0.15, 0.30, 0.45]` | no | desperation: consecutive idle rounds |
| `bid_decrease_after_success` | Float64 | `0.03` | yes |  |
| `bid_increase_when_starved` | Vector{Float64} | `[0.06, 0.12, 0.25]` | no | consecutive rounds of missing out |
| `bread_price_ageing_discount` | Float64 | `0.40` | yes |  |
| `farm_maximum_rent_fraction_of_grain_price` | Float64 | `0.6` | yes |  |
| `bakery_grain_wage_fraction` | Float64 | `0.5` | yes |  |
| `bread_bid_base_multiplier` | Float64 | `1.3` | yes |  |
| `ticket_max_in_breads` | Float64 | `Inf` | yes | Two limits on the price of leisure (28 September; the theatres set the wage level at step 4 — a full house raised its ticket price without end, and an employer's willingness to pay is its revenue per worker): a villager pays at most this many loaves of bread for a ticket, and an employer bids at most this share above the going wage. Inf = no limit. |
| `employer_wage_margin` | Float64 | `Inf` | yes |  |
| `unmet_demand_share` | Float64 | `0.0` | yes | Unmet demand (19 September 2026). Sellers raise their ask and their production target when demand went unmet. 0 = the original rule: one buyer who found nothing is enough. A share s > 0 requires the units that went unserved to be at least s of what the market sold plus what it missed (5–10 % is a realistic threshold). Wages keep the original rule: a worker who sold all their capacity cannot observe how much more was wanted. |
| `unsold_share` | Float64 | `0.0` | yes | Unsold stock, the mirror image (20 September 2026): 0 = the original rule, a cut of `ask_decrease_after_partial_sale` whenever more than `unsold_tolerance_units` were left; a share s > 0 requires the unsold units to be at least s of what was offered, so that the cut has the same logic as the rise on unmet demand. |
| `ask_floor` | Symbol | `:none` | list | Ask floor (20 September 2026). :none = the posted ask may decay without limit (only the negotiation floors it, and aged bread is discounted below cost); :cost = after adaptation the posted ask is never below the seller's unit cost — `seller_reservation` at age 0 — raised by `ask_floor_markup_when_short` while the seller's cash is below its reserve (a producer) or savings buffer (a person). Realistic: nobody prices new output below what it cost to make. |
| `ask_floor_markup_when_short` | Float64 | `0.05` | yes |  |
| `bread_bid_hunger_multiplier` | Float64 | `0.4` | yes |  |
| `wage_ceiling_from_own_ask` | Bool | `false` | yes | employer's maximum wage from the price it will ask for its output, not the market average |
| `expected_price_from_asks` | Bool | `false` | yes | when a good was not traded, expected price = mean posted ask (no frozen prices) |
| `ask_increase_only_on_unmet_demand` | Bool | `false` | yes | sellers raise the ask only when customers were turned away, not on a mere sell-out |
| `distress_land_sales` | Bool | `false` | yes | a hungry or indebted-in-arrears landholder sells one unit per round at a discount |
| `distress_land_discount` | Float64 | `0.8` | yes |  |
| `indexed_pricing` | Bool | `false` | yes | wage, grain and rent asks/bids are re-expressed in bread units every round |
| `reserve_pricing` | Bool | `false` | yes | producers cut their ask (to the cost floor) while cash exceeds the working reserve, raise it when below half of it |
| `reserve_pricing_step` | Float64 | `0.05` | yes |  |
| `expected_price_growth` | Float64 | `0.0` | yes | per round; buyers' valuation = dividend / (own yield − this) — the resale-expectation term, off by default |
| `greedy_pricing` | Bool | `false` | yes | Greedy firms (13 October, Stef): a firm whose owners are greedy (by share; without owners, a greedy village) prices as high as the market allows — on a sell-out it sets its ask to what buyers will pay (the overpay ceiling), not a step up. |
| `distress_pricing` | Bool | `false` | yes | Distress pricing (13 October, Stef): a firm whose overdue obligations have reached `distress_share` of the winding-up threshold abandons the step limit and sets its price to what would clear them within `distress_months`, cost plus the arrears per unit it expects to sell — the last thing a firm does before it fails. |
| `distress_share` | Float64 | `0.5` | yes |  |
| `distress_months` | Int | `3` | yes |  |
| `distress_cost_cutting` | Bool | `true` | yes | on by default: realistic behaviour (Stef, 14 Oct); a switch for the controls |
| `wage_ceiling_in_breads` | Float64 | `0.0` | yes | incomes policy: no employer pays more than this many loaves per full-time round of work (0 = off); binds bids and the surplus-to-wages rule |
| `fixed_prices` | Bool | `false` | yes | Fixed prices (26 September, Stef's question): every transaction at the starting price vector — no bargaining, no adaptation; only quantities move. Does a village eat when nobody raises a price, and what does the public debt do? |

### Labour — 39 parameters

| parameter | type | default | sweep | meaning |
|---|---|---|---|---|
| `hunger_wage_discount` | Float64 | `0.25` | yes |  |
| `savings_target_in_meals` | Float64 | `3.0` | yes | Savings (persons) |
| `savings_protection_probability` | Float64 | `0.5` | yes |  |
| `offer_full_capacity` | Bool | `false` | yes | persons offer all their capacity instead of the minimum that covers their needs |
| `wage_reservation_net_of_tax` | Bool | `false` | yes | worker's floor nets a meal after wage tax (the price vector was derived this way) |
| `random_hiring_ties` | Bool | `false` | yes | equal asks: random order (default: stable sort ⇒ agent-id order) |
| `no_labour_tolerance` | Bool | `false` | yes | unsold labour units always count as 'partly unsold' (tolerance is for goods) |
| `wage_reservation_net_of_gi` | Bool | `false` | yes | SuMSy: the worker's floor covers only the part of the meal the GI does not |
| `wage_reservation_includes_savings` | Bool | `false` | yes | the worker's floor also covers building the savings buffer (3 meals) over savings_build_rounds |
| `savings_build_rounds` | Int | `10` | yes |  |
| `minimum_member_hours` | Float64 | `0.5` | yes | average units a round below which worker membership lapses |
| `members_first_hiring` | Bool | `true` | yes | worker cooperatives serve their members before the open market, spreading the work over them |
| `wage_threshold` | Bool | `false` | yes | Wages rise only when at least `unmet_demand_share` of the labour employers wanted went unfilled (25 September; false = the old rule, any shortfall raises every sold-out worker's ask — a wage ratchet that ran on with a quarter of the village idle). |
| `wage_cut_maximum` | Float64 | `1.0` | yes | Downward wage rigidity (27 September, Stef): a worker lowers the asking wage by at most this share a month, whatever the rules for other goods say (nominal wages hardly fall) — for a worker in work last month; after a month without work the floor is gone (the unemployed take what they can get). 1.0 = no limit (the rule so far). |
| `wage_floor_months` | Int | `1` | yes | How long the floor outlasts a job (28 September): a worker keeps refusing a cut for this many months after last being paid (1 = only while continuously employed). |
| `joint_labour_market` | Bool | `false` | yes | Loyalty and notice (3 October, Stef). `employer_loyalty`: an employer takes on last month's workers before strangers. `notice_months` > 0: a worker who has worked `notice_tenure_months` or more consecutive months for the same employer cannot simply be dropped — the employer keeps hiring them, at their units of last month, for `notice_months` more months (Belgian law: three months' notice after six months' service). One labour market for bakeries and theatres (16–17 October, Stef): after the grain market, bakeries and theatres hire in turns from one pool, a unit each per pass, so that neither can take the hands the other needs (the theatres had left the bakeries 168 short in the productive village). Farms and banks still hire before the harvest, which must precede the grain market. false = farms, banks and theatres first, bakeries after the grain market. |
| `contracts` | Bool | `false` | yes | Labour contracts (17 October, Stef): a worker who has worked `contract_tenure_months` running for an employer gets a contract if the employer still has room under `contract_share` (the share of its hands it may hold on contract; the rest are temps, always on the market). A contracted worker is off the market: the employer hires them first, at the contract wage, for the contracted units; an employer that wants fewer gives `notice_months` notice and keeps paying; a worker who could earn more elsewhere (the going wage above the contract wage by `worker_leave_margin`) gives `worker_notice_months` notice and leaves. |
| `contract_share` | Float64 | `1.0` | yes |  |
| `contract_tenure_months` | Int | `3` | yes |  |
| `worker_notice_months` | Int | `1` | yes |  |
| `worker_leave_margin` | Float64 | `0.1` | yes |  |
| `contract_indexation` | Float64 | `1.0` | yes | 17 Oct (Stef): the contract is a floor — the employer takes at least the contracted units, the worker's remaining hours go to the market as a temp's; the contract wage follows the price of bread by `contract_indexation` (1 = fully, 0 = not at all); when bread or hands fell short (the emergency), contracts do not hold anyone back. |
| `experience` | Bool | `false` | yes | Experience (17 October, Stef): months worked running for the same kind of enterprise build experience — level 2 after `experience_months[1]`, level 3 after `experience_months[2]` — and every `experience_decay_months` not worked in that kind cost a level. An experienced worker produces `experience_bonus` more per unit and is hired first at equal cost. |
| `experience_months` | Tuple{Int, Int} | `(3, 9)` | no |  |
| `experience_bonus` | Tuple{Float64, Float64} | `(0.1, 0.2)` | no |  |
| `experience_decay_months` | Int | `3` | yes |  |
| `employer_loyalty` | Bool | `false` | yes |  |
| `notice_tenure_months` | Int | `6` | yes |  |
| `notice_months` | Int | `0` | yes |  |
| `food_emergency_share` | Float64 | `0.0` | yes | The food emergency (30 September, Stef): a village does not starve because bakers and workers cannot agree a wage. When last month's bread fell short of what the village needs (below `food_emergency_share` of a meal each), the wage floor is suspended — workers take what keeps the ovens going — and every employer will hire at up to `employer_loss_tolerance` above what a unit of labour brings in (a firm runs a loss for a while rather than close; the liquidation test decides later). |
| `labour_for_bread` | Bool | `false` | yes | Labour for the village's bread (12 October, Stef): when last month's bread fell short, or employers could not fill the hands they wanted, everyone offers all their capacity until the ovens are staffed; while the village is fed, each villager offers what their needs require (and the minimum offer). No village starves for want of hands. |
| `labour_for_bread_memory` | Int | `3` | yes | 15 Oct: the share follows the most employers wanted in the last three months |
| `labour_for_bread_margin` | Float64 | `0.1` | yes | each villager offers at least their share of last month's labour wanted, plus this margin. |
| `employer_loss_tolerance` | Float64 | `0.0` | yes | A price lever as much as a labour one (review 7): at 0 the market is tight every month and the SuMSy village inflates ~4–5 %/yr; at 0.1 it deflates ~9 %/yr. Report prices with the margin stated. |
| `standard_of_living_tickets` | Int | `0` | yes | A standard of living (27 September, Stef): the tickets a month a household aims for — it offers labour to afford them and buys up to that many. 0 = the rule so far (work for a meal and the cushion; one to `max_tickets_per_person` tickets when there is spare cash). |
| `minimum_labour_offer` | Float64 | `0.0` | yes | Work as purpose (4 October, Stef; docs/future_work/design_work_as_purpose_2026-10-04.md). `minimum_labour_offer`: everyone offers at least this share of their capacity for paid work, whatever their needs. `volunteer_share`: the share of labour offered and not hired that a villager gives, unpaid, to the commons — a measure (volunteer hours), not a market: the idle split into volunteers and the truly idle. |
| `volunteer_share` | Float64 | `0.0` | yes |  |
| `volunteers_in_theatres` | Bool | `false` | yes | Volunteers in the theatres (4 October, Stef): a theatre hires what its tickets can pay and villagers with unhired labour staff the rest, unpaid — after the paid hiring, never instead of it. The volunteers' hours count as commons hours. |
| `volunteer_kinds` | Tuple{Vararg{Symbol}} | `()` | no | Volunteer work as a structural flag (15 October, Stef): the enterprise kinds whose shortfall of hands volunteers may fill, after the paid hiring (e.g. (:theatre,), (:bakery,)). `volunteers_in_theatres` = true adds :theatre. |

### Firms, planning, ownership and entry — 73 parameters

| parameter | type | default | sweep | meaning |
|---|---|---|---|---|
| `reserve_target_in_rounds` | Float64 | `3.0` | yes | standard reserve = rounds × expected input cost |
| `reserve_protection_probability` | Float64 | `0.5` | yes | enterprises: borrow first (v1 savings rule) vs use own cash first            # wages absorb surplus once reserves reach this multiple |
| `planning_margin` | Float64 | `0.0` | yes | extra share of demand planned for (0.0 = plan exactly the population's meals) |
| `plan_greedy_on_purchases` | Bool | `false` | yes | 14 October (the greedy village's bakeries): plan greedy demand on last month's greedy purchases, not on the greedy villagers' cash; and never target more grain than the ovens can bake — `bakery_capacity_share` of the village's labour, spread over the bakeries, a unit of labour baking one grain (0.5: half the village's hands at full strength — 3,072 loaves a month at 512 villagers; it binds only where a planner runs away, as in the greedy village). |
| `plan_within_capacity` | Bool | `false` | yes |  |
| `bakery_capacity_share` | Float64 | `0.5` | yes |  |
| `plan_for_gluttony` | Bool | `false` | yes | plan for the expected third loaves too (otherwise gluttony is a pure demand shock) |
| `startup_loan_term` | Int | `50` | yes | :debt — enterprises borrow the endowment (own reserve + the persons' share) and pay it out |
| `startup_loan_rate` | Float64 | `0.005` | yes |  |
| `plan_for_tickets` | Bool | `true` | yes | theatres plan hiring on expected ticket demand (like bakeries on gluttony) |
| `ownership` | Symbol | `:none` | list | :none \| :cooperative (every person holds an equal share of every producer) \| :shareholders (a few persons hold all shares) \| :mixed (cooperative_* producers are co-ops, the rest shareholder-owned) |
| `shareholder_count` | Int | `2` | yes | :shareholders / :mixed — persons (lowest ids) who hold the shares |
| `cooperative_farms` | Int | `2` | yes | :mixed |
| `cooperative_bakeries` | Int | `2` | yes |  |
| `cooperative_theatres` | Int | `0` | yes | :mixed — theatres were for-profit only until 14 September 2026 |
| `cooperative_form_farms` | Symbol | `:member` | list | Cooperative forms (14 September 2026), per kind: :member (the original equal-share, equal-dividend rule), :worker (membership follows employment, surplus by hours) or :consumer (membership follows purchases, surplus as a patronage rebate). Farms cannot be consumer cooperatives: they sell to bakeries, not to persons. |
| `cooperative_form_bakeries` | Symbol | `:member` | list |  |
| `cooperative_form_theatres` | Symbol | `:member` | list |  |
| `patronage_window` | Int | `12` | yes | rounds of hours or purchases a distribution is measured over |
| `retained_surplus_share` | Float64 | `0.25` | yes | share of every distribution locked in the indivisible reserve |
| `capital_deduction_share` | Float64 | `0.10` | yes | worker cooperative: share of each net wage collected towards the membership share |
| `membership_lapse_rounds_worker` | Int | `6` | yes | grace period before a member without hours is redeemed |
| `membership_lapse_rounds_consumer` | Int | `12` | yes | grace period before a member without purchases is redeemed |
| `member_price_awareness` | Bool | `true` | yes | consumer cooperative members net the expected rebate off the ask when choosing a seller |
| `membership_contribution` | Symbol | `:money` | list | :money \| :buffer \| :mixed_fixed (both) \| :mixed_flexible (the member splits a single total) |
| `membership_buffer_pledge` | Float64 | `10.0` | yes | buffer requirement, in currency units of exemption |
| `cooperative_founding` | Symbol | `:par_only` | list | :par_only (members bring one share at par) \| :symmetric (members are called on for capital like shareholder founders) |
| `dividend_build_rounds` | Int | `10` | yes | cash above the reserve target is paid out over this many rounds |
| `share_market` | Bool | `false` | yes | shareholder enterprises' shares trade once a round |
| `shares_per_person` | Int | `0` | yes | share units per firm = this × number of persons (0 = 100 units per firm), so every villager could hold shares |
| `startup_financing` | Symbol | `:enterprise_loans` | list | :enterprise_loans (businesses borrow their own start) \| :paid_in_capital (owned businesses start empty; founders borrow personally and pay capital in; co-ops raise membership capital) |
| `membership_share_price` | Float64 | `10.0` | yes | a cooperative share, at par (one meal at initial prices) |
| `cooperative_join_probability` | Float64 | `0.5` | yes | a person with surplus who is not yet a member joins one cooperative a round with this probability |
| `required_yield` | Float64 | `0.01` | yes | base required dividend yield per round; a person's own yield is drawn once around it |
| `required_yield_dispersion` | Float64 | `0.0` | yes | half-width of the per-person spread (0 = everyone values a firm alike → no voluntary trades) |
| `share_step` | Float64 | `0.05` | yes | ask/bid adaptation per round (distress asks) |
| `forward_valuation` | Bool | `false` | yes | value a firm by its expected dividends after its loans are repaid, not by trailing dividends and book |
| `founder_minimum_stake` | Float64 | `0.51` | yes | founders together keep at least this fraction of each firm |
| `arrears_de_minimis_in_meals` | Float64 | `0.01` | yes | a shortfall smaller than this share of a meal is not a missed payment |
| `closure_debt_threshold_in_breads` | Float64 | `1.0` | yes | an enterprise with nothing left to seize is closed only if the uncovered debt exceeds this |
| `settlement` | Symbol | `:clearing_all` | list | :invoicing \| :clearing_all (see above) |
| `settlement_clearing` | Vector{Symbol} | `[:bank, :government]` | no |  |
| `settlement_invoicing` | Vector{Symbol} | `[:farm, :bakery, :theatre, :government]` | no |  |
| `liquidation_test` | Symbol | `:cash_flow` | list | The liquidation test (23 September, closest to Belgian insolvency law: persistent non-payment *and* shaken credit): :cash_flow — overdue obligations (invoices and loan instalments, each at least `liquidation_overdue_rounds` behind) reach `liquidation_arrears_share` of the firm's monthly turnover, *and* a loan to pay them is refused; :book      — the 22 September rule: overdue invoices reach that share of book value (fires on any overdue once book ≤ 0). |
| `founding_equity` | Bool | `false` | yes | Founders pay in equity at the founding equal to the firm's working reserve, from savings or a personal loan (23 Sept; a Belgian BV must start with sufficient equity). false = the old rule: firms start empty and call on founders when short. |
| `founders` | Symbol | `:shared` | list | Who founds the firms (24 September): :shared = the old rule, the same `shareholder_count` villagers found every firm (at 512 villagers: 4 owners of all twelve firms); :distinct = every firm has its own founders, taken in order of id, wrapping round when there are more founder places than villagers (at 512 with twelve firms: 48 owners, 9 %). |
| `stop_without_producers` | Bool | `true` | yes | The run stops when no farm or no bakery is left (the old rule); false = the village runs on, and starves or recovers (review 5). |
| `community_theatres` | Int | `0` | yes | A volunteer-run community theatre (15 October, Stef): the first `community_theatres` theatres hire nobody; volunteers staff them, and their seats sell at `community_ticket_in_breads` loaves — competing with the paid theatres. |
| `community_ticket_in_breads` | Float64 | `0.25` | yes |  |
| `firms_plan_on_sales` | Bool | `false` | yes | on the ladder (RULES); off by default so the reference runs stay as they were |
| `plan_adjustment_months` | Int | `3` | yes | 16 Oct (Stef): a large change in a firm's sales share is followed mildly at first and fully only when it holds — a third of the way in its first month, two thirds in its second, all of it from the third (`plan_adjustment_months`); changes within `plan_small_change` of the current share are followed at once. |
| `plan_small_change` | Float64 | `0.05` | yes |  |
| `plan_share_floor` | Float64 | `0.0` | yes | 19 Oct: no firm's planned share falls below this fraction of an equal share (0.25: a quarter of 1/n) — with contracts on the base, a firm whose share shrank kept paying its contracted hands through the notice, borrowed, was closed for uncovered debt, and its workers went to the winner: every kind collapsed to one firm (step 8, both moneys), and the greedy SuMSy villages starved on one farm. 0 = no floor. |
| `own_market_planning` | Bool | `false` | yes | Own-market planning (19 October, Stef): each firm plans on its own market — next month's target follows what it sold, at the gradual pace above (a third, two thirds, all); a firm that sold out plans `plan_step` more; nothing is handed down from a village plan. The village plan survives only as the **emergency rule**: when bread was short for want of production (the bakeries baked less than the village's meals and people went hungry — hunger for want of money is an outcome, not an emergency), the village's need is planned and split equally among the bakeries, as a government steps in; it stays in force until the village has baked enough for `intervention_exit_months` months running. The first two months plan on the village's need (no sales yet). |
| `plan_step` | Float64 | `0.1` | yes |  |
| `intervention_exit_months` | Int | `2` | yes |  |
| `premium_markup` | Float64 | `1.0` | yes | A premium loaf (11 October, Stef): value that grows without volume growing. A villager with money to spare beyond the cushion and `premium_buyer_margin_in_meals` meals buys the month's bread premium instead of plain — the same loaves at `premium_markup` times the price, no more time to eat them; the bakery hires `premium_labour_per_loaf` extra units at the going wage for each. 1.0 = no premium loaf. |
| `premium_labour_per_loaf` | Float64 | `0.5` | yes |  |
| `premium_buyer_margin_in_meals` | Float64 | `2.0` | yes |  |
| `refound_minimum` | Int | `1` | yes | When fewer than this many farms (or bakeries) are open, villagers try to start one (24 September; 0 = never). |
| `refound_cooldown` | Int | `3` | yes | at most one restart per kind in this many months (a village that cannot sustain a firm would otherwise restart one every month) |
| `market_entry` | Bool | `false` | yes | Market entry (25 September; docs/designs_implemented/design_market_entry_2026-09-25.md): off by default and on the ladder. A new farm, bakery or theatre is founded when its market has had at least `entry_unmet_share` unserved demand in each of the last `entry_unmet_months` months, or its firms have averaged an operating margin above `entry_margin` over the last `entry_margin_months` months — at most one per kind per `entry_cooldown` months and up to `entry_max_ratio` × the starting number. Founders are the villagers with the most spare cash (founding rules); the firm is a cooperative with probability `entry_coop_share`. |
| `entry_unmet_share` | Float64 | `0.05` | yes |  |
| `entry_unmet_months` | Int | `3` | yes |  |
| `entry_margin` | Float64 | `0.20` | yes |  |
| `entry_margin_months` | Int | `6` | yes |  |
| `entry_cooldown` | Int | `3` | yes |  |
| `entry_max_ratio` | Float64 | `2.0` | yes |  |
| `entry_coop_share` | Float64 | `0.0` | yes |  |
| `liquidation_arrears_share` | Float64 | `0.10` | yes |  |
| `liquidation_overdue_rounds` | Int | `3` | yes |  |
| `liquidation_price_share` | Float64 | `0.90` | yes |  |
| `liquidated_coop_stays_coop` | Bool | `false` | yes | true: a cooperative is refounded by its members, one share at par each |

### Land and gold — 19 parameters

| parameter | type | default | sweep | meaning |
|---|---|---|---|---|
| `land_price_rent_multiple` | Float64 | `15.0` | yes |  |
| `land_units_per_landowner_override` | Int | `0` | yes | 0 = spec formula floor((n − p)/(p − 1)) |
| `land_levy_dividend` | Bool | `false` | yes |  |
| `levy_pass_through` | Bool | `false` | yes | Gesell's objection to George (15 October; 16 Oct: on the asked rent, not as a refusal — a hard floor let no land and starved the village in month 2): when true, a landowner asks the levy on top of the going rent; tenants' bids decide whether it sticks. |
| `land_loans` | Bool | `false` | yes | land may be bought on credit (collateral: the land itself, seized after 2 rounds of arrears) |
| `land_sales` | Symbol | `:forced` | list | :forced (spec: any buyer with surplus takes a unit) \| :distress_only \| :reservation (seller sells only above the value of the rent stream) |
| `land_reservation_multiple` | Float64 | `100.0` | yes | :reservation, debt money: rounds of rent a landowner wants for a unit; SuMSy uses rent / demurrage_rate |
| `land_pricing` | Symbol | `:multiple` | list | The land market (24 September). :multiple = the old rule, price = `land_price_rent_multiple` × rent. :market = the price is discovered: it starts at `land_price_rent_multiple` × rent and moves by `land_price_step` when at least `unmet_demand_share` of the demand went unserved (up) or at least `unsold_share` of the land offered went unsold (down). Sellers and buyers value land by the money logic: a unit is worth its rent divided by the monthly rate at which money is held (debt: deposit interest and loyalty bonus; SuMSy: the parking fee and parking tax) or borrowed (debt: the bank's rate). |
| `land_price_step` | Float64 | `0.06` | yes |  |
| `land_life_event_rate` | Float64 | `0.005` | yes | Landowners who sell for reasons of their own (an inheritance, a move) — the monthly probability that a landowner offers a unit at the best bid (25 September). Such sales count for the valuation price; distress sales do not. |
| `land_levy` | Bool | `false` | yes | A levy on land (24 September; Gesell's Freiland as a variant): each month landholders pay `land_levy_rate` × the value of their land to the government. With `land_levy = true` the rate is the cost of holding money (parking fee + parking tax, 0 under debt money) plus `land_levy_margin` — land is then worth its rent over that margin, as a debt village values it over its deposit rate. Without a levy, under SuMSy, land always beats money that loses value, and nobody sells it voluntarily. |
| `land_levy_margin` | Float64 | `0.0025` | yes |  |
| `land_levy_rate` | Float64 | `0.0` | yes | A levy on land holdings (24 September, the Freiland variant): each month every landholder pays `land_levy_rate` × the value of its land at the current price, to the government (a land-value tax). Land is worth rent ÷ (levy − what money earns); under SuMSy money earns minus the parking fee, so without a levy land beats money at any price, and with a levy equal to the parking fee it still does — the levy must exceed the parking fee for land to have a finite price. |
| `gold_grams_per_villager` | Float64 | `0.0` | yes | Gold (5 October, Stef): a fixed stock of `gold_grams_per_villager` × villagers, held at the founding by the richest `gold_initial_holders_share`; a pure store of value (no yield, no fee, no spoilage), traded on a market like land's: a villager with money to spare beyond `gold_buyer_margin_in_meals` meals buys a gram a month when it is within reach; a holder sells when short of cash or, with probability `gold_sale_rate` a month, for reasons of their own; the price moves `gold_price_step` on unserved demand or unsold offers, within what buyers can pay; valued at the median of the last twelve months' trades. |
| `gold_initial_holders_share` | Float64 | `0.10` | yes |  |
| `gold_initial_price_in_breads` | Float64 | `10.0` | yes |  |
| `gold_buyer_margin_in_meals` | Float64 | `2.0` | yes |  |
| `gold_sale_rate` | Float64 | `0.01` | yes |  |
| `gold_price_step` | Float64 | `0.06` | yes |  |

### Behaviour variants — 12 parameters

| parameter | type | default | sweep | meaning |
|---|---|---|---|---|
| `greed` | Bool | `false` | yes | Greed (13 September 2026): a property of persons, above their own reserve |
| `greed_share` | Float64 | `0.25` | yes | share of persons who are greedy |
| `cash_hoarder_share` | Float64 | `0.0` | yes | Cash hoarders (15 October, Stef): `cash_hoarder_share` of villagers (chosen like the greedy, by `greed_selection`) keep every surplus as money — they buy their bread and nothing else: no tickets, land, shares, gold or premium loaves, and lend nothing. |
| `cash_hoarder_month` | Int | `0` | yes | 15 Oct: when > 0, the hoarders are chosen at this month among those holding the most money (whoever the economy has made cash-rich), not at the founding — the richest at the founding are land-rich, cash-poor founders with loans to repay. |
| `greed_hoarding` | Float64 | `0.5` | yes | every greedy person is both: each act of greed goes to capital with this probability (most profitable of land, shares, cash first), to consumption (a loaf or a ticket, coin flip) otherwise |
| `greed_selection` | Symbol | `:rich` | list | :rich (the wealthiest at the founding) \| :random |
| `greed_month` | Int | `0` | yes | 15 Oct (Stef): > 0 — the greedy are chosen at this month, by net wealth (:rich) or at random, once a trend shows |
| `greedy_max_breads_per_round` | Int | `10` | yes | replaces the 3-loaf ceiling for greedy consumers (eaten, not stocked) |
| `spoilage_acceptance` | Float64 | `NaN (unset: see meaning)` | yes | Spoilage acceptance (13 October, Stef): nobody buys bread they know will rot. A greedy villager holds at most what they can eat before it spoils (breads_per_meal × spoilage_age_in_rounds) plus this share of waste: 0.1 = a tenth more, 3.0 = four times. NaN = the old cap of `greedy_max_breads_per_round`. |
| `greedy_max_tickets_per_round` | Int | `10` | yes | replaces the 3-ticket ceiling |
| `nonworking_share` | Float64 | `0.0` | yes | Not working, for reasons of their own (5 October, Stef — care, illness, art, or choice; the model knows only that they do not offer paid work): `nonworking_share` of villagers offer labour only to cover a meal — no cushion, no tickets, no minimum offer — and give no volunteer hours; `nonworking_hungry_share` of them would rather go hungry than take paid work: they offer labour only once hungry. |
| `nonworking_hungry_share` | Float64 | `1 / 3` | yes |  |

### Run control — 7 parameters

| parameter | type | default | sweep | meaning |
|---|---|---|---|---|
| `stop_when_half_dead` | Bool | `true` | yes |  |
| `stop_when_stationary` | Bool | `true` | yes |  |
| `random_streams` | Bool | `true` | yes | one random stream per subsystem (18 September 2026), each seeded from `seed`; false = the single shared stream of earlier runs |
| `maximum_rounds` | Int | `50` | yes |  |
| `stationary_rounds` | Int | `5` | yes |  |
| `stationary_tolerance` | Float64 | `0.01` | yes |  |
| `seed` | Int | `1` | yes |  |

## 6. Validation and consistency rules

- A parameter is editable only when its governing switch (§4) is on; a sweep over a disabled parameter is refused.
- `monetary_system = :sumsy` with `wage_tax_rate`, `capital_tax_rate` or `dividend_tax_rate` > 0 is refused unless the configuration is named "(comparison)": SuMSy never taxes income.
- `unmet_demand_share`, `unsold_share` ∈ [0, 1]; `bread_bid_base_multiplier` ≥ 1; `employer_wage_margin` ≥ 0 (values below 0.2 deadlock the labour market when prices fall — warn); `wage_cut_maximum` ∈ (0, 1]; `wage_floor_months` ≥ 1.
- `ticket_max_in_breads` must exceed the ticket price in loaves of the configuration (else no ticket ever sells — warn).
- `public_project_build_months` ≤ `maximum_rounds` − 12 (else no revenue is ever seen — warn).
- `austerity_start` ≤ `maximum_rounds`; `austerity_fee_in_breads` ≤ `unemployment_fee_in_breads`.
- `gold_initial_holders_share` ∈ (0, 1]; `nonworking_share` + `greed_share` ≤ 1.
- `land_levy` requires `land_pricing = :market`; the dividend (`surplus_redistribution_share` > 0) requires the reserve rule.
- `notice_months` > 0 without `employer_loyalty` is allowed but warned: without continuity of employment the notice rule never fires.
- Seeds: 1 to 50; rounds: 12 to 600.
- 16 Oct: `basic_income` > 0 with `monetary_system = :sumsy` is refused (the SuMSy income is `guaranteed_income`). `land_levy_dividend` requires `land_levy`. `levy_pass_through` requires `land_levy`. `community_theatres` ≤ `number_of_theatres`. `income_cut_share` ∈ [0, 1]; `income_cut_start` ≤ `maximum_rounds`. `cash_hoarder_share` + `greed_share` + `nonworking_share` ≤ 1. `greed_month`, `cash_hoarder_month` < `maximum_rounds`. `plan_adjustment_months` ≥ 1.
- 18 Oct: `public_land` with `land_levy` or `land_pricing = :market` is refused (an ArgumentError in the model). `contract_share`, `contract_indexation` ∈ [0, 1]; `contract_tenure_months`, `worker_notice_months` ≥ 1; `experience_months` increasing; `experience_bonus` ≥ 0. `public_land_dwelling_exempt_benefit` and `public_land_dwelling_in_benefit` are alternatives.
- 19 Oct: `own_market_planning` and `firms_plan_on_sales` are alternatives (own-market planning wins); `plan_step` ≥ 0; `intervention_exit_months` ≥ 1; `refound_minimum` ≥ 2 wherever there is a market in that kind (one firm is a monopoly the model's prices are not built for).
- Warnings: `firms_plan_on_sales` without `plan_within_capacity` lets one bakery be planned beyond its ovens; `public_debt_limit` with `basic_income` cuts the income when it binds (EU8); `fixed_prices` with `distress_pricing` makes the latter inert.


## 7. Run tab

Village size and seeds, months, the compare toggle, and the **ladder preset picker**: every step of `scripts/ladder_definition.jl` (130 steps and 215 village configurations as of 19 October) is a preset, shown with its one-line description and the parameters it sets above the base. Choosing a step fills both sides (a side the step leaves empty is not run). The Run tab also shows the batch's memory plan: workers are replaced every `WORKER_RECYCLE` jobs (a model process retains memory across runs) and start with a heap-size hint; a long series on many workers says how much memory it will need at its peak. A **diff** view shows what the current configuration differs in from the chosen step. Run, cancel, progress, estimated time. The model version (`MODEL_VERSION`: the date the version was made, then .0, .1, …) is shown with every run; results from another version are never mixed in. The test suite runs once per version and code (a fingerprinted marker), and the Run tab shows whether it has. A **variant ladder** runs every step again with one parameter changed (`CONTRACT_SHARE`, the contracts dial — the base is 0.8 since 19 October, so the variant serves for 1.0 or 0.5) into its own folder and summary; the dashboard offers the variant as a toggle and shows the two ladders side by side.

## 8. Series tab (sweeps, ladders and batches)

A sweep is a preset (or the current configuration) plus up to three **dimensions**, each a parameter with a list of values (numeric: a list or a range with a step; Boolean: both; Symbol: a list of options). The sweep runs the Cartesian product, each cell with the chosen seeds, on both sides if compare is on. Dimensions must pass §6 for every value. The sweeps the ladder already carries are offered as templates: the overpay dial (1.1, 1.2, 1.3, 2.0), the wage floor (1, 3 months), the employer margin (0.05, 0.2, 0.25), the parking fee with matching starting prices (2, 3, 4 %), public employment (10–50 %), the debt ceiling (0.5, 1.0 × output), the levy margin, the benefit (0, 1, 2 loaves), the gold stock. A sweep's results open in the Results tab as a grid with one chosen measure per cell, and any cell opens as a full run. Templates added since 5 October: the sharing margin (M0: 0, 5, 10, 20 %), the labour rules (Y8: floor three months, no loyalty, no notice), the spoilage acceptance and the overpay ceiling on the greedy village (S3-SP, S3-W), the debt-money twins (DGI8, DD8, DDL8, DDGL8 at 1.5 and 3.5 %), the debt ceiling with a basic income (EU8, D8-60), the income reversed (RV8), cash hoarders at 1 and 10 % (HC8), the levy passed on (LPT8, DDL8-PT), fixed against free prices (V8/V8-P, U8/U8-P, UP8/UP8-P), the contracts dial (NJ8, J8-50, the 0.8 ladder), experience (XP8, XPN8), public land and its dwelling rent (PL8, PL8-0, PL8-X, PL8-B).


## 9. Results tab

Grouped like the parameter tabs, so that each part of the model has its own panel, each with the ten-run mean, the worst run, and the single-run detail on demand:

- **Village**: alive, hungry, bread baked and sold, prices (bread, grain, wage, ticket, rent), unemployment and its split (volunteers, truly idle, not working by choice, the not-working), capacity offered and worked.
- **Money**: the money stock, loans, peer loans, write-offs, bailouts, the money identity gap (must be zero), the bank rate, deposit interest paid, the capital reserve.
- **Government**: taxes by family and their scales, the demurrage tax under debt money, the basic income paid, the levy dividend, outlays by kind (jobs, benefit, project, coupons, interest), public debt and its course (peak, month repaid), bonds, the reserve, the dividend paid out, the levy, the spending scale under a ceiling, the project's cost and revenue and rides.
- **Prices**: the price paths, inflation a year, the quoted and traded land price, the gold price and valuation.
- **Labour**: wages, the floor's incidence, notices given, tenure, labour wanted and unfilled, the sharing floor, volunteer hours (and volunteer staffing by enterprise kind), the commons.
- **Firms**: firms open by kind and form, liquidations (with their reason and what the overdue invoices were for), restarts, entries, margins, each firm's planned share and its trend, distress prices set and cuts made, the Herfindahl index of bread, owners, dividends, premium loaves.
- **Land and gold**: land held by households, sales (voluntary, distress, life-event), the levy; gold holders, grams by decile, grams traded, what the gold would fetch in meals (beside wealth, not in it).
- **Distribution**: the rich–poor gap in meals with the poorest tenth's own holding beside it, the Ginis (cash, net wealth, net wealth with ownerless firms' equity attributed), under water, without cash, the top 1 %'s share.
- **Ladder view**: any measure across all chosen steps, both villages side by side, as the report's panels.

Every panel's data is downloadable as CSV with the run's parameter set attached.
- **Behaviour**: the greedy (when chosen, how many), cash hoarders and the money they hold, those not working, greedy loaves.
- **Labour contracts and experience**: contracted workers, contracts given and ended (by whom), notices both ways, experienced workers by level.
- **Planning and intervention**: each firm's target and its trend; the months under the emergency rule, when it began and ended, and why (bread baked against the village's need); hunger split into want of production and want of money.
- **Firms**: closures by route (wound up, sold as a going concern, closed for uncovered debt, restarted at the minimum).
- **Distributions** (every measure): the median, the quartiles and the 5th–95th band over the seeds, beside the mean; the paired comparison of the two moneys seed by seed (how many pairs each way, the Wilcoxon test, corrected over the cells compared).
- **Public land**: ground rents by payer, the plots allotted.


## 10. Presets

The ladder's steps (§7) and the named villages of the report: the best debt village, the productive village (V8), the levy-and-dividend village (SuMSy from step 8), the fixed-price twins (P), the stress tests (S), the full-money-stock starts (E). Presets are versioned with the model; a preset saved under an older version is flagged. Added: the debt village with SuMSy's arrangement (DDGL8), the euro-rule village (EU8), public land (PL8), the village without contracts (NJ8).

## 11. The result as a picture (Basic view, the game)

The Basic view answers one question first: **who is alive after ten years, and how do they live** — the two villages side by side as 512 dots that die out as the months run, with the four numbers the report leads with underneath (alive, out of work, the price of bread, the government's debt) and the rich–poor gap in meals with the poorest tenth's holding. Then the same for the ten seeds (the band). A player can stop the clock at any month and look at that month's village (the "what is there" panels of the report). A **score** for the game, if one is wanted, is the report's own measure in a different dress: everyone fed, nobody idle, nothing owed, the poorest tenth holding a month of meals — four ticks, shown as such, never summed into one number.

## 12. Tutorial and tooltips

**The tutorial** opens the first time and can be skipped at once and reopened from the help menu. Six steps, each a sentence and a click: (1) the village and its people; (2) the two moneys, in one paragraph each; (3) run the village as it is and watch who lives; (4) change one lever (the tutorial suggests the benefit) and run again; (5) read the result: alive, work, bread, debt, the gap; (6) save the configuration and add it to a series. Each step highlights the control it talks about. The tutorial runs on the Basic view; Policy and Expert get a shorter one about tabs, switches, presets and sweeps.

**Tooltips in two registers.** Every parameter has a tooltip; the register follows the view, and either can be switched to from the tooltip itself.
- **Plain** (Basic and Policy): what the lever is in the village, in the words of the report, one or two sentences; what turning it up or down tends to do, with the ladder's own numbers where there are any; the default and the ladder's range. No model names. Example, `unemployment_fee_in_breads`: *"What the village pays someone without work each month, counted in loaves. The debt village pays two, the SuMSy village one on top of its income. Two loaves keeps the unemployed alive and is borrowed every month; less than two and people starve (the austerity village lost forty-three more)."*
- **Expert**: the parameter's name, type, default and range; the mechanism it enters (which rule, which step of the month); its interactions (which switch governs it, what it excludes); the cells of the ladder that vary it. Example, the same parameter: *"`unemployment_fee_in_breads` (Float64, 2.0 debt / 1.0 SuMSy). Promised by the government to each unemployed villager at step C (priority 2) as fee × expected bread price × spending_scale; scaled by a debt ceiling (`public_debt_limit`) and by `austerity_*`; under SuMSy paid on top of the guaranteed income; see A8, D8, I8 (the benefit fixed in money)."*
- **Where the text comes from.** The expert text is generated from `src/parameters.jl` (the comments beside each parameter, kept in that register) by `scripts/dashboard_tables.py`, which already produces §5. The plain text is written by hand, lever by lever, starting with the Basic view's twenty-five and the Policy view's sixty; the rest show the expert text in both registers until written. The report's glossary is the source for the plain register's vocabulary.
- **Two rules for the plain register.** A tooltip states what the model does, never what the reader should want; and where the ladder has a number, the tooltip gives it, so that a player's expectations are set by the village's own history rather than by intuition.

## 13. Change log

- 18 September 2026 — first version (cooperative forms, membership contribution, random streams).
- 5 October 2026 — version 2: regrouped into tabs with switches and sweeps; all parameters added since 18 September: settlement by invoicing and the cash-flow liquidation test; founding equity and distinct founders; the protected minimum; the land market (price discovery, best-bid sales, valuation from comparable sales, the levy and dividend); the wage rules (threshold, floor, memory, emergency, loss tolerance, employer margin, loyalty, notice); fixed prices; the standard of living; the minimum offer and volunteer hours; those not working for reasons of their own; gold; the benefit's indexation and austerity; the debt ceiling; the owners' guarantee; interest from equity and the capital requirement; the bank rate following inflation; restarts; entry; the tax-scale floor; the public investment; the bond coupon; stopping rules.
- 16 October 2026 — version 3: 328 parameters (29 added since 5 October); the tables generated by `scripts/dashboard_tables.py`; switches, validation rules, sweep templates and results added for the labour-for-bread rule, the debt-money twins (demurrage tax on debt money, basic income, levy dividend, income cut), the euro debt rule, pricing under greed and distress, cost cutting, gradual planning on sales, the premium loaf, cash hoarders, greed chosen later, volunteers on any enterprise, community theatres, Gesell's pass-through; the version scheme and the once-per-version test suite.
- 18 October 2026 — version 4: 345 parameters (17 added since 16 October): the joint labour market, contracts (on the base, with the dial and the 0.8 variant ladder), experience, public land and the dwelling-rent policies; the variant ladder in the Run tab.
- 18 October 2026 — version 5: the purpose widened (researcher, policy maker, player); configurations (a parameter set per side over a shared base), series (named batches, the ladder as the shipped one), three views (Basic, Policy, Expert), the result as a picture and a four-tick score, the tutorial, tooltips in two registers with their sources.
- 18 October 2026 — version 5.1: storage in DuckDB (Julia client), the tables, sharing by object and separately for parameters (or a subset) and results, the public gallery.
- 18 October 2026 — version 5.2: the village's size and the run's length settable in every view (years, villagers, land, the minimum and maximum of each kind of firm), with a calibrated runtime estimate and a warning on long runs.
- 18 October 2026 — version 5.3: those not working (`nonworking_share`, `nonworking_hungry_share`) listed under the behaviour variants, where they belong, with their meaning.
- 18 October 2026 — version 5.4: the meaning column no longer cut at 170 characters; a `NaN` default is marked as unset with its meaning in the comment.
- 19 October 2026 — version 6: own-market planning with the emergency rule (want of production only), the firm minimum, contracts at 0.8 on the base and the dial's ends as cells; the memory plan in the Run tab; distributions and paired comparisons in the results; 349 parameters.
