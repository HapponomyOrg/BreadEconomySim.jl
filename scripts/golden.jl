using BreadEconomySim, DataFrames
const BEH = (; demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true,
              ask_increase_only_on_unmet_demand = true, random_hiring_ties = false, no_labour_tolerance = true,
              offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true, distress_land_sales = true,
              maximum_capacity = 4.0, number_of_landowners = 4, land_units_per_landowner_override = 6,
              wage_reservation_net_of_tax = true, minimum_fee_in_breads = 2.0, partial_unemployment_fee = true,
              initial_endowment = :norm, startup_loan_term = 50, land_sales = :reservation, plan_for_gluttony = true,
              stop_when_half_dead = false, stop_when_stationary = false)
const SUM = (; monetary_system = :sumsy, wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0,
              minimum_fee_in_breads = 0.0, partial_unemployment_fee = false, government_employment_share = 0.0,
              account_fee_person = 0.5, account_fee_enterprise = 1.5, demurrage_rate = 0.02,
              instalment_purchases = true, land_price_rent_multiple = 50.0)
configs = ["debt" => BEH, "sumsy" => (; BEH..., SUM...), "debt_bonds" => (; BEH..., government_bonds = true, deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02)]
for streams in (false, true), (name, kw) in configs
    d = round_data(run_simulation(SimulationParameters(; seed = 3, maximum_rounds = 25, random_streams = streams, kw...))); r = d[end, :]
    println("streams=", streams, " \"", name, "\" => (; price_bread = ", r.price_bread, ", price_wage = ", r.price_wage, ", money = ", r.money_in_circulation,
            ", debt = ", r.outstanding_debt, ", gov_debt = ", r.government_debt, ", gini = ", r.gini_net_wealth_persons, ", cash_persons = ", r.cash_persons, ", tax = ", r.tax, "),  alive=", r.persons_alive, " bread=", r.bread_baked)
end
