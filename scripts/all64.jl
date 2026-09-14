# Every experiment of Sections 8–10B at sixty-four villagers, a hundred rounds, three seeds.
using BreadEconomySim, DataFrames, CSV, Statistics
nseeds = 3; rounds = 100; N = 64
BASE = (; number_of_persons = N, number_of_landowners = 16, land_per_person = 1.5, initial_production_target = 10, shares_per_person = 10, shareholder_count = 4,
         demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true, random_hiring_ties = true, no_labour_tolerance = true, offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true, distress_land_sales = true, maximum_capacity = 4.0,
         wage_reservation_net_of_tax = true, initial_endowment = :norm, startup_loan_term = 60, land_sales = :reservation, gluttony_probability = 0.1, plan_for_gluttony = true, planning_margin = 0.1, entertainment = true, number_of_theatres = 2, maximum_rounds = rounds, stop_when_half_dead = false, stop_when_stationary = false)
DEBT = (; wage_tax_rate = 0.15, capital_tax_rate = 0.15, unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, government_employment_share = 0.1, deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02, account_fee_person = 0.0, account_fee_enterprise = 0.0, government_bonds = true)
SUMSY = (; monetary_system = :sumsy, wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0, government_employment_share = 0.1, demurrage_tax_rate = 0.01, guaranteed_income = 5.0, demurrage_free_buffer = 30.0, demurrage_rate = 0.02, account_fee_person = 0.5, account_fee_enterprise = 1.5, instalment_purchases = true, land_price_rent_multiple = 50.0)
MARKET = (; ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002, startup_financing = :paid_in_capital)
GREEDY = (; MARKET..., greed = true, greed_share = 1.0)
experiments = Dict(
 "share_market" => [("cash only, no spread", (; MARKET..., required_yield_dispersion = 0.0)), ("cash only", MARKET), ("cash only, resale +0.5%", (; MARKET..., expected_price_growth = 0.005)),
                    ("deferred payment", (; MARKET..., deferred_payment = true)), ("deferred payment, resale +0.5%", (; MARKET..., deferred_payment = true, expected_price_growth = 0.005))],
 "coops" => [("co-ops vs profit, paid-in founding", (; MARKET..., number_of_farms = 4, number_of_bakeries = 4, ownership = :mixed))],
 "greed" => [("no greed", MARKET), ("greedy rich 25 %", (; MARKET..., greed = true, greed_share = 0.25)), ("hoarding 0.0", (; GREEDY..., greed_hoarding = 0.0)), ("hoarding 0.25", (; GREEDY..., greed_hoarding = 0.25)), ("hoarding 0.5", (; GREEDY..., greed_hoarding = 0.5)), ("hoarding 0.75", (; GREEDY..., greed_hoarding = 0.75)), ("hoarding 1.0", (; GREEDY..., greed_hoarding = 1.0))],
 "measures" => [("hoarding 0.0 + rationing", (; GREEDY..., greed_hoarding = 0.0, bread_rationing = true)), ("hoarding 0.5 + rationing", (; GREEDY..., greed_hoarding = 0.5, bread_rationing = true)),
                ("hoarding 0.0 + tiered price", (; GREEDY..., greed_hoarding = 0.0, tiered_bread_price = true)), ("hoarding 0.5 + tiered price", (; GREEDY..., greed_hoarding = 0.5, tiered_bread_price = true)),
                ("hoarding 0.0 + land 2 + capacity 5 + ration", (; GREEDY..., greed_hoarding = 0.0, land_per_person = 2.0, maximum_capacity = 5.0, bread_rationing = true)),
                ("hoarding 0.5 + wage ceiling 4", (; GREEDY..., greed_hoarding = 0.5, wage_ceiling_in_breads = 4.0)), ("hoarding 0.0 + wage ceiling 4", (; GREEDY..., greed_hoarding = 0.0, wage_ceiling_in_breads = 4.0)),
                ("no greed, no self-service", (; MARKET..., no_self_service = true))],
 "indexed" => [("no greed, indexed income", (; MARKET..., guaranteed_income_in_breads = 1.0)), ("hoarding 0.0, indexed income", (; GREEDY..., greed_hoarding = 0.0, guaranteed_income_in_breads = 1.0)), ("hoarding 0.5, indexed income", (; GREEDY..., greed_hoarding = 0.5, guaranteed_income_in_breads = 1.0))],
 "saturation" => [("no greed, saturated upper", (; MARKET..., start_at_saturation = :upper, initial_price_multiplier = 0.63)), ("no greed, saturated lower", (; MARKET..., start_at_saturation = :lower, initial_price_multiplier = 0.63)),
                  ("hoarding 0.0, saturated upper", (; GREEDY..., greed_hoarding = 0.0, start_at_saturation = :upper, initial_price_multiplier = 0.63)), ("hoarding 0.5, saturated upper", (; GREEDY..., greed_hoarding = 0.5, start_at_saturation = :upper, initial_price_multiplier = 0.63)), ("hoarding 1.0, saturated upper", (; GREEDY..., greed_hoarding = 1.0, start_at_saturation = :upper, initial_price_multiplier = 0.63)),
                  ("hoarding 0.0, saturated lower", (; GREEDY..., greed_hoarding = 0.0, start_at_saturation = :lower, initial_price_multiplier = 0.63)), ("hoarding 0.5, saturated lower", (; GREEDY..., greed_hoarding = 0.5, start_at_saturation = :lower, initial_price_multiplier = 0.63))],
 "prices" => [("no greed ×0.5", (; MARKET..., initial_price_multiplier = 0.5)), ("no greed ×2", (; MARKET..., initial_price_multiplier = 2.0)),
              ("hoarding 0.0 ×0.5", (; GREEDY..., greed_hoarding = 0.0, initial_price_multiplier = 0.5)), ("hoarding 0.0 ×2", (; GREEDY..., greed_hoarding = 0.0, initial_price_multiplier = 2.0)),
              ("hoarding 0.5 ×0.5", (; GREEDY..., greed_hoarding = 0.5, initial_price_multiplier = 0.5)), ("hoarding 0.5 ×2", (; GREEDY..., greed_hoarding = 0.5, initial_price_multiplier = 2.0))])
order = length(ARGS) >= 1 ? split(ARGS[1], ",") : ["greed", "measures", "indexed", "share_market", "coops", "saturation", "prices"]
for exp in order
    out = DataFrame[]
    for (name, kw) in experiments[exp], (system, base) in (("debt", DEBT), ("sumsy", SUMSY)), s in 1:nseeds
        (exp in ("indexed", "saturation") && system == "debt") && continue           # SuMSy-only experiments
        t = @elapsed m = run_simulation(SimulationParameters(; seed = s, BASE..., base..., kw...)); d = round_data(m)
        d.variant .= name; d.system .= system; d.seed .= s; d.identity .= money_identity_gap(m); d.seconds .= t; push!(out, d)
        println(exp, " | ", name, " ", system, " seed ", s, " ", round(t, digits = 1), "s alive ", d.persons_alive[end], " rounds ", nrow(d)); flush(stdout)
    end
    CSV.write(joinpath(@__DIR__, "..", "results", "all64_$(exp)_rounds.csv"), vcat(out...; cols = :union))
end
