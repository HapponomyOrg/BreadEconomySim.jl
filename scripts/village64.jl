# 64-person village: same farms, bakeries, banks and theatres; land scaled (1.5 units a head, 16 landowners); 10 share units per villager.
using BreadEconomySim, DataFrames, CSV, Statistics
nseeds = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 3; rounds = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 50
N = 64
RULES = (; demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true, random_hiring_ties = true, no_labour_tolerance = true, offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true, distress_land_sales = true, maximum_capacity = 4.0,
          number_of_persons = N, number_of_landowners = 16, land_per_person = 1.5, initial_production_target = N ÷ 6, shares_per_person = 10,
          wage_reservation_net_of_tax = true, initial_endowment = :norm, startup_loan_term = 60, land_sales = :reservation, gluttony_probability = 0.1, plan_for_gluttony = true, planning_margin = 0.1, entertainment = true, number_of_theatres = 2, maximum_rounds = rounds, stop_when_half_dead = false, stop_when_stationary = false)
DEBT = (; wage_tax_rate = 0.15, capital_tax_rate = 0.15, unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, government_employment_share = 0.1, deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02, account_fee_person = 0.0, account_fee_enterprise = 0.0, government_bonds = true)
SUMSY = (; monetary_system = :sumsy, wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0, government_employment_share = 0.1, demurrage_tax_rate = 0.01, guaranteed_income = 5.0, demurrage_free_buffer = 30.0, demurrage_rate = 0.02, account_fee_person = 0.5, account_fee_enterprise = 1.5, instalment_purchases = true, land_price_rent_multiple = 50.0)
MARKET = (; ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002, startup_financing = :paid_in_capital, shareholder_count = 4)
variants = [("rung 4 + theatres", (;)), ("rung 8 shares, trading market", MARKET), ("rung 8 + deferred payment", (; MARKET..., deferred_payment = true)),
            ("rung 9 co-ops vs profit", (; MARKET..., number_of_farms = 4, number_of_bakeries = 4, ownership = :mixed)),
            ("everyone greedy, hoarding 0.5", (; MARKET..., greed = true, greed_share = 1.0, greed_hoarding = 0.5)), ("everyone greedy, hoarding 1.0", (; MARKET..., greed = true, greed_share = 1.0, greed_hoarding = 1.0))]
out = DataFrame[]
for (name, kw) in variants, (system, base) in (("debt", DEBT), ("sumsy", SUMSY)), s in 1:nseeds
    t = @elapsed m = run_simulation(SimulationParameters(; seed = s, RULES..., base..., kw...)); d = round_data(m)
    d.variant .= name; d.system .= system; d.seed .= s; d.identity .= money_identity_gap(m); d.seconds .= t
    push!(out, d); println(name, " ", system, " seed ", s, " ", round(t, digits = 1), "s alive ", d.persons_alive[end]); flush(stdout)
end
CSV.write(joinpath(@__DIR__, "..", "results", "village64_rounds.csv"), vcat(out...; cols = :union))
