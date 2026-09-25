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
    initial_prices::OrderedDict{Symbol, Float64} = OrderedDict(:bread => 5.0, :grain => 5.2, :rent => 0.75, :wage => 3.92, :ticket => 2.0)   # static-consistent vector, see HANDOFF
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
    # Unmet demand (19 September 2026). Sellers raise their ask and their production target when demand went unmet.
    # 0 = the original rule: one buyer who found nothing is enough. A share s > 0 requires the units that went unserved
    # to be at least s of what the market sold plus what it missed (5–10 % is a realistic threshold). Wages keep the
    # original rule: a worker who sold all their capacity cannot observe how much more was wanted.
    unmet_demand_share::Float64 = 0.0
    # Unsold stock, the mirror image (20 September 2026): 0 = the original rule, a cut of `ask_decrease_after_partial_sale`
    # whenever more than `unsold_tolerance_units` were left; a share s > 0 requires the unsold units to be at least s of what
    # was offered, so that the cut has the same logic as the rise on unmet demand.
    unsold_share::Float64 = 0.0
    # Ask floor (20 September 2026). :none = the posted ask may decay without limit (only the negotiation floors it, and aged
    # bread is discounted below cost); :cost = after adaptation the posted ask is never below the seller's unit cost —
    # `seller_reservation` at age 0 — raised by `ask_floor_markup_when_short` while the seller's cash is below its reserve
    # (a producer) or savings buffer (a person). Realistic: nobody prices new output below what it cost to make.
    ask_floor::Symbol = :none
    ask_floor_markup_when_short::Float64 = 0.05
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
    government_rate::Float64 = 0.005                  # per round; the government's borrowing rate (a policy rate, about 6 % a year); NaN = the bank's marginal rate × government_rate_discount (a bank with a small loan book then charges a great deal)
    maximum_interest_rate::Float64 = 0.05             # per round; a ceiling on the rate a bank may set
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
    # Government reserve (20 September 2026). 0 = the rule until now: whatever tax exceeds spending sits on the government's
    # balance (under SuMSy it pays demurrage there, and in the no-greed village it reached a fifth of the money stock).
    # n > 0: the government keeps a reserve of n rounds of expected spending (the trailing mean of its outlays over
    # `government_expense_window` rounds) and disposes of the surplus above it each round, `surplus_redistribution_share`
    # of it as an equal per-capita payment to the living and `surplus_tax_reduction_share` of it by scaling next round's
    # taxes down (all of them: wage, capital, demurrage tax — the scale is one number, `tax_scale`, never above 1). With
    # the two shares summing to 1 the reserve tracks the target up to the volatility of spending; below 1 it drifts up.
    # A shortfall lets the scale climb back towards 1 at `surplus_tax_reduction_share` of the gap a round.
    government_reserve_in_rounds::Int = 0
    government_expense_window::Int = 12
    surplus_redistribution_share::Float64 = 0.0
    surplus_tax_reduction_share::Float64 = 0.0
    # Fiscal policy (20 September 2026): taxes that move in both directions, incrementally.
    # The shortfall a round is what spending exceeds revenue by (trailing means over `government_expense_window`) plus
    # the gap between the reserve and its target spread over `government_reserve_in_rounds` rounds. The policy aims to
    # close `tax_response_coverage` of it by raising taxes, and lowers them again on a surplus (the reserve rule's
    # `surplus_tax_reduction_share` of the surplus above target), but never changes revenue by more than
    # `tax_response_step` (a fraction of current revenue) in one round, so that there are no shocks.
    #   :none     — no raises; only the reserve rule's reductions, unlimited in size (the rule until now)
    #   :scale    — one multiplier on every tax (flat wage tax, capital tax, demurrage tax; the whole progressive schedule).
    #               The "income" family is the wage and capital tax under debt money and the demurrage tax under SuMSy,
    #               which taxes no income; the lever on that family acts on whichever the village has.
    #   :brackets — needs `income_tax_schedule = :progressive`: a rise of r changes each bracket's rate to
    #               rate × (1 + r) + `bracket_fixed_rise` × sign(r) — proportional, so the 50 % bracket moves five times as
    #               much as the 10 % one, plus a fixed number of points per bracket; falls back to :scale under :flat
    # Consumption tax (20 September 2026): a VAT on what persons buy to consume — bread and tickets — paid by the buyer on
    # top of the negotiated price and promised to the government (grain is an input and stays untaxed, as VAT is neutral
    # between firms). The buyer's willingness to pay is for the price including tax, so the ceiling passed to the
    # negotiation is divided by (1 + rate). Belgium's average rate on consumption is about 6 %. The fiscal policy scales
    # it with the same triggers and step as the income tax.
    consumption_tax_rate::Float64 = 0.0
    # Mix (20 September 2026, night — levers, replacing the sliders): three tax families, each with its own scale — income
    # (wage, capital, demurrage tax; the progressive brackets), consumption, wealth. Each round the policy first *shifts*
    # and then *moves*. The move is r (raise on a shortfall, cut on a surplus, step-limited), applied to every family.
    # The shift is a lever per family: family i first moves by r × lever_i — a positive lever moves with the policy at
    # that rate, a negative one against it, 0 not at all. So a family's total relative move in a round is
    # (1 + |r| × lever_i) × (1 + r) − 1. The shift uses |r|: a lever is a standing preference, not a direction, so a
    # family with a negative lever is relieved on a raise and cut hardest on a cut. Levers (0, 0, 0) = one scale;
    # (−2, +1, 0) shifts the burden from income to consumption whichever way the total moves. The step limit applies to
    # r; a lever multiplies it. Under SuMSy the income family is the demurrage tax (see `tax_policy`).
    # Five tax families (22 September 2026, design §3), each with its own scale and lever: income (wage, capital and dividend tax;
    # the progressive brackets), consumption (VAT), wealth, profit, parking (the SuMSy parking tax — the parking *fee* is money,
    # not tax, and is never scaled). Any family left out of the tuple has lever 0, so (income = -3.0,) is a valid setting.
    tax_levers::NamedTuple = (income = 0.0, consumption = 0.0, wealth = 0.0, profit = 0.0, parking = 0.0, land = 0.0)   # land: the land levy (24 Sept)
    # Collection periods (design §3): 1 = every month, as before; 12 = accrued through the year and charged in the twelfth month.
    # Monthly withholding with a yearly balance (the Belgian mode) is a future option.
    income_tax_period::Int = 1
    # Profit tax (design §3): per period, revenue − `deductible_materials` × (materials, rent and interest) − `deductible_labour` ×
    # wages, never below 0 (no loss carry-forward), at `profit_tax_rate` (the rate applies to the profit whatever the period's
    # length). Charged to farms, bakeries and theatres; an invoice to the government under settlement = :invoicing.
    profit_tax_rate::Float64 = 0.0
    profit_tax_period::Int = 1
    deductible_materials::Float64 = 1.0
    deductible_labour::Float64 = 0.5
    # Wealth tax (20 September 2026): a yearly rate on what a person holds in land and shares, valued at book — land at
    # `land_price` (rent multiple × expected rent), shares at `book_per_unit` (the firm's cash + land − debt per unit),
    # cooperative membership at the capital paid in. Charged every round at rate ÷ `wealth_tax_rounds_per_year`, in cash,
    # after demurrage; what a person cannot pay is carried as `wealth_tax_arrears` (no interest) and collected first from
    # the next round's cash. Part of the mix: the fiscal policy moves its own scale (with r, and with the shift)
    # (weight 0 keeps it statutory). Enterprises are not taxed directly: their
    # land and cash are in the book value of the shares their owners pay on.
    wealth_tax_rate::Float64 = 0.0                    # per year, on book value of land and shares held by persons
    wealth_tax_rounds_per_year::Int = 12
    tax_policy::Symbol = :none
    tax_response_coverage::Float64 = 0.5              # share of the shortfall a raise is sized to cover
    tax_response_step::Float64 = 0.02                 # largest relative change in revenue per round (2 % = incremental)
    bracket_fixed_rise::Float64 = 0.0                 # :brackets — points added to every bracket per step, on top of the proportional rise
    tax_scale_maximum::Float64 = 3.0                  # :scale — the multiplier never exceeds this (statutory rates × 3)
    bracket_rate_maximum::Float64 = 0.9               # :brackets — no bracket rate above this
    demurrage_free_buffer::Float64 = 30.0             # persons only (3 meals at initial prices); everyone else: 0
    initial_money_per_person::Float64 = 30.0          # debt-free initial money, created by the authority
    start_at_saturation::Symbol = :none               # SuMSy: :upper — every person starts at buffer + GI/d (all buffers used, stock N·b + N·GI/d); :lower — one person holds b + N·GI/d, the rest nothing; :equilibrium (20 September 2026) — every person at b + GI/(d + demurrage tax), the balance at which their own creation equals their own destruction, so the stock starts inside its bounds and stays there. The money stock depends on GI and demurrage only, never on prices: a village started below its equilibrium sees the stock — and with it the price level — rise for ~60 rounds. Pair with `initial_price_multiplier` ≈ 1.35 (the 64-person steady state: bread 1.27×, grain 1.32×, wage 1.49× the initial vector; the 0.63 used in the 15 September saturation runs is a 16-person figure)
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
    # Theatre capacity (20 September 2026). A theatre runs at most `shows_per_round` shows a round with `seats_per_show`
    # seats each, so it can sell at most shows × seats tickets and never needs more labour than that takes at
    # `customers_per_labour_unit`. 0 shows = unlimited (the rule until 20 September: a theatre absorbed whatever labour
    # ticket demand paid for). 0 seats = one seat for every person in the village at founding.
    shows_per_round::Int = 0
    seats_per_show::Int = 0                           # 0 = villagers ÷ theatres × (1 + theatre_seat_margin), so the theatres together seat the village plus the margin
    theatre_seat_margin::Float64 = 0.25               # 21 September: with several theatres a seat per villager *per theatre* would be several times the village
    # Clearing switch (13 September 2026): true = all intra-round payments are promises netted at clearing (spec v2 addendum);
    # false = every payment is settled immediately (cash, then credit, the unpaid tail becomes a trade arrear)
    clearing::Bool = true
    # Ownership (13 September 2026)
    ownership::Symbol = :none                          # :none | :cooperative (every person holds an equal share of every producer) | :shareholders (a few persons hold all shares) | :mixed (cooperative_* producers are co-ops, the rest shareholder-owned)
    shareholder_count::Int = 2                         # :shareholders / :mixed — persons (lowest ids) who hold the shares
    cooperative_farms::Int = 2                         # :mixed
    cooperative_bakeries::Int = 2
    cooperative_theatres::Int = 0                      # :mixed — theatres were for-profit only until 14 September 2026
    # Cooperative forms (14 September 2026), per kind: :member (the original equal-share, equal-dividend rule),
    # :worker (membership follows employment, surplus by hours) or :consumer (membership follows purchases,
    # surplus as a patronage rebate). Farms cannot be consumer cooperatives: they sell to bakeries, not to persons.
    cooperative_form_farms::Symbol = :member
    cooperative_form_bakeries::Symbol = :member
    cooperative_form_theatres::Symbol = :member
    patronage_window::Int = 12                         # rounds of hours or purchases a distribution is measured over
    retained_surplus_share::Float64 = 0.25             # share of every distribution locked in the indivisible reserve
    capital_deduction_share::Float64 = 0.10            # worker cooperative: share of each net wage collected towards the membership share
    membership_lapse_rounds_worker::Int = 6            # grace period before a member without hours is redeemed
    membership_lapse_rounds_consumer::Int = 12         # grace period before a member without purchases is redeemed
    minimum_member_hours::Float64 = 0.5                # average units a round below which worker membership lapses
    members_first_hiring::Bool = true                  # worker cooperatives serve their members before the open market, spreading the work over them
    member_price_awareness::Bool = true                # consumer cooperative members net the expected rebate off the ask when choosing a seller
    # What a member brings in (14 September 2026). Under SuMSy a member can pledge part of their demurrage-free
    # buffer instead of money: no money moves, the member's own exemption shrinks by the pledge and the cooperative's
    # grows by the same amount, so the cooperative can hold that much cash without paying demurrage. A pledge is
    # worthless under debt money (there is no demurrage): a :buffer membership is then free and a :mixed_flexible one
    # costs its money half alone, so the buffer forms are only meaningful under SuMSy.
    membership_contribution::Symbol = :money           # :money | :buffer | :mixed_fixed (both) | :mixed_flexible (the member splits a single total)
    membership_buffer_pledge::Float64 = 10.0           # buffer requirement, in currency units of exemption
    buffer_contribution_value::Float64 = 1.0           # money a unit of pledged buffer counts for under :mixed_flexible (0 under debt money)
    cooperative_founding::Symbol = :par_only           # :par_only (members bring one share at par) | :symmetric (members are called on for capital like shareholder founders)
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

    # Settlement (22 September 2026, design of 21 September). Two systems:
    #   :invoicing    — the design: a consumer pays cash at the counter; wages and rent are paid at the end of the month from
    #                   takings (credit for the shortfall); firms invoice each other, payable at the end of the NEXT month (trade
    #                   credit, no interest; unpaid invoices age and can trigger liquidation); clearing only among
    #                   `settlement_clearing` members (the banks, and the government, which finances itself there).
    #   :clearing_all — the system of every version before 22 September: all payments of everyone, consumers included, are
    #                   netted and settled together at the end of the month. Kept as the default for now only so earlier
    #                   results and the regression tests still reproduce; to become the comparison once :invoicing is the default.
    # `clearing = false` still means cash for everything (legacy).
    settlement::Symbol = :clearing_all              # :invoicing | :clearing_all (see above)
    settlement_clearing::Vector{Symbol} = [:bank, :government]
    settlement_invoicing::Vector{Symbol} = [:farm, :bakery, :theatre, :government]
    # Liquidation (design §2): a producer whose invoices overdue by `liquidation_overdue_rounds` or more reach
    # `liquidation_arrears_share` of its book value is sold as a going concern at `liquidation_price_share` × book value
    # (never below the debt left after its cash), to up to `shareholder_count` buyers with the most spare cash, who hold the
    # new shares pro rata; if no group can pay, it is closed and its assets go to its creditors, the rest struck.
    # Working capital (22 September): under :invoicing a supplier waits a month to be paid, so banks lend against what it is owed —
    # a loan is affordable when it is covered by `receivables_advance_rate` of the open invoices owed to the borrower, whatever
    # the income test says (invoice financing). 0 switches it off.
    receivables_advance_rate::Float64 = 0.8
    # Bank staff (22 September): 0 = one unit of labour per bank, as before. k > 0 = one unit per k villagers the bank serves, so a
    # bank's wage bill grows with its customers and the cost-recovery lending rate does not fall just because the village is larger.
    bank_customers_per_labour_unit::Int = 0
    # The liquidation test (23 September, closest to Belgian insolvency law: persistent non-payment *and* shaken credit):
    #   :cash_flow — overdue obligations (invoices and loan instalments, each at least `liquidation_overdue_rounds` behind) reach
    #                `liquidation_arrears_share` of the firm's monthly turnover, *and* a loan to pay them is refused;
    #   :book      — the 22 September rule: overdue invoices reach that share of book value (fires on any overdue once book ≤ 0).
    liquidation_test::Symbol = :cash_flow
    # Founders pay in equity at the founding equal to the firm's working reserve, from savings or a personal loan (23 Sept; a Belgian
    # BV must start with sufficient equity). false = the old rule: firms start empty and call on founders when short.
    founding_equity::Bool = false
    # Who founds the firms (24 September): :shared = the old rule, the same `shareholder_count` villagers found every firm
    # (at 512 villagers: 4 owners of all twelve firms); :distinct = every firm has its own founders, taken in order of id,
    # wrapping round when there are more founder places than villagers (at 512 with twelve firms: 48 owners, 9 %).
    founders::Symbol = :shared
    # The land market (24 September). :multiple = the old rule, price = `land_price_rent_multiple` × rent. :market = the price is
    # discovered: it starts at `land_price_rent_multiple` × rent and moves by `land_price_step` when at least `unmet_demand_share`
    # of the demand went unserved (up) or at least `unsold_share` of the land offered went unsold (down). Sellers and buyers value
    # land by the money logic: a unit is worth its rent divided by the monthly rate at which money is held (debt: deposit interest
    # and loyalty bonus; SuMSy: the parking fee and parking tax) or borrowed (debt: the bank's rate).
    land_pricing::Symbol = :multiple
    land_price_step::Float64 = 0.06
    # Landowners who sell for reasons of their own (an inheritance, a move) — the monthly probability that a landowner offers a unit
    # at the best bid (25 September). Such sales count for the valuation price; distress sales do not.
    land_life_event_rate::Float64 = 0.005
    # A levy on land (24 September; Gesell's Freiland as a variant): each month landholders pay `land_levy_rate` × the value of their
    # land to the government. With `land_levy = true` the rate is the cost of holding money (parking fee + parking tax, 0 under
    # debt money) plus `land_levy_margin` — land is then worth its rent over that margin, as a debt village values it over its
    # deposit rate. Without a levy, under SuMSy, land always beats money that loses value, and nobody sells it voluntarily.
    land_levy::Bool = false
    land_levy_margin::Float64 = 0.0025
    # Seller credit on land (24 September): the monthly rate is a market decision between the seller's best alternative for the
    # money and the buyer's best alternative source of credit; the seller gets this share of the gap (0.5 = split the difference).
    # Under SuMSy both alternatives are negative, so the rate is too.
    instalment_bargaining::Float64 = 0.5
    # A levy on land holdings (24 September, the Freiland variant): each month every landholder pays `land_levy_rate` × the value of
    # its land at the current price, to the government (a land-value tax). Land is worth rent ÷ (levy − what money earns); under SuMSy
    # money earns minus the parking fee, so without a levy land beats money at any price, and with a levy equal to the parking fee
    # it still does — the levy must exceed the parking fee for land to have a finite price.
    land_levy_rate::Float64 = 0.0
    # The run stops when no farm or no bakery is left (the old rule); false = the village runs on, and starves or recovers (review 5).
    stop_without_producers::Bool = true
    # Wages rise only when at least `unmet_demand_share` of the labour employers wanted went unfilled (25 September; false = the
    # old rule, any shortfall raises every sold-out worker's ask — a wage ratchet that ran on with a quarter of the village idle).
    wage_threshold::Bool = false
    # When fewer than this many farms (or bakeries) are open, villagers try to start one (24 September; 0 = never).
    refound_minimum::Int = 1
    refound_cooldown::Int = 3                         # at most one restart per kind in this many months (a village that cannot sustain a firm would otherwise restart one every month)
    # The reserve rule without a tax policy never scales taxes below this (25 September, review 6: at 0 they could never recover).
    tax_scale_minimum::Float64 = 0.05
    # Market entry (25 September; docs/designs_implemented/design_market_entry_2026-09-25.md): off by default and on the ladder. A new farm, bakery or theatre
    # is founded when its market has had at least `entry_unmet_share` unserved demand in each of the last `entry_unmet_months`
    # months, or its firms have averaged an operating margin above `entry_margin` over the last `entry_margin_months` months — at
    # most one per kind per `entry_cooldown` months and up to `entry_max_ratio` × the starting number. Founders are the villagers
    # with the most spare cash (founding rules); the firm is a cooperative with probability `entry_coop_share`.
    market_entry::Bool = false
    entry_unmet_share::Float64 = 0.05
    entry_unmet_months::Int = 3
    entry_margin::Float64 = 0.20
    entry_margin_months::Int = 6
    entry_cooldown::Int = 3
    entry_max_ratio::Float64 = 2.0
    entry_coop_share::Float64 = 0.0
    # Founding loans on business terms (24 September): a founder borrows for their share of the founding equity only what passes
    # the affordability test over `founding_loan_term` months; a founder who cannot carry the full share puts in what they can
    # and the firm starts with less equity (it borrows the rest itself when it needs it).
    founding_loan_term::Int = 60
    # A protected minimum on debt collection (24 September; cf. the legal limits on garnishment): loan repayment and garnishment
    # never take a person's cash below this many loaves at the current price — what cannot be paid becomes arrears.
    collection_floor_in_breads::Float64 = 1.0
    liquidation_arrears_share::Float64 = 0.10
    liquidation_overdue_rounds::Int = 3
    liquidation_price_share::Float64 = 0.90
    liquidated_coop_stays_coop::Bool = false           # true: a cooperative is refounded by its members, one share at par each
    bank_bailout::Bool = true                          # a bank whose net worth goes below zero is recapitalised by the government (failure: a future option)
    peer_loan_insurance::Bool = false                  # SuMSy: every peer loan is insured (premium on repayments to the bank's pool; the pool covers a struck loan, the rest is the lenders' loss)
    # Run control
    random_streams::Bool = true                        # one random stream per subsystem (18 September 2026), each seeded from `seed`; false = the single shared stream of earlier runs
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
