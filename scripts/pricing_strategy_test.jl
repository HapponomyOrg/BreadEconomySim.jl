# ======================================================================================================================
# pricing_strategy_test.jl — greed against sufficiency in one market (21 October 2026, Stef)
#
# Half of each sector's firms price on a target net margin (never enough), the other half at cost with a reserve target
# (enough). Both villages, one step of the ladder, ten seeds. For each firm the script accumulates its months alive, units sold,
# dividends paid and whether it was wound up, and reports per money, per kind and per strategy: firms started, wound up, alive
# at the end, share of the kind's sales, cash at the end, dividends over the run. Everything is written to
# results/pricing_strategy_test.csv (one row per firm) and results/pricing_strategy_summary.csv.
#
# In the REPL:
#     include("scripts/pricing_strategy_test.jl")
#     strategy_test()                                      # step 8, both moneys, seeds 1:10, half of each sector on margins
#     strategy_test(share = 0.25)                          # a quarter on margins
#     strategy_test(seeds = 1:1, rounds = 6, jobs = 1)     # a smoke test
# ======================================================================================================================

using Distributed, DataFrames, CSV, Statistics

const PS_ROOT = normpath(joinpath(@__DIR__, ".."))

const PS_SETUP = quote
    using BreadEconomySim, DataFrames, Statistics
    const B = BreadEconomySim
    include(joinpath($PS_ROOT, "scripts", "ladder_definition.jl"))
    function ps_run(job)
        def = ladder_definition(512, job.rounds, :invoicing)
        (_, kd, ks) = only(r for r in def.rungs if startswith(r[1], job.step))
        base, kw = job.system == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
        p = SimulationParameters(; seed = job.seed, base..., kw..., pricing_margin_share = job.share)
        m = create_bread_economy(p)
        months = Dict{Int, Int}(); sold = Dict{Int, Float64}(); good(e) = e.kind == :bakery ? :bread : e.kind == :farm ? :grain : :ticket
        for _ in 1:job.rounds
            B.econo_step!(m, 1)
            for e in m.enterprise_list
                (e.alive && B.is_producer(e)) || continue
                months[e.id] = get(months, e.id, 0) + 1
                sold[e.id] = get(sold, e.id, 0.0) + e.market[good(e)].sold
            end
        end
        d = round_data(m)
        rows = NamedTuple[]
        for e in m.enterprise_list
            B.is_producer(e) || continue
            haskey(months, e.id) || continue
            push!(rows, (; system = job.system, seed = job.seed, share = job.share, kind = e.kind, firm = e.id, strategy = e.pricing,
                           months_alive = months[e.id], alive_at_end = e.alive, units_sold = sold[e.id],
                           cash_at_end = e.alive ? B.cash(e) : 0.0, dividends = sum(e.dividend_history; init = 0.0),
                           persons_alive = d.persons_alive[end], bread_price = d.price_bread[end]))
        end
        return rows
    end
end

Distributed.remotecall_eval(Main, [1], PS_SETUP)

"""
    strategy_test(; step = "8 ", seeds = 1:10, rounds = 120, share = 0.5, jobs = max(Sys.CPU_THREADS - 1, 1))

Both villages at `step`, `share` of each sector's firms on margins. Prints the summary per money, kind and strategy; writes
results/pricing_strategy_test.csv (one row per firm) and results/pricing_strategy_summary.csv; returns the per-firm DataFrame.
"""
function strategy_test(; step::AbstractString = "8 ", seeds = 1:10, rounds::Int = 120, share::Float64 = 0.5, jobs::Int = max(Sys.CPU_THREADS - 1, 1))
    jobs_list = [(; step = String(step), system, seed, rounds, share) for system in ("debt", "sumsy") for seed in seeds]
    n = min(jobs, length(jobs_list))
    if n > 1
        workers() == [1] || rmprocs(workers())
        addprocs(n; exeflags = ["--project=$PS_ROOT", "-O1", "--heap-size-hint=4G"])
        Distributed.remotecall_eval(Main, workers(), PS_SETUP)
        parts = pmap(WorkerPool(workers()), jobs_list) do job; ps_run(job) end
        rmprocs(workers())
    else
        parts = [ps_run(job) for job in jobs_list]
    end
    df = DataFrame(reduce(vcat, parts))
    mkpath(joinpath(PS_ROOT, "results")); CSV.write(joinpath(PS_ROOT, "results", "pricing_strategy_test.csv"), df)
    # the share of each kind's sales taken by each strategy, per run, then averaged
    df.kind_sales = [sum(df.units_sold[(df.system .== r.system) .& (df.seed .== r.seed) .& (df.kind .== r.kind)]) for r in eachrow(df)]
    df.sales_share = df.units_sold ./ max.(df.kind_sales, 1e-9)
    summary = combine(groupby(df, [:system, :kind, :strategy]),
                      nrow => :firms, :alive_at_end => (x -> count(!, x)) => :wound_up, :alive_at_end => count => :alive_at_end,
                      :months_alive => mean => :months_alive, :sales_share => sum => :sales_share_total, :cash_at_end => mean => :cash_at_end,
                      :dividends => mean => :dividends_per_firm)
    summary.sales_share_total ./= length(seeds)                          # the strategy's share of the kind's sales, averaged over the seeds
    sort!(summary, [:system, :kind, :strategy])
    CSV.write(joinpath(PS_ROOT, "results", "pricing_strategy_summary.csv"), summary)
    show(stdout, summary; allcols = true, allrows = true); println()
    println("\nvillagers alive at the end, mean: debt ", round(mean(unique(df[df.system .== "debt", [:seed, :persons_alive]]).persons_alive)), ", SuMSy ", round(mean(unique(df[df.system .== "sumsy", [:seed, :persons_alive]]).persons_alive)))
    println("written: results/pricing_strategy_test.csv ($(nrow(df)) firms) and results/pricing_strategy_summary.csv")
    return df
end
nothing
