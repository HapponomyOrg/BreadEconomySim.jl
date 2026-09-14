"""
    SimulationParameters

All named parameters of the v2 bread economy (specification v2, 11 September 2026).
"""
Base.@kwdef struct SimulationParameters
    # Agents
    number_of_banks::Int = 2
    number_of_farms::Int = 3
    number_of_bakeries::Int = 3
    number_of_persons::Int = 16
    number_of_landowners::Int = 2

    # Capacity, food and death
    maximum_capacity::Float64 = 3.0
    capacity_recovery_per_round::Float64 = 2.0
    half_meal_capacity_fraction::Float64 = 2 / 3
    rounds_without_food_until_death::Int = 3
    breads_per_grain::Int = 2
    breads_per_meal::Int = 2
    initial_breads_per_person::Float64 = 2.0          # bootstrap: everyone starts with one meal in stock
    maximum_breads_per_round::Int = 3                   # gluttony: up to this many breads eaten in a round
    gluttony_probability::Float64 = 0.10                # chance a person who can pay cash eats a third bread
    stocking_marginality::Vector{Tuple{Int, Float64}} = [(3, 1.0), (4, 0.5), (5, 0.3), (7, 0.15)]  # after gluttony: chance of one more bread while stock < units

    # Goods
    spoilage_age_in_rounds::Int = 3

    # Prices and negotiation
    initial_prices::Dict{Symbol, Float64} = Dict(:bread => 5.0, :grain => 5.2, :rent => 0.75, :wage => 3.92, :ticket => 2.0)   # static-consistent vector, see HANDOFF
    land_price_rent_multiple::Float64 = 15.0
    negotiation_steps::Int = 6
    minimum_concession_fraction::Float64 = 0.25
    maximum_concession_fraction::Float64 = 0.40
    ask_increase_after_sellout::Float64 = 0.06
    ask_decrease_after_partial_sale::Float64 = 0.06
    unsold_tolerance_units::Float64 = 2.0                             # unsold ≤ this (one grain-unit of bread) is not 'partly unsold'
    ask_decrease_when_idle::Vector{Float64} = [0.15, 0.30, 0.45]      # desperation: consecutive idle rounds
    bid_decrease_after_success::Float64 = 0.03
    bid_increase_when_starved::Vector{Float64} = [0.06, 0.12, 0.25]   # consecutive rounds of missing out
    bread_price_ageing_discount::Float64 = 0.40
    hunger_wage_discount::Float64 = 0.25
    farm_maximum_rent_fraction_of_grain_price::Float64 = 0.6
    bakery_grain_wage_fraction::Float64 = 0.5
    bread_bid_base_multiplier::Float64 = 1.3
    bread_bid_hunger_multiplier::Float64 = 0.4
    initial_production_target::Int = 6

    # Enterprises
    reserve_target_in_rounds::Float64 = 3.0            # standard reserve = rounds × expected input cost
    surplus_reserve_multiple::Float64 = 2.0
    reserve_protection_probability::Float64 = 0.5      # enterprises: borrow first (v1 savings rule) vs use own cash first            # wages absorb surplus once reserves reach this multiple

    # Credit
    loan_term_in_rounds::Int = 20
    affordability_ratio::Float64 = 0.8
    initial_interest_rate::Float64 = 0.05
    interbank_rate_discount::Float64 = 0.5             # bank-to-bank loans at discount × lender's rate
    government_rate_discount::Float64 = 0.5
    arrears_rounds_until_seizure::Int = 2
    garnishment_rate::Float64 = 0.25

    # Savings (persons)
    savings_target_in_meals::Float64 = 3.0
    savings_protection_probability::Float64 = 0.5

    # Government
    wage_tax_rate::Float64 = 0.15
    capital_tax_rate::Float64 = 0.15
    government_employment_share::Float64 = 0.10        # of total person capacity
    government_wage_in_breads::Float64 = 2.0
    government_wage_premium::Float64 = 0.10            # net wage for full-time = breads × (1 + premium)
    unemployment_fee_in_breads::Float64 = 2.0
    minimum_fee_in_breads::Float64 = 1.0
    fee_reduction_interval::Int = 3
    fee_reduction_rate::Float64 = 0.10
    employment_rounds_to_reset_fee::Int = 3

    # Variants
    debt_dies_with_bank::Bool = false
    # Behavioural rules (viability study, 12 September 2026) — all off reproduces spec v2
    demand_based_targets::Bool = false          # producers plan output for the living population instead of the ±1 ratchet
    planning_margin::Float64 = 0.0              # extra share of demand planned for (0.0 = plan exactly the population's meals)
    plan_for_gluttony::Bool = false             # plan for the expected third loaves too (otherwise gluttony is a pure demand shock)
    wage_ceiling_from_own_ask::Bool = false     # employer's maximum wage from the price it will ask for its output, not the market average
    expected_price_from_asks::Bool = false      # when a good was not traded, expected price = mean posted ask (no frozen prices)
    ask_increase_only_on_unmet_demand::Bool = false   # sellers raise the ask only when customers were turned away, not on a mere sell-out
    offer_full_capacity::Bool = false                 # persons offer all their capacity instead of the minimum that covers their needs
    wage_reservation_net_of_tax::Bool = false         # worker's floor nets a meal after wage tax (the price vector was derived this way)
    random_hiring_ties::Bool = false                  # equal asks: random order (default: stable sort ⇒ agent-id order)
    no_labour_tolerance::Bool = false                 # unsold labour units always count as 'partly unsold' (tolerance is for goods)
    partial_unemployment_fee::Bool = false            # fee pro rata to the unsold share of offered labour
    credit_for_bread::Bool = false                    # a person may promise a meal on credit when eligible for the loan (spec v1 §4.9 'borrowed if needed')
    spoilage_aware_stocking::Bool = false             # stockers hold at most breads_per_meal × spoilage_age (nothing they buy will spoil)
    distress_land_sales::Bool = false                 # a hungry or indebted-in-arrears landholder sells one unit per round at a discount
    distress_land_discount::Float64 = 0.8
    land_units_per_landowner_override::Int = 0        # 0 = spec formula floor((n − p)/(p − 1))
    land_per_person::Float64 = 0.0                    # > 0: total land = land_per_person × persons, shared equally by the landowners (overrides the formula and the override); 2 makes four loaves a head feasible on the land side
    # Enterprise taxation (12 September 2026)
    enterprise_tax::Symbol = :none                    # :none | :income (on net operating cash flow minus interest; banks on interest received) | :reserves (on cash held at end of round)
    enterprise_income_tax_rate::Float64 = 0.10
    enterprise_reserve_tax_rate::Float64 = 0.10
    reserve_tax_exempts_standard_reserve::Bool = false   # :reserves — tax only cash above the standard working reserve
    # Monetary system (SuMSy variant, 12 September 2026)
    monetary_system::Symbol = :debt                   # :debt (bank credit creates money) | :sumsy (GI created, demurrage destroys, peer lending only)
    guaranteed_income::Float64 = 5.0                  # per person per round, fixed nominal (one bread at the initial price)
    guaranteed_income_in_breads::Float64 = 0.0        # > 0: the income is this many loaves at the expected bread price each round (indexed; breaks the bounded money stock — a test, not a design)
    demurrage_rate::Float64 = 0.02                    # per round, on balances above the buffer; destroys money
    demurrage_tax_rate::Float64 = 0.0                 # surcharge on the same base, transferred to the government
    demurrage_free_buffer::Float64 = 30.0             # persons only (3 meals at initial prices); everyone else: 0
    initial_money_per_person::Float64 = 30.0          # debt-free initial money, created by the authority
    start_at_saturation::Symbol = :none               # SuMSy: :upper — every person starts at buffer + GI/d (all buffers used, stock N·b + N·GI/d); :lower — one person holds b + N·GI/d, the rest nothing
    initial_price_multiplier::Float64 = 1.0           # scales the initial price vector (a saturated village runs at a lower price level than a starting one)
    account_fee_person::Float64 = 0.5                 # per round, promised to the person's bank at clearing
    account_fee_enterprise::Float64 = 1.5
    peer_lending::Bool = true
    peer_loan_rate::Float64 = -0.01                   # borrower's rate per round (negative: lending beats demurrage)
    bank_spread::Float64 = 0.005                      # lender receives peer_loan_rate − bank_spread
    affordability_pricing::Bool = false               # a seller who turned buyers away for lack of cash cuts its ask towards their cash, above its cost floor
    indexed_pricing::Bool = false                     # wage, grain and rent asks/bids are re-expressed in bread units every round
    wage_reservation_net_of_gi::Bool = false          # SuMSy: the worker's floor covers only the part of the meal the GI does not
    reserve_pricing::Bool = false                     # producers cut their ask (to the cost floor) while cash exceeds the working reserve, raise it when below half of it
    reserve_pricing_step::Float64 = 0.05
    wage_reservation_includes_savings::Bool = false   # the worker's floor also covers building the savings buffer (3 meals) over savings_build_rounds
    savings_build_rounds::Int = 10
    # Initial endowment (12 September 2026): every actor starts at its stock-flow norm
    initial_endowment::Symbol = :none                 # :none | :norm — persons: savings target (3 meals); farms/bakeries: standard working reserve
    startup_loan_term::Int = 50                       # :debt — enterprises borrow the endowment (own reserve + the persons' share) and pay it out
    startup_loan_rate::Float64 = 0.005
    inherited_money::Bool = false                     # debt money: villagers start with the SuMSy starting cash debt-free — residual money of deceased villagers whose loans were written off (booked against the banks' equity)
    land_loans::Bool = false                          # land may be bought on credit (collateral: the land itself, seized after 2 rounds of arrears)
    bread_loan_term::Int = 0                          # persons' clearing credit (meals) at this term; 0 = loan_term_in_rounds
    land_sales::Symbol = :forced                      # :forced (spec: any buyer with surplus takes a unit) | :distress_only | :reservation (seller sells only above the value of the rent stream)
    land_reservation_multiple::Float64 = 100.0        # :reservation, debt money: rounds of rent a landowner wants for a unit; SuMSy uses rent / demurrage_rate
    # Deposit interest (debt system): paid by the account holder's bank from retained interest
    deposit_interest_rate::Float64 = 0.0              # per payout period, on the average end-of-round balance over the period
    deposit_interest_period::Int = 1                  # rounds between payouts (1 = every round; 12 = yearly)
    loyalty_bonus_rate::Float64 = 0.0                 # per period, on the lowest end-of-round balance over the period
    deposit_interest_to_enterprises::Bool = false     # business accounts earn nothing unless switched on
    # Instalment purchases (SuMSy): seller-financed land sales, paid in equal instalments, land as collateral
    instalment_purchases::Bool = false
    instalment_rounds::Int = 20
    # Deferred payment for shares (14 September 2026): seller credit through the bank, the shares as collateral
    deferred_payment::Bool = false                    # a share buyer short of cash may pay in instalments; the seller finances it at deferred_payment_rate (bank keeps its spread)
    deferred_payment_rounds::Int = 20
    deferred_payment_rate::Float64 = NaN              # NaN = peer_loan_rate under SuMSy (−1 %), 0.5 % a round under debt money
    # Buffer pool and default insurance (SuMSy, 12 September 2026)
    buffer_lending::Bool = false                      # persons may lend part of their demurrage-free buffer to their bank (exemption moves with the money)
    buffer_lending_participation::Float64 = 0.5       # share of persons who opt in
    buffer_lend_fraction::Float64 = 0.5               # share of the buffer a participant lends
    buffer_lender_spread_discount::Float64 = 0.5      # participants pay this fraction less of the bank spread when they borrow
    default_insurance::Bool = false                   # instalment sellers pay a premium; the bank covers missed instalments from its reserves and takes over the claim
    insurance_premium_rate::Float64 = 0.02            # share of each instalment paid by the insured seller to the bank
    # Harvest shock
    harvest_shock_start::Int = 0                      # 0 = no shock
    harvest_shock_length::Int = 3
    harvest_shock_factor::Float64 = 0.5
    # Government bonds (13 September 2026): sold to surplus holders through the bank before any bank credit
    government_bonds::Bool = false
    bond_term_long::Int = 60
    bond_term_short::Int = 12
    # Income tax schedule (13 September 2026). :belgian — brackets as shares of the full-time gross wage (median gross ≈ €45k):
    # social contributions 13.07 % first, then 25/40/45/50 % on taxable income above 0.363/0.64/1.108 × reference,
    # a 25 % credit on an allowance of 0.242 × reference, and a 7 % municipal surcharge. Wage tax only; rent keeps capital_tax_rate.
    income_tax_schedule::Symbol = :flat
    social_contribution_rate::Float64 = 0.1307
    tax_free_share::Float64 = 0.242
    tax_bracket_edges::Vector{Float64} = [0.363, 0.640, 1.108]
    tax_bracket_rates::Vector{Float64} = [0.25, 0.40, 0.45, 0.50]
    municipal_surcharge::Float64 = 0.07
    # Entertainment (13 September 2026): a pure service, labour only
    entertainment::Bool = false
    number_of_theatres::Int = 1
    customers_per_labour_unit::Float64 = 2.5          # 10 customers per full-time job at capacity 4
    max_tickets_per_person::Int = 3                   # 1–3 tickets a round, at random within what cash above the buffer allows
    entertainment_propensity::Float64 = 1.0           # probability a person who can afford a ticket wants one
    plan_for_tickets::Bool = true                     # theatres plan hiring on expected ticket demand (like bakeries on gluttony)
    # Clearing switch (13 September 2026): true = all intra-round payments are promises netted at clearing (spec v2 addendum);
    # false = every payment is settled immediately (cash, then credit, the unpaid tail becomes a trade arrear)
    clearing::Bool = true
    # Ownership (13 September 2026)
    ownership::Symbol = :none                          # :none | :cooperative (every person holds an equal share of every producer) | :shareholders (a few persons hold all shares) | :mixed (cooperative_* producers are co-ops, the rest shareholder-owned)
    shareholder_count::Int = 2                         # :shareholders / :mixed — persons (lowest ids) who hold the shares
    cooperative_farms::Int = 2                         # :mixed
    cooperative_bakeries::Int = 2
    dividend_build_rounds::Int = 10                    # cash above the reserve target is paid out over this many rounds
    dividend_tax_rate::Float64 = 0.30                  # Belgian withholding tax on dividends
    share_market::Bool = false                         # shareholder enterprises' shares trade once a round
    shares_per_person::Int = 0                         # share units per firm = this × number of persons (0 = 100 units per firm), so every villager could hold shares
    startup_financing::Symbol = :enterprise_loans      # :enterprise_loans (businesses borrow their own start) | :paid_in_capital (owned businesses start empty; founders borrow personally and pay capital in; co-ops raise membership capital)
    membership_share_price::Float64 = 10.0             # a cooperative share, at par (one meal at initial prices)
    cooperative_join_probability::Float64 = 0.5        # a person with surplus who is not yet a member joins one cooperative a round with this probability
    required_yield::Float64 = 0.01                     # base required dividend yield per round; a person's own yield is drawn once around it
    required_yield_dispersion::Float64 = 0.0           # half-width of the per-person spread (0 = everyone values a firm alike → no voluntary trades)
    share_step::Float64 = 0.05                         # ask/bid adaptation per round (distress asks)
    forward_valuation::Bool = false                    # value a firm by its expected dividends after its loans are repaid, not by trailing dividends and book
    founder_minimum_stake::Float64 = 0.51              # founders together keep at least this fraction of each firm
    expected_price_growth::Float64 = 0.0               # per round; buyers' valuation = dividend / (own yield − this) — the resale-expectation term, off by default
    arrears_de_minimis_in_meals::Float64 = 0.01       # a shortfall smaller than this share of a meal is not a missed payment
    closure_debt_threshold_in_breads::Float64 = 1.0   # an enterprise with nothing left to seize is closed only if the uncovered debt exceeds this
    # Greed (13 September 2026): a property of persons, above their own reserve
    greed::Bool = false
    greed_share::Float64 = 0.25                        # share of persons who are greedy
    greed_hoarding::Float64 = 0.5                      # every greedy person is both: each act of greed goes to capital with this probability (most profitable of land, shares, cash first), to consumption (a loaf or a ticket, coin flip) otherwise
    greed_selection::Symbol = :rich                    # :rich (the wealthiest at the founding) | :random
    greedy_max_breads_per_round::Int = 10              # replaces the 3-loaf ceiling for greedy consumers (eaten, not stocked)
    greedy_max_tickets_per_round::Int = 10             # replaces the 3-ticket ceiling
    # Bread rationing (13 September 2026): stage one, everyone up to the ration; stage two, leftovers to the greedy
    bread_rationing::Bool = false
    ration_breads_per_person::Int = 4                 # lowered to what the shelves can give everyone, never below a meal
    tiered_bread_price::Bool = false                  # loaves beyond the ration sell at a second posted price that rises on unmet greed and falls on unsold leftovers (never below the ordinary price)
    tier_step::Float64 = 0.06
    no_self_service::Bool = false                     # a theatre's workers are not served at their own theatre that round
    wage_ceiling_in_breads::Float64 = 0.0             # incomes policy: no employer pays more than this many loaves per full-time round of work (0 = off); binds bids and the surplus-to-wages rule
    stop_when_half_dead::Bool = true
    stop_when_stationary::Bool = true

    # Run control
    maximum_rounds::Int = 50
    stationary_rounds::Int = 5
    stationary_tolerance::Float64 = 0.01
    seed::Int = 1
end

"""floor((n − p) / (p − 1)) with n persons and p landowners; n when p = 1 (spec §1)."""
function land_units_per_landowner(p::SimulationParameters)
    p.land_per_person > 0 && return max(round(Int, p.land_per_person * p.number_of_persons / max(p.number_of_landowners, 1)), 1)
    p.land_units_per_landowner_override > 0 && return p.land_units_per_landowner_override
    n = p.number_of_persons
    l = p.number_of_landowners
    return l == 1 ? n : (n - l) ÷ (l - 1)
end
