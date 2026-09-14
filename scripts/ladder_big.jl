# 1,000-person village: rung 4 (government + deposit interest + theatre) and rung 9 (co-ops vs profit firms, paid-in founding), both systems, 3 seeds, 50 rounds.
using BreadEconomySim, DataFrames, CSV, Statistics
N = 1000
RULES = (; demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true, random_hiring_ties = true, no_labour_tolerance = true, offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true, distress_land_sales = true, maximum_capacity = 4.0,
          number_of_persons = N, number_of_landowners = N ÷ 10, land_units_per_landowner_override = 12, number_of_farms = 5, number_of_bakeries = 4, number_of_banks = 3, number_of_theatres = 2, initial_production_target = N ÷ 4,
          wage_reservation_net_of_tax = true, initial_endowment = :norm, startup_loan_term = 60, land_sales = :reservation, gluttony_probability = 0.1, plan_for_gluttony = true, planning_margin = 0.1, entertainment = true, maximum_rounds = 50, stop_when_half_dead = false, stop_when_stationary = false)
DEBT = (; wage_tax_rate = 0.15, capital_tax_rate = 0.15, unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, government_employment_share = 0.1, deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02, account_fee_person = 0.0, account_fee_enterprise = 0.0)
SUMSY = (; monetary_system = :sumsy, wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0, government_employment_share = 0.1, demurrage_tax_rate = 0.01, guaranteed_income = 5.0, demurrage_free_buffer = 30.0, demurrage_rate = 0.02, account_fee_person = 0.5, account_fee_enterprise = 1.5, instalment_purchases = true, land_price_rent_multiple = 50.0)
OWN = (; number_of_farms = 4, number_of_bakeries = 4, ownership = :mixed, share_market = true, startup_financing = :paid_in_capital, shareholder_count = 10, cooperative_farms = 2, cooperative_bakeries = 2)
rows = NamedTuple[]; out = DataFrame[]
for (rung, kw) in [("4 + theatre", (;)), ("9 co-ops vs profit", OWN)], (system, base) in (("debt", DEBT), ("sumsy", SUMSY)), s in 1:3
    t = @elapsed m = run_simulation(SimulationParameters(; seed = s, RULES..., base..., kw...)); d = round_data(m)
    d.rung .= rung; d.system .= system; d.seed .= s; push!(out, d)
    gdp = d.bread_sold .* d.price_bread .+ d.ticket_revenue; gdp_a = mean(gdp[end-11:end]) * 12
    push!(rows, (rung = rung, system = system, seed = s, seconds = round(t, digits = 1), alive = d.persons_alive[end], hungry = sum(d.hungry), unemployed = round(mean(d.unemployed), digits = 1), bread = d.bread_baked[end], tickets = d.tickets_sold[end],
                 p_bread = round(d.price_bread[end], digits = 2), p_wage = round(d.price_wage[end], digits = 2), money = round(d.money_in_circulation[end]), gov_debt = round(d.government_debt[end]), debt_gdp = round(100 * d.government_debt[end] / gdp_a, digits = 1),
                 gini_cash = round(d.gini_cash_persons[end], digits = 3), gini_wealth = round(d.gini_net_wealth_persons[end], digits = 3), members = d.coop_members[end], founder_debt = round(d.founder_debt[end]), share_trades = sum(d.share_trades), dividends = round(sum(d.dividends)), identity = money_identity_gap(m)))
    println(rung, " ", system, " seed ", s, " ", round(t, digits = 1), "s alive ", d.persons_alive[end]); flush(stdout)
end
CSV.write(joinpath(@__DIR__, "..", "results", "big_summary.csv"), DataFrame(rows)); CSV.write(joinpath(@__DIR__, "..", "results", "big_rounds.csv"), vcat(out...; cols = :union))
