include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
step = ARGS[1]
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], step * " "))
d = round_data(run_simulation(SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks..., offer_full_capacity = false))); r = d[end, :]
println("step ", step, " sumsy, needs-based offers, GI counted — alive ", r.persons_alive, ", hungry peak ", maximum(d.hungry), ", unemployed ", round(Int, r.unemployed), ", capacity offered ", round(Int, 100 * r.labour_offered_share), " %, worked ", round(Int, 100 * r.labour_sold_share), " %, bread ", round(r.price_bread, digits = 2), ", cash per head ", round(Int, r.cash_persons / r.persons_alive), ", public debt ", round(Int, r.government_debt / 1000), "k")
