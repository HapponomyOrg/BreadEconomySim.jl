# The five runs of the plain-language report, 6 seeds each, per-round data in long format → results/report_rounds.csv
using BreadEconomySim, DataFrames, CSV
BEH = (; demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true,
        random_hiring_ties = true, no_labour_tolerance = true, offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true,
        distress_land_sales = true, maximum_capacity = 4.0, number_of_landowners = 4, land_units_per_landowner_override = 6, wage_reservation_net_of_tax = true,
        minimum_fee_in_breads = 2.0, partial_unemployment_fee = true, initial_endowment = :norm, startup_loan_term = 50,
        account_fee_person = 0.0, account_fee_enterprise = 0.0, land_sales = :reservation, plan_for_gluttony = true)
SUMSY = (; monetary_system = :sumsy, wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0,
          partial_unemployment_fee = false, government_employment_share = 0.0, enterprise_tax = :none, account_fee_person = 0.5, account_fee_enterprise = 1.5, demurrage_rate = 0.02)
fixed = (; maximum_rounds = 100, stop_when_half_dead = false, stop_when_stationary = false)
runs = [
    ("original_spec",     (;)),
    ("debt",              BEH),
    ("debt_balance_tax",  (; BEH..., enterprise_tax = :reserves, enterprise_reserve_tax_rate = 0.05, reserve_tax_exempts_standard_reserve = true)),
    ("sumsy_gi1",         (; BEH..., SUMSY..., guaranteed_income = 5.0, demurrage_free_buffer = 30.0)),
    ("sumsy_gi05_savings",(; BEH..., SUMSY..., guaranteed_income = 2.5, demurrage_free_buffer = 15.0, wage_reservation_net_of_gi = true, wage_reservation_includes_savings = true, savings_build_rounds = 3)),
    ("debt_theatre",      (; BEH..., partial_unemployment_fee = false, entertainment = true, planning_margin = 0.1, deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02)),
    ("sumsy_theatre",     (; BEH..., SUMSY..., guaranteed_income = 5.0, demurrage_free_buffer = 30.0, entertainment = true, planning_margin = 0.1)),
]
out = DataFrame[]
for (name, kw) in runs, s in 1:6
    m = run_simulation(SimulationParameters(; seed = s, fixed..., kw...)); d = round_data(m)
    d.variant .= name; d.seed .= s
    push!(out, d); println(name, " seed ", s, " rounds ", nrow(d), " alive ", d.persons_alive[end]); flush(stdout)
end
CSV.write(joinpath(@__DIR__, "..", "results", "report_rounds_v3.csv"), vcat(out...; cols = :union))
