# Sensitivity to the initial price vector: the whole vector (wages included) at ×0.5, ×1, ×2 with the money anchors unchanged,
# so a villager starts with 12 / 6 / 3 loaves of money and the SuMSy income buys 2 / 1 / ½ a loaf. Rungs 2, 4, 8; both systems; 6 seeds; 50 rounds.
using BreadEconomySim, DataFrames, CSV, Statistics
RULES = (; demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true, random_hiring_ties = true, no_labour_tolerance = true, offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true, distress_land_sales = true, maximum_capacity = 4.0, number_of_landowners = 4, land_units_per_landowner_override = 6, wage_reservation_net_of_tax = true, initial_endowment = :norm, startup_loan_term = 60, land_sales = :reservation, gluttony_probability = 0.1, plan_for_gluttony = true, planning_margin = 0.1, maximum_rounds = 50, stop_when_half_dead = false, stop_when_stationary = false)
DEBT = (; wage_tax_rate = 0.15, capital_tax_rate = 0.15, unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, government_employment_share = 0.1, deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02, account_fee_person = 0.0, account_fee_enterprise = 0.0)
SUMSY = (; monetary_system = :sumsy, wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0, government_employment_share = 0.1, demurrage_tax_rate = 0.01, guaranteed_income = 5.0, demurrage_free_buffer = 30.0, demurrage_rate = 0.02, account_fee_person = 0.5, account_fee_enterprise = 1.5, instalment_purchases = true, land_price_rent_multiple = 50.0)
rungs = [("2 + government", (;)), ("4 + theatre", (; entertainment = true)), ("8 + shareholders & share market", (; entertainment = true, number_of_theatres = 2, ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002))]
out = DataFrame[]
for (rung, rkw) in rungs, (system, base) in (("debt", DEBT), ("sumsy", SUMSY)), mult in (0.5, 1.0, 2.0), s in 1:6
    m = run_simulation(SimulationParameters(; seed = s, RULES..., base..., rkw..., initial_price_multiplier = mult)); d = round_data(m)
    d.rung .= rung; d.system .= system; d.mult .= mult; d.seed .= s; d.identity .= money_identity_gap(m); push!(out, d)
    println(rung, " ", system, " ×", mult, " seed ", s, " alive ", d.persons_alive[end]); flush(stdout)
end
CSV.write(joinpath(@__DIR__, "..", "results", "price_scale_rounds.csv"), vcat(out...; cols = :union))
