# The planning ablation study (coder brief of 1 November 2026, task 3; Stef, 3 November): the realistic set's planning
# rules switched off one at a time, on a few cells and seeds, each variant written as a ladder-style folder so that
# `scripts/stylized_facts.py` scores it and `scripts/paired_tests.py` compares the villages.
#
#     include("scripts/planning_ablation.jl")
#     ablation()                                   # the defaults below: 3 cells × 2 villages × 4 seeds × 7 variants, 120 months
#     ablation(cells = ["8 "], seeds = 1:2, variants = [:base, :no_contracts], months = 120, jobs = 6)
#
# Then, per variant folder (e.g. results/parts/ablation_2026-11-03.3_no_contracts):
#     python3 scripts/stylized_facts.py results/parts/ablation_<version>_<variant>
#     python3 scripts/paired_tests.py   results/parts/ablation_<version>_<variant>
# and compare the variants' summaries side by side: the measures the brief names first are `ac1_gdp` (the oscillation:
# −0.31 at step 11 on the .3 runs against about +0.85 in the data), `sd_gdp`, `rel_sd_unemp`, `mean_unemp`, and the count
# of liquidations and hungry months per run (in `ablation_<version>_<variant>_runs.csv`, written here).
#
# The variants (each one rule of the realistic set turned off, or one remedy turned on, against the base):
#   :base               the ladder's base as it stands
#   :no_turned_away     respond_to_turned_away = false       (firms do not plan on customers turned away)
#   :no_bake_to_target  bakeries_bake_to_target = false
#   :no_expected_sales  price_on_expected_sales = false, price_rise_band = false   (the older pricing)
#   :no_contracts       supply_contracts = false              (3 Nov: the farms back on their own guess of the market)
#   :no_storage         grain_spoilage_age_in_rounds = 0      (grain spoils like bread, 3 months)
#   :partial            plan_adjustment_share = 0.5           (half the way to the plan each month)
#   :small_steps        price steps of 2 % instead of 6 % (4 Nov)
#   :wide_band          a 25 % tolerance band on expected sales instead of 10 % (4 Nov)
#   :price_only         the expected-sales rule's pricing half only (4 Nov)
#   :plan_only          its planning half only (4 Nov)
# Runs are spread over `jobs` worker processes (default: CPU threads − 1), as in `run_all`; an interrupted call resumes.

include(joinpath(@__DIR__, "run_all.jl"))
using CSV, DataFrames

const ABLATION_VARIANTS = Dict(
    :base => (;),
    :no_turned_away => (; respond_to_turned_away = false),
    :no_bake_to_target => (; bakeries_bake_to_target = false),
    :no_expected_sales => (; price_on_expected_sales = false, price_rise_band = false),
    :no_contracts => (; supply_contracts = false),
    :no_storage => (; grain_spoilage_age_in_rounds = 0),
    :partial => (; plan_adjustment_share = 0.5),
    # 4 Nov, after the first subset (step 8, 4 seeds): the oscillation is the expected-sales pricing (volatility 5.2 % → 1.65 % and
    # autocorrelation −0.38 → −0.06 with it off in the debt village; 14 %/yr inflation in SuMSy without it) — so the remedies to
    # test are smaller price steps and a wider tolerance band, not removal:
    :small_steps => (; ask_increase_after_sellout = 0.02, ask_decrease_after_partial_sale = 0.02),
    :wide_band => (; expected_sales_tolerance = 0.25),
    # 4 Nov, after the second subset: neither remedy removed the debt village's oscillation, so the rule is split in two —
    :price_only => (; expected_sales_in_plan = false),      # prices against expected sales, plans the older way
    :plan_only => (; expected_sales_in_price = false),      # plans on expected sales, prices the older way
)

# 4 Nov: the runs go to worker processes as in `run_all` (same `jobs`, `worker_recycle`, `heap_hint`), each run written under
# a temporary name and renamed, so an interrupted call resumes where it stopped.
const ABLATION_WORKER = quote
    ABL_VARIANTS = $(ABLATION_VARIANTS)
    ABL_REALISTIC = $(REALISTIC_LABOUR)
    function run_ablation_job(job)
        def = ladder(job.villagers, job.months, :invoicing)
        (name, kd, ks) = only(r for r in def.rungs if startswith(r[1], job.cell))
        base, kw = job.system == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
        m = run_simulation(SimulationParameters(; seed = job.seed, base..., kw..., ABL_REALISTIC..., ABL_VARIANTS[job.variant]...))
        d = round_data(m); d.rung .= name; d.system .= job.system; d.seed .= job.seed
        mkpath(dirname(job.file)); tmp = job.file * ".tmp"; CSV.write(tmp, d); mv(tmp, job.file; force = true)
        row = (variant = String(job.variant), rung = name, system = job.system, seed = job.seed, alive = d.persons_alive[end],
               liquidations = count(e -> e.kind == :liquidation, m.events), hungry_months = count(i -> d.hungry[i] > 0.3 * d.persons_alive[i], 1:nrow(d)),
               bread_y10 = d.price_bread[end], unemployed_y10 = d.unemployed[end])
        println("ablation ", job.variant, " ", strip(name)[1:min(end, 12)], " ", job.system, " seed ", job.seed, ": alive ", row.alive, ", liquidations ", row.liquidations, ", hungry months ", row.hungry_months); flush(stdout)
        return row
    end
end

function ablation(; cells = ["8 ", "B ", "V8 "], seeds = 1:4, variants = collect(keys(ABLATION_VARIANTS)), months = 120, villagers = 512,
                  jobs::Int = max(Sys.CPU_THREADS - 1, 1), worker_recycle::Int = 20, heap_hint::AbstractString = "4G")
    def = ladder_definition(villagers, months, :invoicing)
    todo = NamedTuple[]
    for var in variants, cell in cells
        haskey(ABLATION_VARIANTS, var) || error("no ablation variant $var; known: $(collect(keys(ABLATION_VARIANTS)))")
        (name, kd, ks) = only(r for r in def.rungs if startswith(r[1], cell))
        slug = replace(strip(name), r"[^A-Za-z0-9]+" => "_")
        folder = joinpath(@__DIR__, "..", "results", "parts", "ablation_$(MODEL_VERSION)_$(var)")
        for (sysn, kw) in (("debt", kd), ("sumsy", ks)), seed in seeds
            isempty(kw) && continue
            file = joinpath(folder, "$(slug)__$(sysn)__$(seed).csv")
            isfile(file) || push!(todo, (; variant = var, cell, system = sysn, seed, file, months, villagers))
        end
    end
    println(length(todo), " ablation runs to do, on ", min(jobs, max(length(todo), 1)), " process(es)"); flush(stdout)
    rows = Any[]
    n = min(jobs, length(todo))
    for lo in 1:max(worker_recycle * max(n, 1), 1):length(todo)
        part = todo[lo:min(lo + worker_recycle * max(n, 1) - 1, end)]
        fresh_workers!(n, String(heap_hint))
        Distributed.remotecall_eval(Main, n > 1 ? workers() : [1], ABLATION_WORKER)
        if n > 1
            append!(rows, pmap(WorkerPool(workers()), part; on_error = e -> "FAILED: " * sprint(showerror, e)) do job
                Main.run_ablation_job(job)
            end)
        else
            append!(rows, [try Main.run_ablation_job(job) catch e; "FAILED: " * sprint(showerror, e) end for job in part])
        end
    end
    workers() == [1] || rmprocs(workers())
    failed = [(j, r) for (j, r) in zip(todo, rows) if r isa AbstractString]
    for (j, r) in failed; println("FAILED ", j.variant, " ", j.cell, " ", j.system, " seed ", j.seed, ": ", first(r, 300)); end
    good = [r for r in rows if !(r isa AbstractString)]
    for var in unique(r.variant for r in good)
        table = joinpath(@__DIR__, "..", "results", "ablation_$(MODEL_VERSION)_$(var)_runs.csv")
        new = DataFrame([r for r in good if r.variant == var])
        isfile(table) && (new = vcat(CSV.read(table, DataFrame), new; cols = :union))   # a resumed call adds to the table
        CSV.write(table, new)
    end
    isempty(failed) || @warn "$(length(failed)) ablation runs failed; call ablation again to retry them (finished runs are kept)"
    return nothing
end
