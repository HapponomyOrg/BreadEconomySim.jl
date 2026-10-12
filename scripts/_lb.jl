include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
yr(d) = round(100 * ((d.price_bread[end] / d.price_bread[min(12, end)])^(1 / 9) - 1), digits = 1)
step, sys = ARGS[1], ARGS[2]
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], step * " "))
base, kw = sys == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
margin = length(ARGS) >= 3 ? parse(Float64, ARGS[3]) : 0.1
d = round_data(run_simulation(SimulationParameters(; seed = 1, base..., kw..., labour_for_bread_margin = margin))); r = d[end, :]
println("step ", step, " ", sys, ", labour for bread, margin ", margin, " — alive ", r.persons_alive, ", hungry peak ", maximum(d.hungry), ", months short of hands ", count(x -> x > 0, d.labour_unfilled), ", unemployed ", round(Int, r.unemployed), ", offered ", round(Int, 100 * r.labour_offered_share), " % worked ", round(Int, 100 * r.labour_sold_share), " %, bread ", round(r.price_bread, digits = 2), " (", yr(d), " %/yr), baked ", round(Int, r.bread_baked), ", cash/head ", round(Int, r.cash_persons / max(r.persons_alive, 1)), ", public debt ", round(Int, r.government_debt / 1000), "k, gap ", round(r.wealth_gap_meals, digits = 1), ", bottom tenth ", round(r.wealth_bottom10_meals, digits = 1))
