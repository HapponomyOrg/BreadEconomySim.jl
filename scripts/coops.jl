# Section 9: cooperatives (members buy in at par, one equal dividend per member) against profit firms (founders borrow
# personally and pay capital in), 2+2 farms, 2+2 bakeries, 2 profit theatres; both monetary systems; 6 seeds.
using BreadEconomySim, DataFrames, CSV, Statistics
nseeds = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 6; rounds = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 50
BEH = (; demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true, random_hiring_ties = true, no_labour_tolerance = true, offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true, distress_land_sales = true, maximum_capacity = 4.0, number_of_landowners = 4, land_units_per_landowner_override = 6, wage_reservation_net_of_tax = true, initial_endowment = :norm, land_sales = :reservation, gluttony_probability = 0.1, plan_for_gluttony = true, planning_margin = 0.1, entertainment = true, number_of_theatres = 2, number_of_farms = 4, number_of_bakeries = 4, ownership = :mixed, share_market = true, startup_financing = :paid_in_capital, stop_when_half_dead = false, stop_when_stationary = false, maximum_rounds = rounds)
DEBT = (; wage_tax_rate = 0.15, capital_tax_rate = 0.15, unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, government_employment_share = 0.1, deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02, account_fee_person = 0.0, account_fee_enterprise = 0.0)
SUMSY = (; monetary_system = :sumsy, wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0, government_employment_share = 0.1, demurrage_tax_rate = 0.01, guaranteed_income = 5.0, demurrage_free_buffer = 30.0, demurrage_rate = 0.02, account_fee_person = 0.5, account_fee_enterprise = 1.5, instalment_purchases = true, land_price_rent_multiple = 50.0)
out = DataFrame[]
for (system, kw) in (("debt", DEBT), ("sumsy", SUMSY)), s in 1:nseeds
    m = run_simulation(SimulationParameters(; seed = s, BEH..., kw...)); d = round_data(m)
    d.system .= system; d.seed .= s; d.identity .= money_identity_gap(m)
    # closures by ownership from the event log
    ev = event_log(m); cl = ev[ev.kind .== :closure, :]
    d.coop_closures .= count(r -> m[r.actor].ownership == :cooperative, eachrow(cl)); d.forprofit_closures .= count(r -> m[r.actor].ownership == :shareholders, eachrow(cl))
    push!(out, d); println(system, " seed ", s, " alive ", d.persons_alive[end], " coops ", d.coop_open[end], " fp ", d.forprofit_open[end]); flush(stdout)
end
CSV.write(joinpath(@__DIR__, "..", "results", "coops_rounds.csv"), vcat(out...; cols = :union))
