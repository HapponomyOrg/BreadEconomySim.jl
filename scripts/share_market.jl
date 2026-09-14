# Share market with forward valuation: dispersion of required yields (0 / 0.002 / 0.005), with and without the resale-expectation term,
# on two foundings (start-up loans to businesses; paid-in capital by founders), both systems, 6 seeds, 50 rounds.
using BreadEconomySim, DataFrames, CSV, Statistics
nseeds = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 6; rounds = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 50
RULES = (; demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true, random_hiring_ties = true, no_labour_tolerance = true, offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true, distress_land_sales = true, maximum_capacity = 4.0, number_of_landowners = 4, land_units_per_landowner_override = 6, wage_reservation_net_of_tax = true, initial_endowment = :norm, startup_loan_term = 60, land_sales = :reservation, gluttony_probability = 0.1, plan_for_gluttony = true, planning_margin = 0.1, entertainment = true, number_of_theatres = 2, ownership = :shareholders, share_market = true, forward_valuation = true, maximum_rounds = rounds, stop_when_half_dead = false, stop_when_stationary = false)
DEBT = (; wage_tax_rate = 0.15, capital_tax_rate = 0.15, unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, government_employment_share = 0.1, deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02, account_fee_person = 0.0, account_fee_enterprise = 0.0, government_bonds = true)
SUMSY = (; monetary_system = :sumsy, wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0, government_employment_share = 0.1, demurrage_tax_rate = 0.01, guaranteed_income = 5.0, demurrage_free_buffer = 30.0, demurrage_rate = 0.02, account_fee_person = 0.5, account_fee_enterprise = 1.5, instalment_purchases = true, land_price_rent_multiple = 50.0)
variants = Vector{Tuple{String, NamedTuple}}()
for (dp, dkw) in (("cash only", (;)), ("deferred payment", (; deferred_payment = true))), (rs, rkw) in (("no resale term", (;)), ("resale +0.5%", (; expected_price_growth = 0.005)))
    push!(variants, ("paid-in capital, spread 0.002, $(dp), $(rs)", (; startup_financing = :paid_in_capital, required_yield_dispersion = 0.002, dkw..., rkw...)))
end
out = DataFrame[]
for (name, kw) in variants, (system, base) in (("debt", DEBT), ("sumsy", SUMSY)), s in 1:nseeds
    m = run_simulation(SimulationParameters(; seed = s, RULES..., base..., kw...)); d = round_data(m)
    d.variant .= name; d.system .= system; d.seed .= s; d.identity .= money_identity_gap(m)
    push!(out, d); println(name, " ", system, " seed ", s, " trades ", sum(d.share_trades), " alive ", d.persons_alive[end]); flush(stdout)
end
CSV.write(joinpath(@__DIR__, "..", "results", "share_deferred_rounds.csv"), vcat(out...; cols = :union))
