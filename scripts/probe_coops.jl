using BreadEconomySim, DataFrames, Statistics
N = 64
BASE = (; number_of_persons = N, number_of_landowners = 16, land_per_person = 1.5, initial_production_target = 10, shares_per_person = 10, shareholder_count = 4,
         demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true, random_hiring_ties = true, no_labour_tolerance = true, offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true, distress_land_sales = true, maximum_capacity = 4.0,
         wage_reservation_net_of_tax = true, initial_endowment = :norm, startup_loan_term = 60, land_sales = :reservation, gluttony_probability = 0.1, plan_for_gluttony = true, planning_margin = 0.1, entertainment = true, number_of_theatres = 2, maximum_rounds = 40, stop_when_half_dead = false, stop_when_stationary = false)
DEBT = (; wage_tax_rate = 0.15, capital_tax_rate = 0.15, unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, government_employment_share = 0.1, deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02, account_fee_person = 0.0, account_fee_enterprise = 0.0, government_bonds = true)
MARKET = (; ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002, startup_financing = :paid_in_capital)
COOP = (; MARKET..., number_of_farms = 4, number_of_bakeries = 4, ownership = :mixed)
variants = [("member (current)", (;)),
            ("worker+consumer", (; cooperative_form_farms = :worker, cooperative_form_bakeries = :worker, cooperative_form_theatres = :consumer, cooperative_theatres = 1)),
            ("consumer bakeries", (; cooperative_form_bakeries = :consumer, cooperative_theatres = 1, cooperative_form_theatres = :consumer))]
for (name, kw) in variants
    m = run_simulation(SimulationParameters(; seed = 1, BASE..., DEBT..., COOP..., kw...))
    d = round_data(m)
    println(rpad(name, 20), " alive ", d.persons_alive[end], " rounds ", nrow(d),
            " | coopW ", d.coop_worker_open[end], " coopC ", d.coop_consumer_open[end], " coopM ", d.coop_member_open[end],
            " | membersW ", d.coop_members_worker[end], " membersC ", d.coop_members_consumer[end],
            " | hours ", round(d.coop_worker_hours[end], digits=1), " reserved ", round(d.reserved_labour[end], digits=1),
            " | patwage ", round(sum(d.patronage_wages), digits=1), " rebate ", round(sum(d.rebates), digits=1),
            " | reserve ", round(d.coop_retained_reserve[end], digits=1), " cap ", round(sum(d.membership_capital), digits=1),
            " | unempM ", d.unemployed_members[end], " unempN ", d.unemployed_nonmembers[end],
            " | gap ", money_identity_gap(m))
    flush(stdout)
end
