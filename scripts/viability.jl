# Viability study (12 September 2026): 50 fixed rounds, ablation of the behavioural rules.
#   julia --project=. scripts/viability.jl [nseeds]
# Reports per variant and seed: share of persons dead at round 50, price levels and the interest rate
# (means over the last 10 rounds), output, hunger, money and debt. Writes results/viability.csv.
using BreadEconomySim, DataFrames, CSV, Statistics

nseeds = isempty(ARGS) ? 10 : parse(Int, ARGS[1])
fixed = (; maximum_rounds = 50, stop_when_half_dead = false, stop_when_stationary = false)
ABC = (; demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true)
ABCDE = (; demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true, minimum_fee_in_breads = 2.0)
HI = (; random_hiring_ties = true, no_labour_tolerance = true)
BEST = (; ABCDE..., wage_reservation_net_of_tax = true, HI..., partial_unemployment_fee = true, offer_full_capacity = true)
CAP4 = (; maximum_capacity = 4.0)
LO4 = (; number_of_landowners = 4, land_units_per_landowner_override = 6)
ALL = (; credit_for_bread = true, spoilage_aware_stocking = true, distress_land_sales = true, CAP4..., LO4...)
ZD = (; BEST..., ALL...)          # the zero-death configuration (gluttony 10 %)
SUMSY = (; monetary_system = :sumsy, wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0,
            government_employment_share = 0.0, initial_money_per_person = 30.0, account_fee_person = 0.5, account_fee_enterprise = 1.5, demurrage_rate = 0.05, guaranteed_income = 5.0)
scale(f) = (; guaranteed_income = 5.0 * f, demurrage_free_buffer = 30.0 * f, initial_money_per_person = 30.0 * f)
nominal(f) = (; scale(f)..., initial_prices = Dict(:bread => 5.0 * f, :grain => 5.2 * f, :rent => 0.75 * f, :wage => 3.92 * f),
                account_fee_person = 0.5 * f, account_fee_enterprise = 1.5 * f)
AI = (; affordability_pricing = true, indexed_pricing = true)
GW = (; wage_reservation_net_of_gi = true)
RP = (; reserve_pricing = true)
SV(k) = (; wage_reservation_includes_savings = true, savings_build_rounds = k)
NORM = (; initial_endowment = :norm)
DEBT0 = (; ZD..., account_fee_person = 0.0, account_fee_enterprise = 0.0)
LL = (; land_loans = true); BL = (; bread_loan_term = 2)
DN = (; DEBT0..., NORM..., startup_loan_term = 50)
S100 = (; ZD..., SUMSY..., demurrage_rate = 0.02, scale(1.0)..., NORM...)
DN = (; DEBT0..., NORM..., startup_loan_term = 50, land_sales = :reservation)
SR = (; ZD..., SUMSY..., demurrage_rate = 0.02, scale(1.0)..., NORM..., land_sales = :reservation)
SI = (; SR..., land_price_rent_multiple = 50.0, instalment_purchases = true, instalment_rounds = 20)
SHOCK = (; harvest_shock_start = 25, harvest_shock_length = 3, harvest_shock_factor = 0.5)
POOL = (; buffer_lending = true, default_insurance = true)
GI05 = (; scale(0.5)..., wage_reservation_net_of_gi = true, wage_reservation_includes_savings = true, savings_build_rounds = 3)
DEP = (; deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02)
DNR = (; DN..., deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02)
SRR = (; SR..., instalment_purchases = true, land_price_rent_multiple = 50.0)
DG = (; DNR..., gluttony_probability = 0.1, plan_for_gluttony = true)
SG = (; SRR..., gluttony_probability = 0.1, plan_for_gluttony = true)
variants = [
    ("debt_partial",             DG),
    ("debt_fullonly",            (; DG..., partial_unemployment_fee = false)),
    ("debt_theatre_partial",     (; DG..., entertainment = true)),
    ("debt_theatre_fullonly",    (; DG..., entertainment = true, partial_unemployment_fee = false)),
    ("debt_theatre_fullonly_margin", (; DG..., entertainment = true, partial_unemployment_fee = false, planning_margin = 0.1)),
    ("debt_fullonly_nofee",      (; DG..., partial_unemployment_fee = false, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0, entertainment = true)),
]
variants_old = [
    ("targets",                (; demand_based_targets = true)),
    ("ceiling",                (; wage_ceiling_from_own_ask = true)),
    ("asks",                   (; expected_price_from_asks = true)),
    ("targets+ceiling",        (; demand_based_targets = true, wage_ceiling_from_own_ask = true)),
    ("targets+asks",           (; demand_based_targets = true, expected_price_from_asks = true)),
    ("ceiling+asks",           (; wage_ceiling_from_own_ask = true, expected_price_from_asks = true)),
    ("all_three",              (; demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true)),
    ("all_three+margin10",     (; demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, planning_margin = 0.10)),
    ("all_three+ageing15",     (; demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, bread_price_ageing_discount = 0.15)),
]
lastn(v, n = 10) = v[max(1, end - n + 1):end]
mean_nn(v) = (x = filter(!isnan, v); isempty(x) ? NaN : mean(x))

function summarise(name, kw, s)
    m = run_simulation(SimulationParameters(; seed = s, fixed..., kw...)); d = round_data(m)
    n0 = m.initial_person_count
    (variant = name, seed = s, rounds = nrow(d), stop = m.termination_reason,
     dead_pct = round(100 * (n0 - d.persons_alive[end]) / n0, digits = 1),
     first_death = (i = findfirst(>(0), d.deaths); i === nothing ? 0 : i),
     farms = d.farms_open[end], bakeries = d.bakeries_open[end],
     bread_last10 = round(mean(lastn(d.bread_baked)), digits = 1), bread_need = 2 * d.persons_alive[end],
     hungry_person_rounds = sum(d.hungry), half_meal_rounds = sum(d.half_meals),
     p_bread = round(mean_nn(lastn(d.price_bread)), digits = 2), p_grain = round(mean_nn(lastn(d.price_grain)), digits = 2),
     p_wage = round(mean_nn(lastn(d.price_wage)), digits = 2), p_rent = round(mean_nn(lastn(d.price_rent)), digits = 2),
     rate_pct = get(kw, :monetary_system, :debt) == :sumsy ? NaN : round(100 * mean_nn(lastn(d.interest_rate)), digits = 2),
     rate_max_pct = get(kw, :monetary_system, :debt) == :sumsy ? NaN : round(100 * maximum(filter(!isnan, d.interest_rate)), digits = 2),
     money = round(d.money_in_circulation[end], digits = 0), debt = round(d.outstanding_debt[end], digits = 0), gov_debt = round(d.government_debt[end], digits = 0),
     refusals = d.cumulative_credit_refusals[end], unemployed = round(mean(d.unemployed), digits = 1),
     tax_last10 = round(mean(lastn(d.tax)), digits = 1), ent_tax_last10 = round(mean(lastn(d.enterprise_tax)), digits = 1), fees_last10 = round(mean(lastn(d.fees)), digits = 1),
     gov_debt_growth = round((d.government_debt[end] - d.government_debt[max(1, end - 10)]) / 10, digits = 1),
     dep_interest_total = round(sum(d.deposit_interest), digits = 1), bank_retained = round(d.bank_retained_interest[end], digits = 1),
     bonds = round(d.bonds_outstanding[end], digits = 0), gov_bank_debt = round(d.government_bank_debt[end], digits = 0), coupons_total = round(sum(d.coupons), digits = 1),
     bond_rate_pct = round(100 * mean_nn(lastn(d.bond_rate)), digits = 3), interest_paid_total = round(d.cumulative_interest_paid[end], digits = 1),
     land_farms = d.land_farms[end], land_persons = d.land_persons[end], instalment_sales = count(e -> e.kind == :instalment_purchase, m.events),
     seizures = count(e -> e.kind == :seizure, m.events), write_offs = round(d.cumulative_write_offs[end], digits = 1),
     missed = sum(d.missed_payments), pool = round(d.buffer_pool[end], digits = 1), premiums = round(d.insurance_premiums[end], digits = 1), payouts = round(d.insurance_payouts[end], digits = 1),
     gini_cash = round(d.gini_cash_persons[end], digits = 3), below_meal = round(mean(d.persons_below_meal), digits = 2),
     tickets = round(mean(lastn(d.tickets_sold)), digits = 1), theatre_labour = round(mean(lastn(d.theatre_labour)), digits = 1),
     ticket_share_gdp = round(mean(lastn(d.ticket_revenue)) / (mean(lastn(d.bread_bill)) + mean(lastn(d.ticket_revenue))), digits = 3),
     p_ticket = round(mean_nn(lastn(d.price_ticket)), digits = 2), cash_theatres = round(d.cash_theatres[end], digits = 0),
     glut_attempted = sum(d.gluttony_attempted), glut_refused = sum(d.gluttony_refused),
     income_over_bill = round(mean(lastn(d.persons_income)) / mean(lastn(d.bread_bill)), digits = 3),
     unsold_last10 = round(mean(lastn(d.bread_baked .- d.bread_sold)), digits = 2),
     hungry_shock = sum(d.hungry[min(25, end):min(35, end)]),
     cash_enterprises = round(d.cash_farms[end] + d.cash_bakeries[end], digits = 0), cash_persons = round(d.cash_persons[end], digits = 0),
     money_growth = round((d.money_in_circulation[end] - d.money_in_circulation[max(1, end - 10)]) / 10, digits = 1),
     gi_last10 = round(mean(lastn(d.gi_created)), digits = 1), dem_last10 = round(mean(lastn(d.demurrage_destroyed)), digits = 1),
     demtax_last10 = round(mean(lastn(d.demurrage_tax)), digits = 1), fees_bank_last10 = round(mean(lastn(d.account_fees)), digits = 1),
     peer_lent_last10 = round(mean(lastn(d.peer_lent)), digits = 1), gov_cash = round(d.government_cash[end], digits = 0),
     money_r25 = round(d.money_in_circulation[min(25, end)], digits = 0), money_r40 = round(d.money_in_circulation[min(40, end)], digits = 0), trade_arrears = round(d.trade_arrears[end], digits = 0),
     gini_nw = round(d.gini_net_wealth_persons[end], digits = 2), identity_gap = round(money_identity_gap(m), digits = 8))
end

rows = NamedTuple[]
for (name, kw) in variants, s in 1:nseeds
    push!(rows, summarise(name, kw, s))
    flush(stdout)
end
df = DataFrame(rows)
CSV.write(joinpath(@__DIR__, "..", "results", "viability.csv"), df)
show(stdout, df; allrows = true, allcols = true); println()
println("\n=== per variant (mean over seeds) ===")
g = combine(groupby(df, :variant), :dead_pct => mean => :dead_pct, :dead_pct => (x -> count(==(0), x)) => :seeds_no_death,
            :rounds => mean => :rounds, :bread_last10 => mean => :bread, :hungry_person_rounds => mean => :hungry_pr,
            :p_bread => mean_nn => :p_bread, :p_grain => mean_nn => :p_grain, :p_wage => mean_nn => :p_wage, :p_rent => mean_nn => :p_rent,
            :rate_pct => mean_nn => :rate_pct, :money => mean => :money, :debt => mean => :debt, :gov_debt => mean => :gov_debt, :gini_nw => mean => :gini_nw)
for c in names(g)[2:end]; g[!, c] = round.(g[!, c], digits = 2); end
show(stdout, g; allrows = true, allcols = true); println()
