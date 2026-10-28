# ======================================================================================================================
# run_all.jl — everything the Bread Economy report needs, in one call.
#
# In the REPL (20 October, Stef: one function with named settings, so a session can run several batches without new REPLs or
# environment variables):
#
#     include("scripts/run_all.jl")          # once per session: defines `run_all` and loads the packages
#     run_all()                                # the standard run: the 512-villager ladder, ten seeds, 120 months
#     run_all(seeds = 1, rounds = 6, ladders = [(128, :invoicing)], rungs = ["0", "2"], skip_tests = true)   # a quick check
#     run_all(shard = "1/2")                   # this machine takes every second job (the other machine: shard = "2/2")
#     run_all(summary_only = true)             # rebuild the summary from the part files already there; runs nothing
#     run_all(contract_share = 1.0)            # the whole ladder again at another contracts setting, in its own folder
#     run_all(variant = REALISTIC_LABOUR, variant_label = "realistic")   # the whole ladder with this week's labour market
#     run_all(variant = REALISTIC_LABOUR_90, variant_label = "realistic90")   # the same with contract wages indexed at 0.9
#     run_all(seeds = 4, fiscal = :taxes, rungs = ["8"], variant = FLOOR_TWO_LOAVES, variant_label = "floor2")   # the collection-floor test (and fiscal = :parking): 32 jobs
#     run_all(seeds = 4, fiscal = :taxes, rungs = ["11"], variant = PARTIAL_BENEFIT, variant_label = "partial")   # the step-11 test: floor2, partial, both — each with fiscal = :taxes and :parking: 48 jobs
#     run_all(seeds = 4, fiscal = :taxes, rungs = ["11"], variant = FLOOR_AND_PARTIAL, variant_label = "floor2_partial")
#     run_all(seeds = 4, fiscal = :taxes, rungs = ["B "], variant = BANK_MARGIN, variant_label = "bankmargin")   # 23 Oct: the best village with banks on a real-world net margin (and fiscal = :parking)
#     run_all(seeds = 4, fiscal = :taxes, rungs = ["2", "8"], variant = RATE_CAP_04, variant_label = "cap04")   # 23 Oct: the rate cap at 0.4 % a month, steps 2 and 8 (and fiscal = :parking): 32 jobs
#     run_all(seeds = 4, fiscal = :taxes, rungs = ["1 "], variant = OWN_PLANNING, variant_label = "ownplan")   # 23 Oct (Stef): rung 1 with own-market planning (no government: the package is empty there, so fiscal = :taxes or :own alike)
#
# From the command line the environment variables still work as before (JOBS, SEEDS, ROUNDS, LADDERS, RUNGS, SKIP_TESTS,
# SUMMARY_ONLY, SHARD, CONTRACT_SHARE, WORKER_RECYCLE, HEAP_HINT, UPDATE_ECONOSIM):
#
#     julia --project=. scripts/run_all.jl
#
# The settings of `run_all` (all optional):
#   jobs            worker processes (default: CPU threads − 1); 1 runs everything in this process
#   seeds           runs per configuration (10)
#   rounds          months per run (120 = ten years)
#   ladders         [(512, :invoicing)] — add (512, :clearing_all) or (128, :invoicing) for the old comparisons
#   rungs           only steps whose name starts with one of these prefixes (empty = all)
#   skip_tests      skip the test suite (it also runs only once per version and code — a fingerprinted marker in results/)
#   summary_only    write the summaries from the part files already there and run nothing
#   shard           "k/n": take every n-th job starting at the k-th, to split a run over n machines
#   contract_share  nothing (the ladder as defined) or a number: every step again at that contracts setting, own folder
#   variant         a NamedTuple of settings added to every step (e.g. REALISTIC_LABOUR), with variant_label naming its folder
#   surplus_rule    :debt_levy_taxcut (default: repay debt, levy per head, lower taxes) or :per_head (the 2026-10-22.13 packages); with a package only
#   fiscal          :own (the ladder as it is: each money its own package), :taxes (package T on both sides) or :parking (package P
#                   on both sides) — docs/talk/same_fiscal_rules_instructions_2026-10-22.md; part of the folder name (…_fiscal_taxes_…)
#   worker_recycle  jobs per worker before the workers are replaced (a model process retains memory across runs) (20)
#   heap_hint       the workers' --heap-size-hint ("4G")
#   update_econosim move EconoSim.jl to the latest commit on its main branch first (false)
#
# Each run is saved as its own file under results/parts/ the moment it finishes, so a batch can be stopped and started again
# at any time: finished runs are skipped. Output per ladder, named with the version: …_<version>_rounds.csv (split under GitHub's
# 100 MB limit), …_<version>_summary.csv (one row per step and village, with medians and bands), …_<version>_rungs.csv (what each step contains).
# ======================================================================================================================

using Dates, Pkg, Distributed

const ROOT = normpath(joinpath(@__DIR__, ".."))

const MODEL_VERSION = "2026-10-28.0"   # the date the version was made, then .0, .1, … for each version made that day (Stef, 16 Oct); part of the key: runs made with an earlier version are never reused

# ---- packages (once per session) ---------------------------------------------------------------------------------------
const PACKAGES_READY = Ref(false)
function prepare_packages!(; update_econosim::Bool = false)
    PACKAGES_READY[] && !update_econosim && return nothing
    Pkg.activate(ROOT; io = devnull)
    # EconoSim.jl comes from its GitHub repository (branch main); the commit in the Manifest is used unless updated
    update_econosim && (println("Updating EconoSim.jl to the latest commit on main…"); Pkg.update("EconoSim"))
    println("Installing and precompiling packages (first time only takes a while)…"); flush(stdout)
    Pkg.instantiate(); Pkg.precompile()
    PACKAGES_READY[] = true
    return nothing
end
prepare_packages!()
using DataFrames, CSV, Statistics

# ---- the test suite (once per version and code) ------------------------------------------------------------------------
# 16 Oct (Stef): when the suite passes, a marker is written for this version with a fingerprint of the code it tested (src/,
# test/, scripts/ladder_definition.jl, the Julia version); a later run of the same version and code skips the suite. Any change
# to that code runs it again. The marker is per machine (.gitignore).
test_marker() = joinpath(ROOT, "results", "tests_passed_$(MODEL_VERSION).txt")
function code_fingerprint()
    files = sort(vcat([joinpath(ROOT, "src", f) for f in readdir(joinpath(ROOT, "src")) if endswith(f, ".jl")],
                      [joinpath(ROOT, "test", f) for f in readdir(joinpath(ROOT, "test")) if endswith(f, ".jl")],
                      [joinpath(ROOT, "scripts", "ladder_definition.jl")]))
    return string(foldl((h, f) -> hash(read(f), hash(basename(f), h)), files; init = hash(string(VERSION))); base = 16)
end
function run_tests!(; skip::Bool = false)
    skip && return nothing
    fp = code_fingerprint()
    if isfile(test_marker()) && strip(read(test_marker(), String)) == fp
        println("The test suite already passed for version $(MODEL_VERSION) and this code — not run again."); flush(stdout)
        return nothing
    end
    println("Running the test suite…"); flush(stdout)
    proc = run(ignorestatus(`$(Base.julia_cmd()) --project=$ROOT $(joinpath(ROOT, "test", "runtests.jl"))`))
    if proc.exitcode != 0
        println("""
        The test suite failed (see the output above for which tests and why). The ladders are not run on a model that fails
        its tests. Since 23 September the model's randomness is version-stable (StableRNGs, fixed stream seeds, ordered
        dictionaries), so the golden values should match on any Julia version and processor; a failure there is a real
        difference worth reporting, as is any other failing test.""")
        error("test suite failed (details above)")      # an error, not exit(): exit would also close the REPL
    end
    println("Tests passed.")
    mkpath(dirname(test_marker())); write(test_marker(), fp)
    return nothing
end

# ---- names and places ---------------------------------------------------------------------------------------------------
variant_name(contract_share, variant = nothing, label = "variant", fiscal = :own, surplus_rule = :debt_levy_taxcut) = (contract_share !== nothing ? "_contracts$(round(Int, 100 * contract_share))" : variant === nothing ? "" : "_" * label) * (fiscal == :own ? "" : "_fiscal_$fiscal") * (fiscal != :own && surplus_rule == :per_head ? "_perhead" : "")   # 22 Oct: the package in the name; 23 Oct: the old surplus rule marked
variant_extra(contract_share, variant = nothing) = contract_share !== nothing ? (; contract_share = Float64(contract_share)) : variant === nothing ? (;) : variant
# 20 Oct: this week's realistic labour market as a variant of the whole ladder — run_all(variant = REALISTIC_LABOUR, variant_label = "realistic")
# runs every step with it, into its own folder (…_realistic_…). Market rounds stay at one: with four, the lowered asks pushed
# prices down month after month until the grain market froze (no-contract SuMSy village, seed 7: 100 alive; one round: 512).
const REALISTIC_LABOUR = (; contracts = true, contract_share = 0.8, refound_minimum = 2, uncovered_debt_sale = true,
                            own_market_planning = true, firms_plan_on_sales = false, market_rounds = 1,
                            price_on_expected_sales = true, cost_floor_includes_debt_service = true, floor_debt_service = :long,
                            floor_per_unit_sold = true, firm_land_loan_max_rounds = 240, land_price_meets_offers = true)   # 22 Oct: the same set as REALISTIC in scripts/pricing_strategy_test.jl (without the strategy mix)
const REALISTIC_LABOUR_90 = (; REALISTIC_LABOUR..., contract_indexation = 0.9)   # 22 Oct (Stef): the same with wages indexed at nine tenths
const FLOOR_TWO_LOAVES = (; collection_floor_in_breads = 2.0)   # 22 Oct (the talk chat): debt collection may not take a villager below two loaves (a meal) instead of one — does the debt village then keep everyone?
const PARTIAL_BENEFIT = (; partial_unemployment_fee = true)      # 22 Oct (the talk chat): the benefit pro rata for a villager with a little work, instead of stopping at the first hour
const FLOOR_AND_PARTIAL = (; FLOOR_TWO_LOAVES..., PARTIAL_BENEFIT...)
const BANK_MARGIN = (; bank_target_net_margin = 0.2967)   # 23 Oct (Stef): banks on the real-world net margin (Banks, Regional: 29.67 %) — the loan rate (debt money)
const BANK_MARGIN_BOTH = (; BANK_MARGIN..., bank_margin_on_spread = true)   # and the SuMSy banks' spread on peer loans too
const BANK_RATE_MARKET = (; bank_rate_market = true)   # 23 Oct (Stef): the rate as an ask, floored at cost-plus
const OWN_PLANNING = (; own_market_planning = true, firms_plan_on_sales = false, market_rounds = 1)   # 23 Oct (Stef): own-market planning alone (three-month average, net of stock, turned-away counted; prices against expected sales need price_on_expected_sales too)
const RATE_CAP_04 = (; maximum_interest_rate = 0.004)   # 23 Oct (the talk chat): the loan rate capped at a realistic 0.4 % a month (the base's cap, 1.5 %, binds in every run)
with_extra(kw, extra) = isempty(kw) ? kw : (; kw..., extra...)
ladder_name(N, settlement, variant = "") = (settlement == :invoicing ? "ladder2_$(N)" : "ladder2_$(N)_$(settlement)") * variant
parts_dir(N, settlement, rounds, variant = "") = joinpath(ROOT, "results", "parts", "$(ladder_name(N, settlement, variant))_$(rounds)months_$(MODEL_VERSION)")   # the run length and the model version are part of the key
safe(s) = replace(s, r"[^A-Za-z0-9]+" => "_")

# ---- workers --------------------------------------------------------------------------------------------------------------
# A model process retains about 0.6 GB per 120-month run (a leak not yet traced), so workers start with a heap-size hint and
# are replaced every `worker_recycle` jobs. Each call of run_all starts from fresh workers.
const WORKER_SETUP = quote
    using BreadEconomySim, DataFrames, CSV
    include(joinpath($ROOT, "scripts", "ladder_definition.jl"))
    isdefined(Main, :LADDER_CACHE) || (const LADDER_CACHE = Dict{Tuple{Int, Int, Symbol, Symbol, Symbol}, Any}())   # set up once per process
    ladder(N, rounds, settlement, fiscal = :own, surplus_rule = :debt_levy_taxcut) = get!(() -> ladder_definition(N, rounds, settlement; fiscal = fiscal, surplus_rule = surplus_rule), LADDER_CACHE, (N, rounds, settlement, fiscal, surplus_rule))

    """One run: build the rung's parameters, simulate, save the rounds to the job's own file (written under a temporary
    name and renamed, so a half-written file is never taken for a finished run)."""
    function run_job(job)
        # every line is printed by the worker the moment the run finishes (a worker's output is forwarded to this terminal),
        # so progress is visible while the batch is running, not only at the end
        say(line) = (println("[", lpad(job.index, 4), "/", job.total, "] ", line); flush(stdout))
        isfile(job.file) && (say("skipped (already done): $(job.rung) | $(job.system) seed $(job.seed)"); return "skipped")
        def = ladder(job.N, job.rounds, job.settlement, get(job, :fiscal, :own), get(job, :surplus_rule, :debt_levy_taxcut))
        i = only(k for (k, r) in enumerate(def.rungs) if r[1] == job.rung); (_, kd, ks) = def.rungs[i]
        kd = isempty(kd) ? kd : (; job.extra..., kd...); ks = isempty(ks) ? ks : (; job.extra..., ks...)   # 28 Oct: a step's own settings win over the variant (the realistic set had overwritten the contract steps)   # 18 Oct: the contracts variant travels inside the job (workers do not see the main process's globals)
        base, kw = job.system == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
        # 12 Oct: a rung whose settings are unchanged for this village from the rung below is the same village run again, so that
        # the two stay side by side — say so (the ladder names each rung once for both: "interest on deposits | sumsy" has none)
        same_as = i > 1 && kw == (job.system == "debt" ? def.rungs[i - 1][2] : def.rungs[i - 1][3]) ? " (as " * first(split(def.rungs[i - 1][1])) * ")" : ""
        t = @elapsed m = run_simulation(SimulationParameters(; seed = job.seed, base..., kw...))
        d = round_data(m)
        d.rung .= job.rung; d.system .= job.system; d.seed .= job.seed; d.identity .= hasproperty(d, :identity_gap) ? d.identity_gap : fill(money_identity_gap(m), nrow(d))
        mkpath(dirname(job.file)); tmp = job.file * ".tmp"
        CSV.write(tmp, d); mv(tmp, job.file; force = true)
        line = "$(job.N) $(job.settlement) | $(job.rung) | $(job.system)$(same_as) seed $(job.seed): alive $(d.persons_alive[end]) of $(job.N), $(round(t, digits = 0)) s"
        say(line)
        return line
    end
end
const SET_UP = Set{Int}()
function setup!(targets)
    todo = [p for p in targets if !(p in SET_UP)]                    # a process is set up once (fresh workers have new ids)
    isempty(todo) && return nothing
    Distributed.remotecall_eval(Main, todo, WORKER_SETUP)            # `using` cannot sit inside a function: a quoted block
    union!(SET_UP, todo)
    return nothing
end
function fresh_workers!(n::Int, heap_hint::String)
    workers() == [1] || rmprocs(workers())
    n > 1 && addprocs(n; exeflags = ["--project=$ROOT", "-O1", "--heap-size-hint=$heap_hint"])
    setup!(n > 1 ? workers() : [1])
    return nothing
end
setup!([1])                                                          # the main process: ladder_definition, run_job

# ---- the combined files and the summary ------------------------------------------------------------------------------------
"""
    write_split(path, df; limit_mb = 90)

Write `df` as one CSV if it stays under `limit_mb`, else as `…_rounds_part1.csv`, `…_part2.csv`, … each under the limit
(GitHub refuses files over 100 MB). Pieces are cut only between runs, never inside one. Earlier pieces or an earlier whole
file of the same name are removed first, so a smaller rerun leaves no stale parts behind. `read_split` reads them back.
"""
function write_split(path::String, df::DataFrame; limit_mb = 90)
    base = path[1:end-4]                                              # without ".csv"
    for f in readdir(dirname(path); join = true)                     # remove an earlier whole file and earlier parts
        (f == path || part_number(base, f) !== nothing) && rm(f)
    end
    CSV.write(path, df)
    size_mb = filesize(path) / 2^20
    size_mb <= limit_mb && return [path]
    rm(path)
    sort!(df, [:rung, :system, :seed, :round])
    runs = collect(groupby(df, [:rung, :system, :seed]))
    pieces = ceil(Int, size_mb / limit_mb) + 1                       # a margin: rows are not all the same width
    per = ceil(Int, length(runs) / pieces)
    written = String[]
    for (k, chunk) in enumerate(Iterators.partition(runs, per))
        f = "$(base)_part$(k).csv"
        CSV.write(f, reduce(vcat, (DataFrame(r) for r in chunk)))
        push!(written, f)
    end
    return written
end

"""The part number of `f` if it is `<base>_part<k>.csv`, else `nothing`."""
function part_number(base::String, f::String)
    prefix = base * "_part"
    (startswith(f, prefix) && endswith(f, ".csv")) || return nothing
    return tryparse(Int, f[length(prefix)+1:end-4])
end

"""Read a file written by `write_split` — the whole file, or its parts in order."""
function read_split(path::String)
    isfile(path) && return CSV.read(path, DataFrame)
    base = path[1:end-4]
    parts = sort([f for f in readdir(dirname(path); join = true) if part_number(base, f) !== nothing]; by = f -> part_number(base, f))
    isempty(parts) && error("neither $(path) nor its parts exist")
    return reduce((a, b) -> vcat(a, b; cols = :union), (CSV.read(f, DataFrame) for f in parts))
end

"""One row per rung and village: the numbers the report quotes (means over the runs, with the worst run and the count of
runs in which the village stayed whole, i.e. lost at most one person in sixteen)."""
function summarise(rounds::DataFrame, N::Int)
    # 26 Oct: the model's own GDP (bread, tickets, premium loaves, public wages, the banks' margin, stock changes) where the run has it;
    # older runs fall back to bread and tickets only, which leaves out the government and overstates the debt ratio
    rounds.gdp_round = hasproperty(rounds, :gdp_nominal) ? coalesce.(rounds.gdp_nominal, 0.0) : coalesce.(rounds.bread_sold .* coalesce.(rounds.price_bread, 0.0) .+ rounds.ticket_revenue, 0.0)
    rounds.gdp_head_round = hasproperty(rounds, :gdp_per_head_loaves) ? coalesce.(rounds.gdp_per_head_loaves, NaN) : fill(NaN, nrow(rounds))
    last_rows = combine(groupby(sort(rounds, :round), [:rung, :system, :seed]), last)
    maxround = maximum(rounds.round)
    tail = combine(groupby(filter(r -> r.round > maxround - 12, rounds), [:rung, :system, :seed]),
        :gdp_round => mean => :gdp, :gdp_head_round => (x -> (v = filter(isfinite, x); isempty(v) ? missing : mean(v))) => :gdp_per_head, :tickets_sold => mean => :tickets, :price_bread => (x -> mean(skipmissing(x))) => :bread_price,
        :unemployed => mean => :unemployed, :tax => mean => :revenue, :government_outlay => mean => :outlay)
    # every run is kept: a run that ended early (a village that lost its last farm or bakery) has no rows in the tail window,
    # and an inner join silently dropped it — survivorship bias (review 3). Left join; the run's last recorded row stands.
    runs = leftjoin(last_rows, tail; on = [:rung, :system, :seed], makeunique = true)
    # 13 Oct (review 7): the price trend of each run — bread at the end against bread at month 12, as a yearly rate
    yr1 = combine(groupby(filter(r -> r.round == min(12, maxround), rounds), [:rung, :system, :seed]), :price_bread => first => :bread_year1)
    runs = leftjoin(runs, yr1; on = [:rung, :system, :seed])
    runs.bread_price_change_per_year = [(ismissing(a) || ismissing(b) || !(a > 0) || !(b > 0)) ? missing : 100 * ((a / b)^(12 / max(maxround - 12, 1)) - 1) for (a, b) in zip(runs.bread_price, runs.bread_year1)]
    runs.collapsed = runs.round .< maxround
    # the public debt's course in each run: its peak, the month of the peak, and the first month after it with nothing owed
    debt_course = combine(groupby(sort(rounds, :round), [:rung, :system, :seed])) do g
        peak, k = findmax(g.government_debt)
        after = findfirst(<=(1e-6), g.government_debt[k:end])
        (; debt_peak = peak, debt_peak_month = g.round[k], debt_repaid_month = (peak <= 1e-6 || after === nothing) ? missing : g.round[k + after - 1],
           owes_nothing = g.government_debt[end] <= 1e-6)          # 15 Oct: a run that never borrowed owes nothing too
    end
    runs = leftjoin(runs, debt_course; on = [:rung, :system, :seed])
    runs.debt_pct_gdp = [(ismissing(g) || g <= 0) ? missing : 100 * d / (12 * g) for (d, g) in zip(runs.government_debt, runs.gdp)]   # a collapsed run has no last-year rows
    runs.shortfall = runs.outlay .- runs.revenue
    m(x) = (v = collect(skipmissing(x)); isempty(v) ? missing : mean(v))          # means over the runs that have the figure
    # 18 Oct (roadmap step 3): distributions beside the means — median, quartiles and the 5th–95th band — for the measures the
    # report quotes, and the public debt per head on two bases (per survivor and per starting villager)
    q(p) = x -> (v = filter(y -> !(y isa AbstractFloat && isnan(y)), collect(skipmissing(x))); isempty(v) ? missing : quantile(v, p))   # 19 Oct: a village that died out has NaN prices; quantiles over the runs that have the figure
    dist(col) = [col => q(0.5) => Symbol(col, :_median), col => q(0.25) => Symbol(col, :_q25), col => q(0.75) => Symbol(col, :_q75), col => q(0.05) => Symbol(col, :_p5), col => q(0.95) => Symbol(col, :_p95)]
    runs.public_debt_per_survivor = runs.government_debt ./ max.(runs.persons_alive, 1)
    runs.public_debt_per_villager = runs.government_debt ./ N
    combine(groupby(runs, [:rung, :system]),
        dist(:persons_alive)..., dist(:unemployed)..., dist(:bread_price)..., dist(:government_debt)..., dist(:wealth_gap_meals)..., dist(:wealth_bottom10_meals)..., dist(:bread_price_change_per_year)...,
        :public_debt_per_survivor => m => :public_debt_per_survivor, :public_debt_per_villager => m => :public_debt_per_villager,
        nrow => :runs, :collapsed => sum => :runs_collapsed,
        :persons_alive => m => :alive_at_end, :persons_alive => minimum => :alive_worst,
        [:persons_alive, :collapsed] => ((a, c) -> count(i -> !c[i] && a[i] >= N * 15 / 16, eachindex(a))) => :runs_whole,   # a collapsed village is never whole (review 5)
        [:persons_alive, :collapsed] => ((a, c) -> (v = a[.!c]; isempty(v) ? missing : mean(v))) => :alive_complete_runs,
        :unemployed => m => :unemployed, :tickets => m => :tickets, :bread_price => m => :bread_price,
        :government_debt => m => :public_debt, :debt_pct_gdp => m => :public_debt_pct_gdp, :gdp_per_head => m => :gdp_per_head_loaves, :shortfall => m => :shortfall_per_month,
        :debt_peak => m => :public_debt_peak, :debt_peak_month => m => :public_debt_peak_month,
        :owes_nothing => count => :runs_debt_repaid,   # 15 Oct: runs that owe nothing at the end (a run that never borrowed counted as unpaid before)
         :debt_repaid_month => (x -> all(ismissing, x) ? missing : mean(skipmissing(x))) => :public_debt_repaid_month,
        :fiscal => first => :fiscal,                                 # 22 Oct: the package (own | taxes | parking)
        :levy_paid_out_per_head => last => :levy_paid_out_per_head, :tax_scale => last => :tax_scale_end, :surplus_debt_repaid_total => last => :surplus_debt_repaid_total,   # 23 Oct (§1.3): at month 120
        :gini_cash_persons => m => :gini_cash,
        :gini_net_wealth_persons => (x -> (v = collect(skipmissing(x)); (isempty(v) || any(g -> !(0 <= g <= 1), v)) ? missing : mean(v))) => :gini_wealth,   # not defined when net wealth goes negative
        :gini_total_wealth_persons => (x -> (v = collect(skipmissing(x)); (isempty(v) || any(g -> !(0 <= g <= 1), v)) ? missing : mean(v))) => :gini_total_wealth,   # 20 Oct: gold included (review 5)
        :wealth_gap_meals => m => :wealth_gap_meals, :wealth_bottom10_meals => m => :wealth_bottom10_meals,
        :cash_gap_meals => m => :cash_gap_meals, :cash_bottom10_meals => m => :cash_bottom10_meals,
        :negative_wealth_persons => m => :under_water, :zero_cash_persons => m => :without_cash,
        :bad_debt => m => :loans_written_off, :new_firms => m => :firms_restarted,   # 27 Sept: the money pump made visible (bank_bailouts is already below)
        :land_households_share => m => :land_held_by_households, :gini_wealth_attributed => (x -> (v = collect(skipmissing(x)); (isempty(v) || any(g -> !(0 <= g <= 1), v)) ? missing : mean(v))) => :gini_wealth_firms_attributed,
        :liquidations => m => :liquidations, :refoundings => m => :refoundings, :bank_bailouts => m => :bank_bailouts,
        :bread_price_change_per_year => m => :bread_price_change_per_year,   # 13 Oct (review 7): the price trend, in the summary
        :identity => (x -> maximum(abs.(x))) => :worst_identity_gap)
end


# ---- run_all ----------------------------------------------------------------------------------------------------------------
"""
    run_all(; jobs, seeds = 10, rounds = 120, ladders = [(512, :invoicing)], rungs = String[], skip_tests = false,
            summary_only = false, shard = "", contract_share = nothing, worker_recycle = 20, heap_hint = "4G",
            update_econosim = false)

Run the ladders and write their combined files and summaries. See the head of scripts/run_all.jl for every setting.
Returns how many runs this call did and how many failed, how many were already done, and how many it left to another shard.
"""
function run_all(; jobs::Int = max(Sys.CPU_THREADS - 1, 1), seeds::Int = 10, rounds::Int = 120,
                   ladders = [(512, :invoicing)], rungs = String[], skip_tests::Bool = false, summary_only::Bool = false,
                   shard::AbstractString = "", contract_share = nothing, variant = nothing, variant_label::AbstractString = "variant", fiscal::Symbol = :own, surplus_rule::Symbol = :debt_levy_taxcut,
                   worker_recycle::Int = 20, heap_hint::AbstractString = "4G",
                   update_econosim::Bool = false)
    start_time = now()
    update_econosim && prepare_packages!(; update_econosim = true)
    run_tests!(; skip = skip_tests || summary_only)
    fiscal in (:own, :taxes, :parking) || error("fiscal must be :own, :taxes or :parking")
    extra = variant_extra(contract_share, variant); variant = variant_name(contract_share, variant, String(variant_label), fiscal, surplus_rule)
    rungs = String.(rungs)

    # the jobs
    jobs_list = NamedTuple[]
    for (N, settlement) in ladders
        def = ladder(N, rounds, settlement, fiscal, surplus_rule)
        missing_steps = [r for r in rungs if !any(x -> startswith(x[1], r), def.rungs)]   # 25 Oct: a name that matches nothing used to be skipped without a word
        isempty(missing_steps) || error("run_all: no step of the ladder matches " * join(repr.(missing_steps), ", ") * " — check the name, or unpack the latest package (this code is version $(MODEL_VERSION))")
        for (name, kd, ks) in def.rungs
            (isempty(rungs) || any(p -> startswith(name, p), rungs)) || continue
            for system in ("debt", "sumsy"), seed in 1:seeds
                kw = system == "debt" ? kd : ks
                (isempty(kw) && !occursin(r"^[0-9]", name)) && continue   # a side with no settings of its own is not run (main steps excepted)
                file = joinpath(parts_dir(N, settlement, rounds, variant), "$(safe(name))__$(system)__$(seed).csv")
                push!(jobs_list, (; N, settlement, rounds, rung = name, system, seed, extra, fiscal, surplus_rule, file, index = length(jobs_list) + 1, total = 0))
            end
        end
    end
    jobs_list = [(; j..., total = length(jobs_list)) for j in jobs_list]
    # mirror cells: a configuration identical to an earlier cell's is the same village — its finished files are copied, relabelled
    let seen = Dict{String, Any}(), copied = 0
        for j in jobs_list
            def = ladder(j.N, j.rounds, j.settlement, j.fiscal, j.surplus_rule)
            (_, kd, ks) = only(r for r in def.rungs if r[1] == j.rung)
            kw = with_extra(j.system == "debt" ? kd : ks, extra)
            key = string(j.N, "|", j.settlement, "|", j.rounds, "|", j.system, "|", j.seed, "|", repr(kw))
            if haskey(seen, key)
                src = seen[key]
                if !isfile(j.file) && isfile(src)
                    df = CSV.read(src, DataFrame); df.rung .= j.rung; mkpath(dirname(j.file)); CSV.write(j.file, df); copied += 1
                end
            else
                seen[key] = j.file
            end
        end
        copied > 0 && println("$(copied) mirror cells copied from identical configurations.")
    end
    todo = filter(j -> !isfile(j.file), jobs_list)
    if !isempty(shard)
        k, n = parse.(Int, split(shard, "/"))
        (1 <= k <= n) || error("shard must be \"k/n\" with 1 ≤ k ≤ n, got $shard")
        todo = filter(j -> (j.index - 1) % n == k - 1, todo)
        println("Shard $k of $n: this machine takes $(length(todo)) of the runs still to do."); flush(stdout)
    end
    summary_only && (todo = empty(todo); println("summary_only: no runs; summarising what is there."))
    # 20 Oct (Stef): the progress lines count this call's runs — on a shard, [  12/1075] rather than [  24/2150]
    todo = [(; j..., index = k, total = length(todo)) for (k, j) in enumerate(todo)]
    done_before = count(j -> isfile(j.file), jobs_list)
    println("\n$(length(jobs_list)) runs in total, $(done_before) already done; this call runs $(length(todo))$(isempty(shard) ? "" : " (shard $shard)"), on $(min(jobs, max(length(todo), 1))) process(es).\n"); flush(stdout)

    # the runs, in chunks with fresh workers
    results = String[]
    if !isempty(todo)
        n = min(jobs, length(todo))
        chunk = max(worker_recycle * n, 1)
        for lo in 1:chunk:length(todo)
            part = todo[lo:min(lo + chunk - 1, end)]
            fresh_workers!(n, String(heap_hint))
            if n > 1
                append!(results, pmap(WorkerPool(workers()), part; on_error = e -> "FAILED: " * sprint(showerror, e)) do job
                    run_job(job)
                end)
            else
                append!(results, [try run_job(job) catch e; "FAILED: " * sprint(showerror, e) end for job in part])
            end
            lo + chunk <= length(todo) && (println("… $(length(results)) of $(length(todo)) done; replacing the workers (memory)."); flush(stdout))
        end
        workers() == [1] || rmprocs(workers())                        # leave the REPL as it was
    end
    failed = count(startswith("FAILED"), results)
    for (job, line) in zip(todo, results)
        startswith(line, "FAILED") && println("FAILED  $(job.N) $(job.settlement) | $(job.rung) | $(job.system) seed $(job.seed): ", first(line, 400))
    end
    failed > 0 && @warn "$failed runs failed; call run_all again to retry them (finished runs are kept)"

    # the combined files and summaries
    for (N, settlement) in ladders
        dir = parts_dir(N, settlement, rounds, variant)
        isdir(dir) || continue
        # 14 Oct: only the files of steps on the current ladder — a renamed or removed step leaves orphans in the folder (Y8-loyal,
        # a duplicated S3-W block), which must not reach the summary
        name_of = Dict(safe(r[1]) => r[1] for r in ladder(N, rounds, settlement, fiscal, surplus_rule).rungs)
        current = Set(keys(name_of))
        stepof(f) = first(rsplit(basename(f), "__"; limit = 3))        # 16 Oct: from the right — a name ending in ')' or '%' leaves '___' in the file name
        files = filter(f -> endswith(f, ".csv") && stepof(f) in current, readdir(dir; join = true))
        orphans = count(f -> endswith(f, ".csv") && !(stepof(f) in current), readdir(dir; join = true))
        orphans > 0 && println("$(orphans) part files of steps no longer on the ladder are left out of the summary.")
        isempty(files) && continue
        # 16 Oct: the step, side and seed come from the file name — a mirror copy carries its source's labels inside (GP10-40's SuMSy
        # side was summarised as UP8, and T10's copies of T8 counted twice under T8)
        function labelled(f)
            df = CSV.read(f, DataFrame)
            step, system, seed = rsplit(replace(basename(f), ".csv" => ""), "__"; limit = 3)
            df.rung .= name_of[step]; df.system .= String(system); df.seed .= parse(Int, seed); df.fiscal .= String(fiscal)   # 22 Oct: the package
            return df
        end
        rounds_df = reduce((a, b) -> vcat(a, b; cols = :union), [labelled(f) for f in files])
        name = ladder_name(N, settlement, variant)
        # 23 Oct (Stef): the combined files carry the version, so a run on a new version never overwrites an earlier run's
        # summary (a 24-run call on .8 had replaced the full ladder's .13 summary, and its one rounds file had deleted the four parts)
        vname = "$(name)_$(MODEL_VERSION)"
        write_split(joinpath(ROOT, "results", "$(vname)_rounds.csv"), rounds_df)   # under GitHub's 100 MB limit (25 Sept)
        CSV.write(joinpath(ROOT, "results", "$(vname)_summary.csv"), summarise(rounds_df, N))
        println("wrote results/$(vname)_rounds*.csv and results/$(vname)_summary.csv ($(length(files)) runs)")
        if settlement == :invoicing
            run(addenv(`$(Base.julia_cmd()) --project=$ROOT $(joinpath(ROOT, "scripts", "dump_rungs.jl")) $seeds $rounds all $N`, "SETTLEMENT" => "invoicing", "FISCAL" => String(fiscal), "SURPLUS_RULE" => String(surplus_rule), "VERSION_TAG" => MODEL_VERSION))   # 22 Oct: the package's rungs file; 23 Oct: with the version
        end
    end
    elapsed = Dates.value(now() - start_time) ÷ 1000
    println("\nAll done in $(elapsed ÷ 3600) h $(lpad((elapsed % 3600) ÷ 60, 2, '0')) min $(lpad(elapsed % 60, 2, '0')) s (started $(Dates.format(start_time, "yyyy-mm-dd HH:MM")), finished $(Dates.format(now(), "yyyy-mm-dd HH:MM")))."); flush(stdout)
    return (; done = length(results) - failed, failed, already_done = done_before, not_in_this_call = length(jobs_list) - done_before - length(todo))   # 20 Oct: a shard's other half is 'not in this call', not 'skipped'
end

# ---- the command line: the environment variables of before ------------------------------------------------------------
function settings_from_env()
    kw = Dict{Symbol, Any}()
    haskey(ENV, "JOBS") && (kw[:jobs] = parse(Int, ENV["JOBS"]))
    haskey(ENV, "SEEDS") && (kw[:seeds] = parse(Int, ENV["SEEDS"]))
    haskey(ENV, "ROUNDS") && (kw[:rounds] = parse(Int, ENV["ROUNDS"]))
    haskey(ENV, "LADDERS") && (kw[:ladders] = [(parse(Int, split(x, ":")[1]), Symbol(split(x, ":")[2])) for x in split(ENV["LADDERS"], ",")])
    haskey(ENV, "RUNGS") && (kw[:rungs] = filter(!isempty, split(ENV["RUNGS"], ",")))
    get(ENV, "SKIP_TESTS", "0") == "1" && (kw[:skip_tests] = true)
    get(ENV, "SUMMARY_ONLY", "0") == "1" && (kw[:summary_only] = true)
    haskey(ENV, "SHARD") && (kw[:shard] = ENV["SHARD"])
    haskey(ENV, "CONTRACT_SHARE") && !isempty(ENV["CONTRACT_SHARE"]) && (kw[:contract_share] = parse(Float64, ENV["CONTRACT_SHARE"]))
    haskey(ENV, "WORKER_RECYCLE") && (kw[:worker_recycle] = parse(Int, ENV["WORKER_RECYCLE"]))
    haskey(ENV, "HEAP_HINT") && (kw[:heap_hint] = ENV["HEAP_HINT"])
    get(ENV, "UPDATE_ECONOSIM", "0") == "1" && (kw[:update_econosim] = true)
    return (; kw...)
end
if abspath(PROGRAM_FILE) == abspath(@__FILE__)                       # run from the command line: the environment variables
    run_all(; settings_from_env()...)
end
nothing                                                               # include() in the REPL returns nothing (it returned `false` before)
