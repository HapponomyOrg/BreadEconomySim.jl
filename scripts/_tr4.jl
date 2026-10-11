include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
const B = BreadEconomySim
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], "V8"))
m = create_bread_economy(SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks..., fixed_prices = false, maximum_rounds = 20))
for r in 1:17
    B.econo_step!(m, 1)
    r < 13 && continue
    x = m.data[end]
    farms = B.enterprises(m, :farm); baks = B.enterprises(m, :bakery)
    println("m", r, " farms ", length(farms), " bakeries ", length(baks), " grain produced ", round(Int, x.grain_harvested), " baked ", round(Int, x.bread_baked), " bread sold ", round(Int, x.bread_sold), " price bread ", round(x.price_bread, digits = 2), " grain ", round(x.price_grain, digits = 2), " wage ", round(x.price_wage, digits = 2),
            " farm labour ", round(Int, sum(f.hired_labour for f in farms; init = 0.0)), " bakery labour ", round(Int, sum(b.hired_labour for b in baks; init = 0.0)), " farm cash ", round(Int, sum(B.cash(f) for f in farms; init = 0.0)), " bakery cash ", round(Int, sum(B.cash(b) for b in baks; init = 0.0)), " bakery grain stock ", round(Int, sum(B.grain_units(b) for b in baks; init = 0.0)), " liq ", x.liquidations); flush(stdout)
end
