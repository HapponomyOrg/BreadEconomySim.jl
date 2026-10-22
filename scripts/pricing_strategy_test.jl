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
#
# Spare supply (21 October, Stef): at step 8 every firm sells out, so the two strategies never compete — the cheaper firms sell
# out and the margin firms sell the rest at their price. More firms would not change that: supply is planned to the village's
# need and divided among the firms, so eight bakeries are four smaller ones. What makes firms offer more than the village will
# buy is the planning margin: at 30 % every kind brings a third more to market than there is demand, the cheaper firms sell
# first, the margin firms sell last, and customers can walk away. Own-market planning is the other case we are looking into:
# each firm plans on its own sales (three-month average, net of stock, counting the turned-away), so a firm that loses
# customers shrinks and one that sells out grows — the strategies then compete through the plan as well as the price.
#     strategy_test(extra = SPARE_SUPPLY, label = "spare_supply")                       # planning margin 30 %
#     strategy_test(extra = OWN_PLANNING, label = "own_planning")                       # firms plan on their own market
#     strategy_test(extra = merge(SPARE_SUPPLY, OWN_PLANNING), label = "spare_own")     # both
#     strategy_test(extra = OVERCAPACITY, label = "overcapacity")                       # eight firms of each kind (market structure, not spare supply)
#     strategy_test(extra = merge(SPARE_SUPPLY, OWN_PLANNING, DEBT_AWARE), label = "spare_own_debt")   # and the firms count their loans
#     strategy_test(extra = merge(SPARE_SUPPLY, OWN_PLANNING, DEBT_AWARE, EXPECTED_SALES), label = "spare_own_debt_sold")   # and price per unit they expect to sell
#     strategy_test(extra = merge(PRICE_ON_EXPECTED, DEBT_AWARE, EXPECTED_SALES), label = "expected")   # 22 Oct: prices against expected sales, adaptive buffer
#     strategy_test(extra = merge(PRICE_ON_EXPECTED, DEBT_AWARE, EXPECTED_SALES, CONTRACTS), label = "expected_contracts")   # with contracts (none of the earlier runs had them)
#     strategy_test(extra = REALISTIC, label = "realistic")                         # the whole realistic set: planning, pricing, loans, contracts, minimum, sale before closure
# `extra` is any set of SimulationParameters, applied last; `label` names the output files. The summary carries each strategy's
# unsold share (what it offered and did not sell), which says whether supply exceeded demand.
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
        p = SimulationParameters(; seed = job.seed, base..., kw..., pricing_margin_share = job.share, job.extra...)
        m = create_bread_economy(p)
        months = Dict{Int, Int}(); sold = Dict{Int, Float64}(); offered = Dict{Int, Float64}(); good(e) = e.kind == :bakery ? :bread : e.kind == :farm ? :grain : :ticket
        for _ in 1:job.rounds
            B.econo_step!(m, 1)
            for e in m.enterprise_list
                (e.alive && B.is_producer(e)) || continue
                months[e.id] = get(months, e.id, 0) + 1
                sold[e.id] = get(sold, e.id, 0.0) + e.market[good(e)].sold
                offered[e.id] = get(offered, e.id, 0.0) + e.market[good(e)].offered
            end
        end
        d = round_data(m)
        rows = NamedTuple[]
        for e in m.enterprise_list
            B.is_producer(e) || continue
            haskey(months, e.id) || continue
            push!(rows, (; system = job.system, seed = job.seed, share = job.share, label = job.label, kind = e.kind, firm = e.id, strategy = e.pricing,
                           months_alive = months[e.id], alive_at_end = e.alive, units_sold = sold[e.id], units_offered = offered[e.id],
                           unsold_share = offered[e.id] > 0 ? 1 - sold[e.id] / offered[e.id] : 0.0,
                           cash_at_end = e.alive ? B.cash(e) : 0.0, dividends = sum(e.dividend_history; init = 0.0),
                           persons_alive = d.persons_alive[end], bread_price = d.price_bread[end], unemployed = mean(d.unemployed[max(end - 11, 1):end])))
        end
        return rows
    end
end

Distributed.remotecall_eval(Main, [1], PS_SETUP)

const SPARE_SUPPLY = (; planning_margin = 0.3)                                                   # a third more than the village will buy
const OWN_PLANNING = (; own_market_planning = true, firms_plan_on_sales = false, market_rounds = 1)   # the 19–21 October planning rule (window 3, net of stock, turned-away counted)
const OVERCAPACITY = (; number_of_farms = 8, number_of_bakeries = 8, number_of_theatres = 8)   # twice the firms of each kind (smaller firms, the same supply)
const EXPECTED_SALES = (; floor_per_unit_sold = true)                                           # 22 Oct (Stef): sufficiency prices per unit it expects to sell
const PRICE_ON_EXPECTED = (; own_market_planning = true, firms_plan_on_sales = false, market_rounds = 1, price_on_expected_sales = true)   # 22 Oct (Stef): asks move against expected sales, with an adaptive buffer
const CONTRACTS = (; contracts = true, contract_share = 0.8)                                      # 22 Oct (Stef): the realistic labour market — contracts for four fifths of the hands, which hold wages and so the cost floor
const DEBT_AWARE = (; cost_floor_includes_debt_service = true)                                   # 21 Oct (Stef): reserve planners count their loans — interest in the floor, the full service in the reserve
const REALISTIC = merge(PRICE_ON_EXPECTED, DEBT_AWARE, EXPECTED_SALES, CONTRACTS, (; refound_minimum = 2, uncovered_debt_sale = true))   # everything of 18–22 October together

"""
    strategy_test(; step = "8 ", seeds = 1:10, rounds = 120, share = 0.5, extra = (;), label = "", jobs = max(Sys.CPU_THREADS - 1, 1))

Both villages at `step`, `share` of each sector's firms on margins, `extra` settings applied last (e.g. OVERCAPACITY). Prints the
summary per money, kind and strategy; writes results/pricing_strategy_test[_label].csv (one row per firm) and
results/pricing_strategy_summary[_label].csv; returns the per-firm DataFrame.
"""
function strategy_test(; step::AbstractString = "8 ", seeds = 1:10, rounds::Int = 120, share::Float64 = 0.5, extra = (;), label::AbstractString = "",
                         jobs::Int = max(Sys.CPU_THREADS - 1, 1))
    jobs_list = [(; step = String(step), system, seed, rounds, share, extra, label = String(label)) for system in ("debt", "sumsy") for seed in seeds]
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
    suffix = isempty(label) ? "" : "_" * label
    mkpath(joinpath(PS_ROOT, "results")); CSV.write(joinpath(PS_ROOT, "results", "pricing_strategy_test$(suffix).csv"), df)
    # the share of each kind's sales taken by each strategy, per run, then averaged
    df.kind_sales = [sum(df.units_sold[(df.system .== r.system) .& (df.seed .== r.seed) .& (df.kind .== r.kind)]) for r in eachrow(df)]
    df.sales_share = df.units_sold ./ max.(df.kind_sales, 1e-9)
    summary = combine(groupby(df, [:system, :kind, :strategy]),
                      nrow => :firms, :alive_at_end => (x -> count(!, x)) => :wound_up, :alive_at_end => count => :alive_at_end,
                      :months_alive => mean => :months_alive, :sales_share => sum => :sales_share_total, :unsold_share => mean => :unsold_share, :cash_at_end => mean => :cash_at_end,
                      :dividends => mean => :dividends_per_firm)
    summary.sales_share_total ./= length(seeds)                          # the strategy's share of the kind's sales, averaged over the seeds
    sort!(summary, [:system, :kind, :strategy])
    CSV.write(joinpath(PS_ROOT, "results", "pricing_strategy_summary$(suffix).csv"), summary)
    show(stdout, summary; allcols = true, allrows = true); println()
    for sys in ("debt", "sumsy")
        runs = unique(df[df.system .== sys, [:seed, :persons_alive, :unemployed]])
        println(sys, ": villagers alive at the end ", round(mean(runs.persons_alive)), ", unemployed over the last year ", round(mean(runs.unemployed), digits = 1), " (idle hands = idle capacity)")
    end
    println("written: results/pricing_strategy_test$(suffix).csv ($(nrow(df)) firms) and results/pricing_strategy_summary$(suffix).csv")
    return df
end
nothing
