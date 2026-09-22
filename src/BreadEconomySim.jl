"""
    BreadEconomySim

Agent-based bread economy (specification v2, 11 September 2026) on EconoSim.jl / Agents.jl.
"""
module BreadEconomySim

using Agents
using EconoSim
using DataFrames
using Random
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
include("lifecycle.jl")
include("sumsy.jl")
include("data.jl")

# Round structure (spec v2 §7)
append!(ROUND_BEHAVIORS, Function[
    begin_round!,
    pay_guaranteed_income!,
    manage_buffer_pool!,
    set_interest_rates!,
    land_market!,
    m -> labour_market!(m, (:farm, :bank, :theatre)),
    produce_grain!,
    grain_market!,
    m -> labour_market!(m, (:bakery,)),
    bake!,
    charge_account_fees!,
    government_hiring!,
    pay_unemployment_fees!,
    bread_market!,
    ticket_market!,
    greed_spending!,
    charge_income_tax!,
    settle_end_of_round!,
    settle_invoices!,
    liquidate_insolvent_firms!,
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
