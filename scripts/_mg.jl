include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
sys, mode = ARGS[1], ARGS[2]
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], "8 "))
base, kw = sys == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
extra = mode == "none" ? (;) : (; pricing_target_farm = :margin, pricing_target_bakery = :margin, pricing_target_theatre = :margin, margin_profit_mode = Symbol(mode))
d = round_data(run_simulation(SimulationParameters(; seed = 1, base..., kw..., extra...)))
inf(c) = round(100 * ((d[end, c] / d[12, c])^(1 / 9) - 1), digits = 1)
println("step 8 ", sys, " seed 1, margins ", mode, " — alive ", d.persons_alive[end], ", bread ", round(d.price_bread[end], digits = 2), " (", inf(:price_bread), " %/yr), public debt ", round(Int, d.government_debt[end] / 1000), "k, Gini wealth ", round(d.gini_net_wealth_persons[end], digits = 3), ", richest tenth ", round(Int, d.wealth_top10_meals[end]), " meals, poorest ", round(d.wealth_bottom10_meals[end], digits = 1), ", dividends (last 12 months) ", round(Int, sum(d.dividends_forprofit[end-11:end])), ", liquidations ", d.liquidations[end])
