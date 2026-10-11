include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames, Statistics
def = ladder_definition(512, 120, :invoicing)
const B = BreadEconomySim
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], "V8"))
m = create_bread_economy(SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks..., fixed_prices = false, maximum_rounds = 20))
for r in 1:15; B.econo_step!(m, 1); end
bak = first(B.enterprises(m, :bakery)); p = B.parameters(m)
println("bakery: ask bread ", round(bak.ask[:bread], digits = 3), " floor ", round(B.seller_reservation(m, bak, :bread), digits = 3), " bid wage ", round(bak.bid[:wage], digits = 3), " own limit ", round(B.employer_wage_limit(m, bak), digits = 3), " ceiling ", round(B.buyer_reservation(m, bak, :wage), digits = 3), " going ", round(B.going_wage(m), digits = 3), " target ", bak.production_target, " grain ", round(B.grain_units(bak), digits = 1), " cash ", round(B.cash(bak)), " labour need ", round(B.labour_need(bak), digits = 1))
ws = sort([w for w in B.persons(m) if w.alive && w.labour_offered > 0]; by = w -> w.ask[:wage])
for w in ws[[1, length(ws) ÷ 2, end]]
    println("worker ", w.id, ": ask ", round(w.ask[:wage], digits = 3), " reservation ", round(B.seller_reservation(m, w, :wage), digits = 3), " last wage ", round(w.last_wage_rate, digits = 3), " months since ", B.current_round(m) - w.last_wage_round, " offered ", w.labour_offered, " → negotiate ", B.negotiate(m, w, bak, :wage))
end
