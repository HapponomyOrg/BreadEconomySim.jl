include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
yr(d) = round(100 * ((d.price_bread[end] / d.price_bread[12])^(1 / 9) - 1), digits = 1)
(_, _, ks) = only(r for r in def.rungs if startswith(r[1], "8 "))
variants = Dict("floor1" => (; wage_floor_months = 1), "noemergency" => (; food_emergency_share = 0.0), "notolerance" => (; employer_loss_tolerance = 0.0), "margin25" => (; employer_wage_margin = 0.25), "all_old" => (; wage_floor_months = 1, food_emergency_share = 0.0, employer_loss_tolerance = 0.0, employer_wage_margin = 0.25))
ex = variants[ARGS[1]]
d = round_data(run_simulation(SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks..., ex...))); r = d[end, :]
println("step 8 sumsy, ", ARGS[1], " — bread ", round(r.price_bread, digits = 2), " (", yr(d), " %/yr), wage ", round(r.price_wage, digits = 2), ", gap ", round(r.wealth_gap_meals, digits = 1), " meals, land traded ", round(r.land_price_traded, digits = 1), ", alive ", r.persons_alive, ", unemployed ", round(Int, r.unemployed))
