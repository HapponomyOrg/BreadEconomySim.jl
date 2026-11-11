# Long runs of one village over several seeds, on worker processes (11 November 2026).
#
#     include("scripts/long_run.jl")
#     long_run(cell = "B ", system = "sumsy", months = 1200, seeds = 1:10, jobs = 5)
#
# Each seed runs on its own worker process and is written the moment it finishes, under a temporary name that is renamed, then
# read back and its rows counted. A call that is interrupted resumes: seeds whose file exists are skipped. The files go to
# results/<folder>/seed_<n>.csv; the folder name is built from the arguments unless `folder` is given.
#
#   cell        the village by the first word of its name in the ladder, with the trailing space ("8 ", "B ", "V8 ", …)
#   system      "sumsy" or "debt"
#   months      length of the run (1200 = a hundred years)
#   seeds       the rolls of the dice, e.g. 1:10
#   realistic   true = the realistic labour rules (REALISTIC_LABOUR), false = the standard ladder
#   jobs        worker processes; by default one a seed, at most the CPU threads minus one
#   heap_hint   memory at which a worker starts collecting garbage harder ("6G"); a hundred-year run keeps every event in memory
include(joinpath(@__DIR__, "run_all.jl"))

const LONG_RUN_WORKER = quote
    LONG_REALISTIC = $(REALISTIC_LABOUR)
    function long_run_job(job)
        def = ladder(job.villagers, job.months, :invoicing)
        (name, kd, ks) = only(r for r in def.rungs if startswith(r[1], job.cell))
        base, kw = job.system == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
        isempty(kw) && error("the village \"$(strip(name))\" has no $(job.system) copy")
        extra = job.realistic ? LONG_REALISTIC : (;)
        d = round_data(run_simulation(SimulationParameters(; seed = job.seed, base..., kw..., extra...)))
        d.rung .= name; d.system .= job.system; d.seed .= job.seed
        mkpath(dirname(job.file)); tmp = job.file * ".tmp"; CSV.write(tmp, d); mv(tmp, job.file; force = true)
        rows = nrow(CSV.read(job.file, DataFrame))
        msg = "seed $(job.seed): written to $(job.file) — $rows rows, $(d.persons_alive[end]) alive, bread $(round(d.price_bread[end], digits = 2))"
        println(msg); flush(stdout)
        return msg
    end
end

function long_run(; cell::AbstractString = "B ", system::AbstractString = "sumsy", months::Int = 1200, seeds = 1:10, realistic::Bool = true, villagers::Int = 512,
                  jobs::Int = min(length(seeds), max(Sys.CPU_THREADS - 1, 1)), heap_hint::AbstractString = "6G",
                  folder::AbstractString = "$(system)_$(replace(strip(cell), r"[^A-Za-z0-9]+" => "_"))_$(realistic ? "realistic" : "standard")_$(months)_months")
    system in ("sumsy", "debt") || error("system must be \"sumsy\" or \"debt\"")
    dir = mkpath(joinpath(@__DIR__, "..", "results", folder))
    todo = [(; cell = String(cell), system = String(system), seed, months, villagers, realistic, file = joinpath(dir, "seed_$(seed).csv")) for seed in seeds]
    done = filter(j -> isfile(j.file), todo); todo = filter(j -> !isfile(j.file), todo)
    isempty(done) || println("already there, skipped: seeds ", [j.seed for j in done])
    n = min(jobs, length(todo))
    println(length(todo), " runs of ", months, " months to do, on ", max(n, 1), " process(es); files in ", abspath(dir)); flush(stdout)
    if !isempty(todo)
        fresh_workers!(n, String(heap_hint))
        Distributed.remotecall_eval(Main, n > 1 ? workers() : [1], LONG_RUN_WORKER)
        out = n > 1 ? pmap(job -> Main.long_run_job(job), WorkerPool(workers()), todo; on_error = e -> "FAILED: " * sprint(showerror, e)) :
                      [try Base.invokelatest(Main.long_run_job, job) catch e; "FAILED: " * sprint(showerror, e) end for job in todo]   # invokelatest: the function was defined during this call
        workers() == [1] || rmprocs(workers())
        for (j, r) in zip(todo, out); startswith(r, "FAILED") && println("FAILED seed ", j.seed, ": ", first(r, 300)); end
    end
    # the check: every seed's file exists and has one row a month
    ok = true
    for seed in seeds
        f = joinpath(dir, "seed_$(seed).csv")
        rows = isfile(f) ? nrow(CSV.read(f, DataFrame)) : 0
        rows == months || (ok = false; println("NOT COMPLETE seed ", seed, ": ", isfile(f) ? "$rows rows instead of $months (the village may have stopped early)" : "no file"))
    end
    println(ok ? "all $(length(seeds)) seeds written and complete in $(abspath(dir))" : "some seeds are missing or short — call long_run again with the same arguments to retry them")
    return nothing
end
