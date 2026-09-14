# Per-enterprise, per-round table: what each farm/bakery wanted, hired, bought, produced, sold, and held in cash.
#   julia --project=. scripts/diagnose.jl [seed] [rounds]
using BreadEconomySim, DataFrames, CSV
seed = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 1
rounds = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 10
m = create_bread_economy(SimulationParameters(seed = seed, maximum_rounds = rounds))
rows = NamedTuple[]
while !m.finished
    BreadEconomySim.econo_step!(m, 1)
    for e in BreadEconomySim.alive_agents(m)
        e isa Enterprise && e.kind in (:farm, :bakery) || continue
        push!(rows, (round = BreadEconomySim.current_round(m) - 1, id = e.id, kind = e.kind, target = e.production_target,
                     land = e.land + e.rented_land, wanted_labour = e.market[:wage].wanted, hired = e.hired_labour,
                     wanted_input = e.kind == :farm ? e.market[:rent].wanted : e.market[:grain].wanted,
                     got_input = e.kind == :farm ? e.market[:rent].got : e.market[:grain].got,
                     offered = e.market[e.kind == :farm ? :grain : :bread].offered, sold = e.market[e.kind == :farm ? :grain : :bread].sold,
                     unmet = e.market[e.kind == :farm ? :grain : :bread].unmet_demand,
                     stock = e.kind == :farm ? BreadEconomySim.grain_units(e) : BreadEconomySim.bread_units(e),
                     cash = round(BreadEconomySim.cash(e), digits = 1), debt = round(BreadEconomySim.debt_of(e), digits = 1),
                     ask = round(e.ask[e.kind == :farm ? :grain : :bread], digits = 2), wage_bid = round(e.bid[:wage], digits = 2)))
    end
end
df = DataFrame(rows)
CSV.write(joinpath(@__DIR__, "..", "results", "diagnose_seed$(seed).csv"), df)
show(stdout, df; allrows = true, allcols = true); println()
