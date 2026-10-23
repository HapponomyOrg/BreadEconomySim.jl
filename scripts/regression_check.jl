# ======================================================================================================================
# regression_check.jl — does the current code, with every switch off (fiscal = :own, no variant), reproduce an earlier run?
# (22 October 2026, docs/talk/same_fiscal_rules_instructions_2026-10-22.md §3.7)
#
#     include("scripts/regression_check.jl")
#     regression_check()                                   # steps 2 and 8, both moneys, seed 1, against results/parts/ladder2_512_120months_2026-10-20.4
#     regression_check(steps = ["2 ", "8 ", "V8 "], seeds = 1:2, folder = "results/parts/ladder2_512_120months_2026-10-20.4")
#     regression_check(steps = ["B "], fiscal = :taxes, surplus_rule = :per_head, folder = "results/parts/ladder2_512_fiscal_taxes_120months_2026-10-22.13")   # 23 Oct: the old surplus rule must reproduce 22.13 (handoff §1.5)
#
# Each run is compared month by month with the part file of the same step, money and seed in `folder`, on the behavioural
# columns below. A match means the code change since that run did not touch the base. Runs in this process (no workers).
# ======================================================================================================================
using DataFrames, CSV, Statistics
include(joinpath(@__DIR__, "ladder_definition.jl"))

const RC_COLUMNS = [:persons_alive, :price_bread, :government_debt, :unemployed, :money_in_circulation, :hungry, :liquidations, :bread_baked]

function regression_check(; steps = ["2 ", "8 "], seeds = 1:1, folder = joinpath(@__DIR__, "..", "results", "parts", "ladder2_512_120months_2026-10-20.4"), rounds = 120, fiscal::Symbol = :own, surplus_rule::Symbol = :debt_levy_taxcut, extra = (;))
    def = ladder_definition(512, rounds, :invoicing; fiscal, surplus_rule)
    safe(s) = replace(s, r"[^A-Za-z0-9]+" => "_")
    results = NamedTuple[]
    for step in steps, system in ("debt", "sumsy"), seed in seeds
        (name, kd, ks) = only(r for r in def.rungs if startswith(r[1], step))
        base, kw = system == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
        isempty(kw) && !occursin(r"^[0-9]", name) && continue
        file = joinpath(folder, "$(safe(name))__$(system)__$(seed).csv")
        isfile(file) || (println("no reference file: ", file); continue)
        d = round_data(run_simulation(SimulationParameters(; seed, base..., kw..., extra...)))
        o = CSV.read(file, DataFrame)
        n = min(nrow(d), nrow(o))
        off = [(c, findfirst(i -> !(isequal(d[i, c], o[i, c]) || (isa(d[i, c], Number) && isa(o[i, c], Number) && isapprox(d[i, c], o[i, c]; rtol = 1e-9, atol = 1e-9))), 1:n)) for c in RC_COLUMNS if c in propertynames(o)]
        off = [(c, m) for (c, m) in off if m !== nothing]
        verdict = isempty(off) && nrow(d) == nrow(o) ? "identical" : "DIFFERS: " * join(["$c from month $m" for (c, m) in off], ", ") * (nrow(d) != nrow(o) ? " (lengths $(nrow(d)) vs $(nrow(o)))" : "")
        println(name, " | ", system, " seed ", seed, " — ", verdict); flush(stdout)
        push!(results, (; step = name, system, seed, verdict))
    end
    return DataFrame(results)
end
nothing
