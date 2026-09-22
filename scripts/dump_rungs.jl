# Writes results/ladder2_<N>_rungs.csv: for every rung and both villages, what is there — firms, founders, taxes, rates,
# starting prices — read from the effective SimulationParameters, so the report's "what is there" panels come from the
# configuration and not from memory (docs/report_style.md §4). Usage: julia --project=. scripts/dump_rungs.jl 10 100 all 128
include(joinpath(@__DIR__, "ladder2_rungs.jl"))
using CSV, DataFrames
rows = Any[]
for (name, kd, ks) in rungs, (system, base, kw) in (("debt", BARE_DEBT, kd), ("sumsy", BARE_SUMSY, ks))
    (startswith(name, "X1") && system == "debt") && continue
    (startswith(name, "X2") && system == "sumsy") && continue
    p = SimulationParameters(; base..., kw...)
    theatres = p.entertainment ? p.number_of_theatres : 0
    firms = p.number_of_farms + p.number_of_bakeries + theatres
    owned = p.ownership in (:shareholders, :mixed) ? firms - (p.ownership == :mixed ? p.cooperative_farms + p.cooperative_bakeries + p.cooperative_theatres : 0) : 0
    seats = theatres > 0 && p.shows_per_round > 0 ? ceil(Int, p.number_of_persons / theatres * (1 + p.theatre_seat_margin)) : 0
    push!(rows, (; rung = name, system, villagers = p.number_of_persons, landowners = p.number_of_landowners,
        farms = p.number_of_farms, bakeries = p.number_of_bakeries, theatres, coops = p.ownership == :mixed ? p.cooperative_farms + p.cooperative_bakeries + p.cooperative_theatres : 0,
        ownership = String(p.ownership), founders = owned * p.shareholder_count, share_market = p.share_market,
        shows = p.shows_per_round, seats_per_theatre = seats,
        wage_tax = p.wage_tax_rate, capital_tax = p.capital_tax_rate, dividend_tax = p.dividend_tax_rate, consumption_tax = p.consumption_tax_rate, wealth_tax = p.wealth_tax_rate,
        public_jobs_share = p.government_employment_share, benefit_loaves = p.unemployment_fee_in_breads, bonds = p.government_bonds,
        reserve_rounds = p.government_reserve_in_rounds, tax_policy = String(p.tax_policy), levers = p.tax_policy == :none ? "" : join(["$(f) $(get(p.tax_levers, f, 0.0))" for f in (:income, :consumption, :wealth, :profit, :parking)], ", "),
        profit_tax = p.profit_tax_rate, income_tax_period = p.income_tax_period, profit_tax_period = p.profit_tax_period,
        deposit_interest = p.deposit_interest_rate, deposit_period = p.deposit_interest_period, bank_rate_start = p.initial_interest_rate, bank_rate_cap = p.maximum_interest_rate, government_rate = p.government_rate,
        guaranteed_income = p.monetary_system == :sumsy ? p.guaranteed_income : 0.0, buffer = p.monetary_system == :sumsy ? p.demurrage_free_buffer : 0.0,
        parking_fee = p.monetary_system == :sumsy ? p.demurrage_rate : 0.0, parking_tax = p.monetary_system == :sumsy ? p.demurrage_tax_rate : 0.0,
        account_fee_person = p.account_fee_person, account_fee_enterprise = p.account_fee_enterprise, charge_on_balances = p.enterprise_tax == :none ? 0.0 : p.enterprise_reserve_tax_rate,
        price_bread = p.initial_prices[:bread] * p.initial_price_multiplier, price_grain = p.initial_prices[:grain] * p.initial_price_multiplier, price_wage = p.initial_prices[:wage] * p.initial_price_multiplier,
        price_rent = p.initial_prices[:rent] * p.initial_price_multiplier, price_ticket = p.initial_prices[:ticket] * p.initial_price_multiplier,
        unmet_share = p.unmet_demand_share, unsold_share = p.unsold_share, ask_floor = String(p.ask_floor), bread_ceiling = p.bread_bid_base_multiplier, planning_margin = p.planning_margin,
        greed = p.greed ? "$(round(Int, 100 * p.greed_share)) % greedy, hoarding $(p.greed_hoarding)" : ""))
end
path = joinpath(@__DIR__, "..", "results", "ladder2_$(N)_rungs.csv")
CSV.write(path, DataFrame(rows))
println("wrote ", path, " (", length(rows), " rows)")
