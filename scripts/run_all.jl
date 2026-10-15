# ======================================================================================================================
# run_all.jl — everything the Bread Economy report needs, in one command.
#
#     julia --project=. scripts/run_all.jl
#
# What it does, in order:
#   1. installs and precompiles the packages (Pkg.instantiate), and runs the test suite unless SKIP_TESTS=1;
#   2. runs the ladders — by default the 512-villager ladder under invoicing, the main ladder (26 September: the old-settlement
#      and 128-villager comparisons are optional, see LADDERS) — every rung, both
#      villages, SEEDS runs each, ROUNDS months each, in parallel over JOBS worker processes;
#   3. writes, per ladder, the round-by-round data, a summary table (one row per rung and village) and the "what is there"
#      configuration table that the report's panels are built from.
#
# Each single run is saved as its own file under results/parts/ the moment it finishes, so the script can be stopped and
# started again at any time: finished runs are skipped. Nothing is ever overwritten except the combined files of step 3.
#
# Settings, all optional, as environment variables:
#   JOBS=6                  worker processes (default: number of CPU threads − 1)
#   SEEDS=10                runs per configuration
#   ROUNDS=120              months per run (120 = ten years)
#   LADDERS=512:invoicing       (default: the main ladder only; add 512:clearing_all for the old-settlement comparison and
#                               128:invoicing for the size comparison — both answered, worth one run on the frozen baseline)
#   RUNGS=                  only rungs whose name starts with one of these comma-separated prefixes (for testing)
#   SKIP_TESTS=1            skip the test suite
#   UPDATE_ECONOSIM=1       move EconoSim.jl to the latest commit on its main branch first
#
# Example, a quick check that everything works (a few minutes):
#     SEEDS=1 ROUNDS=6 LADDERS=128:invoicing RUNGS=0,2 SKIP_TESTS=1 julia --project=. scripts/run_all.jl
#
# Output (results/):
#   ladder2_<N>_rounds.csv / ladder2_<N>_clearing_all_rounds.csv     every round of every run — split into …_part1.csv, …_part2.csv
#                                                                    when over 90 MB (GitHub's limit is 100 MB); `read_split` reads either form
#   ladder2_<N>_summary.csv / ladder2_<N>_clearing_all_summary.csv   one row per rung and village
#   ladder2_<N>_rungs.csv                                            what each rung contains (for the report's panels)
# ======================================================================================================================

using Dates
const START_TIME = now()                                            # the whole batch is timed; printed at the end

const ROOT = normpath(joinpath(@__DIR__, ".."))
cd(ROOT)

# ---- 1. packages and tests --------------------------------------------------------------------------------------------
using Pkg
Pkg.activate(ROOT; io = devnull)
# EconoSim.jl comes from its GitHub repository (https://github.com/HapponomyOrg/EconoSim.jl, branch main). Set
# UPDATE_ECONOSIM=1 to move to its latest commit before running; otherwise the commit recorded in the Manifest is used.
get(ENV, "UPDATE_ECONOSIM", "0") == "1" && (println("Updating EconoSim.jl to the latest commit on main…"); Pkg.update("EconoSim"))
println("Installing and precompiling packages (first time only takes a while)…"); flush(stdout)
Pkg.instantiate(); Pkg.precompile()

if get(ENV, "SKIP_TESTS", "0") != "1"
    println("Running the test suite…"); flush(stdout)
    # the test output is shown in full, so that a failure says which test and why
    proc = run(ignorestatus(`$(Base.julia_cmd()) --project=$ROOT $(joinpath(ROOT, "test", "runtests.jl"))`))
    if proc.exitcode != 0
        println("""
        The test suite failed (see the output above for which tests and why). The ladders are not run on a model that fails
        its tests. Since 23 September the model's randomness is version-stable (StableRNGs, fixed stream seeds, ordered
        dictionaries), so the golden values should match on any Julia version and processor; a failure there is a real
        difference worth reporting, as is any other failing test.""")
        error("test suite failed (details above)")      # an error, not exit(): exit would also close a REPL the script runs in
    end
    println("Tests passed.")
end

# ---- settings -----------------------------------------------------------------------------------------------------------
const JOBS    = parse(Int, get(ENV, "JOBS", string(max(Sys.CPU_THREADS - 1, 1))))
const SEEDS   = parse(Int, get(ENV, "SEEDS", "10"))
const ROUNDS  = parse(Int, get(ENV, "ROUNDS", "120"))
const LADDERS = [(parse(Int, split(x, ":")[1]), Symbol(split(x, ":")[2])) for x in split(get(ENV, "LADDERS", "512:invoicing"), ",")]
const RUNGS   = filter(!isempty, split(get(ENV, "RUNGS", ""), ","))

ladder_name(N, settlement) = settlement == :invoicing ? "ladder2_$(N)" : "ladder2_$(N)_$(settlement)"
const MODEL_VERSION = "2026-10-15"   # part of the key: runs made with an earlier model are never taken for current ones
parts_dir(N, settlement) = joinpath(ROOT, "results", "parts", "$(ladder_name(N, settlement))_$(ROUNDS)months_$(MODEL_VERSION)")   # the run length is part of the key: a short test run is never taken for a real one
safe(s) = replace(s, r"[^A-Za-z0-9]+" => "_")
part_file(job) = joinpath(parts_dir(job.N, job.settlement), "$(safe(job.rung))__$(job.system)__$(job.seed).csv")

# ---- 2. the jobs ------------------------------------------------------------------------------------------------------
using Distributed
JOBS > 1 && nprocs() < JOBS + 1 && addprocs(JOBS - nprocs() + 1; exeflags = ["--project=$ROOT", "-O1"])

@everywhere begin
    using BreadEconomySim, DataFrames, CSV
    include(joinpath($ROOT, "scripts", "ladder_definition.jl"))
    const LADDER_CACHE = Dict{Tuple{Int, Int, Symbol}, Any}()
    ladder(N, rounds, settlement) = get!(() -> ladder_definition(N, rounds, settlement), LADDER_CACHE, (N, rounds, settlement))

    """One run: build the rung's parameters, simulate, save the rounds to the job's own file (written under a temporary
    name and renamed, so a half-written file is never taken for a finished run)."""
    function run_job(job)
        # every line is printed by the worker the moment the run finishes (a worker's output is forwarded to this terminal),
        # so progress is visible while the batch is running, not only at the end
        say(line) = (println("[", lpad(job.index, 4), "/", job.total, "] ", line); flush(stdout))
        isfile(job.file) && (say("skipped (already done): $(job.rung) | $(job.system) seed $(job.seed)"); return "skipped")
        def = ladder(job.N, job.rounds, job.settlement)
        i = only(k for (k, r) in enumerate(def.rungs) if r[1] == job.rung); (_, kd, ks) = def.rungs[i]
        base, kw = job.system == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
        # 12 Oct: a rung whose settings are unchanged for this village from the rung below is the same village run again, so that
        # the two stay side by side — say so (the ladder names each rung once for both: "interest on deposits | sumsy" has none)
        same_as = i > 1 && kw == (job.system == "debt" ? def.rungs[i - 1][2] : def.rungs[i - 1][3]) ? " (as " * first(split(def.rungs[i - 1][1])) * ")" : ""
        t = @elapsed m = run_simulation(SimulationParameters(; seed = job.seed, base..., kw...))
        d = round_data(m)
        d.rung .= job.rung; d.system .= job.system; d.seed .= job.seed; d.identity .= money_identity_gap(m)
        mkpath(dirname(job.file)); tmp = job.file * ".tmp"
        CSV.write(tmp, d); mv(tmp, job.file; force = true)
        line = "$(job.N) $(job.settlement) | $(job.rung) | $(job.system)$(same_as) seed $(job.seed): alive $(d.persons_alive[end]) of $(job.N), $(round(t, digits = 0)) s"
        say(line)
        return line
    end
end

include(joinpath(ROOT, "scripts", "ladder_definition.jl"))
jobs = NamedTuple[]
for (N, settlement) in LADDERS
    def = ladder_definition(N, ROUNDS, settlement)
    for (name, _, _) in def.rungs
        (isempty(RUNGS) || any(p -> startswith(name, p), RUNGS)) || continue
        for system in ("debt", "sumsy"), seed in 1:SEEDS
            (startswith(name, "X1") && system == "debt") && continue       # the 2×2 rungs run one side only
            (startswith(name, "X2") && system == "sumsy") && continue
            (startswith(name, "E") && system == "debt") && continue        # full-money-stock twins: SuMSy only
            (startswith(name, "L") && system == "debt") && continue        # land-levy variants: SuMSy only
            (startswith(name, "GP") && system == "debt") && continue       # parking-tax policy sweep: SuMSy only
            (startswith(name, "NLD") && system == "debt") && continue      # levy with entry: SuMSy only
            (startswith(name, "F") && system == "debt") && continue        # parking-fee policy: SuMSy only
            (startswith(name, "D") && system == "sumsy") && continue       # public debt ceiling: debt side only
            (startswith(name, "I") && system == "sumsy") && continue       # benefit fixed in money: debt side only
            (startswith(name, "W") && system == "sumsy") && continue       # willingness to overpay: debt side only
            (startswith(name, "A") && system == "sumsy") && continue       # austerity: debt side only
            (startswith(name, "Z") && system == "debt") && continue        # SuMSy without the levy: SuMSy only
            (startswith(name, "RZ") && system == "debt") && continue       # gold without the levy: SuMSy only
            (startswith(name, "GP") && system == "debt") && continue       # parking-tax policy sweep: SuMSy only
            (startswith(name, "NLD") && system == "debt") && continue      # levy with entry: SuMSy only
            (startswith(name, "F") && system == "debt") && continue        # parking-fee policy: SuMSy only
            (startswith(name, "D") && system == "sumsy") && continue       # public debt ceiling: debt side only
            (startswith(name, "I") && system == "sumsy") && continue       # benefit fixed in money: debt side only
            (startswith(name, "W") && system == "sumsy") && continue       # willingness to overpay: debt side only
            (startswith(name, "A") && system == "sumsy") && continue       # austerity: debt side only
            (startswith(name, "Z") && system == "debt") && continue        # SuMSy without the levy: SuMSy only
            (startswith(name, "RZ") && system == "debt") && continue       # gold without the levy: SuMSy only
            job = (; N, settlement, rounds = ROUNDS, rung = name, system, seed)
            push!(jobs, (; job..., file = part_file(job), index = length(jobs) + 1, total = 0))
        end
    end
end
jobs = [(; j..., total = length(jobs)) for j in jobs]                 # each run knows its number, for the progress lines
# 13 Oct (review 7): a cell whose configuration is identical to an earlier cell's — the SuMSy village at a rung that only changes
# the debt village, a variant that mirrors the ladder — is the same village, so its finished files are copied, not rerun
let seen = Dict{String, Any}(), copied = 0
    for j in jobs
        def = ladder(j.N, j.rounds, j.settlement)
        (_, kd, ks) = only(r for r in def.rungs if r[1] == j.rung)
        kw = j.system == "debt" ? kd : ks
        key = string(j.N, "|", j.settlement, "|", j.rounds, "|", j.system, "|", j.seed, "|", repr(kw))
        if haskey(seen, key)
            src = seen[key]
            if !isfile(j.file) && isfile(src)
                cp(src, j.file); copied += 1
            end
        else
            seen[key] = j.file
        end
    end
    copied > 0 && println("$(copied) mirror cells copied from identical configurations.")
end
todo = filter(j -> !isfile(j.file), jobs)
println("\n$(length(jobs)) runs in total, $(length(jobs) - length(todo)) already done, $(length(todo)) to go, on $(max(nworkers(), 1)) worker(s).\n"); flush(stdout)

results = pmap(todo; on_error = e -> "FAILED: " * sprint(showerror, e)) do job
    run_job(job)
end
failed = count(startswith("FAILED"), results)
for (job, line) in zip(todo, results)
    startswith(line, "FAILED") && println("FAILED  $(job.N) $(job.settlement) | $(job.rung) | $(job.system) seed $(job.seed): ", first(line, 400))
end
failed > 0 && @warn "$failed runs failed; run the script again to retry them (finished runs are kept)"

# ---- 3. combined files, summaries and configuration tables ----------------------------------------------------------
using DataFrames, CSV, Statistics

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
    rounds.gdp_round = coalesce.(rounds.bread_sold .* coalesce.(rounds.price_bread, 0.0) .+ rounds.ticket_revenue, 0.0)
    last_rows = combine(groupby(sort(rounds, :round), [:rung, :system, :seed]), last)
    maxround = maximum(rounds.round)
    tail = combine(groupby(filter(r -> r.round > maxround - 12, rounds), [:rung, :system, :seed]),
        :gdp_round => mean => :gdp, :tickets_sold => mean => :tickets, :price_bread => (x -> mean(skipmissing(x))) => :bread_price,
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
        (; debt_peak = peak, debt_peak_month = g.round[k], debt_repaid_month = (peak <= 1e-6 || after === nothing) ? missing : g.round[k + after - 1])
    end
    runs = leftjoin(runs, debt_course; on = [:rung, :system, :seed])
    runs.debt_pct_gdp = [(ismissing(g) || g <= 0) ? missing : 100 * d / (12 * g) for (d, g) in zip(runs.government_debt, runs.gdp)]   # a collapsed run has no last-year rows
    runs.shortfall = runs.outlay .- runs.revenue
    m(x) = (v = collect(skipmissing(x)); isempty(v) ? missing : mean(v))          # means over the runs that have the figure
    combine(groupby(runs, [:rung, :system]),
        nrow => :runs, :collapsed => sum => :runs_collapsed,
        :persons_alive => m => :alive_at_end, :persons_alive => minimum => :alive_worst,
        [:persons_alive, :collapsed] => ((a, c) -> count(i -> !c[i] && a[i] >= N * 15 / 16, eachindex(a))) => :runs_whole,   # a collapsed village is never whole (review 5)
        [:persons_alive, :collapsed] => ((a, c) -> (v = a[.!c]; isempty(v) ? missing : mean(v))) => :alive_complete_runs,
        :unemployed => m => :unemployed, :tickets => m => :tickets, :bread_price => m => :bread_price,
        :government_debt => m => :public_debt, :debt_pct_gdp => m => :public_debt_pct_gdp, :shortfall => m => :shortfall_per_month,
        :debt_peak => m => :public_debt_peak, :debt_peak_month => m => :public_debt_peak_month,
        :debt_repaid_month => (x -> count(!ismissing, x)) => :runs_debt_repaid, :debt_repaid_month => (x -> all(ismissing, x) ? missing : mean(skipmissing(x))) => :public_debt_repaid_month,
        :gini_cash_persons => m => :gini_cash,
        :gini_net_wealth_persons => (x -> (v = collect(skipmissing(x)); (isempty(v) || any(g -> !(0 <= g <= 1), v)) ? missing : mean(v))) => :gini_wealth,   # not defined when net wealth goes negative (review 5)
        :wealth_gap_meals => m => :wealth_gap_meals, :wealth_bottom10_meals => m => :wealth_bottom10_meals,
        :cash_gap_meals => m => :cash_gap_meals, :cash_bottom10_meals => m => :cash_bottom10_meals,
        :negative_wealth_persons => m => :under_water, :zero_cash_persons => m => :without_cash,
        :bad_debt => m => :loans_written_off, :new_firms => m => :firms_restarted,   # 27 Sept: the money pump made visible (bank_bailouts is already below)
        :land_households_share => m => :land_held_by_households, :gini_wealth_attributed => (x -> (v = collect(skipmissing(x)); (isempty(v) || any(g -> !(0 <= g <= 1), v)) ? missing : mean(v))) => :gini_wealth_firms_attributed,
        :liquidations => m => :liquidations, :refoundings => m => :refoundings, :bank_bailouts => m => :bank_bailouts,
        :bread_price_change_per_year => m => :bread_price_change_per_year,   # 13 Oct (review 7): the price trend, in the summary
        :identity => (x -> maximum(abs.(x))) => :worst_identity_gap)
end

for (N, settlement) in LADDERS
    dir = parts_dir(N, settlement)
    isdir(dir) || continue
    # 14 Oct: only the files of steps on the current ladder — a renamed or removed step leaves orphans in the folder (Y8-loyal,
    # a duplicated S3-W block), which must not reach the summary
    current = Set(safe(r[1]) for r in ladder(N, ROUNDS, settlement).rungs)
    files = filter(f -> endswith(f, ".csv") && first(split(basename(f), "__")) in current, readdir(dir; join = true))
    orphans = count(f -> endswith(f, ".csv") && !(first(split(basename(f), "__")) in current), readdir(dir; join = true))
    orphans > 0 && println("$(orphans) part files of steps no longer on the ladder are left out of the summary.")
    isempty(files) && continue
    rounds = reduce((a, b) -> vcat(a, b; cols = :union), [CSV.read(f, DataFrame) for f in files])
    name = ladder_name(N, settlement)
    write_split(joinpath(ROOT, "results", "$(name)_rounds.csv"), rounds)   # under GitHub's 100 MB limit (25 Sept)
    CSV.write(joinpath(ROOT, "results", "$(name)_summary.csv"), Base.invokelatest(summarise, rounds, N))   # invokelatest: the function is defined in this script (Julia 1.12 world age)
    println("wrote results/$(name)_rounds*.csv and results/$(name)_summary.csv ($(length(files)) runs)")
    if settlement == :invoicing
        run(addenv(`$(Base.julia_cmd()) --project=$ROOT $(joinpath(ROOT, "scripts", "dump_rungs.jl")) $SEEDS $ROUNDS all $N`, "SETTLEMENT" => "invoicing"))
    end
end
elapsed = Dates.value(now() - START_TIME) ÷ 1000                      # seconds
println("\nAll done in $(elapsed ÷ 3600) h $(lpad((elapsed % 3600) ÷ 60, 2, '0')) min $(lpad(elapsed % 60, 2, '0')) s (started $(Dates.format(START_TIME, "yyyy-mm-dd HH:MM")), finished $(Dates.format(now(), "yyyy-mm-dd HH:MM"))).")
