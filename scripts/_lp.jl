include(joinpath(@__DIR__, "ladder_definition.jl"))
include(joinpath(@__DIR__, "pricing_strategy_test.jl"))
using DataFrames
const B = BreadEconomySim
def = ladder_definition(512, 120, :invoicing)
sys = ARGS[1]
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], "8 "))
base, kw = sys == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
m = run_simulation(SimulationParameters(; seed = 1, base..., kw..., REALISTIC..., pricing_margin_share = 0.5))
ev = event_log(m)
buys = ev[ev.event .== :instalment_purchase, :]; cash_buys = ev[ev.event .== :land_purchase, :]
farms_inst = count(r -> r.buyer_kind == :farm, eachrow(buys)); farms_cash = count(r -> r.buyer_kind == :farm, eachrow(cash_buys))
delev = count(r -> r.event == :deleverage_land_sale, eachrow(ev))
fs = [e for e in m.enterprise_list if e.alive && e.kind == :farm]
println("LAND ", sys, " seed 1, realistic — instalment purchases by farms ", farms_inst, " (by anyone ", nrow(buys), "), cash purchases by farms ", farms_cash, ", deleveraging sales ", delev, "; farms alive ", length(fs), " owning ", sum(e.land for e in fs), " plots; farms' bank loans outstanding ", round(sum(B.debt_of(e) for e in fs), digits = 1), ", peer loans ", round(sum(B.peer_debt_of(m, e) for e in fs), digits = 1), "; land price ", round(B.land_valuation_price(m), digits = 1), ", rent ", round(B.expected_price(m, :rent), digits = 2))
