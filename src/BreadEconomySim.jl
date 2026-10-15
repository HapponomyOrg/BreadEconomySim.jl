"""
    BreadEconomySim

Agent-based bread economy (specification v2, 11 September 2026) on EconoSim.jl / Agents.jl.
"""
module BreadEconomySim

using Agents
using EconoSim
using DataFrames
using Random
using Logging
using Statistics
using StableRNGs
using OrderedCollections

export SimulationParameters, create_bread_economy, run_simulation, run_simulation!
export round_data, event_log, agent_end_state, money_identity_gap, gini, land_units_per_landowner
export Person, Enterprise

include("stable_random.jl")
include("parameters.jl")
include("agents.jl")
include("model.jl")
include("credit.jl")
include("cooperatives.jl")
include("negotiation.jl")
include("markets.jl")
include("government.jl")
include("gold.jl")
include("lifecycle.jl")
include("sumsy.jl")
include("data.jl")

# Round structure (spec v2 §7)
append!(ROUND_BEHAVIORS, Function[
    begin_round!,
    choose_greedy!,                     # 15 Oct: at greed_month
    choose_cash_hoarders!,              # 15 Oct: at cash_hoarder_month
    apply_debt_ceiling!,                # the ceiling on public borrowing sets this month's spending scale (26 Sept)
    pay_guaranteed_income!,
    manage_buffer_pool!,
    set_interest_rates!,
    land_market!,
    gold_market!,                       # 5 Oct: a pure store of value, traded like land
    m -> labour_market!(m, (:farm, :bank, :theatre)),
    m -> staff_with_volunteers!(m, (:farm,)),   # 15 Oct: volunteers where allowed
    produce_grain!,
    grain_market!,
    m -> labour_market!(m, (:bakery,)),
    m -> staff_with_volunteers!(m, (:bakery,)),
    bake!,
    charge_account_fees!,
    government_hiring!,
    pay_unemployment_fees!,
    pay_basic_income!,                  # 14 Oct: a basic income under debt money
    bread_market!,
    staff_theatres_with_volunteers!,   # 4 Oct: after the labour markets, before the shows
    ticket_market!,
    sell_rides!,
    volunteer!,
    greed_spending!,
    charge_income_tax!,
    collect_land_levy!,
    pay_levy_dividend!,                 # 14 Oct: the levy paid out per head
    settle_end_of_round!,
    settle_invoices!,
    liquidate_insolvent_firms!,
    refound_missing_producers!,
    market_entry!,
    clear!,
    service_debt!,
    service_peer_loans!,
    service_bonds!,
    pay_deposit_interest!,
    tax_enterprises!,
    tax_profits!,
    join_cooperatives!,
    pay_dividends!,
    share_market!,
    apply_demurrage!,
    collect_wealth_tax!,
    manage_government_reserve!,
    eat!,
    age_stock!,
    record_and_adapt!,
])

end # module
