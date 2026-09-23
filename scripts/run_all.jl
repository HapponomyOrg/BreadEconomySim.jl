# ======================================================================================================================
# run_all.jl — everything the Bread Economy report needs, in one command.
#
#     julia --project=. scripts/run_all.jl
#
# What it does, in order:
#   1. installs and precompiles the packages (Pkg.instantiate), and runs the test suite unless SKIP_TESTS=1;
#   2. runs the ladders — by default the 512-villager ladder under the new settlement (invoicing), the same ladder under the
#      old settlement (the before/after comparison), and the 128-villager ladder (the size comparison) — every rung, both
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
#   LADDERS=512:invoicing,512:clearing_all,128:invoicing
#   RUNGS=                  only rungs whose name starts with one of these comma-separated prefixes (for testing)
#   SKIP_TESTS=1            skip the test suite
#   ECONOSIM_PATH=…         where EconoSim.jl is, if not in a folder next to this repository
#
# Example, a quick check that everything works (a few minutes):
#     SEEDS=1 ROUNDS=6 LADDERS=128:invoicing RUNGS=0,2 SKIP_TESTS=1 julia --project=. scripts/run_all.jl
#
# Output (results/):
#   ladder2_<N>_rounds.csv / ladder2_<N>_clearing_all_rounds.csv     every round of every run
#   ladder2_<N>_summary.csv / ladder2_<N>_clearing_all_summary.csv   one row per rung and village
#   ladder2_<N>_rungs.csv                                            what each rung contains (for the report's panels)
# ======================================================================================================================

const ROOT = normpath(joinpath(@__DIR__, ".."))
cd(ROOT)

# ---- 1. packages and tests --------------------------------------------------------------------------------------------
using Pkg
Pkg.activate(ROOT; io = devnull)
# EconoSim.jl is a local package: the Manifest records the path it had on the machine where it was last resolved. If that path
# does not exist here, use ECONOSIM_PATH, or an EconoSim.jl folder next to this repository, and point the project at it.
let manifest = read(joinpath(ROOT, "Manifest.toml"), String)
    i = findfirst("[[deps.EconoSim]]", manifest)
    block = i === nothing ? "" : split(manifest[last(i)+1:end], "\n[[")[1]           # the EconoSim entry, up to the next package
    m = match(r"path = \"([^\"]+)\"", block)
    recorded = m === nothing ? "" : m.captures[1]
    if isempty(recorded) || !isdir(isabspath(recorded) ? recorded : joinpath(ROOT, recorded))
        candidate = get(ENV, "ECONOSIM_PATH", normpath(joinpath(ROOT, "..", "EconoSim.jl")))
        isdir(candidate) || error("EconoSim.jl not found. Clone https://github.com/HapponomyOrg/EconoSim.jl next to this repository, or set ECONOSIM_PATH.")
        println("Pointing the project at EconoSim.jl in $candidate"); Pkg.develop(path = candidate)
    end
end
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
const LADDERS = [(parse(Int, split(x, ":")[1]), Symbol(split(x, ":")[2])) for x in split(get(ENV, "LADDERS", "512:invoicing,512:clearing_all,128:invoicing"), ",")]
const RUNGS   = filter(!isempty, split(get(ENV, "RUNGS", ""), ","))

ladder_name(N, settlement) = settlement == :invoicing ? "ladder2_$(N)" : "ladder2_$(N)_$(settlement)"
const MODEL_VERSION = "2026-09-23"   # part of the key: runs made with an earlier model are never taken for current ones
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
        (_, kd, ks) = only(r for r in def.rungs if r[1] == job.rung)
        base, kw = job.system == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
        t = @elapsed m = run_simulation(SimulationParameters(; seed = job.seed, base..., kw...))
        d = round_data(m)
        d.rung .= job.rung; d.system .= job.system; d.seed .= job.seed; d.identity .= money_identity_gap(m)
        mkpath(dirname(job.file)); tmp = job.file * ".tmp"
        CSV.write(tmp, d); mv(tmp, job.file; force = true)
        line = "$(job.N) $(job.settlement) | $(job.rung) | $(job.system) seed $(job.seed): alive $(d.persons_alive[end]) of $(job.N), $(round(t, digits = 0)) s"
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
            job = (; N, settlement, rounds = ROUNDS, rung = name, system, seed)
            push!(jobs, (; job..., file = part_file(job), index = length(jobs) + 1, total = 0))
        end
    end
end
jobs = [(; j..., total = length(jobs)) for j in jobs]                 # each run knows its number, for the progress lines
todo = filter(j -> !isfile(j.file), jobs)
println("\n$(length(jobs)) runs in total, $(length(jobs) - length(todo)) already done, $(length(todo)) to go, on $(max(nworkers(), 1)) worker(s).\n"); flush(stdout)

results = pmap(todo; on_error = e -> "FAILED: " * sprint(showerror, e)) do job
    run_job(job)
end
failed = count(startswith("FAILED"), results)
failed > 0 && @warn "$failed runs failed; run the script again to retry them (finished runs are kept)"

# ---- 3. combined files, summaries and configuration tables ----------------------------------------------------------
using DataFrames, CSV, Statistics

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
    runs.collapsed = runs.round .< maxround
    # the public debt's course in each run: its peak, the month of the peak, and the first month after it with nothing owed
    debt_course = combine(groupby(sort(rounds, :round), [:rung, :system, :seed])) do g
        peak, k = findmax(g.government_debt)
        after = findfirst(<=(1e-6), g.government_debt[k:end])
        (; debt_peak = peak, debt_peak_month = g.round[k], debt_repaid_month = (peak <= 1e-6 || after === nothing) ? missing : g.round[k + after - 1])
    end
    runs = leftjoin(runs, debt_course; on = [:rung, :system, :seed])
    runs.debt_pct_gdp = [g > 0 ? 100 * d / (12 * g) : NaN for (d, g) in zip(runs.government_debt, runs.gdp)]
    runs.shortfall = runs.outlay .- runs.revenue
    combine(groupby(runs, [:rung, :system]),
        nrow => :runs, :collapsed => sum => :runs_collapsed,
        :persons_alive => mean => :alive_at_end, :persons_alive => minimum => :alive_worst,
        :persons_alive => (x -> count(>=(N * 15 / 16), x)) => :runs_whole,
        :unemployed => mean => :unemployed, :tickets => mean => :tickets, :bread_price => mean => :bread_price,
        :government_debt => mean => :public_debt, :debt_pct_gdp => mean => :public_debt_pct_gdp, :shortfall => mean => :shortfall_per_month,
        :debt_peak => mean => :public_debt_peak, :debt_peak_month => mean => :public_debt_peak_month,
        :debt_repaid_month => (x -> count(!ismissing, x)) => :runs_debt_repaid, :debt_repaid_month => (x -> all(ismissing, x) ? missing : mean(skipmissing(x))) => :public_debt_repaid_month,
        :gini_cash_persons => mean => :gini_cash, :gini_net_wealth_persons => mean => :gini_wealth,
        :wealth_gap_meals => mean => :wealth_gap_meals, :wealth_bottom10_meals => mean => :wealth_bottom10_meals,
        :cash_gap_meals => mean => :cash_gap_meals, :cash_bottom10_meals => mean => :cash_bottom10_meals,
        :negative_wealth_persons => mean => :under_water, :zero_cash_persons => mean => :without_cash,
        :liquidations => mean => :liquidations, :refoundings => mean => :refoundings, :bank_bailouts => mean => :bank_bailouts,
        :identity => (x -> maximum(abs.(x))) => :worst_identity_gap)
end

for (N, settlement) in LADDERS
    dir = parts_dir(N, settlement)
    isdir(dir) || continue
    files = filter(endswith(".csv"), readdir(dir; join = true))
    isempty(files) && continue
    rounds = reduce((a, b) -> vcat(a, b; cols = :union), [CSV.read(f, DataFrame) for f in files])
    name = ladder_name(N, settlement)
    CSV.write(joinpath(ROOT, "results", "$(name)_rounds.csv"), rounds)
    CSV.write(joinpath(ROOT, "results", "$(name)_summary.csv"), summarise(rounds, N))
    println("wrote results/$(name)_rounds.csv and results/$(name)_summary.csv ($(length(files)) runs)")
    if settlement == :invoicing
        run(addenv(`$(Base.julia_cmd()) --project=$ROOT $(joinpath(ROOT, "scripts", "dump_rungs.jl")) $SEEDS $ROUNDS all $N`, "SETTLEMENT" => "invoicing"))
    end
end
println("\nAll done.")
