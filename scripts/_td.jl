include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames, Statistics
const B = BreadEconomySim
def = ladder_definition(512, 120, :invoicing)
mode = ARGS[1]
(_, _, ks) = only(r for r in def.rungs if startswith(r[1], "8 "))
margins = (; pricing_target_farm = :margin, pricing_target_bakery = :margin, pricing_target_theatre = :margin)
extra = mode == "flat" ? (;) : mode == "tiers" ? (; demurrage_tiers = DEMURRAGE_TIERS_TEST) : mode == "margins_flat" ? margins : (; margins..., demurrage_tiers = DEMURRAGE_TIERS_TEST)
m = run_simulation(SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks..., extra...))
ps = B.persons(m); lp = B.land_valuation_price(m)
w(x) = B.net_wealth(m, x) - B.share_wealth(m, x) + B.measured_share_wealth(m, x)
srt = sort(ps; by = x -> -w(x)); top = srt[1:51]; rest = srt[52:end]
comp(g) = (cash = round(Int, sum(B.cash(x) for x in g)), land = round(Int, sum(x.land for x in g) * lp), shares = round(Int, sum(B.measured_share_wealth(m, x) for x in g)), wealth = round(Int, sum(w(x) for x in g)))
d = round_data(m)
println("SuMSy step 8 seed 1, ", mode, " — alive ", d.persons_alive[end], ", bread ", round(d.price_bread[end], digits = 2), ", money stock ", round(Int, d.money_in_circulation[end]), ", richest tenth ", comp(top), ", the rest ", comp(rest), ", demurrage last year ", round(Int, sum(d.money_destroyed[end-11:end])), ", Gini cash ", round(d.gini_cash_persons[end], digits = 3), " wealth ", round(d.gini_net_wealth_persons[end], digits = 3), ", poorest tenth ", round(d.wealth_bottom10_meals[end], digits = 1), ", land price ", round(lp, digits = 1))
