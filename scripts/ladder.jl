# The report's ladder: a bare-bones village, then one component at a time, debt money vs SuMSy at every rung.
#   julia --project=. scripts/ladder.jl [nseeds] [rounds]
# Writes results/ladder_rounds.csv (per round) and results/ladder_summary.csv.
using BreadEconomySim, DataFrames, CSV, Statistics

nseeds = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 6
rounds = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 50

# Behaviour rules needed for any village to function at all (Section 5 of the report); not components.
N = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 16
RULES = (; number_of_persons = N, number_of_landowners = N ÷ 4, land_per_person = 1.5, initial_production_target = max(N ÷ 6, 6), shares_per_person = (N > 16 ? 10 : 0), shareholder_count = max(N ÷ 16, 2), demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true,
          random_hiring_ties = true, no_labour_tolerance = true, offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true,
          distress_land_sales = true, maximum_capacity = 4.0,
          wage_reservation_net_of_tax = true, initial_endowment = :norm, startup_loan_term = 60, land_sales = :reservation,
          gluttony_probability = 0.1, plan_for_gluttony = true, maximum_rounds = rounds, stop_when_half_dead = false, stop_when_stationary = false)
# Bare bones: no government activity, no benefit, no interest on deposits, no theatre, no margin.
BARE_DEBT = (; RULES..., wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0,
              partial_unemployment_fee = false, government_employment_share = 0.0, account_fee_person = 0.0, account_fee_enterprise = 0.0)
BARE_SUMSY = (; BARE_DEBT..., monetary_system = :sumsy, guaranteed_income = 5.0, demurrage_free_buffer = 30.0, demurrage_rate = 0.02,
               account_fee_person = 0.5, account_fee_enterprise = 1.5, instalment_purchases = true, land_price_rent_multiple = 50.0)
GOV_DEBT = (; wage_tax_rate = 0.15, capital_tax_rate = 0.15, unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, government_employment_share = 0.10)
GOV_SUMSY = (; demurrage_tax_rate = 0.01, government_employment_share = 0.10)       # public jobs funded by a 1 % demurrage tax; the GI is the benefit
DEP = (; deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02)

rungs = [
    ("0 bare bones",             (;),                                     (;)),
    ("1 + planning margin",      (; planning_margin = 0.1),               (; planning_margin = 0.1)),
    ("2 + government",           (; planning_margin = 0.1, GOV_DEBT...),  (; planning_margin = 0.1, GOV_SUMSY...)),
    ("3 + interest on deposits", (; planning_margin = 0.1, GOV_DEBT..., DEP...), (; planning_margin = 0.1, GOV_SUMSY...)),
    ("4 + theatre",              (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true)),
    ("5 + government bonds",     (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, government_bonds = true), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true)),
    ("6 + charge on balances",   (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, government_bonds = true, enterprise_tax = :reserves, enterprise_reserve_tax_rate = 0.05, reserve_tax_exempts_standard_reserve = true), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true)),
    ("7 + second theatre",       (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, government_bonds = true, number_of_theatres = 2), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true, number_of_theatres = 2)),
    ("8 + shareholders & share market", (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, government_bonds = true, number_of_theatres = 2, ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true, number_of_theatres = 2, ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002)),
    ("9 co-ops vs for-profit",   (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, government_bonds = true, number_of_theatres = 2, number_of_farms = 4, number_of_bakeries = 4, ownership = :mixed, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true, number_of_theatres = 2, number_of_farms = 4, number_of_bakeries = 4, ownership = :mixed, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002)),
    ("10 clearing off (rung 7)", (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, government_bonds = true, number_of_theatres = 2, clearing = false), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true, number_of_theatres = 2, clearing = false)),
]

lastn(v, n = 10) = v[max(1, end - n + 1):end]
mean_nn(v) = (x = filter(!isnan, v); isempty(x) ? NaN : mean(x))
out = DataFrame[]; rows = NamedTuple[]
SAT_UP = (; start_at_saturation = :upper, initial_price_multiplier = 0.63)
SAT_LO = (; start_at_saturation = :lower, initial_price_multiplier = 0.63)
only_sumsy = length(ARGS) >= 3 && ARGS[3] == "saturation"
only_rung = length(ARGS) >= 5 ? ARGS[5] : ""
only_rung != "" && filter!(r -> startswith(r[1], only_rung), rungs)
systems(kd, ks) = only_sumsy ? (("sumsy_sat_upper", BARE_SUMSY, (; ks..., SAT_UP...)), ("sumsy_sat_lower", BARE_SUMSY, (; ks..., SAT_LO...))) : (("debt", BARE_DEBT, kd), ("debt_inherited", BARE_DEBT, (; kd..., inherited_money = true)), ("sumsy", BARE_SUMSY, ks))
N != 16 && filter!(r -> !startswith(r[1], "10"), rungs)      # immediate settlement at scale is not part of the comparison
for (name, kd, ks) in rungs, (system, base, kw) in systems(kd, ks), s in 1:nseeds
    m = run_simulation(SimulationParameters(; seed = s, base..., kw...)); d = round_data(m)
    d.rung .= name; d.system .= system; d.seed .= s
    push!(out, d)
    gdp = d.bread_sold .* d.price_bread .+ d.ticket_revenue
    gdp_a = mean(lastn(gdp, 12)) * 12
    push!(rows, (rung = name, system = system, seed = s, alive = d.persons_alive[end], dead_pct = round(100 * (N - d.persons_alive[end]) / N, digits = 1),
                 hungry = sum(d.hungry), unemployed = round(mean(d.unemployed), digits = 1), bread = round(mean(lastn(d.bread_baked)), digits = 1),
                 tickets = round(mean(lastn(d.tickets_sold)), digits = 1), p_bread = round(mean_nn(lastn(d.price_bread)), digits = 2), p_wage = round(mean_nn(lastn(d.price_wage)), digits = 2),
                 gov_debt = round(d.government_debt[end]), debt_gdp_pct = round(100 * d.government_debt[end] / gdp_a, digits = 1),
                 deficit_gdp_pct = round(100 * 12 * (d.government_debt[end] - d.government_debt[max(1, end - 10)]) / 10 / gdp_a, digits = 1),
                 money = round(d.money_in_circulation[end]), gini_wealth = round(d.gini_net_wealth_persons[end], digits = 2), gini_cash = round(d.gini_cash_persons[end], digits = 2),
                 cash_ent = round(d.cash_farms[end] + d.cash_bakeries[end] + d.cash_theatres[end]), dividends = round(sum(d.dividends), digits = 1),
                 share_trades = sum(d.share_trades), share_price = round(mean_nn(lastn(d.share_price_mean)), digits = 2), book = round(mean_nn(lastn(d.book_per_unit_mean)), digits = 2),
                 coop_open = d.coop_open[end], forprofit_open = d.forprofit_open[end], cash_coops = round(d.cash_coops[end]), cash_forprofit = round(d.cash_forprofit[end]),
                 arrears = round(d.trade_arrears[end], digits = 1), refusals = d.cumulative_credit_refusals[end], identity = round(money_identity_gap(m), digits = 8)))
    println(name, " ", system, " seed ", s, " alive ", d.persons_alive[end]); flush(stdout)
end
CSV.write(joinpath(@__DIR__, "..", "results", only_sumsy ? "ladder_sat_rounds.csv" : (N == 16 ? "ladder_rounds.csv" : (only_rung == "" ? "ladder$(N)_rounds.csv" : "ladder$(N)_$(replace(only_rung, " " => "_"))_rounds.csv"))), vcat(out...; cols = :union))
CSV.write(joinpath(@__DIR__, "..", "results", only_sumsy ? "ladder_sat_summary.csv" : (N == 16 ? "ladder_summary.csv" : (only_rung == "" ? "ladder$(N)_summary.csv" : "ladder$(N)_$(replace(only_rung, " " => "_"))_summary.csv"))), DataFrame(rows))
