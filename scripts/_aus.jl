include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
const B = BreadEconomySim
yr(d) = round(100 * ((d.price_bread[end] / d.price_bread[12])^(1 / 9) - 1), digits = 1)
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], "8 "))
which = ARGS[1]
if which == "sumsybase"
    d = round_data(run_simulation(SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks...))); r = d[end, :]
    println("step 8 sumsy, baseline — bread ", round(r.price_bread, digits = 2), " (", yr(d), " %/yr), alive ", r.persons_alive, ", gini wealth ", round(r.gini_net_wealth_persons, digits = 2), ", gap ", round(r.wealth_gap_meals, digits = 1), ", bottom tenth ", round(r.wealth_bottom10_meals, digits = 1), ", unemployed ", round(Int, r.unemployed))
elseif which == "austerity" || which == "baseline"
    ex = which == "austerity" ? (; austerity_start = 60) : (;)
    d = round_data(run_simulation(SimulationParameters(; seed = 1, def.BARE_DEBT..., kd..., ex...))); r = d[end, :]
    println("step 8 debt, ", which, " — bread ", round(r.price_bread, digits = 2), " (", yr(d), " %/yr), alive ", r.persons_alive, " (m66 ", d.persons_alive[min(66, end)], ", m72 ", d.persons_alive[min(72, end)], "), hungry peak after m60 ", maximum(d.hungry[60:end]), ", unemployed ", round(Int, r.unemployed), ", public debt ", round(Int, r.government_debt / 1000), "k (m60 ", round(Int, d.government_debt[60] / 1000), "k), benefit bill last year ", round(Int, sum(d.government_outlay[end-11:end])), ", taxes ", round(Int, sum(d.tax[end-11:end])), ", bottom tenth ", round(r.wealth_bottom10_meals, digits = 1))
else
    sys = which
    base, kw = sys == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
    m = run_simulation(SimulationParameters(; seed = 1, base..., kw..., greed = true, greed_share = 0.01, greed_hoarding = 0.5)); d = round_data(m); r = d[end, :]
    ws = [w for w in B.persons(m) if w.alive]; nw = sort([B.net_wealth(m, w) for w in ws]; rev = true)
    top1 = sum(nw[1:max(1, length(nw) ÷ 100)]); tot = sum(max.(nw, 0.0))
    greedy = [w for w in ws if w.greed == :greedy]
    println("step 8 ", sys, ", 1 % hoarders — alive ", r.persons_alive, ", gini wealth ", round(r.gini_net_wealth_persons, digits = 2), ", gap ", round(r.wealth_gap_meals, digits = 1), " meals, bottom tenth ", round(r.wealth_bottom10_meals, digits = 1), ", top 1 % hold ", round(Int, 100 * top1 / max(tot, 1)), " % of net wealth, the hoarders' mean wealth ", round(Int, sum(B.net_wealth(m, w) for w in greedy; init = 0.0) / max(length(greedy), 1)), " vs everyone ", round(Int, sum(nw) / length(nw)), ", land held by households ", round(Int, 100 * r.land_households_share), " %, bread ", round(r.price_bread, digits = 2), ", public debt ", round(Int, r.government_debt / 1000), "k")
end
