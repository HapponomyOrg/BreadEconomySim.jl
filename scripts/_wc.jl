include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames, Statistics
const B = BreadEconomySim
def = ladder_definition(512, 120, :invoicing)
mode = ARGS[1]
(_, _, ks) = only(r for r in def.rungs if startswith(r[1], "8 "))
extra = mode == "none" ? (;) : (; pricing_target_farm = :margin, pricing_target_bakery = :margin, pricing_target_theatre = :margin)
m = run_simulation(SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks..., extra...))
ps = B.persons(m); lp = B.land_valuation_price(m)
w(x) = B.net_wealth(m, x) - B.share_wealth(m, x) + B.measured_share_wealth(m, x)
top = sort(ps; by = x -> -w(x))[1:51]; rest = sort(ps; by = x -> -w(x))[52:end]
comp(g) = (cash = round(Int, sum(B.cash(x) for x in g)), land = round(Int, sum(x.land for x in g) * lp), shares = round(Int, sum(B.measured_share_wealth(m, x) for x in g)), wealth = round(Int, sum(w(x) for x in g)))
d = round_data(m)
println("SuMSy step 8 seed 1, margins ", mode, " — richest tenth: ", comp(top), "; the other nine tenths: ", comp(rest), "; demurrage destroyed last year ", round(Int, sum(d.money_destroyed[end-11:end])), ", dividends last year ", round(Int, sum(d.dividends_forprofit[end-11:end])), ", Gini wealth ", round(d.gini_net_wealth_persons[end], digits = 3))
