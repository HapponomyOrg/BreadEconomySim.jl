# ======================================================================================================================
# preorder_capacity_diagnostic.jl — a DIAGNOSTIC for the bread pre-order experiment (11 November 2026), not part of the design
#
#     julia --project=. scripts/preorder_capacity_diagnostic.jl
#
# The experiment of docs/future_work/coder_brief_bread_preorders_2026-11-11.md (§8.3) found that in mode A (:at_risk) the
# cheapest bakery takes more orders than it can bake: its plan is capped at its share of the village's hands
# (`plan_within_capacity`, on in the ladder), but the order limit of the brief, max((1 + growth) × baked, plan), does not know
# the cap — so the orders above it fail every month. To test that explanation, this script re-runs mode A with the limit also
# capped at the bakery's capacity, by redefining `bread_order_limit` in the worker processes at run time. src/ is unchanged:
# the model as built is the brief's design. Same cells, villages, seeds and settings as `ablation` (realistic ladder);
# folders results/parts/ablation_<version>_diag_capped_<variant>, read by scripts/preorder_report.py like any variant.
# ======================================================================================================================
using Distributed
const ROOT = abspath(joinpath(@__DIR__, ".."))
include(joinpath(ROOT, "scripts", "run_all.jl"))            # MODEL_VERSION, REALISTIC_LABOUR
const DIAG_VARIANTS = Dict(:diag_capped_at_risk => (; bread_preorders = :at_risk),
                           :diag_capped_at_risk_no_limit => (; bread_preorders = :at_risk, bread_preorder_growth = Inf))
workers() == [1] || rmprocs(workers())
addprocs(min(12, Sys.CPU_THREADS - 1); exeflags = ["--project=$ROOT", "-O1", "--heap-size-hint=3G"])
@everywhere workers() begin
    using BreadEconomySim, DataFrames, CSV
    include(joinpath($ROOT, "scripts", "ladder_definition.jl"))
    Core.eval(BreadEconomySim, quote
        function bread_order_limit(model, b::Enterprise)     # the brief's limit, also capped at what the bakery may plan
            p = parameters(model); g = p.bread_preorder_growth
            lim = isinf(g) ? Inf : max((1 + g) * b.bread_baked, b.production_target * p.breads_per_grain)
            p.plan_within_capacity && (lim = min(lim, ceil(Int, bakery_capacity_loaves(model) / p.breads_per_grain) * p.breads_per_grain))
            return lim
        end
    end)
end
@everywhere workers() const DIAG = $(DIAG_VARIANTS)
@everywhere workers() const REAL = $(REALISTIC_LABOUR)
@everywhere workers() function diag_job(job)
    isfile(job.file) && return "skipped"
    def = ladder_definition(512, 120, :invoicing)
    (name, kd, ks) = only(r for r in def.rungs if startswith(r[1], job.cell))
    base, kw = job.system == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
    m = run_simulation(SimulationParameters(; seed = job.seed, base..., kw..., REAL..., DIAG[job.variant]...))
    d = round_data(m); d.rung .= name; d.system .= job.system; d.seed .= job.seed
    mkpath(dirname(job.file)); tmp = job.file * ".tmp"; CSV.write(tmp, d); mv(tmp, job.file; force = true)
    return "$(job.variant) $(job.cell) $(job.system) $(job.seed): alive $(d.persons_alive[end])"
end
def = ladder_definition(512, 120, :invoicing)
jobs = NamedTuple[]
for var in keys(DIAG_VARIANTS), cell in ["8 ", "B ", "V8 "], system in ("debt", "sumsy"), seed in 1:10
    name = only(r[1] for r in def.rungs if startswith(r[1], cell))
    file = joinpath(ROOT, "results", "parts", "ablation_$(MODEL_VERSION)_$(var)", "$(replace(strip(name), r"[^A-Za-z0-9]+" => "_"))__$(system)__$(seed).csv")
    push!(jobs, (; variant = var, cell, system, seed, file))
end
for line in pmap(j -> Main.diag_job(j), jobs; on_error = e -> "FAILED: " * sprint(showerror, e)); println(line); end
rmprocs(workers())
