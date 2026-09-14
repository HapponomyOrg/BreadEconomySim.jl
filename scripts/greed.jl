# Greed experiment: the wealthiest quarter / half of the village become greedy (half hoarders, half over-consumers), both systems.
using BreadEconomySim, DataFrames, CSV, Statistics
nseeds = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 6; rounds = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 50
RULES = (; demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true, random_hiring_ties = true, no_labour_tolerance = true, offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true, distress_land_sales = true, maximum_capacity = 4.0, number_of_landowners = 4, land_units_per_landowner_override = 6, wage_reservation_net_of_tax = true, initial_endowment = :norm, startup_loan_term = 60, land_sales = :reservation, gluttony_probability = 0.1, plan_for_gluttony = true, planning_margin = 0.1, entertainment = true, ownership = :shareholders, share_market = true, maximum_rounds = rounds, stop_when_half_dead = false, stop_when_stationary = false)
DEBT = (; wage_tax_rate = 0.15, capital_tax_rate = 0.15, unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, government_employment_share = 0.1, deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02, account_fee_person = 0.0, account_fee_enterprise = 0.0)
SUMSY = (; monetary_system = :sumsy, wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0, government_employment_share = 0.1, demurrage_tax_rate = 0.01, guaranteed_income = 5.0, demurrage_free_buffer = 30.0, demurrage_rate = 0.02, account_fee_person = 0.5, account_fee_enterprise = 1.5, instalment_purchases = true, land_price_rent_multiple = 50.0)
variants = [("no greed", (;)), ("no greed, no self-service", (; no_self_service = true)), ("everyone greedy", (; greed = true, greed_share = 1.0)), ("everyone greedy + tiered price", (; greed = true, greed_share = 1.0, tiered_bread_price = true)), ("everyone a consumer", (; greed = true, greed_share = 1.0, greed_hoarder_fraction = 0.0)), ("everyone a consumer + tiered price", (; greed = true, greed_share = 1.0, greed_hoarder_fraction = 0.0, tiered_bread_price = true))]
out = DataFrame[]
for (name, kw) in variants, (system, base) in (("debt", DEBT), ("sumsy", SUMSY)), s in 1:nseeds
    m = run_simulation(SimulationParameters(; seed = s, RULES..., base..., kw...)); d = round_data(m)
    d.variant .= name; d.system .= system; d.seed .= s; d.identity .= money_identity_gap(m)
    push!(out, d); println(name, " ", system, " seed ", s, " alive ", d.persons_alive[end]); flush(stdout)
end
CSV.write(joinpath(@__DIR__, "..", "results", "greed_tier_rounds.csv"), vcat(out...; cols = :union))
